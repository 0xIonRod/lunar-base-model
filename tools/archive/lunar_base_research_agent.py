"""Query-driven, source-backed research agent for the lunar-base project.

The agent is intentionally dependency-free. It searches the local research
register first, then fetches the project's curated primary-source URLs unless
``--offline`` is supplied. Results retain a short excerpt and the source URL
so a human can audit every finding before it is used by the simulator.
"""

from __future__ import annotations

import argparse
import html
import json
import re
import sys
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from typing import Iterable
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parent
DEFAULT_SOURCES = ROOT / "sources.md"
DEFAULT_OUTPUT = ROOT / "lunar_base_research_brief.md"
DEFAULT_JSON = ROOT / "lunar_base_research_results.json"
DEFAULT_TIMEOUT = 20
MAX_DOWNLOAD_BYTES = 2_000_000
USER_AGENT = "LunarBaseResearchAgent/1.0 (+local research tool)"

STOP_WORDS = {
    "a", "an", "and", "are", "as", "at", "be", "by", "for", "from",
    "how", "in", "is", "it", "of", "on", "or", "the", "to", "what",
    "when", "where", "which", "with", "why",
}


@dataclass(frozen=True)
class Source:
    title: str
    url: str
    local: bool = False


@dataclass(frozen=True)
class Finding:
    title: str
    url: str
    source_kind: str
    relevance: float
    confidence: str
    excerpt: str
    matched_terms: list[str]


class PageTextParser(HTMLParser):
    """Extract useful visible text without requiring BeautifulSoup."""

    SKIP_TAGS = {"script", "style", "noscript", "svg", "nav", "footer"}

    def __init__(self) -> None:
        super().__init__()
        self._skip_depth = 0
        self._parts: list[str] = []
        self.title = ""
        self._in_title = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        tag = tag.lower()
        if tag in self.SKIP_TAGS:
            self._skip_depth += 1
        if tag == "title":
            self._in_title = True

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        if tag == "title":
            self._in_title = False
        if tag in self.SKIP_TAGS and self._skip_depth:
            self._skip_depth -= 1

    def handle_data(self, data: str) -> None:
        if self._skip_depth:
            return
        text = re.sub(r"\s+", " ", html.unescape(data)).strip()
        if not text:
            return
        if self._in_title:
            self.title = f"{self.title} {text}".strip()
        self._parts.append(text)

    @property
    def text(self) -> str:
        return " ".join(self._parts)


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def tokenize(value: str) -> list[str]:
    words = re.findall(r"[a-z0-9]+(?:['’-][a-z0-9]+)?", value.lower())
    return [word for word in words if word not in STOP_WORDS and len(word) > 2]


def query_terms(query: str) -> list[str]:
    terms = tokenize(query)
    return list(dict.fromkeys(terms))


def clean_excerpt(text: str, terms: Iterable[str], limit: int = 420) -> str:
    compact = re.sub(r"\s+", " ", text).strip()
    if len(compact) <= limit:
        return compact
    lowered = compact.lower()
    positions = [lowered.find(term.lower()) for term in terms]
    positions = [position for position in positions if position >= 0]
    start = max(0, (min(positions) if positions else 0) - 120)
    excerpt = compact[start : start + limit]
    if start > 0:
        excerpt = "…" + excerpt
    if start + limit < len(compact):
        excerpt += "…"
    return excerpt


def source_kind(url: str) -> str:
    host = urlparse(url).netloc.lower()
    primary_hosts = ("nasa.gov", "esa.int", "jaxa.jp", "isro.gov.in", "cnsa.gov.cn")
    provider_hosts = ("fireflyspace.com", "astrobotic.com", "intuitivemachines.com",
                     "blueorigin.com", "ispace-inc.com", "jpl.nasa.gov")
    if any(host == domain or host.endswith("." + domain) for domain in primary_hosts):
        return "primary_agency"
    if any(host == domain or host.endswith("." + domain) for domain in provider_hosts):
        return "primary_provider"
    return "secondary_or_other"


def confidence_for(kind: str, relevance: float) -> str:
    if kind in {"primary_agency", "primary_provider"} and relevance >= 0.35:
        return "high"
    if relevance >= 0.2:
        return "medium"
    return "low"


def load_local_documents() -> list[Source]:
    documents: list[Source] = []
    for path in sorted(ROOT.glob("*.md")):
        if path.name == "sources.md":
            continue
        documents.append(Source(path.stem.replace("-", " ").title(), str(path), True))
    return documents


def load_curated_sources(path: Path) -> list[Source]:
    if not path.exists():
        return []
    sources: list[Source] = []
    seen: set[str] = set()
    text = path.read_text(encoding="utf-8")
    for title, url in re.findall(r"\[([^\]]+)\]\((https?://[^)]+)\)", text):
        if url in seen:
            continue
        seen.add(url)
        sources.append(Source(title.strip(), url))
    return sources


