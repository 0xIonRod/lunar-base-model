import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
// Griffin-1 Twin requirements, lints, and live-edit gates.
//
// This is Twin policy, not a second USD reader. Every model fact comes from
// QueryUsdPrim, and every live edit goes through the typed USD command bus.
// Pass a numeric `doc_id` for an open Editor document; pass `()` for the one
// mounted runtime stage. The same functions therefore exercise the model in
// the headful Editor and in a Twin-owned scene test.
import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;

// Run this report explicitly from the Griffin requirements tool when doing a
// source review. It is not part of normal Twin startup or scene admission.
// The policy is a review choice, while the audit implementation and finding
// identities are shared by all SysML models. A missing formal predicate is
// informational here; this audit checks verification links but does not claim
// that any linked scenario or evidence procedure has run.
fn requirement_quality_audit() {
    let model = sysml_requirements::model();
    if model == () || !sysml_model_is(model) {
        return #{ok: false, error: "resolved Griffin SysML model is unavailable"};
    }
    let policy = engineering_review_requirement_audit_policy();
    let report = model.audit_requirements(policy);
    #{ok: !report.has_errors, source_revision: report.source_revision,
      source_fingerprint: report.source_fingerprint, findings: report.findings}
}

// Tool-library functions are used instead of top-level constants because the
// production static-module binding resolves names from function scope.
fn max_payload_kg() { griffin_spec::max_payload_kg() }
fn max_ramp_command_rad() { griffin_spec::max_ramp_command_rad() }
fn pi_value() { griffin_spec::pi_value() }
fn landing_leg_count() { griffin_spec::landing_leg_count() }
fn ramp_count() { griffin_spec::ramp_count() }
fn solar_array_count() { griffin_spec::solar_array_count() }

fn _sysml_number(report, name) {
    if report == () || report.ok != true { return (); }
    sysml_requirements::number(report, griffin_spec::qualified_attribute_name(name))
}

fn _sysml_text(report, name) {
    if report == () || report.ok != true { return (); }
    sysml_requirements::text(report, griffin_spec::qualified_attribute_name(name))
}

fn _sysml_list(report, name) {
    let qualified = griffin_spec::qualified_attribute_name(name);
    let items = sysml_requirement_checks::source_enum_identifiers(report, qualified);
    if items == () { return []; }
    items
}

// `compact=true` projects records to a flat qualified_name.  Keep this helper
// tolerant of the full ValidateSysml shape as well, so the Twin policy can be
// inspected with either projection without a second parser path.
fn _qualified(record) {
    if record == () { return ""; }
    if record.qualified_name != () { return record.qualified_name; }
    if record.element != () && record.element.qualified_name != () {
        return record.element.qualified_name;
    }
    ""
}

fn _short_name(name) {
    if name == () { return ""; }
    let parts = name.split("::");
    if parts.len() == 0 { return name; }
    parts[parts.len() - 1]
}

fn _verification_covers_usage(verification, requirement_name) {
    if verification == () || verification.verifies == () { return false; }
    for target in verification.verifies {
        if target == requirement_name
            || _short_name(target) == _short_name(requirement_name) {
            return true;
        }
    }
    false
}

// Read the normative SysML source through the shared bounded, typed source
// projection. The Rust parser/resolver owns the immutable source set; Griffin
// policy selects its acceptance checks and emits the verdict.
fn _sysml_contract_failure(report, fallback) {
    let missing = [];
    let error = fallback;
    if report != () && report.errors != () {
        for detail in report.errors { missing.push(detail); }
        if missing.len() > 0 { error = missing[0]; }
    }
    if missing.len() == 0 { missing.push(fallback); }
    #{ok: false, sysml_ok: false, error: error, sysml_missing: missing,
      kind: if report == () || report.kind == () { "sysml" } else { report.kind },
      path: if report == () { () } else { report.path },
      source_files: if report == () || report.source_files == () { [] } else { report.source_files },
      source_revision: if report == () { () } else { report.source_revision },
      sysml_required_count: 0, sysml_verification_count: 0, sysml_verifies: 0,
      sysml_general_required_count: 0, sysml_general_verifies: 0,
      sysml_visual_required_count: 0, sysml_visual_verifies: 0,
      sysml_visual_wheel_count: 0, sysml_visual_case_name: "",
      sysml_verification_name: ""}
}

fn sysml_contract_report(verification_name) {
    let name = twin_name();
    if name == "" {
        return _sysml_contract_failure((), "active Twin root is unavailable");
    }
    // source() pages the manifest-declared requirement and verification
    // identities through AnalyzeSysml and adds the active typed Twin contract.
    // Scalar literals remain lazy; this avoids transporting full source and
    // AST tables through Rhai on every runtime report.
    let report = sysml_requirements::source();
    if report == () {
        return _sysml_contract_failure((), "typed SysML source projection is unavailable");
    }
    if report.ok != true {
        return _sysml_contract_failure(report, "typed SysML source projection failed");
    }
    if report.kind != "sysml" {
        return _sysml_contract_failure(report,
            "Griffin requirement source is not classified as SysML");
    }
    let requirements = report.requirement_records;
    let verification_cases = report.verification_records;
    let missing = [];
    let verification = ();
    if verification_cases != () {
        for verification_case in verification_cases {
            let candidate_name = _qualified(verification_case);
            if candidate_name == verification_name
                || _short_name(candidate_name) == verification_name {
                if verification != () {
                    missing.push("verification identity is ambiguous: " + verification_name);
                    verification = ();
                    break;
                }
                verification = verification_case;
            }
        }
    }
    if report.verification_registry_errors != () {
        for error in report.verification_registry_errors {
            missing.push("Twin verification registry: " + error);
        }
    }
    let registry = report.verification_registry;
    if registry == () || registry.len() == 0 {
        missing.push("Twin verification registry is empty");
    } else if verification == () {
        missing.push("SysML verification case is missing: " + verification_name);
    } else {
        // Only the verification selected for this execution needs an
        // executable Twin mapping. Nested verification definitions remain
        // available for reuse inside another case without inventing a second
        // scene/script binding for each one.
        let expected_name = _qualified(verification);
        let found = 0;
        for binding in registry {
            if binding.name == expected_name {
                found += 1;
                if binding.scene == () || binding.script == ()
                    || binding.verdict_channel == () {
                    missing.push("incomplete Twin verification mapping " + expected_name);
                }
            }
        }
        if found != 1 {
            missing.push("executed SysML verification must have exactly one Twin mapping " + expected_name);
        }
    }
    if verification != () && verification.verifies == () {
        missing.push("executed SysML verification has no requirement links: "
            + _qualified(verification));
    }
    // The component→verification selection is a generic Rhai bridge over the
    // Twin manifest. Exercise it here so every component acceptance run proves
    // that its own requirement source and verification harness are resolvable;
    // the script does not duplicate scene or script paths.
    if report.components == () || report.components.len() == 0 {
        missing.push("Twin component registry is empty");
    } else {
        for component in report.components {
            let binding = sysml_requirements::component_binding(report, component.name);
            if binding.ok != true {
                let detail = if binding.error == () { "binding failed" } else { binding.error };
                missing.push("Twin component binding " + component.name + ": " + detail);
            } else if binding.verification.name != component.verification {
                missing.push("Twin component verification drift " + component.name);
            }
        }
    }
    let requirement_usages = 0;
    if requirements != () {
        for requirement in requirements {
            // Definitions (GR001_...) and usages (gr001) are both valid
            // SysML records. The verification case covers the Griffin usage
            // instances,
            // which are the stable instance-level contract for this gate.
            // Count only Griffin's instance usages.  Other Twin packages use
            // the same lowercase `gr...` naming convention (for example the
            // dedicated ramp package), but they have their own verification
            // declarations and must not inflate this Griffin count.
            let name = _qualified(requirement);
            for domain in ["GriffinFunctionalRequirements", "GriffinVisualRequirements",
                "GriffinMechanicalRequirements", "GriffinSimulationAccuracyRequirements",
                "GriffinAssuranceRequirements"] {
                if name.starts_with(domain + "::gr") {
                    requirement_usages += 1;
                    break;
                }
            }
        }
    }
    let griffin_coverage = 0;
    if verification != () && verification.verifies != () {
        for requirement in requirements {
            let name = _qualified(requirement);
            for domain in ["GriffinFunctionalRequirements", "GriffinVisualRequirements",
                "GriffinMechanicalRequirements", "GriffinSimulationAccuracyRequirements",
                "GriffinAssuranceRequirements"] {
                if name.starts_with(domain + "::gr") {
                    if _verification_covers_usage(verification, name) {
                        griffin_coverage += 1;
                    } else {
                        missing.push("verification does not cover SysML requirement " + name);
                    }
                    break;
                }
            }
        }
    }
    if verification == () || verification.verifies == ()
        || griffin_coverage != requirement_usages {
        missing.push("declared verification case covering all requirements");
    }
    for name in ["rampMaxDeploymentAngleRad", "mainEngineCount", "propellantTankCount", "landingVehicleReferenceTouchdownY"] {
        if _sysml_number(report, name) == () {
            missing.push("typed SysML attribute " + name);
        }
    }
    // Short names may intentionally collide across component packages.  The
    // accessors above resolve each canonical value to its owning qualified
    // SysML name; do not reject a valid composed source merely because a
    // different component reuses a local attribute name.
    // Source-backed creation facts are checked separately from the active
    // USD proxy. This prevents an inherited/default value from making a model
    // look Griffin-compatible when the public architecture has drifted.
    for name in ["payloadCapacityKg", "landingLegCount", "mainEngineCount",
        "propellantTankCount", "rampCount", "solarArrayCount",
        "flipPayloadCapacityKg", "landingVehicleReferenceTouchdownY",
        "rampSurfaceLengthM", "rampSurfaceThicknessM",
        "physicalRampTerrainContactToleranceM",
        "physicalRampMassKg", "physicalRampInertiaXKgM2",
        "physicalRampInertiaYKgM2", "physicalRampInertiaZKgM2",
        "physicalRampDeckTransitionMassKg", "physicalRampDeckTransitionLengthM",
        "physicalRampDeckTransitionRequiredOverlapM",
        "physicalRampDeckTransitionInterfaceToleranceM"] {
        let actual = _sysml_number(report, name);
        if actual == () || actual <= 0.0 {
            missing.push("positive typed SysML fact " + name);
        }
    }
    let transition_length = _sysml_number(report, "physicalRampDeckTransitionLengthM");
    let transition_overlap = _sysml_number(report,
        "physicalRampDeckTransitionRequiredOverlapM");
    if transition_length != () && transition_overlap != ()
        && transition_overlap >= transition_length {
        missing.push("required physical deck overlap must be less than the transition length");
    }
    // Instance identities cross the SysML/Rhai boundary only as typed
    // enumeration literals.  Their enum definitions live with the visual
    // configuration; this package owns counts and mission dimensions.
    let cargo_lower_bound = _sysml_number(report, "cargoMassLowerBoundKg");
    let cargo_bound_exclusive = sysml_requirements::boolean(report,
        griffin_spec::qualified_attribute_name("cargoMassLowerBoundIsExclusive"));
    if cargo_lower_bound == () || cargo_lower_bound != 499.0
        || cargo_bound_exclusive != true {
        missing.push("public cargo lower bound must remain the exclusive 499 kg threshold");
    }
    let egress_mode = _sysml_text(report, "egressMode");
    if egress_mode != () && !egress_mode.contains("direct top-deck") {
        missing.push("FLIP egress mode must retain the public direct top-deck path");
    }
    let array_mode = _sysml_text(report, "solarArrayMode");
    if array_mode != () && !array_mode.contains("collapsible") {
        missing.push("FLIP solar-array concept must remain collapsible in the source record");
    }
    if griffin_spec::solar_array_names().len() != griffin_spec::solar_array_count() {
        missing.push("solar-array identity list/count mismatch in SysML");
    }
    if griffin_spec::landing_leg_names().len() != griffin_spec::landing_leg_count() {
        missing.push("landing-leg identity/count mismatch in typed SysML configuration");
    }
    if griffin_spec::ramp_names().len() != griffin_spec::ramp_hinge_names().len()
        || griffin_spec::ramp_names().len() != griffin_spec::ramp_count() {
        missing.push("ramp/hinge identity list/count mismatch in SysML");
    }
    if griffin_spec::propellant_tank_names().len() != griffin_spec::propellant_tank_count() {
        missing.push("propellant-tank identity list/count mismatch in SysML");
    }
    if griffin_spec::main_engine_names().len() != griffin_spec::main_engine_count() {
        missing.push("main-engine identity list/count mismatch in SysML");
    }
    let wheel_names = griffin_spec::rover_wheel_station_names();
    if wheel_names.len() == 0
        || griffin_spec::rover_wheel_station_x().len() != wheel_names.len()
        || griffin_spec::rover_wheel_station_y().len() != wheel_names.len()
        || griffin_spec::rover_wheel_station_z().len() != wheel_names.len() {
        missing.push("typed FLIP wheel stations and metric datums must have matching cardinality");
    }
    let transition_inertia = griffin_spec::physical_ramp_deck_transition_inertia_kg_m2();
    if transition_inertia.len() != 3 {
        missing.push("physical deck transition inertia must have three values in SysML");
    }
    if griffin_spec::physical_ramp_transition_joint_name_prefix() == () {
        missing.push("physical deck transition joint identity is missing in SysML");
    }
    let route_names = griffin_spec::surface_route_marker_names();
    let route_speeds = griffin_spec::surface_route_speed_mps();
    let route_radii = griffin_spec::surface_route_arrival_radius_m();
    if route_names.len() == 0 || route_speeds.len() != route_names.len()
        || route_radii.len() != route_names.len() {
        missing.push("surface route marker/speed/radius cardinality mismatch in SysML");
    } else {
        for i in 0..route_names.len() {
            if route_speeds[i] <= 0.0 || route_radii[i] <= 0.0 {
                missing.push("surface route speed/radius must be positive in SysML");
                break;
            }
        }
    }
    let general_requirements = [];
    if report.requirement_records != () {
        for requirement in report.requirement_records {
            if _qualified(requirement).starts_with("MoonBaseProjectRequirements::mb") {
                general_requirements.push(requirement);
            }
        }
    }
    let general_count = general_requirements.len();
    let general_case = ();
    let general_case_ambiguous = false;
    if verification_cases != () && general_count > 0 {
        for verification_case in verification_cases {
            if verification_case.verifies == () { continue; }
            let covers_project = true;
            for requirement in general_requirements {
                let covered = false;
                for target in verification_case.verifies {
                    if _short_name(target) == _short_name(requirement.qualified_name) {
                        covered = true;
                        break;
                    }
                }
                if !covered { covers_project = false; break; }
            }
            if covers_project {
                if general_case != () {
                    general_case_ambiguous = true;
                    break;
                }
                general_case = verification_case;
            }
        }
    }
    if general_case == () || general_case_ambiguous || general_case.verifies == () {
        missing.push("Moon Base project SysML verification case does not cover all project requirements");
    }
    // MB-001/MB-002 are executable source checks, not just coverage rows:
    // every geometry and simulation datum must remain SI, and the composed
    // USD frame must stay metre/Y-up. These values are read from the general
    // project source that the Twin manifest includes alongside Griffin facts.
    let unit_system = _sysml_text(report, "unitSystem");
    let length_unit = _sysml_text(report, "lengthUnit");
    let mass_unit = _sysml_text(report, "massUnit");
    let angle_unit = _sysml_text(report, "angleUnit");
    let time_unit = _sysml_text(report, "timeUnit");
    let project_up_axis = _sysml_text(report, "frameUpAxis");
    let meters_per_unit = _sysml_number(report, "metersPerUnit");
    if unit_system != "SI metric" || length_unit != "metres"
        || mass_unit != "kilograms" || angle_unit != "radians"
        || time_unit != "seconds" {
        missing.push("Moon Base project MB-001 SI unit contract");
    }
    if project_up_axis != "Y" || meters_per_unit == ()
        || (meters_per_unit - 1.0).abs() > 0.000001 {
        missing.push("Moon Base project MB-002 metre/Y-up frame contract");
    }
    let visual_usages = [];
    if requirements != () {
        for requirement in requirements {
            if _qualified(requirement).starts_with("GriffinVisualRequirements::gv") {
                visual_usages.push(_qualified(requirement));
            }
        }
    }
    let visual_case = ();
    if verification_cases != () {
        for verification_case in verification_cases {
            if _qualified(verification_case)
                == "GriffinVisualRequirements::Verify_GriffinVisualRequirements" {
                visual_case = verification_case;
                break;
            }
        }
    }
    let visual_coverage_ok = visual_case != () && visual_case.verifies != ()
        && visual_case.verifies.len() == visual_usages.len();
    if visual_coverage_ok {
        for name in visual_usages {
            if !_verification_covers_usage(visual_case, name) {
                visual_coverage_ok = false;
                break;
            }
        }
    }
    if !visual_coverage_ok {
        missing.push("Griffin visual verification case does not cover all visual requirements");
    }
    let visual_configuration_usages = [];
    if requirements != () {
        for requirement in requirements {
            if _qualified(requirement).starts_with(
                "GriffinVisualConfigurationRequirements::gvc") {
                visual_configuration_usages.push(_qualified(requirement));
            }
        }
    }
    let visual_configuration_case = ();
    if verification_cases != () {
        for verification_case in verification_cases {
            if _qualified(verification_case)
                == "GriffinVisualConfigurationRequirements::Verify_GriffinVisualConfiguration" {
                visual_configuration_case = verification_case;
                break;
            }
        }
    }
    let visual_configuration_coverage_ok = visual_configuration_case != ()
        && visual_configuration_case.verifies != ()
        && visual_configuration_case.verifies.len() == visual_configuration_usages.len();
    if visual_configuration_coverage_ok {
        for name in visual_configuration_usages {
            if !_verification_covers_usage(visual_configuration_case, name) {
                visual_configuration_coverage_ok = false;
                break;
            }
        }
    }
    if !visual_configuration_coverage_ok {
        missing.push("Griffin visual configuration verification case does not cover all configuration requirements");
    }
    for name in ["reviewCameraName", "reviewLanderName"] {
        let text = _sysml_text(report, name);
        if text == () || text == "" {
            missing.push("typed visual component identity is missing " + name);
        }
    }
    for name in ["visualLanderDeckWidthM", "wheelRadiusM",
        "landingSitePadExtentM", "visualReviewGroundWidthM"] {
        let value = _sysml_number(report, name);
        if value == () || value <= 0.0 {
            missing.push("positive visual SysML datum " + name);
        }
    }
    if report.source_revision == () {
        missing.push("non-zero SysML source revision");
    }
    report.sysml_required_count = requirement_usages;
    report.sysml_verification_count = if verification_cases == () { 0 } else { verification_cases.len() };
    report.sysml_verifies = if verification == () { 0 } else { verification.verifies.len() };
    report.sysml_general_required_count = if general_count == () { 0 } else { general_count };
    report.sysml_general_verifies = if general_case == () || general_case_ambiguous {
        0
    // The integrated verifier also covers Griffin requirements; report only
    // the project-baseline subset here.
    } else { general_count };
    report.sysml_visual_required_count = visual_usages.len();
    report.sysml_visual_verifies = if visual_case == () || visual_case.verifies == () {
        0
    } else { visual_case.verifies.len() };
    report.sysml_visual_wheel_count = visual_wheel_count;
    report.sysml_visual_case_name = if visual_case == () { "" } else { _qualified(visual_case) };
    report.sysml_verification_name = if verification == () { "" } else { _qualified(verification) };
    let provenance_handle = sysml_requirements::requirement_handle_by_short_name(
        report, "GR-005");
    report.provenance_requirement_handle = if provenance_handle.ok == true {
        provenance_handle.handle
    } else { () };
    report.sysml_missing = missing;
    report.sysml_ok = missing.len() == 0;
    if !report.sysml_ok {
        report.ok = false;
        report.error = "required Griffin SysML definitions are missing";
    }
    report
}

