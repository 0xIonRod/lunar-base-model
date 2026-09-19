#!/usr/bin/env bash
set -euo pipefail

# Authoring-time gate for the separate typed SysML provenance catalog.
#
# The native bridge can resolve qualified source fields efficiently, but the
# current Rhai surface intentionally does not expose an unbounded catalog
# enumeration. This small read-only gate therefore checks the source files at
# authoring/CI time. It compares requirement IDs from the owning SysML docs
# with the typed RequirementEvidence usages and verifies that every evidence
# usage has all four required fields.

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
requirements_dir="$script_dir/../requirements"
catalog="$requirements_dir/griffin_requirement_sources.sysml"

if [[ ! -f "$catalog" ]]; then
    printf 'ERROR: missing typed provenance catalog: %s\n' "$catalog" >&2
    exit 1
fi

requirement_ids=$(
    rg -o 'doc /\* [A-Z][A-Z0-9]*-[0-9]+' \
        "$requirements_dir"/griffin_*.sysml \
        "$requirements_dir"/flip_*.sysml \
        "$requirements_dir"/moonbase_project_requirements.sysml \
        --glob '!griffin_requirement_sources.sysml' \
        | sed -E 's/.*doc \/\* //' \
        | sort -u
)

catalog_ids=$(
    rg -o 'attribute requirementId = "[A-Z][A-Z0-9]*-[0-9]+";' "$catalog" \
        | sed -E 's/.*"([A-Z][A-Z0-9]*-[0-9]+)".*/\1/' \
        | sort -u
)

missing_ids=$(comm -23 <(printf '%s\n' "$requirement_ids") <(printf '%s\n' "$catalog_ids"))
extra_ids=$(comm -13 <(printf '%s\n' "$requirement_ids") <(printf '%s\n' "$catalog_ids"))

evidence_count=$(rg -c '^    part evidence_[a-z0-9_]+ : RequirementEvidence \{' "$catalog" || true)
id_count=$(rg -c '^        attribute requirementId = ' "$catalog" || true)
qualified_count=$(rg -c '^        attribute qualifiedRequirement = ' "$catalog" || true)
source_count=$(rg -c '^        attribute sourceReference = ' "$catalog" || true)
rationale_count=$(rg -c '^        attribute rationale = ' "$catalog" || true)
catalog_unique_count=$(printf '%s\n' "$catalog_ids" | sed '/^$/d' | wc -l)
empty_fields=$(rg -n '^        attribute (sourceReference|rationale) = "";' "$catalog" || true)

failed=0
if [[ -n "$missing_ids" ]]; then
    printf 'ERROR: requirement IDs missing from typed catalog:\n%s\n' "$missing_ids" >&2
    failed=1
fi
if [[ -n "$extra_ids" ]]; then
    printf 'ERROR: typed catalog contains IDs without an owning requirement:\n%s\n' "$extra_ids" >&2
    failed=1
fi
if [[ "$evidence_count" -eq 0 || "$evidence_count" -ne "$id_count" \
    || "$evidence_count" -ne "$qualified_count" \
    || "$evidence_count" -ne "$source_count" \
    || "$evidence_count" -ne "$rationale_count" \
    || "$evidence_count" -ne "$catalog_unique_count" ]]; then
    printf 'ERROR: typed catalog field counts disagree: evidence=%s id=%s qualified=%s source=%s rationale=%s\n' \
        "$evidence_count" "$id_count" "$qualified_count" "$source_count" "$rationale_count" >&2
    failed=1
fi
if [[ -n "$empty_fields" ]]; then
    printf 'ERROR: typed catalog contains an empty source or rationale:\n%s\n' "$empty_fields" >&2
    failed=1
fi

if [[ "$failed" -ne 0 ]]; then
    exit 1
fi

printf 'OK: typed Griffin provenance catalog covers %s requirement IDs with %s complete evidence records.\n' \
    "$(printf '%s\n' "$requirement_ids" | sed '/^$/d' | wc -l)" "$evidence_count"
