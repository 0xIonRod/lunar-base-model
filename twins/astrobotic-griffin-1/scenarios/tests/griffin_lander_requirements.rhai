// Standalone Griffin lander component verification.
// SysML owns names/counts/dimensions and references; this Rhai observer only
// queries the composed USD and emits the generic structured verdict.

const ROOT = "/World/Griffin1";
const VERIFICATION = "GriffinLanderRequirements::Verify_GriffinLanderRequirements";

fn on_start(me) {
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

fn on_tick(me) {
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

    let leg_names = _list(source, "legNames");
    for name in leg_names {
        let path = ROOT + "/" + name;
        checks.push(_exists("GLR-002-" + name, "GriffinLanderRequirements::glr002", path, "Xform"));
        checks.push(_children("GLR-002-" + name + "-parts", "GriffinLanderRequirements::glr002", path,
            [path + "/StrutOuter", path + "/StrutInner", path + "/ShockPiston", path + "/FootPad"]));
    }
    let tank_names = _list(source, "tankNames");
    for name in tank_names {
        let path = ROOT + "/" + name;
        checks.push(_exists("GLR-003-" + name, "GriffinLanderRequirements::glr003", path, "Xform"));
        checks.push(_children("GLR-003-" + name + "-parts", "GriffinLanderRequirements::glr003", path,
            [path + "/MliTank", path + "/TankBandA", path + "/TankBandB", path + "/TankBandC"]));
    }
    let engine_names = _list(source, "engineNames");
    for name in engine_names {
        let path = ROOT + "/Nozzle/MainEngineCluster/" + name;
        checks.push(_exists("GLR-004-" + name, "GriffinLanderRequirements::glr004", path, "Xform"));
        checks.push(_children("GLR-004-" + name + "-parts", "GriffinLanderRequirements::glr004", path,
            [path + "/Bell", path + "/Throat"]));
    }
    let solar_names = _list(source, "solarArrayNames");
    for name in solar_names {
        let path = ROOT + "/" + name;
        checks.push(_exists("GLR-005-" + name, "GriffinLanderRequirements::glr005", path, "Xform"));
        checks.push(_children("GLR-005-" + name + "-parts", "GriffinLanderRequirements::glr005", path,
            [path + "/Frame", path + "/Cells"]));
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
