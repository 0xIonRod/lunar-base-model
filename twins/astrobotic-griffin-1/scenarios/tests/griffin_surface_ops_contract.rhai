// Twin-owned fixed-clock landing-stability test.
//
// The scene retains the production mission, while this separate Rhai observer
// samples the lander for the SysML stability horizon after touchdown. A verification
// binding selects the stability channel and a Twin-local harness compares the
// resulting metrics from two fresh processes. SysML owns every limit; Rhai
// owns the observations and verdict.

const ROOT = "/Griffin1SurfaceOps";

fn simulation_dependencies(me, ctx) {
    let lander = find_path(ROOT + "/Lander");
    let gnc = find_path(ROOT + "/Lander/GNC");
    let propulsion = find_path(ROOT + "/Lander/MainPropulsion");
    let altimeter = find_path(ROOT + "/Lander/Altimeter/Model");
    #{modelica_entities: [lander, gnc, propulsion, altimeter],
      entity_reads: [lander, gnc, propulsion, altimeter], entity_writes: [],
      query_reads: ["AnalyzeSysml", "ValidateSysml", "ReadActiveTwinContract",
        "QueryUsdPrim", "QueryPhysicsState"], required_inputs: []}
}

fn finite_number(value) {
    value != () && value.is_finite()
}

fn on_start(me, ctx) {
    // A qualified touchdown can be shorter than the ten-tick sample cadence.
    // Latch the native source event; the following samples still require every
    // physical stability predicate, so the event cannot create a passing run.
    subscribe_from("lander_touchdown", find_path(ROOT + "/Lander"));
    // SimTick is the shared simulation master. Fixed/virtual elapsed resources
    // also include scheduler bookkeeping while a causal participant is held,
    // so they are diagnostic clocks rather than the test horizon.
    this.clock_start = clock_snapshot();
    this.start_tick = sim_tick();
    this.touchdown_tick = ();
    this.touchdown_position = ();
    this.touchdown_seen = false;
    this.elapsed = 0.0;
    this.stability_done = false;
    this.last_sample_tick = sim_tick();
    this.sample_count = 0;
    this.total_sample_count = 0;
    this.unready_sample_count = 0;
    this.post_touchdown_unready_count = 0;
    this.finite = true;
    this.all_post_touchdown_samples_contact = true;
    this.min_upright = 1.0;
    this.max_ground = 0.0;
    this.max_angular = 0.0;
    this.max_horizontal = 0.0;
    this.minimum_position_y = 1.0e30;
    this.maximum_position_y = -1.0e30;
    this.all_four_contact_samples = 0;
    this.touchdown_samples = 0;
    this.last = #{};
    // Resolve the SysML projection once. Re-querying the full validation map
    // at 60 Hz needlessly allocates a large dynamic value and can exceed the
    // VM string budget before the first sample is taken.
    this.contract = griffin_surface_ops::landing_stability_contract();
    print("[griffin-landing-stability] waiting for composed Twin stage");
}

fn on_event(me, ctx, evt) {
    if evt.name != "lander_touchdown" || this.touchdown_seen {return;}
    let position=world_pos3(find_path(ROOT + "/Lander"));
    if position==() {return;}
    this.touchdown_seen=true;
    this.touchdown_tick=sim_tick();
    this.touchdown_position=[position.x,position.y,position.z];
    print("[griffin-landing-stability] qualified touchdown event latched at tick="
        + this.touchdown_tick.to_string());
}

fn _bind_stability_observation(ir, input_name, observation) {
    if ir == () || ir.ok != true {
        observation.path = [];
        observation.state = "invalid";
        observation.detail = "GR-036 constraint IR is unavailable";
        return observation;
    }
    let bound = sysml_requirements::scalar_constraint_observation(
        ir, input_name, observation);
    if bound.state == "invalid" {
        observation.path = bound.path;
        observation.state = "invalid";
        observation.detail = bound.detail;
        return observation;
    }
    bound
}

