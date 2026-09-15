// Standalone Griffin main-propulsion visual verification.  Thrust and
// collision remain owned by the flight model; this observer checks only the
// replaceable bell/throat presentation components.

const PACKAGE = "GriffinPropulsionRequirements";
const VERIFICATION = "GriffinPropulsionRequirements::Verify_GriffinPropulsionRequirements";

fn own(name) { PACKAGE + "::GriffinMainPropulsionAssembly::" + name }
fn parent(name) { "GriffinLanderRequirements::GriffinLanderComponent::" + name }

fn position(id, path, index, expected) {
    #{id: id, component: "engine", requirement: "GriffinPropulsionRequirements::gpp005",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: 0.002}
}

fn on_start(me) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let names_source = sysml_requirements::text(source, own("namesSource"));
    let count_source = sysml_requirements::text(source, own("countSource"));
    let names = component_requirements::source_text_list(source, names_source);
    let xs = component_requirements::source_number_list(source, parent("engineStationX"));
    let ys = component_requirements::source_number_list(source, parent("engineStationY"));
    let zs = component_requirements::source_number_list(source, parent("engineStationZ"));
    let checks = [];
    checks.push(component_requirements::source_list_count("GPP-001-count", "propulsion", "GriffinPropulsionRequirements::gpp001", VERIFICATION, names_source, count_source));
    for axis in ["engineStationX", "engineStationY", "engineStationZ"] {
        checks.push(component_requirements::source_list_count("GPP-005-" + axis,
            "engine", "GriffinPropulsionRequirements::gpp005", VERIFICATION,
            parent(axis), count_source));
    }
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        checks.push(component_requirements::exists("GPP-001-" + name, "engine", "GriffinPropulsionRequirements::gpp001", VERIFICATION, path, "Xform"));
        checks.push(component_requirements::children("GPP-002-" + name, "engine", "GriffinPropulsionRequirements::gpp002", VERIFICATION, path,
            [path + "/Bell", path + "/Throat"]));
        checks.push(component_requirements::attribute_equals("GPP-002-" + name + "-purpose", "engine", "GriffinPropulsionRequirements::gpp002", VERIFICATION,
            path + "/Bell", "purpose", "render"));
        if xs.len() == names.len() && ys.len() == names.len() && zs.len() == names.len() {
            checks.push(position("GPP-005-" + name + "-x", path, 0, xs[index]));
            checks.push(position("GPP-005-" + name + "-y", path, 1, ys[index]));
            checks.push(position("GPP-005-" + name + "-z", path, 2, zs[index]));
        }
    }
    checks.push(component_requirements::coverage("GPP-003-ownership", "propulsion", "GriffinPropulsionRequirements::gpp003", VERIFICATION));
    checks.push(component_requirements::coverage("GPP-004-traceability", "propulsion", "GriffinPropulsionRequirements::gpp004", VERIFICATION));
    component_requirements::finish(source, checks, "GRIFFIN PROPULSION REQUIREMENTS", "GRIFFIN_PROPULSION_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
