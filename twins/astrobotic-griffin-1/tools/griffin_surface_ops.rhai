// Griffin-1 surface-operations tools.
//
// This Twin-local library owns reusable mission presentation and route policy.
// Physical descent, contact, integrated ramp geometry, the adapter joint, and
// drivetrain remain authored in USD/Modelica and are commanded through the
// normal Rhai verbs. The functions are intentionally useful from other
// Griffin scenarios as well as the production surface-operations scenario.

/// Put the mission view on the lander while its authored GNC performs descent.
fn follow_lander() {
    follow(find("/Griffin1SurfaceOps/Lander"));
}

/// Hand the mission view to the rover immediately after the adapter release.
/// The follow camera makes the physical ramp exit and rover drop visible
/// without taking control away from the rover's autopilot.
fn follow_rover() {
    follow(find("/Griffin1SurfaceOps/FLIP"));
}

// Compact, named telemetry probe for the landing study.  This replaces ad-hoc
// multi-line REPL expressions: the same function can be called from the
// Editor, an API Rhai client, or a repeatability harness and returns the exact
// values that the scenario's landing gates consume.
fn landing_gate_report() {
    let lander = find("/Griffin1SurfaceOps/Lander");
    let gnc = find("/Griffin1SurfaceOps/Lander/GNC");
    let environment = find("/Griffin1SurfaceOps/Lander/Environment");
    let altimeter = find("/Griffin1SurfaceOps/Lander/Altimeter");
    let altimeter_model = find("/Griffin1SurfaceOps/Lander/Altimeter/Model");
    let pose = query("QueryUsdPrim", #{
        path: "/Griffin1SurfaceOps/Lander",
        attrs: ["xformOp:translate"]
    });
    let physics = query("QueryPhysicsState", #{id: lander});
    let rover = find("/Griffin1SurfaceOps/FLIP");
    let rover_physics = query("QueryPhysicsState", #{id: rover});
    let rover_settle = rover_route_settle_report(rover);
    let report = #{
        position: if pose == () { [] } else { pose.world_position },
        physics_state: physics,
        rover_physics_state: rover_physics,
        rover_settle: rover_settle,
        rover_brake_command: get(rover, "brake"),
        rover_throttle_command: get(rover, "throttle"),
        rover_steer_command: get(rover, "steer"),
        all_legs_contact: get(lander, "all_legs_contact"),
        upright_axis_y: get(lander, "upright_axis_y"),
        ground_speed: get(lander, "ground_speed"),
        descent_speed: get(lander, "descent_speed"),
        angular_speed: get(lander, "angular_speed"),
        maximum_leg_speed: get(lander, "maximum_leg_speed"),
        landing_contact: get(lander, "landing_contact"),
        touchdown: get(lander, "touchdown"),
        engine_cutoff_contact: get(lander, "engine_cutoff_contact"),
        landing_handoff: get(lander, "landing_handoff"),
        target_distance_m: get(gnc, "target_distance_m"),
        target_zone_gate: get(gnc, "target_zone_gate"),
        target_recovery_gate: get(gnc, "target_recovery_gate"),
        any_leg_contact: get(gnc, "any_leg_contact"),
        landing_handoff_request: get(gnc, "landing_handoff_request"),
        landing_engine_cutoff_request: get(gnc, "landing_engine_cutoff_request"),
        guidance_engage: get(gnc, "engage"),
        guidance_piloted: get(gnc, "piloted"),
        guidance_authority: get(gnc, "flight_authority_gate"),
        guidance_alignment: get(gnc, "engine_alignment_gate_output"),
        guidance_vertical_projection: get(gnc, "thrust_vertical_projection"),
        guidance_vertical_command: get(gnc, "vertical_limiter_output"),
        guidance_thrust_accel: get(gnc, "thrust_accel"),
        guidance_lateral_accel_magnitude: get(gnc, "lateral_accel_magnitude"),
        guidance_lateral_accel_x: get(gnc, "lateral_accel_x"),
        guidance_lateral_accel_z: get(gnc, "lateral_accel_z"),
        guidance_lateral_support_vertical_command: get(gnc, "lateral_support_vertical_command"),
        guidance_altitude_above_target: get(gnc, "altitude_above_target"),
        guidance_unsaturated_throttle: get(gnc, "unsaturated_throttle"),
        guidance_pid_y: get(gnc, "pid_y_command"),
        guidance_altimeter_confidence: get(gnc, "altimeter_altitude_confidence"),
        guidance_nav_y: get(gnc, "altimeter_vehicle_position_y"),
        environment_gravity_x: get(environment, "gravity_x"),
        environment_gravity_y: get(environment, "gravity_y"),
        environment_gravity_z: get(environment, "gravity_z"),
        guidance_nav_x: get(gnc, "navigation.nav_pos_x"),
        guidance_nav_z: get(gnc, "navigation.nav_pos_z"),
        ray_hit_valid: get(altimeter, "ray_hit_valid"),
        ray_distance_m: get(altimeter, "ray_distance"),
        ray_hit_position_y: get(altimeter, "ray_hit_position_y"),
        altimeter_range_m: get(altimeter_model, "range_m"),
        altimeter_range_valid: get(altimeter_model, "range_valid"),
        altimeter_range_confidence: get(altimeter_model, "range_confidence"),
        altimeter_vehicle_position_y: get(altimeter_model, "vehicle_position_y"),
        altimeter_input_ray_distance_m: get(altimeter_model, "ray_distance_m"),
        altimeter_input_ray_valid: get(altimeter_model, "ray_hit_valid"),
        throttle_cmd: get(gnc, "throttle_cmd"),
        lander_throttle: get(lander, "throttle"),
        pitch_cmd: get(gnc, "pitch_cmd"),
        roll_cmd: get(gnc, "roll_cmd")
    };
    print("[griffin] landing gates: pos=" + report.position
        + " legs=" + report.all_legs_contact
        + " upright=" + report.upright_axis_y
        + " ground=" + report.ground_speed + "m/s"
        + " descent=" + report.descent_speed + "m/s"
        + " angular=" + report.angular_speed + "rad/s"
        + " landing=" + report.landing_contact
        + " touchdown=" + report.touchdown
        + " handoff=" + report.landing_handoff);
    report
}

