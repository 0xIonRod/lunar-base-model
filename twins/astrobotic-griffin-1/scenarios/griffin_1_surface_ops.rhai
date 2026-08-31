// Griffin-1 landing + surface-operations scenario.
//
// This is mission policy only. Continuous control remains in the composed
// Modelica lander/rover domains; this script waits for physical/model events,
// commands the two revolute ramp targets, detaches the top-deck adapter after
// touchdown, and announces phase transitions.

fn on_event(me, evt) {
    let rover = find("/Griffin1SurfaceOps/FLIP");
    if evt.name != "waypoint.reached" || evt.source != rover { return; }
    if evt.value == "/Griffin1SurfaceOps/RoverRampApproach" {
        emit("griffin_ramp_approach_reached");
        print("[griffin] rover reached ramp approach");
    } else if evt.value == "/Griffin1SurfaceOps/RoverRampExit" {
        emit("griffin_ramp_exit_reached");
        print("[griffin] rover cleared ramp");
    } else if evt.value == "/Griffin1SurfaceOps/RoverTarget1" {
        emit("griffin_waypoint_1_reached");
        print("[griffin] waypoint 1 reached");
    } else if evt.value == "/Griffin1SurfaceOps/RoverTarget2" {
        emit("griffin_waypoint_2_reached");
        print("[griffin] waypoint 2 reached");
    } else if evt.value == "/Griffin1SurfaceOps/BaseSite" {
        emit("griffin_base_site_reached");
        emit("griffin_surface_ops_complete");
        print("[griffin] base site reached; surface operations complete");
    }
}

fn begin_descent(me) {
    follow(find("/Griffin1SurfaceOps/Lander"));
    emit("griffin_powered_descent_started");
    notify_kind("Griffin-1 powered descent started.", "info");
    print("[griffin] powered descent started");
}

fn touchdown_notice(me) {
    emit("griffin_touchdown_confirmed");
    notify_kind("Griffin-1 touchdown confirmed.", "success");
    print("[griffin] touchdown confirmed");
}

fn deploy_ramps(me) {
    set(find("/Griffin1SurfaceOps/Lander/EgressRampPortHinge"), "angle", -0.58);
    set(find("/Griffin1SurfaceOps/Lander/EgressRampStarboardHinge"), "angle", 0.58);
    emit("griffin_ramps_deploy_commanded");
    notify_kind("Griffin side ramps deploying.", "info");
    print("[griffin] both egress-ramp hinge targets commanded");
}

fn release_rover(me) {
    emit("griffin_ramp_deployment_settled");
    // This is an execution-time release boundary. Interactive intent removes
    // the live fixed joint without trying to author a RemovePrim into a
    // runtime layer that does not own the authored scene joint.
    cmd("DetachJoint", #{
        target: find("/Griffin1SurfaceOps/FLIPPayloadAdapterJoint"),
        intent: "Interactive"
    });
    emit("griffin_flip_released");
    notify_kind("FLIP released from the top-deck adapter; rover egress enabled.", "info");
    print("[griffin] FLIP payload adapter detached");
}

fn engage_rover(me) {
    emit("griffin_flip_deployed");
    // The FLIP BTXML remains the editable route source, but it must not be
    // re-used implicitly here: the attached rover may have crossed a marker
    // while the lander was descending. Re-arm the complete route explicitly
    // after the adapter weld is detached, with the ramp-entry waypoint first.
    //
    // This bounded landing-demo uses an accelerated control demand so the
    // complete ramp-to-base acceptance path can be exercised in a short
    // deterministic run. It is not a claim about FLIP's flight speed: the
    // nominal public FLEX-family proxy remains the lower-speed profile in the
    // BTXML and the research register, and the live four-wheel drivetrain,
    // contact, battery, and thermal equations remain active here.
    let route = #{
        kind: "sequence",
        children: [
            #{ kind: "drive_to", target: [4.0, 6.2, 0.0], speed: 1.0, radius: 2.5 },
            #{ kind: "drive_to", target: [11.9, 1.0, 0.0], speed: 1.0, radius: 2.5 },
            #{ kind: "drive_to", target: [16.0, 0.0, 4.0], speed: 1.0, radius: 2.5 },
            #{ kind: "drive_to", target: [19.0, 0.0, 2.0], speed: 1.0, radius: 2.5 },
            #{ kind: "drive_to", target: [21.0, 0.0, 0.5], speed: 1.0, radius: 2.5 },
            #{ kind: "drive_to", target: [21.6, 0.0, -1.0], speed: 1.0, radius: 2.5 },
            #{ kind: "drive_to", target: [21.8, 0.0, -2.5], speed: 1.0, radius: 2.5 },
            #{ kind: "drive_to", target: [22.0, 0.0, -4.0], speed: 1.0, radius: 2.5 },
            #{ kind: "drive_to", target: [22.4, 0.0, -5.5], speed: 1.0, radius: 2.5 },
            #{ kind: "drive_to", target: [23.0, 0.0, -7.0], speed: 1.0, radius: 2.5 },
            #{ kind: "drive_to", target: [24.5, 0.0, -8.0], speed: 1.0, radius: 2.5 },
            #{ kind: "drive_to", target: [26.0, 0.0, -9.0], speed: 1.0, radius: 2.5 },
            #{ kind: "drive_to", target: [27.0, 0.0, -10.0], speed: 1.0, radius: 2.5 },
            #{ kind: "drive_to", target: [29.0, 0.0, -11.0], speed: 1.0, radius: 2.5 },
            #{ kind: "drive_to", target: [31.0, 0.0, -12.0], speed: 1.0, radius: 2.5 }
        ]
    };
    cmd("EngageAutopilot", #{
        vessel: find("/Griffin1SurfaceOps/FLIP"),
        spec_json: to_json(route)
    });
    notify_kind("FLIP deployment complete; rover route engaged.", "success");
    print("[griffin] FLIP route engaged");
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
                wait(90.0),
                once(|m| fail_phase(m, "landing")),
            ]),
        ]),
        once(|m| touchdown_notice(m)),
        wait(1.5),
        once(|m| deploy_ramps(m)),
        wait(4.0),
        once(|m| release_rover(m)),
        // Re-arm the route immediately after the adapter disappears. The rover
        // may enter the ramp-approach sensor during this short handoff; engaging
        // first keeps that physical arrival in the same ordered route session.
        wait(0.25),
        once(|m| engage_rover(m)),
        par_race([
            par_all([
                wait_for("griffin_ramp_approach_reached"),
                wait_for("griffin_ramp_exit_reached"),
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
