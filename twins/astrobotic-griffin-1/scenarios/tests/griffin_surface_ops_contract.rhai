// Twin-owned fixed-clock landing-stability test.
//
// The scene remains a compact composed fixture, while this Rhai observer
// samples the lander until the SysML stability horizon. A verification
// binding selects the stability channel and a Twin-local harness compares the
// resulting metrics from two fresh processes. SysML owns every limit; Rhai
// owns the observations and verdict.

const ROOT = "/Griffin1SurfaceOps";

fn finite_number(value) {
    value != () && value.is_finite()
}

fn on_start(me, ctx) {
    // SimTick is the shared simulation master. Fixed/virtual elapsed resources
    // also include scheduler bookkeeping while a causal participant is held,
    // so they are diagnostic clocks rather than the test horizon.
    this.clock_start = clock_snapshot();
    this.start_tick = sim_tick();
    this.elapsed = 0.0;
    this.stability_done = false;
    this.last_sample_tick = sim_tick();
    this.sample_count = 0;
    this.finite = true;
    this.min_upright = 1.0;
    this.max_ground = 0.0;
    this.max_angular = 0.0;
    this.max_horizontal = 0.0;
    this.last = #{};
    // Resolve the SysML projection once. Re-querying the full validation map
    // at 60 Hz needlessly allocates a large dynamic value and can exceed the
    // VM string budget before the first sample is taken.
    this.contract = griffin_surface_ops::landing_stability_contract();
    print("[griffin-landing-stability] waiting for composed Twin stage");
}

fn emit_stability_verdict(me, contract, source, checks) {
    let failures = [];
    for check in checks {
        if check.ok != true { failures.push(check); }
    }
    let last_position = if me.last.position != () { me.last.position } else { [] };
    let last_upright = if me.last.upright_axis_y != () { me.last.upright_axis_y } else { 0.0 };
    let last_ground = if me.last.ground_speed != () { me.last.ground_speed } else { 0.0 };
    let last_angular = if me.last.angular_speed != () { me.last.angular_speed } else { 0.0 };
    let clocks = clock_snapshot();
    let clock_elapsed_delta = (clocks.sim_tick - me.clock_start.sim_tick).to_float()
        * clocks.fixed_dt_s;
    let fixed_elapsed_delta = clocks.fixed_elapsed_s - me.clock_start.fixed_elapsed_s;
    let clock_sync_error = (clock_elapsed_delta - me.elapsed).abs();
    let metrics = #{
        horizon_s: contract.horizon_s,
        elapsed_s: me.elapsed,
        sim_tick: clocks.sim_tick,
        clock_start_sim_tick: me.clock_start.sim_tick,
        clock_tick_delta: clocks.sim_tick - me.clock_start.sim_tick,
        fixed_elapsed_s: clocks.fixed_elapsed_s,
        fixed_elapsed_delta_s: fixed_elapsed_delta,
        admitted_sim_elapsed_delta_s: clock_elapsed_delta,
        clock_sync_error_s: clock_sync_error,
        clock_contract_ok: clocks.clock_contract_ok,
        virtual_elapsed_s: clocks.virtual_elapsed_s,
        physics_elapsed_s: clocks.physics_elapsed_s,
        barrier_held: clocks.barrier_held,
        sample_count: me.sample_count,
        position: last_position,
        upright_axis_y: last_upright,
        ground_speed_mps: last_ground,
        angular_speed_rad_per_sec: last_angular,
        min_upright_axis_y: me.min_upright,
        max_ground_speed_mps: me.max_ground,
        max_angular_speed_rad_per_sec: me.max_angular,
        max_horizontal_drift_m: me.max_horizontal,
        finite: me.finite,
        touchdown: if me.last.touchdown != () { me.last.touchdown } else { 0.0 },
        source_revision: source.source_revision_hex,
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
    let report = #{
        ok: failures.len() == 0,
        verification: "Griffin1Requirements::Verify_GriffinLandingStability",
        requirement_count: 1,
        source_revision: source.source_revision_hex,
        results: checks,
        failures: failures,
        metrics: metrics,
        contract: contract
    };
    report_structured_verdict(report, "GRIFFIN LANDING STABILITY", "GRIFFIN_LANDING_STABILITY");
    me.stability_done = true;
}

