// Production pilot regression: take off, tap the semantic pitch intent, then
// hold thrust while observing recovery. The engine study owns flight limits.
fn simulation_dependencies(me, ctx) {
    let deps = griffin_surface_ops::landing_stability_dependencies();
    deps.modelica_entities.push(find_path("/Griffin1SurfaceOps/Lander/AttitudePropulsion"));
    deps.entity_reads.push(find_path("/Griffin1SurfaceOps/Lander/AttitudePropulsion"));
    for name in griffin_spec::ramp_root_joint_names() + griffin_spec::ramp_intermediate_joint_names() {
        deps.entity_reads.push(find_path("/Griffin1SurfaceOps/Lander/" + name));
    }
    deps.query_reads.push("ReadPortsBatch");
    deps.entity_writes = [find_path("/Griffin1SurfaceOps/Lander"),
        find_path("/Griffin1SurfaceOps/Lander/GNC")];
    if ctx["isolate_leg_joints"] == true {
        for path in _leg_joint_paths() {
            deps.entity_reads.push(find_path(path));
            deps.entity_writes.push(find_path(path));
        }
    }
    deps
}

fn _leg_joint_paths() {
    let paths=[];
    for name in griffin_spec::landing_leg_names() {
        paths.push("/Griffin1SurfaceOps/Lander/"+name+"_Spring");
    }
    paths
}

