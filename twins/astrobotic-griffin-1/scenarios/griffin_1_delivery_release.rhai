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

fn on_start(me, ctx) {
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

fn release_rover(me) {
    if !this.landed || this.released { return false; }
    this.dock = find(DOCK_PATH);
    if this.dock < 0 {
        // A prior command may already have retired the joint.  Treat the
        // observed topology as the authority and finish idempotently.
        this.released = true;
        return true;
    }

    let result = cmd("DetachJoint", #{
        target: this.dock,
        intent: "Interactive",
    });
    if result.ok != true {
        let detail = if result.error == () { "unknown DetachJoint rejection" } else { result.error };
        notify_kind("Rover release failed: " + detail, "error");
        print("[griffin-delivery] DetachJoint rejected: " + detail);
        return false;
    }

    this.released = true;
    emit("griffin_rover_release_requested");
    notify_kind("Rover release requested. Waiting for the physics joint to retire.", "info");
    print("[griffin-delivery] PayloadDock detach accepted; waiting for topology retirement");
    true
}

fn on_event(me, evt, ctx) {
    if evt.name == "lander_touchdown" && evt.source == this.lander {
        this.landed = true;
        if !this.landing_notice_sent {
            this.landing_notice_sent = true;
            emit("griffin_landed");
            notify_kind("Griffin touched down. Press G to release the rover.", "success");
            print("[griffin-delivery] touchdown event accepted from the lander model");
        }
        return;
    }

    // Release is an event edge, never a per-frame input poll.  The shared
    // controller emits the semantic edge; the key path remains available for
    // a human-owned lander during an ownership handoff.
    let request = false;
    if evt.name == "intent.edge" && evt.source == this.lander {
        let value = evt.value;
        request = value != () && value["target_gid"] == this.lander
            && value["intent"] == "release"
            && (value["edge"] == "pressed" || value["edge"] == "pulse");
    } else if evt.name == "key:KeyG" && owner_of(this.lander) == 0 {
        request = true;
    } else if evt.name == "cmd:SetPorts" && evt.source == this.lander {
        let transition = dock_release_edge(
            this.lander, this.release_was_high, true, this.released);
        this.release_was_high = transition.held;
        request = transition.fire;
    }
    if request { release_rover(me); }
}

fn task(me) {
    seq([
        // Touchdown is emitted by the composed lander Modelica supervisor
        // after its contact predicate; the mission does not infer landing from
        // a timer or overwrite a pose to make the gate pass.
        wait_for_from("lander_touchdown", LANDER_PATH),
        once(|m| {
            this.landed = true;
            if !this.landing_notice_sent {
                this.landing_notice_sent = true;
                emit("griffin_landed");
                notify_kind("Griffin touched down. Press G to release the rover.", "success");
            }
            true
        }),
        // Human or controller input is handled by on_event.  This wait keeps
        // the task causal without a production on_tick poll.
        wait_until(|m| this.released),
        wait_until(|m| find(DOCK_PATH) < 0),
        once(|m| {
            emit("griffin_rover_released");
            notify_kind("Rover released. Possess FLIP and drive it with the rover controls.", "success");
            print("[griffin-delivery] PayloadDock retired; rover is free to drive");
            true
        }),
    ])
}

fn on_stop(me, ctx) {
    print("[griffin-delivery] controller stopped");
}