// Small observation payload for fixed-clock acceptance tests.  Keep the
// verbose landing_gate_report available for interactive diagnostics, but do
// not retain its nested physics snapshots in a per-tick test state map.
fn landing_stability_sample() {
    let lander = find("/Griffin1SurfaceOps/Lander");
    let pose = query("QueryUsdPrim", #{
        path: "/Griffin1SurfaceOps/Lander",
        attrs: ["xformOp:translate"]
    });
    #{
        position: if pose == () || pose.world_position == () { [] } else { pose.world_position },
        upright_axis_y: get(lander, "upright_axis_y"),
        ground_speed: get(lander, "ground_speed"),
        angular_speed: get(lander, "angular_speed"),
        touchdown: get(lander, "touchdown")
    }
}

// Stable, source-backed acceptance limits for a fixed-clock landing trial.
// SysML owns the limits; Rhai owns only the observation and verdict.
fn landing_stability_contract() {
    let max_tilt = griffin_spec::landing_max_tilt_rad();
    #{
        horizon_s: griffin_spec::landing_stability_horizon_s(),
        max_tilt_rad: max_tilt,
        min_upright_axis_y: if max_tilt == () { () } else { max_tilt.cos() },
        max_ground_speed_mps: griffin_spec::landing_max_ground_speed_mps(),
        max_angular_speed_rad_per_sec: griffin_spec::landing_max_angular_speed_rad_per_sec(),
        max_horizontal_drift_m: griffin_spec::landing_max_horizontal_drift_m(),
        divergence_tolerance_m: griffin_spec::landing_divergence_tolerance_m(),
        divergence_tolerance_upright: griffin_spec::landing_divergence_tolerance_upright(),
        divergence_tolerance_speed_mps: griffin_spec::landing_divergence_tolerance_speed_mps(),
        replay_tolerance_m: griffin_spec::landing_replay_tolerance_m(),
        replay_tolerance_upright: griffin_spec::landing_replay_tolerance_upright(),
        replay_tolerance_speed_mps: griffin_spec::landing_replay_tolerance_speed_mps(),
        replay_tolerance_time_s: griffin_spec::landing_replay_tolerance_time_s()
    }
}

