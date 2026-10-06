// Griffin-1 control surface.
//
// The simulator already owns possession, input routing, and autopilot
// authority. This Twin-local library makes those existing commands explicit
// for this mission and keeps the on-screen handoff language in one place.
// It is deliberately not a second vehicle-control implementation.

fn lander_path() { "/Griffin1SurfaceOps/Lander" }
fn rover_path() { "/Griffin1SurfaceOps/FLIP" }

fn resolve(path, label) {
    let target = find_path(path);
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
        #{ text: "LANDER  " + yaw_left + "/" + yaw_right + " yaw | U open ramps | F detach rover", state: "pending" },
        #{ text: "FLIP    " + forward + "/" + backward + " drive | " + left + "/" + right + " steer | Space brake", state: "pending" },
        #{ text: "FLIP    " + action + " toggles autopilot; manual input takes authority back", state: "pending" },
        #{ text: "HANDOFF " + cancel + " releases the selected vehicle", state: "pending" }
    ]);
    set_surface_action_buttons();
}

/// Whether the lander's guidance (GNC) currently commands it: true while no
/// pilot holds the lander's `piloted` authority, () when it cannot be read.
fn gnc_connected() {
    let lander = find_path(lander_path());
    if lander == () || lander < 0 { return (); }
    let piloted = get(lander, "piloted");
    if piloted == () { return (); }
    piloted < 0.5
}

fn set_surface_action_buttons() {
    set_surface_action_buttons_for(gnc_connected())
}

/// `gnc` is the guidance state the GNC button offers to change.
fn set_surface_action_buttons_for(gnc) {
    let result = guided_hud_actions("griffin_surface_ops", "on_hud_action", [
        #{id: "unfold_ramps", label: "OPEN RAMPS  U", enabled: true},
        #{id: "release_rover", label: "DETACH ROVER  F", enabled: true},
        #{id: "toggle_gnc",
          label: if gnc == false { "RECONNECT GNC" } else { "DISCONNECT GNC" },
          enabled: gnc != ()}
    ]);
    if result == () || result.ok != true {
        let detail = if result == () || result.error == () { "unknown HUD action update rejection" } else { result.error };
        notify_kind("Griffin mission buttons could not be updated: " + detail, "error");
    }
    result
}

fn show_touchdown_actions() {
    show_briefing();
    hint("TOUCHDOWN CONFIRMED: U or OPEN RAMPS to lower both ramps. F detaches FLIP immediately.");
    set_surface_action_buttons();
}

fn show_ramp_unfolding_actions() {
    hint("RAMP UNFOLDING: middle sections, toes, then deck hinges. F remains available.");
    set_surface_action_buttons();
}

fn show_rover_release_actions() {
    hint("RAMPS SETTLED: F or DETACH ROVER detaches FLIP from the top deck.");
    set_surface_action_buttons();
}

fn show_rover_release_pending() {
    hint("ROVER RELEASE REQUESTED: waiting for the physics joint to retire.");
    set_surface_action_buttons();
}

fn clear_surface_operation_actions() {
    clear_guided_hud_actions()
}