fn _stability_telemetry(model, ir, input_name, state, value, detail,
                        generation, sample_interval) {
    let observation = #{
        provider: "telemetry",
        state: state,
        provider_generation: generation,
        source_revision: if model == () { () } else { model.source_revision },
        document_id: (),
        document_generation: (),
        sample_interval: sample_interval,
    };
    if state == "value" { observation.value = value; }
    if detail != () { observation.detail = detail; }
    _bind_stability_observation(ir, input_name, observation)
}

fn _stability_source_literal(model, ir, input_name, attribute_name) {
    if model == () || !sysml_model_is(model) {
        return #{path: [], provider: "source_literal", state: "invalid",
            detail: "source-pinned SysML model is unavailable"};
    }
    let attribute = model.attribute(attribute_name);
    if attribute == () {
        return #{path: [], provider: "source_literal", state: "invalid",
            source_revision: model.source_revision,
            provider_generation: model.source_revision,
            detail: "GR-036 source limit is missing: " + attribute_name};
    }
    let observation = model.source_literal_observation(attribute);
    _bind_stability_observation(ir, input_name, observation)
}

fn emit_stability_verdict(me, contract, source) {
    let last_position = if me.last.position != () { me.last.position } else { [] };
    let last_upright = if me.last.upright_axis_y != () { me.last.upright_axis_y } else { 0.0 };
    let last_ground = if me.last.ground_speed != () { me.last.ground_speed } else { 0.0 };
    let last_angular = if me.last.angular_speed != () { me.last.angular_speed } else { 0.0 };
    let touchdown_observed = me.touchdown_seen;
    let all_four_legs_contact = me.last.all_legs_contact != ()
        && me.last.all_legs_contact >= 0.999
        && me.all_post_touchdown_samples_contact
        && me.post_touchdown_unready_count == 0;
    let clocks = clock_snapshot();
    let clock_tick_delta = clocks.sim_tick - me.clock_start.sim_tick;
    let post_touchdown_tick_delta = clocks.sim_tick - me.touchdown_tick;
    let simulation_elapsed_delta = clock_tick_delta.to_float() * clocks.fixed_dt_s;
    let clock_elapsed_delta = post_touchdown_tick_delta.to_float() * clocks.fixed_dt_s;
    let fixed_elapsed_delta = clocks.fixed_elapsed_s - me.clock_start.fixed_elapsed_s;
    let clock_sync_error = (clock_elapsed_delta - me.elapsed).abs();
    let metrics = #{
        horizon_s: contract.horizon_s,
        elapsed_s: me.elapsed,
        sim_tick: clocks.sim_tick,
        clock_start_sim_tick: me.clock_start.sim_tick,
        clock_tick_delta: clock_tick_delta,
        post_touchdown_tick_delta: post_touchdown_tick_delta,
        simulation_elapsed_delta_s: simulation_elapsed_delta,
        fixed_elapsed_s: clocks.fixed_elapsed_s,
        fixed_elapsed_delta_s: fixed_elapsed_delta,
        admitted_sim_elapsed_delta_s: clock_elapsed_delta,
        clock_sync_error_s: clock_sync_error,
        clock_contract_ok: clocks.clock_contract_ok,
        virtual_elapsed_s: clocks.virtual_elapsed_s,
        physics_elapsed_s: clocks.physics_elapsed_s,
        barrier_held: clocks.barrier_held,
        sample_count: me.sample_count,
        total_sample_count: me.total_sample_count,
        post_touchdown_unready_count: me.post_touchdown_unready_count,
        touchdown_tick: me.touchdown_tick,
        touchdown_position: me.touchdown_position,
        position: last_position,
        upright_axis_y: last_upright,
        ground_speed_mps: last_ground,
        angular_speed_rad_per_sec: last_angular,
        min_upright_axis_y: me.min_upright,
        max_ground_speed_mps: me.max_ground,
        max_angular_speed_rad_per_sec: me.max_angular,
        max_horizontal_drift_m: me.max_horizontal,
        minimum_reference_y_m: if me.sample_count > 0 { me.minimum_position_y } else { () },
        maximum_reference_y_m: if me.sample_count > 0 { me.maximum_position_y } else { () },
        all_four_contact_samples: me.all_four_contact_samples,
        touchdown_samples: me.touchdown_samples,
        all_post_touchdown_samples_contact: me.all_post_touchdown_samples_contact,
        finite: me.finite,
        unready_sample_count: me.unready_sample_count,
        vertical_velocity_mps: if me.last.linear_velocity_mps != ()
            && me.last.linear_velocity_mps.len() == 3 {
                me.last.linear_velocity_mps[1]
            } else { () },
        touchdown: if me.last.touchdown != () { me.last.touchdown } else { 0.0 },
        touchdown_observed: touchdown_observed,
        any_leg_contact: if me.last.any_leg_contact != () { me.last.any_leg_contact } else { () },
        all_legs_contact: if me.last.all_legs_contact != () { me.last.all_legs_contact } else { () },
        all_four_legs_contact: all_four_legs_contact,
        landing_contact: if me.last.landing_contact != () { me.last.landing_contact } else { () },
        engine_cutoff_contact: if me.last.engine_cutoff_contact != () { me.last.engine_cutoff_contact } else { () },
        source_revision: source.source_revision,
        divergence_tolerance_m: contract.divergence_tolerance_m,
        divergence_tolerance_upright: contract.divergence_tolerance_upright,
        divergence_tolerance_speed_mps: contract.divergence_tolerance_speed_mps,
        replay_tolerance_m: contract.replay_tolerance_m,
        replay_tolerance_upright: contract.replay_tolerance_upright,
        replay_tolerance_speed_mps: contract.replay_tolerance_speed_mps,
        replay_tolerance_time_s: contract.replay_tolerance_time_s
    };
    // This compact line is parsed by the Twin-local repeatability harness.
    // The full typed result remains on the generic *_EVIDENCE telemetry event.
    print("GRIFFIN_LANDING_STABILITY_METRICS " + to_json(metrics));
    let metric_state = if me.sample_count == 0 { "unavailable" }
        else if me.finite != true { "invalid" } else { "value" };
    let metric_detail = if metric_state == "unavailable" {
        "No physics samples were available during the required observation window"
    } else if metric_state == "invalid" {
        "A sampled physics value was non-finite"
    } else { () };
    let sample_available = me.sample_count > 0
        && me.post_touchdown_unready_count == 0
        && me.elapsed >= contract.horizon_s;
    let sample_state = if sample_available { "value" } else { "unavailable" };
    let source_model = sysml_requirements::model();
    let requirement = if source_model != () && sysml_model_is(source_model) {
        source_model.requirement("GriffinSimulationAccuracyRequirements::gr036")
    } else { () };
    let constraint_ir = if requirement != () {
        sysml_requirements::required_constraint_ir(
            source_model,
            requirement,
            "GriffinSimulationAccuracyRequirements::GR036_LandingStabilityWithinBounds")
    } else { () };
    let sample_interval = #{
        clock: "simulation",
        start_tick: if me.touchdown_tick != () { me.touchdown_tick } else { me.start_tick },
        end_tick: clocks.sim_tick,
    };
    let telemetry = [];
    telemetry.push(_stability_telemetry(source_model, constraint_ir,
        "telemetryFinite", metric_state, me.finite, metric_detail,
        clocks.sim_tick, sample_interval));
    telemetry.push(_stability_telemetry(source_model, constraint_ir,
        "sampleAvailable", sample_state, sample_available,
        if sample_available { () } else { "The full post-touchdown sample window is incomplete" },
        clocks.sim_tick, sample_interval));
    telemetry.push(_stability_telemetry(source_model, constraint_ir,
        "touchdownObserved", "value", touchdown_observed, (),
        clocks.sim_tick, sample_interval));
    telemetry.push(_stability_telemetry(source_model, constraint_ir,
        "allFourLegsContact", metric_state, all_four_legs_contact, metric_detail,
        clocks.sim_tick, sample_interval));
    telemetry.push(_stability_telemetry(source_model, constraint_ir,
        "minimumUprightAxisY", metric_state, me.min_upright, metric_detail,
        clocks.sim_tick, sample_interval));
    telemetry.push(_stability_source_literal(source_model, constraint_ir,
        "minimumUprightAxisYLimit",
        "GriffinSimulationAccuracyRequirements::GR036_LandingStability::landingMinimumUprightAxisY"));
    telemetry.push(_stability_telemetry(source_model, constraint_ir,
        "maximumGroundSpeedMps", metric_state, me.max_ground, metric_detail,
        clocks.sim_tick, sample_interval));
    telemetry.push(_stability_source_literal(source_model, constraint_ir,
        "maximumGroundSpeedLimitMps",
        "GriffinSimulationAccuracyRequirements::GR036_LandingStability::landingMaxGroundSpeedMps"));
    telemetry.push(_stability_telemetry(source_model, constraint_ir,
        "maximumAngularSpeedRadPerSec", metric_state, me.max_angular, metric_detail,
        clocks.sim_tick, sample_interval));
    telemetry.push(_stability_source_literal(source_model, constraint_ir,
        "maximumAngularSpeedLimitRadPerSec",
        "GriffinSimulationAccuracyRequirements::GR036_LandingStability::landingMaxAngularSpeedRadPerSec"));
    telemetry.push(_stability_telemetry(source_model, constraint_ir,
        "maximumHorizontalDriftM", metric_state, me.max_horizontal, metric_detail,
        clocks.sim_tick, sample_interval));
    telemetry.push(_stability_source_literal(source_model, constraint_ir,
        "maximumHorizontalDriftLimitM",
        "GriffinSimulationAccuracyRequirements::GR036_LandingStability::landingMaxHorizontalDriftM"));
    let check = sysml_requirements::required_constraints_check(
        "GR-036-landing-stability", "lander", "gr036",
        "Verify_GriffinLandingStability",
        "GriffinSimulationAccuracyRequirements::GR036_LandingStabilityWithinBounds",
        telemetry, "typed", 0.0);
    let report = sysml_requirements::evaluate(source, [check]);
    report.metrics = metrics;
    report.contract = contract;
    report_structured_verdict(report, "GRIFFIN LANDING STABILITY", "GRIFFIN_LANDING_STABILITY");
    me.stability_done = true;
}

