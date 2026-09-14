// Griffin delivery controller.
//
// The control path is deliberately split at the authored boundary:
//   G -> LanderControls/release -> Modelica/OBC inputs:release
//     -> this Twin program -> generic DetachJoint -> PayloadDock
//
// This program owns the mission meaning of "release". Rust owns only the
// domain-neutral DetachJoint command. The rover remains on its authored
// control profile and can be possessed after the dock is released.

const ROOT = "/GriffinRoverDeliveryTest";
const LANDER_PATH = ROOT + "/Lander";
const ROVER_PATH = ROOT + "/Rover";
const DOCK_PATH = ROOT + "/PayloadDock";

fn input_port(target, name) {
    let record = query("ReadPorts", #{ api_id: target });
    if record == () || record.ports == () { return (); }
    for port in record.ports {
        if port.name == name && port.direction == "in" {
            return port.value;
        }
    }
    ()
}

fn output_port(target, name) {
    let record = query("ReadPorts", #{ api_id: target });
    if record == () || record.ports == () { return (); }
    for port in record.ports {
        if port.name == name && port.direction == "out" {
            return port.value;
        }
    }
    ()
}

fn on_start(me) {
    this.start_elapsed = elapsed_seconds();
    this.last_elapsed = this.start_elapsed;
    this.elapsed = 0.0;
    this.stable_time = 0.0;
    this.last_y = ();
    this.landed = false;
    this.released = false;
    this.release_was_high = false;
    this.landing_notice_sent = false;
    this.lander = find(LANDER_PATH);
    this.rover = find(ROVER_PATH);
    this.dock = find(DOCK_PATH);
    print("[griffin-delivery] lander=" + this.lander +
          " rover=" + this.rover + " dock=" + this.dock);
}

fn on_tick(me) {
    if this.released { return; }

    let now = elapsed_seconds();
    let delta = now - this.last_elapsed;
    if delta < 0.0 { delta = 0.0; }
    this.last_elapsed = now;
    this.elapsed = now - this.start_elapsed;
    if this.lander < 0 { this.lander = find(LANDER_PATH); }
    if this.rover < 0 { this.rover = find(ROVER_PATH); }
    if this.dock < 0 { this.dock = find(DOCK_PATH); }
    if this.lander < 0 || this.dock < 0 { return; }

    let pose = world_pos(this.lander);
    if pose == () { return; }

    // A landing is a stable low pose, not a timer or a teleport. Prefer the
    // live Modelica/physics velocity when it is exposed; the position delta is
    // the generic fallback for assets with no velocity telemetry.
    let velocity_y = output_port(this.lander, "velocity_y");
    let stable = pose[1] < 1.0;
    if velocity_y != () {
        stable = stable && velocity_y.abs() < 0.25;
    } else if this.last_y != () {
        stable = stable && (pose[1] - this.last_y).abs() < 0.01;
    }
    if stable { this.stable_time += delta; } else { this.stable_time = 0.0; }
    this.last_y = pose[1];

    if !this.landed && this.stable_time >= 0.5 {
        this.landed = true;
        if !this.landing_notice_sent {
            this.landing_notice_sent = true;
            emit("griffin_landed");
            notify_kind("Griffin touched down. Press G to release the rover.", "success");
            print("[griffin-delivery] landed at y=" + pose[1]);
        }
    }

    let release = input_port(this.lander, "release");
    if release == () { return; }
    let rising = release > 0.5 && !this.release_was_high;
    this.release_was_high = release > 0.5;
    if !this.landed || !rising { return; }

    let result = cmd("DetachJoint", #{
        target: this.dock,
        intent: "Interactive",
    });
    if !result.ok {
        notify_kind("Rover release failed: " + result.error, "error");
        print("[griffin-delivery] DetachJoint rejected: " + result.error);
        return;
    }

    this.released = true;
    emit("griffin_rover_released");
    notify_kind("Rover released. Possess FLIP and drive it with the rover controls.", "success");
    print("[griffin-delivery] PayloadDock detached; rover is free to drive");
}

fn on_stop(me) {
    print("[griffin-delivery] controller stopped");
}
