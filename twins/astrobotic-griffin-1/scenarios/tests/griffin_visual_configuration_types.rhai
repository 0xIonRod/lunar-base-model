// Twin-level positive verification for native SysML-to-Rhai geometry values.
// Engineering stations and envelopes cross as f64 vectors and typed enums.

const PACKAGE = "GriffinVisualConfigurationRequirements";
const VERIFICATION = "Verify_GriffinVisualConfiguration";
const PART = PACKAGE + "::GriffinVisualConfiguration::";

fn _resolved(source, name) {
    sysml_requirements::attribute(source, PART + name)
}

fn _native_value(source, name) {
    let resolved = _resolved(source, name);
    if resolved.ok != true { return (); }
    sysml_requirements::native_value(source, PART + name)
}

fn typed_collection_check(source, id, requirement, field, base, count, item_type) {
    let resolved = _resolved(source, field);
    let values = _native_value(source, field);
    let ok = resolved.ok == true && values != () && type_of(values) == "array"
        && resolved.record.declared_type.base == base
        && resolved.record.declared_type.dimensions.len() == 1
        && resolved.record.declared_type.dimensions[0] == count
        && values.len() == count;
    if ok {
        for value in values {
            if type_of(value) != item_type { ok = false; }
            if item_type == "Vec3" && !vec3_is_finite(value) { ok = false; }
            if item_type == "Vec2" && !vec2_is_finite(value) { ok = false; }
        }
    }
    component_requirements::assertion(id, "griffin.typed_geometry",
        requirement, VERIFICATION, ok,
        "SysML collection must retain its declared native element type: " + field,
        #{field: field, declared_base: if resolved.ok { resolved.record.declared_type.base } else { "" },
          count: if values == () { 0 } else { values.len() }, item_type: item_type},
        #{base: base, count: count, item_type: item_type})
}

