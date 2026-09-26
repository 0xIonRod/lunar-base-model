import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
// Standalone FLIP rover component verification.
// The integration scene still has a combined visual gate; this component gate
// is independent and can be opened in Editor Perspective without the lander.

const ROOT = "/World/FLIP";
const VERIFICATION = "Verify_FLIPComponentRequirements";

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn _source_attr(name) {
    "FlipRequirements::FlipRover::" + name
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

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let checks = [];
    checks.push(_exists("FGV-001-root", "fvg001", ROOT, "Xform"));
    checks.push(#{id: "FGV-001-steering-mode", component: "rover",
        requirement: "fvg001", verification: VERIFICATION,
        kind: "attribute_equals", path: ROOT, attr: "lunco:steeringGeometry",
        expected_attr: _source_attr("missionSteeringMode")});

    checks.push(_exists("FGV-004-chassis", "fvg004", ROOT + "/Chassis", "Xform"));
    checks.push(_children("FGV-004-chassis-parts", "fvg004", ROOT + "/Chassis",
        [ROOT + "/Chassis/LowerFrame", ROOT + "/Chassis/WhiteEquipmentBox",
         ROOT + "/Chassis/FrontBumper", ROOT + "/Chassis/PayloadDeck",
         ROOT + "/Chassis/ServicePanel"]));
    checks.push(_exists("FGV-004-mast", "fvg004", ROOT + "/SensorMast", "Xform"));
    checks.push(_children("FGV-004-mast-parts", "fvg004", ROOT + "/SensorMast",
        [ROOT + "/SensorMast/MastPost", ROOT + "/SensorMast/SensorHead", ROOT + "/SensorMast/SensorAntenna"]));
    checks.push(_exists("FGV-004-solar", "fvg004", ROOT + "/SolarArray", "Xform"));
    checks.push(_exists("FGV-004-solar-visual", "fvg004", ROOT + "/SolarArray/SolarArrayVisual", "Xform"));
    checks.push(_children("FGV-004-solar-parts", "fvg004", ROOT + "/SolarArray/SolarArrayVisual",
        [ROOT + "/SolarArray/SolarArrayVisual/WhiteBacksheet",
         ROOT + "/SolarArray/SolarArrayVisual/BlueCells",
         ROOT + "/SolarArray/SolarArrayVisual/FoldHinge"]));
    let solar_mount = sysml_requirement_checks::source_number_list(source, _source_attr("solarArrayMount"));
    if solar_mount.len() == 3 {
        checks.push(_attribute_component("FGV-004-solar-x", "fvg004", ROOT + "/SolarArray", "xformOp:translate", 0, solar_mount[0]));
        checks.push(_attribute_component("FGV-004-solar-y", "fvg004", ROOT + "/SolarArray", "xformOp:translate", 1, solar_mount[1]));
        checks.push(_attribute_component("FGV-004-solar-z", "fvg004", ROOT + "/SolarArray", "xformOp:translate", 2, solar_mount[2]));
        checks.push(_attribute_component("FGV-004-solar-tilt", "fvg004", ROOT + "/SolarArray", "xformOp:rotateXYZ", 0,
            sysml_requirements::number(source, _source_attr("solarArrayTiltDeg"))));
    }

    checks.push(#{id: "FGV-002-width", component: "chassis",
        requirement: "fvg002", verification: VERIFICATION,
        kind: "extent_component", path: ROOT + "/Chassis/LowerFrame", index: 0,
        multiplier: 2.0, expected_attr: _source_attr("chassisWidthM"), tolerance: 0.002});
    checks.push(#{id: "FGV-002-length", component: "chassis",
        requirement: "fvg002", verification: VERIFICATION,
        kind: "extent_component", path: ROOT + "/Chassis/LowerFrame", index: 2,
        multiplier: 2.0, expected_attr: _source_attr("chassisLengthM"), tolerance: 0.002});
    checks.push(#{id: "FGV-002-mast-height", component: "mast",
        requirement: "fvg002", verification: VERIFICATION,
        kind: "attribute", path: ROOT + "/SensorMast/MastPost", attr: "height",
        expected_attr: _source_attr("sensorMastHeightM"), tolerance: 0.002});

    let wheel_names = sysml_requirement_checks::source_enum_identifiers(source, _source_attr("wheelStations"));
    let wheel_x = sysml_requirement_checks::source_number_list(source, _source_attr("wheelStationX"));
    let wheel_y = sysml_requirement_checks::source_number_list(source, _source_attr("wheelStationY"));
    let wheel_z = sysml_requirement_checks::source_number_list(source, _source_attr("wheelStationZ"));
    for axis in ["wheelStationX", "wheelStationY", "wheelStationZ"] {
        let stations = sysml_requirement_checks::source_number_list(source, _source_attr(axis));
        checks.push(#{id: "FGV-003-" + axis, component: "wheel",
            requirement: "fvg003", verification: VERIFICATION,
            kind: "source_collection_count", actual_count: stations.len(),
            expected_count: wheel_names.len()});
    }
    for index in 0..wheel_names.len() {
        let name = wheel_names[index];
        let station = ROOT + "/Suspension_" + name;
        let wheel = station + "/Wheel_" + name;
        checks.push(_exists("FGV-003-" + name, "fvg003", wheel, "Cylinder"));
        checks.push(_children("FGV-003-" + name + "-parts", "fvg003", wheel + "/Visual",
            [wheel + "/Visual/Tire", wheel + "/Visual/MetalHub", wheel + "/Visual/HubCap"]));
        checks.push(#{id: "FGV-003-" + name + "-radius", component: "wheel",
            requirement: "fvg003", verification: VERIFICATION,
            kind: "attribute", path: wheel, attr: "physxVehicleWheel:radius",
            expected_attr: _source_attr("wheelRadiusM"), tolerance: 0.002});
        checks.push(#{id: "FGV-003-" + name + "-width", component: "wheel",
            requirement: "fvg003", verification: VERIFICATION,
            kind: "attribute", path: wheel, attr: "height",
            expected_attr: _source_attr("wheelWidthM"), tolerance: 0.002});
        if wheel_x.len() == wheel_names.len() && wheel_y.len() == wheel_names.len() && wheel_z.len() == wheel_names.len() {
            checks.push(_attribute_component("FGV-003-" + name + "-x", "fvg003", station, "xformOp:translate", 0, wheel_x[index]));
            checks.push(_attribute_component("FGV-003-" + name + "-y", "fvg003", station, "xformOp:translate", 1, wheel_y[index]));
            checks.push(_attribute_component("FGV-003-" + name + "-z", "fvg003", station, "xformOp:translate", 2, wheel_z[index]));
        }
    }
    checks.push(#{id: "FGV-005-source", component: "rover",
        requirement: "fvg005", verification: VERIFICATION,
        kind: "coverage"});
    let result = sysml_requirements::evaluate(source, checks);
    result.metrics = #{clock: clock_snapshot(), root: ROOT, separate_component_document: true};
    report_structured_verdict(result, "FLIP REQUIREMENTS", "FLIP_REQUIREMENTS");
    this.done = true;
}
