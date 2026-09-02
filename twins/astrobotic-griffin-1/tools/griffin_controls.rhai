// Griffin-1 control surface.
//
// The simulator already owns possession, input routing, and autopilot
// authority. This Twin-local library makes those existing commands explicit
// for this mission and keeps the on-screen handoff language in one place.
// It is deliberately not a second vehicle-control implementation.

fn lander_path() { "/Griffin1SurfaceOps/Lander" }
fn rover_path() { "/Griffin1SurfaceOps/FLIP" }

fn rover_wheel_paths() {
    [
        "/Griffin1SurfaceOps/FLIP/Suspension_FL/Wheel_FL",
        "/Griffin1SurfaceOps/FLIP/Suspension_FR/Wheel_FR",
        "/Griffin1SurfaceOps/FLIP/Suspension_RL/Wheel_RL",
        "/Griffin1SurfaceOps/FLIP/Suspension_RR/Wheel_RR"
    ]
}

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
        #{ text: "STEERING MODE  griffin_controls::crab_walk() / ::ackermann_steering()", state: "pending" },
        #{ text: "Stopped FLIP: griffin_controls::toggle_rover_steering_mode()", state: "pending" },
        #{ text: action + " toggles the authored route; manual input disengages autopilot", state: "pending" },
        #{ text: cancel + " releases FLIP and returns to free flight", state: "pending" }
    ]);
}

// Configure FLIP's four steering actuators as one vehicle-level mode. The
// current production runtime exposes steering lock and Ackermann correction on
// each wheel, so the Twin applies both values as one single policy rather than
// leaving a mixed front/rear state behind. Ordinary Ackermann driving gives the
// rear axle a zero lock; crab walk gives all four wheels the same parallel lock.
//
// This is a live control state, not an authored geometry edit. Stop FLIP before
// changing it so the steering axes do not slew underneath a moving chassis.
fn set_rover_steering_mode(mode) {
    if mode != "ackermann" && mode != "crab" {
        notify_kind("FLIP steering mode must be ackermann or crab.", "error");
        return #{ ok: false, error: "unknown steering mode" };
    }

    let wheels = rover_wheel_paths();
    let first = resolve(wheels[0], "FLIP wheel");
    if first == () { return #{ ok: false, error: "wheel is unavailable" }; }
    let lock = get(first, "SteeringActuator.max_steer_angle");
    if lock == () || lock <= 0.0 {
        notify_kind("FLIP steering lock is not ready.", "error");
        return #{ ok: false, error: "steering lock is unavailable" };
    }
    let parallel = mode == "crab";
    let strength = if parallel { 0.0 } else { 1.0 };
    for i in [0, 1, 2, 3] {
        let path = wheels[i];
        let wheel = resolve(path, "FLIP wheel");
        if wheel == () { return #{ ok: false, error: "wheel is unavailable" }; }
        if set(wheel, "SteeringActuator.ackermann_strength", strength) == false {
            notify_kind("FLIP steering actuator is not ready on " + path + ".", "error");
            return #{ ok: false, error: "steering actuator is unavailable" };
        }
        let wheel_lock = if parallel || i < 2 { lock } else { 0.0 };
        if set(wheel, "SteeringActuator.max_steer_angle", wheel_lock) == false {
            notify_kind("FLIP steering lock is not ready on " + path + ".", "error");
            return #{ ok: false, error: "steering lock is unavailable" };
        }
    }

    let label = if mode == "crab" { "CRAB WALK" } else { "ACKERMANN" };
    notify_kind("FLIP steering mode: " + label + ". Change only while stopped.", "success");
    show_rover_controls();
    #{ ok: true, mode: mode }
}

fn crab_walk() {
    set_rover_steering_mode("crab")
}

fn ackermann_steering() {
    set_rover_steering_mode("ackermann")
}

fn toggle_rover_steering_mode() {
    let first = resolve("/Griffin1SurfaceOps/FLIP/Suspension_FL/Wheel_FL", "FLIP wheel");
    if first == () { return #{ ok: false, error: "wheel is unavailable" }; }
    let strength = get(first, "SteeringActuator.ackermann_strength");
    if strength == () {
        notify_kind("FLIP steering actuator is not ready.", "error");
        return #{ ok: false, error: "steering actuator is unavailable" };
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
