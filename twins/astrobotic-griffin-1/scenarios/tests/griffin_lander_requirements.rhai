import "twin://astrobotic-griffin-1/tools/usd_geometry_inspection.rhai" as usd_geometry_inspection;
import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
// Standalone Griffin lander component verification.
// SysML owns names/counts/dimensions and references; this Rhai observer only
// queries the composed USD and emits the generic structured verdict.

const ROOT = "/World/Griffin1";
const VERIFICATION = "Verify_GriffinLanderRequirements";

fn simulation_dependencies(me, ctx) { usd_geometry_inspection::dependencies() }

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn _source_attr(name) {
    "GriffinLanderRequirements::GriffinLanderComponent::" + name
}

fn _configuration_attr(name) {
    "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::" + name
}

fn _enum_names(source, name) {
    let values = sysml_requirements::native_value(source, _configuration_attr(name));
    if values == () || !array_is(values) { return []; }
    let names = [];
    for value in values {
        if !sysml_enum_is(value) { return []; }
        names.push(value.literal);
    }
    names
}

fn _position_values(source, name) {
    let values = sysml_requirements::native_value(source, _configuration_attr(name));
    if values == () || !array_is(values) { return []; }
    for value in values { if !vec3_is_native(value) { return []; } }
    values
}

fn _exists(id, requirement, path, expected_type) {
    #{id: id, component: "lander", requirement: requirement,
      verification: VERIFICATION, kind: "exists", path: path,
      expected_type: expected_type, visible: true}
}

fn _children(id, requirement, path, paths) {
    #{id: id, component: "lander", requirement: requirement,
      verification: VERIFICATION, kind: "children", path: path,
      paths: paths, visible: true}
}

fn _coverage(id, requirement) {
    #{id: id, component: "lander", requirement: requirement,
      verification: VERIFICATION, kind: "coverage"}
}

fn _position(id, requirement, path, index, expected) {
    #{id: id, component: "placement", requirement: requirement,
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected,
      tolerance: 0.002}
}

