import copy
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import tempfile
import unittest
from collect import NEWS, collect, canonical_url, make_record, parse_feed, parse_date
from validate import validate_record

NOW = datetime(2026, 9, 11, 12, tzinfo=timezone.utc)
ARTICLE = {"title": "NASA lunar power development", "url": "https://www.nasa.gov/example/", "published": "Tue, 08 Sep 2026 12:00:00 GMT", "excerpt": "New solar array technology for lunar surface operations."}

def rss(article=ARTICLE):
    return f"<rss><channel><item><title>{article['title']}</title><link>{article['url']}</link><pubDate>{article['published']}</pubDate><description>{article['excerpt']}</description></item></channel></rss>".encode()

class NewsTests(unittest.TestCase):
    def setUp(self):
        self.config = json.loads((NEWS / "sources.json").read_text())
        self.config["feeds"] = self.config["feeds"][:1]

    def test_tracking_urls_and_untrusted_scheme(self):
        self.assertEqual(canonical_url(ARTICLE["url"] + "?utm_source=x#part"), ARTICLE["url"])
        with self.assertRaises(ValueError):
            canonical_url("javascript:alert(1)")

    def test_atom_and_missing_date(self):
        entries = parse_feed(b'<feed xmlns="http://www.w3.org/2005/Atom"><entry><title>Lunar power</title><link rel="alternate" href="https://www.nasa.gov/a"/><published>2026-09-08T00:00:00Z</published><summary>Power</summary></entry></feed>')
        self.assertEqual(entries[0]["url"], "https://www.nasa.gov/a")
        self.assertIsNone(parse_date("not a date"))
        self.assertIsNone(parse_date("2026-09-08"))

    def test_rerun_and_revision_preserve_history(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp)
            first = collect(self.config, output, NOW, lambda _: rss())
            again = collect(self.config, output, NOW + timedelta(seconds=1), lambda _: rss())
            self.assertEqual(len(first["records"]), 1)
            self.assertEqual(again["records"], [])
            update = collect(self.config, output, NOW + timedelta(seconds=2), lambda _: rss(dict(ARTICLE, excerpt="Changed power requirements.")))
            record = json.loads((output / "records" / update["records"][0]).read_text())
            self.assertEqual(record["supersedes"], first["records"])
            self.assertEqual(len(list((output / "briefings").glob("*.md"))), 3)

    def test_stale_future_undated_and_unrelated_are_excluded(self):
        for article in [dict(ARTICLE, published="Tue, 01 Sep 2026 12:00:00 GMT"), dict(ARTICLE, published="Sat, 12 Sep 2026 12:00:00 GMT"), dict(ARTICLE, published=""), dict(ARTICLE, title="Galaxy research", excerpt="Stars")]:
            with tempfile.TemporaryDirectory() as tmp:
                self.assertEqual(collect(self.config, Path(tmp), NOW, lambda _: rss(article))["records"], [])

    def test_total_failure_writes_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(RuntimeError):
                collect(self.config, Path(tmp), NOW, lambda _: b"<html>maintenance</html>")
            self.assertEqual(list(Path(tmp).iterdir()), [])

    def test_partial_failure_and_duplicate_feeds(self):
        self.config["feeds"].append(dict(self.config["feeds"][0], url="https://www.nasa.gov/broken"))
        with tempfile.TemporaryDirectory() as tmp:
            report = collect(self.config, Path(tmp), NOW, lambda u: b"invalid" if u.endswith("broken") else rss())
            self.assertEqual(report["coverage"], "partial")
            self.assertEqual(len(report["records"]), 1)
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(len(collect(self.config, Path(tmp), NOW, lambda _: rss())["records"]), 1)

    def test_ceremony_is_not_simulation_news(self):
        with tempfile.TemporaryDirectory() as tmp:
            article = dict(ARTICLE, title="NASA Artemis Accords signing ceremony", excerpt="Lunar landing cooperation")
            report = collect(self.config, Path(tmp), NOW, lambda _: rss(article))
            self.assertEqual(report["records"], [])
            self.assertEqual(report["sources"][0]["filtered"], 1)

    def test_changes_beyond_excerpt_are_versioned(self):
        prefix = "lunar power " * 20
        with tempfile.TemporaryDirectory() as tmp:
            first = collect(self.config, Path(tmp), NOW, lambda _: rss(dict(ARTICLE, excerpt=prefix + "initial")))
            second = collect(self.config, Path(tmp), NOW + timedelta(seconds=1), lambda _: rss(dict(ARTICLE, excerpt=prefix + "revised")))
            self.assertEqual(len(second["records"]), 1)
            self.assertNotEqual(first["records"], second["records"])

    def test_candidate_cannot_masquerade_as_verified(self):
        record = make_record(ARTICLE, self.config["feeds"][0], self.config["routes"], NOW)
        filename = f"{record['id']}-{record['revision']}.json"
        validate_record(record, filename)
        record["review"].update(status="verified", reviewer="test", reviewed_at=NOW.isoformat())
        with self.assertRaises(AssertionError):
            validate_record(record, filename)

    def test_invalid_model_path_and_parameter_contract(self):
        record = make_record(ARTICLE, self.config["feeds"][0], self.config["routes"], NOW)
        filename = f"{record['id']}-{record['revision']}.json"
        bad = copy.deepcopy(record)
        bad["simulation_actions"][0]["affected_paths"] = ["../outside"]
        with self.assertRaises(AssertionError):
            validate_record(bad, filename)
        bad = copy.deepcopy(record)
        bad["simulation_actions"][0]["kind"] = "propose_parameter_change"
        with self.assertRaises(AssertionError):
            validate_record(bad, filename)

if __name__ == "__main__":
    unittest.main()
