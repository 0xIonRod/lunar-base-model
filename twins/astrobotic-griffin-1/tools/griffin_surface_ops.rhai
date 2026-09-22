// Griffin-1 surface-operations tools.
//
// This Twin-local library owns reusable mission presentation and route policy.
// Physical descent, contact, integrated ramp geometry, the adapter joint, and
// drivetrain remain authored in USD/Modelica and are commanded through the
// normal Rhai verbs. The functions are intentionally useful from other
// Griffin scenarios as well as the production surface-operations scenario.

// SetPorts is a persistent level command. Re-sending an unchanged route
// setpoint every fixed tick only re-enters command reflection and flushing;
// it does not improve control authority. Ten updates per simulated second
// preserve the low-speed rover response while keeping command traffic bounded.
// The cadence is derived from the admitted simulation clock, never wall time.
fn route_command_rate_hz() { 10.0 }

// A route leg is a physical operation, not an unbounded retry loop. If the
// measured horizontal distance has not improved for this long, the Twin emits
// a control fault and the scenario reports evidence immediately instead of
// spending its full mission timeout in a solver/contact deadlock.
fn route_stall_timeout_s() { griffin_spec::surface_route_stall_timeout_s() }

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
    // Topology/performance is sampled only at an explicit diagnostic gate;
    // keeping it out of per-tick control avoids turning a useful probe into a
    // source of allocations during a mission.
    let physics_performance = query("PhysicsPerformance", #{});
    let report = #{
        position: if pose == () { [] } else { pose.world_position },
        physics_state: physics,
        rover_physics_state: rover_physics,
        rover_settle: rover_settle,
        physics_performance: physics_performance,
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

/// Return the generic physics/topology snapshot used by Twin diagnostics.
/// This is intentionally a thin Rhai name over the core query: no component
/// count or detach bookkeeping is reimplemented in the Twin.
fn physics_performance() {
    query("PhysicsPerformance", #{})
}

// Small observation payload for fixed-clock acceptance tests.  Keep the
// verbose landing_gate_report available for interactive diagnostics, but do
// not retain its nested physics snapshots in a per-tick test state map.
fn landing_stability_sample() {
    let lander = find("/Griffin1SurfaceOps/Lander");
    if lander == () || lander < 0 { return (); }
    let pose = query("QueryUsdPrim", #{
        path: "/Griffin1SurfaceOps/Lander",
        attrs: ["xformOp:translate"]
    });
    let physics = query("QueryPhysicsState", #{id: lander});
    if pose == () || pose.ok == false || pose.world_position == ()
        || physics == () || physics.ok == false
        || physics.physics_state_ready != true {
        return ();
    }
    let linear = physics.linear_velocity_mps;
    let angular = physics.angular_velocity_radps;
    let up = world_up3(lander);
    if linear == () || linear.len() != 3 || angular == () || angular.len() != 3
        || up == () {
        return ();
    }
    let ground_speed = (linear[0] * linear[0] + linear[2] * linear[2]).sqrt();
    let angular_speed = vlen(angular);
    #{
        position: pose.world_position,
        upright_axis_y: up.y,
        ground_speed: ground_speed,
        angular_speed: angular_speed,
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

// Resolve a route datum from its authored marker.  Route geometry must have a
// single owner: the USD assembly owns the marker pose, while this Twin tool
// owns only the operation order and control limits.  A missing marker is a
// construction error, not permission to carry a duplicate literal.
fn route_marker_target(path) {
    let marker = find(path);
    if marker == () || marker < 0 {
        throw("Griffin route marker is missing: " + path);
    }
    let pose = world_pos3(marker);
    if pose == () {
        throw("Griffin route marker pose is unavailable: " + path);
    }
    pose
}

// Validate the route frame before lowering any drive task.  SysML owns the
// ordered marker table; the composed scene owns the actual marker transforms;
// the active rover owns the forward axis.  Keeping these three observations in
// one bounded preflight prevents a stale marker table or a frame/sign error
// from becoming a late route stall.
fn surface_route_preflight() {
    let names = griffin_spec::surface_route_marker_names();
    let expected_x = griffin_spec::surface_route_marker_x();
    let expected_y = griffin_spec::surface_route_marker_y();
    let expected_z = griffin_spec::surface_route_marker_z();
    let findings = [];
    let markers = [];
    let count_ok = names.len() > 0
        && expected_x.len() == names.len()
        && expected_y.len() == names.len()
        && expected_z.len() == names.len();
    if !count_ok {
        findings.push("SysML route marker table has inconsistent cardinality");
        return #{ok: false, findings: findings, markers: markers,
            marker_count: names.len(), forward_alignment: ()};
    }

    let previous = ();
    for index in 0..names.len() {
        let path = "/Griffin1SurfaceOps/" + names[index];
        let marker = find(path);
        let actual = if marker == () || marker < 0 { () } else { world_pos3(marker) };
        let expected = vec3(expected_x[index], expected_y[index], expected_z[index]);
        if actual == () {
            findings.push(path + " has no world marker pose");
        } else {
            let valid = actual.x.is_finite() && actual.y.is_finite() && actual.z.is_finite();
            if !valid {
                findings.push(path + " marker pose is non-finite");
            } else {
                if vlen(vsub(actual, expected)) > 0.02 {
                    findings.push(path + " disagrees with its SysML route datum");
                }
                if index > 0 && previous != ()
                    && vlen(vec3(actual.x - previous.x, 0.0, actual.z - previous.z)) < 0.05 {
                    findings.push(path + " is too close to the previous route marker");
                }
            }
        }
        markers.push(#{name: names[index], path: path,
            expected: vec3_array(expected), actual: if actual == () { () } else { vec3_array(actual) }});
        if actual != () { previous = actual; }
    }

    let rover = find("/Griffin1SurfaceOps/FLIP");
    let rover_pose = if rover == () || rover < 0 { () } else { world_pos3(rover) };
    let rover_forward = if rover == () || rover < 0 { () } else { world_forward3(rover) };
    let first_actual = if markers.len() == 0 { () } else { markers[0].actual };
    let alignment = ();
    if rover_pose != () && rover_forward != () && first_actual != () {
        let delta = vec3(first_actual[0] - rover_pose.x, 0.0,
            first_actual[2] - rover_pose.z);
        let forward_plane = vec3(rover_forward.x, 0.0, rover_forward.z);
        let delta_len = vlen(delta);
        let forward_len = vlen(forward_plane);
        if delta_len > 0.05 && forward_len > 0.05 {
            alignment = vdot(vnorm(forward_plane), vnorm(delta));
            if alignment < 0.05 {
                findings.push("first route marker is not in the rover forward hemisphere");
            }
        } else {
            findings.push("rover forward frame or first route delta is degenerate");
        }
    } else {
        findings.push("active FLIP pose/forward frame is unavailable");
    }

    #{ok: findings.len() == 0, findings: findings, markers: markers,
      marker_count: names.len(), rover_pose: if rover_pose == () { () } else { vec3_array(rover_pose) },
      rover_forward: if rover_forward == () { () } else { vec3_array(rover_forward) },
      forward_alignment: alignment}
}

