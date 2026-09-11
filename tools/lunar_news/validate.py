"""Validate news contracts and repository/evidence links."""
import json
from pathlib import Path
import sys
from jsonschema import Draft202012Validator, FormatChecker
from collect import ROOT, NEWS, canonical_url, parse_date


def validate_record(record, filename, root=ROOT, news=NEWS):
    schema = json.loads((news / "schema.json").read_text(encoding="utf-8"))
    Draft202012Validator(schema, format_checker=FormatChecker()).validate(record)
    assert filename == f"{record['id']}-{record['revision']}.json", "Filename does not match record identity"
    assert record["content_sha256"].startswith(record["revision"]), "Revision mismatch"
    assert canonical_url(record["source"]["url"]) == record["source"]["url"], "Noncanonical source URL"
    assert parse_date(record["published_at"]) <= parse_date(record["retrieved_at"]), "Publication after retrieval"
    if record["review"]["status"] == "verified":
        assert record["review"]["reviewer"] and record["review"]["reviewed_at"], "Verified record lacks review provenance"
        assert record["source"]["evidence_scope"] != "feed_excerpt", "Feed-only evidence cannot be verified"
    for previous in record["supersedes"]:
        assert previous != filename, "Self supersession"
        prior = json.loads((news / "records" / previous).read_text(encoding="utf-8"))
        assert parse_date(prior["retrieved_at"]) < parse_date(record["retrieved_at"]), "Supersession must point backward in time"
    for action in record["simulation_actions"]:
        for relative in action["affected_paths"]:
            path = (root / relative).resolve()
            assert path.is_relative_to(root.resolve()) and path.is_file(), f"Invalid target: {relative}"
        if action["kind"] == "propose_parameter_change":
            assert action["parameters"], "Parameter proposal lacks parameters"
        for parameter in action["parameters"]:
            assert parameter["value"] is not None or parameter["basis"] == "unknown", "Missing value must be unknown"
            assert parameter["basis"] != "unknown" or parameter["value"] is None, "Unknown parameter cannot have a value"


def main():
    count = 0
    for path in sorted((NEWS / "records").glob("*.json")):
        validate_record(json.loads(path.read_text(encoding="utf-8")), path.name)
        count += 1
    for path in (NEWS / "briefings").glob("*.json"):
        report = json.loads(path.read_text(encoding="utf-8"))
        assert report["coverage"] in {"complete", "partial"}
        assert report["sources"] and any(s["status"] == "ok" for s in report["sources"])
        assert (report["coverage"] == "partial") == any(s["status"] == "failed" for s in report["sources"])
        assert path.with_suffix(".md").is_file(), "Missing readable briefing"
        for filename in report["records"]:
            assert Path(filename).name == filename and (NEWS / "records" / filename).is_file(), "Broken briefing record link"
    print(f"OK: {count} news records, source contracts, model targets, and briefings")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        sys.exit(1)
