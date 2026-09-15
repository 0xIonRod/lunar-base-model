// Standalone Griffin landing-leg verification.  The identity list and count
// are read from GriffinLanderRequirements; no leg names are duplicated here.

const PACKAGE = "GriffinLandingLegRequirements";
const VERIFICATION = "GriffinLandingLegRequirements::Verify_GriffinLandingLegRequirements";

fn own(name) { PACKAGE + "::GriffinLandingLegAssembly::" + name }
fn parent(name) { "GriffinLanderRequirements::GriffinLanderComponent::" + name }

fn position(id, path, index, expected) {
    #{id: id, component: "landing_leg", requirement: "GriffinLandingLegRequirements::gll005",
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
    let xs = component_requirements::source_number_list(source, parent("legStationX"));
    let ys = component_requirements::source_number_list(source, parent("legStationY"));
    let zs = component_requirements::source_number_list(source, parent("legStationZ"));
    let checks = [];
    checks.push(component_requirements::source_list_count("GLL-001-count", "landing_legs", "GriffinLandingLegRequirements::gll001", VERIFICATION, names_source, count_source));
    for axis in ["legStationX", "legStationY", "legStationZ"] {
        checks.push(component_requirements::source_list_count("GLL-005-" + axis,
            "landing_leg", "GriffinLandingLegRequirements::gll005", VERIFICATION,
            parent(axis), count_source));
    }
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        checks.push(component_requirements::exists("GLL-001-" + name, "landing_leg", "GriffinLandingLegRequirements::gll001", VERIFICATION, path, "Xform"));
        checks.push(component_requirements::children("GLL-002-" + name, "landing_leg", "GriffinLandingLegRequirements::gll002", VERIFICATION, path,
            [path + "/StrutOuter", path + "/StrutInner", path + "/ShockPiston", path + "/FootPad"]));
        if xs.len() == names.len() && ys.len() == names.len() && zs.len() == names.len() {
            checks.push(position("GLL-005-" + name + "-x", path, 0, xs[index]));
            checks.push(position("GLL-005-" + name + "-y", path, 1, ys[index]));
            checks.push(position("GLL-005-" + name + "-z", path, 2, zs[index]));
        }
    }
    checks.push(component_requirements::coverage("GLL-003-frame", "landing_leg", "GriffinLandingLegRequirements::gll003", VERIFICATION));
    checks.push(component_requirements::coverage("GLL-004-traceability", "landing_leg", "GriffinLandingLegRequirements::gll004", VERIFICATION));
    component_requirements::finish(source, checks, "GRIFFIN LANDING LEG REQUIREMENTS", "GRIFFIN_LANDING_LEG_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
