// Production pilot path: qualify contact, acquire control, hold thrust once,
// observe delivered momentum, then release. Repeated key edges must not be
// necessary to sustain powered flight. Run on the surface contract fixture.
fn simulation_dependencies(me, ctx) {
    let deps=griffin_surface_ops::landing_stability_dependencies();
    deps.query_reads.push("ReadPortsBatch");
    deps.entity_writes.push(find_path("/Griffin1SurfaceOps/Lander"));
    deps
}

// One admitted read samples the native solver endpoints and the connected
// PropellantStatus outputs. CoSim may propagate the preceding fixed tick.
fn _live_mass_properties(lander, main) {
    let native_names=["mass","com_x","com_y","com_z","inertia_xx","inertia_yy","inertia_zz"];
    let model_names=["vehicle_mass_kg","vehicle_com_x_m","vehicle_com_y_m","vehicle_com_z_m",
        "vehicle_inertia_xx_kg_m2","vehicle_inertia_yy_kg_m2","vehicle_inertia_zz_kg_m2"];
    let batch=query("ReadPortsBatch",#{targets:[#{api_id:lander,port_names:native_names},
        #{api_id:main,port_names:model_names}]});
    if batch==() || batch.sim_tick==() || batch.sim_tick.to_int()!=sim_tick()
        || batch.entities==() || batch.entities.len()!=2 {
        throw("native mass property snapshot unavailable: "+batch);
    }
    let values=[];
    for index in 0..2 {
        let row=batch.entities[index];
        if row.api_id==() || row.api_id.to_int()!=[lander,main][index]
            || row.ports==() {
            throw("native mass property target or port snapshot invalid: "+row);
        }
        let selected=[];
        let names=if index==0 {native_names} else {model_names};
        let direction=if index==0 {"inout"} else {"out"};
        let source=if index==0 {"Avian rigid body"} else {"Modelica co-simulation component"};
        for axis in 0..7 {
            let matches=[];
            for candidate in row.ports {
                if candidate.name==names[axis] && candidate.direction==direction
                    && candidate.metadata!=() && candidate.metadata.source==source {
                    matches.push(candidate);
                }
            }
            if matches.len()!=1 {
                throw("native mass property requires exactly one authoritative owner: "+
                    #{name:names[axis],direction:direction,source:source,matches:matches});
            }
            let port=matches[0];
            if port.value==() || !port.value.is_finite()
                || ((axis==0 || axis>=4) && port.value<=0.0) {
                throw("native mass property owner or finite value invalid: "+port);
            }
            selected.push(port.value);
        }
        values.push(selected);
    }
    #{sim_tick:batch.sim_tick.to_int(),native:values[0],model:values[1]}
}

fn _propagation_matches(current, previous) {
    if previous==() || current.sim_tick!=previous.sim_tick+1 {
        throw("native mass property observations are not consecutive admitted ticks");
    }
    for axis in 0..7 {
        let lower=min(previous.model[axis],current.model[axis]);
        let upper=max(previous.model[axis],current.model[axis]);
        // Avian stores an inverse inertia tensor. Its reciprocal reader can
        // differ by roundoff; this bound is two binary64 machine epsilons.
        let roundoff=4.440892098500626e-16*max(1.0,max(lower.abs(),upper.abs()));
        if current.native[axis]<lower-roundoff || current.native[axis]>upper+roundoff {return false;}
    }
    true
}

fn _trial_number(name) {
    let value = griffin_spec::_typed_model_number(
        "GriffinPropulsionRequirements::GriffinEngineControlStudy::" + name);
    if value == () || value <= 0.0 {throw("missing engine command trial datum: " + name);}
    value
}

// Highest chamber pressure across the cluster; () when any engine is unread.
fn _peak_engine_pressure(main) {
    let peak=0.0;
    for name in griffin_spec::main_engine_names() {
        let value=get(main,griffin_spec::main_engine_port(name,"chamber_pressure_pa"));
        if value==() {return ();}
        peak=max(peak,value);
    }
    peak
}

// Each engine's chamber pressure closes with its own reacting flow and bore.
fn _engine_pressures_close(main, pressure_per_flow, tolerance) {
    for name in griffin_spec::main_engine_names() {
        let pressure=get(main,griffin_spec::main_engine_port(name,"chamber_pressure_pa"));
        let mass_flow=get(main,griffin_spec::main_engine_port(name,"propellant_flow"));
        let efficiency=get(main,griffin_spec::main_engine_port(name,"mixture_efficiency"));
        if pressure==() || mass_flow==() || efficiency==()
            || (pressure-mass_flow*efficiency*pressure_per_flow).abs()>tolerance {return false;}
    }
    true
}

fn _elapsed(start_tick) {
    (sim_tick() - start_tick).to_float() * clock_snapshot().fixed_dt_s
}

fn on_start(me, ctx) {
    this.lander = find_path("/Griffin1SurfaceOps/Lander");
    this.main = find_path("/Griffin1SurfaceOps/Lander/MainPropulsion");
    this.start_tick = sim_tick();
    this.phase = "landing";
    this.done = false;
    this.samples = [];
    this.peak_thrust = 0.0;
    this.peak_angular_speed = 0.0;
    this.minimum_upright_y = 1.0;
    this.lift = 0.0;
    let own="GriffinPropulsionRequirements::GriffinPressureFedStudy::";
    this.pressure_tolerance=griffin_spec::_typed_model_number(own+"pressureObservationTolerancePa");
    this.pressure_per_flow=griffin_spec::_typed_model_number(own+"characteristicVelocityMps")
        *griffin_spec::_typed_model_number(own+"combustionEfficiency")
        /griffin_spec::_typed_model_number(own+"engineThroatBoreAreaM2");
    this.pressure_closure_ok=true;
    this.mass_propagation_ok=true;
    this.previous_mass_properties=();
}

fn on_tick(me, ctx) {
    if this.done {return;}
    try {
    let sample = griffin_surface_ops::landing_stability_sample();
    if sample==() || sample.ok!=true {
        if this.phase=="landing" && sample!=() && sample.physics!=()
            && sample.physics.physics_state_ready==false
            && _elapsed(this.start_tick)<=_trial_number("touchdownTimeoutS") {return;}
        throw("engine command physical observation unavailable: "+sample);
    }
    let properties=_live_mass_properties(this.lander,this.main);
    if this.phase!="landing" && this.previous_mass_properties!=() {
        this.mass_propagation_ok=this.mass_propagation_ok
            && _propagation_matches(properties,this.previous_mass_properties);
    }
    this.previous_mass_properties=properties;
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
        this.native_before=properties;
        this.cold_pressure=_peak_engine_pressure(this.main);
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
        this.peak_angular_speed = max(this.peak_angular_speed, sample.angular_speed);
        this.minimum_upright_y = min(this.minimum_upright_y, sample.upright_axis_y);
        this.lift = max(this.lift, sample.position[1] - this.rest_y);
        // Pressure closes with useful reacting flow. Tank pressure imbalance
        // and physical valve saturation can reduce the mixture efficiency.
        this.pressure_closure_ok=this.pressure_closure_ok
            && _engine_pressures_close(this.main,this.pressure_per_flow,this.pressure_tolerance);
        if tick % 60 == 0 {
            this.samples.push(sample);
            print("GRIFFIN_ENGINE_COMMAND_SAMPLE " + #{physical:sample,mass_properties:properties});
        }
        if _elapsed(this.phase_tick) < _trial_number("burnDurationS") {return;}
        let released = cmd("SimulateIntent", #{target: this.lander, intent: "thrust", held: false});
        if !released.ok {throw("thrust release rejected: " + released);}
        this.fuel_after = sample.engine_vehicle_mass_kg;
        this.native_after=properties;
        this.end_lift = sample.position[1] - this.rest_y;
        this.end_vertical_speed = sample.linear_velocity_mps[1];
        this.phase = "release";
        this.phase_tick = sim_tick();
        return;
    }
    if _elapsed(this.phase_tick) < _trial_number("releaseDurationS") {return;}
    this.done = true;
    let final_pressure=_peak_engine_pressure(this.main);
    let inertia_decreased=true;
    // The tanks lie along body Y: consuming their mass reduces X/Z inertia.
    // The Y component remains governed by the same model propagation check.
    for axis in [4,6] {
        inertia_decreased=inertia_decreased && this.native_after.native[axis]<this.native_before.native[axis];
    }
    print("GRIFFIN_ENGINE_NATIVE_MASS_PROPERTIES "+#{before:this.native_before,
        after:this.native_after,propagation_matches:this.mass_propagation_ok});
    print("GRIFFIN_ENGINE_RELEASE pressure_pa="+final_pressure+" thrust_n="+sample.engine_thrust_n);
    report_verdict([
        t_true(this.peak_thrust > _trial_number("extinguishedThrustThresholdN"), "held pilot demand did not produce useful thrust"),
        t_true(this.end_lift > _trial_number("minimumSustainedLiftM"), "held thrust did not sustain liftoff: lift=" + this.end_lift),
        t_true(this.end_vertical_speed > _trial_number("minimumEndVerticalSpeedMps"),
            "held thrust ended without sustained climb: vertical speed=" + this.end_vertical_speed),
        t_true(this.fuel_after < this.fuel_before, "burn did not consume propellant"),
        t_true(this.native_after.native[0]<this.native_before.native[0],"native solver mass did not decrease with propellant"),
        t_true(inertia_decreased,"native solver X/Z inertia did not decrease with propellant"),
        t_true(this.mass_propagation_ok,"native solver mass, COM or inertia differs from consecutive PropellantStatus samples"),
        t_true(this.peak_angular_speed <= _trial_number("maximumBurnAngularSpeedRadS"),
            "straight-up burn spun too fast: " + this.peak_angular_speed),
        t_true(this.minimum_upright_y >= _trial_number("minimumBurnUprightY"),
            "straight-up burn exceeded attitude envelope: upright Y=" + this.minimum_upright_y),
        t_true(sample.engine_thrust_n < _trial_number("extinguishedThrustThresholdN"), "release did not extinguish engine thrust"),
        t_true(this.cold_pressure!=() && this.cold_pressure<this.pressure_tolerance,
            "cold chamber retained liquid-feed pressure"),
        t_true(this.pressure_closure_ok,"chamber pressure did not follow combustion flow and bore area"),
        t_true(final_pressure!=() && final_pressure<this.pressure_tolerance,
            "release chamber pressure remained above settling threshold: "+final_pressure),
    ], "GRIFFIN ENGINE COMMANDS", "GRIFFIN_ENGINE_COMMANDS");
    } catch (error) {
        this.done=true;
        let stopped=cmd("SimulateIntent",#{target:this.lander,intent:"thrust",held:false});
        print("GRIFFIN_ENGINE_COMMAND_OBSERVATION_ERROR "+#{error:error,stopped:stopped});
        report_verdict([t_true(false,"engine command observation failed: "+error)],
            "GRIFFIN ENGINE COMMANDS","GRIFFIN_ENGINE_COMMANDS");
    }
}

fn on_stop(me, ctx) {
    if this.lander >= 0 {
        cmd("SimulateIntent", #{target: this.lander, intent: "thrust", held: false});
    }
}