fn show_rover_controls() {
    let forward = input_hint("forward");
    let backward = input_hint("backward");
    let left = input_hint("left");
    let right = input_hint("right");
    let action = input_hint("action");
    let cancel = input_hint("cancel");
    let steering_mode = rover_steering_mode_label();
    set_surface_action_buttons();
    hint("FLIP CONTROL: " + forward + "/" + backward + " drive · " + left + "/" + right + " steer · Space brake · " + cancel + " release");
    objectives_hud([
        #{ text: "FLIP is the active surface vehicle", state: "active" },
        #{ text: "Drive  " + forward + "/" + backward + "   Steer  " + left + "/" + right + "   Brake  Space", state: "active" },
        #{ text: "STEERING MODE  " + steering_mode + "  (CRAB = parallel / ACKERMANN = wheel geometry)", state: "active" },
        #{ text: "Stopped FLIP: toggle_rover_steering_mode() switches the vehicle once", state: "pending" },
        #{ text: action + " is reserved for the authored route; manual input takes control", state: "pending" },
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

// SimulateIntent is the controller-owned persistent hold used by the keyboard;
// the immediate SetPorts write closes the one-tick gap before the next control
// projection.  Both target the authored `brake` input and therefore use the
// generic mobility parking-brake boundary.  No autopilot-specific command is
// assumed: route ownership is explicit in the mission's AcquireControl step.
fn hold_rover_brake() {
    let target = resolve(rover_path(), "FLIP rover");
    if target == () { return #{ ok: false, error: "rover is unavailable" }; }
    let intent = cmd("SimulateIntent", #{ intent: "brake", held: true, target: target });
    if intent == () || intent.ok != true {
        return #{ ok: false, error: "controller rejected persistent brake intent" };
    }
    let result = cmd("SetPorts", #{
        target: target,
        writes: [["throttle", 0.0], ["steer", 0.0], ["brake", 1.0]],
    });
    if result.ok { notify_kind("FLIP brake held through the vehicle controller.", "info"); }
    result
}

fn release_rover_brake() {
    let target = resolve(rover_path(), "FLIP rover");
    if target == () { return #{ ok: false, error: "rover is unavailable" }; }
    let intent = cmd("SimulateIntent", #{ intent: "brake", held: false, target: target });
    if intent == () || intent.ok != true {
        return #{ ok: false, error: "controller rejected brake release" };
    }
    cmd("SetPorts", #{
        target: target,
        writes: [["throttle", 0.0], ["steer", 0.0], ["brake", 0.0]],
    })
}

// Configure FLIP's front steering actuators as one vehicle-level mode. The
// shared vehicle attribute selects Ackermann correction (1.0) for finite-turn
// motion or parallel front-wheel angles (0.0) for crab walk. Rear wheels remain
// straight in both modes.
//
// The steering mode is an authored assembly fact, not a physics-time command.
// Stop FLIP before changing it so the steering axes do not slew underneath a
// moving chassis, then use the Editor's typed ApplyUsdOp wrapper. The wrapper
// preserves the document generation and journal, so a later reload sees the
// same mode that the operator saw in Edit perspective.
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
    let viewport = assembly_edit::viewport();
    if viewport == () || viewport.focused_preview == () {
        notify_kind("FLIP steering mode needs a focused Editor preview.", "error");
        return #{ ok: false, error: "no focused Editor preview" };
    }
    let preview = ();
    for candidate in viewport.previews {
        if candidate.preview == viewport.focused_preview {
            preview = candidate;
            break;
        }
    }
    if preview == () || preview.doc_id == () || preview.edit_target == () {
        notify_kind("FLIP steering mode could not resolve the focused USD document.", "error");
        return #{ ok: false, error: "focused USD document is unavailable" };
    }
    let result = assembly_edit::attribute(preview.doc_id, preview.edit_target,
        rover_path(), "physxVehicleAckermannSteering:strength", "float",
        strength.to_string(), preview.projected_generation);
    if result == () || result.ok != true {
        let detail = if result == () { "typed Editor edit returned no result" } else { result.error };
        notify_kind("FLIP steering mode command was rejected: " + detail, "error");
        return #{ ok: false, error: detail };
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

// The authored surface mission reads its requested steering mode from SysML
// and verifies the corresponding authored assembly fact. The mission must not
// mutate USD while physics is running: Editor edits go through the typed
// ApplyUsdOp wrapper above, and this check makes a missing/stale scene fact a
// visible mission failure instead of silently selecting a numeric default.
fn configure_route_steering() {
    let mode = griffin_spec::route_steering_mode();
    if mode != "ackermann" && mode != "crab" {
        return #{ ok: false, error: "SysML missionSteeringMode must be ackermann or crab" };
    }
    let state = query("QueryUsdPrim", #{
        path: rover_path(),
        attrs: ["physxVehicleAckermannSteering:strength"]
    });
    if state == () || state.ok == false {
        return #{ ok: false, error: "authored route steering attribute is unavailable" };
    }
    let strength = state.attrs["physxVehicleAckermannSteering:strength"];
    let expected = if mode == "ackermann" { 1.0 } else { 0.0 };
    if strength == () || (strength - expected).abs() > 0.001 {
        return #{ ok: false, error: "authored route steering mode does not match SysML" };
    }
    let label = if mode == "ackermann" { "ACKERMANN" } else { "CRAB" };
    notify_kind("FLIP route steering verified: " + label, "info");
    #{ ok: true, mode: mode, strength: strength }
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
    let result = cmd("AcquireControl", #{ target: target, bind_camera: true });
    if result.ok {
        hint("LANDER CONTROL: " + input_hint("thrust") + " thrust · W/S pitch · A/D roll · Q/E yaw · F detach rover");
        notify_kind("Griffin lander under manual control.", "success");
    } else {
        notify_kind("Lander control was rejected: " + result.error, "error");
    }
    result
}

/// Disconnect GNC by taking manual possession of the lander (its `piloted`
/// authority makes the flight law ignore guidance commands), or reconnect it
/// by releasing that possession. Uses the existing control commands only.
fn toggle_gnc() {
    let connected = gnc_connected();
    if connected == () {
        notify_kind("Griffin GNC state is not readable from the active scene.", "error");
        return #{ok: false, error: "lander piloted authority is unavailable"};
    }
    let result = if connected { control_lander() } else { release_lander() };
    if result == () || result.ok != true {
        let detail = if result == () || result.error == () { "control command rejected" } else { result.error };
        return #{ok: false, error: detail};
    }
    if connected {
        notify_kind("Griffin GNC disconnected: manual flight.", "warning");
    } else {
        hint("GNC RECONNECTED: guidance commands the lander again.");
        notify_kind("Griffin GNC reconnected.", "success");
    }
    set_surface_action_buttons_for(!connected);
    #{ok: true, gnc_connected: !connected}
}

fn control_rover() {
    let target = resolve(rover_path(), "FLIP rover");
    if target == () { return; }
    let result = cmd("AcquireControl", #{ target: target, bind_camera: true });
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
    let source = resolve("/Griffin1SurfaceOps/Avatar", "local control avatar");
    if source == () { return #{ ok: false, error: "local control avatar is unavailable" }; }
    cmd("ReleaseControlSource", #{ source: source });
}

fn release_rover() {
    let source = resolve("/Griffin1SurfaceOps/Avatar", "local control avatar");
    if source == () { return #{ ok: false, error: "local control avatar is unavailable" }; }
    cmd("ReleaseControlSource", #{ source: source });
}

fn release_control() {
    let lander = release_lander();
    let rover = release_rover();
    hint("FREE FLIGHT: click Griffin or FLIP to take control; " + input_hint("cancel") + " releases control");
    #{ lander: lander, rover: rover }
}

fn toggle_rover_autopilot() {
    notify_kind("FLIP autopilot toggle is not a registered command; use the authored route task.", "error");
    #{ ok: false, error: "ToggleAutopilot is not a registered command" }
}

fn start_rover_autopilot() {
    notify_kind("FLIP autopilot start is not registered; use the authored route task.", "error");
    #{ ok: false, error: "StartAutopilot is not a registered command" }
}

fn stop_rover_autopilot() {
    notify_kind("FLIP autopilot stop is not registered; use the authored route task.", "error");
    #{ ok: false, error: "DisengageAutopilot is not a registered command" }
}