fn route_leg(path, speed, radius, event) {
    #{ kind: "drive_to", target: route_marker_target(path),
       speed: speed, radius: radius, event: event }
}

fn _surface_route_events() {
    [
        "griffin_ramp_approach_reached",
        "griffin_ramp_exit_reached",
        "griffin_waypoint_1_reached",
        "griffin_transit_1_reached",
        "griffin_transit_2_reached",
        "griffin_transit_3_reached",
        "griffin_transit_4_reached",
        "griffin_transit_5_reached",
        "griffin_transit_6_reached",
        "griffin_waypoint_2_reached",
        "griffin_base_arc_1_reached",
        "griffin_base_arc_2_reached",
        "griffin_base_approach_reached",
        "griffin_base_final_reached",
        "griffin_base_site_reached"
    ]
}

/// The explicit Griffin landing-demo route: first cross the top deck to the
/// selected ramp approach, clear the ramp, then reach the survey gates and
/// base site.  The first two legs are a physical egress phase; they are kept
/// separate so the mission can prove surface support before survey torque.
/// Marker poses and command limits are authored in SysML and the scene; they
/// are not duplicated here.  Event labels remain executable verdict vocabulary
/// so structured mission evidence is stable when route numbers change.
fn surface_route() {
    let preflight = surface_route_preflight();
    if preflight.ok != true {
        let findings_text = "";
        for finding in preflight.findings {
            if findings_text != "" { findings_text += "; "; }
            findings_text += finding;
        }
        throw("Griffin surface route preflight failed: " + findings_text);
    }
    let names = griffin_spec::surface_route_marker_names();
    let speeds = griffin_spec::surface_route_speed_mps();
    let radii = griffin_spec::surface_route_arrival_radius_m();
    let events = _surface_route_events();
    if names.len() == 0 || speeds.len() != names.len()
        || radii.len() != names.len() || events.len() != names.len() {
        throw("Griffin SysML surface route table has inconsistent cardinality");
    }
    let children = [];
    for i in 0..names.len() {
        children.push(route_leg("/Griffin1SurfaceOps/" + names[i],
            speeds[i], radii[i], events[i]));
    }
    #{kind: "sequence", children: children, preflight: preflight}
}

