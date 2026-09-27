import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
// FLIP simulation wheel verification. Typed station identities and metric
// datums are owned by FlipRover and checked against the composed vehicle.

const PACKAGE = "FlipWheelRequirements";
const VERIFICATION = "Verify_FLIPWheelRequirements";

fn own(name) { PACKAGE + "::FlipDirectionalWheelAssembly::" + name }
fn rover(name) { "FlipRequirements::FlipRover::" + name }

fn position(id, path, index, expected) {
    #{id: id, component: "wheel", requirement: "fww005",
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
    let source_owner = sysml_requirements::attribute(source, own("usdRootPath")).record.owner_handle;
    let names = sysml_requirement_checks::source_enum_identifiers(source, rover("wheelStations"));
    let child_names = sysml_requirement_checks::source_enum_identifiers(source, own("childNames"));
    let radius = sysml_requirements::number(source, rover("wheelRadiusM"));
    let width = sysml_requirements::number(source, rover("wheelWidthM"));
    let steering_mode = sysml_requirements::text(source, rover("missionSteeringMode"));
    let rest_length = sysml_requirements::number(source, rover("suspensionRestLengthM"));
    let xs = sysml_requirement_checks::source_number_list(source, rover("wheelStationX"));
    let ys = sysml_requirement_checks::source_number_list(source, rover("wheelStationY"));
    let zs = sysml_requirement_checks::source_number_list(source, rover("wheelStationZ"));
    if names.len() == 0 || xs.len() != names.len() || ys.len() != names.len()
        || zs.len() != names.len() || child_names.len() != 3 || radius == ()
        || width == () || steering_mode == () || rest_length == () {
        throw("FlipWheelRequirements typed station identities and wheel datums are incomplete");
    }
    let checks = [];
    checks.push(#{id: "FWW-003-steering-mode", component: "wheels", requirement: "fww003",
        verification: VERIFICATION, kind: "attribute_equals", path: root,
        attr: "lunco:steeringGeometry", expected: steering_mode});
    for axis in ["wheelStationX", "wheelStationY", "wheelStationZ"] {
        let stations = sysml_requirement_checks::source_number_list(source, rover(axis));
        checks.push(#{id: "FWW-005-" + axis, component: "wheel",
            requirement: "fww005", verification: VERIFICATION,
            kind: "source_collection_count", actual_count: stations.len(),
            expected_count: names.len()});
    }
    for index in 0..names.len() {
        let name = names[index];
        let station = root + "/Suspension_" + name;
        let wheel = station + "/Wheel_" + name;
        checks.push(sysml_requirement_checks::exists("FWW-001-" + name, "wheel", "fww001", VERIFICATION, wheel, "Cylinder"));
        checks.push(sysml_requirement_checks::children("FWW-002-" + name, "wheel", "fww002", VERIFICATION, wheel + "/Visual",
            [wheel + "/Visual/" + child_names[0], wheel + "/Visual/" + child_names[1],
             wheel + "/Visual/" + child_names[2]]));
        checks.push(#{id: "FWW-002-" + name + "-radius", component: "wheel",
            requirement: "fww002", verification: VERIFICATION,
            kind: "attribute", path: wheel, attr: "physxVehicleWheel:radius",
            expected: radius, tolerance: 0.002});
        checks.push(#{id: "FWW-002-" + name + "-width", component: "wheel",
            requirement: "fww002", verification: VERIFICATION,
            kind: "attribute", path: wheel, attr: "physxVehicleWheel:width",
            expected: width, tolerance: 0.002});
        checks.push(#{id: "FWW-007-" + name + "-axis", component: "wheel",
            requirement: "fww007", verification: VERIFICATION, kind: "attribute_equals",
            path: wheel + "/Visual/Tire", attr: "axis", expected_attr: own("wheelAxis")});
        checks.push(#{id: "FWW-007-" + name + "-tire-width", component: "wheel",
            requirement: "fww007", verification: VERIFICATION, kind: "attribute",
            path: wheel + "/Visual/Tire", attr: "height", expected: width, tolerance: 0.002});
        checks.push(#{id: "FWW-007-" + name + "-tire-radius", component: "wheel",
            requirement: "fww007", verification: VERIFICATION, kind: "attribute",
            path: wheel + "/Visual/Tire", attr: "radius", expected: radius, tolerance: 0.002});
        checks.push(#{id: "FWW-007-" + name + "-hub-radius", component: "wheel",
            requirement: "fww007", verification: VERIFICATION, kind: "attribute",
            path: wheel + "/MetalHub", attr: "radius", expected_attr: own("hubRadiusM"), tolerance: 0.002});
        checks.push(#{id: "FWW-007-" + name + "-hub-width", component: "wheel",
            requirement: "fww007", verification: VERIFICATION, kind: "attribute",
            path: wheel + "/MetalHub", attr: "height", expected_attr: own("hubWidthM"), tolerance: 0.002});
        checks.push(#{id: "FWW-007-" + name + "-cap-radius", component: "wheel",
            requirement: "fww007", verification: VERIFICATION, kind: "attribute",
            path: wheel + "/HubCap", attr: "radius", expected_attr: own("hubCapRadiusM"), tolerance: 0.002});
        checks.push(#{id: "FWW-007-" + name + "-cap-width", component: "wheel",
            requirement: "fww007", verification: VERIFICATION, kind: "attribute",
            path: wheel + "/HubCap", attr: "height", expected_attr: own("hubCapWidthM"), tolerance: 0.002});
        checks.push(#{id: "FWW-007-" + name + "-suspension-length", component: "wheel",
            requirement: "fww007", verification: VERIFICATION, kind: "attribute",
            path: wheel, attr: "lunco:suspension:restLength", expected: rest_length, tolerance: 0.002});
        if xs.len() == names.len() && ys.len() == names.len() && zs.len() == names.len() {
            checks.push(position("FWW-005-" + name + "-x", station, 0, xs[index]));
            checks.push(position("FWW-005-" + name + "-y", station, 1, ys[index]));
            checks.push(position("FWW-005-" + name + "-z", station, 2, zs[index]));
        }
        let suspension = station + "/Visual";
        checks.push(sysml_requirement_checks::exists("FWW-006-" + name,
            "suspension", "fww006", VERIFICATION,
            suspension, "Xform"));
        checks.push(sysml_requirement_checks::attribute_equals("FWW-006-" + name + "-source",
            "suspension", "fww006", VERIFICATION,
            suspension, "lunco:visual:component", "flip_suspension"));
        checks.push(#{id: "FWW-006-" + name + "-mirror", component: "suspension",
            requirement: "fww006", verification: VERIFICATION,
            kind: "attribute_component", path: suspension, attr: "xformOp:rotateXYZ",
            index: 1, expected: if xs[index] < 0.0 { 0.0 } else { 180.0 }, tolerance: 0.002});
    }
    checks.push(sysml_requirement_checks::coverage("FWW-004-traceability", "wheels", "fww004", VERIFICATION));
    sysml_requirement_checks::finish(source, checks, "FLIP WHEEL REQUIREMENTS", "FLIP_WHEEL_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
