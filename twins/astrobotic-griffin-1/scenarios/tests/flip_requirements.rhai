// Standalone FLIP rover component verification.
// The integration scene still has a combined visual gate; this component gate
// is independent and can be opened in Editor Perspective without the lander.

const ROOT = "/World/FLIP";
const VERIFICATION = "FlipRequirements::Verify_FLIPComponentRequirements";

fn on_start(me) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn _source_attr(name) {
    "FlipRequirements::FlipRover::" + name
}

fn _list(source, name) {
    let text = sysml_requirements::text(source, _source_attr(name));
    if text == () || text == "" { return []; }
    let values = [];
    for value in text.split(",") {
        value.trim();
        if value != "" { values.push(value); }
    }
    values
}

fn _exists(id, requirement, path, expected_type) {
    #{id: id, component: "rover", requirement: requirement,
      verification: VERIFICATION, kind: "exists", path: path,
      expected_type: expected_type, visible: true}
}

fn _children(id, requirement, path, paths) {
    #{id: id, component: "rover", requirement: requirement,
      verification: VERIFICATION, kind: "children", path: path,
      paths: paths, visible: true}
}

fn _attribute_component(id, requirement, path, attr, index, expected) {
    #{id: id, component: "rover", requirement: requirement,
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: attr, index: index, expected: expected, tolerance: 0.002}
}

