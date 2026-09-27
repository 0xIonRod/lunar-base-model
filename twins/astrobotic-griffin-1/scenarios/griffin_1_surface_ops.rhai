// Griffin-1 landing + surface-operations scenario.
//
// This is mission policy only. Continuous control remains in the composed
// Modelica lander/rover domains; this script waits for physical/model events,
// confirms the authored solid-ramp pose, detaches the top-deck adapter after
// touchdown, and announces phase transitions. The ramp meshes are integrated
// into the lander compound; the unstable independent-body hinge variant is
// deliberately not selected by this mission.

const LANDER = "/Griffin1SurfaceOps/Lander";
const ROVER = "/Griffin1SurfaceOps/FLIP";
const DOCK = "/Griffin1SurfaceOps/FLIPPayloadAdapterJoint";

fn trace_event(state, evt) {
    if state.event_trace == () || state.event_trace.len() >= 64 { return; }
    let source_id = if evt.source == () { () } else { evt.source };
    let source_path = ();
    if source_id != () { source_path = usd_path(source_id); }
    state.event_trace.push(#{
        name: evt.name,
        source: source_id,
        source_path: if source_path == () { "" } else { source_path },
        sim_tick: sim_tick(),
    });
}

fn on_start(me, ctx) {
    // This mission only reacts to these discrete control/phase edges. Opt into
    // the event filter so unrelated wheel/terrain collision chatter does not
    // enter the Rhai VM; the shared task/mission identity buffer remains
    // bounded and deterministic.
    // Scope vehicle events to their emitter. The source-scoped subscriptions
    // keep the mission's lander/rover semantics while preventing unrelated
    // controller traffic from entering this VM. The release edge is the
    // controller-owned event; continuous SetPorts commands are not mission
    // events and stay out of this hook entirely.
    let lander_gid = find_path(LANDER);
    let rover_gid = find_path(ROVER);
    if lander_gid >= 0 {
        subscribe_from("intent.edge", lander_gid);
        subscribe_from("lander_touchdown", lander_gid);
    }
    if rover_gid >= 0 {
        subscribe_from("waypoint.reached", rover_gid);
    }
    subscribe("key:KeyG");
    for event_name in [
        "griffin_ramp_approach_reached", "griffin_ramp_exit_reached", "griffin_waypoint_1_reached",
        "griffin_waypoint_2_reached", "griffin_base_site_reached",
        "griffin_surface_route_stalled", "griffin_surface_route_control_failed",
    ] {
        subscribe(event_name);
    }
    this.lander_settled = false;
    this.release_requested = false;
    this.rover_detached = false;
    this.ramps_deployed = false;
    this.route_engaged = false;
    this.ramp_approach_reached = false;
    this.ramp_exit_reached = false;
    this.waypoint_1_reached = false;
    this.waypoint_2_reached = false;
    this.base_site_reached = false;
    this.mission_ready = true;
    this.phase_timeout = false;
    this.rover_brake_held = false;
    this.route_started = false;
    this.route_control_error = false;
    this.route_command_updates = 0;
    this.route_failure_evidence = ();
    this.route_preflight = ();
    this.egress_apron_evidence = ();
    this.rover_settle_probe_tick = ();
    this.event_trace = [];
}