fn _query(doc_id, path, attrs, rels, children) {
    let request = #{ path: path };
    if doc_id != () { request.doc_id = doc_id; }
    if attrs != () { request.attrs = attrs; }
    if rels != () { request.rels = rels; }
    if children != () { request.children = children; }
    query("QueryUsdPrim", request)
}

// Schema projection is intentionally opt-in. Most requirement checks need only
// a few authored values; this narrow helper asks for applied APIs only where a
// topology contract depends on them, keeping the hot query path small.
fn _query_schemas(doc_id, path, attrs, rels, children) {
    let request = #{ path: path, schemas: true };
    if doc_id != () { request.doc_id = doc_id; }
    if attrs != () { request.attrs = attrs; }
    if rels != () { request.rels = rels; }
    if children != () { request.children = children; }
    query("QueryUsdPrim", request)
}

// One composed geometry observation carries schema, geometry bounds, collision
// bounds, and optional cooked Avian collider geometry.
fn _query_geometry(doc_id, path, attrs, rels, exact_collision_geometry) {
    let request = #{path: path, schemas: true, geometry_bounds: true,
        collision_bounds: true};
    if doc_id != () { request.doc_id = doc_id; }
    if attrs != () { request.attrs = attrs; }
    if rels != () { request.rels = rels; }
    if exact_collision_geometry == true { request.collision_geometry = true; }
    query("QueryUsdPrim", request)
}

fn _bounds_deviation(a, b) {
    if a == () || b == () || a.frame != "canonical_stage"
        || b.frame != "canonical_stage" { return (); }
    let maximum = 0.0;
    for key in ["min", "max", "center", "half_extents"] {
        let left = a[key];
        let right = b[key];
        if left == () || right == () || left.len() != 3 || right.len() != 3 {
            return ();
        }
        for axis in 0..3 {
            let delta = (left[axis] - right[axis]).abs();
            if delta > maximum { maximum = delta; }
        }
    }
    maximum
}

fn _vector_max_deviation(a, b) {
    if a == () || b == () || a.len() != b.len() { return (); }
    let maximum = 0.0;
    for index in 0..a.len() {
        let delta = (a[index] - b[index]).abs();
        if delta > maximum { maximum = delta; }
    }
    maximum
}

fn _transform_or_identity(attrs, name, identity) {
    let value = attrs[name];
    if value == () { return identity; }
    if value.len() != identity.len() { return (); }
    value
}

fn _maximum_value(a, b) { if a > b { a } else { b } }

fn _constraint_result_failure(result) {
    if result.ok == true { return ""; }
    if result.error != () { return result.error; }
    result.id + " verdict: " + result.verdict
}

fn _evaluation_failure(evaluation, fallback) {
    if evaluation.error != () { return evaluation.error; }
    fallback
}

fn _distance3(a, b) {
    let x = a[0] - b[0];
    let y = a[1] - b[1];
    let z = a[2] - b[2];
    (x * x + y * y + z * z).sqrt()
}

fn _source_value(value, source) {
    let revision = if source == () { () } else { source.source_revision };
    #{provider: "source_literal",
      state: if value == () { "unavailable" } else { "value" },
      value: value, source_revision: revision,
      provider_generation: revision}
}

fn _usd_value(value) {
    #{provider: "usd",
      state: if value == () { "unavailable" } else { "value" },
      value: value}
}

fn _usd_snapshot_value(value, observation) {
    #{provider: "usd",
      state: if value == () { "unavailable" } else { "value" },
      value: value, doc_id: observation.doc_id,
      document_generation: observation.document_generation,
      stage_generation: observation.stage_generation}
}

fn _derived_snapshot_value(value, observation) {
    #{provider: "derived",
      state: if value == () { "unavailable" } else { "value" },
      value: value, provider_generation: observation.stage_generation,
      document_id: if observation.doc_id == () { () }
          else { "usd:" + observation.doc_id },
      document_generation: observation.document_generation}
}

fn _ok(record) {
    record != () && record.ok != false && record.path != ()
}

fn _has(values, expected) {
    if values == () { return false; }
    for value in values {
        if value == expected { return true; }
    }
    false
}

fn _relationship(record, name) {
    if !_ok(record) || record.relationships == ()
        || record.relationships[name] == ()
        || record.relationships[name].len() != 1 {
        return ();
    }
    record.relationships[name][0]
}

fn _finding(id, path, message) {
    #{ id: id, severity: "error", path: path, message: message }
}

// Generic assembly-audit primitives. The Griffin manifest below supplies the
// Twin-specific part names and known values; these checks deliberately know
// nothing about Griffin so the same helpers can be reused by another Twin.
fn _visible(record) {
    _ok(record) && record.attrs["visibility"] != "invisible"
}

fn _geometry_type(type_name) {
    _has(["Mesh", "Cube", "Cylinder", "Cone", "Sphere", "Capsule",
          "NurbsPatch", "Points", "BasisCurves"], type_name)
}

fn _near(a, b, tolerance) {
    (a - b).abs() <= tolerance
}

fn _horizontal_radius_squared(position) {
    if position == () || position.len() < 3 { return -1.0; }
    position[0] * position[0] + position[2] * position[2]
}

fn _layout_query(doc_id, path, attrs, children) {
    _query(doc_id, path, attrs, (), children)
}

// Geometry-aware query used by the visual gate. The ordinary layout query is
// intentionally cheap and only proves authored topology; it must not be used
// as evidence that a component has the right metric envelope.
fn _layout_finding(id, path, message) {
    _finding(id, path, message)
}

