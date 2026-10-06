// Production HUD GNC handoff during powered descent. DISCONNECT GNC takes the
// lander's piloted authority through the shared control commands, so the
// flight law ignores guidance; RECONNECT GNC releases it again. The observer
// presses the same HUD action twice and measures the native authority port.
const TEST_KIND = "headless";

fn simulation_dependencies(me, ctx) {
    griffin_surface_ops::landing_stability_dependencies()
}

fn on_start(me, ctx) {
    this.lander = find_path("/Griffin1SurfaceOps/Lander");
    if this.lander == () || this.lander < 0 { throw("Griffin lander is unavailable"); }
    this.done = false;
    this.checks = [];
}

fn is_manual(lander) { let value = get(lander, "piloted"); value != () && value >= 0.5 }
fn is_guided(lander) { let value = get(lander, "piloted"); value != () && value < 0.5 }
fn manual(me) { is_manual(this.lander) }
fn guided(me) { is_guided(this.lander) }

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
            wait(3.0),
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