/// Claim FLIP for the mission controller and drive one route point through the
/// shared navigation law.  This is deliberately a small Twin helper rather
/// than a second autopilot implementation: `nav_command` supplies the typed
/// arrival predicate, while `modelica_waypoint` sends the target to the
/// authored Ackermann guidance law that closes the loop on live pose, yaw,
/// and yaw rate.
fn engage_route_subject() {
    let rover = find("/Griffin1SurfaceOps/FLIP");
    if rover < 0 { return #{ ok: false, error: "FLIP entity is unavailable" }; }
    // Use LunCoSim's current typed control contract.  The old
    // `PossessVessel` name was never registered in the production command
    // catalog, so the handoff looked like a rover-physics failure while the
    // actual rejection happened before FLIP received route authority.
    let result = cmd("AcquireControl", #{ target: rover, bind_camera: false });
    if result == () || result.ok != true {
        return #{ ok: false, error: "FLIP rejected mission control" };
    }
    #{ ok: true, rover: rover }
}

fn drive_route_point(rover, target, speed, radius) {
    let command = nav_command(rover, target, speed, radius);
    if command == () {
        brake(rover);
        return #{ok: false, arrived: false, error: "navigation command unavailable"};
    }
    if command.arrived || command.brake > 0.5 {
        // Modelica owns FLIP's actuator path.  The generic brake verb does
        // not clear the authored waypoint program, so use the typed stop
        // ports at the route boundary or the previous target can continue
        // driving after the task has declared arrival.
        modelica_waypoint_stop(rover);
        return #{ok: true, arrived: true};
    }
    // FLIP's authored Modelica drive law is the actuator owner. Passing its
    // waypoint through the existing typed SetPorts surface preserves the
    // requested speed as a guidance limit and lets the continuous law use the
    // live yaw/yaw-rate feedback; sending `command.throttle` as motor demand
    // would turn a route speed into an uncontrolled torque request.
    // `nav_command` uses the native Vec3 bridge. Lower it once at the typed
    // mission boundary and write the authored Modelica input ports directly;
    // this avoids the older array adapter's null-valued optional-parameter
    // path while keeping the target, speed, and radius numeric on the wire.
    let waypoint = vec3_array(target);
    if waypoint == () || waypoint.len() != 3 {
        return #{ok: false, arrived: false,
            error: "native route target could not be lowered to an array"};
    }
    let result = cmd("SetPorts", #{target: rover, writes: [
        ["program_active", 1.0],
        ["autopilot_enable", 1.0],
        ["autopilot_target_x", waypoint[0]],
        ["autopilot_target_z", waypoint[2]],
        ["autopilot_speed", speed],
        ["autopilot_radius", radius],
        ["autopilot_turn_only", 0.0],
        ["throttle", 0.0],
        ["steer", 0.0],
        ["brake", 0.0],
    ]});
    if result == () || result.ok != true {
        return #{ok: false, arrived: false,
            error: "Modelica waypoint guidance command was rejected"};
    }
    // SetPorts holds the latest target until it is replaced. The task leaf
    // applies this target at a deterministic simulation-time cadence, while
    // the authored Modelica equations compute the live throttle/steer output.
    #{ok: true, arrived: false, guidance: "modelica_waypoint"}
}

