// Standalone Griffin dual solar-array visual verification.

const PACKAGE = "GriffinSolarRequirements";
const VERIFICATION = "Verify_GriffinSolarRequirements";

fn own(name) { PACKAGE + "::GriffinSolarArrayAssembly::" + name }
fn parent(name) { "GriffinLanderRequirements::GriffinLanderComponent::" + name }

fn position(id, path, index, expected) {
    #{id: id, component: "solar_array", requirement: "gsa005",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: 0.002}
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let names_source = sysml_requirements::text(source, own("namesSource"));
    let count_source = sysml_requirements::text(source, own("countSource"));
    let names = component_requirements::source_text_list(source, names_source);
    let xs = component_requirements::source_number_list(source, parent("solarStationX"));
    let ys = component_requirements::source_number_list(source, parent("solarStationY"));
    let zs = component_requirements::source_number_list(source, parent("solarStationZ"));
    let checks = [];
    checks.push(component_requirements::source_list_count("GSA-001-count", "lander_solar", "gsa001", VERIFICATION, names_source, count_source));
    for axis in ["solarStationX", "solarStationY", "solarStationZ"] {
        checks.push(component_requirements::source_list_count("GSA-005-" + axis,
            "solar_array", "gsa005", VERIFICATION,
            parent(axis), count_source));
    }
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        checks.push(component_requirements::exists("GSA-001-" + name, "solar_array", "gsa001", VERIFICATION, path, "Xform"));
        checks.push(component_requirements::children("GSA-002-" + name, "solar_array", "gsa002", VERIFICATION, path,
            [path + "/Frame", path + "/Cells"]));
        if xs.len() == names.len() && ys.len() == names.len() && zs.len() == names.len() {
            checks.push(position("GSA-005-" + name + "-x", path, 0, xs[index]));
            checks.push(position("GSA-005-" + name + "-y", path, 1, ys[index]));
            checks.push(position("GSA-005-" + name + "-z", path, 2, zs[index]));
        }
    }
    checks.push(component_requirements::coverage("GSA-003-symmetry", "solar_array", "gsa003", VERIFICATION));
    checks.push(component_requirements::coverage("GSA-004-traceability", "solar_array", "gsa004", VERIFICATION));
    component_requirements::finish(source, checks, "GRIFFIN SOLAR REQUIREMENTS", "GRIFFIN_SOLAR_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
