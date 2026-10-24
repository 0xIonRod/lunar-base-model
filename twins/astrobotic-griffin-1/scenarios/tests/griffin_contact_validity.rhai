const TEST_KIND = "headless";
const ROOT = "/Griffin1SurfaceOps";

fn bodies() {
    let pending = [ROOT + "/Lander", ROOT + "/FLIP"];
    let result = [];
    while pending.len() > 0 {
        let path = pending.pop();
        let prim = query("QueryUsdPrim", #{path: path, schemas: true, children: true,
            attrs: ["physics:rigidBodyEnabled", "physics:kinematicEnabled"]});
        if prim.error != () { throw("Impact fixture topology unavailable: " + prim.error); }
        if prim.api_schemas.contains("PhysicsRigidBodyAPI")
            && prim.attrs["physics:rigidBodyEnabled"] != false
            && prim.attrs["physics:kinematicEnabled"] != true {
            let id = find_path(path);
            if id < 0 { throw("Impact fixture body is missing: " + path); }
            result.push(id);
        }
        for child in prim.children { pending.push(child); }
    }
    result
}
fn simulation_dependencies(me, ctx) {
    let members = bodies();
    #{modelica_entities: [find_path(ROOT + "/Lander"), find_path(ROOT + "/Lander/GNC"),
        find_path(ROOT + "/Lander/ContactValidity")],
      entity_reads: members, entity_writes: members,
      query_reads: ["QueryUsdPrim", "QueryPhysicsState", "GetReadiness"], required_inputs: []}
}
fn on_start(me, ctx) {
    this.crash = query("QueryUsdPrim", #{path: ROOT + "/ValidityTest",
        attrs: ["inputs:expect_pause"]}).attrs["inputs:expect_pause"];
    if type_of(this.crash) != "bool" { throw("Impact fixture requires an explicit expected response"); }
    this.members = bodies(); this.lander = find_path(ROOT + "/Lander");
    this.model = find_path(ROOT + "/Lander/ContactValidity");
    this.gnc = find_path(ROOT + "/Lander/GNC");
    this.started = sim_tick(); this.launched = false; this.done = false; this.held_at = ();
    this.impact = false; this.events = 0; this.warned = false; this.bounded = true;
    this.peak_descent = 0.0;
    subscribe("griffin.contact-validity-exceeded"); subscribe("simulation-object-paused");
}
fn on_event(me, evt, ctx) {
    if evt.name == "griffin.contact-validity-exceeded" && evt.source == this.model {
        this.impact = evt.value > 1.0 && evt.sim_tick <= sim_tick();
        emit("GRIFFIN_CONTACT_VALIDITY_EVENT_EVIDENCE", evt);
    }
    if evt.name == "simulation-object-paused" && evt.source == this.lander {
        this.events += 1;
        this.warned = evt.severity == "Warning" && evt.value.contains("Impact normal approach speed=")
            && evt.value.contains("study limit=5") && evt.value.contains("including Modelica");
    }
}
fn on_tick(me, ctx) {
    if this.done { return; }
    if this.crash && !this.launched && sim_tick() - this.started >= 3 {
        for body in this.members {
            let mass = get(body, "mass");
            if mass == () || mass <= 0.0 { throw("Impact fixture body mass is unavailable"); }
            let applied = cmd("SetPorts", #{target: body, writes: [["force_y", -300.0*mass/dt()]]});
            if applied.ok != true { throw("Impact launch input was rejected: " + applied); }
        }
        this.launched = true;
        return;
    }
    let state = query("QueryPhysicsState", #{id: this.lander});
    this.peak_descent = max(this.peak_descent, -state.linear_velocity_mps[1]);
    this.bounded = this.bounded && vlen(state.linear_velocity_mps) < 1000.0
        && vlen(world_pos(this.lander)) < 100000.0;
    let reached = if this.crash { state.simulation_object_paused }
        else { get(this.lander, "touchdown") >= 0.5 };
    if reached && this.held_at == () {
        this.held_at = sim_tick(); this.pose = world_pos(this.lander);
        this.model_time = get(this.model, "ModelicaModel.current_time");
        this.controller_time = get(this.lander, "ModelicaModel.current_time");
        this.gnc_time = get(this.gnc, "ModelicaModel.current_time");
    }
    if this.held_at == () && sim_tick() - this.started < (if this.crash { 300 } else { 6000 }) { return; }
    if this.held_at != () && sim_tick() - this.held_at < 30 { return; }
    this.done = true;
    let ready = query("GetReadiness", #{});
    let checks = [t_true(this.held_at != (), "the configured impact or nominal touchdown is observed"),
        t_true(this.bounded, "the articulated system stays finite and bounded before containment"),
        t_true(ready.ready && !ready.world_hold && !ready.faulted, "the scene remains usable")];
    if this.crash {
        let stopped = true;
        for body in this.members {
            let member = query("QueryPhysicsState", #{id: body});
            stopped = stopped && member.simulation_object_paused && member.rigid_body_disabled;
        }
        checks.push(t_true(this.launched && this.peak_descent > 280.0,
            "the complete articulated assembly reaches the high-energy return condition"));
        checks.push(t_true(this.impact && stopped, "the validity event contains every connected dynamic body"));
        checks.push(t_true(this.events == 1 && this.warned, "one warning explains the study boundary and complete pause"));
        checks.push(t_true(this.held_at != () && world_pos(this.lander) == this.pose
            && get(this.model, "ModelicaModel.current_time") == this.model_time
            && get(this.lander, "ModelicaModel.current_time") == this.controller_time
            && get(this.gnc, "ModelicaModel.current_time") == this.gnc_time,
            "the pose, validity observer, flight controller and guidance clock stop together"));
    } else {
        checks.push(t_true(!state.simulation_object_paused && !this.impact && this.events == 0,
            "nominal powered descent does not produce a false impact pause"));
        checks.push(t_true(this.held_at != () && get(this.model, "ModelicaModel.current_time") > this.model_time,
            "the admitted contact observer keeps integrating after nominal touchdown"));
    }
    emit("GRIFFIN_CONTACT_VALIDITY_EVIDENCE", #{crash_case: this.crash,
        bodies: this.members.len(), peak_descent_mps: this.peak_descent,
        paused: state.simulation_object_paused, velocity_mps: state.linear_velocity_mps,
        condition: state.simulation_object_pause_reason});
    report_verdict(checks, "GRIFFIN CONTACT VALIDITY", "GRIFFIN_CONTACT_VALIDITY");
}