// Cross-check the authored support probe against both public geometry
// providers. `support_contacts` is the runtime's published footprint; the
// per-probe Raycast result says whether Avian has a collider in that interval,
// while TerrainHeight says whether the retained DEM has a surface there. This
// is sampled only when a route verdict is produced, not in the drive loop.
fn support_raycast_evidence(rover, pose, support_contacts) {
    if pose == () || pose.len() != 3 || support_contacts == () {
        return [];
    }
    let rotation = world_rotation_quat(rover);
    if rotation == () { return []; }
    let body = vec3_from(pose);
    let samples = [];
    for contact in support_contacts {
        let local_origin = vec3(contact.probe_origin[0], contact.probe_origin[1], contact.probe_origin[2]);
        let local_direction = vec3(contact.probe_direction[0], contact.probe_direction[1], contact.probe_direction[2]);
        let origin = body + qrot(rotation, local_origin);
        let direction = qrot(rotation, local_direction);
        let physics_hit = raycast(origin, direction, contact.probe_length_m);
        let dem_height = terrain_height(origin.x, origin.z);
        samples.push(#{origin: vec3_array(origin), direction: vec3_array(direction),
            max_distance_m: contact.probe_length_m,
            physics_raycast: physics_hit,
            dem_height_m: dem_height});
    }
    samples
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
    let physics_ok = physics != () && physics.ok != false;
    let physics_error = if physics == () {
        "physics query returned no result"
    } else if !physics_ok && physics.error != () {
        physics.error
    } else {
        ""
    };
    let velocity = if !physics_ok || physics.linear_velocity_mps == () {
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
    let terrain_y = if pose == () || pose.len() != 3 {
        ()
    } else {
        terrain_height(pose[0], pose[2])
    };
    let height_above_terrain = if terrain_y == () || pose == () || pose.len() != 3 {
        ()
    } else {
        pose[1] - terrain_y
    };
    let support_count = if !physics_ok || physics.support_contact_count == () {
        ()
    } else {
        physics.support_contact_count
    };
    // Preserve the authored/runtime support footprint in the evidence. The
    // aggregate count alone cannot distinguish a bad station datum from a
    // terrain-raycast/contact problem, while these probe origins make that
    // distinction inspectable in a deterministic verdict.
    let support_contacts = if !physics_ok || physics.support_contacts == () {
        []
    } else {
        physics.support_contacts
    };
    let support_raycast = support_raycast_evidence(rover, pose, support_contacts);
    // `wheel_contacts` is the native per-wheel snapshot: unlike the authored
    // support footprint and the secondary Twin raycast, it identifies the
    // actual Avian collider and the force/compression values used by the
    // mobility realization. Keep it in the settle report so every release or
    // route verdict carries the same typed evidence.
    let wheel_contacts = if !physics_ok || physics.wheel_contacts == () {
        []
    } else {
        physics.wheel_contacts
    };
    let support_sample_tick = if !physics_ok || physics.support_sample_tick == () {
        ()
    } else {
        physics.support_sample_tick
    };
    let now_tick = sim_tick();
    let support_fresh = support_sample_tick != () && now_tick >= support_sample_tick
        && now_tick - support_sample_tick <= 1;
    // Release is a ground-stability gate.  FLIP must have authoritative
    // support at the normalized surface datum before wheel torque is enabled;
    // a deck contact is not sufficient because the adapter has already been
    // detached and the rover is otherwise airborne.
    let ok = pose != () && speed != () && height_limit != () && speed_limit != ()
        && support_count != () && support_count > 0
        && support_fresh
        && pose[1] <= height_limit && speed.abs() <= speed_limit;
    #{ok: ok,
      pose: pose, speed: speed, height_limit_m: height_limit,
      speed_limit_mps: speed_limit, support_footprint_count: if !physics_ok { () } else { physics.support_footprint_count },
      support_contact_count: support_count, support_sample_tick: support_sample_tick,
      support_contacts: support_contacts, support_raycast: support_raycast,
      wheel_contacts: wheel_contacts,
      support_fresh: support_fresh, physics_query_ok: physics_ok,
      physics_query_error: physics_error, terrain_height_m: terrain_y,
      height_above_terrain_m: height_above_terrain}
}

// The release-settle predicate is a diagnostic gate, not a force loop. A
// free-body rover can remain unsupported for several seconds while it drops
// from the deck; running two JSON-producing queries on every fixed tick during
// that interval needlessly competes with the physics worker. Sample it at a
// deterministic six-tick cadence (10 Hz at the authored 60 Hz clock) and keep
// the last probe tick in the task's persistent state. A failed probe simply
// leaves the wait active; the watchdog still owns the terminal timeout.
fn rover_route_settle_ready(rover) {
    rover_route_settle_report(rover).ok
}

// The generic physics query intentionally reports velocities and support, not
// body orientation. Keep the deployment evidence structured by sampling the
// two physical ramp bodies through the native pose bridge at the same route
// observation point. This makes a failed egress distinguish an uncommanded
// hinge from a rover/contact failure without scraping log text.
fn physical_ramp_runtime_pose_evidence() {
    let records = [];
    for side in ["Port", "Starboard"] {
        let path = "/Griffin1SurfaceOps/Lander/EgressRamp" + side;
        let id = find(path);
        let pose = if id == () || id < 0 { () } else { world_pos3(id) };
        let rotation = if id == () || id < 0 { () } else { world_rotation_quat(id) };
        records.push(#{side: side, path: path, entity: id,
            pose: if pose == () { () } else { vec3_array(pose) },
            rotation: if rotation == () { () } else { quat_array(rotation) }});
    }
    records
}