// Repeatability metadata is kept with the Twin so a harness cannot silently
// compare different source revisions or a jittered/non-single-thread run.
// The production command supplies the clock controls; this helper reports the
// values that must be held constant and the current SysML source revision.
fn repeatability_contract() {
    let source = query("ValidateSysml", #{path: "twin://" + twin_name()});
    #{
        twin: twin_name(),
        source_revision: if source == () { "" } else { source.source_revision_hex },
        scene: "scenes/griffin_1_surface_ops.usda",
        threads: 1,
        jitter: 0.0,
        seed: 6840157149251759617,
        tick_hz: 60.0,
        note: "repeat luncosim test with the same scene revision and controls"
    }
}

/// The short, explicit Griffin landing-demo route: clear the authored ramp,
/// then reach the two survey gates and the base site. The top-deck approach
/// marker is deliberately not a post-release target: its y=6.2 m elevation
/// describes the attached payload deck, not the surface the rover drives on.
/// This is route data, not a claim about flight speed or the as-built FLIP ICD.
fn surface_route() {
    #{
        kind: "sequence",
        children: [
            #{ kind: "drive_to", target: [8.2, 1.0, 0.0], speed: 0.22, radius: 1.2, event: "griffin_ramp_exit_reached" },
            #{ kind: "drive_to", target: [16.0, 0.0, 4.0], speed: 0.35, radius: 1.2, event: "griffin_waypoint_1_reached" },
            #{ kind: "drive_to", target: [19.0, 0.0, 2.0], speed: 0.35, radius: 1.2, event: "griffin_transit_1_reached" },
            #{ kind: "drive_to", target: [21.0, 0.0, 0.5], speed: 0.35, radius: 1.2, event: "griffin_transit_2_reached" },
            // Keep every corner in front of the current heading. The generic
            // nav leaf pivots with zero throttle when a target is behind, but
            // the physical Ackermann rig needs forward motion to turn.
            #{ kind: "drive_to", target: [22.5, 0.0, 0.2], speed: 0.30, radius: 1.0, event: "griffin_transit_3_reached" },
            #{ kind: "drive_to", target: [23.7, 0.0, -0.3], speed: 0.30, radius: 1.0, event: "griffin_transit_4_reached" },
            #{ kind: "drive_to", target: [24.6, 0.0, -1.2], speed: 0.30, radius: 1.0, event: "griffin_transit_5_reached" },
            #{ kind: "drive_to", target: [25.2, 0.0, -2.3], speed: 0.30, radius: 1.0, event: "griffin_transit_6_reached" },
            #{ kind: "drive_to", target: [25.4, 0.0, -3.6], speed: 0.30, radius: 1.0, event: "griffin_waypoint_2_reached" },
            #{ kind: "drive_to", target: [25.8, 0.0, -4.9], speed: 0.30, radius: 1.0, event: "griffin_base_arc_1_reached" },
            #{ kind: "drive_to", target: [26.7, 0.0, -6.1], speed: 0.30, radius: 1.0, event: "griffin_base_arc_2_reached" },
            #{ kind: "drive_to", target: [28.0, 0.0, -7.2], speed: 0.30, radius: 1.0, event: "griffin_base_approach_reached" },
            #{ kind: "drive_to", target: [29.5, 0.0, -8.5], speed: 0.30, radius: 1.0, event: "griffin_base_final_reached" },
            #{ kind: "drive_to", target: [31.0, 0.0, -10.0], speed: 0.30, radius: 1.2, event: "griffin_base_site_reached" }
        ]
    }
}

