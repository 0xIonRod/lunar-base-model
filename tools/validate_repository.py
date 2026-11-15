"""Check Twin manifest structure and package-local file references.

This check does not parse USD, SysML, Modelica or Rhai. Production native
preflight and scene verdicts are run by qualification.py.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys
import tomllib

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_TWIN = ROOT / "twins/astrobotic-griffin-1"


def validate_twin(twin: Path) -> list[str]:
    twin = twin.resolve()
    errors: list[str] = []

    def local_path(value: object, label: str, *, directory: bool = False) -> Path | None:
        if not isinstance(value, str) or not value or Path(value).is_absolute():
            errors.append(f"{label}: expected a non-empty Twin-relative path")
            return None
        try:
            path = (twin / value).resolve()
        except (OSError, RuntimeError) as error:
            errors.append(f"{label}: cannot resolve {value}: {error}")
            return None
        if not path.is_relative_to(twin):
            errors.append(f"{label}: path escapes the Twin: {value}")
            return None
        exists = path.is_dir() if directory else path.is_file()
        if not exists:
            errors.append(f"{label}: missing {'directory' if directory else 'file'}: {value}")
        return path

    manifest_path = local_path("twin.toml", "Twin manifest")
    if manifest_path is None or not manifest_path.is_file():
        return errors
    try:
        manifest = tomllib.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, tomllib.TOMLDecodeError) as error:
        return [f"twin.toml: {error}"]
    for name in ("name", "version"):
        if not isinstance(manifest.get(name), str) or not manifest[name].strip():
            errors.append(f"twin.toml: {name} must be a non-empty string")
    for required in ("README.md", "Assets.toml"):
        local_path(required, "Twin package")
    assets = twin / "Assets.toml"
    if assets.is_file():
        try:
            tomllib.loads(assets.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, tomllib.TOMLDecodeError) as error:
            errors.append(f"Assets.toml: {error}")

    usd = manifest.get("usd")
    if not isinstance(usd, dict):
        errors.append("twin.toml: [usd] is required")
        usd = {}
    default_scene = local_path(usd.get("default_scene"), "usd.default_scene")
    patterns = usd.get("scenes")
    indexed_scenes: set[Path] = set()
    if not isinstance(patterns, list) or not patterns:
        errors.append("usd.scenes: expected a non-empty array of Twin-relative patterns")
    else:
        for pattern in patterns:
            if not isinstance(pattern, str) or not pattern or Path(pattern).is_absolute() or ".." in Path(pattern).parts:
                errors.append(f"usd.scenes: invalid Twin-relative pattern: {pattern!r}")
                continue
            try:
                for path in twin.glob(pattern):
                    if path.is_file():
                        resolved = path.resolve()
                        if resolved.is_relative_to(twin):
                            indexed_scenes.add(resolved)
                        else:
                            errors.append(f"usd.scenes: indexed scene escapes the Twin: {path.relative_to(twin)}")
            except (OSError, RuntimeError, ValueError) as error:
                errors.append(f"usd.scenes: cannot resolve pattern {pattern!r}: {error}")
    if default_scene is not None and default_scene not in indexed_scenes:
        errors.append("usd.default_scene is not included by usd.scenes")
    sysml = manifest.get("sysml")
    if not isinstance(sysml, dict):
        errors.append("twin.toml: [sysml] is required")
    else:
        local_path(sysml.get("root"), "sysml.root")
        roots = sysml.get("paths", [])
        if not isinstance(roots, list):
            errors.append("sysml.paths: expected an array")
        else:
            for root in roots:
                local_path(root, "sysml.paths", directory=True)

    verification = manifest.get("verification", {})
    cases = verification.get("cases", []) if isinstance(verification, dict) else []
    names: set[str] = set()
    if not isinstance(cases, list) or not cases:
        errors.append("verification.cases: expected a non-empty array")
        cases = []
    for case in cases:
        if not isinstance(case, dict):
            errors.append("verification.cases: each entry must be a table")
            continue
        name = case.get("name")
        if not isinstance(name, str) or not name:
            errors.append("verification case: missing name")
            continue
        if name in names:
            errors.append(f"duplicate verification case: {name}")
        names.add(name)
        scene = local_path(case.get("scene"), f"{name}.scene")
        local_path(case.get("script"), f"{name}.script")
        if scene is not None and scene not in indexed_scenes:
            errors.append(f"{name}.scene is not included by usd.scenes")
        if not isinstance(case.get("verdict_channel"), str) or not case["verdict_channel"]:
            errors.append(f"{name}: explicit verdict_channel is required")
    components = manifest.get("components", [])
    component_names: set[str] = set()
    if not isinstance(components, list):
        errors.append("components: expected an array")
        components = []
    for component in components:
        if not isinstance(component, dict):
            errors.append("components: each entry must be a table")
            continue
        name = component.get("name")
        if not isinstance(name, str) or not name:
            errors.append("component: missing name")
            continue
        if name in component_names:
            errors.append(f"duplicate component: {name}")
        component_names.add(name)
        local_path(component.get("requirements"), f"{name}.requirements")
        verification_name = component.get("verification")
        if not isinstance(verification_name, str) or verification_name not in names:
            errors.append(f"{name}: verification does not name a registered case")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--twin", type=Path, default=DEFAULT_TWIN)
    args = parser.parse_args()
    errors = validate_twin(args.twin)
    for error in errors:
        print(f"FAIL: {error}")
    if errors:
        return 1
    print("OK: Twin TOML structure and package-local manifest references; native preflight and runtime not evaluated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
