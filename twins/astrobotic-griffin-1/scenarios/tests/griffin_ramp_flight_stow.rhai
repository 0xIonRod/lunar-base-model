import "twin://astrobotic-griffin-1/tools/griffin_spec.rhai" as griffin_spec;
import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
import "twin://astrobotic-griffin-1/tools/usd_geometry_inspection.rhai" as usd_geometry_inspection;

const ROOT = "/World/Griffin1";
const OWN = "GriffinRampRequirements::GriffinEgressRamp::";
const VERIFICATION = "Verify_GriffinRampFlightStow";

fn simulation_dependencies(me, ctx) {
    usd_geometry_inspection::dependencies()
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn _source_attr(name) { OWN + name }
fn _source_number(source, name) {
    sysml_requirements::number(source, _source_attr(name))
}
fn _root_axes_observation() {
    let paths = [ROOT + "/EgressRampPort", ROOT + "/EgressRampStarboard",
        ROOT + "/EgressRampPort/DeckSection/RampTrackPort",
        ROOT + "/EgressRampPort/DeckSection/RampTrackStarboard",
        ROOT + "/EgressRampStarboard/DeckSection/RampTrackPort",
        ROOT + "/EgressRampStarboard/DeckSection/RampTrackStarboard"];
    let result = query("QueryUsdPrims", #{paths: paths,
        attrs: ["xformOp:translate", "xformOp:rotateXYZ"], geometry_bounds: true});
    if result == () || result.error != () || result.records == ()
        || result.records.len() != paths.len() {
        return #{provider: "usd", state: "unavailable",
            detail: "both composed ramp root transforms are required"};
    }
    let port = result.records[0];
    let starboard = result.records[1];
    if port.doc_id == () || port.document_generation == () || port.stage_generation == ()
        || starboard.doc_id != port.doc_id
        || starboard.document_generation != port.document_generation
        || starboard.stage_generation != port.stage_generation {
        return #{provider: "usd", state: "unavailable",
            detail: "composed ramp roots do not share one document and stage snapshot"};
    }
    if port.attrs == () || starboard.attrs == () {
        return #{provider: "usd", state: "unavailable",
            detail: "composed ramp root rotations are unavailable",
            doc_id: port.doc_id,
            document_generation: port.document_generation,
            stage_generation: port.stage_generation};
    }
    let port_euler = port.attrs["xformOp:rotateXYZ"];
    let starboard_euler = starboard.attrs["xformOp:rotateXYZ"];
    if port_euler == () || port_euler.len() != 3
        || starboard_euler == () || starboard_euler.len() != 3 {
        return #{provider: "usd", state: "unavailable",
            detail: "composed ramp root rotations are malformed",
            doc_id: port.doc_id,
            document_generation: port.document_generation,
            stage_generation: port.stage_generation};
    }
    // Measure the actual composed straight track centers. Averaging the two
    // lateral tracks cancels their Z offset; the center-to-root vector is
    // local +X. This avoids reinterpreting USD Euler angles with a different
    // quaternion convention and incorrectly accepting a downward ramp.
    let centers=[];
    for i in 2..6 {
        let record=result.records[i];
        if record.doc_id != port.doc_id || record.document_generation != port.document_generation
            || record.stage_generation != port.stage_generation
            || record.geometry_bounds == () || record.geometry_bounds.center == () {
            return #{provider:"usd",state:"unavailable",detail:"ramp track centers lack one canonical geometry snapshot"};
        }
        centers.push(record.geometry_bounds.center);
    }
    let port_delta=[]; let starboard_delta=[];
    for axis in 0..3 {
        port_delta.push((centers[0][axis]+centers[1][axis])/2.0-port.attrs["xformOp:translate"][axis]);
        starboard_delta.push((centers[2][axis]+centers[3][axis])/2.0-starboard.attrs["xformOp:translate"][axis]);
    }
    let port_forward=vnorm(port_delta);
    let starboard_forward=vnorm(starboard_delta);
    #{provider: "usd", state: "value",
      port_forward_x: port_forward[0], port_forward_y: port_forward[1],
      starboard_forward_x: starboard_forward[0],
      starboard_forward_y: starboard_forward[1],
      doc_id: port.doc_id,
      document_generation: port.document_generation,
      stage_generation: port.stage_generation}
}
fn _axis_component_observation(axes, value) {
    let observation = #{provider: "usd", state: axes.state};
    if axes.state == "value" { observation.value = value; }
    else { observation.detail = axes.detail; }
    if axes.doc_id != () { observation.doc_id = axes.doc_id; }
    if axes.document_generation != () {
        observation.document_generation = axes.document_generation;
    }
    if axes.stage_generation != () { observation.stage_generation = axes.stage_generation; }
    observation
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
    if batch == () {
        return #{ok: false, error: "QueryUsdPrims returned no result"};
    }
    if batch.error != () {
        return #{ok: false, error: "QueryUsdPrims failed: " + batch.error};
    }
    if batch.records == () {
        return #{ok: false, error: "QueryUsdPrims returned no prim records"};
    }
    if batch.records.len() != paths.len() {
        return #{ok: false, error: "QueryUsdPrims returned "
            + batch.records.len().to_string() + " records for "
            + paths.len().to_string() + " requested prims"};
    }
    let first = batch.records[0];
    if first.doc_id == () || first.document_generation == () || first.stage_generation == () {
        return #{ok: false,
            error: "composed rail and landing-leg bounds lack document and stage provenance"};
    }
    let snapshot = #{doc_id: first.doc_id,
        document_generation: first.document_generation,
        stage_generation: first.stage_generation};
    let by_path = #{};
    for record in batch.records {
        if record.doc_id != snapshot.doc_id
            || record.document_generation != snapshot.document_generation
            || record.stage_generation != snapshot.stage_generation {
            return #{ok: false,
                error: "composed rail and landing-leg bounds span different USD snapshots",
                path: record.path};
        }
        if record.geometry_bounds != () { by_path[record.path] = record.geometry_bounds; }
    }
    let lowest_rail = 1.0e30;
    let lowest_rail_path = "";
    for path in rail_paths {
        let bounds = by_path[path];
        if bounds == () || bounds.min == () || bounds.min.len() < 2 {
            return #{ok: false, error: "composed rail geometry bounds are missing", path: path};
        }
        if bounds.min[1] < lowest_rail {
            lowest_rail = bounds.min[1];
            lowest_rail_path = path;
        }
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
      lowest_stowed_rail_path: lowest_rail_path,
      highest_landing_leg_top_y_m: highest_leg,
      vertical_clearance_m: lowest_rail - highest_leg,
      rail_prim_count: rail_paths.len(), leg_prim_count: leg_paths.len(),
      doc_id: snapshot.doc_id,
      document_generation: snapshot.document_generation,
      stage_generation: snapshot.stage_generation}
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let attributes = [];
    for name in ["rampSectionLengthM", "rampSectionGeometryToleranceM",
        "rampSurfaceCenterYM", "rampSurfaceThicknessM", "rampRailCenterYM",
        "rampRailHeightM", "rampRailOffsetZM", "rampMaxDeploymentAngleRad",
        "assemblySidePostCountPerSectionPerSide", "assemblySidePostFirstCenterXM",
        "assemblySidePostPitchM", "assemblySideTrussChordHeightM",
        "assemblySideTrussLowerChordCenterYM", "assemblySideTrussBraceThicknessM",
        "assemblySideTrussBraceCountPerSide", "physicalRampMountY", "physicalRampPortMountX",
        "physicalRampStarboardMountX", "physicalRampPanelClearanceM", "physicalRampSectionJointLimitRad",
        "physicalRampPortRootJointStowLimitRad", "physicalRampRootStowedAngleRad",
        "physicalRampStarboardRootJointStowLimitRad",
        "physicalRampSectionStowedRelativeAngleRad",
        "physicalRampSectionJointFrameOffsetRad",
        "physicalRampSectionDeploymentRelativeAngleRad"] {
        attributes.push(_source_attr(name));
    }
    let source = sysml_requirements::source_with_selection(attributes,
        ["GriffinRampRequirements::grr017", "GriffinRampRequirements::grr018",
         "GriffinRampRequirements::grr019", "GriffinRampRequirements::grr020"],
        ["GriffinRampRequirements::Verify_GriffinRampFlightStow"]);
    if source == () || source.ok != true {
        throw("Griffin ramp flight-stow SysML source selection is invalid");
    }

    let checks = [];
    checks.push(_constraint(source, "GRR-017-flight-stow-angle-envelope", "grr017",
        "GRC022_RampFlightStowAnglesWithinTravel",
        #{rootStowAngleRad: _source_number(source, "physicalRampRootStowedAngleRad"),
          sectionStowRelativeAngleRad: _source_number(source, "physicalRampSectionStowedRelativeAngleRad"),
          sectionDeploymentRelativeAngleRad: _source_number(source, "physicalRampSectionDeploymentRelativeAngleRad"),
          sectionJointFrameOffsetRad: _source_number(source, "physicalRampSectionJointFrameOffsetRad"),
          portRootLimitRad: _source_number(source, "physicalRampPortRootJointStowLimitRad"),
          starboardRootLimitRad: _source_number(source, "physicalRampStarboardRootJointStowLimitRad"),
          sectionLimitRad: _source_number(source, "physicalRampSectionJointLimitRad")}));
    checks.push(_constraint(source, "GRR-018-rails-on-upper-track-face", "grr018",
        "GRC023_RailsRemainOnUpperTrackFace",
        #{railCenterYM: _source_number(source, "rampRailCenterYM"),
          railHeightM: _source_number(source, "rampRailHeightM"),
          walkingSurfaceCenterYM: _source_number(source, "rampSurfaceCenterYM"),
          walkingSurfaceThicknessM: _source_number(source, "rampSurfaceThicknessM"),
          toleranceM: _source_number(source, "rampSectionGeometryToleranceM")}));
    checks.push(_constraint(source, "GRR-019-truss-source-envelope", "grr019",
        "GRC026_SideTrussBracing",
        #{braceCountPerSide: _source_number(source, "assemblySideTrussBraceCountPerSide").to_int(),
          postCountPerSide: _source_number(source, "assemblySidePostCountPerSectionPerSide").to_int(),
          braceThicknessM: _source_number(source, "assemblySideTrussBraceThicknessM"),
          lowerChordHeightM: _source_number(source, "assemblySideTrussChordHeightM"),
          lowerChordCenterYM: _source_number(source, "assemblySideTrussLowerChordCenterYM"),
          upperChordCenterYM: _source_number(source, "rampRailCenterYM"),
          walkingSurfaceCenterYM: _source_number(source, "rampSurfaceCenterYM"),
          walkingSurfaceThicknessM: _source_number(source, "rampSurfaceThicknessM"),
          toleranceM: _source_number(source, "rampSectionGeometryToleranceM")}));
    checks.push(_constraint(source, "GRR-017-post-touchdown-unfold-target", "grr017",
        "GRC024_RampSectionDeploymentTargetIsLevel",
        #{deploymentRelativeAngleRad: _source_number(source, "physicalRampSectionDeploymentRelativeAngleRad")}));
    let envelope = _stowed_rail_leg_envelope();
    let source_model = sysml_requirements::model();
    let tolerance_attribute = source_model.attribute(
        _source_attr("rampSectionGeometryToleranceM"));
    if tolerance_attribute == () {
        throw("SysML source literal is unavailable: "
            + _source_attr("rampSectionGeometryToleranceM"));
    }
    let geometry_tolerance = source_model.source_literal_observation(tolerance_attribute);
    if geometry_tolerance == () || geometry_tolerance.provider != "source_literal"
        || geometry_tolerance.source_revision == ()
        || geometry_tolerance.provider_generation != geometry_tolerance.source_revision {
        throw("SysML source literal observation has invalid provenance: "
            + _source_attr("rampSectionGeometryToleranceM"));
    }
    let envelope_binding = if envelope.ok == true {
        #{lowestStowedRailBottomYM: #{provider: "usd", state: "value",
              value: envelope.lowest_stowed_rail_bottom_y_m,
              doc_id: envelope.doc_id,
              document_generation: envelope.document_generation,
              stage_generation: envelope.stage_generation},
          highestLandingLegTopYM: #{provider: "usd", state: "value",
              value: envelope.highest_landing_leg_top_y_m,
              doc_id: envelope.doc_id,
              document_generation: envelope.document_generation,
              stage_generation: envelope.stage_generation},
          geometryToleranceM: geometry_tolerance}
    } else {
        #{lowestStowedRailBottomYM: #{provider: "usd", state: "unavailable", detail: envelope.error},
          highestLandingLegTopYM: #{provider: "usd", state: "unavailable", detail: envelope.error},
          geometryToleranceM: geometry_tolerance}
    };
    checks.push(sysml_requirements::required_constraint_check(
        "GRR-017-stowed-rails-clear-of-legs", "ramp", "grr017",
        VERIFICATION,
        "GriffinRampRequirements::GRC025_StowedRailsClearLandingLegEnvelope",
        envelope_binding, "typed", 0.0));

    let section_length = _source_number(source, "rampSectionLengthM");
    let middle_fold_axis_y = _source_number(source, "rampRailCenterYM")
        + _source_number(source, "rampRailHeightM") / 2.0;
    let toe_fold_axis_y = -_source_number(source, "rampSurfaceThicknessM") / 2.0;
    let section_stow_relative_rad = _source_number(source,
        "physicalRampSectionStowedRelativeAngleRad");
    let section_frame_offset_rad = _source_number(source,
        "physicalRampSectionJointFrameOffsetRad");
    let port_root_deg = _source_number(source,
        "physicalRampRootStowedAngleRad") * 180.0 / 3.141592653589793;
    let starboard_root_deg = port_root_deg;
    let section_stow_relative_deg = section_stow_relative_rad * 180.0 / 3.141592653589793;
    let section_stow_joint_deg = (section_stow_relative_rad + section_frame_offset_rad)
        * 180.0 / 3.141592653589793;
    let ramp_names = ["EgressRampPort", "EgressRampStarboard"];
    let root_joint_names = ["RampHingePort", "RampHingeStarboard"];
    let section_limit_deg = _source_number(source,
        "physicalRampSectionJointLimitRad") * 180.0 / 3.141592653589793;
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
        // Body Euler rotation and revolute-coordinate target differ on the
        // starboard side because its Y=180 mount reverses the hinge axis.
        let root_target_deg = if side_index == 0 { port_root_deg } else { -starboard_root_deg };
        let root_body_rotation_z_deg = root_target_deg;
        checks.push(_attribute_component("GRR-017-" + side + "-root-stow-angle", "grr017",
            ramp, "xformOp:rotateXYZ", 2, root_body_rotation_z_deg));
        checks.push(_attribute_component("GRR-017-" + side + "-root-mirror", "grr017",
            ramp, "xformOp:rotateXYZ", 1, if side_index == 0 { 0.0 } else { 180.0 }));
        let root_joint = ROOT + "/" + root_joint_names[side_index];
        let deployment_limit_deg = _source_number(source,
            "rampMaxDeploymentAngleRad") * 180.0 / 3.141592653589793;
        let root_stow_limit_rad = if side_index == 0 {
            _source_number(source, "physicalRampPortRootJointStowLimitRad")
        } else {
            _source_number(source, "physicalRampStarboardRootJointStowLimitRad")
        };
        let root_stow_limit_deg = root_stow_limit_rad * 180.0 / 3.141592653589793;
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
            let angle_deg = section_stow_relative_deg;
            checks.push(_check("GRR-017-" + side + "-section-" + section_index.to_string(),
                "grr017", "exists", section));
            checks[checks.len() - 1].expected_type = "Xform";
            checks.push(_attribute_component("GRR-017-" + side + "-section-" + section_index.to_string() + "-x",
                "grr017", section, "xformOp:translate", 0, section_length));
            let expected_stowed_y = if section_index == 0 {
                2.0 * middle_fold_axis_y
            } else { 2.0 * toe_fold_axis_y };
            checks.push(_attribute_component("GRR-017-" + side + "-section-" + section_index.to_string() + "-stack-y",
                "grr017", section, "xformOp:translate", 1, expected_stowed_y));
            checks.push(_attribute_component("GRR-017-" + side + "-section-" + section_index.to_string() + "-rotation-z",
                "grr017", section, "xformOp:rotateXYZ", 2, angle_deg));

            let joint = ROOT + "/" + joint_names[side_index][section_index];
            let body0 = if section_index == 0 { ramp } else { section_paths[0] };
            let target_angle_deg = section_stow_joint_deg;
            checks.push(_check("GRR-017-" + side + "-joint-" + section_index.to_string(),
                "grr017", "exists", joint));
            checks[checks.len() - 1].expected_type = "PhysicsRevoluteJoint";
            checks.push(_relationship("GRR-017-" + side + "-joint-" + section_index.to_string() + "-body0",
                "grr017", joint, "physics:body0", body0));
            checks.push(_relationship("GRR-017-" + side + "-joint-" + section_index.to_string() + "-body1",
                "grr017", joint, "physics:body1", section));
            let expected_hinge_y = if section_index == 0 {
                middle_fold_axis_y
            } else { toe_fold_axis_y };
            checks.push(_attribute_component("GRR-017-" + side + "-joint-" + section_index.to_string() + "-stack-anchor0-y",
                "grr017", joint, "physics:localPos0", 1, expected_hinge_y));
            checks.push(_attribute_component("GRR-017-" + side + "-joint-" + section_index.to_string() + "-stack-anchor1-y",
                "grr017", joint, "physics:localPos1", 1, expected_hinge_y));
            checks.push(_attribute("GRR-017-" + side + "-joint-" + section_index.to_string() + "-flight-target",
                "grr017", joint, "drive:angular:physics:targetPosition", target_angle_deg));
            checks.push(_attribute_component("GRR-017-" + side + "-joint-" + section_index.to_string() + "-joint-frame-z",
                "grr017", joint, "physics:localRot1", 3,
                sin(section_frame_offset_rad / 2.0)));
            checks.push(_attribute_component("GRR-017-" + side + "-joint-" + section_index.to_string() + "-joint-frame-w",
                "grr017", joint, "physics:localRot1", 0,
                cos(section_frame_offset_rad / 2.0)));
            // Observe every component in USD's scalar-first representation.
            // Checking the drive angle alone misses a hinge about the wrong axis.
            for index in 0..4 {
                checks.push(_attribute_component("GRR-017-" + side + "-joint-"
                    + section_index.to_string() + "-parent-frame-" + index.to_string(),
                    "grr017", joint, "physics:localRot0", index,
                    if index == 0 { 1.0 } else { 0.0 }));
            }
            for index in [1, 2] {
                checks.push(_attribute_component("GRR-017-" + side + "-joint-"
                    + section_index.to_string() + "-child-frame-" + index.to_string(),
                    "grr017", joint, "physics:localRot1", index, 0.0));
            }
            checks.push(_attribute("GRR-017-" + side + "-joint-" + section_index.to_string() + "-lower-limit",
                "grr017", joint, "physics:lowerLimit", -section_limit_deg));
            checks.push(_attribute("GRR-017-" + side + "-joint-" + section_index.to_string() + "-upper-limit",
                "grr017", joint, "physics:upperLimit", section_limit_deg));
            for rail_name in ["OuterRail", "InnerRail"] {
                let rail = section + "/" + rail_name;
                checks.push(_attribute_component("GRR-018-" + side + "-" + section_index.to_string() + "-" + rail_name + "-top-y",
                    "grr018", rail, "xformOp:translate", 1,
                    _source_number(source, "rampRailCenterYM")));
                checks.push(sysml_requirement_checks::array_component(
                    "GRR-018-" + side + "-" + section_index.to_string() + "-" + rail_name + "-height",
                    "ramp", "grr018", VERIFICATION, rail, "extent", [1, 0],
                    _source_number(source, "rampRailHeightM") / 2.0, 0.002));
            }
            let truss_brace_count = _source_number(source,
                "assemblySideTrussBraceCountPerSide").to_int();
            for truss_side in ["Port", "Starboard"] {
                let lower_chord_path = section + "/SideTrussLowerChord" + truss_side;
                checks.push(_check("GRR-019-" + side + "-" + section_index.to_string()
                    + "-" + truss_side + "-lower-chord", "grr019", "exists",
                    lower_chord_path));
                checks[checks.len() - 1].expected_type = "Cube";
                for brace_index in 0..truss_brace_count {
                    let brace_path = section + "/SideTrussBrace" + truss_side
                        + (brace_index + 1).to_string();
                    checks.push(_check("GRR-019-" + side + "-" + section_index.to_string()
                        + "-" + truss_side + "-brace" + (brace_index + 1).to_string(),
                        "grr019", "exists", brace_path));
                    checks[checks.len() - 1].expected_type = "Cube";
                }
            }
        }
        let deck_section = ramp + "/DeckSection";
        for rail_name in ["OuterRail", "InnerRail"] {
            let rail = deck_section + "/" + rail_name;
            checks.push(_attribute_component("GRR-018-" + side + "-deck-" + rail_name + "-top-y",
                "grr018", rail, "xformOp:translate", 1,
                (griffin_spec::ramp_guide_center_y_m(0, 0.0)
                    + griffin_spec::ramp_guide_center_y_m(0, section_length)) / 2.0));
            checks.push(sysml_requirement_checks::array_component(
                "GRR-018-" + side + "-deck-" + rail_name + "-height",
                "ramp", "grr018", VERIFICATION, rail, "extent", [1, 0],
                _source_number(source, "rampRailHeightM") / 2.0, 0.002));
        }
    }

    // Evaluate each composed USD root transform in the lander frame. The live
    // physics pose is time-varying, so it is not a stable measurement of the
    // authored transport configuration after the hinge drives start moving.
    let axis_observation = _root_axes_observation();
    let port_forward_x = _axis_component_observation(axis_observation,
        axis_observation.port_forward_x);
    let port_forward_y = _axis_component_observation(axis_observation,
        axis_observation.port_forward_y);
    let starboard_forward_x = _axis_component_observation(axis_observation,
        axis_observation.starboard_forward_x);
    let starboard_forward_y = _axis_component_observation(axis_observation,
        axis_observation.starboard_forward_y);
    checks.push(_constraint(source, "GRR-017-root-axes-mirror", "grr017",
        "GRC027_RampStowedRootAxesMirror",
        #{portForwardX: port_forward_x,
          portForwardY: port_forward_y,
          starboardForwardX: starboard_forward_x,
          starboardForwardY: starboard_forward_y,
          tolerance: _source_number(source, "physicalRampRootAxisMirrorTolerance")}));

    let panel_names = griffin_spec::solar_array_names();
    let panel_paths = [];
    for name in panel_names {
        panel_paths.push(ROOT + "/" + name + "/Frame");
        panel_paths.push(ROOT + "/" + name + "/ArrayBackplane");
    }
    let ramp_paths = [];
    for side in ["EgressRampPort", "EgressRampStarboard"] {
        for section in ["DeckSection", "MiddleSection", "MiddleSection/ToeSection"] {
            for member in ["RampTrackPort", "RampTrackStarboard", "OuterRail", "InnerRail",
                "CenterRailPort", "CenterRailStarboard", "HingeBarrel",
                "OuterRailJointPin", "InnerRailJointPin", "UnderBeamPort", "UnderBeamStarboard"] {
                ramp_paths.push(ROOT + "/" + side + "/" + section + "/" + member);
            }
        }
    }
    let paths = panel_paths + ramp_paths;
    // Bounds are the measurement. Do not pull every Mesh topology/material
    // attribute into this multi-part snapshot and exhaust the Rhai array budget.
    let batch = query("QueryUsdPrims", #{paths: paths, attrs:["purpose"], geometry_bounds: true});
    let valid = panel_names.len() > 0 && panel_names.len() == griffin_spec::solar_array_count()
        && batch != () && batch.error == () && batch.records != ()
        && batch.records.len() == paths.len() && usd_geometry_inspection::same_snapshot(batch.records);
    if valid {
        for index in 0..paths.len() {
            if batch.records[index].path != paths[index] { valid = false; break; }
        }
    }
    let port_gap = 1.0e30; let starboard_gap = 1.0e30;
    if valid {
        for panel in batch.records {
            if !panel_paths.contains(panel.path) { continue; }
            for ramp in batch.records {
                if !ramp_paths.contains(ramp.path) { continue; }
                let a = panel.geometry_bounds; let b = ramp.geometry_bounds;
                if a == () || b == () || a.min == () || a.max == ()
                    || b.min == () || b.max == () || a.min.len() != 3 || a.max.len() != 3
                    || b.min.len() != 3 || b.max.len() != 3 { valid = false; break; }
                // A separating axis is sufficient to certify disjoint AABBs.
                // Do not force vertical separation: the panels sit alongside
                // the payload, with clear lateral rover/ramp corridors.
                let gap = -1.0e30;
                for axis in 0..3 {
                    gap = max(gap, max(a.min[axis]-b.max[axis], b.min[axis]-a.max[axis]));
                }
                if ramp.path.contains("/EgressRampPort/") { port_gap = min(port_gap, gap); }
                else { starboard_gap = min(starboard_gap, gap); }
            }
        }
    }
    for side in ["port", "starboard"] {
        let gap = if side == "port" { port_gap } else { starboard_gap };
        let observation = if valid {
            usd_geometry_inspection::measurement(gap, batch.records[0], "stowed ramp/panel 3D envelope separation")
        } else { #{provider: "usd", state: "unavailable", detail: "one composed ramp/panel bounds snapshot is required"} };
        checks.push(_constraint(source, "GRR-020-" + side + "-panel-clearance", "grr020",
            "GRC030_StowedRampClearsSolarPanels", #{gapM: observation,
                requiredGapM: _source_number(source, "physicalRampPanelClearanceM")}));
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
        root_axis_mirror: axis_observation,
        stowed_panel_clearance: #{available: valid, panel_count: panel_names.len(),
            port_gap_m: if valid { port_gap } else { () },
            starboard_gap_m: if valid { starboard_gap } else { () }},
        stowed_rail_leg_envelope: envelope,
        lowest_stowed_rail_path: if envelope.ok == true {
            envelope.lowest_stowed_rail_path
        } else { "unavailable" }};
    report_structured_verdict(result, "GRIFFIN RAMP FLIGHT STOW",
        "GRIFFIN_RAMP_FLIGHT_STOW");
    this.done = true;
    if result.ok != true {
        print("[griffin-ramp-stow] source or composed pose checks failed: "
            + result.failure_count.to_string());
        for failure in result.failures {
            print("[griffin-ramp-stow] failed check "
                + failure.id.to_string() + " at "
                + failure.path.to_string() + ": "
                + failure.error.to_string());
        }
    }
}
