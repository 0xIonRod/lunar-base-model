// Twin-owned independent Griffin ramp verification.
// The test is intentionally Rhai-backed: SysML supplies the normative
// requirement names and metric values, while this observer queries the
// composed USD component and emits a generic structured verdict.

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

fn _behavior_result(id, requirement, verification, ok, message, actual, expected) {
    #{id: id, component: "ramp", requirement: requirement,
      // Runtime behavior is a source-derived predicate, so use the generic
      // evaluator's pathless assertion contract rather than a private kind.
      verification: verification, kind: "assert", ok: ok,
      error: if ok { "" } else { message }, actual: actual, expected: expected}
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
    let source = sysml_requirements::source();
    let checks = [];
    let limit = _source_number(source, "rampMaxDeploymentAngleRad");
    let ramp_width = _source_number(source, "rampSurfaceWidthM");
    let wheel_z = component_requirements::source_number_list(source,
        "FlipRequirements::FlipRover::wheelStationZ");
    let wheel_radius = sysml_requirements::number(source,
        "FlipRequirements::FlipRover::visualRoverWheelRadiusM");
    let wheel_clearance = _source_number(source, "rampWheelClearanceM");
    let half_track = _maximum_abs(wheel_z);
    if ramp_width == () || half_track == () || wheel_radius == ()
        || wheel_clearance == () || wheel_z.len() != 4
        || wheel_radius <= 0.0 || wheel_clearance <= 0.0 {
        throw("GriffinRampRequirements ramp/FLIP clearance datums are incomplete");
    }
    let required_width = 2.0 * (half_track + wheel_radius + wheel_clearance);
    checks.push(component_requirements::assertion("GRR-003-flip-wheel-clearance",
        "ramp_flip_interface", "grr003", VERIFICATION,
        ramp_width + 0.002 >= required_width,
        "ramp width does not clear both FLIP tyre envelopes and the authored wheel clearance",
        ramp_width, required_width));
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
        checks.push(#{id: "GRR-001-" + side + "-parts", component: "ramp",
            requirement: "grr001", verification: VERIFICATION,
            kind: "children", path: ramp, paths: [ramp + "/RampSurface",
                ramp + "/OuterRail", ramp + "/InnerRail", ramp + "/SupportArm"]});
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
        checks.push(#{id: "GRR-006-" + side + "-length", component: "geometry",
            requirement: "grr006", verification: VERIFICATION,
            kind: "extent_component", path: ramp + "/RampSurface", index: 0,
            multiplier: 2.0, expected_attr: _source_attr("rampSurfaceLengthM"), tolerance: 0.002});
        checks.push(#{id: "GRR-006-" + side + "-thickness", component: "geometry",
            requirement: "grr006", verification: VERIFICATION,
            kind: "extent_component", path: ramp + "/RampSurface", index: 1,
            multiplier: 2.0, expected_attr: _source_attr("rampSurfaceThicknessM"), tolerance: 0.002});
        checks.push(#{id: "GRR-006-" + side + "-width", component: "geometry",
            requirement: "grr006", verification: VERIFICATION,
            kind: "extent_component", path: ramp + "/RampSurface", index: 2,
            multiplier: 2.0, expected_attr: _source_attr("rampSurfaceWidthM"), tolerance: 0.002});
    }
    // Evidence is a process gate: the source report must include the
    // independent package and its verification before any USD result counts.
    checks.push(#{id: "GRR-007-source", component: "ramp", requirement: "grr007",
        verification: VERIFICATION, kind: "coverage"});
    let result = sysml_requirements::evaluate(source, checks);
    let behavior_requirement = sysml_requirements::requirement_name(source, "grr005");
    if behavior_requirement.ok != true || result.verification == () {
        throw("ramp behavior evidence identity is missing from the SysML source report");
    }
    // Behavioral boundary checks use the reusable generic ramp helper. They
    // operate on SysML values, so no command angle or limit is duplicated in
    // this test and the composed USD remains read-only evidence.
    for side in ["Port", "Starboard"] {
        let angle = _source_number(source, if side == "Port" {
            "rampPortDeploymentAngleRad"
        } else {
            "rampStarboardDeploymentAngleRad"
        });
        let nominal = egress_ramp_requirements::deployment_check(angle, limit);
        let boundary = egress_ramp_requirements::deployment_check(limit, limit);
        let over = egress_ramp_requirements::deployment_check(limit + 0.001, limit);
        for behavior in [
            _behavior_result("GRR-005-" + side + "-nominal", behavior_requirement.name, result.verification,
                nominal.ok, "nominal deployment was rejected", angle, limit),
            _behavior_result("GRR-005-" + side + "-boundary", behavior_requirement.name, result.verification,
                boundary.ok, "deployment limit boundary was rejected", limit, limit),
            _behavior_result("GRR-005-" + side + "-over-limit", behavior_requirement.name, result.verification,
                !over.ok, "over-limit deployment was accepted", limit + 0.001, limit),
        ] {
            result.results.push(behavior);
            if !behavior.ok { result.failures.push(behavior); }
        }
    }
    result.metrics = #{clock: clock_snapshot(), root: ROOT,
                       verification: result.verification,
                       separate_vehicle_document: true};
    report_structured_verdict(result, "GRIFFIN RAMP REQUIREMENTS", "GRIFFIN_RAMP_REQUIREMENTS");
    this.done = true;
}
