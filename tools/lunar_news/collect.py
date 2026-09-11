"""Collect source excerpts and explicit research actions, without inventing model inputs."""
from __future__ import annotations

import argparse
from datetime import datetime, timedelta, timezone
from email.utils import parsedate_to_datetime
import hashlib
import html
import json
from pathlib import Path
import re
import sys
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit
from urllib.request import Request, urlopen
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
NEWS = ROOT / "research/news"


def canonical_url(url):
    p = urlsplit(url.strip())
    if p.scheme != "https" or not p.hostname or p.username or p.password:
        raise ValueError("Expected a public HTTPS source URL")
    query = [(k, v) for k, v in parse_qsl(p.query) if not k.lower().startswith("utm_") and k not in {"fbclid", "gclid"}]
    return urlunsplit((p.scheme, p.netloc.lower(), p.path, urlencode(sorted(query)), ""))


def clean(value):
    return " ".join(html.unescape(re.sub(r"<[^>]+>", " ", value or "")).split())


def parse_date(value):
    if not value:
        return None
    try:
        result = parsedate_to_datetime(value)
    except (ValueError, TypeError):
        try:
            result = datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            return None
    if result.tzinfo is None:
        return None
    return result.astimezone(timezone.utc)


def parse_feed(data):
    root = ET.fromstring(data)
    local = lambda tag: tag.rsplit("}", 1)[-1]
    if local(root.tag) not in {"rss", "feed", "RDF"}:
        raise ValueError("Response is not an RSS/Atom feed")
    articles = []
    for entry in root.iter():
        if local(entry.tag) not in {"item", "entry"}:
            continue
        fields = {}
        for child in entry:
            tag = local(child.tag)
            if tag == "link" and child.attrib.get("rel", "alternate") != "alternate":
                continue
            fields[tag] = child.attrib.get("href") or "".join(child.itertext())
        articles.append({"title": clean(fields.get("title")), "url": fields.get("link", ""),
                         "published": fields.get("pubDate") or fields.get("published") or fields.get("date"),
                         "excerpt": clean(fields.get("description") or fields.get("summary") or fields.get("content"))})
    return articles


def fetch(url):
    request = Request(url, headers={"User-Agent": "MoonDAO-Lunar-News/1.0 (+https://github.com/Official-MoonDao/lunar-base-model)"})
    with urlopen(request, timeout=30) as response:
        data = response.read(4_000_001)
        if len(data) > 4_000_000:
            raise ValueError("Feed exceeds 4 MB limit")
        return data


def matches(text, keywords):
    return any(re.search(r"(?<!\w)" + re.escape(word) + r"(?!\w)", text, re.I) for word in keywords)


def make_record(article, source, routes, now):
    url = canonical_url(article["url"])
    host = urlsplit(url).hostname
    if host not in source["article_hosts"]:
        raise ValueError("Article host is outside configured publisher hosts")
    title = article["title"]
    excerpt = " ".join(article["excerpt"].split()[:24])
    text = title + " " + article["excerpt"]
    selected = [route for route in routes if matches(text, route["keywords"])]
    if not selected:
        return None
    identity = hashlib.sha256(url.encode()).hexdigest()[:16]
    fingerprint = hashlib.sha256(json.dumps([title, article["excerpt"], article["published"]], ensure_ascii=False).encode()).hexdigest()
    return {
        "schema_version": "1.0", "id": "lunar-" + identity, "revision": fingerprint[:12],
        "content_sha256": fingerprint, "title": title, "published_at": parse_date(article["published"]).isoformat(),
        "retrieved_at": now.isoformat(), "event_date": None, "supersedes": [],
        "source": {"name": source["name"], "url": url, "feed_url": source["url"], "type": "primary", "evidence_scope": "feed_excerpt"},
        "summary": title,
        "reported_facts": [{"statement": title, "source_url": url, "locator": "RSS/Atom title", "evidence_excerpt": excerpt}],
        "topics": [route["topic"] for route in selected],
        "simulation_actions": [{"kind": "research", "status": "proposed", "rationale": route["rationale"],
                                "next_step": route["next_step"], "affected_paths": route["affected_paths"],
                                "missing_inputs": route["missing_inputs"], "acceptance_criteria": route["acceptance_criteria"],
                                "parameters": []} for route in selected],
        "review": {"status": "candidate", "reviewer": None, "reviewed_at": None,
                   "notes": "Keyword-routed source lead. Read the full article; do not apply to model parameters."}
    }


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def md(text):
    # Source strings remain visible text, not Markdown/HTML instructions or links.
    return re.sub(r"([\\`*_{}\[\]<>#!|])", r"\\\1", " ".join(text.split()))