// Check the authored landing target and collision pad against one source
// revision and one composed USD snapshot. The SysML constraints own both
// datums; this policy only binds source literals and measured USD geometry.
fn landing_setup_geometry_check(doc_id, target_path, pad_path) {
    let source = sysml_requirements::source();
    if source == () || source.ok != true {
        return #{ok: false,
            error: "typed SysML source is unavailable for the landing setup constraints",
            landing_target: #{ok: false, path: target_path,
                error: "typed SysML source is unavailable"},
            landing_surface: #{ok: false, path: pad_path,
                error: "typed SysML source is unavailable"}};
    }
    let expected_target_y = sysml_requirements::number(source,
        griffin_spec::qualified_attribute_name("landingVehicleReferenceTouchdownY"));
    let target_tolerance = sysml_requirements::number(source,
        griffin_spec::qualified_attribute_name("landingTargetDatumToleranceM"));
    let surface_y = sysml_requirements::number(source,
        griffin_spec::qualified_attribute_name("siteSurfaceY"));
    let pad_extent = sysml_requirements::number(source,
        griffin_spec::qualified_attribute_name("landingSitePadExtentM"));
    let pad_thickness = sysml_requirements::number(source,
        griffin_spec::qualified_attribute_name("landingSitePadThicknessM"));
    let surface_tolerance = sysml_requirements::number(source,
        griffin_spec::qualified_attribute_name("landingSurfaceDatumToleranceM"));
    if expected_target_y == () || target_tolerance == () || surface_y == ()
        || pad_extent == () || pad_thickness == () || surface_tolerance == () {
        return #{ok: false, error: "landing setup datums are incomplete in the SysML source"};
    }
    let request = #{paths: [target_path, pad_path], schemas: true,
        attrs: ["xformOp:translate", "xformOp:scale", "size",
            "physics:collisionEnabled"]};
    if doc_id != () { request.doc_id = doc_id; }
    let snapshot = query("QueryUsdPrims", request);
    if snapshot == () || snapshot.ok == false {
        let detail = if snapshot == () {
            "QueryUsdPrims returned no response"
        } else if snapshot.error == () {
            "QueryUsdPrims failed without a provider diagnostic"
        } else { snapshot.error };
        return #{ok: false, error: detail,
            landing_target: #{ok: false, path: target_path, error: detail},
            landing_surface: #{ok: false, path: pad_path, error: detail}};
    }
    if snapshot.records == () || snapshot.records.len() != 2 {
        let detail = if snapshot.records == () {
            "QueryUsdPrims succeeded without a records array"
        } else {
            "QueryUsdPrims returned " + snapshot.records.len()
                + " records for the two requested landing setup prims"
        };
        return #{ok: false, error: detail,
            landing_target: #{ok: false, path: target_path, error: detail},
            landing_surface: #{ok: false, path: pad_path, error: detail}};
    }
    let target = snapshot.records[0];
    let pad = snapshot.records[1];
    let target_position = target.attrs["xformOp:translate"];
    let pad_center = pad.attrs["xformOp:translate"];
    let pad_scale = pad.attrs["xformOp:scale"];
    let cube_size = pad.attrs["size"];
    if target.path != target_path || pad.path != pad_path
        || target_position == () || target_position.len() != 3
        || pad_center == () || pad_center.len() != 3
        || pad_scale == () || pad_scale.len() != 3 || cube_size == ()
        || cube_size <= 0.0 {
        return #{ok: false, error: "landing target or pad has incomplete composed geometry",
            landing_target: #{ok: false, path: target_path,
                error: "landing target has no composed three-axis translate"},
            landing_surface: #{ok: false, path: pad_path,
                error: "landing pad has no complete composed cube geometry"}};
    }
    let actual_pad_half_extent_x = (pad_scale[0] * cube_size * 0.5).abs();
    let actual_pad_half_extent_y = (pad_scale[1] * cube_size * 0.5).abs();
    let actual_pad_half_extent_z = (pad_scale[2] * cube_size * 0.5).abs();
    let actual_pad_top_y = pad_center[1] + actual_pad_half_extent_y;
    let collision_enabled = pad.attrs["physics:collisionEnabled"] == true;
    let collision_schema = pad.api_schemas != ()
        && _has(pad.api_schemas, "PhysicsCollisionAPI");

    let target_constraint = sysml_requirements::required_constraint_check(
        "GR-037-landing-target-datum", "lander", "gr037",
        "Verify_GriffinSurfaceOperations",
        "GriffinSimulationAccuracyRequirements::GR037_LandingTargetDatumMatchesSource",
        #{authoredTargetY: _usd_snapshot_value(target_position[1], target),
          sourceTargetY: _source_value(expected_target_y, source),
          toleranceM: _source_value(target_tolerance, source)}, "typed", 0.0);
    let surface_constraint = sysml_requirements::required_constraint_check(
        "GR-038-landing-surface-datum", "lander", "gr038",
        "Verify_GriffinSurfaceOperations",
        "GriffinSimulationAccuracyRequirements::GR038_LandingSurfaceContainsTargetOnTerrainPlane",
        #{authoredPadTopY: _derived_snapshot_value(actual_pad_top_y, pad),
          sourceSurfaceY: _source_value(surface_y, source),
          padCenterX: _usd_snapshot_value(pad_center[0], pad),
          padCenterZ: _usd_snapshot_value(pad_center[2], pad),
          targetX: _usd_snapshot_value(target_position[0], target),
          targetZ: _usd_snapshot_value(target_position[2], target),
          actualPadHalfExtentX: _derived_snapshot_value(actual_pad_half_extent_x, pad),
          actualPadHalfExtentZ: _derived_snapshot_value(actual_pad_half_extent_z, pad),
          requiredPadHalfExtentM: _source_value(pad_extent, source),
          actualPadThicknessM: _derived_snapshot_value(
              actual_pad_half_extent_y * 2.0, pad),
          requiredPadThicknessM: _source_value(pad_thickness, source),
          toleranceM: _source_value(surface_tolerance, source)}, "typed", 0.0);
    let evaluation = sysml_requirements::evaluate(source,
        [target_constraint, surface_constraint]);
    if evaluation == () || evaluation.results == ()
        || evaluation.results.len() != 2 {
        return #{ok: false,
            error: "SysML landing setup constraints did not produce two results",
            landing_target: #{ok: false, path: target_path,
                error: "GR-037 constraint evaluation failed"},
            landing_surface: #{ok: false, path: pad_path,
                error: "GR-038 constraint evaluation failed"}};
    }
    let target_result = evaluation.results[0];
    let surface_result = evaluation.results[1];
    let shape_valid = pad.type_name == "Cube" && collision_enabled && collision_schema;
    let surface_ok = surface_result.ok == true && shape_valid;
    let target_ok = target_result.ok == true;
    let detail = "";
    if !target_ok { detail = _constraint_result_failure(target_result); }
    if surface_result.ok != true {
        if detail != "" { detail += "; "; }
        detail += _constraint_result_failure(surface_result);
    }
    if !shape_valid {
        if detail != "" { detail += "; "; }
        detail += "landing pad is not a colliding Cube with PhysicsCollisionAPI";
    }
    #{ok: target_ok && surface_ok,
      error: if target_ok && surface_ok { "" } else { detail },
      source_revision: source.source_revision,
      source_files: source.source_files,
      target_y_m: target_position[1],
      pad_top_y_m: actual_pad_top_y,
      pad_center: pad_center,
      pad_half_extents_m: [actual_pad_half_extent_x,
          actual_pad_half_extent_y, actual_pad_half_extent_z],
      pad_collision_enabled: collision_enabled,
      landing_target: #{ok: target_ok, path: target_path,
          expected_y: expected_target_y, actual_y: target_position[1],
          tolerance: target_tolerance, constraint: target_result,
          error: _constraint_result_failure(target_result)},
      landing_surface: #{ok: surface_ok, path: pad_path,
          expected_surface_y: surface_y, actual_pad_top_y: actual_pad_top_y,
          expected_half_extent_m: pad_extent,
          expected_thickness_m: pad_thickness,
          target_position: target_position,
          collision_enabled: collision_enabled,
          collision_schema: collision_schema,
          constraint: surface_result,
          error: if surface_ok { "" }
              else if surface_result.ok != true {
                  _constraint_result_failure(surface_result)
              } else { "landing pad is not a colliding Cube" }}}
}

// Visual-only wrappers are not always spawned by the isolated headless
// requirements fixture. Layout checks must use the authored local datum so
// gravity/contact cannot turn a static geometry assertion into a flaky result;
// the resolved world pose is only a fallback for references without a local
// translate opinion. This is still a typed USD read; it never invents a
// placement.
fn _position(record) {
    if record == () { return (); }
    if record.attrs != () {
        let local = record.attrs["xformOp:translate"];
        if local != () && local.len() == 3 { return local; }
    }
    let world = record.world_position;
    if world != () && world.len() == 3 { return world; }
    ()
}

// A relationship between a parent and a nested child must use resolved stage
// coordinates.  The landing-pad wrappers intentionally publish a local offset
// relative to each leg, so comparing their local xformOp:translate values
// would report a false "inboard" failure.  QueryUsdPrim owns this resolved
// value; missing world pose is an evidence failure, not a reason to fall back
// to an unrelated local frame.
fn _world_position(record) {
    if record == () { return (); }
    let world = record.world_position;
    if world != () && world.len() == 3 { return world; }
    ()
}

// Layout contracts describe the authored assembly, not a body after gravity
// or contact dynamics have moved it. Prefer the explicit local datum when it
// exists; fall back to the resolved pose for references that do not publish a
// local translate opinion.
fn _authored_position(record) {
    if record != () && record.attrs != () {
        let local = record.attrs["xformOp:translate"];
        if local != () && local.len() == 3 { return local; }
    }
    _position(record)
}

fn _pair_mirror_check(findings, rule, left_path, left, right_path, right,
    axis, label) {
    if !_ok(left) || !_ok(right) { return; }
    let a = _authored_position(left);
    let b = _authored_position(right);
    if a == () || b == () || a.len() != 3 || b.len() != 3 { return; }
    if axis == "X" {
        if !_near(a[0], -b[0], 0.02) || !_near(a[1], b[1], 0.02)
            || !_near(a[2], b[2], 0.02) {
            findings.push(_layout_finding(rule, left_path,
                label + " must mirror " + right_path + " across the X=0 plane"));
        }
    }
    if axis == "Z" {
        if !_near(a[2], -b[2], 0.02) || !_near(a[1], b[1], 0.02)
            || !_near(a[0], b[0], 0.02) {
            findings.push(_layout_finding(rule, left_path,
                label + " must mirror " + right_path + " across the Z=0 plane"));
        }
    }
}

fn _solar_layout_report(doc_id, root) {
    let findings = [];
    let names = griffin_spec::solar_array_names();
    let expected = solar_array_count();
    if expected == () || names.len() != expected {
        findings.push(_layout_finding("GR-016", root,
            "solar-array identities do not match the Griffin-1 required count"));
    }
    if names.len() == 0 {
        findings.push(_layout_finding("GR-016", root,
            "no solar-array component identities are configured"));
        return findings;
    }
    for name in names {
        let path = root + "/" + name;
        let panel = _layout_query(doc_id, path,
            ["visibility", "xformOp:translate", "xformOp:rotateXYZ"], true);
        if !_ok(panel) {
            findings.push(_layout_finding("GR-016", path,
                "configured solar-array component is missing from the composed stage"));
            continue;
        }
        if !_visible(panel) {
            findings.push(_layout_finding("GR-016", path,
                "required solar panel is hidden"));
        }
        if !_has(panel.children, path + "/Cells") {
            findings.push(_layout_finding("GR-016", path,
                "solar panel must contain its named Cells geometry"));
        }
    }
    // This generic layout check intentionally does not infer the Sun-facing
    // quadrant from a render pose. That mission constraint needs the approved
    // Griffin-1 installation datums and a time-tagged Sun-direction provider.
    findings
}

fn _ramp_layout_report(doc_id, root) {
    let findings = [];
    let names = griffin_spec::ramp_names();
    let expected = ramp_count();
    if names.len() != 2 || expected != names.len() {
        findings.push(_layout_finding("GR-017", root,
            "SysML ramp identity list must contain exactly two names"));
        return findings;
    }
    let port_path = root + "/" + names[0];
    let starboard_path = root + "/" + names[1];
    let port = _layout_query(doc_id, port_path,
        ["xformOp:translate", "xformOp:rotateXYZ", "lunco:deployment_angle_rad"], true);
    let starboard = _layout_query(doc_id, starboard_path,
        ["xformOp:translate", "xformOp:rotateXYZ", "lunco:deployment_angle_rad"], true);
    if !_ok(port) || !_ok(starboard) {
        return findings;
    }
    _pair_mirror_check(findings, "GR-017", port_path, port,
        starboard_path, starboard, "X", "egress ramps");
    let port_pos = _authored_position(port);
    let starboard_pos = _authored_position(starboard);
    if port_pos == () || starboard_pos == ()
        || port_pos.len() != 3 || starboard_pos.len() != 3 {
        findings.push(_layout_finding("GR-017", root,
            "ramp world placement is unavailable in the composed stage"));
        return findings;
    }
    if port_pos[0] <= 0.0 || starboard_pos[0] >= 0.0
        || !_near(port_pos[2], 0.0, 0.02)
        || !_near(starboard_pos[2], 0.0, 0.02) {
        findings.push(_layout_finding("GR-017", root,
            "port/starboard ramps must be opposite side ramps on the X axis"));
    }
    let port_rot = port.attrs["xformOp:rotateXYZ"];
    let starboard_rot = starboard.attrs["xformOp:rotateXYZ"];
    if port_rot != () && starboard_rot != () {
        if !_near(port_rot[0], 0.0, 0.02) || !_near(port_rot[1], 0.0, 0.02)
            || !_near(starboard_rot[0], 0.0, 0.02)
            || (!_near(starboard_rot[1], 0.0, 0.02)
                && !_near(starboard_rot[1], 180.0, 0.02))
            || !_near(port_rot[2], -starboard_rot[2], 0.02) {
            findings.push(_layout_finding("GR-017", root,
                "ramp rotations must mirror about the Z hinge axis"));
        }
    }
    let port_angle = port.attrs["lunco:deployment_angle_rad"];
    let starboard_angle = starboard.attrs["lunco:deployment_angle_rad"];
    if port_angle != () && starboard_angle != () {
        if !_near(port_angle, -starboard_angle, 0.002) {
            findings.push(_layout_finding("GR-017", root,
                "ramp deployment metadata must be equal and opposite"));
        }
        if port_rot != () && !_near(port_rot[2] * pi_value() / 180.0,
            port_angle, 0.02) {
            findings.push(_layout_finding("GR-017", port_path,
                "ramp transform rotation and deployment metadata disagree"));
        }
        if starboard_rot != () && !_near(starboard_rot[2] * pi_value() / 180.0,
            starboard_angle, 0.02) {
            findings.push(_layout_finding("GR-017", starboard_path,
                "ramp transform rotation and deployment metadata disagree"));
        }
    }
    if !_has(port.children, port_path + "/RampTrackPort")
        || !_has(port.children, port_path + "/RampTrackStarboard")
        || !_has(starboard.children, starboard_path + "/RampTrackPort")
        || !_has(starboard.children, starboard_path + "/RampTrackStarboard") {
        findings.push(_layout_finding("GR-017", root,
            "each ramp must contain both source-aligned FLIP wheel tracks"));
    }
    findings
}

fn _body_collider_observation(doc_id, root) {
    let body_path = root + "/GriffinBody/BodyCollisionProxy";
    let body = _query_geometry(doc_id, body_path,
        ["size", "xformOp:scale", "physics:collisionEnabled", "visibility", "purpose"],
        (), true);
    if !_ok(body) { return body; }
    let collision = body.collision_geometry;
    let bounds = body.collision_bounds;
    body.collisionEnabled = _has(body.api_schemas, "PhysicsCollisionAPI")
        && body.attrs["physics:collisionEnabled"] == true;
    body.cookedCubeHull = collision != () && collision.type_name == "Cube"
        && collision.shape == "convex_hull" && collision.frame == "canonical_stage"
        && collision.vertices != () && collision.vertices.len() == 8;
    body.exactCanonicalBounds = bounds != () && bounds.fidelity == "exact"
        && bounds.frame == "canonical_stage";
    body
}

