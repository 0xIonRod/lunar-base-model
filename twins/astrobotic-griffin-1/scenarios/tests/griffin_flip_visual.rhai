import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;

// Twin-owned visual contract.  It checks the authored presentation topology
// and key SI dimensions; it never hard-codes engine internals or mutates USD.
const TEST_KIND = "graphics";

fn visual_exists_check(id, component, requirement, kind, path) {
    #{ id: id, component: component, requirement: requirement,
       verification: "Verify_GriffinVisualRequirements",
       kind: kind, path: path, visible: true }
}

fn visual_children_check(id, component, requirement, path, paths) {
    #{ id: id, component: component, requirement: requirement,
       verification: "Verify_GriffinVisualRequirements",
       kind: "children", path: path, paths: paths, visible: true }
}

fn flip_visual_exists_check(id, component, kind, path) {
    let check = visual_exists_check(id, component,
        "fvg001", kind, path);
    check.verification = "Verify_GriffinVisualRequirements";
    check
}

fn flip_visual_children_check(id, component, path, paths) {
    let check = visual_children_check(id, component,
        "fvg001", path, paths);
    check.verification = "Verify_GriffinVisualRequirements";
    check
}

// Lists of authored component identities come from the same SysML snapshot
// passed to the generic evaluator. The test owns only child geometry names;
// it does not carry a second list of rover/lander station identities.
fn _sysml_list(report, name) {
    let qualified = griffin_spec::qualified_attribute_name(name);
    let items = sysml_requirement_checks::source_enum_identifiers(report, qualified);
    if items == () { return []; }
    items
}