fn _rotation_y(id, requirement, path, expected) {
    #{id: id, component: "placement", requirement: requirement,
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:rotateXYZ", index: 1, expected: expected,
      tolerance: 0.002}
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let selected_attributes = [
        _configuration_attr("landingLegInstances"), _configuration_attr("tankInstances"),
        _configuration_attr("mainEngineInstances"), _configuration_attr("solarArrayInstances"),
        _configuration_attr("legStations"), _configuration_attr("tankStations"),
        _configuration_attr("engineStations"), _configuration_attr("solarStations"),
        _configuration_attr("legStationRotationYDeg"), _configuration_attr("solarStationRotationZDeg"),
        _configuration_attr("bodyMount"), _configuration_attr("bodyDimensions"),
        _source_attr("visualEnvelopeToleranceM"), _source_attr("legCount"), _source_attr("tankCount"),
        _source_attr("engineCount"), _source_attr("solarArrayCount")
    ];
    let source = sysml_requirements::source_with_selection(selected_attributes, [
        "GriffinLanderRequirements::glr001", "GriffinLanderRequirements::glr002",
        "GriffinLanderRequirements::glr003", "GriffinLanderRequirements::glr004",
        "GriffinLanderRequirements::glr005", "GriffinLanderRequirements::glr006",
        "GriffinLanderRequirements::glr007", "GriffinLanderRequirements::glr008",
        "GriffinLanderRequirements::glr009", "GriffinLanderRequirements::glr010",
        "GriffinLanderRequirements::glr011"
    ], ["GriffinLanderRequirements::Verify_GriffinLanderRequirements"]);
    let values = source;
    let checks = [];

    checks.push(_exists("GLR-001-root", "glr001", ROOT, "Xform"));
    checks.push(_children("GLR-001-bus", "glr001", ROOT + "/Bus",
        [ROOT + "/Bus/PerimeterFrame", ROOT + "/Bus/LowerServiceSkirtOctagon", ROOT + "/Bus/TopDeckOctagon"]));
    let body_mount = sysml_requirements::native_value(values,
        _configuration_attr("bodyMount"));
    checks.push(#{id: "GLR-008-bus-y", component: "bus",
        requirement: "glr008", verification: VERIFICATION,
        kind: "attribute_component", path: ROOT + "/Bus", attr: "xformOp:translate",
        index: 1, expected: body_mount.y, tolerance: 0.002});

    let leg_names = _enum_names(values, "landingLegInstances");
    let leg_stations = _position_values(values, "legStations");
    let leg_rot_y = sysml_requirement_checks::source_number_list(values,
        _configuration_attr("legStationRotationYDeg"));
    for index in 0..leg_names.len() {
        let name = leg_names[index];
        let path = ROOT + "/" + name;
        checks.push(_exists("GLR-002-" + name, "glr002", path, "Xform"));
        let visual_path = path + "/LandingLegVisual";
        checks.push(_children("GLR-002-" + name + "-parts", "glr002", visual_path,
            [visual_path + "/StrutOuter", visual_path + "/StrutInner",
             visual_path + "/FootPad"]));
        // The shock piston is the physical `<leg>/ShockPiston` body; its
        // visual copy is hidden and owned by griffin_landing_legs_requirements.
        if leg_stations.len() == leg_names.len() {
            checks.push(_position("GLR-008-" + name + "-x", "glr008", path, 0, leg_stations[index].x));
            checks.push(_position("GLR-008-" + name + "-y", "glr008", path, 1, leg_stations[index].y));
            checks.push(_position("GLR-008-" + name + "-z", "glr008", path, 2, leg_stations[index].z));
        }
        if leg_rot_y.len() == leg_names.len() {
            checks.push(_rotation_y("GLR-008-" + name + "-rotation-y",
                "glr008", path, leg_rot_y[index]));
        }
    }
    let tank_names = _enum_names(values, "tankInstances");
    let tank_stations = _position_values(values, "tankStations");
    for index in 0..tank_names.len() {
        let name = tank_names[index];
        let path = ROOT + "/" + name;
        checks.push(_exists("GLR-003-" + name, "glr003", path, "Xform"));
        checks.push(_children("GLR-003-" + name + "-parts", "glr003", path,
            [path + "/MliTank", path + "/TankBandA", path + "/TankBandB", path + "/TankBandC"]));
        if tank_stations.len() == tank_names.len() {
            checks.push(_position("GLR-008-" + name + "-x", "glr008", path, 0, tank_stations[index].x));
            checks.push(_position("GLR-008-" + name + "-y", "glr008", path, 1, tank_stations[index].y));
            checks.push(_position("GLR-008-" + name + "-z", "glr008", path, 2, tank_stations[index].z));
        }
    }
    let engine_names = _enum_names(values, "mainEngineInstances");
    let engine_stations = _position_values(values, "engineStations");
    for index in 0..engine_names.len() {
        let name = engine_names[index];
        let path = ROOT + "/Nozzle/MainEngineCluster/" + name;
        checks.push(_exists("GLR-004-" + name, "glr004", path, "Xform"));
        checks.push(_children("GLR-004-" + name + "-parts", "glr004", path,
            [path + "/Bell", path + "/Throat"]));
        if engine_stations.len() == engine_names.len() {
            checks.push(_position("GLR-008-" + name + "-x", "glr008", path, 0, engine_stations[index].x));
            checks.push(_position("GLR-008-" + name + "-y", "glr008", path, 1, engine_stations[index].y));
            checks.push(_position("GLR-008-" + name + "-z", "glr008", path, 2, engine_stations[index].z));
        }
    }
    let solar_names = _enum_names(values, "solarArrayInstances");
    // solarStations are bus attachment datums; the installed panel centre
    // rises by half the frame-height difference (griffin_solar_requirements).
    let solar_stations = griffin_spec::component_solar_stations();
    for index in 0..solar_names.len() {
        let name = solar_names[index];
        let path = ROOT + "/" + name;
        checks.push(_exists("GLR-005-" + name, "glr005", path, "Xform"));
        checks.push(_children("GLR-005-" + name + "-parts", "glr005", path,
            [path + "/Frame", path + "/Cells"]));
        if solar_stations.len() == solar_names.len() {
            checks.push(_position("GLR-008-" + name + "-x", "glr008", path, 0, solar_stations[index].x));
            checks.push(_position("GLR-008-" + name + "-y", "glr008", path, 1, solar_stations[index].y));
            checks.push(_position("GLR-008-" + name + "-z", "glr008", path, 2, solar_stations[index].z));
        }
        for check in griffin_requirements::solar_orientation_checks(
            "GLR-011-" + name, path, index, "glr011", VERIFICATION) { checks.push(check); }

    }

    checks.push(sysml_requirement_checks::coverage("GLR-010-frame-ownership", "lander",
        "glr010", VERIFICATION));

    let body_dimensions = sysml_requirements::native_value(values,
        _configuration_attr("bodyDimensions"));
    let envelope_tolerance = sysml_requirements::native_value(values,
        _source_attr("visualEnvelopeToleranceM"));
    checks.push(#{id: "GLR-006-width", component: "bus",
        requirement: "glr006", verification: VERIFICATION,
        kind: "bounds_component", path: ROOT + "/Bus/PerimeterFrame", index: 0,
        multiplier: 2.0, expected: body_dimensions.x, tolerance: envelope_tolerance});
    checks.push(#{id: "GLR-006-depth", component: "bus",
        requirement: "glr006", verification: VERIFICATION,
        kind: "bounds_component", path: ROOT + "/Bus/PerimeterFrame", index: 2,
        multiplier: 2.0, expected: body_dimensions.z, tolerance: envelope_tolerance});
    checks.push(#{id: "GLR-006-height", component: "bus",
        requirement: "glr006", verification: VERIFICATION,
        kind: "bounds_component", path: ROOT + "/Bus/PerimeterFrame", index: 1,
        multiplier: 2.0, expected: body_dimensions.y, tolerance: envelope_tolerance});
    for subsystem in [
        #{id: "legs", identities: "landingLegInstances", stations: "legStations", count: "legCount"},
        #{id: "tanks", identities: "tankInstances", stations: "tankStations", count: "tankCount"},
        #{id: "engines", identities: "mainEngineInstances", stations: "engineStations", count: "engineCount"},
        #{id: "solar", identities: "solarArrayInstances", stations: "solarStations", count: "solarArrayCount"}
    ] {
        checks.push(sysml_requirement_checks::source_list_count(
            "GLR-007-" + subsystem.id + "-identity-count", "lander", "glr007",
            VERIFICATION, _configuration_attr(subsystem.identities),
            _source_attr(subsystem.count)));
        checks.push(sysml_requirement_checks::source_list_count(
            "GLR-007-" + subsystem.id + "-station-count", "lander", "glr007",
            VERIFICATION, _configuration_attr(subsystem.stations),
            _source_attr(subsystem.count)));
    }
    checks.push(_coverage("GLR-007-source", "glr007"));

    let result = sysml_requirements::evaluate(source, checks);
    result.metrics = #{clock: clock_snapshot(), root: ROOT, integrated_vehicle_document: true};
    report_structured_verdict(result, "GRIFFIN LANDER REQUIREMENTS", "GRIFFIN_LANDER_REQUIREMENTS");
    this.done = true;
}
