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
fn _measurement_value(observation, field, label) {
    if observation == () || observation.ok != true || observation[field] == () {
        return #{provider: "composed_usd_geometry", state: "unavailable",
            detail: if observation == () || observation.message == () {
                label + " could not be measured from composed collision geometry"
            } else { observation.message }};
    }
    #{provider: "composed_usd_geometry", state: "value", value: observation[field]}
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
fn _side_sign(side) { if side == "port" { 1.0 } else { -1.0 } }

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
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
        "rampMountY", "rampMountZ", "rampPortDeploymentAngleRad",
        "rampStarboardDeploymentAngleRad", "hingeAxis", "physicalRampDeckTransitionRequiredOverlapM",
        "physicalRampDeckTransitionLengthM", "physicalRampDeckTransitionInterfaceToleranceM",
        "physicalRampTerrainContactToleranceM", "physicalRampPortMountX",
        "physicalRampStarboardMountX", "physicalRampMountY", "physicalRampMountZ",
        "physicalRampPortDeploymentAngleRad", "physicalRampStarboardDeploymentAngleRad",
        "physicalRampMassKg", "physicalRampSectionMassKg",
        "physicalRampSectionInertiaXKgM2", "physicalRampSectionInertiaYKgM2",
        "physicalRampSectionInertiaZKgM2", "physicalRampSectionMassPartitionToleranceKg",
        "physicalRampSectionJointLimitRad", "physicalRampSectionStowedAngleRad",
        "physicalRampRootJointStowLimitRad", "physicalRampRootStowedAngleRad",
        "physicalRampToeSectionStowedAngleRad", "physicalRampSectionDriveTargetRad",
        "physicalRampJointDriveStiffnessNmPerDeg",
        "physicalRampJointDriveDampingNmPerDegPerSec",
        "physicalRampJointDriveMaxTorqueNm",
        "physicalRampSectionMassPropertiesToleranceKgM2",
        "physicalRampDeckTransitionMassKg", "physicalRampDeckTransitionInertiaKgM2"
    ] { attributes.push(_source_attr(name)); }
    let requirements = [];
    for name in ["grr001", "grr002", "grr003", "grr004", "grr005", "grr006",
        "grr007", "grr008", "grr009", "grr010", "grr011", "grr012",
        "grr013", "grr014", "grr015", "grr016", "grr017", "grr018"] {
        requirements.push("GriffinRampRequirements::" + name);
    }
    let source = sysml_requirements::source_with_selection(attributes, requirements,
        ["GriffinRampRequirements::Verify_GriffinRampRequirements"]);
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

    checks.push(_constraint("GRR-003-rover-envelope", "grr003",
        "GRC003_WidthClearsFlipWheelEnvelope",
        #{rampWidthM: ramp_width, wheelHalfTrackM: half_track,
          wheelHalfWidthM: wheel_width / 2.0, wheelClearanceM: wheel_clearance}));
    checks.push(_constraint("GRR-006-contact-track-width", "grr006",
        "GRC016_ContactTrackClearsTire",
        #{trackWidthM: track_width, wheelWidthM: wheel_width,
          wheelClearanceM: wheel_clearance}));
    checks.push(_constraint("GRR-016-section-envelope", "grr016",
        "GRC018_SectionedRampMatchesEnvelope",
        #{totalLengthM: total_length, sectionLengthM: section_length,
          sectionCount: section_count, measuredLengthDeviationM: 0.0,
          toleranceM: geometry_tolerance}));
    checks.push(_constraint("GRR-013-tread-count", "grr013",
        "GRC021_RampTreadCountMatchesSections",
        #{totalTreadCount: _source_number(source, "assemblyTreadCount"),
          treadCountPerSection: _source_number(source, "assemblyTreadCountPerSection"),
          sectionCount: section_count}));
    checks.push(_constraint("GRR-011-mass-partition", "grr011",
        "GRC019_RampSectionMassPartition",
        #{totalMassKg: _source_number(source, "physicalRampMassKg"),
          sectionMassKg: _source_number(source, "physicalRampSectionMassKg"),
          sectionCount: section_count,
          toleranceKg: _source_number(source, "physicalRampSectionMassPartitionToleranceKg")}));
    checks.push(_constraint("GRR-017-flight-stow-angle-envelope", "grr017",
        "GRC022_RampFlightStowAnglesWithinTravel",
        #{rootStowAngleRad: _source_number(source, "physicalRampRootStowedAngleRad"),
          middleAngleRad: _source_number(source, "physicalRampSectionStowedAngleRad"),
          toeAngleRad: _source_number(source, "physicalRampToeSectionStowedAngleRad"),
          rootLimitRad: _source_number(source, "physicalRampRootJointStowLimitRad"),
          sectionLimitRad: _source_number(source, "physicalRampSectionJointLimitRad")}));
    checks.push(_constraint("GRR-018-rails-on-upper-track-face", "grr018",
        "GRC023_RailsRemainOnUpperTrackFace",
        #{railBottomYM: _source_number(source, "rampRailCenterYM")
                - _source_number(source, "rampRailHeightM") / 2.0,
          walkingSurfaceTopYM: _source_number(source, "rampSurfaceCenterYM")
                + _source_number(source, "rampSurfaceThicknessM") / 2.0,
          toleranceM: geometry_tolerance}));
    checks.push(_constraint("GRR-011-section-inertia", "grr011",
        "GRC020_RampSectionInertiaMatchesEnvelope",
        #{measuredXKgM2: _source_number(source, "physicalRampSectionInertiaXKgM2"),
          measuredYKgM2: _source_number(source, "physicalRampSectionInertiaYKgM2"),
          measuredZKgM2: _source_number(source, "physicalRampSectionInertiaZKgM2"),
          sectionMassKg: _source_number(source, "physicalRampSectionMassKg"),
          sectionLengthM: section_length, outsideWidthM: ramp_width,
          thicknessM: _source_number(source, "rampSurfaceThicknessM"),
          toleranceKgM2: _source_number(source, "physicalRampSectionMassPropertiesToleranceKgM2")}));

    let ramp_roots = [ROOT + "/EgressRampPort", ROOT + "/EgressRampStarboard"];
    checks.push(#{id: "GRR-007-separate-ramp-instances", component: "ramp",
        requirement: "grr007", verification: VERIFICATION, kind: "children",
        path: ROOT, paths: ramp_roots});
    let deck_observation = griffin_visual_builder::physical_top_deck_collider_observation((), ROOT);
    let deck_profile_compatible = if deck_observation.ok == true
        && (deck_observation.state == "pass" || deck_observation.state == "fail") {
        #{provider: "composed_usd_geometry", state: "value",
          value: deck_observation.state == "pass"}
    } else {
        #{provider: "composed_usd_geometry", state: "unavailable",
          detail: "upper-deck collision profile is unavailable"}
    };
    let transition_name = transition_body_name;
    let contact_name = transition_contact_name;
    let pi = 3.141592653589793;

    for side in ["port", "starboard"] {
        let suffix = _side_suffix(side);
        let sign = _side_sign(side);
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
        let visual_angle = _source_number(source, if side == "port" {
            "rampPortDeploymentAngleRad"
        } else {
            "rampStarboardDeploymentAngleRad"
        });
        let root_joint = ROOT + "/RampHinge" + suffix;
        let joint_offset = if side == "port" { 0 } else { 2 };
        let root_stow_angle_deg = _source_number(source,
            "physicalRampRootStowedAngleRad") * 180.0 / pi * sign;

        checks.push(_check("GRR-001-" + side + "-ramp-root", "ramp", "grr001", "exists", ramp));
        checks[checks.len() - 1].expected_type = "Xform";
        checks.push(_attribute_component("GRR-004-" + side + "-mount-x", "grr004",
            ramp, "xformOp:translate", 0, mount_x));
        checks.push(_attribute_component("GRR-004-" + side + "-mount-y", "grr004",
            ramp, "xformOp:translate", 1, _source_number(source, "physicalRampMountY")));
        checks.push(_attribute_component("GRR-004-" + side + "-mount-z", "grr004",
            ramp, "xformOp:translate", 2, _source_number(source, "physicalRampMountZ")));
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
        checks.push(#{id: "GRR-017-" + side + "-root-flight-stow-target",
            component: "ramp", requirement: "grr017", verification: VERIFICATION,
            kind: "attribute", path: root_joint,
            attr: "drive:angular:physics:targetPosition",
            expected: root_stow_angle_deg, tolerance: 0.002});
        checks.push(_attribute_component("GRR-017-" + side + "-root-flight-stow-transform",
            "grr017", ramp, "xformOp:rotateXYZ", 2, root_stow_angle_deg));
        let deployment_limit_deg = _source_number(source, "rampMaxDeploymentAngleRad") * 180.0 / pi;
        let root_stow_limit_deg = _source_number(source,
            "physicalRampRootJointStowLimitRad") * 180.0 / pi;
        let root_lower_limit_deg = if side == "port" {
            -deployment_limit_deg
        } else { -root_stow_limit_deg };
        let root_upper_limit_deg = if side == "port" {
            root_stow_limit_deg
        } else { deployment_limit_deg };
        checks.push(_attribute_component("GRR-005-" + side + "-lower-limit", "grr005",
            root_joint, "physics:lowerLimit", 0, root_lower_limit_deg));
        checks.push(_attribute_component("GRR-005-" + side + "-upper-limit", "grr005",
            root_joint, "physics:upperLimit", 0, root_upper_limit_deg));
        checks.push(_constraint("GRR-005-" + side + "-command-envelope", "grr005",
            "GRC005_DeploymentCommandWithinLimit",
            #{commandRad: physical_angle,
              limitRad: _source_number(source, "rampMaxDeploymentAngleRad")}));

        let section_paths = [];
        for index in 0..section_count {
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
                        _source_attr(dim.attr), 2.0, 0.002));
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
                        kind: "extent_component", path: post_path, index: 1, multiplier: 2.0,
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
                        checks.push(sysml_requirement_checks::extent_component(
                            "GRR-013-" + side + "-" + index.to_string() + "-" + track.name + tread_index.to_string() + "-" + dim.name,
                            "ramp_tread", "grr013", VERIFICATION, tread_path,
                            dim.axis, _source_attr(dim.attr), 2.0, 0.002));
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
                        _source_attr(dim.attr), 2.0, 0.002));
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

        checks.push(#{id: "GRR-001-" + side + "-sections", component: "ramp",
            requirement: "grr001", verification: VERIFICATION,
            kind: "children", path: ramp, paths: [section_paths[0], section_paths[1], ramp + "/TransitionPlate"]});
        checks.push(_relationship("GRR-002-" + side + "-transition-body0", "grr012",
            ramp + "/" + transition_joint_names[if side == "port" { 0 } else { 1 }],
            "physics:body0", ROOT));
        checks.push(_relationship("GRR-002-" + side + "-transition-body1", "grr012",
            ramp + "/" + transition_joint_names[if side == "port" { 0 } else { 1 }],
            "physics:body1", ramp + "/" + transition_name));
        let transition_path = ramp + "/" + transition_name;
        let transition_joint = ramp + "/" + transition_joint_names[if side == "port" { 0 } else { 1 }];
        checks.push(_attribute_component("GRR-012-" + side + "-transition-inboard-placement",
            "grr012", transition_path, "xformOp:translate", 0,
            -_source_number(source, "physicalRampDeckTransitionLengthM") / 2.0));
        let expected_joint_rot1_y = if side == "port" { 0.0 } else { 1.0 };
        let expected_joint_rot1_w = if side == "port" { 1.0 } else { 0.0 };
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
            checks.push(_attribute_component("GRR-016-" + side + "-" + joint_name + "-lower-limit",
                "grr016", joint_path, "physics:lowerLimit", 0, -joint_limit_deg));
            checks.push(_attribute_component("GRR-016-" + side + "-" + joint_name + "-upper-limit",
                "grr016", joint_path, "physics:upperLimit", 0, joint_limit_deg));
            let stow_angle = if local_joint_index == 0 {
                _source_number(source, "physicalRampSectionStowedAngleRad")
            } else {
                _source_number(source, "physicalRampToeSectionStowedAngleRad")
            };
            let stow_angle_deg = stow_angle * 180.0 / pi;
            checks.push(#{id: "GRR-017-" + side + "-" + joint_name + "-flight-stow-target",
                component: "ramp", requirement: "grr017", verification: VERIFICATION,
                kind: "attribute", path: joint_path,
                attr: "drive:angular:physics:targetPosition", expected: stow_angle_deg,
                tolerance: 0.002});
            checks.push(_attribute_component("GRR-017-" + side + "-" + joint_name + "-flight-stow-transform",
                "grr017", body1, "xformOp:rotateXYZ", 2, stow_angle_deg));
            checks.push(_attribute_component("GRR-016-" + side + "-" + joint_name + "-stiffness",
                "grr016", joint_path, "drive:angular:physics:stiffness", 0,
                _source_number(source, "physicalRampJointDriveStiffnessNmPerDeg")));
            checks.push(_attribute_component("GRR-016-" + side + "-" + joint_name + "-damping",
                "grr016", joint_path, "drive:angular:physics:damping", 0,
                _source_number(source, "physicalRampJointDriveDampingNmPerDegPerSec")));
            checks.push(_attribute_component("GRR-016-" + side + "-" + joint_name + "-torque",
                "grr016", joint_path, "drive:angular:physics:maxForce", 0,
                _source_number(source, "physicalRampJointDriveMaxTorqueNm")));
        }

        let transition_path = ramp + "/" + transition_name;
        let contact_path = transition_path + "/" + contact_name;
        for track in ["RampTrackPort", "RampTrackStarboard"] {
            let ramp_track = section_paths[0] + "/" + track;
            let observation = authoring_measurements::interface_geometry_observation((), #{
                kind: "interface_geometry", deck_path: ROOT + "/RoverPayloadDeckCollider",
                transition_path: contact_path, ramp_path: ramp_track, side: side,
                travel_axis: 0, face_axis: 1, lateral_axis: 2});
            checks.push(_constraint("GRR-012-" + side + "-" + track + "-transition-fit", "grr012",
                "GRC012_ComposedDeckTransitionFit",
                #{measuredOverlapM: _measurement_value(observation, "measured_overlap_m", side + " deck overlap"),
                  requiredOverlapM: _source_number(source, "physicalRampDeckTransitionRequiredOverlapM"),
                  measuredTransitionLengthM: _measurement_value(observation, "measured_transition_length_m", side + " transition length"),
                  requiredTransitionLengthM: _source_number(source, "physicalRampDeckTransitionLengthM"),
                  transitionLengthToleranceM: _source_number(source, "physicalRampDeckTransitionInterfaceToleranceM"),
                  deckTopStepM: _measurement_value(observation, "deck_top_step_m", side + " deck top step"),
                  interfaceToleranceM: _source_number(source, "physicalRampDeckTransitionInterfaceToleranceM"),
                  hingeGapM: _measurement_value(observation, "hinge_gap_m", side + " track seam"),
                  lateralCoverageM: _measurement_value(observation, "lateral_coverage_m", side + " deck coverage"),
                  requiredLateralCoverageM: _measurement_value(observation, "deck_lateral_span_m", side + " deck span"),
                  deckProfileCompatible: deck_profile_compatible}));
        }

        let bevel = mechanical_relations::planar_horizontal_face_bevel_run(
            _source_number(source, "rampSurfaceThicknessM"), physical_angle);
        let local_tip_x = sign * total_length;
        let tip_bottom_x = sign * (total_length - bevel);
        let origin = vec3(0.0,
            sysml_requirements::number(source, "Griffin1Requirements::PublicMissionContext::landingVehicleReferenceTouchdownY")
                + _source_number(source, "physicalRampMountY"), 0.0);
        let top_point = mechanical_relations::planar_rigid_transform_point(origin,
            vec3(local_tip_x, _source_number(source, "rampSurfaceCenterYM")
                + _source_number(source, "rampSurfaceThicknessM") / 2.0, 0.0), physical_angle);
        let bottom_point = mechanical_relations::planar_rigid_transform_point(origin,
            vec3(tip_bottom_x, _source_number(source, "rampSurfaceCenterYM")
                - _source_number(source, "rampSurfaceThicknessM") / 2.0, 0.0), physical_angle);
        checks.push(_constraint("GRR-010-" + side + "-tip-contact", "grr010",
            "GRC010_PhysicalRampReachesTerrain",
            #{rampTipTopYM: _measurement_value(#{ok: true, y: top_point.y}, "y", side + " ramp toe top"),
              rampTipBottomYM: _measurement_value(#{ok: true, y: bottom_point.y}, "y", side + " ramp toe bottom"),
              terrainSurfaceYM: sysml_requirements::number(source,
                  "Griffin1Requirements::PublicMissionContext::egressApronSurfaceY"),
              contactToleranceM: _source_number(source, "physicalRampTerrainContactToleranceM")}));
    }

    checks.push(#{id: "GRR-007-source-coverage", component: "ramp", requirement: "grr007",
        verification: VERIFICATION, kind: "coverage"});
    let result = sysml_requirements::evaluate(source, checks);
    result.metrics = #{clock: clock_snapshot(), root: ROOT,
        verification: result.verification, separate_vehicle_document: true};
    report_structured_verdict(result, "GRIFFIN RAMP REQUIREMENTS", "GRIFFIN_RAMP_REQUIREMENTS");
    this.done = true;
}