fn on_tick(me) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let checks = [];
    checks.push(_exists("FGV-001-root", "FlipRequirements::fvg001", ROOT, "Xform"));
    checks.push(#{id: "FGV-001-config", component: "rover",
        requirement: "FlipRequirements::fvg001", verification: VERIFICATION,
        kind: "attribute_equals", path: ROOT, attr: "lunco:visual:configuration",
        expected: "four directional wheels, white equipment box, sensor mast, fixed solar-array proxy"});
    checks.push(#{id: "FGV-001-wheel-count", component: "rover",
        requirement: "FlipRequirements::fvg001", verification: VERIFICATION,
        kind: "attribute", path: ROOT, attr: "lunco:visual:wheel_count",
        expected_attr: _source_attr("visualRoverWheelCount")});

    checks.push(_exists("FGV-004-chassis", "FlipRequirements::fvg004", ROOT + "/Chassis", "Xform"));
    checks.push(_children("FGV-004-chassis-parts", "FlipRequirements::fvg004", ROOT + "/Chassis",
        [ROOT + "/Chassis/LowerFrame", ROOT + "/Chassis/WhiteEquipmentBox", ROOT + "/Chassis/PayloadDeck"]));
    checks.push(_exists("FGV-004-mast", "FlipRequirements::fvg004", ROOT + "/SensorMast", "Xform"));
    checks.push(_children("FGV-004-mast-parts", "FlipRequirements::fvg004", ROOT + "/SensorMast",
        [ROOT + "/SensorMast/MastPost", ROOT + "/SensorMast/SensorHead", ROOT + "/SensorMast/SensorAntenna"]));
    checks.push(_exists("FGV-004-solar", "FlipRequirements::fvg004", ROOT + "/SolarArray", "Xform"));
    checks.push(_children("FGV-004-solar-parts", "FlipRequirements::fvg004", ROOT + "/SolarArray",
        [ROOT + "/SolarArray/WhiteBacksheet", ROOT + "/SolarArray/BlueCells", ROOT + "/SolarArray/FoldHinge"]));
    let solar_mount = component_requirements::source_number_list(source, _source_attr("solarArrayMount"));
    if solar_mount.len() == 3 {
        checks.push(_attribute_component("FGV-004-solar-x", "FlipRequirements::fvg004", ROOT + "/SolarArray", "xformOp:translate", 0, solar_mount[0]));
        checks.push(_attribute_component("FGV-004-solar-y", "FlipRequirements::fvg004", ROOT + "/SolarArray", "xformOp:translate", 1, solar_mount[1]));
        checks.push(_attribute_component("FGV-004-solar-z", "FlipRequirements::fvg004", ROOT + "/SolarArray", "xformOp:translate", 2, solar_mount[2]));
        checks.push(_attribute_component("FGV-004-solar-tilt", "FlipRequirements::fvg004", ROOT + "/SolarArray", "xformOp:rotateXYZ", 0,
            sysml_requirements::number(source, _source_attr("solarArrayTiltDeg"))));
    }

    checks.push(#{id: "FGV-002-width", component: "chassis",
        requirement: "FlipRequirements::fvg002", verification: VERIFICATION,
        kind: "extent_component", path: ROOT + "/Chassis/LowerFrame", index: 0,
        multiplier: 2.0, expected_attr: _source_attr("chassisWidthM"), tolerance: 0.002});
    checks.push(#{id: "FGV-002-length", component: "chassis",
        requirement: "FlipRequirements::fvg002", verification: VERIFICATION,
        kind: "extent_component", path: ROOT + "/Chassis/LowerFrame", index: 2,
        multiplier: 2.0, expected_attr: _source_attr("chassisLengthM"), tolerance: 0.002});
    checks.push(#{id: "FGV-002-mast-height", component: "mast",
        requirement: "FlipRequirements::fvg002", verification: VERIFICATION,
        kind: "attribute", path: ROOT + "/SensorMast/MastPost", attr: "height",
        expected_attr: _source_attr("sensorMastHeightM"), tolerance: 0.002});

    let wheel_names = _list(source, "visualWheelNames");
    let wheel_x = component_requirements::source_number_list(source, _source_attr("wheelStationX"));
    let wheel_y = component_requirements::source_number_list(source, _source_attr("wheelStationY"));
    let wheel_z = component_requirements::source_number_list(source, _source_attr("wheelStationZ"));
    for axis in ["wheelStationX", "wheelStationY", "wheelStationZ"] {
        checks.push(component_requirements::source_list_count("FGV-003-" + axis,
            "wheel", "FlipRequirements::fvg003", VERIFICATION,
            _source_attr(axis), _source_attr("visualRoverWheelCount")));
    }
    for index in 0..wheel_names.len() {
        let name = wheel_names[index];
        let station = ROOT + "/Suspension_" + name;
        let wheel = station + "/Wheel_" + name;
        checks.push(_exists("FGV-003-" + name, "FlipRequirements::fvg003", wheel, "Xform"));
        checks.push(_children("FGV-003-" + name + "-parts", "FlipRequirements::fvg003", wheel,
            [wheel + "/Tire", wheel + "/MetalHub", wheel + "/HubCap"]));
        checks.push(#{id: "FGV-003-" + name + "-radius", component: "wheel",
            requirement: "FlipRequirements::fvg003", verification: VERIFICATION,
            kind: "attribute", path: wheel, attr: "physxVehicleWheel:radius",
            expected_attr: _source_attr("visualRoverWheelRadiusM"), tolerance: 0.002});
        let steering_attr = if name.starts_with("F") {
            "frontSteeringAngleDeg"
        } else {
            "rearSteeringAngleDeg"
        };
        checks.push(_attribute_component("FGV-003-" + name + "-steering", "FlipRequirements::fvg003",
            wheel, "xformOp:rotateXYZ", 1,
            sysml_requirements::number(source, _source_attr(steering_attr))));
        if wheel_x.len() == wheel_names.len() && wheel_y.len() == wheel_names.len() && wheel_z.len() == wheel_names.len() {
            checks.push(_attribute_component("FGV-003-" + name + "-x", "FlipRequirements::fvg003", station, "xformOp:translate", 0, wheel_x[index]));
            checks.push(_attribute_component("FGV-003-" + name + "-y", "FlipRequirements::fvg003", station, "xformOp:translate", 1, wheel_y[index]));
            checks.push(_attribute_component("FGV-003-" + name + "-z", "FlipRequirements::fvg003", station, "xformOp:translate", 2, wheel_z[index]));
        }
    }
    checks.push(#{id: "FGV-005-source", component: "rover",
        requirement: "FlipRequirements::fvg005", verification: VERIFICATION,
        kind: "coverage"});
    checks.push(#{id: "FGV-005-wheel-list-count", component: "rover",
        requirement: "FlipRequirements::fvg005", verification: VERIFICATION,
        kind: "source_list_count", list_attr: _source_attr("visualWheelNames"),
        expected_attr: _source_attr("visualRoverWheelCount")});

    let result = sysml_requirements::evaluate(source, checks);
    result.metrics = #{clock: clock_snapshot(), root: ROOT, separate_component_document: true};
    report_structured_verdict(result, "FLIP REQUIREMENTS", "FLIP_REQUIREMENTS");
    this.done = true;
}
