// Twin-owned Griffin structural and parameter contract test.
//
// This test deliberately has no terrain, rover mission, or descent timeline.
// It checks the composed lander wrapper itself, then exercises the pure payload
// and ramp limiters at both sides of their boundaries. The same linter is used
// against an open Editor document through griffin_requirements::lint_live().

import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;

const ROOT = "/GriffinRequirementsTest/Griffin1";
const VERIFICATION = "Verify_GriffinRequirements";

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

fn usd_observation_binding(observation, field, label) {
    if observation == () || observation.ok != true || observation[field] == () {
        return #{provider: "usd", state: "unavailable",
            detail: if observation == () || observation.detail == () {
                label + " composed observation is unavailable"
            } else { observation.detail }};
    }
    #{provider: "usd", state: "value", value: observation[field]}
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
    let report = griffin_requirements::runtime_report((), ROOT, VERIFICATION);
    let failures = [];
    for error in report.errors { failures.push(error); }

    // SysML owns the normative requirement and verification intent. The
    // shared Rust/Rhai evaluator executes its supported constraint subset;
    // this Twin script supplies observations and assembles evidence. The
    // remaining structural predicates are still Twin Rhai and are not yet a
    // generic typed USD-provider implementation.
    let sysml = report.sysml;
    // Provenance follows source-scoped SysML handles. The emitted evidence
    // retains the requirement handle and each typed source, rather than
    // copying target identities, locators, or rationale into parallel fields.
    let provenance = sysml_requirements::provenance(sysml,
        sysml.provenance_requirement_handle);
    let provenance_record = if provenance.ok == true { provenance.evidence } else { () };
    let provenance_sources = if provenance.ok == true { provenance_record.sources } else { [] };
    print("[griffin-requirements] sysml_ok=" + sysml.sysml_ok
        + " requirements=" + sysml.sysml_required_count
        + " verification_cases=" + sysml.sysml_verification_count
        + " verifies=" + sysml.sysml_verifies
        + " moonbase_requirements=" + sysml.sysml_general_required_count
        + " moonbase_verifies=" + sysml.sysml_general_verifies
        + " source_files=" + sysml.source_file_count
        + " source_revision=" + sysml.source_revision.to_string()
        + " missing=" + if sysml.sysml_missing.len() > 0 {
            sysml.sysml_missing[0]
        } else { "none" });
    let sysml_failure = if sysml.sysml_missing.len() > 0 {
        sysml.sysml_missing[0]
    } else { "source contract failed without a diagnostic" };
    failures.push(expected(sysml.ok == true && sysml.sysml_ok == true,
        "Griffin SysML requirement/verification source is not valid: " + sysml_failure));
    failures.push(expected(provenance.ok == true && provenance_sources.len() > 0,
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
    // Boundary tests make the limiter itself executable policy, not a helper
    // that exists only for a future UI. The limit comes from the typed SysML
    // snapshot; Rhai supplies only observations around that value.
    let constraint_evidence = [];

    // GR-018 evaluates physical deck collision facts from the same source mesh
    // and SysML deck datums as the visible octagon. Rhai reads and measures
    // composed USD; SysML owns the acceptance predicates and tolerance.
    let deck_requirement = sysml_requirements::source_with_selection([
        "GriffinMechanicalRequirements::GR018_HullAndDeck::topDeckProfileToleranceM"
    ], ["GriffinMechanicalRequirements::gr018"],
       ["Griffin1Requirements::Verify_GriffinRequirements"]);
    let deck_tolerance = if deck_requirement.ok == true {
        sysml_requirements::number(deck_requirement,
            "GriffinMechanicalRequirements::GR018_HullAndDeck::topDeckProfileToleranceM")
    } else { () };
    let deck_observation = griffin_visual_builder::physical_top_deck_collider_observation(
        (), ROOT);
    let deck_model = sysml_requirements::model();
    let deck_topology_constraint =
        "GriffinMechanicalRequirements::GRC018_TopDeckColliderTopologyMatchesSource";
    let deck_profile_constraint =
        "GriffinMechanicalRequirements::GRC018_TopDeckColliderProfileWithinTolerance";
    let deck_contact_constraint =
        "GriffinMechanicalRequirements::GRC018_TopDeckColliderOwnsContact";
    let deck_requirement_usage = deck_model.requirement(
        "GriffinMechanicalRequirements::gr018");
    let deck_tolerance_observation = if deck_tolerance == () {
        #{provider: "source_literal", state: "unavailable",
          detail: "GR-018 source tolerance is unavailable"}
    } else { #{provider: "source_literal", state: "value", value: deck_tolerance} };
    let deck_checks = [
        sysml_requirements::constraint_check("GR-018-source-topology", "lander",
            "gr018", VERIFICATION,
            deck_topology_constraint,
            sysml_requirements::required_constraint_input_observations(deck_model,
                deck_requirement_usage, deck_topology_constraint, [
                    ["topologyMatches", usd_observation_binding(deck_observation,
                        "topology_matches", "GR-018 topology")],
                    ["sourceGeometryLinked", usd_observation_binding(deck_observation,
                        "source_geometry_linked", "GR-018 typed geometry source")]]),
            "usd", 0.0),
        sysml_requirements::constraint_check("GR-018-source-profile", "lander",
            "gr018", VERIFICATION,
            deck_profile_constraint,
            sysml_requirements::required_constraint_input_observations(deck_model,
                deck_requirement_usage, deck_profile_constraint, [
                    ["profileDeviationM", usd_observation_binding(deck_observation,
                        "profile_deviation_m", "GR-018 profile deviation")],
                    ["toleranceM", deck_tolerance_observation]]), "usd", 0.0),
        sysml_requirements::constraint_check("GR-018-collision-role", "lander",
            "gr018", VERIFICATION,
            deck_contact_constraint,
            sysml_requirements::required_constraint_input_observations(deck_model,
                deck_requirement_usage, deck_contact_constraint, [
                    ["collisionEnabled", usd_observation_binding(deck_observation,
                        "collision_enabled", "GR-018 collision ownership")],
                    ["proxyHidden", usd_observation_binding(deck_observation,
                        "proxy_hidden", "GR-018 proxy visibility")],
                    ["convexHullApproximation", usd_observation_binding(deck_observation,
                        "convex_hull_approximation", "GR-018 collision approximation")]]),
            "usd", 0.0)
    ];
    let deck_constraint_report = if deck_requirement.ok == true {
        sysml_requirements::evaluate(deck_requirement, deck_checks)
    } else { #{ok: false, error: "GR-018 requirement source is unavailable", results: []} };
    for result in deck_constraint_report.results {
        failures.push(expected(result.verdict == "pass",
            "GR-018 physical deck collider constraint " + result.id
                + " returned " + result.verdict));
        constraint_evidence.push(result);
    }
    if deck_constraint_report.results == () || deck_constraint_report.results.len() != 3 {
        failures.push("GR-018 physical deck collider did not produce all three formal constraint results");
    }

    // The four dynamics legs use the same SysML foot-pad geometry as the
    // visible LandingLeg components. The generic evaluator applies the GLL-008
    // predicates; this Twin tool only binds composed geometry measurements.
    let pad_requirement = sysml_requirements::source_with_selection([
        "GriffinLandingLegRequirements::GriffinLandingLegAssembly::footPadRadiusM",
        "GriffinLandingLegRequirements::GriffinLandingLegAssembly::footPadHeightM",
        "GriffinLandingLegRequirements::GriffinLandingLegAssembly::footPadCenterYM",
        "GriffinLandingLegRequirements::GriffinLandingLegAssembly::physicalLegRotationToleranceDeg",
        "GriffinLandingLegRequirements::GriffinLandingLegAssembly::physicalLegPlacementToleranceM",
        "GriffinLandingLegRequirements::GriffinLandingLegAssembly::padColliderToleranceM",
        "GriffinLandingLegRequirements::GriffinLandingLegAssembly::bodyMountOverlapM",
        "GriffinLandingLegRequirements::GriffinLandingLegAssembly::bodyMountOverlapMeasurementToleranceM",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::legStations",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::legStationRotationYDeg"
    ], ["GriffinLandingLegRequirements::gll005",
        "GriffinLandingLegRequirements::gll008",
        "GriffinLandingLegRequirements::gll009"],
       ["GriffinLandingLegRequirements::Verify_GriffinLandingLegRequirements"]);
    let pad_tolerance = if pad_requirement.ok == true {
        sysml_requirements::number(pad_requirement,
            "GriffinLandingLegRequirements::GriffinLandingLegAssembly::padColliderToleranceM")
    } else { () };
    let station_tolerance = if pad_requirement.ok == true {
        sysml_requirements::number(pad_requirement,
            "GriffinLandingLegRequirements::GriffinLandingLegAssembly::physicalLegPlacementToleranceM")
    } else { () };
    let body_mount_overlap = if pad_requirement.ok == true {
        sysml_requirements::number(pad_requirement,
            "GriffinLandingLegRequirements::GriffinLandingLegAssembly::bodyMountOverlapM")
    } else { () };
    let body_mount_measurement_tolerance = if pad_requirement.ok == true {
        sysml_requirements::number(pad_requirement,
            "GriffinLandingLegRequirements::GriffinLandingLegAssembly::bodyMountOverlapMeasurementToleranceM")
    } else { () };
    let pad_observation = griffin_visual_builder::physical_landing_leg_pad_observation(
        (), ROOT);
    let pad_model = sysml_requirements::model();
    let pad_requirement_usage = pad_model.requirement(
        "GriffinLandingLegRequirements::gll008");
    let mount_requirement_usage = pad_model.requirement(
        "GriffinLandingLegRequirements::gll009");
    let pad_geometry_constraint =
        "GriffinLandingLegRequirements::GLLC008_PadColliderMatchesVisual";
    let pad_ownership_constraint =
        "GriffinLandingLegRequirements::GLLC008_PadColliderOwnsContact";
    let pad_station_constraint =
        "GriffinLandingLegRequirements::GLLC008_PadColliderStationMatchesSource";
    let mount_constraint =
        "GriffinLandingLegRequirements::GLLC009_BusAndAxleOverlap";
    let pad_tolerance_observation = if pad_tolerance == () {
        #{provider: "source_literal", state: "unavailable",
          detail: "GLL-008 source tolerance is unavailable"}
    } else { #{provider: "source_literal", state: "value", value: pad_tolerance} };
    let station_tolerance_observation = if station_tolerance == () {
        #{provider: "source_literal", state: "unavailable",
          detail: "GLL-008 physical station tolerance is unavailable"}
    } else { #{provider: "source_literal", state: "value", value: station_tolerance} };
    let mount_overlap_observation = if body_mount_overlap == () {
        #{provider: "source_literal", state: "unavailable",
          detail: "GLL-009 mount overlap requirement is unavailable"}
    } else { #{provider: "source_literal", state: "value", value: body_mount_overlap} };
    let pad_checks = [
        sysml_requirements::constraint_check("GLL-008-pad-geometry", "landing_leg",
            "gll008", "Verify_GriffinLandingLegRequirements",
            pad_geometry_constraint,
            sysml_requirements::required_constraint_input_observations(pad_model,
                pad_requirement_usage, pad_geometry_constraint, [
                    ["geometryDeviationM", usd_observation_binding(pad_observation,
                        "geometry_deviation_m", "GLL-008 pad geometry")],
                    ["sourceRadiusDeviationM", usd_observation_binding(pad_observation,
                        "source_radius_deviation_m", "GLL-008 visible pad radius")],
                    ["sourceHeightDeviationM", usd_observation_binding(pad_observation,
                        "source_height_deviation_m", "GLL-008 visible pad height")],
                    ["sourceCenterDeviationM", usd_observation_binding(pad_observation,
                        "source_center_deviation_m", "GLL-008 visible pad local center")],
                    ["padGeometrySemanticsMatch", usd_observation_binding(pad_observation,
                        "pad_geometry_semantics_match", "GLL-008 cylinder axis and transform")],
                    ["toleranceM", pad_tolerance_observation]]), "usd", 0.0),
        sysml_requirements::constraint_check("GLL-008-contact-ownership", "landing_leg",
            "gll008", "Verify_GriffinLandingLegRequirements",
            pad_ownership_constraint,
            sysml_requirements::required_constraint_input_observations(pad_model,
                pad_requirement_usage, pad_ownership_constraint, [
                    ["collisionEnabled", usd_observation_binding(pad_observation,
                        "collision_enabled", "GLL-008 contact ownership")],
                    ["proxyHidden", usd_observation_binding(pad_observation,
                        "proxy_hidden", "GLL-008 proxy visibility")],
                    ["visualCollisionDisabled", usd_observation_binding(pad_observation,
                        "visual_collision_disabled", "GLL-008 visual separation")],
                    ["collisionMatchesVisual", usd_observation_binding(pad_observation,
                        "collision_matches_visual", "GLL-008 collider correspondence")],
                    ["geometrySourceLinked", usd_observation_binding(pad_observation,
                        "source_relationships_valid", "GLL-008 typed geometry source")],
                    ["selfCollisionFilterClear", usd_observation_binding(pad_observation,
                        "self_collision_filter_clear", "GLL-008 compound-body collision filtering")],
                    ["legacyCollisionDisabled", usd_observation_binding(pad_observation,
                        "legacy_collision_disabled", "GLL-008 stale collider ownership")]]),
            "usd", 0.0),
        sysml_requirements::constraint_check("GLL-008-physical-stations", "landing_leg",
            "gll008", "Verify_GriffinLandingLegRequirements",
            pad_station_constraint,
            sysml_requirements::required_constraint_input_observations(pad_model,
                pad_requirement_usage, pad_station_constraint, [
                    ["stationDeviationM", usd_observation_binding(pad_observation,
                        "station_deviation_m", "GLL-008 COM-frame leg stations")],
                    ["toleranceM", station_tolerance_observation],
                    ["rotationMatches", usd_observation_binding(pad_observation,
                        "rotation_matches", "GLL-008 leg orientation")]]), "usd", 0.0),
        sysml_requirements::constraint_check("GLL-009-body-mount-path", "landing_leg",
            "gll009", "Verify_GriffinLandingLegRequirements",
            mount_constraint,
            sysml_requirements::required_constraint_input_observations(pad_model,
                mount_requirement_usage, mount_constraint, [
                    ["measuredBusOverlapM", usd_observation_binding(pad_observation,
                        "bus_mount_overlap_m", "GLL-009 leg arm to bus frame")],
                    ["measuredAxleOverlapM", usd_observation_binding(pad_observation,
                        "mount_axle_overlap_m", "GLL-009 leg arm to clevis axle")],
                    ["requiredOverlapM", mount_overlap_observation],
                    ["measurementToleranceM", if body_mount_measurement_tolerance == () {
                        #{provider: "source_literal", state: "unavailable",
                          detail: "GLL-009 overlap measurement tolerance is unavailable"}
                    } else { #{provider: "source_literal", state: "value",
                        value: body_mount_measurement_tolerance} }],
                    ["physicalJointStationMatches", usd_observation_binding(pad_observation,
                        "physical_joints_match", "GLL-009 physical attachment joints")]]),
            "usd", 0.0)
    ];
    let pad_constraint_report = if pad_requirement.ok == true {
        sysml_requirements::evaluate(pad_requirement, pad_checks)
    } else { #{ok: false, error: "GLL-008 requirement source is unavailable", results: []} };
    for result in pad_constraint_report.results {
        failures.push(expected(result.verdict == "pass",
            "GLL-008 physical leg pad constraint " + result.id
                + " returned " + result.verdict));
        constraint_evidence.push(result);
    }
    if pad_constraint_report.results == () || pad_constraint_report.results.len() != 4 {
        failures.push("GLL-008/GLL-009 physical leg criteria did not produce all four formal constraint results");
    }

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
        + " source_constraint_results=" + constraint_evidence.len()
        + " parts=" + report.parts.len()
        + " assertions=" + failures.len());
    let failure_count = 0;
    for failure in failures {
        if failure != "" { failure_count += 1; }
    }
    this.assertion_count = failures.len();
    this.failure_count = failure_count;
    this.failures = failures;
    this.rule_count = constraint_evidence.len();
    this.part_count = report.parts.len();
    this.verdict = if failure_count == 0 { "PASS" } else { "FAIL" };
    // Preserve measured requirement results; authored status labels are not
    // emitted as run evidence.
    let evidence_results = [
        #{id: "GR-structural-report", kind: "structural_report",
          ok: report.structural.ok, errors: report.structural.errors},
        #{id: "GR-relational-layout", kind: "layout_report",
          ok: report.layout.ok, findings: report.layout.findings}
    ];
    for result in constraint_evidence {
        evidence_results.push(result);
    }
    evidence_results.push(#{id: "GR-005-provenance-catalog",
        component: "requirement-provenance",
        requirement: if provenance.ok == true { provenance_record.requirement } else { () },
        kind: "source", ok: provenance.ok == true && provenance_sources.len() > 0,
        sources: provenance_sources,
        source_span: if provenance.ok == true { provenance_record.source_span } else { () },
        verification: sysml.sysml_verification_name});
    for part in report.parts {
        part.verification = sysml.sysml_verification_name;
        evidence_results.push(part);
    }
    // Keep verdict/evidence formatting in the generic test prelude. The Twin
    // owns observations and rule dispatch; the shared helper owns stable
    // PASS/FAIL output and machine-readable evidence.
    report_structured_verdict(#{ok: failure_count == 0, failures: failures,
        results: evidence_results,
        verification: sysml.sysml_verification_name,
        requirement_count: sysml.sysml_required_count,
        source_files: sysml.source_files,
        source_revision: sysml.source_revision},
        "GRIFFIN REQUIREMENTS", "GRIFFIN_REQUIREMENTS");
    this.done = true;
}