fn on_tick(me, ctx) {
    if this.stability_done { return; }
    let contract = this.contract;
    if contract == () || contract.horizon_s == () || contract.horizon_s <= 0.0 {
        return;
    }

    // Sampling every ten fixed ticks keeps the test inexpensive while still
    // resolving the powered-descent oscillations that caused divergence.
    let tick = sim_tick();
    // Sample in the test's own fixed-tick frame, not against the process-wide
    // tick modulus. Startup admission may begin at any absolute SimTick, but
    // a relative observer must produce the same sample set for the same
    // horizon on every fresh process.
    let relative_tick = tick - this.start_tick;
    this.elapsed = relative_tick.to_float() * dt();
    if relative_tick > 0 && relative_tick % 10 == 0 && tick != this.last_sample_tick {
        this.last_sample_tick = tick;
        let sample = griffin_surface_ops::landing_stability_sample();
        // Scene projection and the first admitted physics pose can complete on
        // different fixed updates.  A missing sample before that boundary is
        // not a non-finite physics value; leave the sample counter untouched
        // and let the explicit no-sample requirement fail if readiness never
        // arrives.  Once all fields exist, NaN/inf still fails immediately.
        let position = if sample == () { () } else { sample.position };
        let ready = sample != () && position != () && position.len() == 3
            && sample.upright_axis_y != () && sample.ground_speed != ()
            && sample.angular_speed != ();
        if !ready {
            return;
        }
        this.last = sample;
        this.sample_count += 1;
        let finite = position != () && position.len() == 3
            && finite_number(position[0]) && finite_number(position[1])
            && finite_number(position[2])
            && finite_number(sample.upright_axis_y)
            && finite_number(sample.ground_speed)
            && finite_number(sample.angular_speed);
        if !finite {
            this.finite = false;
        } else {
            if sample.upright_axis_y < this.min_upright {
                this.min_upright = sample.upright_axis_y;
            }
            if sample.ground_speed.abs() > this.max_ground {
                this.max_ground = sample.ground_speed.abs();
            }
            if sample.angular_speed.abs() > this.max_angular {
                this.max_angular = sample.angular_speed.abs();
            }
            let horizontal = (position[0] * position[0]
                + position[2] * position[2]).sqrt();
            if horizontal > this.max_horizontal {
                this.max_horizontal = horizontal;
            }
        }
    }

    if this.elapsed < contract.horizon_s { return; }
    let source = sysml_requirements::source();
    let current_clocks = clock_snapshot();
    let clock_sync_error = ((current_clocks.sim_tick - this.clock_start.sim_tick).to_float()
        * current_clocks.fixed_dt_s - this.elapsed).abs();
    let checks = [
        #{ id: "GR-031-stability-finite", component: "lander", kind: "divergence", path: ROOT + "/Lander", actual: this.finite, expected: true, ok: this.finite, error: "landing telemetry became non-finite" },
        #{ id: "GR-031-clock-sync", component: "simulation-clock", kind: "divergence", path: ROOT, actual: clock_sync_error, expected: 0.0, ok: clock_sync_error <= 1.0e-7, error: "Rhai elapsed time diverged from the fixed clock" },
        #{ id: "GR-031-sample-count", component: "lander", kind: "divergence", path: ROOT + "/Lander", actual: this.sample_count, expected: 1, ok: this.sample_count > 0, error: "landing trial produced no samples" },
        #{ id: "GR-031-tilt-bound", component: "lander", kind: "stability", path: ROOT + "/Lander", actual: this.min_upright, expected: contract.min_upright_axis_y, ok: this.min_upright >= contract.min_upright_axis_y, error: "lander tilt exceeded the SysML bound" },
        #{ id: "GR-031-ground-speed-bound", component: "lander", kind: "stability", path: ROOT + "/Lander", actual: this.max_ground, expected: contract.max_ground_speed_mps, ok: this.max_ground <= contract.max_ground_speed_mps, error: "landing ground speed exceeded the SysML bound" },
        #{ id: "GR-031-angular-speed-bound", component: "lander", kind: "stability", path: ROOT + "/Lander", actual: this.max_angular, expected: contract.max_angular_speed_rad_per_sec, ok: this.max_angular <= contract.max_angular_speed_rad_per_sec, error: "landing angular speed exceeded the SysML bound" },
        #{ id: "GR-031-horizontal-drift-bound", component: "lander", kind: "divergence", path: ROOT + "/Lander", actual: this.max_horizontal, expected: contract.max_horizontal_drift_m, ok: this.max_horizontal <= contract.max_horizontal_drift_m, error: "landing horizontal drift exceeded the SysML bound" }
    ];
    emit_stability_verdict(this, contract, source, checks);
}
