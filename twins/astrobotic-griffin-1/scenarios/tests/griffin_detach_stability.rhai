// Twin-owned adapter-release regression.
//
// The test drives the authored delivery scene through touchdown, requests the
// generic DetachJoint verb once, and observes the physics-owned retirement.
// It deliberately does not assert wall-clock duration: solver timing depends
// on host hardware.  The timing samples are retained in the verdict as a
// diagnostic signal while topology invariants are the portable acceptance.

import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;

const ROOT = "/GriffinRoverDeliveryTest";
const LANDER = ROOT + "/Lander";
const DOCK = ROOT + "/PayloadDock";

fn simulation_dependencies(me,ctx) {
    #{modelica_entities:[find_path(LANDER),find_path(ROOT+"/Rover")],
      entity_reads:[find_path(LANDER),find_path(DOCK)],entity_writes:[find_path(DOCK)],
      query_reads:["PhysicsPerformance","AnalyzeSysml","ReadActiveTwinContract"],
      required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_name()}]}
}

fn on_start(me, ctx) {
    this.lander = find_path(LANDER);
    this.dock = find_path(DOCK);
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
    this.release_tick = ();
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
    performance
}

fn on_event(me, evt, ctx) {
    if evt.name != "lander_touchdown" || evt.source != this.lander || this.touchdown {
        return;
    }
    this.touchdown = true;
    this.dock = find_path(DOCK);
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

fn emit_release_verdict() {
    if this.finished { return; }
    let source = sysml_requirements::source();
    let post = this.post;
    let pre = this.pre;
    let has_post = post != ();
    // ECS joint counts are bounded by native entity capacity; convert the
    // unsigned API counters explicitly before signed integer arithmetic.
    let topology_ok = has_post
        && post.detach_requests == 0
        && post.pending_joints == 0
        && post.joints == post.joint_graph_edges
        && pre != ()
        && post.joints.to_int() + 1 == pre.joints.to_int()
        && post.entities <= pre.entities;
    let topology_observation = if has_post {
        topology_ok
    } else {
        #{provider: "physics_topology", state: "unavailable",
          detail: if this.failure == "" {
              "No post-release physics topology sample was produced"
          } else { this.failure }}
    };
    let checks = [sysml_requirements::constraint_check(
        "GR-026-release-evidence", "payload_adapter",
        "GriffinFunctionalRequirements::gr026",
        "GriffinFunctionalRequirements::Verify_GriffinAdapterRelease",
        "GriffinFunctionalRequirements::GR026_ReleaseEvidenceComplete",
        #{touchdownObserved: this.touchdown,
          detachAccepted: this.detach_requested,
          releaseTopologyValid: topology_observation},
        "derived", 0.0)];
    let report = sysml_requirements::evaluate(source, checks);
    report.metrics = #{
        clocks: clock_snapshot(),
        pre_release: pre,
        post_release: post,
        post_samples: this.post_samples,
        min_step_time_ms: this.min_step_ms,
        max_step_time_ms: this.max_step_ms,
        topology_invariants: topology_ok
    };
    report_structured_verdict(report, "GRIFFIN ADAPTER RELEASE", "GRIFFIN_ADAPTER_RELEASE");
    this.finished = true;
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
            let step_ms = performance.step_time_ms;
            if step_ms != () && step_ms.is_finite() {
                if step_ms > this.max_step_ms { this.max_step_ms = step_ms; }
                if step_ms < this.min_step_ms { this.min_step_ms = step_ms; }
            }
            if !this.detached {
                this.pre = performance;
            } else {
                this.post = performance;
                this.post_samples += 1;
            }
        }
    }
    if !this.detached && this.detach_requested && find_path(DOCK) < 0 {
        this.detached = true;
        print("[griffin-detach-stability] solver retirement observed");
    }
    if this.failed {
        this.emit_release_verdict();
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
        this.emit_release_verdict();
    }
}
