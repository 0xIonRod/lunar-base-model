import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
// Twin-owned independent Griffin ramp verification.
// SysML supplies the normative constraints and values; Rhai binds FLIP and
// composed-USD observations to the generic structured requirements evaluator.

const ROOT = "/World/Griffin1";
// The source report resolves this short identity to the canonical SysML case
// before evaluation; the package name is not duplicated in the observer.
const VERIFICATION = "Verify_GriffinRampRequirements";

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn _source_attr(name) {
    "GriffinRampRequirements::GriffinEgressRamp::" + name
}

fn _check(id, component, requirement, kind, path) {
    #{id: id, component: component, requirement: requirement,
      verification: VERIFICATION, kind: kind, path: path}
}

fn _source_number(source, name) {
    sysml_requirements::number(source, _source_attr(name))
}

fn _source_text(source, name) {
    sysml_requirements::text(source, _source_attr(name))
}

fn _attribute_component(id, requirement, path, attr, index, expected) {
    #{id: id, component: "ramp", requirement: requirement,
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: attr, index: index, expected: expected, tolerance: 0.002}
}

fn _relationship(id, requirement, path, rel, target) {
    #{id: id, component: "mount", requirement: requirement,
      verification: VERIFICATION, kind: "relationship", path: path,
      rel: rel, targets: [target]}
}

fn _constraint(id, requirement, name, bindings) {
    sysml_requirements::constraint_check(id, "ramp", requirement,
        VERIFICATION, "GriffinRampRequirements::" + name,
        bindings, "derived", 0.0)
}

