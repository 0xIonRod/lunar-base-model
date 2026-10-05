// Retained observer: compare two RestartScene trajectories in one app.
// Mount the surface contract fixture first, then attach one RunScenarioAsset
// observer on WorldGrid with reload_policy=Retain and no scene_asset. on_start
// owns the first restart. Model state is observed, never overwritten.
fn report_restart(name, result) {
    print(name + " " + result);
    emit(name, result);
}
fn simulation_dependencies(me, ctx) {
    let dependencies = griffin_surface_ops::landing_stability_dependencies();
    dependencies.entity_reads.push(find_path("/Griffin1SurfaceOps/FLIP"));
    dependencies
}
fn on_start(me, ctx) {
    subscribe("griffin_reload_observer_unused");
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
        this.sample_index = 0;
        print("GRIFFIN_RELOAD_BEGIN run=" + this.run + " tick=" + this.start_tick);
    }
    let tick = sim_tick() - this.start_tick;
    // Capture admission and its first three solver steps as well as the
    // settled trajectory. A first-step impulse must not hide between samples.
    if tick > 3 && tick % 60 != 0 {return;}
    let index = this.sample_index;
    this.sample_index += 1;
    let sample = griffin_surface_ops::landing_stability_sample();
    if sample.ok != true {
        this.done = true;
        this.result = #{tick: tick, run: this.run, sample: sample};
        report_restart("GRIFFIN_RELOAD_FAIL", this.result);
        return;
    }
    if tick == 0 {
        let flip = query("QueryPhysicsState", #{id:find_path("/Griffin1SurfaceOps/FLIP")});
        let bounds = flip.collider_local_bounds;
        if bounds == () {
            this.done = true;
            report_restart("GRIFFIN_RELOAD_FAIL", #{tick:tick,run:this.run,
                reason:"mounted rover has no cooked collision bounds"});
            return;
        }
        if this.run == 1 {
            this.rover_collision_bounds = bounds;
        } else {
            for corner in ["min", "max"] {
                for axis in 0..3 {
                    if (bounds[corner][axis] - this.rover_collision_bounds[corner][axis]).abs()
                        > this.contract.replay_tolerance_m {
                        this.done = true;
                        report_restart("GRIFFIN_RELOAD_FAIL", #{tick:tick,
                            field:"rover_collision_bounds",corner:corner,axis:axis,
                            reference:this.rover_collision_bounds,sample:bounds});
                        return;
                    }
                }
            }
        }
    }
    if this.run == 1 {
        this.samples.push(sample);
    } else {
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
        if sample.touchdown < 0.999 || sample.all_legs_contact < 0.999 {
            this.done = true;
            report_restart("GRIFFIN_RELOAD_FAIL", #{tick:tick,run:this.run,
                reason:"replay ended without qualified four-pad touchdown",sample:sample});
            return;
        }
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
