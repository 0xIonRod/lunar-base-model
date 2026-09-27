#!/usr/bin/env bash
set -euo pipefail

# Check the authored shape of the Twin's typed evidence catalog. SysML parsing
# and reference resolution remain the responsibility of the production parser;
# this gate checks coverage and rejects legacy string-backed evidence fields.
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
requirements_dir="$script_dir/../requirements"
python3 - "$requirements_dir" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
catalog_path = root / "griffin_requirement_sources.sysml"
if not catalog_path.is_file():
    raise SystemExit(f"ERROR: missing typed provenance catalog: {catalog_path}")
catalog = catalog_path.read_text()


def require(condition, message):
    if not condition:
        raise SystemExit("ERROR: " + message)


require(re.search(r"enum\s+def\s+EvidenceSourceRole\s*\{([^}]+)\}", catalog),
        "EvidenceSourceRole enum definition is missing")
role_match = re.search(r"enum\s+def\s+EvidenceSourceRole\s*\{([^}]+)\}", catalog)
roles = set(re.findall(r"\b[A-Z][A-Za-z0-9_]*\b", role_match.group(1)))
require(roles, "EvidenceSourceRole has no literals")

source_type = re.search(r"part\s+def\s+EvidenceSource\s*\{([^{}]*)\}", catalog)
evidence_type = re.search(r"part\s+def\s+RequirementEvidence\s*\{([^{}]*)\}", catalog)
require(source_type is not None, "typed EvidenceSource definition is missing")
require(evidence_type is not None, "typed RequirementEvidence definition is missing")
require(re.search(r"attribute\s+role\s*:\s*EvidenceSourceRole\s*;", source_type.group(1)),
        "EvidenceSource.role must use EvidenceSourceRole")
require(re.search(r"attribute\s+locator\s*:\s*SourceLocator\s*;", source_type.group(1)),
        "EvidenceSource.locator must use SourceLocator")
require(re.search(r"ref\s+targetRequirement\s*:\s*SysML::RequirementUsage\s*;", evidence_type.group(1)),
        "RequirementEvidence.targetRequirement must be a SysML requirement reference")
require(re.search(r"ref\s+part\s+sources\s*:\s*EvidenceSource\[0\.\.\*\]\s*;", evidence_type.group(1)),
        "RequirementEvidence.sources must be a typed EvidenceSource collection")

for legacy in ("requirementId", "qualifiedRequirement", "sourceReference", "rationale"):
    require(not re.search(rf"\b{legacy}\b", catalog),
            f"legacy duplicate evidence field remains: {legacy}")

source_parts = {}
for match in re.finditer(r"\bpart\s+(source_[A-Za-z0-9_]+)\s*:\s*EvidenceSource\s*\{([^{}]*)\}", catalog):
    name, body = match.groups()
    require(name not in source_parts, f"duplicate source element: {name}")
    role_values = re.findall(r"attribute\s+role\s*:\s*EvidenceSourceRole\s*=\s*\"([^\"]+)\"\s*;", body)
    locators = re.findall(r"attribute\s+locator\s*:\s*SourceLocator\s*=\s*\"([^\"]+)\"\s*;", body)
    require(len(role_values) == 1 and role_values[0] in roles,
            f"{name} must have exactly one valid typed role")
    require(len(locators) == 1 and ";" not in locators[0],
            f"{name} must have exactly one atomic SourceLocator")
    source_parts[name] = locators[0]
require(source_parts, "catalog contains no EvidenceSource instances")

requirement_targets = {}
for path in sorted(root.glob("*.sysml")):
    if path == catalog_path:
        continue
    text = path.read_text()
    package_match = re.search(r"\bpackage\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{", text)
    if not package_match:
        continue
    package = package_match.group(1)
    for short_name, usage_name in re.findall(
        r"\brequirement\s+<'([A-Z][A-Z0-9]*-[0-9]+)'>\s+([A-Za-z_][A-Za-z0-9_]*)\s*:", text
    ):
        target = f"{package}::{usage_name}"
        require(target not in requirement_targets,
                f"duplicate requirement target declaration: {target}")
        requirement_targets[target] = short_name
require(requirement_targets, "no standard SysML requirement short names found")

evidence_targets = {}
evidence_count = 0
for match in re.finditer(r"\bpart\s+(evidence_[A-Za-z0-9_]+)\s*:\s*RequirementEvidence\s*\{([^{}]*)\}", catalog):
    evidence_name, body = match.groups()
    evidence_count += 1
    targets = re.findall(r"\bref\s+targetRequirement\s*=\s*([A-Za-z_][A-Za-z0-9_:]*)\s*;", body)
    require(len(targets) == 1, f"{evidence_name} must have one typed targetRequirement reference")
    target = targets[0]
    require(target in requirement_targets,
            f"{evidence_name} points to undeclared requirement usage {target}")
    require(target not in evidence_targets,
            f"requirement {target} has multiple evidence records")
    evidence_targets[target] = evidence_name
    source_lists = re.findall(r"\bref\s+sources\s*=\s*\(([^)]*)\)\s*;", body)
    require(len(source_lists) <= 1, f"{evidence_name} has multiple source collections")
    if source_lists:
        names = [name.strip() for name in source_lists[0].split(",") if name.strip()]
        require(names, f"{evidence_name} has an empty source collection")
        for name in names:
            require(name in source_parts,
                    f"{evidence_name} points to undeclared source element {name}")

missing = sorted(set(requirement_targets) - set(evidence_targets))
extra = sorted(set(evidence_targets) - set(requirement_targets))
require(not missing, "requirements without evidence records: " + ", ".join(missing))
require(not extra, "evidence records without requirements: " + ", ".join(extra))
require(evidence_count == len(requirement_targets),
        f"evidence count {evidence_count} does not match requirement count {len(requirement_targets)}")
print(f"OK: {len(requirement_targets)} typed requirement targets, {evidence_count} evidence records, {len(source_parts)} typed source elements, {len(roles)} source roles")
PY
