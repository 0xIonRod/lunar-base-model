// Griffin surface mission evidence and verdict construction.
//
// Receives the mission's live state explicitly. The scenario remains the sole
// owner of that state and calls these functions only at phase/report gates.

const MISSION_ROOT = "/Griffin1SurfaceOps";
const ROVER = MISSION_ROOT + "/FLIP";
const DOCK = MISSION_ROOT + "/FLIPPayloadAdapterJoint";

fn trace_event(state, evt) {
    if state.event_trace == () || state.event_trace.len() >= 64 { return state.event_trace; }
    let source_id = if evt.source == () { () } else { evt.source };
    let source_path = ();
    if source_id != () { source_path = usd_path(source_id); }
    state.event_trace.push(#{
        name: evt.name,
        source: source_id,
        source_path: if source_path == () { "" } else { source_path },
        sim_tick: evt.sim_tick,
    });
    state.event_trace
}

fn fail_phase(state, phase) {
    if state.phase_failure_reported == true { return true; }
    print("[griffin] phase failure: " + phase);
    // Keep a typed, bounded snapshot beside the phase failure. This is a
    // read-only query: a failure must never turn into a hidden pose mutation.
    let gates = griffin_surface_ops::landing_gate_report();
    let landing = #{
        position: gates.position,
        leg_contact_geometry: gates.leg_contact_geometry,
        all_legs_contact: gates.all_legs_contact,
        upright_axis_y: gates.upright_axis_y,
        ground_speed: gates.ground_speed,
        descent_speed: gates.descent_speed,
        angular_speed: gates.angular_speed,
        landing_contact: gates.landing_contact,
        touchdown: gates.touchdown,
        engine_cutoff_contact: gates.engine_cutoff_contact,
        landing_handoff: gates.landing_handoff
    };
    let ramp_runtime = griffin_surface_ops::physical_ramp_runtime_pose_evidence();
    let ramp_joints = griffin_surface_ops::physical_ramp_joint_evidence();
    // Keep full evidence typed in the verdict below. Converting the nested
    // control/geometry snapshots and motion trace into one debug string can
    // exceed Rhai's string limit and prevent the failure verdict itself.
    let source = sysml_requirements::source();
    let failure = #{id: "GR-004-phase-" + phase, component: "mission",
        requirement: "GriffinFunctionalRequirements::gr004",
        verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations",
        kind: "phase", path: global::MISSION_ROOT, actual: phase,
        expected: "completed", ok: false, error: "mission phase or preflight failed"};
    let mass_evidence = state.guidance_assembly_mass_evidence;
    let mass_ok = mass_evidence != () && mass_evidence.ok == true;
    let mass_check = #{id: "GR-039-guidance-assembly-mass", component: "guidance",
        requirement: "GriffinSimulationAccuracyRequirements::gr039",
        verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations",
        kind: "preflight", path: global::MISSION_ROOT + "/Lander/GNC", actual: mass_evidence,
        expected: "guidance input equals the complete current dynamic joint-island mass in kilograms",
        ok: mass_ok, error: "complete solver mass, guidance input, units, or validity evidence is missing or mismatched"};
    let results = [failure, mass_check];
    let failures = [failure];
    if !mass_ok { failures.push(mass_check); }
    report_structured_verdict(#{ok: false, verification:
        "Griffin1Requirements::Verify_GriffinSurfaceOperations",
        requirement_count: results.len(), source_revision: source.source_revision,
        source_files: source.source_files, results: results, failures: failures,
        metrics: #{phase: phase, event_trace: state.event_trace,
            clocks: clock_snapshot(), landing_setup: state.landing_setup_evidence,
            guidance_assembly_mass: mass_evidence,
            landing_gates: landing, landing_diagnostics: gates,
            physical_ramps: ramp_runtime, physical_ramp_joints: ramp_joints,
            ramp_section_settle: state.ramp_section_settle_evidence,
            ramp_sections_expected: state.ramp_sections_expected,
            ramp_unfold_waypoints: state.ramp_unfold_waypoint_evidence,
            ramp_middle_settle: state.ramp_middle_settle_evidence,
            ramp_toe_settle: state.ramp_toe_settle_evidence,
            ramp_root_settle: state.ramp_deployment_settle_evidence,
            ramp_terrain_plan: state.ramp_terrain_plan,
            ramp_motion_trace: state.ramp_motion_trace,
            route_command_updates: state.route_command_updates}},
        "GRIFFIN SURFACE OPS", "GRIFFIN_SURFACE_OPS");
    emit("griffin_phase_timeout");
    true
}