fn typed_spatial_scalar_check(source, id, requirement, field) {
    let value = _native_value(source, field);
    let ok = value != () && type_of(value) == "Vec3" && vec3_is_finite(value);
    component_requirements::assertion(id, "griffin.typed_geometry",
        requirement, VERIFICATION, ok,
        "SysML spatial value must project to the shared finite f64 Vec3: " + field,
        #{field: field, value: value}, "finite Vec3")
}

fn typed_enum_check(source, id, requirement, field, expected_literal) {
    let value = _native_value(source, field);
    let ok = value != () && type_of(value) == "EnumValue"
        && value.literal == expected_literal;
    component_requirements::assertion(id, "griffin.typed_configuration",
        requirement, VERIFICATION, ok,
        "configuration choice must remain a SysML enumeration: " + field,
        #{field: field, value: value}, expected_literal)
}

fn _plan_record(plan, name) {
    for record in plan { if record.name == name { return record; } }
    ()
}

fn native_transform_plan_check() {
    let plan = griffin_spec::visual_component_transform_plan();
    let rails = griffin_spec::visual_rail_station_plan();
    let bus = _plan_record(plan, "Bus");
    let tank = _plan_record(plan, "TankPX");
    let solar = _plan_record(plan, "SolarPanelPort");
    let engine = _plan_record(plan, "Engine01");
    let ok = plan.len() == 27 && rails.len() == 6
        && bus != () && tank != () && solar != () && engine != ()
        && transform_is_finite(bus.pose) && transform_is_finite(tank.pose)
        && transform_is_finite(solar.pose) && transform_is_finite(engine.pose)
        && transform_is_finite(rails[0].pose)
        && vec3_is_finite(tank.translation) && quat_is_finite(tank.rotation)
        && vec3_is_finite(solar.translation) && quat_is_finite(solar.rotation)
        && vec3_is_finite(engine.translation) && quat_is_finite(engine.rotation)
        && vec3_is_finite(rails[0].translation) && vec3_is_finite(rails[0].scale);
    component_requirements::assertion("GVC-T-native-plan", "griffin.typed_geometry",
        "gvc002", VERIFICATION, ok,
        "SysML-derived plan must carry native f64 Transform and Vec3 values to the builder",
        #{component_count: plan.len(), rail_count: rails.len()},
        #{component_count: 27, rail_count: 6})
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source_with_attributes([
        PART + "bodyDimensions", PART + "bodyMount", PART + "railDimensions",
        PART + "hexProfileCoordinates",
        PART + "railStations", PART + "legStations", PART + "tankStations",
        PART + "solarStations", PART + "engineStations", PART + "frameRails",
        PART + "frameOpenBayPanels", PART + "tankInstances",
        PART + "landingLegInstances", PART + "solarArrayInstances",
        PART + "mainEngineInstances", PART + "bodyProfile", PART + "rampState",
        "GriffinRampRequirements::GriffinEgressRamp::rampPortMountX",
        "GriffinRampRequirements::GriffinEgressRamp::rampStarboardMountX"
    ]);
    let checks = [
        typed_spatial_scalar_check(source, "GVC-T-body-dimensions", "gvc003", "bodyDimensions"),
        typed_spatial_scalar_check(source, "GVC-T-body-mount", "gvc002", "bodyMount"),
        typed_spatial_scalar_check(source, "GVC-T-rail-dimensions", "gvc012", "railDimensions"),
        typed_collection_check(source, "GVC-T-hex-profile", "gvc014",
            "hexProfileCoordinates", "CartesianVectorValue", 6, "Vec2"),
        typed_collection_check(source, "GVC-T-rail-stations", "gvc012", "railStations", "Position", 6, "Vec3"),
        typed_collection_check(source, "GVC-T-leg-stations", "gvc005", "legStations", "Position", 4, "Vec3"),
        typed_collection_check(source, "GVC-T-tank-stations", "gvc007", "tankStations", "Position", 4, "Vec3"),
        typed_collection_check(source, "GVC-T-solar-stations", "gvc006", "solarStations", "Position", 2, "Vec3"),
        typed_collection_check(source, "GVC-T-engine-stations", "gvc008", "engineStations", "Position", 7, "Vec3"),
        typed_collection_check(source, "GVC-T-frame-rail-identities", "gvc012", "frameRails", "GriffinFrameRailNode", 6, "EnumValue"),
        typed_collection_check(source, "GVC-T-open-bay-identities", "gvc009", "frameOpenBayPanels", "GriffinOpenBayPanelNode", 6, "EnumValue"),
        typed_collection_check(source, "GVC-T-tank-identities", "gvc007", "tankInstances", "GriffinTankInstanceName", 4, "EnumValue"),
        typed_collection_check(source, "GVC-T-leg-identities", "gvc005", "landingLegInstances", "GriffinLandingLegInstanceName", 4, "EnumValue"),
        typed_collection_check(source, "GVC-T-solar-identities", "gvc006", "solarArrayInstances", "GriffinSolarArrayInstanceName", 2, "EnumValue"),
        typed_collection_check(source, "GVC-T-engine-identities", "gvc008", "mainEngineInstances", "GriffinMainEngineInstanceName", 7, "EnumValue"),
        typed_enum_check(source, "GVC-T-body-profile", "gvc003", "bodyProfile", "HexagonalOpenFrame"),
        typed_enum_check(source, "GVC-T-ramp-state", "gvc009", "rampState", "Stowed"),
        native_transform_plan_check(),
        component_requirements::assertion("GVC-T-ramp-source", "griffin.typed_configuration",
            "gvc009", VERIFICATION,
            sysml_requirements::number(source,
                "GriffinRampRequirements::GriffinEgressRamp::rampPortMountX") != ()
                && sysml_requirements::number(source,
                "GriffinRampRequirements::GriffinEgressRamp::rampStarboardMountX") != (),
            "ramp placement resolves from the dedicated Griffin ramp subsystem contract",
            "GriffinRampRequirements::GriffinEgressRamp", "typed ramp mount datums")
    ];
    component_requirements::finish(source, checks,
        "GRIFFIN VISUAL CONFIGURATION TYPES", "GRIFFIN_VISUAL_CONFIGURATION_TYPES",
        "/Griffin1", PACKAGE, VERIFICATION);
    this.done = true;
}
