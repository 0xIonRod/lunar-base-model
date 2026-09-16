// Twin-owned Griffin structural and parameter contract test.
//
// This test deliberately has no terrain, rover mission, or descent timeline.
// It checks the composed lander wrapper itself, then exercises the pure payload
// and ramp limiters at both sides of their boundaries. The same linter is used
// against an open Editor document through griffin_requirements::lint_live().

const ROOT = "/GriffinRequirementsTest/Griffin1";

fn expected(ok, message) {
    if ok { "" } else { message }
}

fn on_start(me, ctx) {
    this.start_elapsed = elapsed_seconds();
    this.elapsed = 0.0;
    this.done = false;
    print("[griffin-requirements] waiting for composed Twin stage");
}

fn on_tick(me, ctx) {
    if this.done { return; }
    this.elapsed = elapsed_seconds() - this.start_elapsed;
    if this.elapsed < 0.1 { return; }
    let report = griffin_requirements::runtime_report((), ROOT);
    let failures = [];
    for error in report.errors { failures.push(error); }

    // SysML owns the normative requirement/verification intent. Rhai remains
    // the sole executable test backend: it consumes the generic validation
    // snapshot, selects the required definitions, and emits this verdict.
    let sysml = report.sysml;
    print("[griffin-requirements] sysml_ok=" + sysml.sysml_ok
        + " requirements=" + sysml.sysml_required_count
        + " verification_cases=" + sysml.sysml_verification_count
        + " verifies=" + sysml.sysml_verifies
        + " moonbase_requirements=" + sysml.sysml_general_required_count
        + " moonbase_verifies=" + sysml.sysml_general_verifies
        + " source_files=" + sysml.source_file_count
        + " source_revision=" + sysml.source_revision_hex
        + " missing=" + sysml.sysml_missing.len());
    failures.push(expected(sysml.ok == true && sysml.sysml_ok == true,
        "Griffin SysML requirement/verification source is not valid"));

    // Prove that every executable rule was dispatched, not just that one
    // aggregate boolean happened to be true.
    for rule in report.expected_rules {
        failures.push(expected(
            griffin_requirements::_has(report.checked_rules, rule),
            "runtime did not execute " + rule));
    }

    // Every manifest entry is an individual part test.
    for part in report.parts {
        failures.push(expected(part.ok, part.id + " part contract failed"));
    }
    failures.push(expected(report.layout.ok,
        "relational layout report contains findings"));

    let frame = griffin_spec::frame();
    failures.push(expected(frame.units == "metres" && frame.up_axis == "Y"
        && frame.root_datum == "Griffin1",
        "GR-007 frame policy is not the Griffin metres/Y-up contract"));
    failures.push(expected(griffin_spec::canonical_parts().len() > 0,
        "Griffin canonical part catalog is empty"));

    // Boundary tests make the limiter itself executable policy, not a helper
    // that exists only for a future UI. The limit comes from the typed SysML
    // snapshot; Rhai supplies only observations around that value.
    let max_payload = griffin_requirements::max_payload_kg();
    let zero_payload = griffin_requirements::payload_load_check(0.0, max_payload);
    failures.push(expected(zero_payload.ok,
        "GR-009 payload limiter rejected the zero-load boundary"));
    let at_capacity = griffin_requirements::payload_load_check(max_payload, max_payload);
    failures.push(expected(at_capacity.ok,
        "GR-009 payload limiter rejected the 625 kg boundary"));
    let negative_payload = griffin_requirements::payload_load_check(-0.001, max_payload);
    failures.push(expected(!negative_payload.ok,
        "GR-009 payload limiter accepted a negative payload"));
    let over_capacity = griffin_requirements::payload_load_check(max_payload + 0.001, max_payload);
    failures.push(expected(!over_capacity.ok,
        "GR-009 payload limiter accepted a load above 625 kg"));

    let max_ramp = griffin_requirements::max_ramp_command_rad();
    let at_negative_ramp_limit = griffin_requirements::ramp_command_check(-max_ramp);
    failures.push(expected(at_negative_ramp_limit.ok,
        "GR-011 ramp limiter rejected the negative SysML ramp boundary"));
    let at_ramp_limit = griffin_requirements::ramp_command_check(max_ramp);
    failures.push(expected(at_ramp_limit.ok,
        "GR-011 ramp limiter rejected the positive SysML ramp boundary"));
    let over_negative_ramp_limit = griffin_requirements::ramp_command_check(-max_ramp - 0.000001);
    failures.push(expected(!over_negative_ramp_limit.ok,
        "GR-011 ramp limiter accepted a command below the SysML ramp limit"));
    let over_ramp_limit = griffin_requirements::ramp_command_check(max_ramp + 0.000001);
    failures.push(expected(!over_ramp_limit.ok,
        "GR-011 ramp limiter accepted a command above the SysML ramp limit"));

    print("[griffin-requirements] structural_errors=" + report.structural.errors.len()
        + " rules=" + report.checked_rules.len()
        + " parts=" + report.parts.len()
        + " assertions=" + failures.len());
    for rule in report.checked_rules {
        print("[griffin-requirements] " + rule + "=PASS");
    }
    for rule in report.planned_rules {
        print("[griffin-requirements] " + rule + "=PLANNED_UNEXECUTED");
    }
    for rule in report.mission_scope_rules {
        print("[griffin-requirements] " + rule + "=MISSION_SCOPE");
    }
    for rule in report.process_gate_rules {
        print("[griffin-requirements] " + rule + "=PROCESS_GATE");
    }
    let failure_count = 0;
    for failure in failures {
        if failure != "" { failure_count += 1; }
    }
    this.assertion_count = failures.len();
    this.failure_count = failure_count;
    this.failures = failures;
    this.rule_count = report.checked_rules.len();
    this.part_count = report.parts.len();
    this.planned_count = report.planned_rules.len();
    this.mission_scope_count = report.mission_scope_rules.len();
    this.process_gate_count = report.process_gate_rules.len();
    this.verdict = if failure_count == 0 { "PASS" } else { "FAIL" };
    // Preserve structured evidence for every executed rule and every
    // component. Passing only `checked_rules` would discard the per-part
    // observations from the generic verdict envelope.
    let evidence_results = [];
    let verification_name = griffin_spec::verification_case_name();
    for rule in report.checked_rules {
        evidence_results.push(#{id: rule, kind: "runtime_rule", ok: true,
            verification: verification_name});
    }
    for part in report.parts {
        part.verification = verification_name;
        evidence_results.push(part);
    }
    // Keep verdict/evidence formatting in the generic test prelude. The Twin
    // owns observations and rule dispatch; the shared helper owns stable
    // PASS/FAIL output and machine-readable evidence.
    report_structured_verdict(#{ok: failure_count == 0, failures: failures,
        results: evidence_results, verification: verification_name,
        requirement_count: report.checked_rules.len(),
        source_files: sysml.source_files,
        source_revision: sysml.source_revision_hex},
        "GRIFFIN REQUIREMENTS", "GRIFFIN_REQUIREMENTS");
    this.done = true;
}
