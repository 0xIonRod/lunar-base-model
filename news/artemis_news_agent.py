#!/usr/bin/env python3
"""Fetch, filter, and summarize Artemis-related news from RSS feeds.

The agent intentionally uses only the Python standard library so it can run
without an API key or a package installation. It produces a Markdown briefing
and a machine-readable JSON feed for downstream automation.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta, timezone
from email.utils import parsedate_to_datetime
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parent
DEFAULT_CONFIG = ROOT / "artemis_news_agent.json"
DEFAULT_STATE = ROOT / ".artemis_news_state.json"
DEFAULT_MARKDOWN = ROOT / "artemis_news.md"
DEFAULT_JSON = ROOT / "artemis_news.json"


@dataclass(frozen=True)
class Article:
    title: str
    url: str
    source: str
    published: str
    summary: str


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def parse_date(value: str | None) -> datetime:
    if not value:
        return datetime.min.replace(tzinfo=timezone.utc)
    try:
        parsed = parsedate_to_datetime(value)
        return parsed.astimezone(timezone.utc)
    except (TypeError, ValueError, OverflowError):
        try:
            return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(timezone.utc)
        except ValueError:
            return datetime.min.replace(tzinfo=timezone.utc)


def clean_html(value: str) -> str:
    text = re.sub(r"<[^>]+>", " ", value or "")
    return re.sub(r"\s+", " ", text).strip()


def make_tldr(summary: str, limit: int = 320) -> str:
    """Create a short local TL;DR from the publisher-provided summary."""
    text = clean_html(summary)
    if not text:
        return "No publisher summary available."
    sentences = re.split(r"(?<=[.!?])\s+", text)
    tldr = " ".join(sentences[:2]).strip()
    if len(tldr) <= limit:
        return tldr
    return tldr[: limit - 1].rsplit(" ", 1)[0] + "…"


def text_from(element: ET.Element, names: Iterable[str]) -> str:
    for name in names:
        child = element.find(name)
        if child is not None and child.text:
            return child.text.strip()
    return ""


def fetch_feed(feed: dict, timeout: int) -> list[Article]:
    request = urllib.request.Request(
        feed["url"],
        headers={"User-Agent": "ArtemisNewsAgent/1.0 (+local research tool)"},
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        root = ET.fromstring(response.read())

    articles: list[Article] = []
    for item in root.findall(".//item"):
        title = text_from(item, ("title",))
        url = text_from(item, ("link",))
        published = text_from(item, ("pubDate", "published", "updated"))
        summary = clean_html(text_from(item, ("description", "summary", "content")))
        publisher = text_from(item, ("source",))
        if publisher and title.endswith(f" - {publisher}"):
            title = title[: -(len(publisher) + 3)]
        if title and url:
            articles.append(Article(title, url, publisher or feed["name"], published, summary))

    # Atom feeds do not use <item>.
    if not articles:
        atom = "{http://www.w3.org/2005/Atom}"
        for entry in root.findall(f".//{atom}entry"):
            title = text_from(entry, (f"{atom}title",))
            link = entry.find(f"{atom}link")
            url = link.attrib.get("href", "") if link is not None else ""
            published = text_from(entry, (f"{atom}published", f"{atom}updated"))
            summary = clean_html(text_from(entry, (f"{atom}summary", f"{atom}content")))
            if title and url:
                articles.append(Article(title, url, feed["name"], published, summary))
    return articles


def matches(
    article: Article,
    keywords: list[str],
    focus_keywords: list[str] | None = None,
) -> bool:
    haystack = f"{article.title} {article.summary}".lower()
    terms = focus_keywords or keywords
    return any(keyword.lower() in haystack for keyword in terms)


def article_key(article: Article) -> str:
    return re.sub(r"[^a-z0-9]+", " ", article.title.lower()).strip()


def load_json(path: Path, fallback):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError):
        return fallback


def append_articles(lines: list[str], articles: list[Article]) -> None:
    for article in articles:
        date = article.published or "Date unavailable"
        lines.extend(
            [
                f"## [{article.title}]({article.url})",
                f"**{article.source} · {date}**",
                "",
                f"**TL;DR:** {make_tldr(article.summary)}",
                "",
            ]
        )


def write_outputs(articles: list[Article], markdown_path: Path, json_path: Path) -> None:
    generated = utc_now().strftime("%Y-%m-%d %H:%M UTC")
    lines = [
        "# Worldwide Lunar Base News Briefing",
        "",
        f"Generated: {generated}",
        "",
        "This briefing covers the last seven days across lunar-base plans, engineering, habitats and life support, power, communications, robotics, resources, science, and international programs.",
        "",
    ]
    if articles:
        append_articles(lines, articles)
    else:
        lines.append("No matching stories found in the seven-day window.")
    markdown_path.write_text("\n".join(lines), encoding="utf-8")
    json_path.write_text(
        json.dumps(
            {"generated_at": generated, "articles": [asdict(article) for article in articles]},
            indent=2,
        ),
        encoding="utf-8",
    )

def run(args: argparse.Namespace) -> int:
    config = load_json(Path(args.config), {})
    keywords = config.get("keywords", [])
    focus_keywords = config.get("focus_keywords", [])
    feeds = config.get("feeds", [])
    state_path = Path(args.state)
    seen_urls: set[str] = set()
    seen_keys: set[str] = set()
    cutoff = utc_now() - timedelta(hours=args.since_hours)
    fresh: list[Article] = []
    errors: list[str] = []

    for feed in feeds:
        try:
            for article in fetch_feed(feed, args.timeout):
                if article.url in seen_urls or article_key(article) in seen_keys:
                    continue
                published_at = parse_date(article.published)
                if published_at < cutoff or published_at > utc_now():
                    continue
                if not matches(article, keywords, focus_keywords):
                    continue
                seen_urls.add(article.url)
                seen_keys.add(article_key(article))
                fresh.append(article)
        except (OSError, urllib.error.URLError, ET.ParseError) as exc:
            errors.append(f"{feed.get('name', feed.get('url', 'unknown'))}: {exc}")

    fresh.sort(key=lambda item: parse_date(item.published), reverse=True)
    state_path.write_text(json.dumps({"seen_urls": list(seen_urls)}, indent=2), encoding="utf-8")
    write_outputs(fresh, Path(args.markdown), Path(args.json))

    print(f"Worldwide Lunar Base News Agent: {len(fresh)} matching article(s) in the seven-day window")
    if errors:
        for error in errors:
            print(f"warning: {error}", file=sys.stderr)
    return 1 if errors and not fresh else 0

def main() -> int:
    parser = argparse.ArgumentParser(description="Build a worldwide lunar-base news briefing.")
    parser.add_argument("--config", default=DEFAULT_CONFIG)
    parser.add_argument("--state", default=DEFAULT_STATE)
    parser.add_argument("--markdown", default=DEFAULT_MARKDOWN)
    parser.add_argument("--json", default=DEFAULT_JSON)
    parser.add_argument("--since-hours", type=int, default=168)
    parser.add_argument("--timeout", type=int, default=20)
    parser.add_argument("--max-state", type=int, default=1000)
    return run(parser.parse_args())


if __name__ == "__main__":
    raise SystemExit(main())