fn _body_shape_report(doc_id, root) {
    let findings = [];
    let body_path = root + "/GriffinBody/BodyCollisionProxy";
    let deck_path = root + "/RoverPayloadDeckCollider";
    let body = _body_collider_observation(doc_id, root);
    if !_ok(body) {
        findings.push(_layout_finding("GR-018", body_path,
            "flight-body collision proxy is missing"));
    } else {
        if body.type_name != "Cube" {
            findings.push(_layout_finding("GR-018", body_path,
                "flight-body proxy must be a Cube collider"));
        }
        let scale = body.attrs["xformOp:scale"];
        let size = body.attrs["size"];
        if scale == () || scale.len() != 3 || size == () || size <= 0.0 {
            findings.push(_layout_finding("GR-018", body_path,
                "flight-body proxy needs positive three-axis dimensions"));
        } else {
            if scale[0].abs() * size <= 0.0 || scale[1].abs() * size <= 0.0
                || scale[2].abs() * size <= 0.0 {
                findings.push(_layout_finding("GR-018", body_path,
                    "flight-body collider must have a positive envelope"));
            }
        }
        if body.attrs["physics:collisionEnabled"] != true {
            findings.push(_layout_finding("GR-018", body_path,
                "flight-body proxy must own an enabled collider"));
        }
        if body.attrs["visibility"] != "invisible" || body.attrs["purpose"] != "proxy" {
            findings.push(_layout_finding("GR-018", body_path,
                "flight-body collider must be hidden proxy geometry"));
        }
        if body.collisionEnabled != true || body.cookedCubeHull != true
            || body.exactCanonicalBounds != true {
            findings.push(_layout_finding("GR-018", body_path,
                "flight-body Cube must read back as an exact eight-vertex Avian hull in canonical-stage coordinates"));
        }
    }
    let deck = griffin_visual_builder::physical_top_deck_collider_observation(doc_id, root);
    if deck.ok != true || deck.state != "pass" {
        findings.push(_layout_finding("GR-018", deck_path,
            "open octagonal perimeter and rover platform colliders do not match the SysML source readback"));
    }
    for old in ["BoxyAirframe", "IsogridDeck"] {
        let path = root + "/" + old;
        let obsolete = _layout_query(doc_id, path, [], false);
        if _ok(obsolete) {
            findings.push(_layout_finding("GR-018", path,
                "obsolete visible body/deck assembly must be removed"));
        }
    }
    #{findings: findings, collider_observation: body}
}

fn _tank_layout_report(doc_id, root) {
    let findings = [];
    let names = griffin_spec::propellant_tank_names();
    let expected = griffin_spec::propellant_tank_count();
    let stations = griffin_spec::component_tank_stations();
    let scales = griffin_spec::component_tank_scale();
    if names.len() != 4 || expected != names.len()
        || stations.len() != names.len() || scales.len() != names.len() {
        findings.push(_layout_finding("GR-033", root,
            "SysML tank identities, stations, and scales must contain four entries"));
        return findings;
    }
    let records = [];
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        let record = _layout_query(doc_id, path,
            ["visibility", "xformOp:translate", "xformOp:scale"], false);
        records.push(record);
        if !_ok(record) {
            findings.push(_layout_finding("GR-033", path,
                "required source-owned propellant tank is missing"));
            continue;
        }
        if !_visible(record) {
            findings.push(_layout_finding("GR-033", path,
                "all four Griffin propellant tanks must be visible"));
        }
        if record.type_name != "Xform"
            || !_ok(_layout_query(doc_id, path + "/MliTank", [], false))
            || !_ok(_layout_query(doc_id, path + "/TankBandA", [], false)) {
            findings.push(_layout_finding("GR-033", path,
                "tank must compose the maintained vessel and band geometry"));
        }
        let position = record.attrs["xformOp:translate"];
        let scale = record.attrs["xformOp:scale"];
        if position == () || position.len() != 3 || scale == () || scale.len() != 3
            || !_near(position[0], stations[index].x, 0.002)
            || !_near(position[1], stations[index].y, 0.002)
            || !_near(position[2], stations[index].z, 0.002)
            || !_near(scale[0], scales[index], 0.002)
            || !_near(scale[1], scales[index], 0.002)
            || !_near(scale[2], scales[index], 0.002) {
            findings.push(_layout_finding("GR-033", path,
                "tank placement and scale must match the ordered SysML station"));
        }
    }
    if _ok(records[0]) && _ok(records[1]) {
        _pair_mirror_check(findings, "GR-033", root + "/TankPX", records[0],
            root + "/TankNX", records[1], "X", "X-axis propellant tanks");
    }
    if _ok(records[2]) && _ok(records[3]) {
        _pair_mirror_check(findings, "GR-033", root + "/TankPZ", records[2],
            root + "/TankNZ", records[3], "Z", "Z-axis propellant tanks");
    }
    findings
}

fn _engine_layout_report(doc_id, root) {
    let findings = [];
    let cluster_path = root + "/Nozzle/MainEngineCluster";
    let cluster = _layout_query(doc_id, cluster_path, [], true);
    if !_ok(cluster) {
        findings.push(_layout_finding("GR-032", cluster_path,
            "seven-engine visual cluster is missing"));
        return findings;
    }
    if cluster.type_name != "Xform" {
        findings.push(_layout_finding("GR-032", cluster_path,
            "main engine cluster must be an Xform"));
    }
    let engine_count = 0;
    for name in griffin_spec::main_engine_names() {
        let path = cluster_path + "/" + name;
        let engine = _layout_query(doc_id, path, [], false);
        if !_ok(engine) {
            findings.push(_layout_finding("GR-032", path,
                "required referenced main engine assembly is missing"));
            continue;
        }
        engine_count += 1;
        if engine.type_name != "Xform" {
            findings.push(_layout_finding("GR-032", path,
                "main engine reference must compose as an Xform assembly"));
        }
        let bell_path = path + "/Bell";
        let bell = _layout_query(doc_id, bell_path,
            ["visibility", "radius1", "radius2", "height", "physics:collisionEnabled"], false);
        if !_ok(bell) {
            findings.push(_layout_finding("GR-032", bell_path,
                "referenced main engine bell geometry is missing"));
            continue;
        }
        if bell.type_name != "Cone" || !_visible(bell)
            || bell.attrs["radius1"] == () || bell.attrs["radius1"] <= 0.0
            || bell.attrs["radius2"] == () || bell.attrs["radius2"] <= 0.0
            || bell.attrs["height"] == () || bell.attrs["height"] <= 0.0 {
            findings.push(_layout_finding("GR-032", bell_path,
                "each main engine must be a visible positive Cone bell"));
        }
        if bell.attrs["physics:collisionEnabled"] == true {
            findings.push(_layout_finding("GR-032", bell_path,
                "engine visual bell must not own a collider"));
        }
    }
    if engine_count != griffin_spec::main_engine_count() {
        findings.push(_layout_finding("GR-032", cluster_path,
            "main-engine bell count disagrees with the SysML source"));
    }
    findings
}

fn _leg_layout_report(doc_id, root) {
    let findings = [];
    let names = griffin_spec::landing_leg_names();
    let expected_rotations = griffin_spec::component_leg_station_rotation_y_deg();
    let expected = landing_leg_count();
    if names.len() != 4 || expected != names.len()
        || expected_rotations.len() != names.len() {
        findings.push(_layout_finding("GR-019", root,
            "typed SysML landing-leg and radial-orientation lists must contain four entries"));
        return findings;
    }
    let legs = [];
    for name in names {
        legs.push(_layout_query(doc_id, root + "/" + name,
            ["xformOp:translate", "xformOp:rotateXYZ", "physics:mass"], true));
    }
    for i in 0..legs.len() {
        let leg = legs[i];
        let path = root + "/" + names[i];
        if !_ok(leg) { continue; }
        let pos = _authored_position(leg);
        if pos == () || pos.len() != 3 { continue; }
        let dynamic_pos = _world_position(leg);
        if dynamic_pos == () || dynamic_pos.len() != 3 {
            findings.push(_layout_finding("GR-019", path,
                "resolved world position is required for leg-to-pad placement"));
            continue;
        }
        if i == 0 && (pos[0] <= 0.0 || !_near(pos[2], 0.0, 0.02)) {
            findings.push(_layout_finding("GR-019", path, "LegPX must attach on +X"));
        }
        if i == 1 && (pos[0] >= 0.0 || !_near(pos[2], 0.0, 0.02)) {
            findings.push(_layout_finding("GR-019", path, "LegNX must attach on -X"));
        }
        if i == 2 && (pos[2] <= 0.0 || !_near(pos[0], 0.0, 0.02)) {
            findings.push(_layout_finding("GR-019", path, "LegPZ must attach on +Z"));
        }
        if i == 3 && (pos[2] >= 0.0 || !_near(pos[0], 0.0, 0.02)) {
            findings.push(_layout_finding("GR-019", path, "LegNZ must attach on -Z"));
        }
        let rotation = leg.attrs["xformOp:rotateXYZ"];
        if rotation == () || rotation.len() != 3 {
            findings.push(_layout_finding("GR-019", path,
                "landing leg radial orientation must publish xformOp:rotateXYZ"));
        } else if !_near(rotation[1], expected_rotations[i], 0.02) {
            findings.push(_layout_finding("GR-019", path,
                "landing leg Y rotation disagrees with the SysML radial orientation datum"));
        }
        let pad_path = path + "/LandingLegVisual/FootPadCollider";
        let pad = _layout_query(doc_id, pad_path,
            ["axis", "radius", "height", "physics:collisionEnabled",
             "xformOp:translate"], false);
        if !_ok(pad) { continue; }
        let pad_pos = _world_position(pad);
        if pad_pos == () || pad_pos.len() != 3 {
            findings.push(_layout_finding("GR-019", pad_path,
                "resolved world position is required for leg-to-pad placement"));
            continue;
        }
        if pad_pos[1] >= dynamic_pos[1] {
            findings.push(_layout_finding("GR-019", pad_path,
                "foot pad must be below its leg attachment"));
        }
        if pad.attrs["axis"] != "Y" || pad.attrs["radius"] == ()
            || pad.attrs["radius"] <= 0.0 || pad.attrs["height"] == ()
            || pad.attrs["height"] <= 0.0 {
            findings.push(_layout_finding("GR-019", pad_path,
                "foot pad needs a positive Y-axis cylindrical contact shape"));
        }
        if pad.attrs["physics:collisionEnabled"] != true {
            findings.push(_layout_finding("GR-019", pad_path,
                "foot pad must keep collision enabled"));
        }
    }
    if _ok(legs[0]) && _ok(legs[1]) {
        _pair_mirror_check(findings, "GR-019", root + "/LegPX", legs[0],
            root + "/LegNX", legs[1], "X", "X-axis landing legs");
    }
    if _ok(legs[2]) && _ok(legs[3]) {
        _pair_mirror_check(findings, "GR-019", root + "/LegPZ", legs[2],
            root + "/LegNZ", legs[3], "Z", "Z-axis landing legs");
    }
    if _ok(legs[0]) && _ok(legs[2]) {
        let px = _horizontal_radius_squared(_authored_position(legs[0]));
        let pz = _horizontal_radius_squared(_authored_position(legs[2]));
        if !_near(px, pz, 0.05) {
            findings.push(_layout_finding("GR-019", root,
                "all four leg attachment points must share one radial body datum"));
        }
    }
    findings
}

fn _legacy_visibility_report(doc_id, root) {
    let findings = [];
    // These are obsolete source/proxy prims. They must be removed from the
    // Griffin composition, not merely hidden, so a later consumer cannot
    // accidentally reactivate a second body.
    for name in ["SolarWingPX", "SolarWingNX",
                 "Hull", "UpperDeck",
                 "LandingLegFrontPort", "LandingLegRearPort",
                 "LandingLegFrontStarboard", "LandingLegRearStarboard",
                 "SolidLegFrontPort", "SolidLegRearPort",
                 "SolidLegFrontStarboard", "SolidLegRearStarboard",
                 "SolidFootFrontPort", "SolidFootRearPort",
                 "SolidFootFrontStarboard", "SolidFootRearStarboard"] {
        let path = root + "/" + name;
        let record = _layout_query(doc_id, path, ["visibility"], false);
        if _ok(record) {
            findings.push(_layout_finding("GR-020", path,
                "obsolete comparison/proxy geometry must be deleted, not hidden"));
        }
    }
    let bell = _layout_query(doc_id, root + "/Nozzle/Bell", ["visibility"], false);
    if _ok(bell) {
        findings.push(_layout_finding("GR-020", root + "/Nozzle/Bell",
            "single-bell placeholder must be deleted after the seven-engine cluster is authored"));
    }
    findings
}

/// Check counts, side placement, symmetry, body shape, leg attachment, and
/// suppression of inherited comparison geometry. These checks are relational,
/// so they catch a correctly named part mounted on the wrong side as well as a
/// missing part.
fn layout_report(doc_id, root) {
    let findings = [];
    let body = _body_shape_report(doc_id, root);
    for finding in body.findings { findings.push(finding); }
    for result in [_solar_layout_report(doc_id, root),
                   _ramp_layout_report(doc_id, root),
                   _leg_layout_report(doc_id, root),
                   _tank_layout_report(doc_id, root),
                   _engine_layout_report(doc_id, root),
                   _legacy_visibility_report(doc_id, root)] {
        for finding in result { findings.push(finding); }
    }
    #{ok: findings.len() == 0, root: root, doc_id: doc_id, findings: findings,
      body_collider_observation: body.collider_observation}
}

fn _audit_parameter(doc_id, rule, part_path, parameter) {
    let findings = [];
    let parameter_path = parameter.path;
    if parameter_path == () { parameter_path = part_path; }
    let record = _query(doc_id, parameter_path, [parameter.attr], (), false);
    let value = ();
    if !_ok(record) {
        findings.push(_finding(rule, parameter_path,
            "parameter owner is missing for " + parameter.name));
        return findings;
    }
    value = record.attrs[parameter.attr];
    if value == () {
        findings.push(_finding(rule, parameter_path,
            "missing required parameter " + parameter.attr + " (" + parameter.name + ")"));
        return findings;
    }
    if parameter.nonempty == true && value == "" {
        findings.push(_finding(rule, parameter_path,
            "parameter " + parameter.attr + " must not be empty"));
    }
    if parameter.contains != () && !value.contains(parameter.contains) {
        findings.push(_finding(rule, parameter_path,
            "parameter " + parameter.attr + " must contain '" + parameter.contains + "'"));
    }
    if parameter.exact != () && value != parameter.exact {
        findings.push(_finding(rule, parameter_path,
            "parameter " + parameter.attr + " has an unexpected value"));
    }
    if parameter.positive == true && value <= 0.0 {
        findings.push(_finding(rule, parameter_path,
            "parameter " + parameter.attr + " must be positive"));
    }
    if parameter.max_abs != () && value.abs() > parameter.max_abs {
        findings.push(_finding(rule, parameter_path,
            "parameter " + parameter.attr + " exceeds its authored absolute limit"));
    }
    findings
}

