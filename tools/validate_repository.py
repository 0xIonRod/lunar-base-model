"""Lightweight structural checks for the NASA lunar-base model repository."""

from __future__ import annotations

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    errors: list[str] = []
    required = [
        ROOT / "README.md",
        ROOT / "research" / "missions.md",
        ROOT / "research" / "vehicles.md",
        ROOT / "missions" / "mission-001" / "mission.yaml",
        ROOT / "missions" / "mission-001" / "scene.usda",
    ]
    for path in required:
        if not path.exists():
            errors.append(f"missing required file: {path.relative_to(ROOT)}")

    forbidden_terms = ("luna" + "2", "Luna " + "2", "LUNA" + "2")
    for path in ROOT.rglob("*"):
        if not path.is_file() or ".git" in path.parts:
            continue
        if "archive" in path.parts or path.resolve() == Path(__file__).resolve():
            continue
        if path.suffix.lower() not in {".md", ".yaml", ".yml", ".toml", ".usda", ".py"}:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if any(term in text for term in forbidden_terms):
            errors.append(f"obsolete legacy reference: {path.relative_to(ROOT)}")

    scenarios = sorted((ROOT / "scenarios").glob("*.yaml"))
    if len(scenarios) != 5:
        errors.append(f"expected 5 scenario files, found {len(scenarios)}")

    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1

    print("OK: repository structure, mission twin, scenarios, and obsolete-reference checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())