fn on_start(me, ctx) {
    this.griffin = find("/GriffinFlipVisual/Griffin1");
    this.flip = find("/GriffinFlipVisual/FLIP");
    this.camera = find("/GriffinFlipVisual/VisualCamera");
    this.ground = find("/GriffinFlipVisual/Ground/RegolithPad");
    this.terrain = find("/GriffinFlipVisual/Environment/Terrain");
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || dt() <= 0.0 { return; }
    this.done = true;
    let source = sysml_requirements::source();
    let root = "/GriffinFlipVisual";
    let checks = [];
    checks.push(visual_exists_check("GV-001-camera", "camera", "gv001", "exists", root + "/VisualCamera"));
    let leg_names = _sysml_list(source, "landingLegInstances");
    for name in leg_names {
        checks.push(visual_exists_check("GV-002-" + name, "legs", "gv002", "exists", root + "/Griffin1/" + name));
        checks.push(visual_children_check("GV-002-" + name + "-subparts", "legs", "gv002",
            root + "/Griffin1/" + name,
            [root + "/Griffin1/" + name + "/StrutOuter",
             root + "/Griffin1/" + name + "/StrutInner",
             root + "/Griffin1/" + name + "/ShockPiston",
             root + "/Griffin1/" + name + "/FootPad"]));
    }
    checks.push(visual_exists_check("GV-002-deck", "lander", "gv002", "exists", root + "/Griffin1/Bus"));
    checks.push(visual_children_check("GV-002-deck-subparts", "lander", "gv002",
        root + "/Griffin1/Bus",
        [root + "/Griffin1/Bus/PerimeterFrame",
         root + "/Griffin1/Bus/TopDeckOctagon",
         root + "/Griffin1/Bus/LowerServiceSkirtOctagon",
         root + "/Griffin1/Bus/TankSupportPlate",
         root + "/Griffin1/Bus/RoverPayloadDeck"]));
    let payload_deck = visual_exists_check("GV-004-rover-payload-deck", "lander_deck",
        "gv004", "exists", root + "/Griffin1/Bus/RoverPayloadDeck");
    payload_deck.expected_type = "Mesh";
    checks.push(payload_deck);
    let body_profile = visual_exists_check("GV-002-octagonal-body", "lander", "gv002",
        "exists", root + "/Griffin1/Bus/PerimeterFrame");
    body_profile.expected_type = "Mesh";
    checks.push(body_profile);
    checks.push(visual_exists_check("GV-002-nozzle", "engines", "gv002", "exists", root + "/Griffin1/Nozzle"));
    let engine_names = _sysml_list(source, "mainEngineInstances");
    let engine_paths = [];
    for name in engine_names {
        engine_paths.push(root + "/Griffin1/Nozzle/MainEngineCluster/" + name);
    }
    checks.push(visual_children_check("GV-002-engine-bells", "engines", "gv002",
        root + "/Griffin1/Nozzle/MainEngineCluster", engine_paths));
    for name in engine_names {
        checks.push(visual_children_check("GV-002-" + name + "-subparts", "engines",
            "gv002", root + "/Griffin1/Nozzle/MainEngineCluster/" + name,
            [root + "/Griffin1/Nozzle/MainEngineCluster/" + name + "/Bell",
             root + "/Griffin1/Nozzle/MainEngineCluster/" + name + "/Throat"]));
    }
    let tank_names = griffin_spec::propellant_tank_names();
    let tank_paths = [];
    for name in tank_names { tank_paths.push(root + "/Griffin1/" + name); }
    checks.push(visual_children_check("GV-002-tanks", "propellant_tanks", "gv002",
        root + "/Griffin1", tank_paths));
    for name in tank_names {
        checks.push(visual_children_check("GV-002-" + name + "-bands", "propellant_tanks",
            "gv002", root + "/Griffin1/" + name,
            [root + "/Griffin1/" + name + "/MliTank",
             root + "/Griffin1/" + name + "/TankBandA",
             root + "/Griffin1/" + name + "/TankBandB",
             root + "/Griffin1/" + name + "/TankBandC"]));
    }
    let ramp_names = _sysml_list(source, "rampInstances");
    let ramp_paths = [];
    for name in ramp_names { ramp_paths.push(root + "/Griffin1/" + name); }
    checks.push(visual_children_check("GV-002-ramps", "egress_ramps", "gv002",
        root + "/Griffin1", ramp_paths));
    for name in ramp_names {
        checks.push(visual_children_check("GV-002-" + name + "-subparts", "egress_ramps",
            "gv002", root + "/Griffin1/" + name,
            [root + "/Griffin1/" + name + "/RampTrackPort",
             root + "/Griffin1/" + name + "/RampTrackStarboard",
             root + "/Griffin1/" + name + "/OuterRail",
             root + "/Griffin1/" + name + "/InnerRail",
             root + "/Griffin1/" + name + "/SupportArm"]));
    }
    let solar_names = _sysml_list(source, "solarArrayInstances");
    let solar_member_names = sysml_requirement_checks::source_enum_identifiers(source,
        "GriffinSolarRequirements::GriffinSolarArrayAssembly::childNames");
    for name in solar_names {
        checks.push(visual_exists_check("GV-003-solar-" + name, "solar_panels", "gv003", "exists", root + "/Griffin1/" + name));
        let solar_children = [];
        for member in solar_member_names {
            solar_children.push(root + "/Griffin1/" + name + "/" + member);
        }
        checks.push(visual_children_check("GV-003-solar-" + name + "-layers", "solar_panels", "gv003",
            root + "/Griffin1/" + name,
            solar_children));
    }
    checks.push(flip_visual_exists_check("GV-003-mast", "rover", "exists", root + "/FLIP/SensorMast"));
    checks.push(flip_visual_children_check("GV-003-mast-subparts", "rover",
        root + "/FLIP/SensorMast", [root + "/FLIP/SensorMast/MastPost",
        root + "/FLIP/SensorMast/SensorHead", root + "/FLIP/SensorMast/SensorAntenna"]));
    checks.push(flip_visual_children_check("GV-003-rover-body", "rover",
        root + "/FLIP/Chassis", [root + "/FLIP/Chassis/LowerFrame",
        root + "/FLIP/Chassis/WhiteEquipmentBox", root + "/FLIP/Chassis/FrontBumper",
        root + "/FLIP/Chassis/PayloadDeck", root + "/FLIP/Chassis/ServicePanel"]));
    checks.push(flip_visual_children_check("GV-003-rover-solar", "rover",
        root + "/FLIP/SolarArray/SolarArrayVisual", [root + "/FLIP/SolarArray/SolarArrayVisual/WhiteBacksheet",
        root + "/FLIP/SolarArray/SolarArrayVisual/BlueCells",
        root + "/FLIP/SolarArray/SolarArrayVisual/FoldHinge"]));
    let wheel_names = _sysml_list(source, "wheelStations");
    for name in wheel_names {
        checks.push(flip_visual_exists_check("GV-003-wheel-" + name, "wheels", "exists", root + "/FLIP/Suspension_" + name + "/Wheel_" + name));
        checks.push(flip_visual_children_check("GV-003-wheel-" + name + "-subparts", "wheels",
            root + "/FLIP/Suspension_" + name + "/Wheel_" + name + "/Visual",
            [root + "/FLIP/Suspension_" + name + "/Wheel_" + name + "/Visual/Tire",
             root + "/FLIP/Suspension_" + name + "/Wheel_" + name + "/Visual/MetalHub",
             root + "/FLIP/Suspension_" + name + "/Wheel_" + name + "/Visual/HubCap"]));
    }
    for name in wheel_names {
        let check = #{ id: "GV-004-wheel-radius-" + name, component: "wheels",
            requirement: "fvg001",
            verification: "Verify_GriffinVisualRequirements",
            kind: "attribute", path: root + "/FLIP/Suspension_" + name + "/Wheel_" + name + "/Visual/Tire",
            attr: "radius", expected_attr: griffin_spec::qualified_attribute_name("wheelRadiusM"), tolerance: 0.001 };
        checks.push(check);
    }
    let steering_mode = #{ id: "FGV-001-steering-mode", component: "rover",
        requirement: "fvg001",
        verification: "Verify_GriffinVisualRequirements",
        kind: "attribute_equals", path: root + "/FLIP", attr: "lunco:steeringGeometry",
        expected_attr: griffin_spec::qualified_attribute_name("missionSteeringMode") };
    checks.push(steering_mode);
    // The assembly-authored socket/frame relationships are the durable
    // placement contract behind the numeric transforms.
    let port_socket = root + "/Griffin1/Bus/RampSocketPort";
    let starboard_socket = root + "/Griffin1/Bus/RampSocketStarboard";
    checks.push(#{ id: "GV-007-ramp-sockets", component: "egress_ramps",
        requirement: "gv007",
        verification: "Verify_GriffinVisualRequirements",
        kind: "relationship", path: root + "/Griffin1/Bus",
        rel: "lunco:mount:sockets", targets: [port_socket, starboard_socket] });
    checks.push(#{ id: "GV-007-port-frame", component: "egress_ramps",
        requirement: "gv007",
        verification: "Verify_GriffinVisualRequirements",
        kind: "relationship", path: root + "/Griffin1/EgressRampPort",
        rel: "lunco:mount:frame",
        targets: [root + "/Griffin1/EgressRampPort/MountFrame"] });
    checks.push(#{ id: "GV-007-starboard-frame", component: "egress_ramps",
        requirement: "gv007",
        verification: "Verify_GriffinVisualRequirements",
        kind: "relationship", path: root + "/Griffin1/EgressRampStarboard",
        rel: "lunco:mount:frame",
        targets: [root + "/Griffin1/EgressRampStarboard/MountFrame"] });
    checks.push(#{ id: "GV-007-port-occupancy", component: "egress_ramps",
        requirement: "gv007",
        verification: "Verify_GriffinVisualRequirements",
        kind: "relationship", path: port_socket, rel: "lunco:mount:part",
        targets: [root + "/Griffin1/EgressRampPort"] });
    checks.push(#{ id: "GV-007-starboard-occupancy", component: "egress_ramps",
        requirement: "gv007",
        verification: "Verify_GriffinVisualRequirements",
        kind: "relationship", path: starboard_socket, rel: "lunco:mount:part",
        targets: [root + "/Griffin1/EgressRampStarboard"] });
    checks.push(visual_exists_check("GV-004-deck-width", "lander_deck", "gv004", "bounds_component", root + "/Griffin1/Bus/PerimeterFrame"));
    checks[checks.len() - 1].index = 0;
    checks[checks.len() - 1].multiplier = 2.0;
    checks[checks.len() - 1].expected_attr = griffin_spec::qualified_attribute_name("visualLanderDeckWidthM");
    checks[checks.len() - 1].tolerance = 0.001;
    for placement in [
        #{name: "Griffin1", expected: vec3_array(griffin_spec::visual_review_griffin_station())},
        #{name: "FLIP", expected: vec3_array(griffin_spec::visual_review_flip_station())}
    ] {
        for axis in 0..3 {
            checks.push(#{id: "GV-004-" + placement.name + "-station-" + axis.to_string(),
                component: placement.name, requirement: "gv004",
                verification: "Verify_GriffinVisualRequirements",
                kind: "attribute_component", path: root + "/" + placement.name,
                attr: "xformOp:translate", index: axis,
                expected: placement.expected[axis], tolerance: 0.002});
        }
    }
    let pad = #{ id: "GV-004-pad-radius", component: "context",
        requirement: "gv004",
        verification: "Verify_GriffinVisualRequirements",
        kind: "bounds_component", path: root + "/Ground/LandingPad", index: 0,
        multiplier: 1.0, expected_attr: griffin_spec::qualified_attribute_name("visualLandingPadRadiusM"), tolerance: 0.001 };
    checks.push(pad);
    let ground = #{ id: "GV-004-ground-width", component: "context",
        requirement: "gv004",
        verification: "Verify_GriffinVisualRequirements",
        kind: "bounds_component", path: root + "/Ground/RegolithPad",
        index: 0, multiplier: 2.0, expected_attr: griffin_spec::qualified_attribute_name("visualReviewGroundWidthM"), tolerance: 0.001 };
    checks.push(ground);
    let render = #{ id: "GV-005-ground-render", component: "context",
        requirement: "gv005",
        verification: "Verify_GriffinVisualRequirements",
        kind: "attribute_equals", path: root + "/Ground/RegolithPad", attr: "purpose", expected: "render" };
    checks.push(render);
    let collision = #{ id: "GV-005-ground-noncollision", component: "context",
        requirement: "gv005",
        verification: "Verify_GriffinVisualRequirements",
        kind: "attribute_equals", path: root + "/Ground/RegolithPad", attr: "physics:collisionEnabled", expected: false };
    checks.push(collision);
    checks.push(#{ id: "GV-005-ground-hidden", component: "context",
        requirement: "gv005",
        verification: "Verify_GriffinVisualRequirements",
        kind: "attribute_equals", path: root + "/Ground/RegolithPad", attr: "visibility", expected: "invisible" });
    checks.push(#{ id: "GV-005-landing-pad-hidden", component: "context",
        requirement: "gv005",
        verification: "Verify_GriffinVisualRequirements",
        kind: "attribute_equals", path: root + "/Ground/LandingPad", attr: "visibility", expected: "invisible" });
    checks.push(#{ id: "GV-005-pad-ring-hidden", component: "context",
        requirement: "gv005",
        verification: "Verify_GriffinVisualRequirements",
        kind: "attribute_equals", path: root + "/Ground/PadRing", attr: "visibility", expected: "invisible" });
    let terrain = visual_exists_check("GV-006-terrain", "context", "gv006", "exists", root + "/Environment/Terrain");
    terrain.expected_type = "Xform";
    checks.push(terrain);
    checks.push(#{ id: "GV-006-terrain-shader", component: "context",
        requirement: "gv006",
        verification: "Verify_GriffinVisualRequirements",
        kind: "attribute_equals",
        path: root + "/Environment/Looks/RegolithSurface/Shader",
        attr: "info:wgsl:sourceAsset",
        expected: griffin_spec::visual_terrain_shader_asset() });
    checks.push(#{ id: "GV-006-terrain-mode", component: "context",
        requirement: "gv006",
        verification: "Verify_GriffinVisualRequirements",
        kind: "attribute_equals", path: root,
        attr: "lunco:visual:terrain_mode", expected: "standard_layered" });
    checks.push(visual_exists_check("GV-006-light", "context", "gv006", "exists", root + "/Sun"));
    let report = sysml_requirements::evaluate(source, checks);
    print("[griffin-flip-visual] griffin=" + this.griffin +
          " flip=" + this.flip + " camera=" + this.camera +
          " ground=" + this.ground + " si=metres checks=" + checks.len()
          + " evaluated=" + report.results.len());
    report_structured_verdict(report, "GRIFFIN FLIP VISUAL", "GRIFFIN_FLIP_VISUAL");
}
import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
