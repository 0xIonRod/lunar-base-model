// Griffin-1 control surface.
//
// The simulator already owns possession, input routing, and autopilot
// authority. This Twin-local library makes those existing commands explicit
// for this mission and keeps the on-screen handoff language in one place.
// It is deliberately not a second vehicle-control implementation.

fn lander_path() { "/Griffin1SurfaceOps/Lander" }
fn rover_path() { "/Griffin1SurfaceOps/FLIP" }

fn resolve(path, label) {
    let target = find(path);
    if target == () || target < 0 {
        notify_kind(label + " is not available in the active scene.", "error");
        return ();
    }
    target
}

fn show_briefing() {
    let thrust = input_hint("thrust");
    let forward = input_hint("forward");
    let backward = input_hint("backward");
    let left = input_hint("left");
    let right = input_hint("right");
    let yaw_left = input_hint("yaw_left");
    let yaw_right = input_hint("yaw_right");
    let action = input_hint("action");
    let cancel = input_hint("cancel");

    hint("CONTROL: click the lander or FLIP to possess; " + cancel + " releases control");
    objectives_hud([
        #{ text: "LANDER  " + thrust + " thrust | " + forward + "/" + backward + " pitch | " + left + "/" + right + " roll", state: "active" },
        #{ text: "LANDER  " + yaw_left + "/" + yaw_right + " yaw | G release", state: "pending" },
        #{ text: "FLIP    " + forward + "/" + backward + " drive | " + left + "/" + right + " steer | Space brake", state: "pending" },
        #{ text: "FLIP    " + action + " toggles autopilot; manual input takes authority back", state: "pending" },
        #{ text: "HANDOFF " + cancel + " releases the selected vehicle", state: "pending" }
    ]);
}

fn show_rover_controls() {
    let forward = input_hint("forward");
    let backward = input_hint("backward");
    let left = input_hint("left");
    let right = input_hint("right");
    let action = input_hint("action");
    let cancel = input_hint("cancel");
    let steering_mode = rover_steering_mode_label();
    hint("FLIP CONTROL: " + forward + "/" + backward + " drive · " + left + "/" + right + " steer · Space brake · " + cancel + " release");
    objectives_hud([
        #{ text: "FLIP is the active surface vehicle", state: "active" },
        #{ text: "Drive  " + forward + "/" + backward + "   Steer  " + left + "/" + right + "   Brake  Space", state: "active" },
        #{ text: "STEERING MODE  " + steering_mode + "  (CRAB = parallel / ACKERMANN = wheel geometry)", state: "active" },
        #{ text: "Stopped FLIP: toggle_rover_steering_mode() switches the vehicle once", state: "pending" },
        #{ text: action + " toggles the authored route; manual input disengages autopilot", state: "pending" },
        #{ text: cancel + " releases FLIP and returns to free flight", state: "pending" }
    ]);
}

fn rover_steering_mode_label() {
    let state = query("QueryUsdPrim", #{
        path: "/Griffin1SurfaceOps/FLIP",
        attrs: ["physxVehicleAckermannSteering:strength"]
    });
    if state.ok == false { return "UNKNOWN"; }
    let strength = state.attrs["physxVehicleAckermannSteering:strength"];
    if strength == () { return "UNKNOWN"; }
    if strength > 0.5 { "ACKERMANN" } else { "CRAB WALK" }
}