fn on_tick(me, ctx) {
    if this.stability_done { return; }
    let contract = this.contract;
    if contract == () || contract.horizon_s == () || contract.horizon_s <= 0.0 {
        return;
    }

    // Sampling cadence is owned by GR-036 and measured relative to this
    // observer's fixed-tick frame. Startup admission can begin at any tick.
    let tick = sim_tick();
    // Sample in the test's own fixed-tick frame, not against the process-wide
    // tick modulus. Startup admission may begin at any absolute SimTick, but
    // a relative observer must produce the same sample set for the same
    // horizon on every fresh process.
    let relative_tick = tick - this.start_tick;
    let sample_every = contract.sample_every_n_ticks;
    if sample_every == () || sample_every <= 0 { return; }
    if relative_tick > 0 && relative_tick % sample_every == 0
        && tick != this.last_sample_tick {
        this.last_sample_tick = tick;
        let sample = griffin_surface_ops::landing_stability_sample();
        // Scene projection and the first admitted physics pose can complete on
        // different fixed updates.  A missing sample before that boundary is
        // not a non-finite physics value; leave the sample counter untouched
        // and let the explicit no-sample requirement fail if readiness never
        // arrives.  Once all fields exist, NaN/inf still fails immediately.
        let position = if sample == () { () } else { sample.position };
        let ready = sample != () && sample.ok == true
            && position != () && position.len() == 3
            && sample.upright_axis_y != () && sample.ground_speed != ()
            && sample.angular_speed != ();
        if !ready {
            if this.unready_sample_count < 3 {
                print("[griffin-landing-stability] sample unavailable: " + sample);
            }
            this.unready_sample_count += 1;
            if this.touchdown_seen {
                this.post_touchdown_unready_count += 1;
            }
            return;
        }
        this.last = sample;
        this.total_sample_count += 1;
        if !this.touchdown_seen && sample.touchdown != () && sample.touchdown >= 0.999 {
            this.touchdown_seen = true;
            this.touchdown_tick = tick;
            this.touchdown_position = position;
        }
        if !this.touchdown_seen && relative_tick > 0
            && relative_tick % (sample_every * 6) == 0 {
            let diagnostic_time = (relative_tick.to_float() * dt()).to_string();
            print("[griffin-landing-stability] t=" + diagnostic_time
                + " reference_y_m=" + position[1].to_string()
                + " vertical_velocity_mps=" + sample.linear_velocity_mps[1].to_string());
            print("[griffin-landing-stability] t=" + diagnostic_time
                + " any_leg_contact=" + sample.any_leg_contact.to_string()
                + " all_legs_contact=" + sample.all_legs_contact.to_string()
                + " touchdown=" + sample.touchdown.to_string());
            print("[griffin-landing-stability] t=" + diagnostic_time
                + " nav_y_m=" + sample.navigation_position_y.to_string()
                + " altimeter_y_m=" + sample.altimeter_position_y.to_string()
                + " altimeter_range_m=" + sample.altimeter_range_m.to_string());
            print("[griffin-landing-stability] t=" + diagnostic_time
                + " target_altitude_m=" + sample.altitude_above_target.to_string()
                + " pid_y=" + sample.guidance_pid_y.to_string()
                + " vertical_command_mps2=" + sample.guidance_vertical_command.to_string());
            print("[griffin-landing-stability] t=" + diagnostic_time
                + " throttle=" + sample.guidance_throttle.to_string()
                + " thrust_n=" + sample.engine_thrust_n.to_string()
                + " cutoff=" + sample.landing_engine_cutoff.to_string()
                + " handoff=" + sample.landing_handoff.to_string());
        }
        if this.touchdown_seen {
            this.sample_count += 1;
            this.elapsed = (tick - this.touchdown_tick).to_float() * dt();
            if position[1] < this.minimum_position_y {
                this.minimum_position_y = position[1];
            }
            if position[1] > this.maximum_position_y {
                this.maximum_position_y = position[1];
            }
            if sample.all_legs_contact != () && sample.all_legs_contact >= 0.999 {
                this.all_four_contact_samples += 1;
            } else {
                this.all_post_touchdown_samples_contact = false;
            }
            if sample.touchdown != () && sample.touchdown >= 0.999 {
                this.touchdown_samples += 1;
            }
        }
        let finite = position != () && position.len() == 3
            && finite_number(position[0]) && finite_number(position[1])
            && finite_number(position[2])
            && finite_number(sample.upright_axis_y)
            && finite_number(sample.ground_speed)
            && finite_number(sample.angular_speed);
        if this.touchdown_seen && !finite {
            this.finite = false;
        } else if this.touchdown_seen {
            if sample.upright_axis_y < this.min_upright {
                this.min_upright = sample.upright_axis_y;
            }
            if sample.ground_speed.abs() > this.max_ground {
                this.max_ground = sample.ground_speed.abs();
            }
            if sample.angular_speed.abs() > this.max_angular {
                this.max_angular = sample.angular_speed.abs();
            }
            let horizontal_x = position[0] - this.touchdown_position[0];
            let horizontal_z = position[2] - this.touchdown_position[2];
            let horizontal = (horizontal_x * horizontal_x
                + horizontal_z * horizontal_z).sqrt();
            if horizontal > this.max_horizontal {
                this.max_horizontal = horizontal;
            }
        }
    }

    if !this.touchdown_seen || this.elapsed < contract.horizon_s { return; }
    let source = sysml_requirements::source();
    emit_stability_verdict(this, contract, source);
}
