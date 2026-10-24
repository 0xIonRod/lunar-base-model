// A ballistic engine-off drop exceeds the authored contact-model envelope.
const TEST_KIND = "headless";
const LANDER = "/Griffin1SurfaceOps/Lander";
fn simulation_dependencies(me, ctx) {
    let members = [find_path(LANDER), find_path(LANDER + "/GNC"),
        find_path(LANDER + "/MainPropulsion"), find_path(LANDER + "/ContactValidity")];
    #{modelica_entities: members, entity_reads: members,
      entity_writes: [find_path(LANDER), find_path(LANDER + "/GNC")],
      query_reads: ["QueryPhysicsState", "ReadPorts", "GetReadiness", "AnalyzeSysml", "ReadActiveTwinContract"],
      required_inputs: [#{owner: "sysml.twin-analysis", identity: twin_name()}]}
}
fn on_start(me, ctx) {
    this.lander = find_path(LANDER); this.gnc = find_path(LANDER + "/GNC");
    this.model = find_path(LANDER + "/ContactValidity");
    this.propulsion = find_path(LANDER + "/MainPropulsion");
    this.start_tick = sim_tick(); this.held_at = (); this.done = false;
    this.maximum_thrust = 0.0; this.peak_descent = 0.0; this.bounded = true;
    this.impact = false; this.warnings = 0; this.explained = false; this.released = false;
    subscribe("griffin.contact-validity-exceeded"); subscribe("simulation-object-paused");
    let control = griffin_controls::control_lander();
    let input = cmd("SimulateIntent", #{target: this.lander, intent: "forward", held: true});
    if control.ok != true || input.ok != true { throw("Engine-off input was not admitted"); }
}
fn on_event(me, evt, ctx) {
    if evt.name == "griffin.contact-validity-exceeded" && evt.source == this.model {
        this.impact = evt.value > 1.0 && evt.sim_tick <= sim_tick();
        emit("GRIFFIN_ENGINE_OFF_IMPACT_EVENT_EVIDENCE", evt);
    }
    if evt.name == "simulation-object-paused" && evt.source == this.lander {
        this.warnings += 1;
        this.explained = evt.severity == "Warning"
            && evt.value.contains("Impact normal approach speed=")
            && evt.value.contains("contact-model study limit=")
            && evt.value.contains("including Modelica");
    }
}
fn on_tick(me, ctx) {
    if this.done { return; }
    if !this.released && get(this.lander, "piloted") >= 0.5 {
        let released = cmd("SimulateIntent", #{target: this.lander, intent: "forward", held: false});
        if released.ok != true { throw("Engine-off pitch input could not be released"); }
        this.released = true;
    }
    let state = query("QueryPhysicsState", #{id: this.lander});
    this.maximum_thrust = max(this.maximum_thrust, griffin_spec::main_engine_total(this.propulsion, "thrust_n"));
    this.peak_descent = max(this.peak_descent, -state.linear_velocity_mps[1]);
    this.bounded = this.bounded && vlen(state.linear_velocity_mps) < 1000.0
        && vlen(world_pos(this.lander)) < 100000.0;
    if state.simulation_object_paused && this.held_at == () {
        this.held_at = sim_tick(); this.pose = world_pos(this.lander);
        this.model_time = get(this.model, "ModelicaModel.current_time");
        this.controller_time = get(this.lander, "ModelicaModel.current_time");
        this.gnc_time = get(this.gnc, "ModelicaModel.current_time");
    }
    if this.held_at == () && sim_tick() - this.start_tick < 1800 { return; }
    if this.held_at != () && sim_tick() - this.held_at < 30 { return; }
    this.done = true;
    let ready = query("GetReadiness", #{});
    let limit = get(this.model, "speed_limit_mps");
    report_verdict([
        t_true(this.released && this.maximum_thrust == 0.0, "the ballistic drop keeps its engines extinguished"),
        t_true(this.peak_descent > limit && limit > 0.0, "the drop reaches the authored model-validity boundary"),
        t_true(this.impact && this.held_at != (), "a source-qualified impact event pauses the lander"),
        t_true(state.rigid_body_disabled && state.simulation_object_pause_reason.condition == "griffin:impact-outside-model-validity",
            "native integration stops with its explicit validity condition"),
        t_true(this.warnings == 1 && this.explained, "one warning explains the impact and complete coupled pause"),
        t_true(this.held_at != () && world_pos(this.lander) == this.pose
            && get(this.model, "ModelicaModel.current_time") == this.model_time
            && get(this.lander, "ModelicaModel.current_time") == this.controller_time
            && get(this.gnc, "ModelicaModel.current_time") == this.gnc_time,
            "pose, guidance, controller and validity clocks remain stopped"),
        t_true(this.bounded && ready.ready && !ready.world_hold && !ready.faulted,
            "containment preserves finite state and a usable scene")
    ], "Griffin engine-off impact", "GRIFFIN_ENGINE_OFF_IMPACT");
    emit("GRIFFIN_ENGINE_OFF_IMPACT_EVIDENCE", #{peak_descent_mps: this.peak_descent,
        maximum_thrust_n: this.maximum_thrust, speed_limit_mps: limit,
        condition: state.simulation_object_pause_reason});
}
