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
    hint("FLIP CONTROL: " + forward + "/" + backward + " drive · " + left + "/" + right + " steer · Space brake · " + cancel + " release");
    objectives_hud([
        #{ text: "FLIP is the active surface vehicle", state: "active" },
        #{ text: "Drive  " + forward + "/" + backward + "   Steer  " + left + "/" + right + "   Brake  Space", state: "active" },
        #{ text: action + " toggles the authored route; manual input disengages autopilot", state: "pending" },
        #{ text: cancel + " releases FLIP and returns to free flight", state: "pending" }
    ]);
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