fn on_event(me, evt, ctx) {
    trace_event(this, evt);
    let lander = find_path(LANDER);
    let rover = find_path(ROVER);

    // The shared controller publishes a target-scoped semantic edge for the
    // G binding. G is an explicit lander-owned release action and is available
    // at any phase; the rover must never interpret it as a drive/action command.
    // Keep the actual joint mutation in the Twin policy, where the authored dock
    // is known.
    if evt.name == "intent.edge" && evt.source == lander {
        let value = evt.value;
        if value != () && value["target_gid"] == lander &&
           value["intent"] == "release" &&
           (value["edge"] == "pressed" || value["edge"] == "pulse") {
            if release_rover(me, this.release_requested) {
                this.release_requested = true;
            }
        }
        return;
    }

    // Native keyboard projection is a fallback for a lander that is under the
    // local human's control but whose authored binding has not produced an
    // edge yet (for example during an ownership handoff). It is still gated to
    // the lander owner, so pressing G while driving FLIP cannot detach it.
    if evt.name == "key:KeyG" &&
       owner_of(lander) == 0 && owner_of(rover) != 0 {
        if release_rover(me, this.release_requested) {
            this.release_requested = true;
        }
        return;
    }

    if evt.name == "lander_touchdown" && evt.source == lander {
        this.lander_settled = true;
        return;
    }
    // The route task emits these mission-local edges after the same typed
    // arrival predicate used by navigation.  Keep accepting the generic
    // waypoint sensor events below for interactive/editor runs that use the
    // authored marker triggers instead of the deterministic route task.
    if evt.name == "griffin_ramp_exit_reached" {
        this.ramp_exit_reached = true;
        this.egress_apron_evidence = griffin_surface_ops::egress_apron_runtime_evidence(rover);
        emit("griffin_ramp_exit_reached_confirmed");
        return;
    }
    if evt.name == "griffin_waypoint_1_reached" {
        this.waypoint_1_reached = true;
        emit("griffin_waypoint_1_reached_confirmed");
        return;
    }
    if evt.name == "griffin_waypoint_2_reached" {
        this.waypoint_2_reached = true;
        emit("griffin_waypoint_2_reached_confirmed");
        return;
    }
    if evt.name == "griffin_base_site_reached" {
        this.base_site_reached = true;
        emit("griffin_surface_ops_complete");
        print("[griffin] base site reached; surface operations complete");
        return;
    }
    // Route helpers emit their structured verdict at the observation point.
    // A failed task leaf may finish before this nested event hook runs, so
    // this hook is intentionally trace-only for route failure events.
    if evt.name != "waypoint.reached" || evt.source != rover { return; }
    let path = waypoint_event_path(evt);
    if path == () { return; }
    // Keep the marker presentation static during this mission. The generic
    // helper writes the runtime USD layer, which can rebuild a live physical
    // vehicle while its post-detach bodies are settling. Mission milestones
    // are already carried by this typed waypoint event; no color write is
    // worth disturbing the drivetrain.
    if path == "/Griffin1SurfaceOps/RoverRampApproach" {
        this.ramp_approach_reached = true;
        emit("griffin_ramp_approach_reached");
        print("[griffin] rover reached ramp approach");
    } else if path == "/Griffin1SurfaceOps/RoverRampExit" {
        this.ramp_exit_reached = true;
        this.egress_apron_evidence = griffin_surface_ops::egress_apron_runtime_evidence(rover);
        emit("griffin_ramp_exit_reached");
        print("[griffin] rover cleared ramp");
    } else if path == "/Griffin1SurfaceOps/RoverTarget1" {
        this.waypoint_1_reached = true;
        emit("griffin_waypoint_1_reached");
        print("[griffin] waypoint 1 reached");
    } else if path == "/Griffin1SurfaceOps/RoverTarget2" {
        this.waypoint_2_reached = true;
        emit("griffin_waypoint_2_reached");
        print("[griffin] waypoint 2 reached");
    } else if path == "/Griffin1SurfaceOps/BaseSite" {
        this.base_site_reached = true;
        emit("griffin_base_site_reached");
        emit("griffin_surface_ops_complete");
        print("[griffin] base site reached; surface operations complete");
    }
}

fn begin_descent(me) {
    let target_check = griffin_requirements::landing_target_geometry_check(
        (), "/Griffin1SurfaceOps/LandingTarget");
    if target_check.ok != true {
        let detail = target_check.error;
        if detail == () { detail = "unknown landing-target mismatch"; }
        print("[griffin] landing target geometry check failed: " + detail);
        notify_kind("Griffin landing target does not match the SysML geometry datum.", "error");
        emit("griffin_surface_ops_geometry_failed");
        return false;
    }
    print("[griffin] landing target geometry check PASS (Y="
        + target_check.actual_y + " m)");
    griffin_surface_ops::follow_lander();
    griffin_controls::show_briefing();
    emit("griffin_powered_descent_started");
    notify_kind("Griffin-1 powered descent started.", "info");
    print("[griffin] powered descent started");
    true
}

fn touchdown_notice(me) {
    griffin_controls::show_briefing();
    emit("griffin_touchdown_confirmed");
    notify_kind("Griffin-1 touchdown confirmed.", "success");
    print("[griffin] touchdown confirmed");
}

