// Shared observer helpers for component-owned Twin verification scripts.
//
// SysML remains the normative source for names, counts, and metric datums;
// this module only constructs generic evaluator records and emits the common
// structured verdict shape.  It never edits USD and never supplies defaults.

fn source_text_list(source, qualified_name) {
    let text = sysml_requirements::text(source, qualified_name);
    if text == () || text == "" { return []; }
    let values = [];
    for value in text.split(",") {
        value.trim();
        if value != "" { values.push(value); }
    }
    values
}

// Decode a comma-separated numeric station datum from the SysML source.  The
// caller must check cardinality against the corresponding identity list
// before indexing; an absent list is returned empty and a malformed numeric
// token raises a Rhai error instead of being coerced or guessed.
fn source_number_list(source, qualified_name) {
    let text = sysml_requirements::text(source, qualified_name);
    if text == () || text == "" { return []; }
    let values = [];
    for item in text.split(",") {
        item.trim();
        if item == "" { return []; }
        values.push(parse_float(item));
    }
    values
}

fn exists(id, component, requirement, verification, path, expected_type) {
    #{id: id, component: component, requirement: requirement,
      verification: verification, kind: "exists", path: path,
      expected_type: expected_type, visible: true}
}

fn children(id, component, requirement, verification, path, paths) {
    #{id: id, component: component, requirement: requirement,
      verification: verification, kind: "children", path: path,
      paths: paths, visible: true}
}

fn attribute_check(id, component, requirement, verification, path, attr, expected_attr, tolerance) {
    #{id: id, component: component, requirement: requirement,
      verification: verification, kind: "attribute", path: path,
      attr: attr, expected_attr: expected_attr, tolerance: tolerance}
}

fn attribute_equals(id, component, requirement, verification, path, attr, expected) {
    #{id: id, component: component, requirement: requirement,
      verification: verification, kind: "attribute_equals", path: path,
      attr: attr, expected: expected}
}

fn extent_component(id, component, requirement, verification, path, index,
                    expected_attr, multiplier, tolerance) {
    #{id: id, component: component, requirement: requirement,
      verification: verification, kind: "extent_component", path: path,
      index: index, multiplier: multiplier, expected_attr: expected_attr,
      tolerance: tolerance}
}

fn bounds_component(id, component, requirement, verification, path, index,
                    expected_attr, multiplier, tolerance) {
    #{id: id, component: component, requirement: requirement,
      verification: verification, kind: "bounds_component", path: path,
      index: index, multiplier: multiplier, expected_attr: expected_attr,
      tolerance: tolerance}
}

fn source_list_count(id, component, requirement, verification, list_attr, count_attr) {
    #{id: id, component: component, requirement: requirement,
      verification: verification, kind: "source_list_count",
      path: list_attr, list_attr: list_attr, expected_attr: count_attr}
}

fn coverage(id, component, requirement, verification) {
    #{id: id, component: component, requirement: requirement,
      verification: verification, kind: "coverage"}
}

fn finish(source, checks, title, channel, root, package_name, verification) {
    let result = sysml_requirements::evaluate(source, checks);
    result.metrics = #{clock: clock_snapshot(), root: root,
                       component_package: package_name,
                       verification: verification,
                       separate_component_document: true};
    report_structured_verdict(result, title, channel);
    result
}
