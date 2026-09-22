// Twin-level positive verification for native SysML-to-Rhai geometry values.
// Engineering stations and envelopes cross as f64 vectors and typed enums.

import "/scripting/tools/mechanical_relations" as mechanical_relations;

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
    let ok = resolved.ok == true && values != () && array_is(values)
        && resolved.record.declared_type.base == base
        && resolved.record.declared_type.dimensions.len() == 1
        && resolved.record.declared_type.dimensions[0] == count
        && values.len() == count;
    if ok {
        for value in values {
            let item_ok = if item_type == "Vec3" {
                vec3_is_native(value) && vec3_is_finite(value)
            } else if item_type == "Vec2" {
                vec2_is_native(value) && vec2_is_finite(value)
            } else if item_type == "EnumValue" {
                sysml_enum_is(value)
            } else { false };
            if !item_ok { ok = false; }
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
    let ok = value != () && vec3_is_native(value) && vec3_is_finite(value);
    component_requirements::assertion(id, "griffin.typed_geometry",
        requirement, VERIFICATION, ok,
        "SysML spatial value must project to the shared finite f64 Vec3: " + field,
        #{field: field, value: value}, "finite Vec3")
}

fn typed_enum_check(source, id, requirement, field, expected_literal) {
    let value = _native_value(source, field);
    let ok = value != () && sysml_enum_is(value)
        && value.literal == expected_literal;
    component_requirements::assertion(id, "griffin.typed_configuration",
        requirement, VERIFICATION, ok,
        "configuration choice must remain a SysML enumeration: " + field,
        #{field: field, value: value}, expected_literal)
}

fn display_color_check(source) {
    let fields = ["frameDisplayColor", "deckDisplayColor", "lowerSkirtDisplayColor",
        "avionicsDeckDisplayColor", "avionicsPodDisplayColor", "railDisplayColor",
        "tankSupportDisplayColor", "tankCollarDisplayColor"];
    let evidence = [];
    let ok = true;
    for field in fields {
        let values = _native_value(source, field);
        let valid = array_is(values) && values.len() == 3;
        if valid {
            for channel in values {
                let scalar = f64_from(channel);
                if scalar == () || scalar < 0.0 || scalar > 1.0 { valid = false; }
            }
        }
        evidence.push(#{field: field, values: values, valid: valid});
        if !valid { ok = false; }
    }
    component_requirements::assertion("GVC-T-linear-display-colors",
        "griffin.typed_configuration", "gvc015", VERIFICATION, ok,
        "all component display colors must be source-owned three-channel linear values in [0,1]",
        evidence, #{fields: fields, channels: 3, range: [0.0, 1.0]})
}

fn _plan_record(plan, name) {
    for record in plan { if record.name == name { return record; } }
    ()
}

fn tank_station_layout_check(source) {
    let body_mount = _native_value(source, "bodyMount");
    let names = _native_value(source, "tankInstances");
    let stations = _native_value(source, "tankStations");
    let tank_count = if array_is(names) { names.len() } else { 0 };
    let station_count = if array_is(stations) { stations.len() } else { 0 };
    let ok = vec3_is_native(body_mount) && vec3_is_finite(body_mount)
        && tank_count == 4 && station_count == 4;
    if ok {
        let orbital_radius = if vec3_is_native(stations[0]) {
            (stations[0].x * stations[0].x + stations[0].z * stations[0].z).sqrt()
        } else { -1.0 };
        for index in 0..stations.len() {
            let station = stations[index];
            if !vec3_is_native(station) || !vec3_is_finite(station)
                || (station.y - body_mount.y).abs() > 0.000001
                || (station.x * station.z).abs() > 0.000001
                || ((station.x * station.x + station.z * station.z).sqrt()
                    - orbital_radius).abs() > 0.000001 {
                ok = false;
            }
            let name = if sysml_enum_is(names[index]) { names[index].literal } else { "" };
            if (name == "TankPX" && !(station.x > 0.0 && station.z == 0.0))
                || (name == "TankNX" && !(station.x < 0.0 && station.z == 0.0))
                || (name == "TankPZ" && !(station.x == 0.0 && station.z > 0.0))
                || (name == "TankNZ" && !(station.x == 0.0 && station.z < 0.0)) {
                ok = false;
            }
        }
    }
    component_requirements::assertion("GVC-T-tank-layout", "griffin.typed_geometry",
        "gvc007", VERIFICATION, ok,
        "the four named tanks occupy equally spaced cardinal stations on the bus-origin plane",
        #{tank_count: tank_count,
          station_y: if station_count == 0 { () } else { stations[0].y },
          body_mount_y: if body_mount == () { () } else { body_mount.y }},
        #{tank_count: 4, station_y: if body_mount == () { () } else { body_mount.y }})
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

fn typed_relation_check(source) {
    let body_mount = _native_value(source, "bodyMount");
    let axis_up = _native_value(source, "axisUp");
    let tank_stations = _native_value(source, "tankStations");
    let leg_stations = _native_value(source, "legStations");
    let engine_stations = _native_value(source, "engineStations");
    let tolerance = sysml_requirements::number(source, PART + "verificationToleranceM");
    let ok = vec3_is_native(body_mount) && vec3_is_native(axis_up)
        && array_is(tank_stations) && array_is(leg_stations)
        && array_is(engine_stations) && tolerance != ()
        && vec3_is_finite(body_mount) && vec3_is_finite(axis_up)
        && vlen(axis_up) > 1.0e-12;
    let plane_relations = [];
    let under_relations = [];
    if ok {
        for station in tank_stations {
            let distance = mechanical_relations::plane_signed_distance(
                station, body_mount, axis_up);
            let relation = mechanical_relations::equal(distance, 0.0, tolerance);
            plane_relations.push(relation);
            if relation == () || relation.status != "passed" { ok = false; }
        }
        for station in leg_stations {
            let distance = mechanical_relations::plane_signed_distance(
                body_mount, station, axis_up);
            let relation = mechanical_relations::at_least(distance, 0.0, tolerance);
            under_relations.push(relation);
            if relation == () || relation.status != "passed" { ok = false; }
        }
        for station in engine_stations {
            let distance = mechanical_relations::plane_signed_distance(
                body_mount, station, axis_up);
            let relation = mechanical_relations::at_least(distance, 0.0, tolerance);
            under_relations.push(relation);
            if relation == () || relation.status != "passed" { ok = false; }
        }
    }
    component_requirements::assertion("GVC-T-relations", "griffin.typed_geometry",
        "gvc010", VERIFICATION, ok,
        "source-backed stations must satisfy generic plane-coincidence and under relations",
        #{plane_relations: plane_relations, under_relations: under_relations,
          tolerance_m: tolerance},
        #{tank_plane_distance_m: 0.0, legs_and_engines_under_body: true,
          tolerance_m: tolerance})
}

fn typed_symmetry_check(source) {
    let body_mount = _native_value(source, "bodyMount");
    let axis_port = _native_value(source, "axisPort");
    let axis_forward = _native_value(source, "axisForward");
    let tank_stations = _native_value(source, "tankStations");
    let leg_stations = _native_value(source, "legStations");
    let tolerance = sysml_requirements::number(source, PART + "verificationToleranceM");
    let ok = vec3_is_native(body_mount) && vec3_is_native(axis_port)
        && vec3_is_native(axis_forward) && array_is(tank_stations)
        && array_is(leg_stations) && tank_stations.len() == 4
        && leg_stations.len() == 4 && tolerance != ()
        && vec3_is_finite(body_mount) && vec3_is_finite(axis_port)
        && vec3_is_finite(axis_forward);
    let relations = [];
    if ok {
        relations.push(mechanical_relations::symmetric_pairs_about_plane(
            [tank_stations[0]], [tank_stations[1]], body_mount, axis_port, tolerance));
        relations.push(mechanical_relations::symmetric_pairs_about_plane(
            [tank_stations[2]], [tank_stations[3]], body_mount, axis_forward, tolerance));
        relations.push(mechanical_relations::symmetric_pairs_about_plane(
            [leg_stations[0]], [leg_stations[1]], body_mount, axis_port, tolerance));
        relations.push(mechanical_relations::symmetric_pairs_about_plane(
            [leg_stations[2]], [leg_stations[3]], body_mount, axis_forward, tolerance));
        for relation in relations {
            if relation == () || relation.status != "passed" { ok = false; }
        }
    }
    component_requirements::assertion("GVC-T-symmetry", "griffin.typed_geometry",
        "gvc010", VERIFICATION, ok,
        "ordered component stations must be mirrored across their authored symmetry planes",
        #{relations: relations, tolerance_m: tolerance},
        #{tank_pairs: 2, leg_pairs: 2, tolerance_m: tolerance})
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source_with_selection([
        PART + "bodyDimensions", PART + "bodyMount", PART + "axisPort",
        PART + "axisForward", PART + "axisUp", PART + "railDimensions",
        PART + "outerBodyProfileCoordinates",
        PART + "railStations", PART + "legStations", PART + "tankStations",
        PART + "bodyMount",
        PART + "solarStations", PART + "engineStations", PART + "frameRails",
        PART + "tankInstances",
        PART + "landingLegInstances", PART + "solarArrayInstances",
        PART + "mainEngineInstances", PART + "bodyProfile", PART + "rampState",
        PART + "frameDisplayColor", PART + "deckDisplayColor", PART + "lowerSkirtDisplayColor",
        PART + "avionicsDeckDisplayColor", PART + "avionicsPodDisplayColor",
        PART + "railDisplayColor", PART + "tankSupportDisplayColor", PART + "tankCollarDisplayColor",
        PART + "verificationToleranceM",
        "GriffinRampRequirements::GriffinEgressRamp::rampPortMountX",
        "GriffinRampRequirements::GriffinEgressRamp::rampStarboardMountX"
    ], [
        PACKAGE + "::gvc001", PACKAGE + "::gvc002", PACKAGE + "::gvc003",
        PACKAGE + "::gvc004", PACKAGE + "::gvc005", PACKAGE + "::gvc006",
        PACKAGE + "::gvc007", PACKAGE + "::gvc008", PACKAGE + "::gvc009",
        PACKAGE + "::gvc010", PACKAGE + "::gvc011", PACKAGE + "::gvc012",
        PACKAGE + "::gvc013", PACKAGE + "::gvc014", PACKAGE + "::gvc015"
    ], [PACKAGE + "::" + VERIFICATION]);
    let checks = [
        typed_spatial_scalar_check(source, "GVC-T-body-dimensions", "gvc003", "bodyDimensions"),
        typed_spatial_scalar_check(source, "GVC-T-body-mount", "gvc002", "bodyMount"),
        typed_spatial_scalar_check(source, "GVC-T-rail-dimensions", "gvc012", "railDimensions"),
        typed_collection_check(source, "GVC-T-octagonal-profile", "gvc014",
            "outerBodyProfileCoordinates", "CartesianVectorValue", 8, "Vec2"),
        typed_collection_check(source, "GVC-T-rail-stations", "gvc012", "railStations", "Position", 8, "Vec3"),
        typed_collection_check(source, "GVC-T-leg-stations", "gvc005", "legStations", "Position", 4, "Vec3"),
        typed_collection_check(source, "GVC-T-tank-stations", "gvc007", "tankStations", "Position", 4, "Vec3"),
        tank_station_layout_check(source),
        typed_relation_check(source),
        typed_symmetry_check(source),
        typed_collection_check(source, "GVC-T-solar-stations", "gvc006", "solarStations", "Position", 2, "Vec3"),
        typed_collection_check(source, "GVC-T-engine-stations", "gvc008", "engineStations", "Position", 7, "Vec3"),
        typed_collection_check(source, "GVC-T-frame-rail-identities", "gvc012", "frameRails", "GriffinFrameRailNode", 8, "EnumValue"),
        typed_collection_check(source, "GVC-T-tank-identities", "gvc007", "tankInstances", "GriffinTankInstanceName", 4, "EnumValue"),
        typed_collection_check(source, "GVC-T-leg-identities", "gvc005", "landingLegInstances", "GriffinLandingLegInstanceName", 4, "EnumValue"),
        typed_collection_check(source, "GVC-T-solar-identities", "gvc006", "solarArrayInstances", "GriffinSolarArrayInstanceName", 2, "EnumValue"),
        typed_collection_check(source, "GVC-T-engine-identities", "gvc008", "mainEngineInstances", "GriffinMainEngineInstanceName", 7, "EnumValue"),
        typed_enum_check(source, "GVC-T-body-profile", "gvc003", "bodyProfile", "OctagonalOpenFrame"),
        typed_enum_check(source, "GVC-T-ramp-state", "gvc009", "rampState", "Stowed"),
        display_color_check(source),
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
