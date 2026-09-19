// Shared observer helpers for component-owned Twin verification scripts.
//
// SysML remains the normative source for typed identities, counts, and metric datums;
// this module only constructs generic evaluator records and emits the common
// structured verdict shape.  It never edits USD and never supplies defaults.

fn source_text_list(source, qualified_name) {
    let values = sysml_requirements::native_value(source, qualified_name);
    if values == () || type_of(values) != "array" { return []; }
    let identifiers = [];
    for value in values {
        if type_of(value) == "EnumValue" {
            identifiers.push(value.literal);
        } else if type_of(value) == "string" {
            identifiers.push(value);
        } else {
            return [];
        }
    }
    identifiers
}

fn source_enum_identifiers(source, qualified_name) {
    let values = sysml_requirements::native_value(source, qualified_name);
    if values == () || type_of(values) != "array" { return []; }
    let identifiers = [];
    for value in values {
        if type_of(value) != "EnumValue" { return []; }
        identifiers.push(value.literal);
    }
    identifiers
}

fn source_position_list(source, qualified_name) {
    let values = sysml_requirements::native_value(source, qualified_name);
    if values == () || type_of(values) != "array" { return []; }
    for value in values { if type_of(value) != "Vec3" { return []; } }
    values
}

// Read the typed Real/Integer vector from the SysML projection. The values
// remain numeric throughout; no CSV parsing or string coercion is involved.
// Callers must check cardinality against the corresponding typed identity
// collection before indexing.
fn source_number_list(source, qualified_name) {
    let typed = sysml_requirements::vector(source, qualified_name);
    if typed == () { return []; }
    typed
}

// The SysML registry validates both qualified and short identities.  Store
// only the stable short form in each repeated check record so large component
// check arrays do not exhaust Rhai's bounded value budget with duplicated
// package prefixes.
fn _short_identity(name) {
    if name == () { return (); }
    let parts = name.split("::");
    if parts.len() == 0 { return name; }
    parts[parts.len() - 1]
}

// Twin requirement usages use compact local names (`gll001`) in repeated
// check tables. The separate SysML evidence catalog uses the authored ID
// form (`GLL-001`); derive that lookup key once at the source boundary.
fn _evidence_id(requirement) {
    if requirement == () || requirement == "" { return (); }
    let prefixes = [
        ["fcc", "FCC"], ["fgv", "FGV"], ["fsp", "FSP"], ["fsr", "FSR"],
        ["fww", "FWW"], ["gbc", "GBC"], ["ges", "GES"], ["gll", "GLL"],
        ["glr", "GLR"], ["gpp", "GPP"], ["gpt", "GPT"], ["grr", "GRR"],
        ["gsa", "GSA"], ["gvc", "GVC"], ["grv", "GRV"], ["mb", "MB"]
    ];
    for prefix in prefixes {
        if requirement.starts_with(prefix[0]) {
            return prefix[1] + "-" + requirement.sub_string(prefix[0].len());
        }
    }
    ()
}

fn _source_evidence(source, checks) {
    let records = [];
    let failures = [];
    let seen = #{};
    for check in checks {
        if check == () || check.requirement == () { continue; }
        let local = _short_identity(check.requirement);
        if seen[local] == true { continue; }
        seen[local] = true;
        let evidence_id = _evidence_id(local);
        if evidence_id == () { continue; }
        let selected = sysml_requirements::provenance(source, evidence_id);
        if selected.ok == true {
            records.push(selected.evidence);
        } else {
            failures.push(#{requirement: local, evidence_id: evidence_id,
                error: selected.error});
        }
    }
    #{records: records, failures: failures}
}

fn exists(id, component, requirement, verification, path, expected_type) {
    #{id: id, component: component, requirement: _short_identity(requirement),
      verification: _short_identity(verification), kind: "exists", path: path,
      expected_type: expected_type, visible: true}
}

fn children(id, component, requirement, verification, path, paths) {
    #{id: id, component: component, requirement: _short_identity(requirement),
      verification: _short_identity(verification), kind: "children", path: path,
      paths: paths, visible: true}
}

fn attribute_check(id, component, requirement, verification, path, attr, expected_attr, tolerance) {
    #{id: id, component: component, requirement: _short_identity(requirement),
      verification: _short_identity(verification), kind: "attribute", path: path,
      attr: attr, expected_attr: expected_attr, tolerance: tolerance}
}

fn attribute_equals(id, component, requirement, verification, path, attr, expected) {
    #{id: id, component: component, requirement: _short_identity(requirement),
      verification: _short_identity(verification), kind: "attribute_equals", path: path,
      attr: attr, expected: expected}
}

fn extent_component(id, component, requirement, verification, path, index,
                    expected_attr, multiplier, tolerance) {
    #{id: id, component: component, requirement: _short_identity(requirement),
      verification: _short_identity(verification), kind: "extent_component", path: path,
      index: index, multiplier: multiplier, expected_attr: expected_attr,
      tolerance: tolerance}
}

fn bounds_component(id, component, requirement, verification, path, index,
                    expected_attr, multiplier, tolerance) {
    #{id: id, component: component, requirement: _short_identity(requirement),
      verification: _short_identity(verification), kind: "bounds_component", path: path,
      index: index, multiplier: multiplier, expected_attr: expected_attr,
      tolerance: tolerance}
}

fn source_list_count(id, component, requirement, verification, list_attr, count_attr) {
    #{id: id, component: component, requirement: _short_identity(requirement),
      verification: _short_identity(verification), kind: "source_list_count",
      path: list_attr, list_attr: list_attr, expected_attr: count_attr}
}

fn coverage(id, component, requirement, verification) {
    #{id: id, component: component, requirement: _short_identity(requirement),
      verification: _short_identity(verification), kind: "coverage"}
}

// Build a pathless source-derived assertion for the shared SysML evaluator.
// Component observers use this for interface equations and other checks that
// combine typed requirements without pretending there is a single USD prim.
fn assertion(id, component, requirement, verification, ok, error, actual, expected) {
    #{id: id, component: component, requirement: _short_identity(requirement),
      verification: _short_identity(verification), kind: "assert", ok: ok,
      error: if ok { "" } else { error }, actual: actual, expected: expected}
}

fn finish(source, checks, title, channel, root, package_name, verification) {
    let result = if checks.len() > 64 {
        sysml_requirements::evaluate_stream(source, checks, channel, title)
    } else {
        sysml_requirements::evaluate(source, checks)
    };
    let source_evidence = _source_evidence(source, checks);
    result.source_evidence = source_evidence.records;
    result.source_evidence_failures = source_evidence.failures;
    if source_evidence.failures.len() > 0 {
        result.ok = false;
        if result.failures == () { result.failures = []; }
        for failure in source_evidence.failures { result.failures.push(failure); }
        result.failure_count = if result.failure_count == () { 0 } else { result.failure_count };
        result.failure_count += source_evidence.failures.len();
    }
    result.metrics = #{clock: clock_snapshot(), root: root,
                       component_package: package_name,
                       // `evaluate` canonicalizes this identity from the
                       // mounted SysML report.  Keep metrics and evidence on
                       // that same source-backed name instead of preserving a
                       // duplicated package prefix from the observer.
                       verification: result.verification,
                       separate_component_document: true};
    report_structured_verdict(result, title, channel);
    result
}