fn _audit_part(doc_id, spec) {
    let findings = [];
    let record = _query(doc_id, spec.path, spec.attrs, (), true);
    if !_ok(record) {
        findings.push(_finding(spec.rule, spec.path,
            spec.label + " is missing from the composed stage"));
        return findings;
    }
    if spec.expected_type != () && record.type_name != spec.expected_type {
        findings.push(_finding(spec.rule, spec.path,
            spec.label + " must be " + spec.expected_type
                + ", got " + record.type_name));
    }
    if spec.geometry == true && !_geometry_type(record.type_name) {
        findings.push(_finding(spec.rule, spec.path,
            spec.label + " must resolve to a geometric prim, got " + record.type_name));
    }
    if spec.visible == true && !_visible(record) {
        findings.push(_finding(spec.rule, spec.path,
            spec.label + " must be visible in the authored preview"));
    }
    if spec.collider == true && record.attrs["physics:collisionEnabled"] != true {
        findings.push(_finding(spec.rule, spec.path,
            spec.label + " must own an enabled collider"));
    }
    if spec.required_children != () {
        for child_path in spec.required_children {
            if !_ok(_query(doc_id, child_path, [], (), false)) {
                findings.push(_finding(spec.rule, child_path,
                    spec.label + " is missing required child geometry/interface"));
            }
        }
    }
    if spec.geometry_children != () {
        for geometry in spec.geometry_children {
            let geometry_record = _query(doc_id, geometry.path,
                ["visibility", "physics:collisionEnabled"], (), false);
            if !_ok(geometry_record) {
                findings.push(_finding(spec.rule, geometry.path,
                    spec.label + " is missing required geometry " + geometry.label));
                continue;
            }
            if geometry.geometry == true && !_geometry_type(geometry_record.type_name) {
                findings.push(_finding(spec.rule, geometry.path,
                    "required geometry " + geometry.label + " has non-geometric type "
                        + geometry_record.type_name));
            }
            if geometry.visible == true && !_visible(geometry_record) {
                findings.push(_finding(spec.rule, geometry.path,
                    "required geometry " + geometry.label + " is hidden"));
            }
            if geometry.collider == true
                && geometry_record.attrs["physics:collisionEnabled"] != true {
                findings.push(_finding(spec.rule, geometry.path,
                    "required geometry " + geometry.label + " must own an enabled collider"));
            }
        }
    }
    if spec.parameters != () {
        for parameter in spec.parameters {
            for finding in _audit_parameter(doc_id, spec.rule, spec.path, parameter) {
                findings.push(finding);
            }
        }
    }
    findings
}

fn _named_paths(parent, names) {
    let paths = [];
    for name in names { paths.push(parent + "/" + name); }
    paths
}

// This is the single source of known Griffin part contracts. Numeric values
// that are not source-backed are marked as study/TBD in the returned metadata;
// the linter checks only explicit values and geometry obligations.
fn part_manifest(root) {
    let legs = [];
    let leg_names = griffin_spec::landing_leg_names();
    let leg_source = _landing_leg_requirement_source();
    let visual_child_names = sysml_requirement_checks::source_enum_identifiers(leg_source,
        "GriffinLandingLegRequirements::GriffinLandingLegAssembly::childNames");
    for i in 0..leg_names.len() {
        let name = leg_names[i];
        let leg_path = root + "/" + name;
        let required_children = [];
        let geometry_children = [];
        if visual_child_names != () {
            for child_name in visual_child_names {
                let child_path = leg_path + "/LandingLegVisual/" + child_name;
                required_children.push(child_path);
                geometry_children.push(#{label: child_name,
                    path: child_path, geometry: true, visible: true});
            }
        }
        required_children.push(leg_path + "/LandingLegVisual/FootPadCollider");
        legs.push(#{
            id: "landing_leg_" + name,
            label: "landing leg " + name,
            rule: "GR-010",
            path: leg_path,
            attrs: ["visibility", "physics:mass"],
            expected_type: "Xform",
            visible: true,
            required_children: required_children,
            geometry_children: geometry_children,
            parameters: [#{
                name: "leg mass",
                attr: "physics:mass",
                positive: true,
            }],
        });
    }

    let ramps = [];
    for name in griffin_spec::ramp_names() {
        let ramp_path = root + "/" + name;
        ramps.push(#{
            id: "egress_ramp_" + name,
            label: "egress ramp " + name,
            rule: "GR-003",
            path: ramp_path,
            attrs: ["visibility", "physics:mass", "lunco:deployment_angle_rad"],
            expected_type: "Xform",
            visible: true,
            required_children: [
                ramp_path + "/RampTrackPort",
                ramp_path + "/RampTrackStarboard",
                ramp_path + "/EdgeRail",
                ramp_path + "/EdgeRailInner",
            ],
            geometry_children: [
                #{label: "port wheel track", path: ramp_path + "/RampTrackPort", geometry: true, visible: true, collider: true},
                #{label: "starboard wheel track", path: ramp_path + "/RampTrackStarboard", geometry: true, visible: true, collider: true},
                #{label: "outer edge rail", path: ramp_path + "/EdgeRail", geometry: true, visible: true, collider: true},
                #{label: "inner edge rail", path: ramp_path + "/EdgeRailInner", geometry: true, visible: true, collider: true},
            ],
            parameters: [
                #{name: "ramp mass", attr: "physics:mass", positive: true},
                #{name: "deployment command", attr: "lunco:deployment_angle_rad", max_abs: max_ramp_command_rad()},
            ],
        });
    }

    let tanks = [];
    for name in griffin_spec::propellant_tank_names() {
        let path = root + "/" + name;
        tanks.push(#{
            id: "propellant_" + name,
            label: "propellant tank " + name,
            rule: "GR-033",
            path: path,
            attrs: ["visibility", "xformOp:translate", "xformOp:scale"],
            expected_type: "Xform",
            visible: true,
            required_children: [path + "/MliTank", path + "/TankBandA"],
            geometry_children: [#{label: "vessel skin", path: path + "/MliTank",
                geometry: true, visible: true, collider: false}],
        });
    }

    let solar_arrays = [];
    for name in griffin_spec::solar_array_names() {
        let path = root + "/" + name;
        solar_arrays.push(#{
            id: "solar_array_" + name,
            label: "solar array " + name,
            rule: "GR-016",
            path: path,
            attrs: ["visibility"],
            expected_type: "Xform",
            visible: true,
            required_children: [path + "/Cells"],
            geometry_children: [#{label: "solar cells", path: path + "/Cells", geometry: true, collider: false}],
        });
    }

    [
        #{
            id: "lander",
            label: "Griffin lander root",
            rule: "GR-001",
            path: root,
            attrs: ["visibility", "lunco:payload_class_kg"],
            expected_type: "Xform",
            required_children: [root + "/GriffinBody", root + "/Bus",
                root + "/TopDeckBeamCollider0", root + "/TopDeckBeamCollider1",
                root + "/TopDeckBeamCollider2", root + "/TopDeckBeamCollider3",
                root + "/TopDeckBeamCollider4", root + "/TopDeckBeamCollider5",
                root + "/TopDeckBeamCollider6", root + "/TopDeckBeamCollider7",
                root + "/RoverPayloadDeckCollider", root + "/PayloadAdapter",
                root + "/MainPropulsion"]
                + _named_paths(root, griffin_spec::solar_array_names())
                + [root + "/Nozzle"]
                + _named_paths(root, griffin_spec::propellant_tank_names()),
            parameters: [#{name: "payload capacity", attr: "lunco:payload_class_kg", exact: max_payload_kg()}],
        },
        #{
            id: "deck",
            label: "octagonal visual payload deck",
            rule: "GR-001",
            path: root + "/Bus",
            attrs: ["visibility"],
            expected_type: "Xform",
            visible: true,
            required_children: [root + "/Bus/TopDeckOctagon"],
            geometry_children: [#{label: "octagonal deck", path: root + "/Bus/TopDeckOctagon", geometry: true, collider: false}],
        },
        #{
            id: "body_collider",
            label: "flight-body collision proxy",
            rule: "GR-018",
            path: root + "/GriffinBody/BodyCollisionProxy",
            attrs: ["visibility", "purpose", "physics:collisionEnabled"],
            expected_type: "Cube",
            geometry: true,
            collider: true,
        },
        #{
            id: "deck_collider",
            label: "rover payload platform collision proxy",
            rule: "GR-018",
            path: root + "/RoverPayloadDeckCollider",
            attrs: ["visibility", "purpose", "physics:collisionEnabled"],
            expected_type: "Mesh",
            geometry: true,
            collider: true,
        },
        #{
            id: "payload_adapter",
            label: "payload adapter",
            rule: "GR-002",
            path: root + "/PayloadAdapter",
            attrs: [],
            expected_type: "Xform",
            required_children: [root + "/PayloadAdapter/AdapterPlate"],
            geometry_children: [#{label: "adapter plate", path: root + "/PayloadAdapter/AdapterPlate", geometry: true, collider: true}],
        },
        #{
            id: "main_propulsion",
            label: "main propulsion interface",
            rule: "GR-006",
            path: root + "/MainPropulsion",
            attrs: [],
            expected_type: "Scope",
            required_children: [root + "/MainPropulsion/MainChamber",
                root + "/MainPropulsion/FuelTank", root + "/MainPropulsion/OxidizerTank"],
        },
        #{
            id: "nozzle",
            label: "main engine nozzle",
            rule: "GR-015",
            path: root + "/Nozzle",
            attrs: ["visibility"],
            expected_type: "Xform",
            visible: true,
            required_children: [root + "/Nozzle/MainEngineCluster"],
            geometry_children: [],
        },
        #{
            id: "main_engine_cluster",
            label: "seven-engine visual cluster",
            rule: "GR-032",
            path: root + "/Nozzle/MainEngineCluster",
            attrs: ["visibility"],
            expected_type: "Xform",
            visible: true,
            required_children: _named_paths(root + "/Nozzle/MainEngineCluster",
                griffin_spec::main_engine_names()),
            geometry_children: [],
        },
    ] + solar_arrays + tanks + legs + ramps
}

fn _part_report(doc_id, spec) {
    let findings = _audit_part(doc_id, spec);
    #{
        id: spec.id,
        label: spec.label,
        path: spec.path,
        ok: findings.len() == 0,
        findings: findings,
    }
}

/// Return each part's composed structural evidence for an Editor inspector.
fn part_report(doc_id, root) {
    let parts = [];
    let findings = [];
    for spec in part_manifest(root) {
        let result = _part_report(doc_id, spec);
        parts.push(result);
        for finding in result.findings { findings.push(finding); }
    }
    #{ok: findings.len() == 0, root: root, doc_id: doc_id, parts: parts, findings: findings}
}

/// Compose one machine-readable report for the live runtime test. This is a
/// report rather than a second linter: `lint` remains the current structural
/// implementation. Requirement identities and applicability come from the
/// validated SysML source; this report contains only current observations.
fn runtime_report(doc_id, root, verification_name) {
    let sysml = sysml_contract_report(verification_name);
    let lint_report = lint(doc_id, root);
    let parts = part_report(doc_id, root);
    let layout = layout_report(doc_id, root);
    let errors = [];

    for error in lint_report.errors { errors.push(error); }
    if sysml.ok != true || sysml.sysml_ok != true {
        let message = sysml.error;
        if message == () { message = "SysML requirement source failed validation"; }
        errors.push("SysML requirement contract: " + message);
    }

    let part_failures = [];
    for part in parts.parts {
        if !part.ok { part_failures.push(part.id); }
    }
    for id in part_failures {
        errors.push("part contract failed: " + id);
    }
    if !layout.ok {
        let finding_count = if layout.findings == () { 0 } else { layout.findings.len() };
        errors.push("relational layout report has " + finding_count + " finding(s)");
    }

    // Keep the runtime verdict compact while retaining the source identity
    // needed by typed provenance projections.
    let sysml_summary = #{
        // Preserve the Twin URI needed by bounded typed projections such as
        // sysml_requirements::provenance().  The summary intentionally drops
        // the large AST/attribute tables, but it must retain the source
        // identity so evidence remains Twin-native in runtime tests.
        path: sysml.path,
        ok: sysml.ok,
        error: if sysml.error == () { "" } else { sysml.error },
        kind: sysml.kind,
        sysml_ok: sysml.sysml_ok,
        sysml_required_count: sysml.sysml_required_count,
        sysml_verification_count: sysml.sysml_verification_count,
        sysml_verifies: sysml.sysml_verifies,
        sysml_general_required_count: sysml.sysml_general_required_count,
        sysml_general_verifies: sysml.sysml_general_verifies,
        sysml_visual_required_count: sysml.sysml_visual_required_count,
        sysml_visual_verifies: sysml.sysml_visual_verifies,
        sysml_visual_wheel_count: sysml.sysml_visual_wheel_count,
        sysml_visual_case_name: sysml.sysml_visual_case_name,
        provenance_requirement_handle: sysml.provenance_requirement_handle,
        sysml_verification_name: sysml.sysml_verification_name,
        sysml_missing: sysml.sysml_missing,
        source_files: sysml.source_files,
        source_file_count: if sysml.source_files == () { 0 } else { sysml.source_files.len() },
        source_revision: sysml.source_revision,
    };

    #{
        ok: errors.len() == 0,
        root: root,
        doc_id: doc_id,
        errors: errors,
        sysml: sysml_summary,
        source_files: sysml_summary.source_files,
        sysml_source_file_count: sysml_summary.source_file_count,
        sysml_source_revision: sysml_summary.source_revision,
        parts: parts.parts,
        part_failures: part_failures,
        layout: layout,
        structural: lint_report,
    }
}

fn _report(doc_id, root, findings) {
    let errors = [];
    for finding in findings {
        errors.push(finding.id + " " + finding.path + ": " + finding.message);
    }
    #{
        ok: errors.len() == 0,
        doc_id: doc_id,
        root: root,
        findings: findings,
        errors: errors,
        warnings: [],
    }
}

// Route static engineering predicates through the source-pinned generic
// SysML evaluator. This wrapper supplies requirement identity and typed
// observations; the constraint expression and four-state verdict are owned by
// SysML/IR.
fn _evaluate_source_constraint(source, id, requirement, verification,
                               requirement_usage, constraint_name, inputs) {
    if source == () || source.ok != true {
        return #{ok: false, verdict: "error",
            error: "SysML source report is unavailable for constraint evaluation"};
    }
    let model = sysml_requirements::model();
    let observations = sysml_requirements::required_constraint_input_observations(
        model, requirement_usage, constraint_name, inputs);
    let check = sysml_requirements::constraint_check(id, "lander", requirement,
        verification, constraint_name, observations, "derived", 0.0);
    let report = sysml_requirements::evaluate(source, [check]);
    if report.results == () || report.results.len() != 1 {
        return #{ok: false, verdict: "error",
            error: if report.error == () { "SysML constraint produced no check result" } else { report.error },
            report: report};
    }
    report.results[0]
}

