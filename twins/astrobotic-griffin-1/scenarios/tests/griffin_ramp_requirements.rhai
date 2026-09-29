import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
import "lunco://scripting/tools/authoring_measurements" as authoring_measurements;
import "lunco://scripting/tools/mechanical_relations" as mechanical_relations;

const ROOT = "/World/Griffin1";
const OWN = "GriffinRampRequirements::GriffinEgressRamp::";
const VERIFICATION = "Verify_GriffinRampRequirements";

fn simulation_dependencies(me, ctx) {
    #{modelica_entities: [], entity_reads: [], entity_writes: [],
      query_reads: ["AnalyzeSysml", "QueryUsdPrim", "QueryUsdPrims"],
      required_inputs: []}
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
    this.batch = 0;
    this.source = ();
    this.aggregate = ();
    this.deck_profile = ();
}

fn _source_attr(name) { OWN + name }
fn _source_number(source, name) {
    sysml_requirements::number(source, _source_attr(name))
}
fn _source_enum_names(source, name) {
    sysml_requirement_checks::source_enum_identifiers(source, _source_attr(name))
}
fn _source_enum_name(source, name) {
    let value = sysml_requirements::native_value(source, _source_attr(name));
    if sysml_enum_is(value) { return value.literal; }
    if string_is(value) { return value; }
    ""
}
fn _check(id, component, requirement, kind, path) {
    #{id: id, component: component, requirement: requirement,
      verification: VERIFICATION, kind: kind, path: path}
}
fn _attribute_component(id, requirement, path, attr, index, expected) {
    #{id: id, component: "ramp", requirement: requirement,
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: attr, index: index, expected: expected, tolerance: 0.002}
}
fn _attribute_value(id, requirement, path, attr, expected) {
    #{id: id, component: "ramp", requirement: requirement,
      verification: VERIFICATION, kind: "attribute", path: path,
      attr: attr, expected: expected, tolerance: 0.002}
}
fn _relationship(id, requirement, path, rel, target) {
    #{id: id, component: "ramp", requirement: requirement,
      verification: VERIFICATION, kind: "relationship", path: path,
      rel: rel, targets: [target]}
}
fn _constraint(source, id, requirement, name, bindings) {
    let typed_bindings = #{};
    for name in bindings.keys() {
        let value = bindings[name];
        typed_bindings[name] = if type_of(value) == "map" {
            value
        } else {
            #{provider: "source_literal", state: "value", value: value,
              provider_generation: source.source_revision,
              source_revision: source.source_revision}
        };
    }
    sysml_requirements::required_constraint_check(id, "ramp", requirement,
        VERIFICATION, "GriffinRampRequirements::" + name,
        typed_bindings, "typed", 0.0)
}
fn _measurement_value(observation, field, label) {
    if observation == () || observation.ok != true || observation[field] == () {
        return #{provider: "usd", state: "unavailable",
            detail: if observation == () || observation.message == () {
                label + " could not be measured from composed collision geometry"
            } else { observation.message },
            doc_id: if observation == () { () } else { observation.doc_id },
            document_generation: if observation == () { () } else { observation.document_generation },
            stage_generation: if observation == () { () } else { observation.stage_generation }};
    }
    #{provider: "usd", state: "value", value: observation[field],
      doc_id: observation.doc_id,
      document_generation: observation.document_generation,
      stage_generation: observation.stage_generation}
}
fn _maximum_abs(values) {
    if values == () || values.len() == 0 { return (); }
    let maximum = 0.0;
    for value in values {
        if value.abs() > maximum { maximum = value.abs(); }
    }
    maximum
}
fn _section_path(ramp, index) {
    if index == 0 { return ramp + "/DeckSection"; }
    if index == 1 { return ramp + "/MiddleSection"; }
    ramp + "/MiddleSection/ToeSection"
}
fn _side_suffix(side) { if side == "port" { "Port" } else { "Starboard" } }
fn _merge_batch_verdict(current, next) {
    if current == "error" || next == "error" { return "error"; }
    if current == "fail" || next == "fail" { return "fail"; }
    if current == "inconclusive" || next == "inconclusive" { return "inconclusive"; }
    if current == "unverified" || next == "unverified" { return "unverified"; }
    if current == "" { return next; }
    "pass"
}
fn _accumulate_batch(aggregate, part) {
    if aggregate == () {
        aggregate = #{ok: true, verdict: "", results: [], result_chunks: [],
            failures: [], non_pass_results: [], requirement_count: 0,
            requirement_names: [], requirement_summary: #{}, check_count: 0,
            pass_count: 0, failure_count: 0, inconclusive_count: 0,
            error_count: 0, unverified_count: 0, non_pass_count: 0,
            streamed: true};
    }
    aggregate.verdict = _merge_batch_verdict(aggregate.verdict, part.verdict);
    for field in ["check_count", "pass_count", "failure_count",
        "inconclusive_count", "error_count", "unverified_count", "non_pass_count"] {
        aggregate[field] += part[field];
    }
    for failure in part.failures {
        if aggregate.failures.len() < 64 { aggregate.failures.push(failure); }
    }
    for failure in part.non_pass_results {
        if aggregate.non_pass_results.len() < 64 {
            aggregate.non_pass_results.push(failure);
        }
    }
    for requirement in part.requirement_names {
        if aggregate.requirement_summary[requirement] == () {
            aggregate.requirement_summary[requirement] = #{checks: 0,
                passes: 0, failures: 0, inconclusive: 0, errors: 0,
                unverified: 0};
            aggregate.requirement_names.push(requirement);
        }
        let from = part.requirement_summary[requirement];
        for field in ["checks", "passes", "failures", "inconclusive", "errors", "unverified"] {
            aggregate.requirement_summary[requirement][field] += from[field];
        }
    }
    aggregate.requirement_count = aggregate.requirement_names.len();
    aggregate.verification = part.verification;
    aggregate.source_revision = part.source_revision;
    aggregate.source_files = part.source_files;
    aggregate.ok = aggregate.verdict == "pass";
    aggregate
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let batch = this.batch;
    if batch >= 6 { return; }
    let side_index = (batch / 3).to_int();
    let section_index = batch % 3;
    let current_side = if side_index == 0 { "port" } else { "starboard" };
    let attributes = [];
    for name in [
        "sectionAsset", "sectionInstances", "intermediateJointInstances", "treadInstances",
        "railJointPinInstances",
        "transitionBody", "transitionContact", "transitionJoints",
        "rampCount", "rampSurfaceLengthM", "rampSectionCount", "rampSectionLengthM",
        "rampSectionGeometryToleranceM", "rampSurfaceWidthM", "rampSurfaceThicknessM",
        "rampWheelClearanceM", "rampRailHeightM", "rampRailWidthM", "rampRailOffsetZM",
        "rampRailJointPinRadiusM", "rampRailJointPinLengthM",
        "rampSurfaceCenterYM", "rampRailCenterYM", "rampMaxDeploymentAngleRad",
        "assemblyTrackWidthM", "contactTrackGeometryToleranceM", "assemblyTreadCount",
        "assemblyTreadCountPerSection", "assemblyTreadWidthM", "assemblyTreadHeightM",
        "assemblyTreadFirstCenterXM", "assemblyTreadPitchM", "assemblyUnderBeamWidthM",
        "assemblyUnderBeamHeightM", "assemblyUnderBeamCenterYM",
        "assemblyUnderBeamCenterOffsetZM", "assemblySidePostCountPerSectionPerSide",
        "assemblySidePostWidthM", "assemblySidePostDepthM",
        "assemblySidePostEmbeddedDepthM", "assemblySidePostFirstCenterXM",
        "assemblySidePostPitchM",
        "rampSectionHingeBarrelRadiusM", "rampSectionHingeBarrelLengthM",
        "rampSectionHingeBarrelCenterYM", "rampPortMountX", "rampStarboardMountX",
        "rampMountY", "rampMountZ", "hingeAxis", "physicalRampDeckTransitionRequiredOverlapM",
        "physicalRampDeckTransitionLengthM", "physicalRampDeckTransitionInterfaceToleranceM",
        "physicalRampTerrainContactToleranceM", "physicalRampPortMountX",
        "physicalRampStarboardMountX", "physicalRampMountY", "physicalRampMountZ",
        "physicalRampPortDeploymentAngleRad", "physicalRampStarboardDeploymentAngleRad",
        "physicalRampMassKg", "physicalRampSectionMassKg",
        "physicalRampSectionInertiaXKgM2", "physicalRampSectionInertiaYKgM2",
        "physicalRampSectionInertiaZKgM2", "physicalRampSectionMassPartitionToleranceKg",
        "physicalRampSectionJointLimitRad", "physicalRampSectionStowedRelativeAngleRad",
        "physicalRampSectionJointFrameOffsetRad",
        "physicalRampPortRootJointStowLimitRad", "physicalRampRootStowedAngleRad",
        "physicalRampStarboardRootJointStowLimitRad",
        "physicalRampDeckTransitionOutboardX", "physicalRampDeckTransitionCenterY",
        "physicalRampSectionDeploymentRelativeAngleRad",
        "physicalRampJointDriveStiffnessNmPerDeg",
        "physicalRampRootJointDriveDampingNmPerDegPerSec",
        "physicalRampSectionJointDriveDampingNmPerDegPerSec",
        "physicalRampJointDriveMaxTorqueNm",
        "physicalRampSectionMassPropertiesToleranceKgM2",
        "physicalRampDeckTransitionMassKg", "physicalRampDeckTransitionInertiaKgM2"
    ] { attributes.push(_source_attr(name)); }
    let requirements = [];
    for name in ["grr001", "grr002", "grr003", "grr004", "grr005", "grr006",
        "grr007", "grr008", "grr009", "grr011", "grr012",
        "grr013", "grr014", "grr015", "grr016"] {
        requirements.push("GriffinRampRequirements::" + name);
    }
    let source = this.source;
    if source == () {
        source = sysml_requirements::source_with_selection(attributes, requirements,
            ["GriffinRampRequirements::Verify_GriffinRampRequirements"]);
        this.source = source;
    }
    let section_names = _source_enum_names(source, "sectionInstances");
    let joint_names = _source_enum_names(source, "intermediateJointInstances");
    let tread_names = _source_enum_names(source, "treadInstances");
    let rail_pin_names = _source_enum_names(source, "railJointPinInstances");
    let transition_body_name = _source_enum_name(source, "transitionBody");
    let transition_contact_name = _source_enum_name(source, "transitionContact");
    let transition_joint_names = _source_enum_names(source, "transitionJoints");
    if section_names.len() != 3 || joint_names.len() != 4 || tread_names.len() != 4
        || rail_pin_names.len() != 2
        || transition_body_name == "" || transition_contact_name == ""
        || transition_joint_names.len() != 2 {
        throw("Griffin ramp SysML identity collections are incomplete");
    }
    let checks = [];
    let section_count = _source_number(source, "rampSectionCount").to_int();
    let section_length = _source_number(source, "rampSectionLengthM");
    let total_length = _source_number(source, "rampSurfaceLengthM");
    let geometry_tolerance = _source_number(source, "rampSectionGeometryToleranceM");
    let ramp_width = _source_number(source, "rampSurfaceWidthM");
    let wheel_clearance = _source_number(source, "rampWheelClearanceM");
    let track_width = _source_number(source, "assemblyTrackWidthM");
    let wheel_z = sysml_requirement_checks::source_number_list(source,
        "FlipRequirements::FlipRover::wheelStationZ");
    let wheel_width = sysml_requirements::number(source, "FlipRequirements::FlipRover::wheelWidthM");
    let half_track = _maximum_abs(wheel_z);
    if section_count != 3 || section_length == () || total_length == ()
        || geometry_tolerance == () || ramp_width == () || wheel_clearance == ()
        || track_width == () || wheel_z.len() != 4 || half_track == () || wheel_width == () {
        throw("Griffin ramp or FLIP interface datums are incomplete");
    }

    if batch == 0 {
        checks.push(_constraint(source, "GRR-003-rover-envelope", "grr003",
            "GRC003_WidthClearsFlipWheelEnvelope",
            #{rampWidthM: ramp_width, wheelHalfTrackM: half_track,
              wheelHalfWidthM: wheel_width / 2.0, wheelClearanceM: wheel_clearance}));
        checks.push(_constraint(source, "GRR-006-contact-track-width", "grr006",
            "GRC016_ContactTrackClearsTire",
            #{trackWidthM: track_width, wheelWidthM: wheel_width,
              wheelClearanceM: wheel_clearance}));
        checks.push(_constraint(source, "GRR-016-section-envelope", "grr016",
            "GRC018_SectionedRampMatchesEnvelope",
            #{totalLengthM: total_length, sectionLengthM: section_length,
              sectionCount: section_count, measuredLengthDeviationM: 0.0,
              toleranceM: geometry_tolerance}));
        checks.push(_constraint(source, "GRR-013-tread-count", "grr013",
            "GRC021_RampTreadCountMatchesSections",
            #{totalTreadCount: _source_number(source, "assemblyTreadCount").to_int(),
              treadCountPerSection: _source_number(source, "assemblyTreadCountPerSection").to_int(),
              sectionCount: section_count}));
        checks.push(_constraint(source, "GRR-011-mass-partition", "grr011",
            "GRC019_RampSectionMassPartition",
            #{totalMassKg: _source_number(source, "physicalRampMassKg"),
              sectionMassKg: _source_number(source, "physicalRampSectionMassKg"),
              sectionCount: section_count,
              toleranceKg: _source_number(source, "physicalRampSectionMassPartitionToleranceKg")}));
        checks.push(_constraint(source, "GRR-011-section-inertia", "grr011",
            "GRC020_RampSectionInertiaMatchesEnvelope",
            #{measuredXKgM2: _source_number(source, "physicalRampSectionInertiaXKgM2"),
              measuredYKgM2: _source_number(source, "physicalRampSectionInertiaYKgM2"),
              measuredZKgM2: _source_number(source, "physicalRampSectionInertiaZKgM2"),
              sectionMassKg: _source_number(source, "physicalRampSectionMassKg"),
              sectionLengthM: section_length, outsideWidthM: ramp_width,
              thicknessM: _source_number(source, "rampSurfaceThicknessM"),
              toleranceKgM2: _source_number(source, "physicalRampSectionMassPropertiesToleranceKgM2")}));
    }

    let ramp_roots = [ROOT + "/EgressRampPort", ROOT + "/EgressRampStarboard"];
    let deck_profile_compatible = this.deck_profile;
    if batch == 0 {
        checks.push(#{id: "GRR-007-separate-ramp-instances", component: "ramp",
            requirement: "grr007", verification: VERIFICATION, kind: "children",
            path: ROOT, paths: ramp_roots});
        let deck_observation = griffin_visual_builder::physical_top_deck_collider_observation((), ROOT);
        deck_profile_compatible = if deck_observation.ok == true
            && (deck_observation.state == "pass" || deck_observation.state == "fail") {
            #{provider: "usd", state: "value",
              value: deck_observation.state == "pass",
              doc_id: deck_observation.doc_id,
              document_generation: deck_observation.document_generation,
              stage_generation: deck_observation.stage_generation}
        } else {
            #{provider: "usd", state: "unavailable",
              detail: "upper-deck collision profile is unavailable",
              doc_id: if deck_observation == () { () } else { deck_observation.doc_id },
              document_generation: if deck_observation == () { () } else { deck_observation.document_generation },
              stage_generation: if deck_observation == () { () } else { deck_observation.stage_generation }}
        };
        this.deck_profile = deck_profile_compatible;
    }
    let transition_name = transition_body_name;
    let contact_name = transition_contact_name;
    let pi = 3.141592653589793;

    for side in [current_side] {
        let suffix = _side_suffix(side);
        let ramp = ROOT + "/EgressRamp" + suffix;
        let mount_x = _source_number(source, if side == "port" {
            "physicalRampPortMountX"
        } else {
            "physicalRampStarboardMountX"
        });
        let physical_angle = _source_number(source, if side == "port" {
            "physicalRampPortDeploymentAngleRad"
        } else {
            "physicalRampStarboardDeploymentAngleRad"
        });
        let root_joint = ROOT + "/RampHinge" + suffix;
        let joint_offset = if side == "port" { 0 } else { 2 };

        if section_index == 0 {
        checks.push(_check("GRR-001-" + side + "-ramp-root", "ramp", "grr001", "exists", ramp));
        checks[checks.len() - 1].expected_type = "Xform";
        checks.push(_attribute_component("GRR-004-" + side + "-mount-x", "grr004",
            ramp, "xformOp:translate", 0, mount_x));
        checks.push(_attribute_component("GRR-004-" + side + "-mount-y", "grr004",
            ramp, "xformOp:translate", 1, _source_number(source, "physicalRampMountY")));
        checks.push(_attribute_component("GRR-004-" + side + "-mount-z", "grr004",
            ramp, "xformOp:translate", 2, _source_number(source, "physicalRampMountZ")));
        checks.push(_attribute_component("GRR-012-" + side + "-deployed-test-pose", "grr012",
            ramp, "xformOp:rotateXYZ", 2, physical_angle * 180.0 / pi));
        checks.push(#{id: "GRR-003-" + side + "-outside-width", component: "ramp",
            requirement: "grr003", verification: VERIFICATION, kind: "attribute",
            path: ramp, attr: "lunco:operational_width_m",
            expected_attr: _source_attr("rampSurfaceWidthM"), tolerance: 0.002});
        checks.push(_check("GRR-002-" + side + "-deck-hinge", "ramp_joint", "grr002", "exists", root_joint));
        checks[checks.len() - 1].expected_type = "PhysicsRevoluteJoint";
        checks.push(_relationship("GRR-002-" + side + "-body0", "grr002",
            root_joint, "physics:body0", ROOT));
        checks.push(_relationship("GRR-002-" + side + "-body1", "grr002",
            root_joint, "physics:body1", ramp));
        checks.push(#{id: "GRR-005-" + side + "-axis", component: "ramp_joint",
            requirement: "grr005", verification: VERIFICATION,
            kind: "attribute_equals", path: root_joint,
            attr: "physics:axis", expected: "Z"});
        checks.push(_attribute_value("GRR-016-" + side + "-root-stiffness",
            "grr016", root_joint, "drive:angular:physics:stiffness",
            _source_number(source, "physicalRampJointDriveStiffnessNmPerDeg")));
        checks.push(_attribute_value("GRR-016-" + side + "-root-damping",
            "grr016", root_joint, "drive:angular:physics:damping",
            _source_number(source, "physicalRampRootJointDriveDampingNmPerDegPerSec")));
        checks.push(_attribute_value("GRR-016-" + side + "-root-torque",
            "grr016", root_joint, "drive:angular:physics:maxForce",
            _source_number(source, "physicalRampJointDriveMaxTorqueNm")));
        let deployment_limit_deg = _source_number(source, "rampMaxDeploymentAngleRad") * 180.0 / pi;
        let root_stow_limit_deg = _source_number(source, if side == "port" {
            "physicalRampPortRootJointStowLimitRad"
        } else { "physicalRampStarboardRootJointStowLimitRad" }) * 180.0 / pi;
        let root_lower_limit_deg = if side == "port" {
            -deployment_limit_deg
        } else { -root_stow_limit_deg };
        let root_upper_limit_deg = if side == "port" {
            root_stow_limit_deg
        } else { deployment_limit_deg };
        checks.push(_attribute_value("GRR-005-" + side + "-lower-limit", "grr005",
            root_joint, "physics:lowerLimit", root_lower_limit_deg));
        checks.push(_attribute_value("GRR-005-" + side + "-upper-limit", "grr005",
            root_joint, "physics:upperLimit", root_upper_limit_deg));
        checks.push(_constraint(source, "GRR-005-" + side + "-command-envelope", "grr005",
            "GRC005_DeploymentCommandWithinLimit",
            #{commandRad: physical_angle,
              limitRad: _source_number(source, "rampMaxDeploymentAngleRad")}));
        }

        let section_paths = [];
        for index in section_index..section_index + 1 {
            let section = _section_path(ramp, index);
            section_paths.push(section);
            checks.push(_check("GRR-001-" + side + "-section-" + index.to_string(),
                "ramp", "grr001", "exists", section));
            checks[checks.len() - 1].expected_type = "Xform";
            if index > 0 {
                let section_body = section;
                checks.push(#{id: "GRR-011-" + side + "-section-" + index.to_string() + "-mass",
                    component: "ramp", requirement: "grr011", verification: VERIFICATION,
                    kind: "attribute", path: section_body, attr: "physics:mass",
                    expected_attr: _source_attr("physicalRampSectionMassKg"), tolerance: 0.002});
            }
            let section_body = if index == 0 { ramp } else { section };
            checks.push(#{id: "GRR-011-" + side + "-section-" + index.to_string() + "-inertia-x",
                component: "ramp", requirement: "grr011", verification: VERIFICATION,
                kind: "attribute_component", path: section_body,
                attr: "physics:diagonalInertia", index: 0,
                expected_attr: _source_attr("physicalRampSectionInertiaXKgM2"), tolerance: 0.02});
            checks.push(#{id: "GRR-011-" + side + "-section-" + index.to_string() + "-inertia-y",
                component: "ramp", requirement: "grr011", verification: VERIFICATION,
                kind: "attribute_component", path: section_body,
                attr: "physics:diagonalInertia", index: 1,
                expected_attr: _source_attr("physicalRampSectionInertiaYKgM2"), tolerance: 0.02});
            checks.push(#{id: "GRR-011-" + side + "-section-" + index.to_string() + "-inertia-z",
                component: "ramp", requirement: "grr011", verification: VERIFICATION,
                kind: "attribute_component", path: section_body,
                attr: "physics:diagonalInertia", index: 2,
                expected_attr: _source_attr("physicalRampSectionInertiaZKgM2"), tolerance: 0.02});

            let track_center = half_track;
            for track in [
                #{name: "RampTrackPort", center_z: track_center},
                #{name: "RampTrackStarboard", center_z: -track_center},
            ] {
                let track_path = section + "/" + track.name;
                checks.push(_check("GRR-006-" + side + "-" + index.to_string() + "-" + track.name,
                    "ramp_track", "grr006", "exists", track_path));
                checks[checks.len() - 1].expected_type = "Mesh";
                checks.push(#{id: "GRR-006-" + side + "-" + index.to_string() + "-collision-" + track.name,
                    component: "ramp_track", requirement: "grr006", verification: VERIFICATION,
                    kind: "attribute_equals", path: track_path,
                    attr: "physics:collisionEnabled", expected: true});
                checks.push(#{id: "GRR-006-" + side + "-" + index.to_string() + "-hull-" + track.name,
                    component: "ramp_track", requirement: "grr006", verification: VERIFICATION,
                    kind: "attribute_equals", path: track_path,
                    attr: "physics:approximation", expected: "convexHull"});
                for dim in [
                    #{name: "length", index: 0, attr: "rampSectionLengthM"},
                    #{name: "thickness", index: 1, attr: "rampSurfaceThicknessM"},
                    #{name: "width", index: 2, attr: "assemblyTrackWidthM"},
                ] {
                    checks.push(sysml_requirement_checks::collision_bounds_component(
                        "GRR-006-" + side + "-" + index.to_string() + "-" + track.name + "-" + dim.name,
                        "ramp_track", "grr006", VERIFICATION, track_path, dim.index,
                        _source_attr(dim.attr), 2.0, 0.002));
                }
                checks.push(_attribute_component("GRR-006-" + side + "-" + index.to_string() + "-" + track.name + "-z",
                    "grr006", track_path, "xformOp:translate", 2, track.center_z));
                checks.push(_attribute_component("GRR-006-" + side + "-" + index.to_string() + "-" + track.name + "-y",
                    "grr006", track_path, "xformOp:translate", 1,
                    _source_number(source, "rampSurfaceCenterYM")));
                if index == section_count - 1 {
                    let bevel = mechanical_relations::planar_horizontal_face_bevel_run(
                        _source_number(source, "rampSurfaceThicknessM"), physical_angle);
                    for point in [
                        #{name: "toe-top-x", point: 2, axis: 0, value: section_length},
                        #{name: "toe-bottom-x", point: 3, axis: 0, value: section_length - bevel},
                        #{name: "toe-top-y", point: 2, axis: 1,
                          value: _source_number(source, "rampSurfaceThicknessM") / 2.0},
                        #{name: "toe-bottom-y", point: 3, axis: 1,
                          value: -_source_number(source, "rampSurfaceThicknessM") / 2.0},
                    ] {
                        checks.push(sysml_requirement_checks::array_component(
                            "GRR-006-" + side + "-" + track.name + "-" + point.name,
                            "ramp_track", "grr006", VERIFICATION, track_path, "points",
                            [point.point, point.axis], point.value, 0.002));
                    }
                }
            }

            for rail in [
                #{name: "OuterRail", z: _source_number(source, "rampRailOffsetZM")},
                #{name: "InnerRail", z: -_source_number(source, "rampRailOffsetZM")},
            ] {
                let rail_path = section + "/" + rail.name;
                for dim in [
                    #{name: "length", axis: 0, attr: "rampSectionLengthM"},
                    #{name: "height", axis: 1, attr: "rampRailHeightM"},
                    #{name: "width", axis: 2, attr: "rampRailWidthM"},
                ] {
                    checks.push(sysml_requirement_checks::extent_component(
                        "GRR-008-" + side + "-" + index.to_string() + "-" + rail.name + "-" + dim.name,
                        "ramp_rail", "grr008", VERIFICATION, rail_path, dim.axis,
                        _source_attr(dim.attr), 1.0, 0.002));
                }
                checks.push(_attribute_component("GRR-008-" + side + "-" + index.to_string() + "-" + rail.name + "-y",
                    "grr008", rail_path, "xformOp:translate", 1,
                    _source_number(source, "rampRailCenterYM")));
                checks.push(_attribute_component("GRR-008-" + side + "-" + index.to_string() + "-" + rail.name + "-z",
                    "grr008", rail_path, "xformOp:translate", 2, rail.z));
                checks.push(_attribute_component("GRR-008-" + side + "-" + index.to_string() + "-" + rail.name + "-x",
                    "grr008", rail_path, "xformOp:translate", 0, section_length / 2.0));
            }

            for pin_index in 0..rail_pin_names.len() {
                let pin_name = rail_pin_names[pin_index];
                let pin_z = if pin_index == 0 {
                    _source_number(source, "rampRailOffsetZM")
                } else {
                    -_source_number(source, "rampRailOffsetZM")
                };
                let pin_path = section + "/" + pin_name;
                checks.push(_check("GRR-008-" + side + "-" + index.to_string() + "-" + pin_name,
                    "ramp_rail_joint", "grr008", "exists", pin_path));
                checks[checks.len() - 1].expected_type = "Cylinder";
                for dimension in [
                    #{name: "radius", attr: "rampRailJointPinRadiusM"},
                    #{name: "height", attr: "rampRailJointPinLengthM"},
                ] {
                    checks.push(#{id: "GRR-008-" + side + "-" + index.to_string() + "-" + pin_name + "-" + dimension.name,
                        component: "ramp_rail_joint", requirement: "grr008", verification: VERIFICATION,
                        kind: "attribute", path: pin_path, attr: dimension.name,
                        expected_attr: _source_attr(dimension.attr), tolerance: 0.002});
                }
                checks.push(_attribute_component("GRR-008-" + side + "-" + index.to_string() + "-" + pin_name + "-x",
                    "grr008", pin_path, "xformOp:translate", 0, 0.0));
                checks.push(_attribute_component("GRR-008-" + side + "-" + index.to_string() + "-" + pin_name + "-y",
                    "grr008", pin_path, "xformOp:translate", 1,
                    _source_number(source, "rampRailCenterYM")));
                checks.push(_attribute_component("GRR-008-" + side + "-" + index.to_string() + "-" + pin_name + "-z",
                    "grr008", pin_path, "xformOp:translate", 2, pin_z));
            }

            let walking_surface_top_y = _source_number(source, "rampSurfaceCenterYM")
                + _source_number(source, "rampSurfaceThicknessM") / 2.0;
            let rail_top_y = _source_number(source, "rampRailCenterYM")
                + _source_number(source, "rampRailHeightM") / 2.0;
            let post_bottom_y = walking_surface_top_y
                - _source_number(source, "assemblySidePostEmbeddedDepthM");
            let post_height = rail_top_y - post_bottom_y;
            let post_center_y = (rail_top_y + post_bottom_y) / 2.0;
            for post_side in [
                #{name: "Port", z: _source_number(source, "rampRailOffsetZM")},
                #{name: "Starboard", z: -_source_number(source, "rampRailOffsetZM")},
            ] {
                for post_index in 0.._source_number(source, "assemblySidePostCountPerSectionPerSide").to_int() {
                    let post_path = section + "/SidePost" + post_side.name
                        + (post_index + 1).to_string();
                    checks.push(#{id: "GRR-009-" + side + "-" + index.to_string() + "-" + post_side.name + post_index.to_string(),
                        component: "ramp_support", requirement: "grr009", verification: VERIFICATION,
                        kind: "extent_component", path: post_path, index: 1, multiplier: 1.0,
                        expected: post_height, tolerance: 0.002});
                    checks.push(_attribute_component("GRR-009-" + side + "-" + index.to_string() + "-" + post_side.name + post_index.to_string() + "-y",
                        "grr009", post_path, "xformOp:translate", 1, post_center_y));
                    checks.push(_attribute_component("GRR-009-" + side + "-" + index.to_string() + "-" + post_side.name + post_index.to_string() + "-x",
                        "grr009", post_path, "xformOp:translate", 0,
                        _source_number(source, "assemblySidePostFirstCenterXM")
                            + _source_number(source, "assemblySidePostPitchM") * post_index));
                    checks.push(_attribute_component("GRR-009-" + side + "-" + index.to_string() + "-" + post_side.name + post_index.to_string() + "-z",
                        "grr009", post_path, "xformOp:translate", 2, post_side.z));
                }
            }

            for tread_index in 0.._source_number(source, "assemblyTreadCountPerSection").to_int() {
                for track in [
                    #{name: "Port", center_z: half_track},
                    #{name: "Starboard", center_z: -half_track},
                ] {
                    let tread_path = section + "/Tread" + track.name + (tread_index + 1).to_string();
                    let x = _source_number(source, "assemblyTreadFirstCenterXM")
                        + _source_number(source, "assemblyTreadPitchM") * tread_index;
                    for dim in [
                        #{name: "length", axis: 0, attr: "assemblyTreadWidthM"},
                        #{name: "height", axis: 1, attr: "assemblyTreadHeightM"},
                        #{name: "width", axis: 2, attr: "assemblyTrackWidthM"},
                    ] {
                        let check_id = "GRR-013-" + side + "-" + index.to_string() + "-" + track.name + tread_index.to_string() + "-" + dim.name;
                        let extent = sysml_requirement_checks::extent_component(check_id,
                            "ramp_tread", "grr013", VERIFICATION, tread_path,
                            dim.axis, _source_attr(dim.attr), 1.0, 0.002);
                        checks.push(extent);
                    }
                    checks.push(_attribute_component("GRR-013-" + side + "-" + index.to_string() + "-" + track.name + tread_index.to_string() + "-x",
                        "grr013", tread_path, "xformOp:translate", 0, x));
                    checks.push(_attribute_component("GRR-013-" + side + "-" + index.to_string() + "-" + track.name + tread_index.to_string() + "-z",
                        "grr013", tread_path, "xformOp:translate", 2, track.center_z));
                }
            }

            for beam in [
                #{name: "UnderBeamPort", z: _source_number(source, "assemblyUnderBeamCenterOffsetZM")},
                #{name: "UnderBeamStarboard", z: -_source_number(source, "assemblyUnderBeamCenterOffsetZM")},
            ] {
                let beam_path = section + "/" + beam.name;
                for dim in [
                    #{name: "length", axis: 0, attr: "rampSectionLengthM"},
                    #{name: "height", axis: 1, attr: "assemblyUnderBeamHeightM"},
                    #{name: "width", axis: 2, attr: "assemblyUnderBeamWidthM"},
                ] {
                    checks.push(sysml_requirement_checks::extent_component(
                        "GRR-014-" + side + "-" + index.to_string() + "-" + beam.name + "-" + dim.name,
                        "ramp_load_path", "grr014", VERIFICATION, beam_path, dim.axis,
                        _source_attr(dim.attr), 1.0, 0.002));
                }
                checks.push(_attribute_component("GRR-014-" + side + "-" + index.to_string() + "-" + beam.name + "-y",
                    "grr014", beam_path, "xformOp:translate", 1,
                    _source_number(source, "assemblyUnderBeamCenterYM")));
            }

            let barrel = section + "/HingeBarrel";
            checks.push(#{id: "GRR-015-" + side + "-" + index.to_string() + "-barrel-radius",
                component: "ramp_hinge", requirement: "grr015", verification: VERIFICATION,
                kind: "attribute", path: barrel, attr: "radius",
                expected_attr: _source_attr("rampSectionHingeBarrelRadiusM"), tolerance: 0.002});
            checks.push(#{id: "GRR-015-" + side + "-" + index.to_string() + "-barrel-span",
                component: "ramp_hinge", requirement: "grr015", verification: VERIFICATION,
                kind: "attribute", path: barrel, attr: "height",
                expected_attr: _source_attr("rampSectionHingeBarrelLengthM"), tolerance: 0.002});
            checks.push(_attribute_component("GRR-015-" + side + "-" + index.to_string() + "-barrel-y",
                "grr015", barrel, "xformOp:translate", 1,
                _source_number(source, "rampSectionHingeBarrelCenterYM")));
        }

        if section_index == 0 {
        checks.push(#{id: "GRR-001-" + side + "-sections", component: "ramp",
            requirement: "grr001", verification: VERIFICATION,
            kind: "children", path: ramp,
            paths: [_section_path(ramp, 0), _section_path(ramp, 1)]});
        let transition_path = ROOT + "/" + transition_body_name + _side_suffix(side);
        checks.push(#{id: "GRR-001-" + side + "-transition-plate", component: "ramp",
            requirement: "grr001", verification: VERIFICATION,
            kind: "children", path: ROOT, paths: [transition_path]});
        let transition_joint = ROOT + "/" + transition_joint_names[if side == "port" { 0 } else { 1 }];
        checks.push(_relationship("GRR-002-" + side + "-transition-body0", "grr012",
            transition_joint, "physics:body0", ROOT));
        checks.push(_relationship("GRR-002-" + side + "-transition-body1", "grr012",
            transition_joint, "physics:body1", transition_path));
        let transition_outboard_x = _source_number(source,
            "physicalRampDeckTransitionOutboardX");
        let transition_center_x = if side == "port" {
            transition_outboard_x - _source_number(source,
                "physicalRampDeckTransitionLengthM") / 2.0
        } else {
            -transition_outboard_x + _source_number(source,
                "physicalRampDeckTransitionLengthM") / 2.0
        };
        checks.push(_attribute_component("GRR-012-" + side + "-transition-inboard-placement",
            "grr012", transition_path, "xformOp:translate", 0,
            transition_center_x));
        checks.push(_attribute_component("GRR-012-" + side + "-transition-deck-height",
            "grr012", transition_path, "xformOp:translate", 1,
            _source_number(source, "physicalRampDeckTransitionCenterY")));
        checks.push(_attribute_component("GRR-012-" + side + "-transition-lateral-position",
            "grr012", transition_path, "xformOp:translate", 2,
            _source_number(source, "physicalRampMountZ")));
        let expected_joint_rot1_y = 0.0;
        let expected_joint_rot1_w = 1.0;
        checks.push(_attribute_component("GRR-012-" + side + "-transition-frame0-y",
            "grr012", transition_joint, "physics:localRot0", 1, 0.0));
        checks.push(_attribute_component("GRR-012-" + side + "-transition-frame0-w",
            "grr012", transition_joint, "physics:localRot0", 3, 1.0));
        checks.push(_attribute_component("GRR-012-" + side + "-transition-frame-y",
            "grr012", transition_joint, "physics:localRot1", 1, expected_joint_rot1_y));
        checks.push(_attribute_component("GRR-012-" + side + "-transition-frame-w",
            "grr012", transition_joint, "physics:localRot1", 3, expected_joint_rot1_w));

        for local_joint_index in 0..2 {
            let joint_name = joint_names[joint_offset + local_joint_index];
            let joint_path = ROOT + "/" + joint_name;
            let body0 = if local_joint_index == 0 { ramp } else { ramp + "/MiddleSection" };
            let body1 = if local_joint_index == 0 {
                ramp + "/MiddleSection"
            } else { ramp + "/MiddleSection/ToeSection" };
            checks.push(_check("GRR-016-" + side + "-" + joint_name, "ramp_joint", "grr016", "exists", joint_path));
            checks[checks.len() - 1].expected_type = "PhysicsRevoluteJoint";
            checks.push(_relationship("GRR-016-" + side + "-" + joint_name + "-body0", "grr016",
                joint_path, "physics:body0", body0));
            checks.push(_relationship("GRR-016-" + side + "-" + joint_name + "-body1", "grr016",
                joint_path, "physics:body1", body1));
            checks.push(#{id: "GRR-016-" + side + "-" + joint_name + "-axis", component: "ramp_joint",
                requirement: "grr016", verification: VERIFICATION, kind: "attribute_equals",
                path: joint_path, attr: "physics:axis", expected: "Z"});
            checks.push(_attribute_component("GRR-016-" + side + "-" + joint_name + "-anchor0",
                "grr016", joint_path, "physics:localPos0", 0, section_length));
            checks.push(_attribute_component("GRR-016-" + side + "-" + joint_name + "-anchor1",
                "grr016", joint_path, "physics:localPos1", 0, 0.0));
            let joint_limit_deg = _source_number(source, "physicalRampSectionJointLimitRad") * 180.0 / pi;
            checks.push(_attribute_value("GRR-016-" + side + "-" + joint_name + "-lower-limit",
                "grr016", joint_path, "physics:lowerLimit", -joint_limit_deg));
            checks.push(_attribute_value("GRR-016-" + side + "-" + joint_name + "-upper-limit",
                "grr016", joint_path, "physics:upperLimit", joint_limit_deg));
            checks.push(_attribute_value("GRR-016-" + side + "-" + joint_name + "-stiffness",
                "grr016", joint_path, "drive:angular:physics:stiffness",
                _source_number(source, "physicalRampJointDriveStiffnessNmPerDeg")));
            checks.push(_attribute_value("GRR-016-" + side + "-" + joint_name + "-damping",
                "grr016", joint_path, "drive:angular:physics:damping",
                _source_number(source, "physicalRampSectionJointDriveDampingNmPerDegPerSec")));
            checks.push(_attribute_value("GRR-016-" + side + "-" + joint_name + "-torque",
                "grr016", joint_path, "drive:angular:physics:maxForce",
                _source_number(source, "physicalRampJointDriveMaxTorqueNm")));
        }

        let transition_path = ROOT + "/" + transition_name + suffix;
        let contact_path = transition_path + "/" + contact_name;
        for track in ["RampTrackPort", "RampTrackStarboard"] {
            let ramp_track = section_paths[0] + "/" + track;
            let observation = authoring_measurements::interface_geometry_observation((), #{
                kind: "interface_geometry", deck_path: ROOT + "/RoverPayloadDeckCollider",
                transition_path: contact_path, ramp_path: ramp_track, side: side,
                travel_axis: 0, face_axis: 1, lateral_axis: 2});
            checks.push(_constraint(source, "GRR-012-" + side + "-" + track + "-transition-fit", "grr012",
                "GRC012_ComposedDeckTransitionFit",
                #{measuredOverlapM: _measurement_value(observation, "measured_overlap_m", side + " deck overlap"),
                  requiredOverlapM: _source_number(source, "physicalRampDeckTransitionRequiredOverlapM"),
                  measuredTransitionLengthM: _measurement_value(observation, "measured_transition_length_m", side + " transition length"),
                  requiredTransitionLengthM: _source_number(source, "physicalRampDeckTransitionLengthM"),
                  transitionLengthToleranceM: _source_number(source, "physicalRampDeckTransitionInterfaceToleranceM"),
                  deckTopStepM: _measurement_value(observation, "deck_top_step_m", side + " deck top step"),
                  transitionRampTopStepM: _measurement_value(observation, "transition_ramp_top_step_m", side + " transition-to-ramp top step"),
                  interfaceToleranceM: _source_number(source, "physicalRampDeckTransitionInterfaceToleranceM"),
                  hingeGapM: _measurement_value(observation, "hinge_gap_m", side + " track seam"),
                  lateralCoverageM: _measurement_value(observation, "lateral_coverage_m", side + " deck coverage"),
                  requiredLateralCoverageM: _measurement_value(observation, "deck_lateral_span_m", side + " deck span"),
                  deckProfileCompatible: deck_profile_compatible}));
        }
        }

    }

    if batch == 0 {
        checks.push(#{id: "GRR-007-source-coverage", component: "ramp", requirement: "grr007",
            verification: VERIFICATION, kind: "coverage"});
    }
    let stream_channel = "GRIFFIN_RAMP_REQUIREMENTS_PART_" + batch.to_string();
    let part = sysml_requirements::evaluate_stream(source, checks,
        stream_channel, "GRIFFIN RAMP REQUIREMENTS PART " + batch.to_string());
    this.aggregate = _accumulate_batch(this.aggregate, part);
    this.batch += 1;
    if this.batch == 6 {
        let result = this.aggregate;
        result.metrics = #{clock: clock_snapshot(), root: ROOT,
            verification: result.verification, separate_vehicle_document: true,
            execution_batches: 6, source_revision: result.source_revision};
        report_structured_verdict(result, "GRIFFIN RAMP REQUIREMENTS",
            "GRIFFIN_RAMP_REQUIREMENTS");
        this.done = true;
    }
}
