// Production startup and HUD GNC handoff. Initial pilot possession must not
// suppress mission arming; the airframe's piloted mux keeps engines under the
// pilot until RECONNECT GNC releases control. Observe actual thrust afterward.
const TEST_KIND = "headless";

fn simulation_dependencies(me, ctx) {
    griffin_surface_ops::landing_stability_dependencies()
}

fn on_start(me, ctx) {
    this.lander = find_path("/Griffin1SurfaceOps/Lander");
    if this.lander == () || this.lander < 0 { throw("Griffin lander is unavailable"); }
    this.done = false;
    this.checks = [];
    this.thrust_threshold = griffin_spec::_typed_model_number(
        "GriffinPropulsionRequirements::GriffinEngineControlStudy::extinguishedThrustThresholdN");
    if this.thrust_threshold == () || this.thrust_threshold <= 0.0 {
        throw("engine ignition observation threshold is unavailable");
    }
    let acquired = griffin_controls::control_lander();
    this.checks.push(t_true(acquired != () && acquired.ok == true,
        "initial pilot possession is accepted before descent arming"));
}

fn is_manual(lander) { let value = get(lander, "piloted"); value != () && value >= 0.5 }
fn is_guided(lander) { let value = get(lander, "piloted"); value != () && value < 0.5 }
fn manual(me) { is_manual(this.lander) }
fn guided(me) { is_guided(this.lander) }

fn armed_under_pilot(me) {
    let gnc = find_path("/Griffin1SurfaceOps/Lander/GNC");
    let sample = griffin_surface_ops::landing_stability_sample();
    print("GRIFFIN INITIAL PILOT " + #{sample:sample, piloted:get(this.lander,"piloted"),
        guidance_engage:get(gnc,"engage")});
    this.checks.push(t_true(get(gnc, "engage") == 1.0,
        "validated descent guidance arms despite initial pilot possession"));
    this.checks.push(t_true(is_manual(this.lander) && sample.ok == true
        && sample.engine_thrust_n == 0.0,
        "arming preserves the pilot's zero-throttle authority"));
    if get(gnc, "engage") != 1.0 {
        this.done = true;
        report_verdict(this.checks, "Griffin GNC toggle", "GRIFFIN_GNC_TOGGLE");
        return false;
    }
    true
}

fn ignition_sample_valid(sample, thrust_threshold) {
    sample.ok == true && sample.guidance_throttle > 0.0
        && sample.engine_thrust_n > thrust_threshold && sample.landing_contact < 0.5
}

fn ignited(me) {
    ignition_sample_valid(griffin_surface_ops::landing_stability_sample(), this.thrust_threshold)
}

fn observation_ready(me) { griffin_surface_ops::landing_stability_sample().ok == true }

fn ignition_confirmed(me) {
    let sample = griffin_surface_ops::landing_stability_sample();
    this.checks.push(t_true(ignition_sample_valid(sample, this.thrust_threshold),
        "reconnected guidance delivers positive main-engine thrust while airborne"));
    print("GRIFFIN STARTUP IGNITION " + sample);
    true
}

// One-shot live acceptance after a fresh or reopened automatic mission.
fn verify_automatic_startup() {
    let lander = find_path("/Griffin1SurfaceOps/Lander");
    let gnc = find_path("/Griffin1SurfaceOps/Lander/GNC");
    let mission = query("ScriptStatus", #{target: find_path("/Griffin1SurfaceOps/Scenario")});
    let sample = griffin_surface_ops::landing_stability_sample();
    print("GRIFFIN AUTOMATIC IGNITION " + sample);
    report_verdict([
        t_true(mission.ok == true, "the mission starts without source/dependency diagnostics"),
        t_true(get(gnc, "engage") == 1.0 && is_guided(lander),
            "the automatic mission arms guidance without pilot possession"),
        t_true(sample.ok == true && sample.guidance_throttle > 0.0
            && sample.engine_thrust_n > 0.0 && sample.landing_contact < 0.5,
            "the main engines deliver airborne thrust"),
    ], "Griffin automatic ignition", "GRIFFIN_AUTOMATIC_IGNITION")
}

// The HUD action result must report the new GNC state it established.
fn pressed(expected_connected) {
    let result = griffin_surface_ops::on_hud_action("toggle_gnc");
    result != () && result.ok == true && result.gnc_connected == expected_connected
}

fn disconnect(me) {
    this.checks.push(t_true(griffin_controls::gnc_connected() == true,
        "guidance commands the lander before the handoff"));
    this.checks.push(t_true(pressed(false), "DISCONNECT GNC is accepted"));
    true
}

fn disconnected(me) {
    this.checks.push(t_true(is_manual(this.lander), "the lander's piloted authority is engaged"));
    this.checks.push(t_true(griffin_controls::gnc_connected() == false,
        "the HUD reports GNC disconnected"));
    true
}

fn reconnect(me) {
    this.checks.push(t_true(pressed(true), "RECONNECT GNC is accepted"));
    true
}

fn finish(me) {
    if this.done { return true; }
    this.done = true;
    this.checks.push(t_true(is_guided(this.lander), "guidance owns the lander again"));
    let unknown = griffin_surface_ops::on_hud_action("no_such_action");
    this.checks.push(t_true(unknown != () && unknown.ok == false,
        "an unknown HUD action is rejected"));
    report_verdict(this.checks, "Griffin GNC toggle", "GRIFFIN_GNC_TOGGLE");
    true
}

fn timeout(me) {
    if this.done { return true; }
    this.done = true;
    this.checks.push(t_true(false, "GNC handoff did not complete"));
    report_verdict(this.checks, "Griffin GNC toggle", "GRIFFIN_GNC_TOGGLE");
    true
}

fn task(me, ctx) {
    par_race([
        seq([
            wait_until(Fn("manual")),
            wait(0.5),
            wait_until(Fn("observation_ready")),
            once(Fn("armed_under_pilot")),
            check(|m| !this.done),
            once(Fn("reconnect")),
            wait_until(Fn("guided")),
            wait_until(Fn("ignited")),
            once(Fn("ignition_confirmed")),
            once(Fn("disconnect")),
            wait_until(Fn("manual")),
            once(Fn("disconnected")),
            once(Fn("reconnect")),
            wait_until(Fn("guided")),
            once(Fn("finish")),
        ]),
        seq([wait(30.0), once(Fn("timeout"))]),
    ])
}