fn payload_load_check(payload_kg) {
    let source = _payload_requirement_source();
    let model = sysml_requirements::model();
    let requirement_usage = model.requirement("GriffinFunctionalRequirements::gr009");
    let capacity = sysml_requirements::number(source,
        griffin_spec::qualified_attribute_name("payloadCapacityKg"));
    let result = _evaluate_source_constraint(source, "GR-009-payload-capacity", "gr009",
        "Verify_GriffinPayloadCapacity", requirement_usage,
        "GriffinFunctionalRequirements::GR009_PayloadWithinCapacity",
        [["payloadKg", #{provider: "external",
             state: if payload_kg == () { "unavailable" } else { "value" },
             value: payload_kg}],
         ["capacityKg", _source_value(capacity, source)]]);
    result.payload_kg = payload_kg;
    result.capacity_kg = capacity;
    result
}

fn _payload_scene_checks(root, payload_kg, capacity_kg) {
    let source = _payload_requirement_source();
    let capacity_attribute = griffin_spec::qualified_attribute_name("payloadCapacityKg");
    let constraint_name = "GriffinFunctionalRequirements::GR009_PayloadWithinCapacity";
    let model = sysml_requirements::model();
    let requirement_usage = model.requirement("GriffinFunctionalRequirements::gr009");
    let observations = sysml_requirements::required_constraint_input_observations(
        model, requirement_usage, constraint_name,
        [["payloadKg", _usd_value(payload_kg)],
         ["capacityKg", _source_value(capacity_kg, source)]]);
    [
        #{id: "GR-009-authored-capacity", component: "lander",
          requirement: "gr009", verification: "Verify_GriffinPayloadCapacity",
          kind: "attribute", path: root, attr: "lunco:payload_class_kg",
          expected_attr: capacity_attribute, tolerance: 0.0},
        sysml_requirements::constraint_check("GR-009-payload-load", "lander",
            "gr009", "Verify_GriffinPayloadCapacity",
            constraint_name, observations, "derived", 0.0),
    ]
}

fn _payload_requirement_source() {
    sysml_requirements::source_with_selection([
        griffin_spec::qualified_attribute_name("payloadCapacityKg")
    ], ["GriffinFunctionalRequirements::gr009"],
        ["GriffinFunctionalRequirements::Verify_GriffinPayloadCapacity"])
}

/// Runtime command acceptance uses the source-defined SysML constraint. USD
/// transform conversion remains at the authoring boundary.
fn _ramp_requirement_source() {
    sysml_requirements::source_with_selection([
        "GriffinRampRequirements::GriffinEgressRamp::rampMaxDeploymentAngleRad"
    ], ["GriffinRampRequirements::grr005"],
        ["GriffinRampRequirements::Verify_GriffinRampCommandEnvelope"])
}

fn _landing_leg_requirement_source() {
    let assembly = "GriffinLandingLegRequirements::GriffinLandingLegAssembly::";
    let configuration = "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::";
    sysml_requirements::source_with_selection([
        assembly + "childNames",
        assembly + "footPadRadiusM",
        assembly + "footPadHeightM",
        assembly + "footPadCenterYM",
        assembly + "physicalLegPlacementToleranceM",
        assembly + "physicalLegRotationToleranceDeg",
        assembly + "padColliderToleranceM",
        assembly + "bodyMountOverlapM",
        assembly + "bodyMountOverlapMeasurementToleranceM",
        configuration + "legStations",
        configuration + "legStationRotationYDeg"
    ], ["GriffinLandingLegRequirements::gll005",
        "GriffinLandingLegRequirements::gll008",
        "GriffinLandingLegRequirements::gll009"],
       ["GriffinLandingLegRequirements::Verify_GriffinLandingLegRequirements"])
}

fn _physical_ramp_geometry_source() {
    sysml_requirements::source_with_selection([
        "GriffinRampRequirements::GriffinEgressRamp::rampSurfaceLengthM",
        "GriffinRampRequirements::GriffinEgressRamp::rampSurfaceThicknessM",
        "GriffinRampRequirements::GriffinEgressRamp::rampSurfaceCenterYM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyTrackWidthM",
        "GriffinRampRequirements::GriffinEgressRamp::contactTrackGeometryToleranceM",
        "GriffinRampRequirements::GriffinEgressRamp::rampWheelClearanceM",
        "FlipRequirements::FlipRover::wheelStationZ",
        "FlipWheelRequirements::FlipDirectionalWheelAssembly::tireWidthM"
    ], ["GriffinRampRequirements::grr006"],
       ["GriffinRampRequirements::Verify_GriffinRampRequirements"])
}

fn _landing_pad_requirement_findings(doc_id, root) {
    let findings = [];
    let source = _landing_leg_requirement_source();
    if source.ok != true {
        findings.push(_finding("GLL-008", root,
            "typed landing-leg requirement source is unavailable"));
        return findings;
    }
    let assembly = "GriffinLandingLegRequirements::GriffinLandingLegAssembly::";
    let tolerance = sysml_requirements::number(source, assembly + "padColliderToleranceM");
    let station_tolerance = sysml_requirements::number(source,
        assembly + "physicalLegPlacementToleranceM");
    let mount_overlap = sysml_requirements::number(source,
        assembly + "bodyMountOverlapM");
    let mount_measurement_tolerance = sysml_requirements::number(source,
        assembly + "bodyMountOverlapMeasurementToleranceM");
    if tolerance == () || station_tolerance == () || mount_overlap == ()
        || mount_measurement_tolerance == () {
        findings.push(_finding("GLL-008", root,
            "typed pad, mount, or station tolerances are unavailable"));
        return findings;
    }
    let observation = griffin_visual_builder::physical_landing_leg_pad_observation(
        doc_id, root);
    if observation.ok != true {
        findings.push(_finding("GLL-008", root,
            if observation.detail == () {
                "composed landing-pad measurements are unavailable"
            } else { observation.detail }));
        return findings;
    }
    let pad_geometry_constraint =
        "GriffinLandingLegRequirements::GLLC008_PadColliderMatchesVisual";
    let pad_ownership_constraint =
        "GriffinLandingLegRequirements::GLLC008_PadColliderOwnsContact";
    let pad_station_constraint =
        "GriffinLandingLegRequirements::GLLC008_PadColliderStationMatchesSource";
    let mount_constraint =
        "GriffinLandingLegRequirements::GLLC009_BusAndAxleOverlap";
    let model = sysml_requirements::model();
    let pad_requirement = model.requirement("GriffinLandingLegRequirements::gll008");
    let mount_requirement = model.requirement("GriffinLandingLegRequirements::gll009");
    let checks = [
        sysml_requirements::constraint_check("GLL-008-pad-geometry", "landing_leg",
            "gll008", "Verify_GriffinLandingLegRequirements",
            pad_geometry_constraint,
            sysml_requirements::required_constraint_input_observations(model,
                pad_requirement, pad_geometry_constraint, [
                ["geometryDeviationM",
                    _usd_snapshot_value(observation.geometry_deviation_m, observation)],
                ["sourceRadiusDeviationM",
                    _usd_snapshot_value(observation.source_radius_deviation_m, observation)],
                ["sourceHeightDeviationM",
                    _usd_snapshot_value(observation.source_height_deviation_m, observation)],
                ["sourceCenterDeviationM",
                    _usd_snapshot_value(observation.source_center_deviation_m, observation)],
                ["padGeometrySemanticsMatch",
                    _usd_snapshot_value(observation.pad_geometry_semantics_match, observation)],
                ["toleranceM", _source_value(tolerance, source)]]), "usd", 0.0),
        sysml_requirements::constraint_check("GLL-008-contact-ownership", "landing_leg",
            "gll008", "Verify_GriffinLandingLegRequirements",
            pad_ownership_constraint,
            sysml_requirements::required_constraint_input_observations(model,
                pad_requirement, pad_ownership_constraint, [
                ["collisionEnabled",
                    _usd_snapshot_value(observation.collision_enabled, observation)],
                ["proxyHidden",
                    _usd_snapshot_value(observation.proxy_hidden, observation)],
                ["visualCollisionDisabled",
                    _usd_snapshot_value(observation.visual_collision_disabled, observation)],
                ["collisionMatchesVisual",
                    _usd_snapshot_value(observation.collision_matches_visual, observation)],
                ["geometrySourceLinked",
                    _usd_snapshot_value(observation.source_relationships_valid, observation)],
                ["selfCollisionFilterClear",
                    _usd_snapshot_value(observation.self_collision_filter_clear, observation)],
                ["legacyCollisionDisabled",
                    _usd_snapshot_value(observation.legacy_collision_disabled, observation)]]),
            "usd", 0.0),
        sysml_requirements::constraint_check("GLL-008-physical-stations", "landing_leg",
            "gll008", "Verify_GriffinLandingLegRequirements",
            pad_station_constraint,
            sysml_requirements::required_constraint_input_observations(model,
                pad_requirement, pad_station_constraint, [
                ["stationDeviationM",
                    _usd_snapshot_value(observation.station_deviation_m, observation)],
                ["toleranceM", _source_value(station_tolerance, source)],
                ["rotationMatches",
                    _usd_snapshot_value(observation.rotation_matches, observation)]]), "usd", 0.0),
        sysml_requirements::constraint_check("GLL-009-body-mount-path", "landing_leg",
            "gll009", "Verify_GriffinLandingLegRequirements",
            mount_constraint,
            sysml_requirements::required_constraint_input_observations(model,
                mount_requirement, mount_constraint, [
                ["measuredBusOverlapM", _usd_snapshot_value(observation.bus_mount_overlap_m, observation)],
                ["measuredAxleOverlapM", _usd_snapshot_value(observation.mount_axle_overlap_m, observation)],
                ["requiredOverlapM", _source_value(mount_overlap, source)],
                ["measurementToleranceM", _source_value(mount_measurement_tolerance, source)],
                ["physicalJointStationMatches", _usd_snapshot_value(observation.physical_joints_match, observation)]]),
            "usd", 0.0)
    ];
    let evaluation = sysml_requirements::evaluate(source, checks);
    if evaluation.results == () || evaluation.results.len() != checks.len() {
        findings.push(_finding("GLL-008", root,
            _evaluation_failure(evaluation,
                "SysML landing-pad constraints produced no results")));
        return findings;
    }
    for result in evaluation.results {
        let failure = _constraint_result_failure(result);
        if failure != "" { findings.push(_finding("GLL-008", root, failure)); }
    }
    findings
}

fn _ramp_track_requirement_findings(child, child_path, child_name, ramp_index,
    ramp_source, ramp_length, ramp_thickness, ramp_center_y, track_width,
    ramp_clearance, wheel_width, track_tolerance, wheel_stations_z, half_track) {
    let findings = [];
    if !_ok(child) || child.attrs == () {
        findings.push(_finding("GR-006", child_path,
            "composed physical contact track is unavailable"));
        return findings;
    }
    let translation = child.attrs["xformOp:translate"];
    let collision = child.collision_geometry;
    let collision_bounds = child.collision_bounds;
    let expected_z = if child_name == "RampTrackPort" { half_track } else { -half_track };
    let source_missing = ramp_source.ok != true || ramp_length == ()
        || ramp_thickness == () || ramp_center_y == () || track_width == ()
        || ramp_clearance == () || wheel_width == () || track_tolerance == ()
        || wheel_stations_z == () || wheel_stations_z.len() != 4;
    let geometry_missing = translation == () || translation.len() != 3
        || child.type_name != "Mesh" || collision == ()
        || collision.frame != "canonical_stage"
        || collision.shape != "convex_hull"
        || collision.vertices == () || collision.vertices.len() < 4
        || collision_bounds == () || collision_bounds.fidelity != "exact"
        || collision_bounds.half_extents == ()
        || !_has(child.api_schemas, "PhysicsCollisionAPI")
        || !_has(child.api_schemas, "PhysicsMeshCollisionAPI");
    if source_missing {
        findings.push(_finding("GR-006", child_path,
            "physical contact track needs complete SysML source measurements"));
        return findings;
    }
    if geometry_missing {
        findings.push(_finding("GR-006", child_path,
            "physical contact track needs cooked convex-hull geometry, exact collision bounds, and applied mesh collision APIs"));
        return findings;
    }
    // The geometry query returns the same cooked hull used by Avian. Keep the
    // standard USD approximation token check as an authored-schema check.
    if child.attrs["physics:approximation"] != "convexHull" {
        findings.push(_finding("GR-006", child_path,
            "dynamic contact track collider must use the authored convexHull approximation"));
        return findings;
    }
    let expected_x = if ramp_index == 0 { ramp_length / 2.0 } else { -ramp_length / 2.0 };
    let half_extents = collision_bounds.half_extents;
    let measured_length = 2.0 * half_extents[0];
    let measured_thickness = 2.0 * half_extents[1];
    let measured_width = 2.0 * half_extents[2];
    let dimension_deviation = _maximum_value(
        (measured_length - ramp_length).abs(),
        _maximum_value((measured_thickness - ramp_thickness).abs(),
            (measured_width - track_width).abs()));
    let placement_deviation = _vector_max_deviation(translation,
        [expected_x, ramp_center_y, expected_z]);
    let clearance_constraint =
        "GriffinRampRequirements::GRC016_ContactTrackClearsTire";
    let geometry_constraint =
        "GriffinRampRequirements::GRC017_ComposedContactTrackMatchesSource";
    let model = sysml_requirements::model();
    let requirement_usage = model.requirement("GriffinRampRequirements::grr006");
    let checks = [
        sysml_requirements::constraint_check(
            "GR-006-tire-clearance-" + child_name, "lander", "grr006",
            "Verify_GriffinRampRequirements",
            clearance_constraint,
            sysml_requirements::required_constraint_input_observations(model,
                requirement_usage, clearance_constraint, [
                ["trackWidthM", _usd_value(measured_width)],
                ["wheelWidthM", _source_value(wheel_width, ramp_source)],
                ["wheelClearanceM", _source_value(ramp_clearance, ramp_source)]]), "derived", 0.0),
        sysml_requirements::constraint_check(
            "GR-006-composed-geometry-" + child_name, "lander", "grr006",
            "Verify_GriffinRampRequirements",
            geometry_constraint,
            sysml_requirements::required_constraint_input_observations(model,
                requirement_usage, geometry_constraint, [
                ["maximumDimensionDeviationM", _usd_value(dimension_deviation)],
                ["maximumPlacementDeviationM", _usd_value(placement_deviation)],
                ["toleranceM", _source_value(track_tolerance, ramp_source)]]), "derived", 0.0)
    ];
    let evaluation = sysml_requirements::evaluate(ramp_source, checks);
    if evaluation.results == () || evaluation.results.len() != checks.len() {
        findings.push(_finding("GR-006", child_path,
            _evaluation_failure(evaluation,
                "SysML ramp geometry constraints produced no results")));
        return findings;
    }
    for result in evaluation.results {
        let failure = _constraint_result_failure(result);
        if failure != "" { findings.push(_finding("GR-006", child_path, failure)); }
    }
    findings
}

