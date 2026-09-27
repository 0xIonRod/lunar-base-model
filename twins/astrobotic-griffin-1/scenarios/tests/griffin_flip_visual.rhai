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

fn _visual_scene_document_id() {
    let documents = query("ListOpenDocuments");
    if documents == () || documents.open_documents == () {
        throw("Griffin visual review cannot enumerate open USD documents");
    }
    for document in documents.open_documents {
        if document.kind == "usd" && document.origin != ()
            && document.origin.path != ()
            && document.origin.path.ends_with("/tests/griffin_flip_visual.usda") {
            return document.doc_id;
        }
    }
    throw("Griffin visual review scene document is not open");
}

fn on_start(me, ctx) {
    this.griffin = find("/GriffinFlipVisual/Griffin1");
    this.flip = find("/GriffinFlipVisual/FLIP");
    this.camera = find("/GriffinFlipVisual/VisualCamera");
    this.ground = find("/GriffinFlipVisual/Ground/RegolithPad");
    this.terrain = find("/GriffinFlipVisual/Environment/Terrain");
    this.done = false;
    this.review_batch = 0;
}

fn on_tick(me, ctx) {
    if this.done || dt() <= 0.0 { return; }
    let progress = run_visual_review(this.review_batch);
    this.review_batch += 1;
    if this.review_batch >= progress.batch_count { this.done = true; }
}

// Keep the review callable through the one-shot production API as well as the
// fixed-tick observer. That lets a visual acceptance run read the composed
// scene even when an unrelated continuous model holds physics time.
fn run_visual_review(batch_index) {
    let source = sysml_requirements::source_with_selection([
        griffin_spec::qualified_attribute_name("landingLegInstances"),
        griffin_spec::qualified_attribute_name("mainEngineInstances"),
        griffin_spec::qualified_attribute_name("rampInstances"),
        griffin_spec::qualified_attribute_name("solarArrayInstances"),
        griffin_spec::qualified_attribute_name("wheelStations"),
        griffin_spec::qualified_attribute_name("wheelRadiusM"),
        griffin_spec::qualified_attribute_name("missionSteeringMode"),
        griffin_spec::qualified_attribute_name("visualReviewGriffinStation"),
        griffin_spec::qualified_attribute_name("visualReviewFlipStation"),
        griffin_spec::qualified_attribute_name("deckDimensions"),
        griffin_spec::qualified_attribute_name("visualLandingPadRadiusM"),
        griffin_spec::qualified_attribute_name("visualReviewGroundWidthM")
    ], [
        "GriffinVisualRequirements::gv001",
        "GriffinVisualRequirements::gv002",
        "GriffinVisualRequirements::gv003",
        "GriffinVisualRequirements::gv004",
        "GriffinVisualRequirements::gv005",
        "GriffinVisualRequirements::gv006",
        "GriffinVisualRequirements::gv007",
        "FlipRequirements::fvg001"
    ], ["GriffinVisualRequirements::Verify_GriffinVisualRequirements"]);
    let root = "/GriffinFlipVisual";
    let checks = [];
    checks.push(visual_exists_check("GV-001-camera", "camera", "gv001", "exists", root + "/VisualCamera"));
    let leg_names = _sysml_list(source, "landingLegInstances");
    for name in leg_names {
        checks.push(visual_exists_check("GV-002-" + name, "legs", "gv002", "exists", root + "/Griffin1/" + name));
        checks.push(visual_children_check("GV-002-" + name + "-subparts", "legs", "gv002",
            root + "/Griffin1/" + name + "/LandingLegVisual",
            [root + "/Griffin1/" + name + "/LandingLegVisual/StrutOuter",
             root + "/Griffin1/" + name + "/LandingLegVisual/StrutInner",
             root + "/Griffin1/" + name + "/LandingLegVisual/ShockPiston",
             root + "/Griffin1/" + name + "/LandingLegVisual/FootPad"]));
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
        let ramp = root + "/Griffin1/" + name;
        checks.push(visual_children_check("GV-002-" + name + "-sections", "egress_ramps",
            "gv002", ramp,
            [ramp + "/DeckSection", ramp + "/MiddleSection", ramp + "/TransitionPlate"]));
        for segment in ["DeckSection", "MiddleSection"] {
            let section = ramp + "/" + segment;
            let paths = [section + "/RampTrackPort", section + "/RampTrackStarboard",
                section + "/OuterRail", section + "/InnerRail"];
            if segment == "MiddleSection" { paths.push(section + "/ToeSection"); }
            checks.push(visual_children_check("GV-002-" + name + "-" + segment,
                "egress_ramps", "gv002", section, paths));
        }
        let toe = ramp + "/MiddleSection/ToeSection";
        checks.push(visual_children_check("GV-002-" + name + "-ToeSection",
            "egress_ramps", "gv002", toe,
            [toe + "/RampTrackPort", toe + "/RampTrackStarboard",
             toe + "/OuterRail", toe + "/InnerRail"]));
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
    checks.push(visual_exists_check("GV-004-deck-width", "lander_deck", "gv004", "bounds_component", root + "/Griffin1/Bus/TopDeckOctagon"));
    checks[checks.len() - 1].index = 0;
    checks[checks.len() - 1].multiplier = 2.0;
    checks[checks.len() - 1].expected_attr = griffin_spec::qualified_attribute_name("deckDimensions");
    checks[checks.len() - 1].expected_index = 0;
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
    let batch_count = (checks.len() + 15) / 16;
    if batch_index < 0 || batch_index >= batch_count {
        throw("Griffin visual review batch index is out of range");
    }
    let first = batch_index * 16;
    let batch = [];
    for index in first..checks.len() {
        if index >= first + 16 { break; }
        batch.push(checks[index]);
    }
    let scene_doc_id = _visual_scene_document_id();
    for index in 0..batch.len() {
        batch[index].doc_id = scene_doc_id;
    }
    let title = "GRIFFIN FLIP VISUAL batch " + (batch_index + 1).to_string()
        + "/" + batch_count.to_string();
    let report = sysml_requirements::evaluate_stream(source, batch,
        "GRIFFIN_FLIP_VISUAL", title);
    print("[griffin-flip-visual] si=metres batch=" + (batch_index + 1).to_string()
          + "/" + batch_count.to_string() + " checks=" + checks.len().to_string()
          + " evaluated=" + report.check_count.to_string());
    report_structured_verdict(report, title, "GRIFFIN_FLIP_VISUAL");
    #{batch_count: batch_count, ok: report.ok}
}
import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
