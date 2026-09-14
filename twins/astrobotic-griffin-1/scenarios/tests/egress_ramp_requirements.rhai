// Standalone component test. Run it against an open component document in the
// existing headful process after the component plan has projected.

const ROOT = "/EgressRamp";

fn expected(ok, message) { if ok { "" } else { message } }

fn on_start(me) {
    this.start_elapsed = elapsed_seconds();
    this.elapsed = 0.0;
    this.done = false;
    print("[egress-ramp-test] waiting for composed component");
}

fn on_tick(me) {
    if this.done { return; }
    this.elapsed = elapsed_seconds() - this.start_elapsed;
    if this.elapsed < 0.1 { return; }

    // The host runner binds this test to the component document through the
    // explicit live doc id. The standalone lint remains read-only.
    let report = egress_ramp_requirements::lint((), ROOT);
    let failures = [];
    for finding in report.findings {
        failures.push(finding.path + ": " + finding.message);
    }
    let limit = egress_ramp_requirements::deployment_check(0.58, 0.58);
    failures.push(expected(limit.ok, "deployment limiter rejected its boundary"));
    let over = egress_ramp_requirements::deployment_check(0.580001, 0.58);
    failures.push(expected(!over.ok, "deployment limiter accepted an over-limit value"));
    let at_zero = egress_ramp_requirements::deployment_check(0.0, 0.58);
    failures.push(expected(at_zero.ok, "deployment limiter rejected zero angle"));

    let count = 0;
    for failure in failures { if failure != "" { count += 1; } }
    print("[egress-ramp-test] assertions=" + failures.len() + " failures=" + count);
    report_structured_verdict(#{ok: count == 0, failures: failures,
        results: report.findings},
        "EGRESS RAMP REQUIREMENTS", "EGRESS_RAMP_REQUIREMENTS");
    this.done = true;
}