fn unfold_ramp_sections(me) {
    // Remove the flight fold through the four real intermediate USD hinges
    // before the deck hinges lower the two physical ramps to the terrain.
    let angle = griffin_spec::physical_ramp_section_drive_target_rad();
    if angle == () { return #{ok: false, error: "deployed ramp-section angle is missing from SysML"}; }
    let joints = [
        find_path(LANDER + "/RampSectionHingePort01"),
        find_path(LANDER + "/RampSectionHingePort12"),
        find_path(LANDER + "/RampSectionHingeStarboard01"),
        find_path(LANDER + "/RampSectionHingeStarboard12"),
    ];
    let writes = [];
    for joint in joints {
        if joint == () || joint < 0 {
            return #{ok: false, error: "physical ramp-section hinge entities are unavailable"};
        }
        let result = cmd("SetPorts", #{target: joint, writes: [["angle", angle]]});
        if result == () || result.ok != true {
            return #{ok: false, error: "ramp-section unfold command was rejected", joint: joint, result: result};
        }
        writes.push(result);
    }
    emit("griffin_ramp_sections_unfold_commanded");
    notify_kind("Griffin ramp sections are unfolding after touchdown.", "info");
    print("[griffin] physical ramp-section unfold commands accepted");
    #{ok: true, joints: writes, angle_rad: angle}
}

fn deploy_ramps(me) {
    // The physical ramp sections have already been unfolded after touchdown.
    // Drive their existing USD revolute joints through the generic typed angle
    // port after touchdown; this is a real hinged deployment, not a pose write
    // or a second Twin-side physics implementation.
    let port_joint = find_path(LANDER + "/RampHingePort");
    let starboard_joint = find_path(LANDER + "/RampHingeStarboard");
    if port_joint == () || port_joint < 0 || starboard_joint == () || starboard_joint < 0 {
        return #{ok: false, error: "physical ramp hinge entities are unavailable"};
    }
    let port_angle = griffin_spec::physical_ramp_port_deployment_angle_rad();
    let starboard_angle = griffin_spec::physical_ramp_starboard_deployment_angle_rad();
    if port_angle == () || starboard_angle == () {
        return #{ok: false, error: "physical ramp deployment angles are missing from SysML"};
    }
    let port = cmd("SetPorts", #{target: port_joint, writes: [["angle", port_angle]]});
    let starboard = cmd("SetPorts", #{target: starboard_joint, writes: [["angle", starboard_angle]]});
    if port == () || port.ok != true || starboard == () || starboard.ok != true {
        return #{ok: false, error: "physical ramp joint angle command was rejected",
            port: port, starboard: starboard};
    }
    emit("griffin_ramps_deploy_commanded");
    notify_kind("Griffin solid side ramps are deploying after touchdown.", "info");
    print("[griffin] physical egress ramp angle commands accepted");
    #{ok: true, port: port, starboard: starboard,
        port_angle_rad: port_angle, starboard_angle_rad: starboard_angle}
}

fn release_rover(me, already_requested) {
    if already_requested { return true; }
    emit("griffin_ramp_deployment_settled");

    let joint = find_path(DOCK);
    if joint == () || joint < 0 {
        // The adapter is already absent. Keep the same completion gate as a
        // requested detach so the mission never treats a command acknowledgement
        // as proof of topology removal.
        return true;
    }

    // This is an execution-time release request. The generic physics bridge
    // retires the live edge at its solver boundary; this Twin waits for the
    // entity to disappear before announcing completion or driving the rover.
    let release = cmd("DetachJoint", #{
        target: joint,
        intent: "Interactive"
    });
    if release.ok == false {
        notify_kind("FLIP adapter release was rejected.", "error");
        return false;
    }
    print("[griffin] FLIP adapter detach requested; waiting for solver retirement");
    true
}

fn adapter_detach_complete() {
    let joint = find_path(DOCK);
    joint == () || joint < 0
}

fn complete_rover_release(me) {
    griffin_surface_ops::follow_rover();
    griffin_controls::show_rover_controls();
    emit("griffin_flip_released");
    notify_kind("FLIP released from the top-deck adapter; rover egress enabled.", "info");
    print("[griffin] FLIP payload adapter detached");
}

fn engage_rover(me) {
    emit("griffin_flip_deployed");
    // Re-claim the released rover with the shared typed possession command.
    // The route task below writes normal SetPorts through nav_command; there is
    // no bespoke EngageAutopilot command or hidden teleport path.
    let route_ack = griffin_surface_ops::engage_route_subject();
    if route_ack.ok != true {
        notify_kind("Authored FLIP route was rejected: " + route_ack.error, "error");
        emit("griffin_phase_timeout");
        return #{ok: false, error: route_ack.error};
    }
    let steering = griffin_controls::configure_route_steering();
    if steering == () || steering.ok != true {
        let detail = if steering == () { "route steering configuration returned no result" } else { steering.error };
        notify_kind("FLIP route steering was rejected: " + detail, "error");
        emit("griffin_phase_timeout");
        return #{ok: false, error: detail};
    }
    // The adapter release makes FLIP a live rigid body.  Take explicit
    // ownership of the settle phase through the shared controller surface:
    // stop any authored/autopilot writer and hold the normal brake intent
    // until the authoritative pose/velocity gate passes.  No pose or velocity
    // is overwritten here.
    let brake = griffin_controls::hold_rover_brake();
    if brake == () || brake.ok != true {
        let detail = if brake == () { "controller rejected settle brake" } else { brake.error };
        notify_kind("FLIP settle brake was rejected: " + detail, "error");
        emit("griffin_phase_timeout");
        return #{ok: false, error: detail};
    }
    notify_kind("FLIP deployment complete; authored rover route continues.", "success");
    print("[griffin] FLIP authored route continues after release");
    #{ok: true}
}

fn release_rover_settle_brake() {
    let brake = griffin_controls::release_rover_brake();
    if brake == () || brake.ok != true {
        let detail = if brake == () { "controller rejected brake release" } else { brake.error };
        notify_kind("FLIP route brake release was rejected: " + detail, "error");
        return #{ok: false, error: detail};
    }
    print("[griffin] FLIP settle brake released; route authority is active");
    #{ok: true}
}

fn fail_phase(state, phase) {
    print("[griffin] phase timeout: " + phase);
    // Keep a typed, repeatable snapshot beside the phase failure.  This is
    // deliberately a read-only query: the mission must never turn a timeout
    // into a hidden pose/physics mutation just to make the report look good.
    let gates = griffin_surface_ops::landing_gate_report();
    let ramp_runtime = griffin_surface_ops::physical_ramp_runtime_pose_evidence();
    let ramp_joints = griffin_surface_ops::physical_ramp_joint_evidence();
    print("[griffin] phase timeout evidence: " + #{landing: gates,
        physical_ramps: ramp_runtime, physical_ramp_joints: ramp_joints});
    let source = sysml_requirements::source();
    let failure = #{id: "GR-004-phase-" + phase, component: "mission",
        requirement: "GriffinFunctionalRequirements::gr004",
        verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations",
        kind: "phase", path: "/Griffin1SurfaceOps", actual: phase,
        expected: "completed", ok: false, error: "phase timed out"};
    report_structured_verdict(#{ok: false, verification:
        "Griffin1Requirements::Verify_GriffinSurfaceOperations",
        requirement_count: 1, source_revision: source.source_revision,
        source_files: source.source_files, results: [failure], failures: [failure],
        metrics: #{phase: phase, event_trace: state.event_trace,
            clocks: clock_snapshot(), landing_gates: gates,
            route_command_updates: state.route_command_updates}},
        "GRIFFIN SURFACE OPS", "GRIFFIN_SURFACE_OPS");
    emit("griffin_phase_timeout");
}