fn _maximum_abs(values) {
    if values == () || values.len() == 0 { return (); }
    let maximum = 0.0;
    for value in values {
        if value.abs() > maximum { maximum = value.abs(); }
    }
    maximum
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source_with_selection([
        "GriffinRampRequirements::GriffinEgressRamp::childNames",
        "GriffinRampRequirements::GriffinEgressRamp::rampSurfaceLengthM",
        "GriffinRampRequirements::GriffinEgressRamp::rampSurfaceWidthM",
        "GriffinRampRequirements::GriffinEgressRamp::rampWheelClearanceM",
        "GriffinRampRequirements::GriffinEgressRamp::physicalRampDeckTransitionOverlapM",
        "GriffinRampRequirements::GriffinEgressRamp::physicalRampTransitionChildName",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyTreadCount",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyTreadNamePrefix",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyTreadWidthM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyTreadHeightM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyTrackWidthM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyTreadFirstCenterXM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyTreadPitchM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyUnderBeamWidthM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyUnderBeamHeightM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyUnderBeamCenterYM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyUnderBeamCenterOffsetZM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblySidePostCountPerSide",
        "GriffinRampRequirements::GriffinEgressRamp::assemblySidePostWidthM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblySidePostHeightM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblySidePostDepthM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblySidePostCenterYM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblySidePostFirstCenterXM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblySidePostPitchM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyHingeCollarRadiusM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyHingeCollarLengthM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyHingeCollarOffsetZM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyHingeGussetWidthM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyHingeGussetHeightM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyHingeGussetDepthM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyHingeGussetCenterXM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyHingeGussetCenterYM",
        "GriffinRampRequirements::GriffinEgressRamp::assemblyHingeGussetOffsetZM",
        "GriffinRampRequirements::GriffinEgressRamp::rampMaxDeploymentAngleRad",
        "GriffinRampRequirements::GriffinEgressRamp::rampHingeOffsetX",
        "GriffinRampRequirements::GriffinEgressRamp::rampHingeOffsetY",
        "GriffinRampRequirements::GriffinEgressRamp::rampHingeOffsetZ",
        "GriffinRampRequirements::GriffinEgressRamp::rampMountY",
        "GriffinRampRequirements::GriffinEgressRamp::rampMountZ",
        "GriffinRampRequirements::GriffinEgressRamp::rampRailOffsetZM",
        "GriffinRampRequirements::GriffinEgressRamp::rampSocketX",
        "GriffinRampRequirements::GriffinEgressRamp::rampSocketY",
        "GriffinRampRequirements::GriffinEgressRamp::rampSocketZ",
        "GriffinRampRequirements::GriffinEgressRamp::rampSurfaceThicknessM",
        "GriffinRampRequirements::GriffinEgressRamp::rampSurfaceCenterYM",
        "FlipRequirements::FlipRover::wheelStationZ",
        "FlipRequirements::FlipRover::visualRoverWheelWidthM"
    ], [
        "GriffinRampRequirements::grr001", "GriffinRampRequirements::grr002",
        "GriffinRampRequirements::grr003", "GriffinRampRequirements::grr004",
        "GriffinRampRequirements::grr005", "GriffinRampRequirements::grr006",
        "GriffinRampRequirements::grr007", "GriffinRampRequirements::grr008",
        "GriffinRampRequirements::grr009", "GriffinRampRequirements::grr010",
        "GriffinRampRequirements::grr011", "GriffinRampRequirements::grr012",
        "GriffinRampRequirements::grr013", "GriffinRampRequirements::grr014",
        "GriffinRampRequirements::grr015"
    ], ["GriffinRampRequirements::Verify_GriffinRampRequirements"]);
    let checks = [];
    let limit = _source_number(source, "rampMaxDeploymentAngleRad");
    let ramp_width = _source_number(source, "rampSurfaceWidthM");
    let wheel_z = sysml_requirement_checks::source_number_list(source,
        "FlipRequirements::FlipRover::wheelStationZ");
    let wheel_width = sysml_requirements::number(source,
        "FlipRequirements::FlipRover::visualRoverWheelWidthM");
    let wheel_clearance = _source_number(source, "rampWheelClearanceM");
    let transition_overlap = _source_number(source, "physicalRampDeckTransitionOverlapM");
    let ramp_surface_length = _source_number(source, "rampSurfaceLengthM");
    let transition_name = _source_text(source, "physicalRampTransitionChildName");
    let child_names = sysml_requirement_checks::source_text_list(source,
        _source_attr("childNames"));
    let tread_count = _source_number(source, "assemblyTreadCount");
    let tread_width = _source_number(source, "assemblyTreadWidthM");
    let tread_height = _source_number(source, "assemblyTreadHeightM");
    let track_width = _source_number(source, "assemblyTrackWidthM");
    let tread_first_x = _source_number(source, "assemblyTreadFirstCenterXM");
    let tread_pitch = _source_number(source, "assemblyTreadPitchM");
    let tread_prefix = _source_text(source, "assemblyTreadNamePrefix");
    let beam_width = _source_number(source, "assemblyUnderBeamWidthM");
    let beam_height = _source_number(source, "assemblyUnderBeamHeightM");
    let beam_y = _source_number(source, "assemblyUnderBeamCenterYM");
    let beam_offset = _source_number(source, "assemblyUnderBeamCenterOffsetZM");
    let post_count = _source_number(source, "assemblySidePostCountPerSide");
    let post_width = _source_number(source, "assemblySidePostWidthM");
    let post_height = _source_number(source, "assemblySidePostHeightM");
    let post_depth = _source_number(source, "assemblySidePostDepthM");
    let post_y = _source_number(source, "assemblySidePostCenterYM");
    let post_first_x = _source_number(source, "assemblySidePostFirstCenterXM");
    let post_pitch = _source_number(source, "assemblySidePostPitchM");
    let collar_radius = _source_number(source, "assemblyHingeCollarRadiusM");
    let collar_length = _source_number(source, "assemblyHingeCollarLengthM");
    let collar_offset = _source_number(source, "assemblyHingeCollarOffsetZM");
    let gusset_width = _source_number(source, "assemblyHingeGussetWidthM");
    let gusset_height = _source_number(source, "assemblyHingeGussetHeightM");
    let gusset_depth = _source_number(source, "assemblyHingeGussetDepthM");
    let gusset_x = _source_number(source, "assemblyHingeGussetCenterXM");
    let gusset_y = _source_number(source, "assemblyHingeGussetCenterYM");
    let gusset_offset = _source_number(source, "assemblyHingeGussetOffsetZM");
    let half_track = _maximum_abs(wheel_z);
    if ramp_width == () || half_track == () || wheel_width == ()
        || wheel_clearance == () || wheel_z.len() != 4
        || wheel_width <= 0.0 || wheel_clearance <= 0.0
        || transition_overlap == () || ramp_surface_length == () || transition_name == ()
        || transition_name == "" || child_names.len() == 0
        || tread_count == () || tread_count < 2.0 || tread_width == ()
        || tread_height == () || track_width == () || tread_first_x == ()
        || tread_pitch == () || tread_prefix == () || tread_prefix == ""
        || tread_width <= 0.0 || tread_height <= 0.0 || track_width <= 0.0
        || tread_pitch <= 0.0 {
        throw("GriffinRampRequirements ramp/FLIP clearance datums are incomplete");
    }
    if beam_width == () || beam_height == ()
        || beam_y == () || beam_offset == () || post_count == ()
        || post_count < 2.0 || post_width == () || post_height == ()
        || post_depth == () || post_y == () || post_first_x == ()
        || post_pitch == () || collar_radius == () || collar_length == ()
        || collar_offset == () || beam_width <= 0.0 || beam_height <= 0.0
        || beam_offset <= 0.0 || post_width <= 0.0 || post_height <= 0.0
        || post_depth <= 0.0 || post_pitch <= 0.0 || collar_radius <= 0.0
        || collar_length <= 0.0 || collar_offset <= 0.0 {
        throw("GriffinRampRequirements ramp/FLIP clearance datums are incomplete");
    }
    if gusset_width == () || gusset_height == () || gusset_depth == ()
        || gusset_x == () || gusset_y == () || gusset_offset == ()
        || gusset_width <= 0.0 || gusset_height <= 0.0 || gusset_depth <= 0.0
        || gusset_offset <= 0.0 {
        throw("GriffinRampRequirements hinge-gusset datums are incomplete");
    }
    checks.push(_constraint("GRR-003-flip-wheel-clearance", "grr003",
        "GRC003_WidthClearsFlipWheelEnvelope",
        #{rampWidthM: ramp_width, wheelHalfTrackM: half_track,
          wheelHalfWidthM: wheel_width / 2.0, wheelClearanceM: wheel_clearance}));
    checks.push(_constraint("GRR-006-contact-track-clearance", "grr006",
        "GRC016_ContactTrackClearsTire",
        #{trackWidthM: track_width, wheelWidthM: wheel_width,
          wheelClearanceM: wheel_clearance}));
    let deck_observation = griffin_visual_builder::physical_top_deck_collider_observation(
        (), ROOT);
    let deck_profile_compatible = if deck_observation.ok == true
        && deck_observation.state == "pass" {
        #{provider: "usd", state: "value", value: true}
    } else {
        #{provider: "usd", state: "unavailable",
          detail: "source-derived perimeter and rover platform colliders have not passed composed Editor readback"}
    };
    checks.push(_constraint("GRR-012-source-transition", "grr012",
        "GRC012_TransitionOverlapWithinSurface",
        #{overlapM: #{provider: "usd", state: "unavailable",
              detail: "composed TransitionPlate dimensions are not exposed by a typed USD provider"},
          requiredOverlapM: #{provider: "derived_geometry", state: "unavailable",
              detail: "required transition length must be bound to composed adapter edge, hinge, and source contact overlap"},
          surfaceLengthM: #{provider: "source_literal", state: "value",
              value: ramp_surface_length},
          deckProfileCompatible: deck_profile_compatible}));
    let pi = 3.141592653589793;
    for side in ["Port", "Starboard"] {
        let ramp = ROOT + "/EgressRamp" + side;
        let side_lower = if side == "Port" { "port" } else { "starboard" };
        let x_attr = if side == "Port" { "rampPortMountX" } else { "rampStarboardMountX" };
        let angle_attr = if side == "Port" {
            "rampPortDeploymentAngleRad"
        } else {
            "rampStarboardDeploymentAngleRad"
        };
        let angle = _source_number(source, angle_attr);
        let angle_deg = angle * 180.0 / pi;
        let socket_x = _source_number(source, "rampSocketX");
        checks.push(_check("GRR-001-" + side + "-root", "ramp", "grr001", "exists", ramp));
        checks[checks.len() - 1].expected_type = "Xform";
        let part_paths = [];
        for name in child_names {
            part_paths.push(ramp + "/" + name);
        }
        checks.push(#{id: "GRR-001-" + side + "-parts", component: "ramp",
            requirement: "grr001", verification: VERIFICATION,
            kind: "children", path: ramp, paths: part_paths});
        checks.push(_check("GRR-002-" + side + "-hinge", "hinge", "grr002", "exists", ramp + "/MountFrame"));
        checks[checks.len() - 1].expected_type = "Xform";
        checks.push(#{id: "GRR-002-" + side + "-socket", component: "hinge",
            requirement: "grr002", verification: VERIFICATION,
            kind: "exists", path: ROOT + "/Bus/RampSocket" + side, expected_type: "Xform"});
        checks.push(_relationship("GRR-002-" + side + "-frame-rel", "grr002",
            ramp, "lunco:mount:frame", ramp + "/MountFrame"));
        checks.push(_relationship("GRR-002-" + side + "-socket-rel", "grr002",
            ROOT + "/Bus/RampSocket" + side, "lunco:mount:part", ramp));
        checks.push(#{id: "GRR-004-" + side + "-side", component: "ramp",
            requirement: "grr004", verification: VERIFICATION,
            kind: "attribute_equals", path: ramp, attr: "lunco:visual:side", expected: side_lower});
        checks.push(_attribute_component("GRR-004-" + side + "-root-x", "grr004",
            ramp, "xformOp:translate", 0, _source_number(source, x_attr)));
        checks.push(_attribute_component("GRR-004-" + side + "-root-y", "grr004",
            ramp, "xformOp:translate", 1, _source_number(source, "rampMountY")));
        checks.push(_attribute_component("GRR-004-" + side + "-root-z", "grr004",
            ramp, "xformOp:translate", 2, _source_number(source, "rampMountZ")));
        checks.push(_attribute_component("GRR-004-" + side + "-hinge-x", "grr004",
            ramp + "/MountFrame", "xformOp:translate", 0, _source_number(source, "rampHingeOffsetX")));
        checks.push(_attribute_component("GRR-004-" + side + "-hinge-y", "grr004",
            ramp + "/MountFrame", "xformOp:translate", 1, _source_number(source, "rampHingeOffsetY")));
        checks.push(_attribute_component("GRR-004-" + side + "-hinge-z", "grr004",
            ramp + "/MountFrame", "xformOp:translate", 2, _source_number(source, "rampHingeOffsetZ")));
        checks.push(_attribute_component("GRR-004-" + side + "-socket-x", "grr004",
            ROOT + "/Bus/RampSocket" + side, "xformOp:translate", 0,
            if side == "Port" { socket_x } else { -socket_x }));
        checks.push(_attribute_component("GRR-004-" + side + "-socket-y", "grr004",
            ROOT + "/Bus/RampSocket" + side, "xformOp:translate", 1, _source_number(source, "rampSocketY")));
        checks.push(_attribute_component("GRR-004-" + side + "-socket-z", "grr004",
            ROOT + "/Bus/RampSocket" + side, "xformOp:translate", 2, _source_number(source, "rampSocketZ")));
        checks.push(#{id: "GRR-005-" + side + "-angle", component: "ramp",
            requirement: "grr005", verification: VERIFICATION,
            kind: "attribute", path: ramp, attr: "lunco:deployment_angle_rad",
            expected_attr: _source_attr(angle_attr), tolerance: 0.002});
        checks.push(_attribute_component("GRR-005-" + side + "-rotate-z", "grr005",
            ramp, "xformOp:rotateXYZ", 2, angle_deg));
        checks.push(_attribute_component("GRR-005-" + side + "-hinge-rotate-z", "grr005",
            ramp + "/MountFrame", "xformOp:rotateXYZ", 2, angle_deg));
        checks.push(#{id: "GRR-005-" + side + "-hinge-axis", component: "hinge",
            requirement: "grr005", verification: VERIFICATION,
            kind: "attribute_equals", path: ramp, attr: "lunco:visual:hinge_axis", expected_attr: _source_attr("hingeAxis")});
        checks.push(#{id: "GRR-005-" + side + "-joint", component: "hinge",
            requirement: "grr005", verification: VERIFICATION,
            kind: "attribute_equals", path: ROOT + "/Bus/RampSocket" + side,
            attr: "lunco:mount:joint", expected: "revolute"});
        checks.push(#{id: "GRR-005-" + side + "-behavior", component: "ramp",
            requirement: "grr005", verification: VERIFICATION,
            kind: "attribute", path: ramp, attr: "lunco:visual:behavior", expected_attr: _source_attr("rampBehavior")});
        for field in [
            #{id: "GRR-003-" + side + "-axis", attr: "lunco:visual:hinge_axis", expected_attr: _source_attr("hingeAxis")},
            #{id: "GRR-003-" + side + "-length", attr: "lunco:visual:surface_length_m", expected_attr: _source_attr("rampSurfaceLengthM")},
            #{id: "GRR-003-" + side + "-width", attr: "lunco:visual:surface_width_m", expected_attr: _source_attr("rampSurfaceWidthM")},
            #{id: "GRR-003-" + side + "-limit", attr: "lunco:visual:deployment_limit_rad", expected_attr: _source_attr("rampMaxDeploymentAngleRad")},
        ] {
            let check = #{id: field.id, component: "ramp", requirement: "grr003",
                verification: VERIFICATION, kind: "attribute", path: ramp,
                attr: field.attr, expected_attr: field.expected_attr, tolerance: 0.001};
            checks.push(check);
        }
        for track in [
            #{name: "RampTrackPort", center_z: half_track},
            #{name: "RampTrackStarboard", center_z: -half_track},
        ] {
            let track_path = ramp + "/" + track.name;
            for dim in [
                #{name: "length", index: 0, expected_attr: "rampSurfaceLengthM"},
                #{name: "thickness", index: 1, expected_attr: "rampSurfaceThicknessM"},
                #{name: "width", index: 2, expected_attr: "assemblyTrackWidthM"},
            ] {
                checks.push(#{id: "GRR-006-" + side + "-" + track.name + "-" + dim.name,
                    component: "geometry", requirement: "grr006", verification: VERIFICATION,
                    kind: "extent_component", path: track_path, index: dim.index,
                    multiplier: 2.0, expected_attr: _source_attr(dim.expected_attr), tolerance: 0.002});
            }
            checks.push(_attribute_component("GRR-006-" + side + "-" + track.name + "-hinge-station",
                "grr006", track_path, "xformOp:translate", 0,
                _source_number(source, "rampSurfaceLengthM") / 2.0));
            checks.push(_attribute_component("GRR-006-" + side + "-" + track.name + "-vertical-station",
                "grr006", track_path, "xformOp:translate", 1,
                _source_number(source, "rampSurfaceCenterYM")));
            checks.push(_attribute_component("GRR-006-" + side + "-" + track.name + "-station",
                "grr006", track_path, "xformOp:translate", 2, track.center_z));
        }
        for index in 0..tread_count.to_int() {
            let x = tread_first_x + tread_pitch * index;
            let y = _source_number(source, "rampSurfaceThicknessM") / 2.0
                + tread_height / 2.0;
            for track in [
                #{name: "Port", center_z: half_track},
                #{name: "Starboard", center_z: -half_track},
            ] {
            let tread_name = tread_prefix + track.name + (index + 1).to_string();
            let tread = ramp + "/" + tread_name;
            checks.push(#{id: "GRR-013-" + side + "-" + tread_name + "-width", component: "ramp",
                requirement: "grr013", verification: VERIFICATION,
                kind: "extent_component", path: tread, index: 0,
                multiplier: 2.0, expected_attr: _source_attr("assemblyTreadWidthM"), tolerance: 0.002});
            checks.push(#{id: "GRR-013-" + side + "-" + tread_name + "-height", component: "ramp",
                requirement: "grr013", verification: VERIFICATION,
                kind: "extent_component", path: tread, index: 1,
                multiplier: 2.0, expected_attr: _source_attr("assemblyTreadHeightM"), tolerance: 0.002});
            checks.push(#{id: "GRR-013-" + side + "-" + tread_name + "-span", component: "ramp",
                requirement: "grr013", verification: VERIFICATION,
                kind: "extent_component", path: tread, index: 2,
                multiplier: 2.0, expected_attr: _source_attr("assemblyTrackWidthM"), tolerance: 0.002});
            checks.push(_attribute_component("GRR-013-" + side + "-" + tread_name + "-x", "grr013", tread,
                "xformOp:translate", 0, x));
            checks.push(_attribute_component("GRR-013-" + side + "-" + tread_name + "-y", "grr013", tread,
                "xformOp:translate", 1, y));
            checks.push(_attribute_component("GRR-013-" + side + "-" + tread_name + "-z", "grr013", tread,
                "xformOp:translate", 2, track.center_z));
            checks.push(#{id: "GRR-013-" + side + "-" + tread_name + "-purpose", component: "ramp",
                requirement: "grr013", verification: VERIFICATION,
                kind: "attribute_equals", path: tread, attr: "purpose",
                expected: "render"});
            }
        }
        for beam in [
            #{name: "UnderBeamPort", z: beam_offset},
            #{name: "UnderBeamStarboard", z: -beam_offset},
        ] {
            let beam_path = ramp + "/" + beam.name;
            checks.push(#{id: "GRR-014-" + side + "-" + beam.name + "-width", component: "ramp_load_path",
                requirement: "grr014", verification: VERIFICATION,
                kind: "extent_component", path: beam_path, index: 2,
                multiplier: 2.0, expected_attr: _source_attr("assemblyUnderBeamWidthM"), tolerance: 0.002});
            checks.push(#{id: "GRR-014-" + side + "-" + beam.name + "-height", component: "ramp_load_path",
                requirement: "grr014", verification: VERIFICATION,
                kind: "extent_component", path: beam_path, index: 1,
                multiplier: 2.0, expected_attr: _source_attr("assemblyUnderBeamHeightM"), tolerance: 0.002});
            checks.push(_attribute_component("GRR-014-" + side + "-" + beam.name + "-y",
                "grr014", beam_path, "xformOp:translate", 1, beam_y));
            checks.push(_attribute_component("GRR-014-" + side + "-" + beam.name + "-z",
                "grr014", beam_path, "xformOp:translate", 2, beam.z));
        }
        for post_side in ["Port", "Starboard"] {
            let post_z = if post_side == "Port" { _source_number(source, "rampRailOffsetZM") }
                else { -_source_number(source, "rampRailOffsetZM") };
            for index in 0..post_count.to_int() {
                let post_path = ramp + "/SidePost" + post_side + (index + 1).to_string();
                checks.push(#{id: "GRR-014-" + side + "-" + post_side + (index + 1).to_string() + "-height",
                    component: "ramp_load_path", requirement: "grr014", verification: VERIFICATION,
                    kind: "extent_component", path: post_path, index: 1,
                    multiplier: 2.0, expected_attr: _source_attr("assemblySidePostHeightM"), tolerance: 0.002});
                checks.push(_attribute_component("GRR-014-" + side + "-" + post_side + (index + 1).to_string() + "-x",
                    "grr014", post_path, "xformOp:translate", 0,
                    post_first_x + post_pitch * index));
                checks.push(_attribute_component("GRR-014-" + side + "-" + post_side + (index + 1).to_string() + "-y",
                    "grr014", post_path, "xformOp:translate", 1, post_y));
                checks.push(_attribute_component("GRR-014-" + side + "-" + post_side + (index + 1).to_string() + "-z",
                    "grr014", post_path, "xformOp:translate", 2, post_z));
            }
        }
        for collar in [
            #{name: "HingeCollarPort", z: collar_offset},
            #{name: "HingeCollarStarboard", z: -collar_offset},
        ] {
            let collar_path = ramp + "/" + collar.name;
            checks.push(#{id: "GRR-014-" + side + "-" + collar.name + "-radius", component: "ramp_hinge",
                requirement: "grr014", verification: VERIFICATION,
                kind: "attribute", path: collar_path, attr: "radius",
                expected_attr: _source_attr("assemblyHingeCollarRadiusM"), tolerance: 0.002});
            checks.push(#{id: "GRR-014-" + side + "-" + collar.name + "-length", component: "ramp_hinge",
                requirement: "grr014", verification: VERIFICATION,
                kind: "attribute", path: collar_path, attr: "height",
                expected_attr: _source_attr("assemblyHingeCollarLengthM"), tolerance: 0.002});
            checks.push(_attribute_component("GRR-014-" + side + "-" + collar.name + "-z",
                "grr014", collar_path, "xformOp:translate", 2, collar.z));
        }
        for gusset in [
            #{name: "HingeGussetPort", z: gusset_offset},
            #{name: "HingeGussetStarboard", z: -gusset_offset},
        ] {
            let gusset_path = ramp + "/" + gusset.name;
            for field in [
                #{id: "GRR-015-" + side + "-" + gusset.name + "-width", index: 0,
                  expected_attr: _source_attr("assemblyHingeGussetWidthM"), multiplier: 2.0},
                #{id: "GRR-015-" + side + "-" + gusset.name + "-height", index: 1,
                  expected_attr: _source_attr("assemblyHingeGussetHeightM"), multiplier: 2.0},
                #{id: "GRR-015-" + side + "-" + gusset.name + "-depth", index: 2,
                  expected_attr: _source_attr("assemblyHingeGussetDepthM"), multiplier: 2.0},
            ] {
                checks.push(#{id: field.id, component: "ramp_hinge", requirement: "grr015",
                    verification: VERIFICATION, kind: "extent_component", path: gusset_path,
                    index: field.index, multiplier: field.multiplier,
                    expected_attr: field.expected_attr, tolerance: 0.002});
            }
            checks.push(_attribute_component("GRR-015-" + side + "-" + gusset.name + "-x",
                "grr015", gusset_path, "xformOp:translate", 0, gusset_x));
            checks.push(_attribute_component("GRR-015-" + side + "-" + gusset.name + "-y",
                "grr015", gusset_path, "xformOp:translate", 1, gusset_y));
            checks.push(_attribute_component("GRR-015-" + side + "-" + gusset.name + "-z",
                "grr015", gusset_path, "xformOp:translate", 2, gusset.z));
        }
    }
    // Evidence is a process gate: the source report must include the
    // independent package and its verification before any USD result counts.
    checks.push(#{id: "GRR-007-source", component: "ramp", requirement: "grr007",
        verification: VERIFICATION, kind: "coverage"});
    for side in ["Port", "Starboard"] {
        let angle = _source_number(source, if side == "Port" {
            "rampPortDeploymentAngleRad"
        } else {
            "rampStarboardDeploymentAngleRad"
        });
        checks.push(_constraint("GRR-005-" + side + "-nominal-command", "grr005",
            "GRC005_DeploymentCommandWithinLimit",
            #{commandRad: angle, limitRad: limit}));
        checks.push(_constraint("GRR-005-" + side + "-limit-command", "grr005",
            "GRC005_DeploymentCommandWithinLimit",
            #{commandRad: limit, limitRad: limit}));
    }
    let result = sysml_requirements::evaluate(source, checks);
    result.metrics = #{clock: clock_snapshot(), root: ROOT,
                       verification: result.verification,
                       separate_vehicle_document: true};
    report_structured_verdict(result, "GRIFFIN RAMP REQUIREMENTS", "GRIFFIN_RAMP_REQUIREMENTS");
    this.done = true;
}