def read_source(source: Source, timeout: int) -> tuple[str, str]:
    if source.local:
        path = Path(source.url)
        return source.title, path.read_text(encoding="utf-8")

    request = urllib.request.Request(source.url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        content = response.read(MAX_DOWNLOAD_BYTES + 1)
    if len(content) > MAX_DOWNLOAD_BYTES:
        content = content[:MAX_DOWNLOAD_BYTES]
    decoded = content.decode("utf-8", errors="replace")
    parser = PageTextParser()
    try:
        parser.feed(decoded)
        return parser.title or source.title, parser.text
    except Exception as exc:
        raise ValueError(f"could not parse page: {exc}") from exc


def score_document(text: str, terms: list[str]) -> tuple[float, list[str]]:
    lowered = text.lower()
    matched = [term for term in terms if term in lowered]
    if not terms:
        return 0.0, []
    breadth = len(matched) / len(terms)
    repetition = sum(min(3, lowered.count(term)) for term in matched) / (3 * len(terms))
    return round(min(1.0, 0.75 * breadth + 0.25 * repetition), 3), matched


def search_sources(query: str, sources: list[Source], timeout: int) -> tuple[list[Finding], list[str]]:
    terms = query_terms(query)
    findings: list[Finding] = []
    warnings: list[str] = []
    for source in sources:
        try:
            title, text = read_source(source, timeout)
        except (OSError, UnicodeError, urllib.error.URLError, ValueError) as exc:
            warnings.append(f"{source.title}: {exc}")
            continue
        relevance, matched = score_document(f"{title} {text}", terms)
        if not matched:
            continue
        kind = "local_register" if source.local else source_kind(source.url)
        findings.append(
            Finding(
                title=title,
                url=source.url,
                source_kind=kind,
                relevance=relevance,
                confidence=("context" if source.local else confidence_for(kind, relevance)),
                excerpt=clean_excerpt(text, matched),
                matched_terms=matched,
            )
        )
    findings.sort(key=lambda finding: (finding.relevance, finding.source_kind != "local_register"), reverse=True)
    return findings, warnings


def write_markdown(query: str, findings: list[Finding], warnings: list[str], path: Path) -> None:
    generated = now_utc().strftime("%Y-%m-%d %H:%M UTC")
    lines = [
        "# Lunar Base Research Brief",
        "",
        f"**Question:** {query}",
        f"**Generated:** {generated}",
        "",
        "This brief is a research aid, not an automatic change to the simulator. "
        "Review the cited source before promoting a finding into the mission register.",
        "",
    ]
    if findings:
        for index, finding in enumerate(findings, 1):
            lines.extend([
                f"## {index}. {finding.title}",
                f"**Evidence:** {finding.confidence} · **Relevance:** {finding.relevance} · **Type:** {finding.source_kind}",
                "",
                finding.excerpt,
                "",
                f"Source: [{finding.url}]({finding.url})",
                f"Matched terms: {', '.join(finding.matched_terms)}",
                "",
            ])
    else:
        lines.extend(["No matching evidence was found in the curated register or sources.", ""])
    if warnings:
        lines.extend(["## Retrieval warnings", ""])
        lines.extend(f"- {warning}" for warning in warnings)
        lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def write_json(query: str, findings: list[Finding], warnings: list[str], path: Path) -> None:
    payload = {
        "query": query,
        "generated_at": now_utc().isoformat(),
        "source_policy": "Prefer current primary agency, provider, or mission-owner pages.",
        "findings": [asdict(finding) for finding in findings],
        "warnings": warnings,
    }
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Research a lunar-base question with auditable sources.")
    parser.add_argument("query", help="Question or topic, for example: 'polar water ice and rover operations'")
    parser.add_argument("--offline", action="store_true", help="Use only the local research register")
    parser.add_argument("--sources", default=str(DEFAULT_SOURCES), help="Markdown file containing curated source links")
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT)
    parser.add_argument("--limit", type=int, default=12, help="Maximum findings in the output")
    parser.add_argument("--markdown", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--json", default=str(DEFAULT_JSON))
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    sources = load_local_documents()
    if not args.offline:
        sources.extend(load_curated_sources(Path(args.sources)))
    findings, warnings = search_sources(args.query, sources, max(1, args.timeout))
    findings = findings[: max(1, args.limit)]
    write_markdown(args.query, findings, warnings, Path(args.markdown))
    write_json(args.query, findings, warnings, Path(args.json))
    print(f"Lunar Base Research Agent: {len(findings)} finding(s) for '{args.query}'")
    if warnings:
        print(f"warning: {len(warnings)} source(s) could not be read", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
