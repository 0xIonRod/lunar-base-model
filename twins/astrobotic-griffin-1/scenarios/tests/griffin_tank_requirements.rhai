// Standalone Griffin propellant-tank visual verification.

const PACKAGE = "GriffinTankRequirements";
const VERIFICATION = "GriffinTankRequirements::Verify_GriffinTankRequirements";

fn own(name) { PACKAGE + "::GriffinPropellantTankAssembly::" + name }
fn parent(name) { "GriffinLanderRequirements::GriffinLanderComponent::" + name }

fn position(id, path, index, expected) {
    #{id: id, component: "tank", requirement: "GriffinTankRequirements::gpt005",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: 0.002}
}

fn attribute(id, requirement, path, attr, expected) {
    #{id: id, component: "tank", requirement: requirement,
      verification: VERIFICATION, kind: "attribute", path: path,
      attr: attr, expected: expected, tolerance: 0.002}
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
    let child_names = component_requirements::source_text_list(source, own("childNames"));
    let end_hardware_names = component_requirements::source_text_list(source, own("endHardwareNames"));
    let xs = component_requirements::source_number_list(source, parent("tankStationX"));
    let ys = component_requirements::source_number_list(source, parent("tankStationY"));
    let zs = component_requirements::source_number_list(source, parent("tankStationZ"));
    let body_radius = sysml_requirements::number(source, own("bodyRadiusM"));
    let body_height = sysml_requirements::number(source, own("bodyHeightM"));
    let dome_radius = sysml_requirements::number(source, own("domeRadiusM"));
    let dome_flattening = sysml_requirements::number(source, own("domeFlatteningRatio"));
    let neck_radius = sysml_requirements::number(source, own("neckRadiusM"));
    let neck_height = sysml_requirements::number(source, own("neckHeightM"));
    if body_radius == () || body_height == () || dome_radius == () || dome_flattening == ()
        || neck_radius == () || neck_height == () || child_names.len() == 0 || end_hardware_names.len() != 4 {
        component_requirements::finish(source, [component_requirements::coverage("GPT-006-source", "tank", "GriffinTankRequirements::gpt006", VERIFICATION)], "GRIFFIN TANK REQUIREMENTS", "GRIFFIN_TANK_REQUIREMENTS", root, PACKAGE, VERIFICATION);
        this.done = true;
        return;
    }
    let checks = [];
    checks.push(component_requirements::source_list_count("GPT-001-count", "propellant_tank", "GriffinTankRequirements::gpt001", VERIFICATION, names_source, count_source));
    for axis in ["tankStationX", "tankStationY", "tankStationZ"] {
        checks.push(component_requirements::source_list_count("GPT-005-" + axis,
            "tank", "GriffinTankRequirements::gpt005", VERIFICATION,
            parent(axis), count_source));
    }
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        let child_paths = [];
        for child_name in child_names { child_paths.push(path + "/" + child_name); }
        let end_hardware_paths = [];
        for child_name in end_hardware_names { end_hardware_paths.push(path + "/" + child_name); }
        checks.push(component_requirements::exists("GPT-001-" + name, "tank", "GriffinTankRequirements::gpt001", VERIFICATION, path, "Xform"));
        checks.push(component_requirements::children("GPT-002-" + name, "tank", "GriffinTankRequirements::gpt002", VERIFICATION, path,
            child_paths));
        checks.push(component_requirements::exists("GPT-002-" + name + "-cradle", "tank", "GriffinTankRequirements::gpt002", VERIFICATION, path + "/TankCradle", "Cube"));
        checks.push(component_requirements::children("GPT-006-" + name, "tank", "GriffinTankRequirements::gpt006", VERIFICATION, path,
            end_hardware_paths));
        checks.push(component_requirements::exists("GPT-006-" + name + "-dome-top", "tank", "GriffinTankRequirements::gpt006", VERIFICATION, path + "/TankDomeTop", "Sphere"));
        checks.push(component_requirements::exists("GPT-006-" + name + "-dome-bottom", "tank", "GriffinTankRequirements::gpt006", VERIFICATION, path + "/TankDomeBottom", "Sphere"));
        checks.push(component_requirements::exists("GPT-006-" + name + "-neck-top", "tank", "GriffinTankRequirements::gpt006", VERIFICATION, path + "/TankNeckTop", "Cylinder"));
        checks.push(component_requirements::exists("GPT-006-" + name + "-neck-bottom", "tank", "GriffinTankRequirements::gpt006", VERIFICATION, path + "/TankNeckBottom", "Cylinder"));
        checks.push(attribute("GPT-006-" + name + "-body-radius", "GriffinTankRequirements::gpt006", path + "/MliTank", "radius", body_radius));
        checks.push(attribute("GPT-006-" + name + "-body-height", "GriffinTankRequirements::gpt006", path + "/MliTank", "height", body_height));
        checks.push(attribute("GPT-006-" + name + "-dome-radius", "GriffinTankRequirements::gpt006", path + "/TankDomeTop", "radius", dome_radius));
        checks.push(#{id: "GPT-006-" + name + "-dome-flattening", component: "tank", requirement: "GriffinTankRequirements::gpt006", verification: VERIFICATION, kind: "attribute_component", path: path + "/TankDomeTop", attr: "xformOp:scale", index: 1, expected: dome_flattening, tolerance: 0.002});
        checks.push(attribute("GPT-006-" + name + "-neck-radius", "GriffinTankRequirements::gpt006", path + "/TankNeckTop", "radius", neck_radius));
        checks.push(attribute("GPT-006-" + name + "-neck-height", "GriffinTankRequirements::gpt006", path + "/TankNeckTop", "height", neck_height));
        if xs.len() == names.len() && ys.len() == names.len() && zs.len() == names.len() {
            checks.push(position("GPT-005-" + name + "-x", path, 0, xs[index]));
            checks.push(position("GPT-005-" + name + "-y", path, 1, ys[index]));
            checks.push(position("GPT-005-" + name + "-z", path, 2, zs[index]));
        }
    }
    checks.push(component_requirements::coverage("GPT-003-status", "tank", "GriffinTankRequirements::gpt003", VERIFICATION));
    checks.push(component_requirements::coverage("GPT-004-traceability", "tank", "GriffinTankRequirements::gpt004", VERIFICATION));
    component_requirements::finish(source, checks, "GRIFFIN TANK REQUIREMENTS", "GRIFFIN_TANK_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
