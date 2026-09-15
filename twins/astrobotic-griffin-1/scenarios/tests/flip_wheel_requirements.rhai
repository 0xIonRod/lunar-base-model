// Standalone FLIP four-wheel directional verification.  The source list is
// the acceptance topology; inactive middle-station proxies are deliberately
// outside the list and therefore cannot inflate the count.

const PACKAGE = "FlipWheelRequirements";
const VERIFICATION = "FlipWheelRequirements::Verify_FLIPWheelRequirements";

fn own(name) { PACKAGE + "::FlipDirectionalWheelAssembly::" + name }
fn rover(name) { "FlipRequirements::FlipRover::" + name }

fn position(id, path, index, expected) {
    #{id: id, component: "wheel", requirement: "FlipWheelRequirements::fww005",
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
    let strut_name = sysml_requirements::text(source, own("suspensionVisualChild"));
    if strut_name == () || strut_name == "" {
        throw("FlipWheelRequirements::suspensionVisualChild is required");
    }
    let names = component_requirements::source_text_list(source, names_source);
    let radius_source = rover("visualRoverWheelRadiusM");
    let front_source = rover("frontSteeringAngleDeg");
    let rear_source = rover("rearSteeringAngleDeg");
    let xs = component_requirements::source_number_list(source, rover("wheelStationX"));
    let ys = component_requirements::source_number_list(source, rover("wheelStationY"));
    let zs = component_requirements::source_number_list(source, rover("wheelStationZ"));
    let suspension_component = sysml_requirements::text(source, own("suspensionComponent"));
    if suspension_component == () || suspension_component == "" {
        throw("FlipWheelRequirements::suspensionComponent is required");
    }
    if xs.len() != names.len() || ys.len() != names.len() || zs.len() != names.len() {
        throw("FlipWheelRequirements wheel station datums must match visualWheelNames");
    }
    let checks = [];
    checks.push(component_requirements::source_list_count("FWW-001-count", "wheels", "FlipWheelRequirements::fww001", VERIFICATION, names_source, count_source));
    for axis in ["wheelStationX", "wheelStationY", "wheelStationZ"] {
        checks.push(component_requirements::source_list_count("FWW-005-" + axis,
            "wheel", "FlipWheelRequirements::fww005", VERIFICATION,
            rover(axis), count_source));
    }
    for index in 0..names.len() {
        let name = names[index];
        let station = root + "/Suspension_" + name;
        let wheel = station + "/Wheel_" + name;
        checks.push(component_requirements::exists("FWW-001-" + name, "wheel", "FlipWheelRequirements::fww001", VERIFICATION, wheel, "Xform"));
        checks.push(component_requirements::children("FWW-002-" + name, "wheel", "FlipWheelRequirements::fww002", VERIFICATION, wheel,
            [wheel + "/Tire", wheel + "/MetalHub", wheel + "/HubCap"]));
        checks.push(#{id: "FWW-002-" + name + "-radius", component: "wheel",
            requirement: "FlipWheelRequirements::fww002", verification: VERIFICATION,
            kind: "attribute", path: wheel, attr: "physxVehicleWheel:radius",
            expected_attr: radius_source, tolerance: 0.002});
        let steering_source = if name.starts_with("F") { front_source } else { rear_source };
        checks.push(#{id: "FWW-003-" + name + "-steering", component: "wheel",
            requirement: "FlipWheelRequirements::fww003", verification: VERIFICATION,
            kind: "attribute_component", path: wheel, attr: "xformOp:rotateXYZ",
            index: 1, expected_attr: steering_source, tolerance: 0.002});
        if xs.len() == names.len() && ys.len() == names.len() && zs.len() == names.len() {
            checks.push(position("FWW-005-" + name + "-x", station, 0, xs[index]));
            checks.push(position("FWW-005-" + name + "-y", station, 1, ys[index]));
            checks.push(position("FWW-005-" + name + "-z", station, 2, zs[index]));
        }
        let suspension = station + "/Suspension";
        checks.push(component_requirements::exists("FWW-006-" + name,
            "suspension", "FlipWheelRequirements::fww006", VERIFICATION,
            suspension, "Xform"));
        checks.push(component_requirements::attribute_equals("FWW-006-" + name + "-source",
            "suspension", "FlipWheelRequirements::fww006", VERIFICATION,
            suspension, "lunco:visual:component", "flip_suspension"));
        checks.push(#{id: "FWW-006-" + name + "-mirror", component: "suspension",
            requirement: "FlipWheelRequirements::fww006", verification: VERIFICATION,
            kind: "attribute_component", path: suspension, attr: "xformOp:rotateXYZ",
            index: 1, expected: if xs[index] < 0.0 { 0.0 } else { 180.0 }, tolerance: 0.002});
    }
    checks.push(component_requirements::coverage("FWW-004-traceability", "wheels", "FlipWheelRequirements::fww004", VERIFICATION));
    component_requirements::finish(source, checks, "FLIP WHEEL REQUIREMENTS", "FLIP_WHEEL_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
