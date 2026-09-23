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

fn constraint_boundary_evidence(id, requirement, actual, expected, result,
                                expected_verdict) {
    #{id: id, requirement: requirement, kind: "sysml_constraint_boundary",
      actual: actual, expected: expected, verdict: result.verdict,
      expected_verdict: expected_verdict,
      ok: result.verdict == expected_verdict,
      constraint_result: result, verification: result.verification}
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

    // SysML owns the normative requirement and verification intent. The
    // shared Rust/Rhai evaluator executes its supported constraint subset;
    // this Twin script supplies observations and assembles evidence. The
    // remaining structural predicates are still Twin Rhai and are not yet a
    // generic typed USD-provider implementation.
    let sysml = report.sysml;
    // Provenance is a separate typed SysML catalog. Select one requirement ID
    // through the bounded native projection; the source/rationale/span arrive
    // as structured evidence without duplicating catalog-qualified literals in
    // the test.
    let provenance = sysml_requirements::provenance(sysml, "GR-005");
    let provenance_record = if provenance.ok == true { provenance.evidence } else { () };
    let provenance_source = if provenance.ok == true {
        provenance_record.source_reference
    } else { () };
    let provenance_rationale = if provenance.ok == true {
        provenance_record.rationale
    } else { () };
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
    failures.push(expected(provenance.ok == true
        && provenance_source != () && provenance_source != ""
        && provenance_rationale != () && provenance_rationale != "",
        "typed Griffin requirement provenance catalog is unavailable"));

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
    let constraint_evidence = [];
    let max_payload = griffin_requirements::max_payload_kg();
    let zero_payload = griffin_requirements::payload_load_check(0.0);
    failures.push(expected(zero_payload.verdict == "pass",
        "GR-009 payload limiter rejected the zero-load boundary"));
    constraint_evidence.push(constraint_boundary_evidence("GR-009-zero-payload",
        "GriffinFunctionalRequirements::gr009", 0.0, max_payload,
        zero_payload, "pass"));
    let at_capacity = griffin_requirements::payload_load_check(max_payload);
    failures.push(expected(at_capacity.verdict == "pass",
        "GR-009 payload limiter rejected the 625 kg boundary"));
    constraint_evidence.push(constraint_boundary_evidence("GR-009-at-capacity",
        "GriffinFunctionalRequirements::gr009", max_payload, max_payload,
        at_capacity, "pass"));
    let negative_payload = griffin_requirements::payload_load_check(-0.001);
    failures.push(expected(negative_payload.verdict == "fail",
        "GR-009 payload limiter accepted a negative payload"));
    constraint_evidence.push(constraint_boundary_evidence("GR-009-negative-payload",
        "GriffinFunctionalRequirements::gr009", -0.001, max_payload,
        negative_payload, "fail"));
    let over_capacity = griffin_requirements::payload_load_check(max_payload + 0.001);
    failures.push(expected(over_capacity.verdict == "fail",
        "GR-009 payload limiter accepted a load above 625 kg"));
    constraint_evidence.push(constraint_boundary_evidence("GR-009-over-capacity",
        "GriffinFunctionalRequirements::gr009", max_payload + 0.001, max_payload,
        over_capacity, "fail"));

    let max_ramp = griffin_requirements::max_ramp_command_rad();
    let at_negative_ramp_limit = griffin_requirements::ramp_command_check(-max_ramp);
    failures.push(expected(at_negative_ramp_limit.verdict == "pass",
        "GRR-005 ramp limiter rejected the negative SysML ramp boundary"));
    constraint_evidence.push(constraint_boundary_evidence("GRR-005-at-negative-limit",
        "GriffinRampRequirements::grr005", -max_ramp, max_ramp,
        at_negative_ramp_limit, "pass"));
    let at_ramp_limit = griffin_requirements::ramp_command_check(max_ramp);
    failures.push(expected(at_ramp_limit.verdict == "pass",
        "GRR-005 ramp limiter rejected the positive SysML ramp boundary"));
    constraint_evidence.push(constraint_boundary_evidence("GRR-005-at-positive-limit",
        "GriffinRampRequirements::grr005", max_ramp, max_ramp,
        at_ramp_limit, "pass"));
    let over_negative_ramp_limit = griffin_requirements::ramp_command_check(-max_ramp - 0.000001);
    failures.push(expected(over_negative_ramp_limit.verdict == "fail",
        "GRR-005 ramp limiter accepted a command below the SysML ramp limit"));
    constraint_evidence.push(constraint_boundary_evidence("GRR-005-below-limit",
        "GriffinRampRequirements::grr005", -max_ramp - 0.000001, max_ramp,
        over_negative_ramp_limit, "fail"));
    let over_ramp_limit = griffin_requirements::ramp_command_check(max_ramp + 0.000001);
    failures.push(expected(over_ramp_limit.verdict == "fail",
        "GRR-005 ramp limiter accepted a command above the SysML ramp limit"));
    constraint_evidence.push(constraint_boundary_evidence("GRR-005-above-limit",
        "GriffinRampRequirements::grr005", max_ramp + 0.000001, max_ramp,
        over_ramp_limit, "fail"));

    print("[griffin-requirements] structural_errors=" + report.structural.errors.len()
        + " catalogued_rules=" + report.catalogued_rules.len()
        + " source_constraint_results=" + constraint_evidence.len()
        + " parts=" + report.parts.len()
        + " assertions=" + failures.len());
    for rule in report.catalogued_rules {
        print("[griffin-requirements] " + rule + "=CATALOGUED_NOT_RUNTIME_VERDICT");
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
    this.rule_count = constraint_evidence.len();
    this.part_count = report.parts.len();
    this.planned_count = report.planned_rules.len();
    this.mission_scope_count = report.mission_scope_rules.len();
    this.process_gate_count = report.process_gate_rules.len();
    this.verdict = if failure_count == 0 { "PASS" } else { "FAIL" };
    // Preserve measurements and report results. A catalog entry is not a
    // runtime check and must not be emitted as a passing evidence row.
    let evidence_results = [
        #{id: "GR-structural-report", kind: "structural_report",
          ok: report.structural.ok, errors: report.structural.errors},
        #{id: "GR-relational-layout", kind: "layout_report",
          ok: report.layout.ok, findings: report.layout.findings}
    ];
    for result in constraint_evidence {
        evidence_results.push(result);
    }
    let provenance_evidence_id = if provenance.ok == true {
        provenance_record.requirement_id + "-provenance-catalog"
    } else { "provenance-catalog" };
    let provenance_requirement = if provenance.ok == true {
        provenance_record.qualified_requirement
    } else { "requirement-provenance" };
    evidence_results.push(#{id: provenance_evidence_id,
        component: "requirement-provenance",
        requirement: provenance_requirement,
        kind: "source", ok: provenance.ok == true
            && provenance_source != () && provenance_rationale != (),
        source_reference: provenance_source, rationale: provenance_rationale,
        source_span: if provenance.ok == true { provenance_record.source_span } else { () },
        verification: griffin_spec::verification_case_name()});
    for part in report.parts {
        part.verification = griffin_spec::verification_case_name();
        evidence_results.push(part);
    }
    // Keep verdict/evidence formatting in the generic test prelude. The Twin
    // owns observations and rule dispatch; the shared helper owns stable
    // PASS/FAIL output and machine-readable evidence.
    report_structured_verdict(#{ok: failure_count == 0, failures: failures,
        results: evidence_results,
        verification: griffin_spec::verification_case_name(),
        requirement_count: 2,
        source_files: sysml.source_files,
        source_revision: sysml.source_revision_hex},
        "GRIFFIN REQUIREMENTS", "GRIFFIN_REQUIREMENTS");
    this.done = true;
}