fn ramp_unfold_order_report(state) {
    let required = griffin_surface_ramp_ops::unfold_event_contract().ordered;
    let observed = [];
    let cursor = 0;
    for event_name in required {
        let event_index = ();
        for index in cursor..state.event_trace.len() {
            if state.event_trace[index].name == event_name {
                event_index = index;
                break;
            }
        }
        if event_index == () {
            return #{ok: false, expected: required, observed: observed,
                missing_event: event_name, event_trace: state.event_trace};
        }
        observed.push(#{name: event_name, event_index: event_index});
        cursor = event_index + 1;
    }
    #{ok: true, expected: required, observed: observed}
}

fn finish_surface_ops(state) {
    let ramp_unfold_order = ramp_unfold_order_report(state);
    let ramp_middle_settled = state.ramp_middle_settle_evidence != ()
        && state.ramp_middle_settle_evidence.ok == true
        && state.ramp_middle_settle_evidence.settled == true;
    let ramp_toe_settled = state.ramp_toe_settle_evidence != ()
        && state.ramp_toe_settle_evidence.ok == true
        && state.ramp_toe_settle_evidence.settled == true;
    let ramp_root_settled = state.ramp_deployment_settle_evidence != ()
        && state.ramp_deployment_settle_evidence.ok == true
        && state.ramp_deployment_settle_evidence.settled == true;
    let ramp_deployment_evidence = #{order: ramp_unfold_order,
        middle_settle: state.ramp_middle_settle_evidence,
        toe_settle: state.ramp_toe_settle_evidence,
        root_settle: state.ramp_deployment_settle_evidence};
    let source = sysml_requirements::source();
    let egress_terrain = if state.egress_terrain_evidence == () {
        griffin_surface_ops::egress_terrain_runtime_evidence(find_path(global::ROVER))
    } else {
        state.egress_terrain_evidence
    };
    let egress_terrain_ok = egress_terrain != () && egress_terrain.ok == true;
    let checks = [
        #{id: "GR-004-lander-settled", component: "landing", requirement: "GriffinFunctionalRequirements::gr004", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: global::MISSION_ROOT + "/Lander", actual: state.lander_settled, expected: true, ok: state.lander_settled, error: "lander did not settle"},
        #{id: "GR-003-ramps-deployed", component: "egress_ramps", requirement: "GriffinFunctionalRequirements::gr003", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: global::MISSION_ROOT + "/Lander/EgressRampPort", actual: state.ramps_deployed, expected: true, ok: state.ramps_deployed, error: "ramps were not deployed"},
        #{id: "GR-026-adapter-release", component: "payload_adapter", requirement: "GriffinFunctionalRequirements::gr026", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: global::DOCK, actual: state.rover_detached, expected: true, ok: state.rover_detached, error: "FLIP adapter was not released"},
        #{id: "GR-004-route-engaged", component: "rover", requirement: "GriffinFunctionalRequirements::gr004", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: global::ROVER, actual: state.route_engaged, expected: true, ok: state.route_engaged, error: "FLIP route was not engaged"},
        #{id: "GR-007-ramp-approach", component: "rover", requirement: "GriffinFunctionalRequirements::gr007", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: global::MISSION_ROOT + "/RoverRampApproach", actual: state.ramp_approach_reached, expected: true, ok: state.ramp_approach_reached, error: "ramp approach was not reached"},
        #{id: "GR-007-ramp-exit", component: "rover", requirement: "GriffinFunctionalRequirements::gr007", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: global::MISSION_ROOT + "/RoverRampExit", actual: state.ramp_exit_reached, expected: true, ok: state.ramp_exit_reached, error: "ramp exit was not reached"},
        #{id: "GR-004-waypoint-1", component: "rover", requirement: "GriffinFunctionalRequirements::gr004", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: global::MISSION_ROOT + "/RoverTarget1", actual: state.waypoint_1_reached, expected: true, ok: state.waypoint_1_reached, error: "first survey waypoint was not reached"},
        #{id: "GR-004-waypoint-2", component: "rover", requirement: "GriffinFunctionalRequirements::gr004", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: global::MISSION_ROOT + "/RoverTarget2", actual: state.waypoint_2_reached, expected: true, ok: state.waypoint_2_reached, error: "second survey waypoint was not reached"},
        #{id: "GR-004-base-site", component: "rover", requirement: "GriffinFunctionalRequirements::gr004", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: global::MISSION_ROOT + "/BaseSite", actual: state.base_site_reached, expected: true, ok: state.base_site_reached, error: "base site was not reached"},
        #{id: "GR-004-mission-ready", component: "mission", requirement: "GriffinFunctionalRequirements::gr004", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: global::MISSION_ROOT, actual: state.mission_ready, expected: true, ok: state.mission_ready, error: "mission readiness gate failed"},
        #{id: "GR-039-guidance-assembly-mass", component: "guidance", requirement: "GriffinSimulationAccuracyRequirements::gr039", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "preflight", path: global::MISSION_ROOT + "/Lander/GNC", actual: state.guidance_assembly_mass_evidence, expected: "guidance input equals the complete current dynamic joint-island mass in kilograms", ok: state.guidance_assembly_mass_evidence != () && state.guidance_assembly_mass_evidence.ok == true, error: "complete solver mass, guidance input, units, or validity evidence is missing or mismatched"},
        #{id: "GR-034-route-frame", component: "rover", requirement: "GriffinFunctionalRequirements::gr034", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "preflight", path: global::MISSION_ROOT, actual: state.route_preflight, expected: true, ok: state.route_preflight != () && state.route_preflight.ok == true, error: "route markers do not agree with the active rover frame"},
        #{id: "GR-037-landing-target-datum", component: "landing", requirement: "GriffinSimulationAccuracyRequirements::gr037", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "preflight", path: global::MISSION_ROOT + "/LandingTarget", actual: if state.landing_setup_evidence == () { () } else { state.landing_setup_evidence.landing_target }, expected: "SysML body-reference touchdown Y", ok: state.landing_setup_evidence != () && state.landing_setup_evidence.landing_target != () && state.landing_setup_evidence.landing_target.ok == true, error: "landing target Y does not satisfy GR-037"},
        #{id: "GR-038-landing-surface-datum", component: "landing", requirement: "GriffinSimulationAccuracyRequirements::gr038", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "preflight", path: global::MISSION_ROOT + "/Environment/Terrain", actual: if state.landing_setup_evidence == () { () } else { state.landing_setup_evidence.landing_surface }, expected: "finite source-backed DEM height and target above the measured terrain datum", ok: state.landing_setup_evidence != () && state.landing_setup_evidence.landing_surface != () && state.landing_setup_evidence.landing_surface.ok == true, error: "landing DEM datum does not satisfy GR-038"},
        #{id: "GR-035-egress-terrain-contact", component: "egress_terrain", requirement: "GriffinFunctionalRequirements::gr035", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "contact", path: global::MISSION_ROOT + "/Environment/Terrain", actual: egress_terrain, expected: "four native FLIP wheel contacts on the DEM at ramp exit", ok: egress_terrain_ok, error: "GR-035 native DEM wheel contact evidence is missing"},
        #{id: "GRR-017-ramp-unfold-order", component: "egress_ramps", requirement: "GriffinRampRequirements::grr017", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: global::MISSION_ROOT + "/Lander/EgressRampPort", actual: ramp_deployment_evidence, expected: ramp_unfold_order.expected, ok: ramp_unfold_order.ok && ramp_middle_settled && ramp_toe_settled && ramp_root_settled, error: "ramp middle hinges, toe hinges, and deck hinges did not command and settle in the required order"}
    ];
    let failures = [];
    for check in checks { if check.ok != true { failures.push(check); } }
    report_structured_verdict(#{ok: failures.len() == 0,
        verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations",
        requirement_count: checks.len(), source_revision: source.source_revision,
        source_files: source.source_files, results: checks, failures: failures,
        metrics: #{event_trace: state.event_trace, clocks: clock_snapshot(),
            route_preflight: state.route_preflight,
            landing_setup: state.landing_setup_evidence,
            guidance_assembly_mass: state.guidance_assembly_mass_evidence,
            ramp_deployment: ramp_deployment_evidence,
            egress_terrain: egress_terrain,
            final_state: state}},
        "GRIFFIN SURFACE OPS", "GRIFFIN_SURFACE_OPS");
}
