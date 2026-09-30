import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;
import "lunco://scripting/tools/mechanical_relations" as mechanical_relations;
import "twin://astrobotic-griffin-1/tools/usd_geometry_inspection.rhai" as usd_geometry_inspection;

const ROOT = "/World/Griffin1";
const VERIFICATION = "Verify_GriffinRampTouchdownGeometry";

fn simulation_dependencies(me, ctx) { usd_geometry_inspection::dependencies() }

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn _physical_attr(name) { "GriffinRampRequirements::GriffinEgressRamp::" + name }

fn _constraint(id, bindings) {
    sysml_requirements::constraint_check(id, "ramp", "grr010", VERIFICATION,
        "GriffinRampRequirements::GRC010_PhysicalRampReachesTerrain",
        bindings, "derived", 0.0)
}

fn _attribute_component(id, path, attr, index, expected) {
    #{id: id, component: "ramp", requirement: "grr010",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: attr, index: index, expected: expected, tolerance: 0.002}
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let selected = [
        _physical_attr("rampSurfaceLengthM"),
        _physical_attr("rampSurfaceCenterYM"),
        _physical_attr("rampSurfaceThicknessM"),
        _physical_attr("physicalRampPortMountX"),
        _physical_attr("physicalRampStarboardMountX"),
        _physical_attr("physicalRampMountY"),
        _physical_attr("physicalRampPortDeploymentAngleRad"),
        _physical_attr("physicalRampStarboardDeploymentAngleRad"),
        _physical_attr("physicalRampTerrainContactToleranceM"),
        "Griffin1Requirements::PublicMissionContext::landingVehicleReferenceTouchdownY",
        "Griffin1Requirements::PublicMissionContext::siteSurfaceY"
    ];
    let source = sysml_requirements::source_with_selection(selected,
        ["GriffinRampRequirements::grr010"],
        ["GriffinRampRequirements::" + VERIFICATION]);
    if source == () || source.ok != true {
        throw("Griffin physical-ramp touchdown source selection is invalid");
    }

    let length = sysml_requirements::number(source, _physical_attr("rampSurfaceLengthM"));
    let center_y = sysml_requirements::number(source, _physical_attr("rampSurfaceCenterYM"));
    let thickness = sysml_requirements::number(source, _physical_attr("rampSurfaceThicknessM"));
    let mount_y = sysml_requirements::number(source, _physical_attr("physicalRampMountY"));
    let touchdown_y = sysml_requirements::number(source,
        "Griffin1Requirements::PublicMissionContext::landingVehicleReferenceTouchdownY");
    let terrain_y = sysml_requirements::number(source,
        "Griffin1Requirements::PublicMissionContext::siteSurfaceY");
    let tolerance = sysml_requirements::number(source,
        _physical_attr("physicalRampTerrainContactToleranceM"));
    let top_offset = center_y + thickness / 2.0;
    let bottom_offset = center_y - thickness / 2.0;
    let hinge_y = touchdown_y + mount_y;
    let checks = [];
    let details = [];

    for side in ["Port", "Starboard"] {
        let sign = if side == "Port" { 1.0 } else { -1.0 };
        let mount_x = sysml_requirements::number(source,
            _physical_attr("physicalRamp" + side + "MountX"));
        let angle = sysml_requirements::number(source,
            _physical_attr("physicalRamp" + side + "DeploymentAngleRad"));
        let ramp = ROOT + "/EgressRamp" + side;
        let bevel = mechanical_relations::planar_horizontal_face_bevel_run(thickness, angle);
        let origin = vec3(mount_x, hinge_y, 0.0);
        let top = mechanical_relations::planar_rigid_transform_point(origin,
            vec3(sign * length, top_offset, 0.0), angle);
        let bottom = mechanical_relations::planar_rigid_transform_point(origin,
            vec3(sign * (length - bevel), bottom_offset, 0.0), angle);

        checks.push(_attribute_component("GRR-010-" + side + "-mount-x",
            ramp, "xformOp:translate", 0, mount_x));
        checks.push(_attribute_component("GRR-010-" + side + "-mount-y",
            ramp, "xformOp:translate", 1, mount_y));
        checks.push(_constraint("GRR-010-" + side + "-toe-contact",
            #{rampTipTopYM: top.y,
              rampTipBottomYM: bottom.y,
              terrainSurfaceYM: terrain_y,
              contactToleranceM: tolerance}));
        details.push(#{side: side, angle_rad: angle, hinge_world_y_m: hinge_y,
            tip_top_y_m: top.y, tip_bottom_y_m: bottom.y,
            terrain_y_m: terrain_y, toe_bevel_run_m: bevel});
    }

    let result = sysml_requirements::evaluate(source, checks);
    result.metrics = #{root: ROOT, touchdown_reference_y_m: touchdown_y,
        physical_ramp_length_m: length, physical_ramp_mount_y_m: mount_y,
        source_revision: source.source_revision, ramps: details};
    report_structured_verdict(result, "GRIFFIN RAMP TOUCHDOWN GEOMETRY",
        "GRIFFIN_RAMP_TOUCHDOWN_GEOMETRY");
    this.done = true;
}
