// Griffin-1 landing + surface-operations scenario.
//
// This is mission policy only. Continuous control remains in the composed
// Modelica lander/rover domains; this script waits for physical/model events,
// confirms the authored solid-ramp pose, detaches the top-deck adapter after
// touchdown, and announces phase transitions. The ramp meshes are integrated
// into the lander compound; the unstable independent-body hinge variant is
// deliberately not selected by this mission.

fn on_event(me, evt) {
    let rover = find("/Griffin1SurfaceOps/FLIP");
    if evt.name != "waypoint.reached" || evt.source != rover { return; }
    let path = waypoint_event_path(evt);
    if path == () { return; }
    // Keep the marker presentation static during this mission. The generic
    // helper writes the runtime USD layer, which can rebuild a live physical
    // vehicle while its post-detach bodies are settling. Mission milestones
    // are already carried by this typed waypoint event; no color write is
    // worth disturbing the drivetrain.
    if path == "/Griffin1SurfaceOps/RoverRampApproach" {
        emit("griffin_ramp_approach_reached");
        print("[griffin] rover reached ramp approach");
    } else if path == "/Griffin1SurfaceOps/RoverRampExit" {
        emit("griffin_ramp_exit_reached");
        print("[griffin] rover cleared ramp");
    } else if path == "/Griffin1SurfaceOps/RoverTarget1" {
        emit("griffin_waypoint_1_reached");
        print("[griffin] waypoint 1 reached");
    } else if path == "/Griffin1SurfaceOps/RoverTarget2" {
        emit("griffin_waypoint_2_reached");
        print("[griffin] waypoint 2 reached");
    } else if path == "/Griffin1SurfaceOps/BaseSite" {
        emit("griffin_base_site_reached");
        emit("griffin_surface_ops_complete");
        print("[griffin] base site reached; surface operations complete");
    }
}

fn begin_descent(me) {
    griffin_surface_ops::follow_lander();
    griffin_controls::show_briefing();
    emit("griffin_powered_descent_started");
    notify_kind("Griffin-1 powered descent started.", "info");
    print("[griffin] powered descent started");
}

fn touchdown_notice(me) {
    griffin_controls::show_briefing();
    emit("griffin_touchdown_confirmed");
    notify_kind("Griffin-1 touchdown confirmed.", "success");
    print("[griffin] touchdown confirmed");
}

fn deploy_ramps(me) {
    // The two ramps are authored in their landed/folded-down pose and carry
    // collision geometry as part of the lander compound. Do not spawn a
    // separate rigid body here: the former revolute-body implementation could
    // separate from the lander and leave the bounded physics world.
    emit("griffin_ramps_deploy_commanded");
    notify_kind("Griffin solid side ramps are in the authored deployed pose.", "info");
    print("[griffin] solid egress ramps confirmed in authored deployed pose");
}

fn release_rover(me) {
    emit("griffin_ramp_deployment_settled");
    // This is an execution-time release boundary. Interactive intent removes
    // the live fixed joint without trying to author a RemovePrim into a
    // runtime layer that does not own the authored scene joint.
    griffin_surface_ops::follow_rover();
    griffin_controls::show_rover_controls();
    let release = cmd("DetachJoint", #{
        target: find("/Griffin1SurfaceOps/FLIPPayloadAdapterJoint"),
        intent: "Interactive"
    });
    if release.ok == false {
        notify_kind("FLIP adapter release was rejected.", "error");
        emit("griffin_phase_timeout");
        return;
    }
    emit("griffin_flip_released");
    notify_kind("FLIP released from the top-deck adapter; rover egress enabled.", "info");
    print("[griffin] FLIP payload adapter detached");
}

fn engage_rover(me) {
    emit("griffin_flip_deployed");
    // Re-claim the released rover with an explicit route. The FLIP assembly no
    // longer starts its behavior tree at scene load: while it is fixed to the
    // lander it must remain passive. This is the first point at which route
    // authority is valid.
    let route_ack = cmd("EngageAutopilot", #{
        vessel: find("/Griffin1SurfaceOps/FLIP"),
        spec_json: to_json(griffin_surface_ops::surface_route())
    });
    if route_ack.ok == false {
        notify_kind("Authored FLIP route was rejected.", "error");
        emit("griffin_phase_timeout");
        return;
    }
    notify_kind("FLIP deployment complete; authored rover route continues.", "success");
    print("[griffin] FLIP authored route continues after release");
}

fn fail_phase(me, phase) {
    print("[griffin] phase timeout: " + phase);
    emit("griffin_phase_timeout");
    emit("GRIFFIN_SURFACE_OPS", "FAIL");
}

fn task(me) {
    seq([
        once(|m| begin_descent(m)),
        par_race([
            par_all([
                wait_for_from("lander_engine_cutoff", "/Griffin1SurfaceOps/Lander/GNC"),
                wait_for_from("lander_flight_handoff", "/Griffin1SurfaceOps/Lander/GNC"),
                wait_for_from("lander_touchdown", "/Griffin1SurfaceOps/Lander"),
            ]),
            seq([
                // The authored 60 m descent settles just after 100 s in the
                // current powered-descent proxy. Keep the watchdog bounded,
                // but leave enough margin for the physical touchdown event to
                // arrive before declaring the mission failed.
                wait(180.0),
                once(|m| fail_phase(m, "landing")),
            ]),
        ]),
        once(|m| touchdown_notice(m)),
        wait(1.5),
        once(|m| deploy_ramps(m)),
        wait(4.0),
        once(|m| release_rover(m)),
        // Re-arm the authored BTXML immediately after the adapter disappears.
        wait(0.25),
        once(|m| engage_rover(m)),
        par_race([
            par_all([
                wait_for("griffin_waypoint_1_reached"),
                wait_for("griffin_waypoint_2_reached"),
                wait_for("griffin_base_site_reached"),
            ]),
            seq([
                wait(900.0),
                once(|m| fail_phase(m, "surface-route")),
            ]),
        ]),
        once(|m| emit("GRIFFIN_SURFACE_OPS", "PASS")),
    ])
}
