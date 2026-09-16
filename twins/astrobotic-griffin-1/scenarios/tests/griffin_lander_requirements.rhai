// Standalone Griffin lander component verification.
// SysML owns names/counts/dimensions and references; this Rhai observer only
// queries the composed USD and emits the generic structured verdict.

const ROOT = "/World/Griffin1";
const VERIFICATION = "GriffinLanderRequirements::Verify_GriffinLanderRequirements";

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn _source_attr(name) {
    "GriffinLanderRequirements::GriffinLanderComponent::" + name
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

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let checks = [];

    checks.push(_exists("GLR-001-root", "GriffinLanderRequirements::glr001", ROOT, "Xform"));
    checks.push(_children("GLR-001-bus", "GriffinLanderRequirements::glr001", ROOT + "/Bus",
        [ROOT + "/Bus/PerimeterFrame", ROOT + "/Bus/WhiteEquipmentBox", ROOT + "/Bus/TopDeck"]));
    checks.push(#{id: "GLR-001-profile", component: "bus",
        requirement: "GriffinLanderRequirements::glr001", verification: VERIFICATION,
        kind: "attribute_equals", path: ROOT + "/Bus", attr: "lunco:visual:body_profile",
        expected: "hexagonal-prism"});
    checks.push(#{id: "GLR-008-bus-y", component: "bus",
        requirement: "GriffinLanderRequirements::glr008", verification: VERIFICATION,
        kind: "attribute_component", path: ROOT + "/Bus", attr: "xformOp:translate",
        index: 1, expected_attr: _source_attr("busMountY"), tolerance: 0.002});

    let leg_names = _list(source, "legNames");
    let leg_x = component_requirements::source_number_list(source, _source_attr("legStationX"));
    let leg_y = component_requirements::source_number_list(source, _source_attr("legStationY"));
    let leg_z = component_requirements::source_number_list(source, _source_attr("legStationZ"));
    for axis in ["legStationX", "legStationY", "legStationZ"] {
        checks.push(component_requirements::source_list_count("GLR-008-" + axis,
            "placement", "GriffinLanderRequirements::glr008", VERIFICATION,
            _source_attr(axis), _source_attr("legCount")));
    }
    for index in 0..leg_names.len() {
        let name = leg_names[index];
        let path = ROOT + "/" + name;
        checks.push(_exists("GLR-002-" + name, "GriffinLanderRequirements::glr002", path, "Xform"));
        checks.push(_children("GLR-002-" + name + "-parts", "GriffinLanderRequirements::glr002", path,
            [path + "/StrutOuter", path + "/StrutInner", path + "/ShockPiston", path + "/FootPad"]));
        if leg_x.len() == leg_names.len() && leg_y.len() == leg_names.len() && leg_z.len() == leg_names.len() {
            checks.push(_position("GLR-008-" + name + "-x", "GriffinLanderRequirements::glr008", path, 0, leg_x[index]));
            checks.push(_position("GLR-008-" + name + "-y", "GriffinLanderRequirements::glr008", path, 1, leg_y[index]));
            checks.push(_position("GLR-008-" + name + "-z", "GriffinLanderRequirements::glr008", path, 2, leg_z[index]));
        }
    }
    let tank_names = _list(source, "tankNames");
    let tank_x = component_requirements::source_number_list(source, _source_attr("tankStationX"));
    let tank_y = component_requirements::source_number_list(source, _source_attr("tankStationY"));
    let tank_z = component_requirements::source_number_list(source, _source_attr("tankStationZ"));
    for axis in ["tankStationX", "tankStationY", "tankStationZ"] {
        checks.push(component_requirements::source_list_count("GLR-008-" + axis,
            "placement", "GriffinLanderRequirements::glr008", VERIFICATION,
            _source_attr(axis), _source_attr("tankCount")));
    }
    for index in 0..tank_names.len() {
        let name = tank_names[index];
        let path = ROOT + "/" + name;
        checks.push(_exists("GLR-003-" + name, "GriffinLanderRequirements::glr003", path, "Xform"));
        checks.push(_children("GLR-003-" + name + "-parts", "GriffinLanderRequirements::glr003", path,
            [path + "/MliTank", path + "/TankBandA", path + "/TankBandB", path + "/TankBandC"]));
        if tank_x.len() == tank_names.len() && tank_y.len() == tank_names.len() && tank_z.len() == tank_names.len() {
            checks.push(_position("GLR-008-" + name + "-x", "GriffinLanderRequirements::glr008", path, 0, tank_x[index]));
            checks.push(_position("GLR-008-" + name + "-y", "GriffinLanderRequirements::glr008", path, 1, tank_y[index]));
            checks.push(_position("GLR-008-" + name + "-z", "GriffinLanderRequirements::glr008", path, 2, tank_z[index]));
        }
    }
    let engine_names = _list(source, "engineNames");
    let engine_x = component_requirements::source_number_list(source, _source_attr("engineStationX"));
    let engine_y = component_requirements::source_number_list(source, _source_attr("engineStationY"));
    let engine_z = component_requirements::source_number_list(source, _source_attr("engineStationZ"));
    for axis in ["engineStationX", "engineStationY", "engineStationZ"] {
        checks.push(component_requirements::source_list_count("GLR-008-" + axis,
            "placement", "GriffinLanderRequirements::glr008", VERIFICATION,
            _source_attr(axis), _source_attr("engineCount")));
    }
    for index in 0..engine_names.len() {
        let name = engine_names[index];
        let path = ROOT + "/Nozzle/MainEngineCluster/" + name;
        checks.push(_exists("GLR-004-" + name, "GriffinLanderRequirements::glr004", path, "Xform"));
        checks.push(_children("GLR-004-" + name + "-parts", "GriffinLanderRequirements::glr004", path,
            [path + "/Bell", path + "/Throat"]));
        if engine_x.len() == engine_names.len() && engine_y.len() == engine_names.len() && engine_z.len() == engine_names.len() {
            checks.push(_position("GLR-008-" + name + "-x", "GriffinLanderRequirements::glr008", path, 0, engine_x[index]));
            checks.push(_position("GLR-008-" + name + "-y", "GriffinLanderRequirements::glr008", path, 1, engine_y[index]));
            checks.push(_position("GLR-008-" + name + "-z", "GriffinLanderRequirements::glr008", path, 2, engine_z[index]));
        }
    }
    let solar_names = _list(source, "solarArrayNames");
    let solar_x = component_requirements::source_number_list(source, _source_attr("solarStationX"));
    let solar_y = component_requirements::source_number_list(source, _source_attr("solarStationY"));
    let solar_z = component_requirements::source_number_list(source, _source_attr("solarStationZ"));
    for axis in ["solarStationX", "solarStationY", "solarStationZ"] {
        checks.push(component_requirements::source_list_count("GLR-008-" + axis,
            "placement", "GriffinLanderRequirements::glr008", VERIFICATION,
            _source_attr(axis), _source_attr("solarArrayCount")));
    }
    for index in 0..solar_names.len() {
        let name = solar_names[index];
        let path = ROOT + "/" + name;
        checks.push(_exists("GLR-005-" + name, "GriffinLanderRequirements::glr005", path, "Xform"));
        checks.push(_children("GLR-005-" + name + "-parts", "GriffinLanderRequirements::glr005", path,
            [path + "/Frame", path + "/Cells"]));
        if solar_x.len() == solar_names.len() && solar_y.len() == solar_names.len() && solar_z.len() == solar_names.len() {
            checks.push(_position("GLR-008-" + name + "-x", "GriffinLanderRequirements::glr008", path, 0, solar_x[index]));
            checks.push(_position("GLR-008-" + name + "-y", "GriffinLanderRequirements::glr008", path, 1, solar_y[index]));
            checks.push(_position("GLR-008-" + name + "-z", "GriffinLanderRequirements::glr008", path, 2, solar_z[index]));
        }
    }

    checks.push(#{id: "GLR-006-width", component: "bus",
        requirement: "GriffinLanderRequirements::glr006", verification: VERIFICATION,
        kind: "bounds_component", path: ROOT + "/Bus/WhiteEquipmentBox", index: 0,
        multiplier: 2.0, expected_attr: _source_attr("bodyWidthM"), tolerance: 0.002});
    checks.push(#{id: "GLR-006-depth", component: "bus",
        requirement: "GriffinLanderRequirements::glr006", verification: VERIFICATION,
        kind: "bounds_component", path: ROOT + "/Bus/WhiteEquipmentBox", index: 2,
        multiplier: 2.0, expected_attr: _source_attr("bodyDepthM"), tolerance: 0.002});
    checks.push(#{id: "GLR-006-height", component: "bus",
        requirement: "GriffinLanderRequirements::glr006", verification: VERIFICATION,
        kind: "bounds_component", path: ROOT + "/Bus/WhiteEquipmentBox", index: 1,
        multiplier: 2.0, expected_attr: _source_attr("bodyHeightM"), tolerance: 0.002});
    for pair in [
        #{id: "GLR-007-leg-count", list: "legNames", count: "legCount"},
        #{id: "GLR-007-tank-count", list: "tankNames", count: "tankCount"},
        #{id: "GLR-007-engine-count", list: "engineNames", count: "engineCount"},
        #{id: "GLR-007-solar-count", list: "solarArrayNames", count: "solarArrayCount"}
    ] {
        checks.push(#{id: pair.id, component: "lander",
            requirement: "GriffinLanderRequirements::glr007", verification: VERIFICATION,
            kind: "source_list_count", list_attr: _source_attr(pair.list),
            expected_attr: _source_attr(pair.count)});
    }
    checks.push(_coverage("GLR-007-source", "GriffinLanderRequirements::glr007"));

    let result = sysml_requirements::evaluate(source, checks);
    result.metrics = #{clock: clock_snapshot(), root: ROOT, separate_component_document: true};
    report_structured_verdict(result, "GRIFFIN LANDER REQUIREMENTS", "GRIFFIN_LANDER_REQUIREMENTS");
    this.done = true;
}