fn ramp_command_check(angle_rad) {
    let source = _ramp_requirement_source();
    let model = sysml_requirements::model();
    let requirement_usage = model.requirement("GriffinRampRequirements::grr005");
    let limit = sysml_requirements::number(source,
        "GriffinRampRequirements::GriffinEgressRamp::rampMaxDeploymentAngleRad");
    let result = _evaluate_source_constraint(source, "GRR-005-deployment-command",
        "grr005", "Verify_GriffinRampCommandEnvelope", requirement_usage,
        "GriffinRampRequirements::GRC005_DeploymentCommandWithinLimit",
        [["commandRad", #{provider: "external",
            state: if angle_rad == () { "unavailable" } else { "value" },
            value: angle_rad}],
         ["limitRad", _source_value(limit, source)]]);
    result.angle_rad = angle_rad;
    result.limit_rad = limit;
    result
}

/// Lint the composed Griffin contract. `root` is an absolute composed USD
/// path, such as `/Griffin1` in the isolated Editor preview or
/// `/GriffinRequirementsTest/Griffin1` in the Twin test scene.
fn lint(doc_id, root) {
    let findings = [];
    let root_record = _query(doc_id, root, [
        "lunco:payload_class_kg",
    ], (), true);

    if !_ok(root_record) {
        findings.push(_finding("GR-001", root, "composed Griffin root is missing"));
        return _report(doc_id, root, findings);
    }
    if root_record.type_name != "Xform" {
        findings.push(_finding("GR-001", root,
            "expected Xform root, got " + root_record.type_name));
    }

    // Run the generic manifest audit as part of the Griffin lint. The
    // specialized checks below still cover topology relationships and exact
    // counts; the manifest covers presence, geometry, collision ownership,
    // and per-part parameters uniformly.
    let part_contract = part_report(doc_id, root);
    for finding in part_contract.findings { findings.push(finding); }
    let layout_contract = layout_report(doc_id, root);
    for finding in layout_contract.findings { findings.push(finding); }

    let attrs = root_record.attrs;
    let payload = attrs["lunco:payload_class_kg"];
    let requirement_source = _payload_requirement_source();
    let payload_capacity = sysml_requirements::number(requirement_source,
        griffin_spec::qualified_attribute_name("payloadCapacityKg"));
    let payload_report = sysml_requirements::evaluate_document(requirement_source,
        doc_id, _payload_scene_checks(root, payload, payload_capacity));
    for result in payload_report.results {
        if result.ok != true {
            findings.push(_finding("GR-009", root,
                if result.error == () { "payload capacity constraint verdict: " + result.verdict } else { result.error }));
        }
    }

    let leg_names = griffin_spec::landing_leg_names();
    let visible_leg_count = 0;
    if root_record.children != () {
        for child in root_record.children {
            // Spring joints carry the leg dynamics and are not visible leg
            // bodies; count only visible direct Leg* body roots.
            if child.contains("/Leg") && !child.contains("_Spring") {
                let child_record = _query(doc_id, child, ["visibility"], (), false);
                if _ok(child_record) && child_record.attrs["visibility"] != "invisible" {
                    visible_leg_count += 1;
                }
            }
        }
    }
    if visible_leg_count != landing_leg_count() {
        findings.push(_finding("GR-010", root,
            "visible functional landing-leg count disagrees with SysML, got "
                + visible_leg_count));
    }
    for i in 0..leg_names.len() {
        let leg_name = leg_names[i];
        let leg_path = root + "/" + leg_name;
        let leg = _query(doc_id, leg_path, ["physics:mass", "visibility"], (), true);
        if !_ok(leg) {
            findings.push(_finding("GR-010", leg_path, "landing-leg body is missing"));
        } else {
            if leg.type_name != "Xform" {
                findings.push(_finding("GR-010", leg_path,
                    "landing-leg body must be an Xform"));
            }
            if leg.attrs["visibility"] == "invisible" {
                findings.push(_finding("GR-010", leg_path,
                    "functional landing-leg body is hidden"));
            }
            if leg.attrs["physics:mass"] == () || leg.attrs["physics:mass"] <= 0.0 {
                findings.push(_finding("GR-012", leg_path,
                    "landing-leg body needs a positive mass"));
            }


        }
    }

    for finding in _landing_pad_requirement_findings(doc_id, root) { findings.push(finding); }

    let ramp_source = _physical_ramp_geometry_source();
    let ramp_length = sysml_requirements::number(ramp_source,
        "GriffinRampRequirements::GriffinEgressRamp::rampSurfaceLengthM");
    let ramp_thickness = sysml_requirements::number(ramp_source,
        "GriffinRampRequirements::GriffinEgressRamp::rampSurfaceThicknessM");
    let ramp_center_y = sysml_requirements::number(ramp_source,
        "GriffinRampRequirements::GriffinEgressRamp::rampSurfaceCenterYM");
    let track_width = sysml_requirements::number(ramp_source,
        "GriffinRampRequirements::GriffinEgressRamp::assemblyTrackWidthM");
    let ramp_clearance = sysml_requirements::number(ramp_source,
        "GriffinRampRequirements::GriffinEgressRamp::rampWheelClearanceM");
    let wheel_width = sysml_requirements::number(ramp_source,
        "FlipWheelRequirements::FlipDirectionalWheelAssembly::tireWidthM");
    let track_tolerance = sysml_requirements::number(ramp_source,
        "GriffinRampRequirements::GriffinEgressRamp::contactTrackGeometryToleranceM");
    let wheel_stations_z = sysml_requirement_checks::source_number_list(ramp_source,
        "FlipRequirements::FlipRover::wheelStationZ");
    let half_track = 0.0;
    if wheel_stations_z != () {
        for station in wheel_stations_z {
            if station.abs() > half_track { half_track = station.abs(); }
        }
    }
    let ramp_names = griffin_spec::ramp_names();
    let hinge_names = griffin_spec::ramp_hinge_names();
    for i in 0..ramp_names.len() {
        let ramp_path = root + "/" + ramp_names[i];
        let ramp = _query_schemas(doc_id, ramp_path,
            ["physics:mass", "lunco:deployment_angle_rad"], (), true);
        if !_ok(ramp) {
            findings.push(_finding("GR-003", ramp_path, "egress ramp body is missing"));
        } else {
            if ramp.type_name != "Xform" {
                findings.push(_finding("GR-003", ramp_path,
                    "egress ramp must be an Xform rigid-body assembly"));
            }
            if ramp.attrs["physics:mass"] == () || ramp.attrs["physics:mass"] <= 0.0 {
                findings.push(_finding("GR-012", ramp_path,
                    "egress ramp needs a positive mass"));
            }
            for schema in ["PhysicsRigidBodyAPI", "PhysicsMassAPI"] {
                if !_has(ramp.api_schemas, schema) {
                    findings.push(_finding("GR-003", ramp_path,
                        "egress ramp body is missing " + schema));
                }
            }
            let physical_children = ["RampTrackPort", "RampTrackStarboard",
                "EdgeRail", "EdgeRailInner"];
            let side = if i == 0 { "port" } else { "starboard" };
            let transition_name = griffin_spec::physical_ramp_transition_body_name(side);
            if transition_name != () && transition_name != "" {
                // TransitionPlate is a rigid-body frame; its ContactSurface
                // child owns the collision geometry. Keep that boundary
                // explicit instead of making a scaled gprim itself a body.
                let contact_name = griffin_spec::physical_ramp_transition_contact_child_name();
                if contact_name == () || contact_name == "" {
                    findings.push(_finding("GR-012", ramp_path,
                        "physical deck transition contact child name is missing in SysML"));
                }
            }
            for child_name in physical_children {
                let child_path = ramp_path + "/" + child_name;
                let child = _query_geometry(doc_id, child_path,
                    ["physics:collisionEnabled", "xformOp:translate", "xformOp:scale",
                     "physics:approximation", "lunco:collider:geometrySource",
                     "lunco:requirement"], (), true);
                if !_ok(child) || child.attrs["physics:collisionEnabled"] != true {
                    findings.push(_finding("GR-003", child_path,
                        "ramp contact geometry must have collision enabled"));
                }
                if _ok(child) && (child.attrs["lunco:collider:geometrySource"] != ()
                    || child.attrs["lunco:requirement"] != ()) {
                    findings.push(_finding("GR-006", child_path,
                        "legacy string collider provenance must be removed; SysML and typed geometry own traceability"));
                }
                if child_name == "RampTrackPort" || child_name == "RampTrackStarboard" {
                    let track_findings = _ramp_track_requirement_findings(child,
                        child_path, child_name, i, ramp_source, ramp_length,
                        ramp_thickness, ramp_center_y, track_width, ramp_clearance,
                        wheel_width, track_tolerance, wheel_stations_z, half_track);
                    for finding in track_findings { findings.push(finding); }
                }
            }
            if transition_name != () && transition_name != "" {
                let contact_name = griffin_spec::physical_ramp_transition_contact_child_name();
                let transition_path = root + "/" + transition_name;
                let transition = _query_schemas(doc_id, transition_path,
                    ["physics:mass", "physics:diagonalInertia"], (), true);
                if !_ok(transition) || transition.type_name != "Xform" {
                    findings.push(_finding("GR-012", transition_path,
                        "physical deck transition must be an unscaled Xform rigid-body frame"));
                } else {
                    // QueryUsdPrim exposes the composed applied API list as
                    // `api_schemas`; keep this check on the shared typed
                    // provider contract instead of duplicating a Rhai-only
                    // projection name.
                    let schemas = transition.api_schemas;
                    for schema in ["PhysicsRigidBodyAPI", "PhysicsMassAPI"] {
                        if !_has(schemas, schema) {
                            findings.push(_finding("GR-012", transition_path,
                                "physical deck transition is missing " + schema));
                        }
                    }
                    let mass = griffin_spec::physical_ramp_deck_transition_mass_kg();
                    if transition.attrs["physics:mass"] == () || mass == ()
                        || (transition.attrs["physics:mass"] - mass).abs() > 0.002 {
                        findings.push(_finding("GR-012", transition_path,
                            "transition mass must match the SysML study datum"));
                    }
                    let inertia = griffin_spec::physical_ramp_deck_transition_inertia_kg_m2();
                    let authored_inertia = transition.attrs["physics:diagonalInertia"];
                    if inertia.len() != 3 || authored_inertia == ()
                        || authored_inertia.len() != 3 {
                        findings.push(_finding("GR-012", transition_path,
                            "transition diagonal inertia must be a typed three-value datum"));
                    } else {
                        for index in 0..3 {
                            if (authored_inertia[index] - inertia[index]).abs() > 0.01 {
                                findings.push(_finding("GR-012", transition_path,
                                    "transition diagonal inertia must match SysML"));
                                break;
                            }
                        }
                    }
                }
                let contact_path = transition_path + "/" + contact_name;
                let contact = _query_schemas(doc_id, contact_path,
                    ["physics:collisionEnabled"], (), false);
                if !_ok(contact) || contact.type_name != "Cube"
                    || contact.attrs["physics:collisionEnabled"] != true
                    || !_has(contact.api_schemas, "PhysicsCollisionAPI") {
                    findings.push(_finding("GR-012", contact_path,
                        "transition ContactSurface must be a collision-enabled Cube"));
                }
                let prefix = griffin_spec::physical_ramp_transition_joint_name_prefix();
                let suffix = if i == 0 { "Port" } else { "Starboard" };
                let joint_path = root + "/" + prefix + suffix;
                let joint = _query(doc_id, joint_path,
                    ["physics:localPos0", "physics:localPos1", "physics:collisionEnabled"],
                    ["physics:body0", "physics:body1"], false);
                if !_ok(joint) || joint.type_name != "PhysicsFixedJoint"
                    || _relationship(joint, "physics:body0") != root
                    || _relationship(joint, "physics:body1") != transition_path {
                    findings.push(_finding("GR-012", joint_path,
                        "transition must be fixed-jointed from the Griffin root to the named plate"));
                }
            }
        }

        let hinge_path = root + "/" + hinge_names[i];
        let hinge = _query(doc_id, hinge_path,
            ["physics:axis", "physics:lowerLimit", "physics:upperLimit"],
            ["physics:body0", "physics:body1"], false);
        if !_ok(hinge) {
            findings.push(_finding("GR-011", hinge_path, "ramp revolute joint is missing"));
        } else {
            if hinge.type_name != "PhysicsRevoluteJoint" {
                findings.push(_finding("GR-011", hinge_path,
                    "ramp hinge must be PhysicsRevoluteJoint"));
            }
            if _relationship(hinge, "physics:body0") != root
                || _relationship(hinge, "physics:body1") != ramp_path {
                findings.push(_finding("GR-011", hinge_path,
                    "ramp hinge must connect the Griffin root and its ramp body"));
            }
            if hinge.attrs["physics:axis"] != "Z" {
                findings.push(_finding("GR-011", hinge_path,
                    "ramp hinge axis must be the authored Z axis"));
            }
            let lower = hinge.attrs["physics:lowerLimit"];
            let upper = hinge.attrs["physics:upperLimit"];
            if lower == () || upper == () || lower >= upper {
                findings.push(_finding("GR-011", hinge_path,
                    "ramp hinge needs ordered angular limits"));
            }
        }
    }

    let deck = _query(doc_id, root + "/Bus", [], (), true);
    if !_ok(deck) || !_has(deck.children, root + "/Bus/TopDeckOctagon") {
        findings.push(_finding("GR-001", root + "/Bus",
            "source-owned octagonal payload deck is required"));
    } else {
        let plate = griffin_visual_builder::physical_top_deck_collider_observation(
            doc_id, root);
        if plate.ok != true || plate.state != "pass" {
            findings.push(_finding("GR-012", root + "/RoverPayloadDeckCollider",
                "octagonal perimeter and rover payload platform colliders must match source geometry"));
        }
    }

    let adapter = _query(doc_id, root + "/PayloadAdapter", [], (), true);
    if !_ok(adapter) || !_has(adapter.children, root + "/PayloadAdapter/AdapterPlate") {
        findings.push(_finding("GR-002", root + "/PayloadAdapter",
            "payload adapter and adapter plate are required"));
    } else {
        let plate = _query(doc_id, root + "/PayloadAdapter/AdapterPlate",
            ["physics:collisionEnabled"], (), false);
        if !_ok(plate) || plate.attrs["physics:collisionEnabled"] != true {
            findings.push(_finding("GR-002", root + "/PayloadAdapter/AdapterPlate",
                "payload adapter plate must be an enabled collider"));
        }
    }

    for child_name in ["MainPropulsion"] + griffin_spec::solar_array_names() {
        if !_ok(_query(doc_id, root + "/" + child_name, [], (), false)) {
            findings.push(_finding("GR-006", root + "/" + child_name,
                "required propulsion/power subassembly is missing"));
        }
    }

    _report(doc_id, root, findings)
}

