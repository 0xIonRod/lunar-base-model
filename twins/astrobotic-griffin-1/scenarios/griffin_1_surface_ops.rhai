// Griffin-1 landing + surface-operations scenario.
//
// Powered descent and rover steering remain in their Modelica domains. This
// automatic mission waits for landing and ramp settlement before egress.
// Manual ramp opening and adapter detachment remain available during flight.

const LANDER = "/Griffin1SurfaceOps/Lander";
const ROVER = "/Griffin1SurfaceOps/FLIP";
const DOCK = "/Griffin1SurfaceOps/FLIPPayloadAdapterJoint";

fn simulation_dependencies(me, ctx) {
    let lander = find_path(LANDER);
    let gnc = find_path(LANDER + "/GNC");
    let propulsion = find_path(LANDER + "/MainPropulsion");
    let altimeter_model = find_path(LANDER + "/Altimeter/Model");
    let imu = find_path(LANDER + "/IMU");
    let attitude_reference = find_path(LANDER + "/AttitudeReference");
    let attitude_propulsion = find_path(LANDER + "/AttitudePropulsion");
    let attitude_actuation = find_path(LANDER + "/AttitudeActuation");
    let rover = find_path(ROVER);
    let lander_environment = find_path(LANDER + "/Environment");
    let altimeter = find_path(LANDER + "/Altimeter");
    let ramp_joints = [
        find_path(LANDER + "/RampHingePort"),
        find_path(LANDER + "/RampHingeStarboard"),
        find_path(LANDER + "/RampSectionHingePort01"),
        find_path(LANDER + "/RampSectionHingePort12"),
        find_path(LANDER + "/RampSectionHingeStarboard01"),
        find_path(LANDER + "/RampSectionHingeStarboard12"),
    ];
    let entity_reads = [lander, gnc, propulsion, altimeter_model, imu,
        attitude_reference, attitude_propulsion, attitude_actuation, rover,
        lander_environment, altimeter];
    let entity_writes = [rover];
    for side in ["Port", "Starboard"] {
        entity_reads.push(find_path(LANDER+"/EgressRamp"+side));
    }
    for station in ["FL", "FR", "RL", "RR"] {
        entity_reads.push(find_path(ROVER+"/Suspension_"+station+"/Wheel_"+station));
    }
    let modelica_entities = [lander, gnc, propulsion, altimeter_model, imu,
        attitude_reference, attitude_propulsion, attitude_actuation, rover];
    for joint in ramp_joints {
        entity_reads.push(joint);
        entity_writes.push(joint);
    }
    #{
        modelica_entities: modelica_entities,
        entity_reads: entity_reads,
        entity_writes: entity_writes,
        query_reads: ["AnalyzeSysml", "ValidateSysml", "ReadActiveTwinContract",
            "QueryUsdPrim", "QueryUsdPrims", "QueryPhysicsState", "PhysicsPerformance",
            "ReadPorts", "ReadPortsBatch", "ReadModelicaStepSamples",
            "ListOpenDocuments", "Raycast", "TerrainHeight"],
        required_inputs: []
    }
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
    subscribe("griffin_ramp_unfold_requested");
    subscribe("griffin_rover_release_requested");
    for event_name in griffin_surface_ramp_ops::unfold_event_contract().ordered {
        subscribe(event_name);
    }
    subscribe("key:KeyU");
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
    this.ramp_unfold_requested = false;
    this.route_engaged = false;
    this.ramp_approach_reached = false;
    this.ramp_exit_reached = false;
    this.waypoint_1_reached = false;
    this.waypoint_2_reached = false;
    this.base_site_reached = false;
    this.mission_ready = true;
    this.phase_timeout = false;
    this.ramp_timeout = false;
    this.rover_brake_held = false;
    this.route_started = false;
    this.route_control_error = false;
    this.route_command_updates = 0;
    this.route_failure_evidence = ();
    this.route_preflight = ();
    this.egress_apron_evidence = ();
    this.landing_setup_evidence = ();
    this.guidance_assembly_mass_evidence = ();
    this.rover_settle_probe_tick = ();
    this.ramp_settle_probe_tick = ();
    this.ramp_sections_expected = ();
    this.ramp_section_final_commanded = false;
    this.ramp_unfold_waypoint_evidence = [];
    this.ramp_deployment_expected = ();
    this.ramp_traversal_stable_since = ();
    this.ramp_middle_settle_evidence = ();
    this.ramp_toe_settle_evidence = ();
    this.ramp_section_settle_evidence = ();
    this.ramp_deployment_settle_evidence = ();
    this.ramp_motion_trace = [];
    this.ramp_motion_trace_last_tick = ();
    this.phase_failure_reported = false;
    this.event_trace = [];
}

