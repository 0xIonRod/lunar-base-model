"""External manifest and qualification-report boundary checks; no USD authoring."""
from pathlib import Path
import tempfile
import unittest

from qualification import report_passes
from validate_repository import validate_twin


class ManifestBoundary(unittest.TestCase):
    def diagnostics(self, source: str) -> list[str]:
        with tempfile.TemporaryDirectory() as directory:
            twin = Path(directory)
            (twin / "twin.toml").write_text(source, encoding="utf-8")
            return validate_twin(twin)

    def test_missing_active_manifest_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertTrue(any("Twin manifest" in error for error in validate_twin(Path(directory))))

    def test_malformed_component_binding_is_diagnostic(self):
        errors = self.diagnostics('name="test"\nversion="1"\n[[components]]\nname="part"\nverification=[]\n')
        self.assertTrue(any("part: verification does not name a registered case" in error for error in errors))

    def test_manifest_path_escape_is_rejected(self):
        errors = self.diagnostics('name="test"\nversion="1"\n[usd]\ndefault_scene="../outside.usda"\nscenes=["*.usda"]\n')
        self.assertTrue(any("usd.default_scene: path escapes the Twin" in error for error in errors))

    def test_duplicate_case_is_rejected(self):
        case = '[[verification.cases]]\nname="Package::Case"\nscene="missing.usda"\nscript="missing.rhai"\nverdict_channel="RESULT"\n'
        errors = self.diagnostics('name="test"\nversion="1"\n' + case + case)
        self.assertIn("duplicate verification case: Package::Case", errors)


class NativeReportBoundary(unittest.TestCase):
    def test_only_complete_matching_current_source_passes(self):
        report = {"schema_version": 2, "verification": "Package::Case", "process_exit_code": 0,
                  "process_status": "verdict_produced", "verdict": "pass", "verdict_channel": "RESULT",
                  "source_revision_at_start": 123, "source_revision_at_end": 123,
                  "runner_diagnostic": None, "non_pass_checks": []}
        self.assertTrue(report_passes(report, 0, "Package::Case", "RESULT"))
        for replacement in [{"source_revision_at_end": 124}, {"source_revision_at_start": None},
                            {"source_revision_at_start": True, "source_revision_at_end": True},
                            {"source_revision_at_start": 1, "source_revision_at_end": True},
                            {"process_exit_code": False}, {"schema_version": 2.0},
                            {"process_status": "no_verdict"}, {"verdict_channel": "OTHER"},
                            {"non_pass_checks": [{"verdict": "fail"}]}, {"runner_diagnostic": "failure"}]:
            with self.subTest(replacement=replacement):
                self.assertFalse(report_passes(report | replacement, 0, "Package::Case", "RESULT"))
        self.assertFalse(report_passes(report, 2, "Package::Case", "RESULT"))


if __name__ == "__main__":
    unittest.main()