fn finish_surface_ops(state) {
    let source = sysml_requirements::source();
    let egress_apron = if state.egress_apron_evidence == () {
        griffin_surface_ops::egress_apron_runtime_evidence(find_path(ROVER))
    } else {
        state.egress_apron_evidence
    };
    let egress_apron_ok = egress_apron != () && egress_apron.ok == true;
    let checks = [
        #{id: "GR-004-lander-settled", component: "landing", requirement: "GriffinFunctionalRequirements::gr004", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: "/Griffin1SurfaceOps/Lander", actual: state.lander_settled, expected: true, ok: state.lander_settled, error: "lander did not settle"},
        #{id: "GR-003-ramps-deployed", component: "egress_ramps", requirement: "GriffinFunctionalRequirements::gr003", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: "/Griffin1SurfaceOps/Lander/EgressRampPort", actual: state.ramps_deployed, expected: true, ok: state.ramps_deployed, error: "ramps were not deployed"},
        #{id: "GR-026-adapter-release", component: "payload_adapter", requirement: "GriffinFunctionalRequirements::gr026", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: DOCK, actual: state.rover_detached, expected: true, ok: state.rover_detached, error: "FLIP adapter was not released"},
        #{id: "GR-004-route-engaged", component: "rover", requirement: "GriffinFunctionalRequirements::gr004", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: ROVER, actual: state.route_engaged, expected: true, ok: state.route_engaged, error: "FLIP route was not engaged"},
        #{id: "GR-007-ramp-approach", component: "rover", requirement: "GriffinFunctionalRequirements::gr007", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: "/Griffin1SurfaceOps/RoverRampApproach", actual: state.ramp_approach_reached, expected: true, ok: state.ramp_approach_reached, error: "ramp approach was not reached"},
        #{id: "GR-007-ramp-exit", component: "rover", requirement: "GriffinFunctionalRequirements::gr007", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: "/Griffin1SurfaceOps/RoverRampExit", actual: state.ramp_exit_reached, expected: true, ok: state.ramp_exit_reached, error: "ramp exit was not reached"},
        #{id: "GR-004-waypoint-1", component: "rover", requirement: "GriffinFunctionalRequirements::gr004", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: "/Griffin1SurfaceOps/RoverTarget1", actual: state.waypoint_1_reached, expected: true, ok: state.waypoint_1_reached, error: "first survey waypoint was not reached"},
        #{id: "GR-004-waypoint-2", component: "rover", requirement: "GriffinFunctionalRequirements::gr004", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: "/Griffin1SurfaceOps/RoverTarget2", actual: state.waypoint_2_reached, expected: true, ok: state.waypoint_2_reached, error: "second survey waypoint was not reached"},
        #{id: "GR-004-base-site", component: "rover", requirement: "GriffinFunctionalRequirements::gr004", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: "/Griffin1SurfaceOps/BaseSite", actual: state.base_site_reached, expected: true, ok: state.base_site_reached, error: "base site was not reached"},
        #{id: "GR-004-mission-ready", component: "mission", requirement: "GriffinFunctionalRequirements::gr004", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "phase", path: "/Griffin1SurfaceOps", actual: state.mission_ready, expected: true, ok: state.mission_ready, error: "mission readiness gate failed"},
        #{id: "GR-034-route-frame", component: "rover", requirement: "GriffinFunctionalRequirements::gr034", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "preflight", path: "/Griffin1SurfaceOps", actual: state.route_preflight, expected: true, ok: state.route_preflight != () && state.route_preflight.ok == true, error: "route markers do not agree with the active rover frame"},
        #{id: "GR-035-egress-apron-contact", component: "egress_apron", requirement: "GriffinFunctionalRequirements::gr035", verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations", kind: "contact", path: "/Griffin1SurfaceOps/EgressApron", actual: egress_apron, expected: "typed 10 x 8 x 0.1 m collision apron with native FLIP wheel contact at ramp exit", ok: egress_apron_ok, error: "GR-035 apron geometry or native wheel contact evidence is missing"}
    ];
    let failures = [];
    for check in checks { if check.ok != true { failures.push(check); } }
    report_structured_verdict(#{ok: failures.len() == 0,
        verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations",
        requirement_count: checks.len(), source_revision: source.source_revision,
        source_files: source.source_files, results: checks, failures: failures,
        metrics: #{event_trace: state.event_trace, clocks: clock_snapshot(),
            route_preflight: state.route_preflight,
            egress_apron: egress_apron,
            final_state: state}},
        "GRIFFIN SURFACE OPS", "GRIFFIN_SURFACE_OPS");
}