/// Run the contract against an already open Editor document and print a
/// compact report for the scripting console. The document is not closed,
/// reloaded, or saved.
fn lint_live(doc_id, root) {
    if doc_id == () {
        return #{ ok: false, error: "lint_live requires an explicit USD doc_id" };
    }
    let report = lint(doc_id, root);
    print("[griffin-lint] root=" + root + " doc_id=" + doc_id
        + " result=" + (if report.ok { "PASS" } else { "FAIL" }));
    for error in report.errors { print("[griffin-lint] ERROR " + error); }
    report
}

/// Print the per-part contract, including known values and explicit TBD
/// boundaries, against an already open Editor document. This is read-only.
fn part_report_live(doc_id, root) {
    if doc_id == () {
        return #{ ok: false, error: "part_report_live requires an explicit USD doc_id" };
    }
    let report = part_report(doc_id, root);
    print("[griffin-parts] root=" + root + " doc_id=" + doc_id
        + " result=" + (if report.ok { "PASS" } else { "FAIL" })
        + " parts=" + report.parts.len());
    for part in report.parts {
        print("[griffin-parts] " + part.id + " "
            + (if part.ok { "PASS" } else { "FAIL" }));
        for finding in part.findings {
            print("[griffin-parts] ERROR " + finding.id + " "
                + finding.path + ": " + finding.message);
        }
    }
    report
}

fn _visual_configuration_attr(name) {
    griffin_spec::qualified_attribute_name(name)
}

// Render-only visual acceptance.  The physical Griffin manifest above
// intentionally expects mass/collider/flight prims that do not belong in the
// render document. Keep this report separate so the active Editor visual can
// prove component topology, typed station transforms, ramp load-path children,
// and the SysML source revision without pretending that a presentation asset
// is the flight model.
fn visual_report(doc_id, root) {
    if doc_id == () || root == () || root == "" {
        return #{ok: false, error: "visual_report requires an explicit visual doc_id and root"};
    }
    let source = sysml_requirements::source();
    if source == () || source.ok != true {
        return #{ok: false, error: "visual_report cannot resolve the Twin SysML source"};
    }
    let findings = [];
    let checks = [];
    let root_record = _layout_query(doc_id, root, [], true);
    checks.push("GLR-009-root");
    if !_ok(root_record) {
        findings.push(_finding("GLR-009-root", root,
            "visual Griffin root is missing from the composed Editor document"));
    }

    let required = [root + "/Bus"]
        + _named_paths(root, griffin_spec::propellant_tank_names())
        + _named_paths(root, griffin_spec::landing_leg_names())
        + _named_paths(root, griffin_spec::solar_array_names())
        + [root + "/Nozzle"]
        + _named_paths(root, griffin_spec::ramp_names());
    for path in required {
        checks.push("GLR-009-" + path);
        if !_ok(_layout_query(doc_id, path, [], false)) {
            findings.push(_finding("GLR-009-child", path,
                "required visual component root is missing"));
        }
    }

    let leg_names = griffin_spec::landing_leg_names();
    let leg_stations = sysml_requirement_checks::source_position_list(source, _visual_configuration_attr("legStations"));
    let leg_rot = sysml_requirement_checks::source_number_list(source, _visual_configuration_attr("legStationRotationYDeg"));
    for index in 0..leg_names.len() {
        let path = root + "/" + leg_names[index];
        let record = _layout_query(doc_id, path,
            ["xformOp:translate", "xformOp:rotateXYZ"], false);
        checks.push("GLR-008-" + leg_names[index]);
        if !_ok(record) {
            findings.push(_finding("GLR-008-leg", path,
                "landing-leg station root is missing"));
            continue;
        }
        let position = record.attrs["xformOp:translate"];
        let rotation = record.attrs["xformOp:rotateXYZ"];
        if position == () || position.len() != 3 || leg_stations.len() != leg_names.len()
            || !_near(position[0], leg_stations[index].x, 0.002)
            || !_near(position[1], leg_stations[index].y, 0.002)
            || !_near(position[2], leg_stations[index].z, 0.002) {
            findings.push(_finding("GLR-008-leg-position", path,
                "landing-leg station differs from the ordered SysML datum"));
        }
        if rotation == () || rotation.len() != 3 || leg_rot.len() != leg_names.len()
            || !_near(rotation[1], leg_rot[index], 0.002) {
            findings.push(_finding("GLR-008-leg-rotation", path,
                "landing-leg radial orientation differs from the ordered SysML datum"));
        }
    }

    let solar_names = griffin_spec::solar_array_names();
    let solar_stations = sysml_requirement_checks::source_position_list(source, _visual_configuration_attr("solarStations"));
    let solar_rot_x = sysml_requirement_checks::source_number_list(source, _visual_configuration_attr("solarStationRotationXDeg"));
    let solar_rot = sysml_requirement_checks::source_number_list(source, _visual_configuration_attr("solarStationRotationZDeg"));
    let solar_widths = griffin_spec::component_solar_array_widths_m();
    let solar_frame_width = griffin_spec::solar_panel_frame_width_m();
    for index in 0..solar_names.len() {
        let path = root + "/" + solar_names[index];
        let record = _layout_query(doc_id, path,
            ["xformOp:translate", "xformOp:rotateXYZ", "xformOp:scale"], false);
        checks.push("GLR-011-" + solar_names[index]);
        if !_ok(record) {
            findings.push(_finding("GLR-011-array", path,
                "solar-array station root is missing"));
            continue;
        }
        let position = record.attrs["xformOp:translate"];
        let rotation = record.attrs["xformOp:rotateXYZ"];
        let scale = record.attrs["xformOp:scale"];
        if position == () || position.len() != 3 || solar_stations.len() != solar_names.len()
            || !_near(position[0], solar_stations[index].x, 0.002)
            || !_near(position[1], solar_stations[index].y, 0.002)
            || !_near(position[2], solar_stations[index].z, 0.002) {
            findings.push(_finding("GLR-011-array-position", path,
                "solar-array station differs from the ordered SysML datum"));
        }
        if rotation == () || rotation.len() != 3 || solar_rot_x.len() != solar_names.len()
            || !_near(rotation[0], solar_rot_x[index], 0.002) {
            findings.push(_finding("GLR-011-array-rotation-x", path,
                "solar-array X rotation does not map the local cell face outward"));
        }
        if rotation == () || rotation.len() != 3 || solar_rot.len() != solar_names.len()
            || !_near(rotation[2], solar_rot[index], 0.002) {
            findings.push(_finding("GLR-011-array-rotation", path,
                "solar-array outward orientation differs from the ordered SysML datum"));
        }
        if scale == () || scale.len() != 3 || solar_widths.len() != solar_names.len()
            || solar_frame_width == ()
            || !_near(scale[0], solar_widths[index] / solar_frame_width, 0.002)
            || !_near(scale[1], 1.0, 0.002) || !_near(scale[2], 1.0, 0.002) {
            findings.push(_finding("GLR-011-array-width", path,
                "panel width scale does not fit its paired bus-rail span"));
        }
    }

    let ramp_names = griffin_spec::ramp_names();
    let ramp_children = _sysml_list(source, "childNames");
    for ramp_name in ramp_names {
        let path = root + "/" + ramp_name;
        let ramp = _layout_query(doc_id, path,
            ["xformOp:translate", "xformOp:rotateXYZ", "lunco:visual:surface_length_m",
             "lunco:visual:surface_width_m"], false);
        checks.push("GRR-014-" + ramp_name);
        if !_ok(ramp) {
            findings.push(_finding("GRR-001-ramp", path,
                "visual egress-ramp root is missing"));
            continue;
        }
        for child_name in ramp_children {
            let child_path = path + "/" + child_name;
            checks.push("GRR-014-" + child_path);
            if !_ok(_layout_query(doc_id, child_path, [], false)) {
                findings.push(_finding("GRR-014-ramp-load-path", child_path,
                    "typed ramp load-path child is missing"));
            }
        }
        if ramp.attrs["lunco:visual:surface_length_m"] == ()
            || !_near(ramp.attrs["lunco:visual:surface_length_m"],
                _sysml_number(source, "rampSurfaceLengthM"), 0.002)
            || ramp.attrs["lunco:visual:surface_width_m"] == ()
            || !_near(ramp.attrs["lunco:visual:surface_width_m"],
                _sysml_number(source, "rampSurfaceWidthM"), 0.002) {
            findings.push(_finding("GRR-003-ramp-envelope", path,
                "visual ramp metadata differs from the typed SysML envelope"));
        }
    }
    #{ok: findings.len() == 0, doc_id: doc_id, root: root,
      source_revision: source.source_revision, checks: checks.len(),
      failures: findings.len(), findings: findings,
      metrics: #{document_generation: root_record.generation,
                 text_layer: "authored", perspective: "Edit"}}
}

fn visual_report_live(doc_id, root) {
    let report = visual_report(doc_id, root);
    if report.ok == () {
        return report;
    }
    print("GRIFFIN_VISUAL_EVIDENCE source_revision=" + report.source_revision.to_string()
        + " checks=" + report.checks.to_string()
        + " failures=" + report.failures.to_string());
    for finding in report.findings {
        print("[griffin-visual] ERROR " + finding.id + " "
            + finding.path + ": " + finding.message);
    }
    print("GRIFFIN VISUAL: " + (if report.ok { "PASS" } else { "FAIL" }));
    report
}

/// Print relational geometry checks for an open Editor document. This is
/// read-only and complements `part_report_live`: it checks where parts are,
/// not just whether their named prims exist.
fn layout_report_live(doc_id, root) {
    if doc_id == () {
        return #{ ok: false, error: "layout_report_live requires an explicit USD doc_id" };
    }
    let report = layout_report(doc_id, root);
    print("[griffin-layout] root=" + root + " doc_id=" + doc_id
        + " result=" + (if report.ok { "PASS" } else { "FAIL" })
        + " findings=" + report.findings.len());
    for finding in report.findings {
        print("[griffin-layout] ERROR " + finding.id + " "
            + finding.path + ": " + finding.message);
    }
    report
}

/// Read the live model's authored capacity and gate a proposed payload load.
/// It is intentionally read-only: the payload mass belongs to the composed
/// payload/mission instance, while the capacity belongs to the Griffin asset.
fn payload_limit_live(doc_id, root, payload_kg) {
    if doc_id == () { return #{ok: false, error: "payload_limit_live requires an explicit USD doc_id"}; }
    let source = _payload_requirement_source();
    let capacity = sysml_requirements::number(source,
        griffin_spec::qualified_attribute_name("payloadCapacityKg"));
    let checks = _payload_scene_checks(root, payload_kg, capacity);
    let result = sysml_requirements::evaluate_document(source, doc_id, checks);
    print("[griffin-lint] payload=" + payload_kg + "kg max="
        + max_payload_kg() + "kg result="
        + (if result.ok { "PASS" } else { "FAIL" }));
    result
}

/// Apply one command-limited ramp deployment edit to an open Editor document.
/// This is a live typed edit, not a file rewrite. The caller must re-run
/// `lint_live` after the deferred projection reports the new generation.
fn apply_ramp_deployment(doc_id, edit_target, root, ramp_path, angle_rad, parent_gen) {
    if doc_id == () || edit_target == () || root == () || ramp_path == () {
        return #{ ok: false, error: "live ramp edit requires doc_id, edit_target, root, and ramp_path" };
    }
    if ramp_path != root + "/EgressRampPort"
        && ramp_path != root + "/EgressRampStarboard" {
        return #{ ok: false, error: "ramp_path is not one of the two Griffin egress ramps" };
    }
    let limit = ramp_command_check(angle_rad);
    if !limit.ok { return limit; }

    let before = lint(doc_id, root);
    if !before.ok {
        return #{ ok: false, error: "refusing edit: Griffin contract already fails", report: before };
    }

    let angle_deg = angle_rad * 180.0 / pi_value();
    let result = cmd("ApplyUsdOps", #{
        doc_id: doc_id,
        parent_gen: parent_gen,
        label: "Griffin command-limited ramp deployment",
        ops: [
            #{ SetRotate: #{
                edit_target: edit_target,
                path: ramp_path,
                value: [0.0, 0.0, angle_deg],
            }},
            #{ SetAttribute: #{
                edit_target: edit_target,
                path: ramp_path,
                name: "lunco:deployment_angle_rad",
                type_name: "float",
                value: angle_rad.to_string(),
            }},
        ],
    });
    #{
        ok: result.ok == true,
        accepted: result.ok == true,
        edit: result,
        validation_pending: result.ok == true,
        next: "after projection, call griffin_requirements::lint_live(doc_id, root)",
    }
}