fn _isolate_leg_joints() {
    let paths=_leg_joint_paths();
    if paths.len()!=4 {throw("pilot isolation requires the four sourced leg identities");}
    let snapshot=query("QueryUsdPrims",#{paths:paths,rels:["physics:body0","physics:body1"]});
    if snapshot==() || snapshot.error!=() || snapshot.records==() || snapshot.records.len()!=4 {
        throw("pilot leg joint isolation topology unavailable: "+snapshot);
    }
    let targets=[];
    let names=griffin_spec::landing_leg_names();
    for index in 0..4 {
        let record=snapshot.records[index];
        let target=find_path(paths[index]);
        if record.type_name!="PhysicsPrismaticJoint" || record.active!=true
            || record.relationships==()
            || record.relationships["physics:body0"]!=["/Griffin1SurfaceOps/Lander"]
            || record.relationships["physics:body1"]!=["/Griffin1SurfaceOps/Lander/"+names[index]]
            || target==() || target<0 {
            throw("pilot leg isolation joint contract invalid: "+record);
        }
        targets.push(target);
    }
    let results=[];
    for target in targets {
        let result=cmd("DetachJoint",#{target:target,intent:"Interactive"});
        if result==() || result.ok!=true {throw("pilot leg isolation detach rejected: "+result);}
        results.push(result);
    }
    print("GRIFFIN_PILOT_LEG_ISOLATION "+#{sim_tick:sim_tick(),paths:paths,results:results});
}

fn _study(name) {
    let value = griffin_spec::_typed_model_number(
        "GriffinPropulsionRequirements::GriffinEngineControlStudy::" + name);
    if value == () || !value.is_finite() || value <= 0.0 {
        throw("missing pilot attitude study datum: " + name);
    }
    value
}

fn _elapsed(tick) {
    let clock = clock_snapshot();
    if clock.fixed_dt_s == () || !clock.fixed_dt_s.is_finite() || clock.fixed_dt_s <= 0.0 {
        throw("pilot attitude test has no admitted fixed clock");
    }
    (sim_tick() - tick).to_float() * clock.fixed_dt_s
}

fn _intent(target, name, held) {
    let result = cmd("SimulateIntent", #{target: target, intent: name, held: held});
    if result == () || result.ok != true {throw("pilot intent rejected: " + result);}
}

fn _values(target, names) {
    let values = [];
    for name in names {
        let value = get(target, name);
        values.push(value);
    }
    values
}

fn _diagnostic(lander) {
    let physics = query("QueryPhysicsState", #{id: lander});
    let hinges = griffin_surface_ops::physical_ramp_hinge_report();
    if physics == () || physics.physics_state_ready != true
        || physics.angular_velocity_radps == () || physics.mass_kg==()
        || !physics.mass_kg.is_finite() || physics.mass_kg<=0.0
        || hinges == () || hinges.ok != true {
        return #{ok: false, error: "pilot attitude physical or hinge observation unavailable",
            physics: physics, hinges: hinges};
    }
    let hinge_observations=[];
    for hinge in hinges.hinges {
        hinge_observations.push(#{name:hinge.name,
            drive_target_rad:hinge.drive_target_rad,
            measured_angle_rad:hinge.measured_angle_rad,
            measured_angular_speed_rad_per_s:hinge.measured_angular_speed_rad_per_s});
    }
    let rcs = find_path("/Griffin1SurfaceOps/Lander/AttitudePropulsion");
    let observation = #{ok: true, sim_tick: sim_tick(),
        rotation_xyzw: world_rotation(lander),
        angular_velocity_navigation_rad_s: physics.angular_velocity_radps,
        mass_kg:physics.mass_kg,
        center_of_mass_body_m:physics.center_of_mass_m,
        inertia_principal_kgm2:physics.inertia_principal_kgm2,
        controller_inertia_kgm2:_values(lander,["controller_inertia_xx","controller_inertia_yy","controller_inertia_zz"]),
        gyro_body_rad_s: _values(lander, ["gyro_x", "gyro_y", "gyro_z"]),
        error_body: _values(lander, ["attitude_error_x", "attitude_error_y", "attitude_error_z"]),
        requested_torque_nm: _values(lander, ["torque_x", "torque_y", "torque_z"]),
        commanded_tilt_rad: _values(lander, ["desired_tilt_x", "desired_tilt_z"]),
        pilot_inputs: _values(lander, ["piloted", "external_throttle", "pitch"]),
        pitch_rcs_thrust_n: _values(rcs, ["pitch_pos_a_thrust_n", "pitch_pos_b_thrust_n",
            "pitch_neg_a_thrust_n", "pitch_neg_b_thrust_n"]),
        roll_yaw_rcs_thrust_n:_values(rcs,["roll_pos_a_thrust_n","roll_pos_b_thrust_n",
            "roll_neg_a_thrust_n","roll_neg_b_thrust_n","yaw_pos_a_thrust_n",
            "yaw_pos_b_thrust_n","yaw_neg_a_thrust_n","yaw_neg_b_thrust_n"]),
        main_engine_thrust_n:_values(find_path("/Griffin1SurfaceOps/Lander/MainPropulsion"),
            ["engine01_thrust_n","engine02_thrust_n","engine03_thrust_n","engine04_thrust_n",
             "engine05_thrust_n","engine06_thrust_n","engine07_thrust_n"]),
        leg_rate_mps: _values(lander, ["leg_velocity_px", "leg_velocity_nx",
            "leg_velocity_pz", "leg_velocity_nz"]),
        hinges: #{ok:true,sim_tick:hinges.sim_tick,hinges:hinge_observations}};
    for name in ["gyro_body_rad_s", "error_body", "requested_torque_nm",
        "commanded_tilt_rad", "pilot_inputs", "pitch_rcs_thrust_n", "leg_rate_mps",
        "roll_yaw_rcs_thrust_n","main_engine_thrust_n","controller_inertia_kgm2",
        "center_of_mass_body_m","inertia_principal_kgm2"] {
        for value in observation[name] {
            if value == () || !value.is_finite() {
                observation.ok = false;
                observation.error = "pilot attitude observation unavailable: " + name;
                return observation;
            }
        }
    }
    observation
}

fn on_start(me, ctx) {
    let isolate=ctx["isolate_leg_joints"];
    if isolate!=() && type_of(isolate)!="bool" {throw("isolate_leg_joints must be a boolean");}
    this.isolate_leg_joints=isolate==true;
    this.verdict_category=if this.isolate_leg_joints {"GRIFFIN_PILOT_LEG_ISOLATION"} else {"GRIFFIN_PILOT_ATTITUDE"};
    print("GRIFFIN_PILOT_TRIAL_MODE "+#{isolate_leg_joints:this.isolate_leg_joints});
    this.lander = find_path("/Griffin1SurfaceOps/Lander");
    this.phase = "descent_setup";
    this.start_tick = sim_tick();
    this.phase_tick = sim_tick();
    this.done = false;
    this.minimum_up = 1.0;
    this.maximum_rate = 0.0;
    this.maximum_lift = 0.0;
    this.maximum_tap_tilt = 0.0;
    this.pitch_released = false;
    this.ramp_peak_error_rad = 0.0;
    this.ramp_peak_rate_rad_s = 0.0;
    this.horizon_s = _study("pilotAttitudeRecoveryDurationS");
    this.tap_duration_s = _study("pilotPitchTapDurationS");
}

fn _finish(state, sample, error) {
    _intent(state.lander, "forward", false);
    _intent(state.lander, "thrust", false);
    print("GRIFFIN_PILOT_ATTITUDE_METRICS " + #{minimum_upright_y: state.minimum_up,
        maximum_rate_rad_s: state.maximum_rate, maximum_lift_m: state.maximum_lift,
        maximum_tap_tilt_rad: state.maximum_tap_tilt,
        ramp_peak_error_rad: state.ramp_peak_error_rad,
        ramp_peak_rate_rad_s: state.ramp_peak_rate_rad_s,
        final_sample: sample, terminal_error: error});
    report_verdict([
        t_true(error == "", error),
        t_true(state.pitch_released, "pitch tap was not released"),
        t_true(state.maximum_tap_tilt > 0.0, "semantic pitch tap did not reach controller"),
        t_true(state.maximum_lift >= _study("minimumSustainedLiftM"), "pilot never lifted off"),
        t_true(state.minimum_up >= _study("minimumBurnUprightY"),
            "pilot tap exceeded study tilt envelope: " + state.minimum_up),
        t_true(state.maximum_rate <= _study("maximumBurnAngularSpeedRadS"),
            "pilot tap exceeded study rate envelope: " + state.maximum_rate),
        t_true(state.ramp_peak_error_rad <= griffin_spec::physical_ramp_hinge_settle_angle_tolerance_rad(),
            "flight latch allowed ramp stow angle drift: " + state.ramp_peak_error_rad),
        t_true(state.ramp_peak_rate_rad_s <= griffin_spec::physical_ramp_hinge_settle_speed_tolerance_rad_per_s(),
            "flight latch allowed ramp relative motion: " + state.ramp_peak_rate_rad_s),
        t_true(sample.upright_axis_y >= _study("minimumBurnUprightY"),
            "pilot did not recover upright")
    ], "GRIFFIN PILOT ATTITUDE", state.verdict_category);
}

fn on_tick(me, ctx) {
    if this.done {return;}
    try {
    if this.phase == "descent_setup" {
        let mass = griffin_surface_ops::guidance_assembly_mass_report();
        if mass != () && mass.ready == false {
            if _elapsed(this.start_tick) >= _study("touchdownTimeoutS") {
                throw("pilot descent mass propagation timed out: " + mass);
            }
            return;
        }
        if mass == () || mass.ok != true || mass.ready != true {
            throw("pilot descent assembly mass contract unavailable: " + mass);
        }
        let arm = griffin_surface_ops::arm_descent_guidance();
        if arm == () || arm.ok != true {throw("pilot descent guidance arm rejected: " + arm);}
        print("GRIFFIN_PILOT_DESCENT_SETUP " + #{mass:mass,arm:arm});
        this.phase = "landing";
        this.start_tick = sim_tick();
        return;
    }
    let sample = griffin_surface_ops::landing_stability_sample();
    if sample == () || sample.ok != true {throw("pilot physical sample unavailable: " + sample);}
    if sample.touchdown == () || sample.all_legs_contact == () {
        throw("pilot landing qualification unavailable");
    }
    if this.phase == "landing" {
        if sample.touchdown < 0.999 || sample.all_legs_contact < 0.999 {
            if _elapsed(this.start_tick) > _study("touchdownTimeoutS") {
                this.done = true;
                _finish(this, sample, "no settled touchdown before pilot trial");
            }
            return;
        }
        this.rest_y = sample.position[1];
        let avatar = find_path("/Griffin1SurfaceOps/Avatar");
        let acquired = cmd("AcquireControl", #{target: this.lander, source: avatar, bind_camera: false});
        if acquired == () || acquired.ok != true {throw("pilot acquisition rejected: " + acquired);}
        this.phase = "acquiring";
        this.phase_tick = sim_tick();
        return;
    }
    if this.phase == "acquiring" {
        if sim_tick() - this.phase_tick < 2 {return;}
        _intent(this.lander, "thrust", true);
        this.phase = "liftoff";
        this.phase_tick = sim_tick();
        this.burn_tick = sim_tick();
        return;
    }
    this.minimum_up = min(this.minimum_up, sample.upright_axis_y);
    this.maximum_rate = max(this.maximum_rate, sample.angular_speed);
    this.maximum_lift = max(this.maximum_lift, sample.position[1] - this.rest_y);
    if this.phase == "liftoff" && sample.position[1] - this.rest_y >= _study("minimumSustainedLiftM") {
        if this.isolate_leg_joints {
            _isolate_leg_joints();
            this.phase="isolating_legs";
            this.phase_tick=sim_tick();
        } else {
            _intent(this.lander, "forward", true);
            this.phase = "tap";
            this.phase_tick = sim_tick();
        }
    }
    if this.phase=="isolating_legs" && sim_tick()-this.phase_tick>=2 {
        for path in _leg_joint_paths() {
            if find_path(path)>=0 {throw("pilot leg isolation solver edge was not retired: "+path);}
        }
        _intent(this.lander, "forward", true);
        this.phase = "tap";
        this.phase_tick = sim_tick();
    }
    if this.phase == "tap" && _elapsed(this.phase_tick) >= this.tap_duration_s {
        _intent(this.lander, "forward", false);
        this.pitch_released = true;
        this.phase = "recovery";
        this.phase_tick = sim_tick();
    }
    // Tests observe at fixed cadence; this is verdict data, not a control law.
    if (sim_tick() - this.burn_tick) % 6 == 0 {
        let observation = _diagnostic(this.lander);
        if observation.ok != true {
            print("GRIFFIN_PILOT_ATTITUDE_OBSERVATION_ERROR " + observation);
            this.done = true;
            _finish(this, sample, observation.error);
            return;
        }
        for tilt in observation.commanded_tilt_rad {
            this.maximum_tap_tilt = max(this.maximum_tap_tilt, tilt.abs());
        }
        for hinge in observation.hinges.hinges {
            this.ramp_peak_error_rad = max(this.ramp_peak_error_rad,
                griffin_surface_ops::_ramp_angle_error_rad(hinge.measured_angle_rad, hinge.drive_target_rad).abs());
            this.ramp_peak_rate_rad_s = max(this.ramp_peak_rate_rad_s,
                hinge.measured_angular_speed_rad_per_s.abs());
        }
        print("GRIFFIN_PILOT_ATTITUDE_SAMPLE " + #{phase: this.phase,
            physical: sample, diagnostic: observation});
    }
    if sample.upright_axis_y <= 0.0 {
        this.done = true;
        _finish(this, sample, "pilot attitude crossed horizontal under held thrust");
        return;
    }
    if this.phase == "recovery" && _elapsed(this.phase_tick) >= this.horizon_s {
        this.done = true;
        _finish(this, sample, "");
    } else if this.phase == "liftoff" && _elapsed(this.phase_tick) >= this.horizon_s {
        this.done = true;
        _finish(this, sample, "pilot liftoff timed out");
    }
    } catch (error) {
        this.done = true;
        let stops = [];
        if this.phase != "descent_setup" && this.phase != "landing" && this.phase != "acquiring" {
            for name in ["forward", "thrust"] {
                stops.push(cmd("SimulateIntent", #{target: this.lander, intent: name, held: false}));
            }
        }
        print("GRIFFIN_PILOT_ATTITUDE_OBSERVATION_ERROR " + #{error: error, stops: stops});
        report_verdict([t_true(false, "pilot observation or command failed: " + error)],
            "GRIFFIN PILOT ATTITUDE", this.verdict_category);
    }
}

fn on_stop(me, ctx) {
    if this.lander != () && this.lander >= 0 {
        _intent(this.lander, "forward", false);
        _intent(this.lander, "thrust", false);
    }
}