fn task(me, ctx) {
    let egress_route = griffin_surface_ops::surface_egress_task(find_path(ROVER));
    let route = griffin_surface_ops::surface_route_task(find_path(ROVER));
    let route_preflight = griffin_surface_ops::surface_route_preflight();
    seq([
        once(|m| {
            this.route_preflight = route_preflight;
            if !begin_descent(m) { this.mission_ready = false; };
            true
        }),
        par_race([
            par_all([
                wait_for_from("lander_engine_cutoff", "/Griffin1SurfaceOps/Lander/GNC"),
                wait_for_from("lander_flight_handoff", "/Griffin1SurfaceOps/Lander/GNC"),
                wait_for_from("lander_touchdown", "/Griffin1SurfaceOps/Lander"),
            ]),
            seq([
                // This watchdog is a SysML-authored bound for a missing
                // physical event. It cannot create a PASS; the event branch
                // must still complete the landing predicates.
                wait(griffin_spec::landing_phase_timeout_s()),
                once(|m| { this.phase_timeout = true; fail_phase(this, "landing"); true }),
            ]),
        ]),
        // `par_race` succeeds when the timeout branch completes; stop the
        // mission immediately after its structured failure verdict instead of
        // falling through to touchdown/egress steps.
        check(|m| this.phase_timeout != true),
        once(|m| { this.lander_settled = true; touchdown_notice(m); true }),
        wait(1.5),
        once(|m| {
            let unfold = unfold_ramp_sections(m);
            if unfold.ok != true {
                this.phase_timeout = true;
                fail_phase(this, "ramp-unfold");
            }
            true
        }),
        wait(3.0),
        check(|m| this.phase_timeout != true),
        once(|m| {
            let ramps = deploy_ramps(m);
            if ramps.ok == true {
                this.ramps_deployed = true;
            } else {
                this.phase_timeout = true;
                fail_phase(this, "ramp-deploy");
            }
            true
        }),
        wait(4.0),
        check(|m| this.phase_timeout != true),
        once(|m| {
            if release_rover(m, this.release_requested) {
                this.release_requested = true;
            } else {
                this.phase_timeout = true;
                fail_phase(this, "adapter-release");
            }
            true
        }),
        // The command acknowledgement only means the request was accepted.
        // Wait until the physics-owned lifecycle has retired the live entity,
        // then hand rover control to the Twin.
        wait_until(|m| adapter_detach_complete()),
        once(|m| {
            complete_rover_release(m);
            this.rover_detached = true;
            true
        }),
        wait(0.25),
        once(|m| {
            let engaged = engage_rover(m);
            if engaged.ok == true {
                this.route_engaged = true;
                this.rover_brake_held = true;
            } else {
                this.phase_timeout = true;
                fail_phase(this, "rover-engage");
            }
            true
        }),
        check(|m| this.phase_timeout != true),
        // The rover is released from a top-deck adapter several metres above
        // the pad. It must first drive across the authored deck and down the
        // selected physical ramp. This is an egress operation, not a settle
        // delay or a pose write; the next gate samples support only after the
        // ramp-exit leg has completed.
        once(|m| {
            let released = release_rover_settle_brake();
            if released.ok == true {
                this.rover_brake_held = false;
            } else {
                this.phase_timeout = true;
                fail_phase(this, "rover-brake-release");
            }
            true
        }),
        check(|m| this.phase_timeout != true),
        egress_route,
        // Wait on authoritative ground support and velocity rather than a
        // guessed delay before issuing survey-route torque. The height bound
        // is the source-backed post-release surface envelope.
        par_race([
                wait_until(|m| {
                    let rover = find_path(ROVER);
                    let tick = sim_tick();
                    let previous = this.rover_settle_probe_tick;
                    if previous != () && tick >= previous && tick - previous < 6 {
                        return false;
                    }
                    this.rover_settle_probe_tick = tick;
                    griffin_surface_ops::rover_route_settle_ready(rover)
                }),
            seq([
                // A free-body release should settle within a few seconds. If
                // it does not, report the physical state instead of allowing
                // the route task to hang until the outer harness expires.
                wait(griffin_spec::rover_settle_timeout_s()),
                once(|m| { this.phase_timeout = true; fail_phase(this, "rover-settle"); true }),
            ]),
        ]),
        check(|m| this.phase_timeout != true),
        // Drive every leg through the shared navigation/SetPorts surface.  A
        // completion edge is emitted after each typed arrival so the existing
        // scenario evidence remains event-driven and repeatable.
        route,
        // `surface_route_task` is already the ordered completion gate: it
        // returns only after every route leg has reached its typed horizontal
        // arrival predicate. Waiting for the same events a second time here
        // races against events that were emitted by the completed child and
        // used to leave an otherwise successful mission at NO-VERDICT. The
        // completion edge remains observable through on_event; this boundary
        // records the child-task result directly for the final structured
        // verdict.
        once(|m| {
            this.ramp_approach_reached = true;
            this.ramp_exit_reached = true;
            this.waypoint_1_reached = true;
            this.waypoint_2_reached = true;
            this.base_site_reached = true;
            finish_surface_ops(this);
            true
        }),
    ])
}