fn on_event(me, evt, ctx) {
    this.event_trace = griffin_surface_mission_report::trace_event(this, evt);
    let lander = find_path(LANDER);
    let rover = find_path(ROVER);

    // Shared controller and HUD requests converge on the same Twin-owned
    // manual actions. F on FLIP retains its vehicle-specific control meaning.
    if evt.name == "intent.edge" && evt.source == lander {
        let value = evt.value;
        if value != () && value["intent"] == "action" &&
           (value["edge"] == "pressed" || value["edge"] == "pulse") {
            let result=griffin_surface_ops::request_rover_release();
            if result.ok != true {notify_kind(result.error,"warn");}
        }
        return;
    }

    // The native shortcuts are accepted while the lander is the active local
    // vehicle. The HUD uses the same request functions without a possession
    // requirement; neither route is restricted by landing or mission phase.
    if evt.name == "key:KeyU" && owner_of(lander) == 0 && owner_of(rover) != 0 {
        let result = griffin_surface_ops::request_ramp_unfold();
        if result.ok != true { notify_kind(result.error, "warn"); }
        return;
    }

    if evt.name == "griffin_ramp_unfold_requested" {
        if this.ramp_unfold_requested || this.ramps_deployed { return; }
        this.ramp_unfold_requested = true;
        griffin_controls::show_ramp_unfolding_actions();
        print("[griffin] manual ramp unfold accepted");
        return;
    }

    if evt.name == "griffin_rover_release_requested" {
        if this.release_requested { return; }
        if release_rover(this, false) {
            this.release_requested = true;
            griffin_controls::show_rover_release_pending();
        } else {
            this.phase_timeout = true;
            this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "adapter-release");
        }
        return;
    }

    if evt.name == "lander_touchdown" && evt.source == lander {
        let status = update_landing_status(me, this.lander_settled);
        if status.ok == true { this.lander_settled = status.landed; }
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

fn landing_setup_preflight(state) {
    let setup = griffin_requirements::landing_setup_geometry_check(
        (), "/Griffin1SurfaceOps/LandingTarget",
        "/Griffin1SurfaceOps/LandingSitePad",
        "/Griffin1SurfaceOps/Lander");
    state.landing_setup_evidence = setup;
    if setup.ok != true {
        let detail = setup.error;
        print("[griffin] landing geometry preflight evidence: " + setup);
        if detail == () || detail == "" {
            detail = "landing geometry check failed without a diagnostic";
        }
        print("[griffin] landing geometry preflight failed: " + detail);
        notify_kind("Griffin landing target or contact pad does not match the SysML geometry.", "error");
        emit("griffin_surface_ops_geometry_failed");
        return false;
    }
    print("[griffin] landing geometry and four-leg spring rest-pose preflight PASS (target Y="
        + setup.target_y_m + " m, pad top Y=" + setup.pad_top_y_m + " m)");
    true
}

fn begin_descent(state) {
    let lander = find_path(LANDER);
    let status = griffin_surface_ops::landed_status();
    // Recompilation must not re-arm guidance or move the operator's camera
    // when this vehicle is already landed or under local manual control.
    if (status.ok == true && status.landed) || owner_of(lander) == 0 {
        griffin_controls::show_briefing();
        return true;
    }
    let mass = state.guidance_assembly_mass_evidence;
    if mass == () || mass.ok != true {
        let detail = if mass == () || mass.error == () { "assembly mass evidence is unavailable" } else { mass.error };
        print("[griffin] guidance mass preflight failed: " + detail + " " + mass);
        notify_kind("Guidance has no valid complete lander assembly mass; powered descent is inhibited.", "error");
        emit("griffin_surface_ops_guidance_mass_failed");
        return false;
    }
    print("[griffin] guidance dynamic joint-island mass preflight PASS: " + mass);
    let arm = griffin_surface_ops::arm_descent_guidance();
    if arm.ok != true {
        let detail = if arm.error == () { "descent guidance could not be armed" } else { arm.error };
        print("[griffin] descent guidance arm failed: " + detail);
        notify_kind("Descent guidance did not accept mission authority.", "error");
        emit("griffin_surface_ops_guidance_arm_failed");
        return false;
    }
    griffin_surface_ops::follow_lander();
    griffin_controls::show_briefing();
    emit("griffin_powered_descent_started");
    notify_kind("Griffin-1 powered descent started.", "info");
    print("[griffin] powered descent started");
    true
}

fn update_landing_status(me, previously_landed) {
    let status = griffin_surface_ops::landed_status();
    if status.ok == true {
        if status.landed && !previously_landed { touchdown_notice(me); }
        if !status.landed && previously_landed {
            hint("LANDING NOT CONFIRMED: U opens ramps; F detaches FLIP. Both remain available.");
        }
    }
    status
}

fn on_stop(me, ctx) {
    // The guided overlay is app-wide, so retire this mission's controls when
    // its scenario is stopped even if the Welcome tab stays open underneath.
    hint("");
    objectives_hud([]);
    griffin_controls::clear_surface_operation_actions();
}

fn touchdown_notice(me) {
    griffin_controls::show_touchdown_actions();
    emit("griffin_touchdown_confirmed");
    notify_kind("Griffin-1 touchdown confirmed.", "success");
    print("[griffin] touchdown confirmed");
}

fn release_rover(state, already_requested) {
    if already_requested { return true; }

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

fn ramp_unfold_task() {
    seq([
        // Manual requests start this independent physical sequence immediately;
        // unattended runs request it only after their landing gates complete.
        wait_until(|m| this.ramp_unfold_requested || this.ramp_timeout),
        check(|m| this.ramp_timeout != true),
        once(|m| {
            this.ramp_motion_trace = [];
            this.ramp_motion_trace_last_tick = ();
            this.ramp_section_final_commanded = false;
            let middle = griffin_surface_ramp_ops::unfold_middle_sections();
            if middle.ok != true {
                this.ramp_timeout = true;
                this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "ramp-middle-unfold-command");
            } else {
                this.ramp_sections_expected = middle.expected_angles;
            }
            true
        }),
        check(|m| this.ramp_timeout != true),
        par_race([
            seq([
                wait_until(|m| {
                    let trace = griffin_surface_ops::update_physical_ramp_motion_trace(
                        this.ramp_motion_trace, this.ramp_motion_trace_last_tick,
                        "middle-unfold");
                    this.ramp_motion_trace = trace.samples;
                    this.ramp_motion_trace_last_tick = trace.last_tick;
                    let tick = sim_tick();
                    let previous = this.ramp_settle_probe_tick;
                    if previous != () && tick >= previous && tick - previous < 6 {
                        return false;
                    }
                    this.ramp_settle_probe_tick = tick;
                    let progress=griffin_surface_ramp_ops::section_unfold_progress(
                        this.ramp_sections_expected,"middle",this.ramp_section_final_commanded,
                        this.ramp_unfold_waypoint_evidence);
                    if progress.ok!=true {
                        this.ramp_timeout=true;
                        this.phase_failure_reported=griffin_surface_mission_report::fail_phase(this,"ramp-middle-unfold-progress");
                        return true;
                    }
                    this.ramp_section_settle_evidence=progress.evidence;
                    this.ramp_sections_expected=progress.expected_angles;
                    this.ramp_section_final_commanded=progress.final_commanded;
                    this.ramp_unfold_waypoint_evidence=progress.waypoint_evidence;
                    progress.settled
                })
            ]),
            seq([
                wait(20.0),
                once(|m| {
                    this.ramp_section_settle_evidence =
                        griffin_surface_ops::physical_ramp_hinges_settled(
                            this.ramp_sections_expected, griffin_spec::physical_ramp_hinge_settle_angle_tolerance_rad());
                    this.ramp_timeout = true;
                    this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "ramp-middle-unfold-settle");
                    true
                })
            ])
        ]),
        check(|m| this.ramp_timeout != true),
        once(|m| {
            this.ramp_middle_settle_evidence = this.ramp_section_settle_evidence;
            emit(griffin_surface_ramp_ops::unfold_event_contract().middle_settled);
            true
        }),
        once(|m| {
            this.ramp_motion_trace = [];
            this.ramp_motion_trace_last_tick = ();
            this.ramp_section_final_commanded = false;
            let toes = griffin_surface_ramp_ops::unfold_toes();
            if toes.ok != true {
                this.ramp_timeout = true;
                this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "ramp-toe-unfold-command");
            } else {
                this.ramp_sections_expected = toes.expected_angles;
            }
            true
        }),
        check(|m| this.ramp_timeout != true),
        par_race([
            seq([
                wait_until(|m| {
                    let trace = griffin_surface_ops::update_physical_ramp_motion_trace(
                        this.ramp_motion_trace, this.ramp_motion_trace_last_tick,
                        "toe-unfold");
                    this.ramp_motion_trace = trace.samples;
                    this.ramp_motion_trace_last_tick = trace.last_tick;
                    let tick = sim_tick();
                    let previous = this.ramp_settle_probe_tick;
                    if previous != () && tick >= previous && tick - previous < 6 {
                        return false;
                    }
                    this.ramp_settle_probe_tick = tick;
                    let progress=griffin_surface_ramp_ops::section_unfold_progress(
                        this.ramp_sections_expected,"toe",this.ramp_section_final_commanded,
                        this.ramp_unfold_waypoint_evidence);
                    if progress.ok!=true {
                        this.ramp_timeout=true;
                        this.phase_failure_reported=griffin_surface_mission_report::fail_phase(this,"ramp-toe-unfold-progress");
                        return true;
                    }
                    this.ramp_section_settle_evidence=progress.evidence;
                    this.ramp_sections_expected=progress.expected_angles;
                    this.ramp_section_final_commanded=progress.final_commanded;
                    this.ramp_unfold_waypoint_evidence=progress.waypoint_evidence;
                    progress.settled
                })
            ]),
            seq([
                wait(30.0),
                once(|m| {
                    this.ramp_section_settle_evidence =
                        griffin_surface_ops::physical_ramp_hinges_settled(
                            this.ramp_sections_expected, griffin_spec::physical_ramp_hinge_settle_angle_tolerance_rad());
                    this.ramp_timeout = true;
                    this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "ramp-toe-unfold-settle");
                    true
                })
            ])
        ]),
        check(|m| this.ramp_timeout != true),
        once(|m| {
            this.ramp_toe_settle_evidence = this.ramp_section_settle_evidence;
            emit(griffin_surface_ramp_ops::unfold_event_contract().toes_settled);
            true
        }),
        once(|m| {
            let plan=griffin_surface_ramp_ops::root_deployment_plan();
            this.ramp_terrain_plan=plan;
            this.ramp_deployment_expected=if plan.ok==true {plan.expected_angles} else {()};
            if this.ramp_deployment_expected!=() {
                for expected in this.ramp_sections_expected {
                    this.ramp_deployment_expected.push(expected);
                }
            }
            this.ramp_traversal_stable_since=();
            if this.ramp_deployment_expected == () {
                this.ramp_timeout = true;
                this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "ramp-root-deployment-targets");
                return true;
            }
            this.ramp_motion_trace = [];
            this.ramp_motion_trace_last_tick = ();
            let ramps = griffin_surface_ramp_ops::deploy_roots(plan.expected_angles);
            if ramps.ok != true {
                this.ramp_timeout = true;
                this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "ramp-root-deploy-command");
            }
            true
        }),
        check(|m| this.ramp_timeout != true),
        par_race([
            seq([
                wait_until(|m| {
                    let trace = griffin_surface_ops::update_physical_ramp_motion_trace(
                        this.ramp_motion_trace, this.ramp_motion_trace_last_tick,
                        "root-deployment");
                    this.ramp_motion_trace = trace.samples;
                    this.ramp_motion_trace_last_tick = trace.last_tick;
                    let tick = sim_tick();
                    let previous = this.ramp_settle_probe_tick;
                    if previous != () && tick >= previous && tick - previous < 6 {
                        return false;
                    }
                    this.ramp_settle_probe_tick = tick;
                    let progress=griffin_surface_ramp_ops::traversal_settle_progress(
                        this.ramp_deployment_expected,this.ramp_traversal_stable_since);
                    this.ramp_traversal_stable_since=progress.stable_since;
                    this.ramp_deployment_settle_evidence=progress.evidence;
                    progress.ok==true && progress.settled==true
                })
            ]),
            seq([
                wait(30.0),
                once(|m| {
                    let progress=griffin_surface_ramp_ops::traversal_settle_progress(
                        this.ramp_deployment_expected,this.ramp_traversal_stable_since);
                    this.ramp_traversal_stable_since=progress.stable_since;
                    this.ramp_deployment_settle_evidence=progress.evidence;
                    this.ramp_timeout = true;
                    this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "ramp-root-deployment-settle");
                    true
                })
            ])
        ]),
        check(|m| this.ramp_timeout != true),
        once(|m| {
            this.ramps_deployed = true;
            emit(griffin_surface_ramp_ops::unfold_event_contract().roots_settled);
            griffin_controls::show_rover_release_actions();
            print("[griffin] both physical ramps reached their measured deployment hinge targets");
            if is_unattended() {
                if release_rover(this, false) {
                    this.release_requested = true;
                } else {
                    this.ramp_timeout = true;
                    this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "adapter-release");
                }
            }
            true
        }),
    ])
}