// The joint ports are sampled only at a failure boundary.  This keeps the
// normal mission path allocation-free while recording both the commanded
// hinge angle and the solver-produced angle when a ramp/contact fault occurs.
fn physical_ramp_joint_evidence() {
    let records = [];
    for side in ["Port", "Starboard"] {
        let path = "/Griffin1SurfaceOps/Lander/RampHinge" + side;
        let id = find(path);
        let snapshot = if id == () || id < 0 { () }
            else { query("ReadPorts", #{api_id: id}) };
        let selected = [];
        if snapshot != () && snapshot.ports != () {
            for port in snapshot.ports {
                if port.name == "angle" { selected.push(port); }
            }
        }
        records.push(#{side: side, path: path, entity: id, angle_ports: selected});
    }
    records
}

// Capture the authored egress apron and the native wheel-contact snapshot at
// the ramp-exit boundary. The composed USD query proves the source-backed
// geometry/collision contract; the physics query proves that FLIP actually
// crossed that collider. This is sampled once at the mission boundary, not
// from the fixed-step steering loop.
fn egress_apron_runtime_evidence(rover) {
    let path = "/Griffin1SurfaceOps/EgressApron";
    let apron = query("QueryUsdPrim", #{
        path: path,
        attrs: ["size", "xformOp:scale", "xformOp:translate",
            "physics:collisionEnabled", "lunco:requirement",
            "lunco:source_status", "lunco:egress:surfaceY"],
        schemas: true,
        collision_bounds: true
    });
    let physics = query("QueryPhysicsState", #{id: rover});
    let wheel_contacts = if physics == () || physics.wheel_contacts == () {
        []
    } else {
        physics.wheel_contacts
    };
    let apron_contacts = [];
    for contact in wheel_contacts {
        if contact.hit_usd_prim_path_available == true
            && contact.hit_usd_prim_path == path
            && contact.contact_valid == true {
            apron_contacts.push(contact);
        }
    }

    let expected_center = [
        griffin_spec::egress_apron_center_x_m(),
        griffin_spec::egress_apron_center_y_m(),
        griffin_spec::egress_apron_center_z_m(),
    ];
    let expected_half_extents = [
        griffin_spec::egress_apron_length_m() * 0.5,
        griffin_spec::egress_apron_thickness_m() * 0.5,
        griffin_spec::egress_apron_width_m() * 0.5,
    ];
    let bounds = if apron == () { () } else { apron.collision_bounds };
    let bounds_ok = bounds != () && bounds.center != ()
        && bounds.half_extents != ()
        && bounds.center.len() == 3 && bounds.half_extents.len() == 3;
    let dimensions_match = if !bounds_ok { false } else {
        (bounds.center[0] - expected_center[0]).abs() <= 0.01
        && (bounds.center[1] - expected_center[1]).abs() <= 0.01
        && (bounds.center[2] - expected_center[2]).abs() <= 0.01
        && (bounds.half_extents[0] - expected_half_extents[0]).abs() <= 0.01
        && (bounds.half_extents[1] - expected_half_extents[1]).abs() <= 0.01
        && (bounds.half_extents[2] - expected_half_extents[2]).abs() <= 0.01
    };
    let geometry_ok = apron != () && apron.path == path
        && apron.type_name == "Cube"
        && apron.attrs["physics:collisionEnabled"] == true
        && apron.attrs["lunco:requirement"] == "GR-035"
        && apron.api_schemas != ()
        && dimensions_match;
    #{ok: geometry_ok && apron_contacts.len() > 0,
      path: path,
      requirement: "GR-035",
      source: griffin_spec::egress_apron_source(),
      rationale: griffin_spec::egress_apron_rationale(),
      authored_geometry: apron,
      collision_bounds: bounds,
      expected_center_m: expected_center,
      expected_half_extents_m: expected_half_extents,
      dimensions_match: dimensions_match,
      wheel_contacts: wheel_contacts,
      apron_wheel_contacts: apron_contacts,
      apron_contact_count: apron_contacts.len(),
      physics_query_ok: physics != () && physics.ok != false}
}

// Read the authored guidance boundary only when a route verdict is produced.
// Keeping this out of the fixed-step loop preserves the bounded command path,
// while the selected ports make a steering failure distinguishable between
// (a) a stale target/pose wire, (b) a guidance sign, and (c) a wheel output or
// physics convention issue.
fn route_guidance_evidence(rover) {
    let snapshot = query("ReadPorts", #{api_id: rover});
    if snapshot == () || snapshot.ports == () { return []; }
    let selected = [];
    for port in snapshot.ports {
        if port.name == "program_active" || port.name == "autopilot_enable"
            || port.name == "autopilot_target_x" || port.name == "autopilot_target_z"
            || port.name == "autopilot_position_x" || port.name == "autopilot_position_z"
            || port.name == "autopilot_yaw" || port.name == "autopilot_yaw_rate"
            || port.name == "autopilot_speed" || port.name == "autopilot_radius"
            || port.name == "guidance_heading_error" || port.name == "guidance_throttle"
            || port.name == "guidance_steer" || port.name == "drive_left"
            || port.name == "drive_right" || port.name == "heading_fl"
            || port.name == "heading_fr" {
            selected.push(port);
        }
    }
    selected
}

// A failed task leaf can terminate its task tree before a nested mission
// event hook is scheduled. Emit the machine-readable verdict at the point of
// observation, then emit the ordinary event as a trace edge. This keeps a
// physical route failure from becoming a NO-VERDICT run.
fn report_route_failure(id, error, path, evidence) {
    let source = sysml_requirements::source();
    if source == () || source.ok != true { return; }
    let failure = #{id: id, component: "rover",
        requirement: "Griffin1Requirements::gr004",
        verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations",
        kind: "route", path: path, actual: evidence,
        expected: "route reaches the authored target", ok: false, error: error};
    report_structured_verdict(#{ok: false,
        verification: "Griffin1Requirements::Verify_GriffinSurfaceOperations",
        requirement_count: 1, source_revision: source.source_revision_hex,
        source_files: source.source_files, results: [failure], failures: [failure],
        metrics: #{route_failure: evidence}},
        "GRIFFIN SURFACE OPS", "GRIFFIN_SURFACE_OPS");
}

fn report_route_stall(rover, target, pose, distance, command_updates) {
    let sample = rover_route_settle_report(rover);
    let lander = find("/Griffin1SurfaceOps/Lander");
    let lander_pose = if lander == () || lander < 0 { () } else { world_pos3(lander) };
    let lander_physics = if lander == () || lander < 0 { () }
        else { query("QueryPhysicsState", #{id: lander}) };
    let evidence = #{
        kind: "route_stall",
        target: target,
        pose: pose,
        distance_m: distance,
        steering_mode: griffin_spec::route_steering_mode(),
        command_updates: command_updates,
        sim_tick: sim_tick(),
        elapsed_s: elapsed_seconds(),
        physics_sample: sample,
        guidance_ports: route_guidance_evidence(rover),
        physical_ramps: physical_ramp_runtime_pose_evidence(),
        physical_ramp_joints: physical_ramp_joint_evidence(),
        lander_pose: if lander_pose == () { () } else { vec3_array(lander_pose) },
        lander_physics: lander_physics
    };
    print("[griffin] surface route stalled before target="
        + vec3_array(target) + " pose=" + vec3_array(pose)
        + " distance=" + distance
        + " support=" + sample.support_contact_count
        + " height_above_terrain=" + sample.height_above_terrain_m);
    // Carry the actual route observation in the event value. The scenario's
    // generic verdict then records target, pose, support, and steering policy
    // as structured evidence instead of reducing the failure to a comment
    // string or a phase name.
    report_route_failure("GR-004-route-stall", "route made no progress before the authored target",
        usd_path(rover), evidence);
    emit("griffin_surface_route_stalled", evidence);
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
fn _surface_route_leg_task(rover, leg, stall_timeout) {
    let target = leg.target;
    let target_speed = leg.speed;
    let arrival_radius = leg.radius;
    let event = leg.event;
    seq([
        once(|m| {
            this.route_last_distance = ();
            this.route_progress_time = elapsed_seconds();
            this.route_next_command_at = ();
            if this.route_started != true {
                this.route_started = true;
                emit("griffin_surface_route_started");
                print("[griffin] surface route started; first target=" + target);
            }
            true
        }),
        step(|m| {
            // `step` is the supported native task node. Keep the route's
            // source-owned command cadence here so policy remains at 10 Hz
            // while the generic task kernel advances at the simulation rate.
            let now = elapsed_seconds();
            if this.route_next_command_at != () && now < this.route_next_command_at {
                return;
            }
            this.route_next_command_at = now + 1.0 / route_command_rate_hz();
            this.route_command_updates += 1;
            let command = griffin_surface_ops::drive_route_point(rover, target, target_speed, arrival_radius);
            if command == () || command.ok != true {
                if this.route_control_error != true {
                    this.route_control_error = true;
                    let detail = if command == () { "navigation command unavailable" } else { command.error };
                    let evidence = #{
                        kind: "route_control",
                        error: detail,
                        target: target,
                        steering_mode: griffin_spec::route_steering_mode(),
                        command_updates: this.route_command_updates,
                        sim_tick: sim_tick(),
                        elapsed_s: elapsed_seconds()
                    };
                    print("[griffin] surface route control failed: " + detail);
                    report_route_failure("GR-004-route-control", detail,
                        usd_path(rover), evidence);
                    emit("griffin_surface_route_control_failed", evidence);
                }
                return false;
            }
            if command.arrived { return true; }

            // Sample the physical egress at the same deterministic cadence as
            // route commands.  This is intentionally a bounded observation
            // query rather than a second controller: it identifies whether
            // lateral drift starts on the deck or at the ramp transition.
            if this.route_command_updates % 10 == 0 {
                let trace_pose = world_pos3(rover);
                let trace_physics = query("QueryPhysicsState", #{id: rover});
                let trace_speed = ();
                if trace_physics != () && trace_physics.linear_velocity_mps != ()
                    && trace_physics.linear_velocity_mps.len() == 3 {
                    let trace_velocity = trace_physics.linear_velocity_mps;
                    trace_speed = (trace_velocity[0] * trace_velocity[0]
                        + trace_velocity[2] * trace_velocity[2]).sqrt();
                }
                let trace_pose_text = "()";
                if trace_pose != () { trace_pose_text = vec3_array(trace_pose); }
                let trace_speed_text = "()";
                if trace_speed != () { trace_speed_text = trace_speed.to_string(); }
                let trace_support_text = "()";
                if trace_physics != () && trace_physics.support_contact_count != () {
                    trace_support_text = trace_physics.support_contact_count.to_string();
                }
                let trace_steer_text = "()";
                let trace_heading_text = "()";
                let trace_forward_text = "()";
                let trace_tire_text = "()";
                let trace_tire_fr_text = "()";
                let trace_tire_rl_text = "()";
                let trace_tire_rr_text = "()";
                let trace_normal_text = "()";
                let trace_wheel_rotation_text = "()";
                let trace_body_mode_text = "()";
                let trace_velocity_text = "()";
                let trace_sleeping_text = "()";
                let trace_lander_up_text = "()";
                let trace_steer = get(rover, "guidance_steer");
                let trace_heading = get(rover, "heading_fl");
                let trace_forward = world_forward3(rover);
                let trace_lander = find("/Griffin1SurfaceOps/Lander");
                let trace_lander_up = if trace_lander == () || trace_lander < 0 {
                    ()
                } else {
                    world_up3(trace_lander)
                };
                let trace_wheel = find("/Griffin1SurfaceOps/FLIP/Suspension_FL/Wheel_FL");
                let trace_wheel_fr = find("/Griffin1SurfaceOps/FLIP/Suspension_FR/Wheel_FR");
                let trace_wheel_rl = find("/Griffin1SurfaceOps/FLIP/Suspension_RL/Wheel_RL");
                let trace_wheel_rr = find("/Griffin1SurfaceOps/FLIP/Suspension_RR/Wheel_RR");
                let trace_tire = if trace_wheel == () || trace_wheel < 0 {
                    ()
                } else {
                    get(trace_wheel, "WheelRaycast.tire_force")
                };
                let trace_normal = if trace_wheel == () || trace_wheel < 0 {
                    ()
                } else {
                    get(trace_wheel, "WheelRaycast.last_normal_force")
                };
                let trace_tire_fr = if trace_wheel_fr == () || trace_wheel_fr < 0 {
                    ()
                } else {
                    get(trace_wheel_fr, "WheelRaycast.tire_force")
                };
                let trace_tire_rl = if trace_wheel_rl == () || trace_wheel_rl < 0 {
                    ()
                } else {
                    get(trace_wheel_rl, "WheelRaycast.tire_force")
                };
                let trace_tire_rr = if trace_wheel_rr == () || trace_wheel_rr < 0 {
                    ()
                } else {
                    get(trace_wheel_rr, "WheelRaycast.tire_force")
                };
                let trace_wheel_rotation = if trace_wheel == () || trace_wheel < 0 {
                    ()
                } else {
                    world_rotation_quat(trace_wheel)
                };
                if trace_steer != () { trace_steer_text = trace_steer.to_string(); }
                if trace_heading != () { trace_heading_text = trace_heading.to_string(); }
                if trace_forward != () { trace_forward_text = vec3_array(trace_forward); }
                if trace_tire != () { trace_tire_text = trace_tire.to_string(); }
                if trace_tire_fr != () { trace_tire_fr_text = trace_tire_fr.to_string(); }
                if trace_tire_rl != () { trace_tire_rl_text = trace_tire_rl.to_string(); }
                if trace_tire_rr != () { trace_tire_rr_text = trace_tire_rr.to_string(); }
                if trace_normal != () { trace_normal_text = trace_normal.to_string(); }
                if trace_wheel_rotation != () {
                    trace_wheel_rotation_text = quat_array(trace_wheel_rotation);
                }
                if trace_physics != () && trace_physics.body_mode != () {
                    trace_body_mode_text = trace_physics.body_mode.to_string();
                }
                if trace_physics != () && trace_physics.linear_velocity_mps != () {
                    trace_velocity_text = trace_physics.linear_velocity_mps.to_string();
                }
                if trace_physics != () && trace_physics.sleeping != () {
                    trace_sleeping_text = trace_physics.sleeping.to_string();
                }
                if trace_lander_up != () {
                    trace_lander_up_text = vec3_array(trace_lander_up);
                }
                let trace_line = "[griffin] egress trace target=" + vec3_array(target);
                trace_line += " pose=" + trace_pose_text;
                trace_line += " speed=" + trace_speed_text;
                trace_line += " support=" + trace_support_text;
                trace_line += " steer=" + trace_steer_text;
                trace_line += " heading_fl=" + trace_heading_text;
                trace_line += " forward=" + trace_forward_text;
                trace_line += " tire_fl=" + trace_tire_text;
                trace_line += " tire_fr=" + trace_tire_fr_text;
                trace_line += " tire_rl=" + trace_tire_rl_text;
                trace_line += " tire_rr=" + trace_tire_rr_text;
                trace_line += " normal_fl=" + trace_normal_text;
                trace_line += " wheel_rot_fl=" + trace_wheel_rotation_text;
                trace_line += " body_mode=" + trace_body_mode_text;
                trace_line += " velocity=" + trace_velocity_text;
                trace_line += " sleeping=" + trace_sleeping_text;
                trace_line += " lander_up=" + trace_lander_up_text;
                print(trace_line);
            }

            let pose = world_pos3(rover);
            if pose != () {
                let delta = vsub(pose, vec3_from(target));
                let horizontal_distance = vlen(vec3(delta.x, 0.0, delta.z));
                if this.route_last_distance == ()
                    || horizontal_distance < this.route_last_distance - 0.02 {
                    this.route_last_distance = horizontal_distance;
                    this.route_progress_time = now;
                } else if this.route_progress_time != ()
                    && now - this.route_progress_time >= stall_timeout {
                    this.route_control_error = true;
                    report_route_stall(rover, target, pose, horizontal_distance,
                        this.route_command_updates);
                    return false;
                }
            }
            // The authored Modelica drivetrain consumes the guidance ports
            // above and owns the physical actuator output. Do not call the
            // legacy manual `drive` helper here: that would issue a second
            // SetPorts command to the same control surface and could
            // overwrite or reject the typed guidance write.
            false
        }, |m| this.route_control_error == true || arrived(rover, target, arrival_radius)),
        // A control fault makes the step terminal only so this explicit check
        // can propagate Failure through the native task tree.  It must never
        // be interpreted as arrival or allow the following route leg to run.
        check(|m| this.route_control_error != true),
        once(|m| {
            if event == "griffin_ramp_exit_reached" {
                this.egress_apron_evidence = griffin_surface_ops::egress_apron_runtime_evidence(rover);
            }
            emit(event);
            true
        })
    ])
}

fn _surface_route_task_range(rover, first, last) {
    // Keep one source of route geometry: the returned sequence is also the
    // machine-readable route consumed by tools and review scripts.
    let legs = surface_route().children;
    // Resolve SysML policy once while lowering the route. Calling the public
    // source-backed accessor from a fixed-step leaf would re-read and resolve
    // the complete Twin source set at every command cadence, turning a bounded
    // control loop into an unbounded validation workload. Missing policy is a
    // construction error, never a runtime default.
    let stall_timeout = route_stall_timeout_s();
    if stall_timeout == () {
        throw("surface route stall timeout is missing from SysML");
    }
    let steps = [];
    let index = 0;
    for leg in legs {
        if index >= first && index < last {
            steps.push(_surface_route_leg_task(rover, leg, stall_timeout));
        }
        index += 1;
    }
    seq(steps)
}

/// Run only the two authored physical egress legs.  The mission inserts its
/// support/velocity gate after this phase before starting survey navigation.
fn surface_egress_task(rover) {
    _surface_route_task_range(rover, 0, 2)
}

/// Run the survey and base-site legs after physical egress is proven.
fn surface_route_task(rover) {
    let legs = surface_route().children;
    _surface_route_task_range(rover, 2, legs.len())
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
