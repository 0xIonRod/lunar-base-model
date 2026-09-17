// Twin-owned adapter-release regression.
//
// The test drives the authored delivery scene through touchdown, requests the
// generic DetachJoint verb once, and observes the physics-owned retirement.
// It deliberately does not assert wall-clock duration: solver timing depends
// on host hardware.  The timing samples are retained in the verdict as a
// diagnostic signal while topology invariants are the portable acceptance.

const ROOT = "/GriffinRoverDeliveryTest";
const LANDER = ROOT + "/Lander";
const DOCK = ROOT + "/PayloadDock";

fn on_start(me, ctx) {
    this.lander = find(LANDER);
    this.dock = find(DOCK);
    this.start_tick = sim_tick();
    this.last_sample_tick = this.start_tick - 1;
    this.touchdown = false;
    this.detach_requested = false;
    this.detached = false;
    this.failed = false;
    this.failure = "";
    this.finished = false;
    this.pre = ();
    this.post = ();
    this.post_samples = 0;
    this.max_step_ms = 0.0;
    this.min_step_ms = 1.0e300;
    if this.lander < 0 {
        this.failed = true;
        this.failure = "delivery fixture did not resolve the lander";
        return;
    }
    subscribe_from("lander_touchdown", this.lander);
    print("[griffin-detach-stability] waiting for authored touchdown");
}

fn sample_performance() {
    let performance = query("PhysicsPerformance", #{});
    if performance == () || performance.ok == false {
        return ();
    }
    let step_ms = performance.step_time_ms;
    if step_ms != () && step_ms.is_finite() {
        if step_ms > this.max_step_ms { this.max_step_ms = step_ms; }
        if step_ms < this.min_step_ms { this.min_step_ms = step_ms; }
    }
    performance
}

fn on_event(me, evt, ctx) {
    if evt.name != "lander_touchdown" || evt.source != this.lander || this.touchdown {
        return;
    }
    this.touchdown = true;
    this.dock = find(DOCK);
    if this.dock < 0 {
        this.failed = true;
        this.failure = "touchdown arrived after the authored dock disappeared";
        return;
    }
    let result = cmd("DetachJoint", #{target: this.dock, intent: "Interactive"});
    if result == () || result.ok != true {
        this.failed = true;
        this.failure = if result == () || result.error == () {
            "DetachJoint was rejected"
        } else { result.error };
        return;
    }
    this.detach_requested = true;
    print("[griffin-detach-stability] detach accepted; waiting for topology retirement");
}

fn emit_verdict() {
    if this.finished { return; }
    this.finished = true;
    let source = sysml_requirements::source();
    let post = this.post;
    let pre = this.pre;
    let has_post = post != ();
    let topology_ok = has_post
        && post.detach_requests == 0
        && post.pending_joints == 0
        && post.joints == post.joint_graph_edges
        && pre != ()
        && post.joints + 1 == pre.joints
        && post.entities <= pre.entities;
    let checks = [
        #{id: "GR-026-touchdown", component: "payload_adapter", requirement: "Griffin1Requirements::gr026", verification: "Griffin1Requirements::Verify_GriffinAdapterRelease", kind: "lifecycle", path: LANDER, actual: this.touchdown, expected: true, ok: this.touchdown, error: "authored touchdown was not observed"},
        #{id: "GR-026-detach-request", component: "payload_adapter", requirement: "Griffin1Requirements::gr026", verification: "Griffin1Requirements::Verify_GriffinAdapterRelease", kind: "lifecycle", path: DOCK, actual: this.detach_requested, expected: true, ok: this.detach_requested, error: "detach request was not accepted"},
        #{id: "GR-026-topology", component: "payload_adapter", requirement: "Griffin1Requirements::gr026", verification: "Griffin1Requirements::Verify_GriffinAdapterRelease", kind: "topology", path: ROOT, actual: topology_ok, expected: true, ok: topology_ok, error: if this.failure == "" { "post-release topology did not retire exactly one edge" } else { this.failure }}
    ];
    let failures = [];
    for check in checks { if check.ok != true { failures.push(check); } }
    let report = #{
        ok: failures.len() == 0,
        verification: "Griffin1Requirements::Verify_GriffinAdapterRelease",
        requirement_count: checks.len(),
        source_revision: source.source_revision_hex,
        results: checks,
        failures: failures,
        metrics: #{
            clocks: clock_snapshot(),
            pre_release: pre,
            post_release: post,
            post_samples: this.post_samples,
            min_step_time_ms: this.min_step_ms,
            max_step_time_ms: this.max_step_ms,
            topology_invariants: topology_ok
        }
    };
    report_structured_verdict(report, "GRIFFIN ADAPTER RELEASE", "GRIFFIN_ADAPTER_RELEASE");
    print("[griffin-detach-stability] verdict=" + (if report.ok { "PASS" } else { "FAIL" })
        + " post_samples=" + this.post_samples + " max_step_ms=" + this.max_step_ms);
}

fn on_tick(me, ctx) {
    if this.finished { return; }
    let relative = sim_tick() - this.start_tick;
    // One diagnostic sample per ten fixed ticks is enough to expose a growing
    // solver/topology cost without turning the test itself into the workload.
    if relative > 0 && relative % 10 == 0 && sim_tick() != this.last_sample_tick {
        this.last_sample_tick = sim_tick();
        let performance = sample_performance();
        if performance != () {
            if !this.detached {
                this.pre = performance;
            } else {
                this.post = performance;
                this.post_samples += 1;
            }
        }
    }
    if !this.detached && this.detach_requested && find(DOCK) < 0 {
        this.detached = true;
        print("[griffin-detach-stability] solver retirement observed");
    }
    if this.failed {
        emit_verdict();
        return;
    }
    // Keep a post-release observation window long enough to catch a retained
    // request or graph edge, while remaining short for a repeatable CI gate.
    let release_tick = if this.detached { this.release_tick } else { () };
    if this.detached && release_tick == () {
        this.release_tick = sim_tick();
        release_tick = this.release_tick;
    }
    if this.detached && sim_tick() - release_tick >= 1800 {
        emit_verdict();
    }
}
