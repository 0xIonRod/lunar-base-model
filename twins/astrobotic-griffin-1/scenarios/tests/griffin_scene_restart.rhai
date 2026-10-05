// Retained observer: compare two RestartScene trajectories in one app.
// Mount the surface contract fixture first, then attach one RunScenarioAsset
// observer on WorldGrid with reload_policy=Retain and no scene_asset. on_start
// owns the first restart. Model state is observed, never overwritten.
fn report_restart(name, result) {
    print(name + " " + result);
    emit(name, result);
}
fn simulation_dependencies(me, ctx) {
    griffin_surface_ops::landing_stability_dependencies()
}
fn on_start(me, ctx) {
    this.generation = execution_context().generation;
    this.run = 0;
    this.samples = [];
    this.done = false;
    this.contract = griffin_surface_ops::landing_stability_contract();
    // Source preparation can finish after an already mounted scene starts.
    // Begin observation only on the next replacement, with this host prepared.
    cmd("RestartScene", #{});
}
fn on_tick(me, ctx) {
    if this.done {return;}
    let generation = execution_context().generation;
    if generation == this.generation && this.run == 0 {return;}
    if generation != this.generation {
        this.generation = generation;
        this.run += 1;
        this.start_tick = sim_tick();
        print("GRIFFIN_RELOAD_BEGIN run=" + this.run + " tick=" + this.start_tick);
    }
    let tick = sim_tick() - this.start_tick;
    if tick % 60 != 0 {return;}
    let sample = griffin_surface_ops::landing_stability_sample();
    if sample.ok != true {
        this.done = true;
        this.result = #{tick: tick, run: this.run, sample: sample};
        report_restart("GRIFFIN_RELOAD_FAIL", this.result);
        return;
    }
    if this.run == 1 {
        this.samples.push(sample);
    } else {
        let index = tick / 60;
        let reference = this.samples[index];
        for field in ["position", "linear_velocity_mps"] {
            for axis in 0..3 {
                if (sample[field][axis] - reference[field][axis]).abs()
                    > if field == "position" {this.contract.replay_tolerance_m}
                        else {this.contract.replay_tolerance_speed_mps} {
                    this.done = true;
                    this.result = #{tick: tick, field: field,
                        axis: axis, reference: reference, sample: sample};
                    report_restart("GRIFFIN_RELOAD_FAIL", this.result);
                    return;
                }
            }
        }
        for field in ["upright_axis_y", "angular_speed"] {
            let tolerance = if field == "upright_axis_y" {this.contract.replay_tolerance_upright}
                else {this.contract.replay_tolerance_speed_mps};
            if (sample[field] - reference[field]).abs() > tolerance {
                this.done = true;
                this.result = #{tick: tick, field: field,
                    reference: reference, sample: sample};
                report_restart("GRIFFIN_RELOAD_FAIL", this.result);
                return;
            }
        }
        for field in ["engine_thrust_n",
            "guidance_throttle", "touchdown", "all_legs_contact",
            "landing_handoff", "landing_engine_cutoff"] {
            if sample[field] == () || reference[field] == ()
                || sample[field] != reference[field] {
                this.done = true;
                this.result = #{tick: tick, field: field,
                    reference: reference, sample: sample};
                report_restart("GRIFFIN_RELOAD_FAIL", this.result);
                return;
            }
        }
    }
    // 90 seconds includes descent plus the source-owned 60 s stability horizon.
    if tick >= 5400 {
        if this.run == 1 {
            let restart = cmd("RestartScene", #{});
            print("GRIFFIN_RELOAD_RESTART " + restart);
        } else {
            this.done = true;
            this.result = #{sample_count: this.samples.len(), ticks: tick};
            report_restart("GRIFFIN_RELOAD_PASS", this.result);
        }
    }
}