def render(report, records):
    lines = ["# Lunar base news — " + report["date"], "", "Candidate evidence and proposed research actions; no simulation parameters were changed.", "",
             f"Coverage: **{report['coverage']}**. Window: {report['window_start']} through {report['generated_at']}.", "",
             "## Source coverage", ""]
    for source in report["sources"]:
        lines.append(f"- {md(source['name'])}: {source['status']}; {source.get('entries', 0)} entries; {source.get('undated', 0)} undated; {source.get('rejected', 0)} rejected; {source.get('filtered', 0)} irrelevant. " + md(source.get("error", "")))
    lines += ["", "## New evidence and actions", ""]
    if not records:
        lines += ["No new relevant records were found in the successfully checked feeds. This is not a claim of complete news coverage.", ""]
    for filename, record in records:
        lines += ["### " + md(record["title"]), "", f"Published: {record['published_at']} · **{record['review']['status']}**", "",
                  f"[Source]({record['source']['url']}) · [AI record](../records/{filename})", "",
                  "Source excerpt: " + md(record["reported_facts"][0]["evidence_excerpt"]), ""]
        for action in record["simulation_actions"]:
            lines += ["- **Why it matters:** " + md(action["rationale"]), "- **Next step:** " + md(action["next_step"]),
                      "- **Affected files:** " + ", ".join("`" + p + "`" for p in action["affected_paths"]),
                      "- **Missing inputs:** " + md("; ".join(action["missing_inputs"])),
                      "- **Done when:** " + md(action["acceptance_criteria"]), ""]
    return "\n".join(line.rstrip() for line in lines)


def collect(config, output=NEWS, now=None, fetcher=fetch):
    now = now or datetime.now(timezone.utc)
    start = now - timedelta(days=7)
    existing = {}
    for path in sorted((output / "records").glob("*.json")):
        record = json.loads(path.read_text(encoding="utf-8"))
        existing.setdefault(record["id"], []).append((path.name, record))
    report = {"date": now.date().isoformat(), "generated_at": now.isoformat(), "window_start": start.isoformat(), "coverage": "complete", "sources": [], "records": []}
    pending = []
    seen = set()
    for source in config["feeds"]:
        status = {"name": source["name"], "url": source["url"], "status": "ok", "entries": 0, "undated": 0, "rejected": 0, "filtered": 0}
        try:
            entries = parse_feed(fetcher(source["url"]))
            status["entries"] = len(entries)
            for article in entries:
                date = parse_date(article["published"])
                if date is None:
                    status["undated"] += 1
                    continue
                if not start <= date <= now:
                    continue
                if matches(article["title"], config.get("exclude_title_keywords", [])) or not matches(article["title"] + " " + article["excerpt"], config["lunar_keywords"]):
                    status["filtered"] += 1
                    continue
                try:
                    record = make_record(article, source, config["routes"], now)
                except ValueError:
                    status["rejected"] += 1
                    continue
                if record is None:
                    status["filtered"] += 1
                    continue
                filename = record["id"] + "-" + record["revision"] + ".json"
                if filename in seen or any(r["content_sha256"] == record["content_sha256"] for _, r in existing.get(record["id"], [])):
                    continue
                seen.add(filename)
                previous = existing.get(record["id"], [])
                if previous:
                    record["supersedes"] = [max(previous, key=lambda p: p[1]["retrieved_at"])[0]]
                pending.append((filename, record))
        except Exception as exc:
            status.update(status="failed", error=f"{type(exc).__name__}: {exc}")
            report["coverage"] = "partial"
        report["sources"].append(status)
    if not report["sources"] or all(s["status"] == "failed" for s in report["sources"]):
        raise RuntimeError("All news feeds failed; no briefing was published: " + json.dumps(report["sources"]))
    pending.sort(key=lambda item: (item[1]["published_at"], item[0]), reverse=True)
    for filename, record in pending:
        write_json(output / "records" / filename, record)
    report["records"] = [filename for filename, _ in pending]
    # Each execution has its own immutable report, so reruns never erase prior coverage.
    stamp = now.strftime("%Y-%m-%dT%H%M%S%fZ")
    write_json(output / "briefings" / (stamp + ".json"), report)
    (output / "briefings" / (stamp + ".md")).write_text(render(report, pending), encoding="utf-8")
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=NEWS / "sources.json")
    args = parser.parse_args()
    try:
        report = collect(json.loads(args.config.read_text(encoding="utf-8")))
        print(f"{len(report['records'])} new records; coverage={report['coverage']}")
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