// SimulateIntent is the same per-vessel controller path used by the keyboard,
// but persists the brake intent until explicitly released. A one-shot SetPorts
// write is useful for a single control frame; it is not a reliable stop on a
// sloped polar heightfield.
fn hold_rover_brake() {
    let target = resolve(rover_path(), "FLIP rover");
    if target == () { return #{ ok: false, error: "rover is unavailable" }; }
    cmd("DisengageAutopilot", #{ vessel: target });
    let result = cmd("SimulateIntent", #{ intent: "brake", held: true, target: target });
    if result.ok { notify_kind("FLIP brake held through the vehicle controller.", "info"); }
    result
}

fn release_rover_brake() {
    let target = resolve(rover_path(), "FLIP rover");
    if target == () { return #{ ok: false, error: "rover is unavailable" }; }
    cmd("SimulateIntent", #{ intent: "brake", held: false, target: target })
}

// Configure FLIP's four steering actuators as one vehicle-level mode. FLIP is
// authored as an all-wheel-steer rover: the shared vehicle attribute controls
// whether each left/right wheel pair receives full Ackermann correction (1.0)
// or parallel wheel angles (0.0) for crab walk. The old implementation tried
// to reach SteeringActuator on the USD wheel entities, but physical wheels own
// that actuator on synthesized joint entities. That made every public helper
// fail even though the wheel rig itself was valid.
//
// SetUsdAttribute is the runtime's authored vehicle-control path. It resyncs
// the four physical steering joints in place; it does not rebuild the rover.
// Stop FLIP before changing it so the steering axes do not slew underneath a
// moving chassis.
fn set_rover_steering_mode(mode) {
    if mode != "ackermann" && mode != "crab" {
        notify_kind("FLIP steering mode must be ackermann or crab.", "error");
        return #{ ok: false, error: "unknown steering mode" };
    }

    let target = resolve(rover_path(), "FLIP rover");
    if target == () { return #{ ok: false, error: "rover is unavailable" }; }

    let speed = get(target, "speed");
    if speed == () {
        notify_kind("FLIP speed is not available; steering mode was not changed.", "error");
        return #{ ok: false, error: "rover speed is unavailable" };
    }
    if speed.abs() > 0.08 {
        // Take route authority away and hold the brake through the same
        // per-vessel intent path as Space. The caller can issue the same
        // toggle again after the vehicle settles.
        hold_rover_brake();
        notify_kind("FLIP is still moving; brake is held. Try the steering mode again below 0.08 m/s.", "warning");
        return #{ ok: false, error: "rover must be stopped", speed: speed, brake_held: true };
    }

    release_rover_brake();
    let strength = if mode == "crab" { 0.0 } else { 1.0 };
    let result = cmd("SetUsdAttribute", #{
        path: "/Griffin1SurfaceOps/FLIP",
        name: "physxVehicleAckermannSteering:strength",
        type_name: "float",
        value: if mode == "crab" { "0.0" } else { "1.0" }
    });
    if !result.ok {
        notify_kind("FLIP steering mode command was rejected: " + result.error, "error");
        return #{ ok: false, error: "steering mode command rejected" };
    }
    let label = if mode == "crab" { "CRAB WALK" } else { "ACKERMANN" };
    notify_kind("FLIP steering mode: " + label + " queued on all four wheel joints.", "success");
    show_rover_controls();
    #{ ok: true, mode: mode, strength: strength, speed: speed }
}

fn crab_walk() {
    set_rover_steering_mode("crab")
}

fn ackermann_steering() {
    set_rover_steering_mode("ackermann")
}

fn toggle_rover_steering_mode() {
    let state = query("QueryUsdPrim", #{
        path: "/Griffin1SurfaceOps/FLIP",
        attrs: ["physxVehicleAckermannSteering:strength"]
    });
    let strength = state.attrs["physxVehicleAckermannSteering:strength"];
    if strength == () {
        notify_kind("FLIP steering mode is not readable from the active scene.", "error");
        return #{ ok: false, error: "steering mode is unavailable" };
    }
    if strength > 0.5 { crab_walk() } else { ackermann_steering() }
}

fn control_lander() {
    let target = resolve(lander_path(), "Griffin lander");
    if target == () { return; }
    let result = cmd("PossessVessel", #{ target: target, bind_camera: true });
    if result.ok {
        follow(target);
        hint("LANDER CONTROL: " + input_hint("thrust") + " thrust · W/S pitch · A/D roll · Q/E yaw · G release");
        notify_kind("Griffin lander under manual control.", "success");
    } else {
        notify_kind("Lander control was rejected: " + result.error, "error");
    }
    result
}

fn control_rover() {
    let target = resolve(rover_path(), "FLIP rover");
    if target == () { return; }
    let result = cmd("PossessVessel", #{ target: target, bind_camera: true });
    if result.ok {
        follow(target);
        show_rover_controls();
        notify_kind("FLIP under manual control.", "success");
    } else {
        notify_kind("FLIP control was rejected: " + result.error, "error");
    }
    result
}

fn release_lander() {
    let target = resolve(lander_path(), "Griffin lander");
    if target == () { return; }
    cmd("ReleaseVessel", #{ target: target });
}

fn release_rover() {
    let target = resolve(rover_path(), "FLIP rover");
    if target == () { return; }
    cmd("ReleaseVessel", #{ target: target });
}

fn release_control() {
    let lander = release_lander();
    let rover = release_rover();
    hint("FREE FLIGHT: click Griffin or FLIP to take control; " + input_hint("cancel") + " releases control");
    #{ lander: lander, rover: rover }
}

fn toggle_rover_autopilot() {
    let target = resolve(rover_path(), "FLIP rover");
    if target == () { return; }
    let result = cmd("ToggleAutopilot", #{ vessel: target });
    if result.ok { show_rover_controls(); }
    result
}

fn start_rover_autopilot() {
    let target = resolve(rover_path(), "FLIP rover");
    if target == () { return; }
    cmd("StartAutopilot", #{ vessel: target });
}

fn stop_rover_autopilot() {
    let target = resolve(rover_path(), "FLIP rover");
    if target == () { return; }
    cmd("DisengageAutopilot", #{ vessel: target });
}