fn landing_confirmation_task() {
    if is_unattended() {
        par_race([
            par_all([
                wait_for_from("lander_engine_cutoff", "/Griffin1SurfaceOps/Lander/GNC"),
                wait_for_from("lander_flight_handoff", "/Griffin1SurfaceOps/Lander/GNC"),
                wait_for_from("lander_touchdown", "/Griffin1SurfaceOps/Lander"),
            ]),
            seq([
                // This watchdog cannot create a PASS; the event branch must
                // complete the powered-descent and physical landing contract.
                wait(griffin_spec::landing_phase_timeout_s()),
                once(|m| {
                    this.phase_timeout = true;
                    this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "landing");
                    true
                }),
            ]),
        ])
    } else {
        // landing_status_task observes the qualified Modelica contact state.
        wait_until(|m| this.lander_settled)
    }
}

fn surface_mission_task() {
    let egress_route = griffin_surface_ops::surface_egress_task(find_path(ROVER));
    let route = griffin_surface_ops::surface_route_task(find_path(ROVER));
    let route_preflight = griffin_surface_ops::surface_route_preflight();
    seq([
        once(|m| {
            this.route_preflight = route_preflight;
            if !landing_setup_preflight(this) {
                this.mission_ready = false;
                this.phase_timeout = true;
                this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "landing-setup-preflight");
            }
            true
        }),
        check(|m| this.phase_timeout != true),
        par_race([
            wait_until(|m| {
                let evidence = griffin_surface_ops::guidance_assembly_mass_report();
                this.guidance_assembly_mass_evidence = evidence;
                evidence.ready == true
            }),
            seq([
                wait(griffin_spec::landing_phase_timeout_s()),
                once(|m| {
                    this.phase_timeout = true;
                    this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "guidance-assembly-mass-readiness");
                    true
                }),
            ]),
        ]),
        check(|m| this.phase_timeout != true),
        once(|m| {
            if !begin_descent(this) {
                this.mission_ready = false;
                this.phase_timeout = true;
                this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "guidance-assembly-mass-contract");
            }
            true
        }),
        check(|m| this.phase_timeout != true),
        landing_confirmation_task(),
        // `par_race` succeeds when the timeout branch completes; stop the
        // mission immediately after its structured failure verdict instead of
        // falling through to touchdown/egress steps.
        check(|m| this.phase_timeout != true),
        once(|m| {
            let status = update_landing_status(m, this.lander_settled);
            if status.ok == true { this.lander_settled = status.landed; }
            true
        }),
        wait(1.5),
        once(|m| {
            // Preserve the autonomous post-touchdown dwell. Manual U starts
            // the independent hinge sequence whenever the operator requests.
            if is_unattended() { this.ramp_unfold_requested = true; }
            true
        }),
        wait_until(|m| this.ramps_deployed || this.ramp_timeout || this.phase_timeout),
        check(|m| this.phase_timeout != true),
        check(|m| this.ramp_timeout != true),
        // F and the HUD button share the same immediate detach request.
        wait_until(|m| this.release_requested || this.phase_timeout),
        check(|m| this.phase_timeout != true),
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
                this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "rover-engage");
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
                this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "rover-brake-release");
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
                once(|m| { this.phase_timeout = true; this.phase_failure_reported = griffin_surface_mission_report::fail_phase(this, "rover-settle"); true }),
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
            griffin_surface_mission_report::finish_surface_ops(this);
            true
        }),
    ])
}

// Interactive status remains observed even if autonomous mission acceptance
// fails. Its failure verdict is retained; manual mechanism authority survives.
fn landing_status_task() {
    forever(seq([
        wait(0.1),
        once(|m| {
            let status = update_landing_status(m, this.lander_settled);
            if status.ok == true { this.lander_settled = status.landed; }
            true
        })
    ]))
}

fn task(me, ctx) {
    if is_unattended() {
        par_all([ramp_unfold_task(), surface_mission_task()])
    } else {
        let operator = par_all([ramp_unfold_task(), landing_status_task()]);
        par_race([surface_mission_task(), operator])
    }
}