/// Claim FLIP for the mission controller and drive one route point through the
/// shared navigation law.  This is deliberately a small Twin helper rather
/// than a second autopilot implementation: `nav_command` computes the typed
/// setpoint and `drive` sends the normal SetPorts command consumed by the
/// authored Ackermann Modelica drive law.
fn engage_route_subject() {
    let rover = find("/Griffin1SurfaceOps/FLIP");
    if rover < 0 { return #{ ok: false, error: "FLIP entity is unavailable" }; }
    let result = cmd("PossessVessel", #{ target: rover, bind_camera: false });
    if result == () || result.ok != true {
        return #{ ok: false, error: "FLIP rejected mission control" };
    }
    #{ ok: true, rover: rover }
}

fn drive_route_point(rover, target, speed, radius) {
    let command = nav_command(rover, target, speed, radius);
    if command == () {
        brake(rover);
        return false;
    }
    if command.arrived || command.brake > 0.5 {
        brake(rover);
        return true;
    }
    drive(rover, command.throttle, command.steer);
    false
}

// The release adapter leaves FLIP as a live rigid body.  Keep the route gate
// observable and reusable: callers can inspect the same pose/speed values that
// decide when it is safe to apply wheel torque, without adding a second
// physics or grounding implementation.
fn rover_route_settle_report(rover) {
    let pose = world_pos(rover);
    // `speed` is not a reflected component field. Read the generic physics
    // provider instead so this gate observes the same admitted rigid-body
    // state as every other Twin physics acceptance check.
    let physics = query("QueryPhysicsState", #{id: rover});
    let velocity = if physics == () || physics.linear_velocity_mps == () {
        ()
    } else {
        physics.linear_velocity_mps
    };
    let speed = if velocity == () || velocity.len() != 3 {
        ()
    } else {
        vlen(velocity)
    };
    let height_limit = griffin_spec::rover_settle_height_limit_m();
    let speed_limit = griffin_spec::rover_settle_speed_limit_mps();
    let ok = pose != () && speed != () && height_limit != () && speed_limit != ()
        && pose[1] <= height_limit && speed.abs() <= speed_limit;
    #{ok: ok,
      pose: pose, speed: speed, height_limit_m: height_limit,
      speed_limit_mps: speed_limit}
}

/// Build the native task tree for the short, observable surface route.  Every
/// leg waits on the same horizontal arrival predicate used by nav_command,
/// then emits a named mission edge consumed by the scenario's evidence hook.
/// The route remains data in `surface_route`; this function only lowers it to
/// the reusable Rhai task vocabulary.
// Build one route leg in its own call frame.  Rhai closures capture the local
// scope in which they are created; creating them directly inside the loop that
// owns `steps` also captures the growing task array and eventually exceeds the
// bounded string/value budget.  Keeping the closure frame here makes each
// leaf capture only the rover and this leg's datum, while `surface_route()`
// remains the single source of route geometry.
fn _surface_route_leg_task(rover, leg) {
    let target = leg.target;
    let target_speed = leg.speed;
    let arrival_radius = leg.radius;
    let event = leg.event;
    seq([
        step(|m| {
            griffin_surface_ops::drive_route_point(rover, target, target_speed, arrival_radius)
        }, |m| arrived(rover, target, arrival_radius)),
        once(|m| emit(event))
    ])
}

fn surface_route_task(rover) {
    // Keep one source of route geometry: the returned sequence is also the
    // machine-readable route consumed by tools and review scripts.
    let legs = surface_route().children;
    let steps = [];
    for leg in legs {
        steps.push(_surface_route_leg_task(rover, leg));
    }
    seq(steps)
}

/// Release the adapter and arm the complete route as one mission boundary.
/// Returns the typed command acknowledgment so callers can report a failure
/// instead of claiming that the rover moved when the command was rejected.
fn release_and_engage() {
    let release = cmd("DetachJoint", #{
        target: find("/Griffin1SurfaceOps/FLIPPayloadAdapterJoint"),
        intent: "Interactive"
    });
    if release.ok == false { return release; }
    engage_route_subject()
}
