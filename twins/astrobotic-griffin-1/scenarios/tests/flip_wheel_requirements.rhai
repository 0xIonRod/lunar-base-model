import "twin://astrobotic-griffin-1/tools/usd_geometry_inspection" as usd_geometry_inspection;
import "twin://astrobotic-griffin-1/tools/flip_wheel_checks" as flip_wheel_checks;
import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
// FLIP simulation wheel verification. Typed station identities and metric
// datums are owned by FlipRover and checked against the composed vehicle.

fn _package_name() { "FlipWheelRequirements" }
fn verification() { "Verify_FLIPWheelRequirements" }

fn own(name) { _package_name() + "::FlipDirectionalWheelAssembly::" + name }
fn rover(name) { "FlipRequirements::FlipRover::" + name }

fn position(id, path, index, expected) {
    #{id: id, component: "wheel", requirement: "fww005",
      verification: verification(), kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: 0.002}
}

fn simulation_dependencies(me, ctx) { usd_geometry_inspection::dependencies() }

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    this.done = run_wheel_review();
}

// Also callable once through the production API when physics is held.
fn run_wheel_review() {
    let attributes = [own("usdRootPath"), own("wheelAxis")];
    for name in ["wheelStations", "wheelRadiusM", "wheelWidthM", "missionSteeringMode",
        "suspensionRestLengthM", "wheelStationX", "wheelStationY", "wheelStationZ"] {
        attributes.push(rover(name));
    }
    let requirements = [];
    for name in ["fww001", "fww002", "fww003", "fww004", "fww005", "fww006", "fww007"] {
        requirements.push(_package_name() + "::" + name);
    }
    let source = sysml_requirements::source_with_selection(attributes, requirements,
        [_package_name() + "::" + verification()]);
    if source.ok != true {
        if source.error != () && source.error.contains("preparing asynchronously") { return false; }
        throw("FLIP wheel source failed: " + source.to_string());
    }
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let names = sysml_requirement_checks::source_enum_identifiers(source, rover("wheelStations"));
    let radius = sysml_requirements::number(source, rover("wheelRadiusM"));
    let width = sysml_requirements::number(source, rover("wheelWidthM"));
    let steering_mode = sysml_requirements::text(source, rover("missionSteeringMode"));
    let rest_length = sysml_requirements::number(source, rover("suspensionRestLengthM"));
    let xs = sysml_requirement_checks::source_number_list(source, rover("wheelStationX"));
    let ys = sysml_requirement_checks::source_number_list(source, rover("wheelStationY"));
    let zs = sysml_requirement_checks::source_number_list(source, rover("wheelStationZ"));
    if names.len() == 0 || xs.len() != names.len() || ys.len() != names.len()
        || zs.len() != names.len() || radius == ()
        || width == () || steering_mode == () || rest_length == () {
        throw("FlipWheelRequirements typed station identities and wheel datums are incomplete");
    }
    let checks = [];
    checks.push(#{id: "FWW-003-steering-mode", component: "wheels", requirement: "fww003",
        verification: verification(), kind: "attribute_equals", path: root,
        attr: "lunco:steeringGeometry", expected: steering_mode});
    for axis in ["wheelStationX", "wheelStationY", "wheelStationZ"] {
        let stations = sysml_requirement_checks::source_number_list(source, rover(axis));
        checks.push(#{id: "FWW-005-" + axis, component: "wheel",
            requirement: "fww005", verification: verification(),
            kind: "source_collection_count", actual_count: stations.len(),
            expected_count: names.len()});
    }
    for index in 0..names.len() {
        let name = names[index];
        let station = root + "/Suspension_" + name;
        let wheel = station + "/Wheel_" + name;
        checks.push(sysml_requirement_checks::exists("FWW-001-" + name, "wheel", "fww001", verification(), wheel, "Cylinder"));
        for check in flip_wheel_checks::single_surface("FWW-002-" + name,
            "wheel", "fww002", verification(), wheel) { checks.push(check); }
        checks.push(#{id: "FWW-002-" + name + "-radius", component: "wheel",
            requirement: "fww002", verification: verification(),
            kind: "attribute", path: wheel, attr: "physxVehicleWheel:radius",
            expected: radius, tolerance: 0.002});
        checks.push(#{id: "FWW-002-" + name + "-width", component: "wheel",
            requirement: "fww002", verification: verification(),
            kind: "attribute", path: wheel, attr: "physxVehicleWheel:width",
            expected: width, tolerance: 0.002});
        checks.push(#{id: "FWW-007-" + name + "-axis", component: "wheel",
            requirement: "fww007", verification: verification(), kind: "attribute_equals",
            path: wheel, attr: "axis", expected_attr: own("wheelAxis")});
        checks.push(#{id: "FWW-007-" + name + "-tire-width", component: "wheel",
            requirement: "fww007", verification: verification(), kind: "attribute",
            path: wheel, attr: "height", expected: width, tolerance: 0.002});
        checks.push(#{id: "FWW-007-" + name + "-tire-radius", component: "wheel",
            requirement: "fww007", verification: verification(), kind: "attribute",
            path: wheel, attr: "radius", expected: radius, tolerance: 0.002});
        checks.push(#{id: "FWW-007-" + name + "-suspension-length", component: "wheel",
            requirement: "fww007", verification: verification(), kind: "attribute",
            path: wheel, attr: "lunco:suspension:restLength", expected: rest_length, tolerance: 0.002});
        if xs.len() == names.len() && ys.len() == names.len() && zs.len() == names.len() {
            checks.push(position("FWW-005-" + name + "-x", station, 0, xs[index]));
            checks.push(position("FWW-005-" + name + "-y", station, 1, ys[index]));
            checks.push(position("FWW-005-" + name + "-z", station, 2, zs[index]));
        }
        let suspension = station + "/Visual";
        checks.push(sysml_requirement_checks::exists("FWW-006-" + name,
            "suspension", "fww006", verification(),
            suspension, "Xform"));
        checks.push(sysml_requirement_checks::attribute_equals("FWW-006-" + name + "-source",
            "suspension", "fww006", verification(),
            suspension, "lunco:visual:component", "flip_suspension"));
        checks.push(#{id: "FWW-006-" + name + "-mirror", component: "suspension",
            requirement: "fww006", verification: verification(),
            kind: "attribute_component", path: suspension, attr: "xformOp:rotateXYZ",
            index: 1, expected: if zs[index] < 0.0 { -90.0 } else { 90.0 }, tolerance: 0.002});
    }
    checks.push(sysml_requirement_checks::coverage("FWW-004-traceability", "wheels", "fww004", verification()));
    sysml_requirement_checks::finish(source, checks, "FLIP WHEEL REQUIREMENTS", "FLIP_WHEEL_REQUIREMENTS", root, _package_name(), verification());
    true
}
