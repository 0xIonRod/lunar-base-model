import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;

const ROOT = "/World/Griffin1";
const OWN = "GriffinRampRequirements::GriffinEgressRamp::";
const VERIFICATION = "Verify_GriffinRampFlightStow";

fn simulation_dependencies(me, ctx) {
    #{modelica_entities: [], entity_reads: [], entity_writes: [],
      query_reads: ["AnalyzeSysml", "QueryUsdPrim", "QueryUsdPrims"], required_inputs: []}
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn _source_attr(name) { OWN + name }
fn _source_number(source, name) {
    sysml_requirements::number(source, _source_attr(name))
}
fn _check(id, requirement, kind, path) {
    #{id: id, component: "ramp", requirement: requirement,
      verification: VERIFICATION, kind: kind, path: path}
}
fn _attribute_component(id, requirement, path, attr, index, expected) {
    #{id: id, component: "ramp", requirement: requirement,
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: attr, index: index, expected: expected, tolerance: 0.002}
}
fn _attribute(id, requirement, path, attr, expected) {
    #{id: id, component: "ramp", requirement: requirement,
      verification: VERIFICATION, kind: "attribute", path: path,
      attr: attr, expected: expected, tolerance: 0.002}
}
fn _relationship(id, requirement, path, rel, target) {
    #{id: id, component: "ramp", requirement: requirement,
      verification: VERIFICATION, kind: "relationship", path: path,
      rel: rel, targets: [target]}
}
fn _constraint(id, requirement, name, bindings) {
    sysml_requirements::constraint_check(id, "ramp", requirement,
        VERIFICATION, "GriffinRampRequirements::" + name,
        bindings, "derived", 0.0)
}
fn _stowed_rail_leg_envelope() {
    let rail_paths = [];
    for side in ["EgressRampPort", "EgressRampStarboard"] {
        for section in ["DeckSection", "MiddleSection", "MiddleSection/ToeSection"] {
            for rail in ["OuterRail", "InnerRail"] {
                rail_paths.push(ROOT + "/" + side + "/" + section + "/" + rail);
            }
        }
    }
    let leg_paths = [];
    let leg_shapes = ["StrutOuter", "StrutInner", "ShockPiston", "FootPad",
        "MountClevisOuter", "MountClevisInner", "FootPadPlate", "MountAxle",
        "BodyMountArm", "FootPadCollider"];
    for leg in ["LegPX", "LegNX", "LegPZ", "LegNZ"] {
        for shape in leg_shapes {
            leg_paths.push(ROOT + "/" + leg + "/LandingLegVisual/" + shape);
        }
    }
    let paths = [];
    for path in rail_paths { paths.push(path); }
    for path in leg_paths { paths.push(path); }
    let batch = query("QueryUsdPrims", #{paths: paths, geometry_bounds: true});
    if batch == () || batch.records == () || batch.records.len() != paths.len() {
        return #{ok: false, error: "composed rail or landing-leg bounds are incomplete"};
    }
    let by_path = #{};
    for record in batch.records {
        if record.geometry_bounds != () { by_path[record.path] = record.geometry_bounds; }
    }
    let lowest_rail = 1.0e30;
    for path in rail_paths {
        let bounds = by_path[path];
        if bounds == () || bounds.min == () || bounds.min.len() < 2 {
            return #{ok: false, error: "composed rail geometry bounds are missing", path: path};
        }
        if bounds.min[1] < lowest_rail { lowest_rail = bounds.min[1]; }
    }
    let highest_leg = -1.0e30;
    for path in leg_paths {
        let bounds = by_path[path];
        if bounds == () || bounds.max == () || bounds.max.len() < 2 {
            return #{ok: false, error: "composed landing-leg geometry bounds are missing", path: path};
        }
        if bounds.max[1] > highest_leg { highest_leg = bounds.max[1]; }
    }
    #{ok: true, lowest_stowed_rail_bottom_y_m: lowest_rail,
      highest_landing_leg_top_y_m: highest_leg,
      vertical_clearance_m: lowest_rail - highest_leg,
      rail_prim_count: rail_paths.len(), leg_prim_count: leg_paths.len()}
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let attributes = [];
    for name in ["rampSectionLengthM", "rampSectionGeometryToleranceM",
        "rampSurfaceCenterYM", "rampSurfaceThicknessM", "rampRailCenterYM",
        "rampRailHeightM", "rampMaxDeploymentAngleRad", "physicalRampMountY", "physicalRampPortMountX",
        "physicalRampStarboardMountX", "physicalRampSectionJointLimitRad",
        "physicalRampRootJointStowLimitRad", "physicalRampRootStowedAngleRad",
        "physicalRampSectionStowedAngleRad", "physicalRampToeSectionStowedAngleRad",
        "physicalRampSectionDriveTargetRad"] {
        attributes.push(_source_attr(name));
    }
    let source = sysml_requirements::source_with_selection(attributes,
        ["GriffinRampRequirements::grr017", "GriffinRampRequirements::grr018"],
        ["GriffinRampRequirements::Verify_GriffinRampFlightStow"]);
    if source == () || source.ok != true {
        throw("Griffin ramp flight-stow SysML source selection is invalid");
    }

    let surface_top_y = _source_number(source, "rampSurfaceCenterYM")
        + _source_number(source, "rampSurfaceThicknessM") / 2.0;
    let rail_bottom_y = _source_number(source, "rampRailCenterYM")
        - _source_number(source, "rampRailHeightM") / 2.0;
    let checks = [];
    checks.push(_constraint("GRR-017-flight-stow-angle-envelope", "grr017",
        "GRC022_RampFlightStowAnglesWithinTravel",
        #{rootStowAngleRad: _source_number(source, "physicalRampRootStowedAngleRad"),
          middleAngleRad: _source_number(source, "physicalRampSectionStowedAngleRad"),
          toeAngleRad: _source_number(source, "physicalRampToeSectionStowedAngleRad"),
          rootLimitRad: _source_number(source, "physicalRampRootJointStowLimitRad"),
          sectionLimitRad: _source_number(source, "physicalRampSectionJointLimitRad")}));
    checks.push(_constraint("GRR-018-rails-on-upper-track-face", "grr018",
        "GRC023_RailsRemainOnUpperTrackFace",
        #{railBottomYM: rail_bottom_y, walkingSurfaceTopYM: surface_top_y,
          toleranceM: _source_number(source, "rampSectionGeometryToleranceM")}));
    checks.push(_constraint("GRR-017-post-touchdown-unfold-target", "grr017",
        "GRC024_RampSectionDeploymentTargetIsLevel",
        #{deploymentTargetRad: _source_number(source, "physicalRampSectionDriveTargetRad")}));
    let envelope = _stowed_rail_leg_envelope();
    let envelope_binding = if envelope.ok == true {
        #{lowestStowedRailBottomYM: #{provider: "usd", state: "value",
              value: envelope.lowest_stowed_rail_bottom_y_m},
          highestLandingLegTopYM: #{provider: "usd", state: "value",
              value: envelope.highest_landing_leg_top_y_m},
          geometryToleranceM: #{provider: "source_literal", state: "value",
              value: _source_number(source, "rampSectionGeometryToleranceM")}}
    } else {
        #{lowestStowedRailBottomYM: #{provider: "usd", state: "unavailable", detail: envelope.error},
          highestLandingLegTopYM: #{provider: "usd", state: "unavailable", detail: envelope.error},
          geometryToleranceM: #{provider: "source_literal", state: "value",
              value: _source_number(source, "rampSectionGeometryToleranceM")}}
    };
    checks.push(sysml_requirements::constraint_check(
        "GRR-017-stowed-rails-clear-of-legs", "ramp", "grr017",
        VERIFICATION,
        "GriffinRampRequirements::GRC025_StowedRailsClearLandingLegEnvelope",
        envelope_binding, "usd", 0.0));

    let section_length = _source_number(source, "rampSectionLengthM");
    let middle_rad = _source_number(source, "physicalRampSectionStowedAngleRad");
    let toe_rad = _source_number(source, "physicalRampToeSectionStowedAngleRad");
    let root_rad = _source_number(source, "physicalRampRootStowedAngleRad");
    let middle_deg = middle_rad * 180.0 / 3.141592653589793;
    let toe_deg = toe_rad * 180.0 / 3.141592653589793;
    let root_deg = root_rad * 180.0 / 3.141592653589793;
    let ramp_names = ["EgressRampPort", "EgressRampStarboard"];
    let root_joint_names = ["RampHingePort", "RampHingeStarboard"];
    let joint_names = [
        ["RampSectionHingePort01", "RampSectionHingePort12"],
        ["RampSectionHingeStarboard01", "RampSectionHingeStarboard12"]
    ];
    for side_index in 0..2 {
        let ramp = ROOT + "/" + ramp_names[side_index];
        let side = if side_index == 0 { "port" } else { "starboard" };
        checks.push(_check("GRR-017-" + side + "-ramp", "grr017", "exists", ramp));
        checks[checks.len() - 1].expected_type = "Xform";
        checks.push(_attribute_component("GRR-017-" + side + "-mount-y", "grr017",
            ramp, "xformOp:translate", 1, _source_number(source, "physicalRampMountY")));
        let root_target_deg = if side_index == 0 { root_deg } else { -root_deg };
        checks.push(_attribute_component("GRR-017-" + side + "-root-stow-angle", "grr017",
            ramp, "xformOp:rotateXYZ", 2, root_target_deg));
        checks.push(_attribute_component("GRR-017-" + side + "-root-mirror", "grr017",
            ramp, "xformOp:rotateXYZ", 1, if side_index == 0 { 0.0 } else { 180.0 }));
        let root_joint = ROOT + "/" + root_joint_names[side_index];
        let deployment_limit_deg = _source_number(source,
            "rampMaxDeploymentAngleRad") * 180.0 / 3.141592653589793;
        let root_stow_limit_deg = _source_number(source,
            "physicalRampRootJointStowLimitRad") * 180.0 / 3.141592653589793;
        let root_lower_limit_deg = if side_index == 0 {
            -deployment_limit_deg
        } else { -root_stow_limit_deg };
        let root_upper_limit_deg = if side_index == 0 {
            root_stow_limit_deg
        } else { deployment_limit_deg };
        checks.push(_attribute("GRR-017-" + side + "-root-flight-target", "grr017",
            root_joint, "drive:angular:physics:targetPosition", root_target_deg));
        checks.push(_attribute("GRR-017-" + side + "-root-lower-limit", "grr017",
            root_joint, "physics:lowerLimit", root_lower_limit_deg));
        checks.push(_attribute("GRR-017-" + side + "-root-upper-limit", "grr017",
            root_joint, "physics:upperLimit", root_upper_limit_deg));

        let section_paths = [ramp + "/MiddleSection",
            ramp + "/MiddleSection/ToeSection"];
        for section_index in 0..2 {
            let section = section_paths[section_index];
            let angle_deg = if section_index == 0 { middle_deg } else { toe_deg };
            checks.push(_check("GRR-017-" + side + "-section-" + section_index.to_string(),
                "grr017", "exists", section));
            checks[checks.len() - 1].expected_type = "Xform";
            checks.push(_attribute_component("GRR-017-" + side + "-section-" + section_index.to_string() + "-x",
                "grr017", section, "xformOp:translate", 0, section_length));
            checks.push(_attribute_component("GRR-017-" + side + "-section-" + section_index.to_string() + "-rotation-z",
                "grr017", section, "xformOp:rotateXYZ", 2, angle_deg));

            let joint = ROOT + "/" + joint_names[side_index][section_index];
            let body0 = if section_index == 0 { ramp } else { section_paths[0] };
            let target_angle_deg = angle_deg;
            checks.push(_check("GRR-017-" + side + "-joint-" + section_index.to_string(),
                "grr017", "exists", joint));
            checks[checks.len() - 1].expected_type = "PhysicsRevoluteJoint";
            checks.push(_relationship("GRR-017-" + side + "-joint-" + section_index.to_string() + "-body0",
                "grr017", joint, "physics:body0", body0));
            checks.push(_relationship("GRR-017-" + side + "-joint-" + section_index.to_string() + "-body1",
                "grr017", joint, "physics:body1", section));
            checks.push(_attribute("GRR-017-" + side + "-joint-" + section_index.to_string() + "-flight-target",
                "grr017", joint, "drive:angular:physics:targetPosition", target_angle_deg));
            for rail_name in ["OuterRail", "InnerRail"] {
                let rail = section + "/" + rail_name;
                checks.push(_attribute_component("GRR-018-" + side + "-" + section_index.to_string() + "-" + rail_name + "-top-y",
                    "grr018", rail, "xformOp:translate", 1,
                    _source_number(source, "rampRailCenterYM")));
                checks.push(_attribute_component("GRR-018-" + side + "-" + section_index.to_string() + "-" + rail_name + "-height",
                    "grr018", rail, "xformOp:scale", 1,
                    _source_number(source, "rampRailHeightM")));
            }
        }
        let deck_section = ramp + "/DeckSection";
        for rail_name in ["OuterRail", "InnerRail"] {
            let rail = deck_section + "/" + rail_name;
            checks.push(_attribute_component("GRR-018-" + side + "-deck-" + rail_name + "-top-y",
                "grr018", rail, "xformOp:translate", 1,
                _source_number(source, "rampRailCenterYM")));
            checks.push(_attribute_component("GRR-018-" + side + "-deck-" + rail_name + "-height",
                "grr018", rail, "xformOp:scale", 1,
                _source_number(source, "rampRailHeightM")));
        }
    }

    let result = sysml_requirements::evaluate(source, checks);
    let evidence = [];
    let evidence_failures = [];
    for requirement_name in ["GRR-017", "GRR-018"] {
        let handle = sysml_requirements::requirement_handle_by_short_name(source,
            requirement_name);
        let selected = if handle.ok == true {
            sysml_requirements::provenance(source, handle.handle)
        } else { handle };
        if selected.ok == true {
            evidence.push(selected.evidence);
        } else {
            evidence_failures.push(#{requirement: requirement_name,
                error: selected.error});
        }
    }
    result.source_evidence = evidence;
    result.source_evidence_failures = evidence_failures;
    if evidence_failures.len() > 0 {
        result.ok = false;
        for failure in evidence_failures { result.failures.push(failure); }
        result.failure_count += evidence_failures.len();
    }
    result.metrics = #{clock: clock_snapshot(), root: ROOT,
        component_package: "GriffinRampRequirements",
        verification: VERIFICATION, separate_component_document: true,
        stowed_rail_leg_envelope: envelope};
    report_structured_verdict(result, "GRIFFIN RAMP FLIGHT STOW",
        "GRIFFIN_RAMP_FLIGHT_STOW");
    this.done = true;
    if result.ok != true {
        print("[griffin-ramp-stow] source or composed pose checks failed: "
            + result.failure_count.to_string());
    }
}
