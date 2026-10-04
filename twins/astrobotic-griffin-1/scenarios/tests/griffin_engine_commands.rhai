// Production pilot path: qualify contact, acquire control, hold thrust once,
// observe delivered momentum, then release. Repeated key edges must not be
// necessary to sustain powered flight. Run on the surface contract fixture.
fn simulation_dependencies(me, ctx) {
    griffin_surface_ops::landing_stability_dependencies()
}

fn _trial_number(name) {
    let value = griffin_spec::_typed_model_number(
        "GriffinPropulsionRequirements::GriffinEngineControlStudy::" + name);
    if value == () || value <= 0.0 {throw("missing engine command trial datum: " + name);}
    value
}

fn _elapsed(start_tick) {
    (sim_tick() - start_tick).to_float() * clock_snapshot().fixed_dt_s
}

fn on_start(me, ctx) {
    this.lander = find_path("/Griffin1SurfaceOps/Lander");
    this.start_tick = sim_tick();
    this.phase = "landing";
    this.done = false;
    this.samples = [];
    this.peak_thrust = 0.0;
    this.lift = 0.0;
}

fn on_tick(me, ctx) {
    if this.done {return;}
    let sample = griffin_surface_ops::landing_stability_sample();
    if !sample.ok {return;}
    if this.phase == "landing" {
        if sample.touchdown < 0.999 || sample.all_legs_contact < 0.999 {
            if _elapsed(this.start_tick) > _trial_number("touchdownTimeoutS") {
                this.done = true;
                report_verdict(["no qualified touchdown before command trial"],
                    "GRIFFIN ENGINE COMMANDS", "GRIFFIN_ENGINE_COMMANDS");
            }
            return;
        }
        this.rest_y = sample.position[1];
        this.fuel_before = sample.engine_vehicle_mass_kg;
        // Explicit controller ownership is required when no render camera is
        // bound. A session-only possession cannot deliver semantic pilot input.
        let avatar = find_path("/Griffin1SurfaceOps/Avatar");
        if avatar < 0 {throw("pilot avatar is unavailable");}
        let acquired = cmd("AcquireControl", #{target: this.lander, source: avatar, bind_camera: false});
        if !acquired.ok {throw("pilot acquisition rejected: " + acquired);}
        this.phase = "acquiring";
        this.phase_tick = sim_tick();
        return;
    }
    if this.phase == "acquiring" {
        if sim_tick() - this.phase_tick < 2 {return;}
        let sent = cmd("SimulateIntent", #{target: this.lander, intent: "thrust", held: true});
        if !sent.ok {throw("held thrust rejected: " + sent);}
        this.phase = "burn";
        this.phase_tick = sim_tick();
        return;
    }
    let tick = sim_tick() - this.phase_tick;
    if this.phase == "burn" {
        this.peak_thrust = max(this.peak_thrust, sample.engine_thrust_n);
        this.lift = max(this.lift, sample.position[1] - this.rest_y);
        if tick % 60 == 0 {
            this.samples.push(sample);
            print("GRIFFIN_ENGINE_COMMAND_SAMPLE " + sample);
        }
        if _elapsed(this.phase_tick) < _trial_number("burnDurationS") {return;}
        let released = cmd("SimulateIntent", #{target: this.lander, intent: "thrust", held: false});
        if !released.ok {throw("thrust release rejected: " + released);}
        this.fuel_after = sample.engine_vehicle_mass_kg;
        this.end_lift = sample.position[1] - this.rest_y;
        this.end_vertical_speed = sample.linear_velocity_mps[1];
        this.phase = "release";
        this.phase_tick = sim_tick();
        return;
    }
    if _elapsed(this.phase_tick) < _trial_number("releaseDurationS") {return;}
    this.done = true;
    report_verdict([
        t_true(this.peak_thrust > _trial_number("extinguishedThrustThresholdN"), "held pilot demand did not produce useful thrust"),
        t_true(this.end_lift > _trial_number("minimumSustainedLiftM"), "held thrust did not sustain liftoff: lift=" + this.end_lift),
        t_true(this.end_vertical_speed > _trial_number("minimumEndVerticalSpeedMps"),
            "held thrust ended without sustained climb: vertical speed=" + this.end_vertical_speed),
        t_true(this.fuel_after < this.fuel_before, "burn did not consume propellant"),
        t_true(sample.engine_thrust_n < _trial_number("extinguishedThrustThresholdN"), "release did not extinguish engine thrust"),
    ], "GRIFFIN ENGINE COMMANDS", "GRIFFIN_ENGINE_COMMANDS");
}

fn on_stop(me, ctx) {
    if this.lander >= 0 {
        cmd("SimulateIntent", #{target: this.lander, intent: "thrust", held: false});
    }
}
