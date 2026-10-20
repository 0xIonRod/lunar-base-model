import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
import "twin://astrobotic-griffin-1/tools/usd_geometry_inspection.rhai" as usd_geometry_inspection;
// Read-only detached suspension verification. The fixture owns composition;
// generic authoring and reference-load behavior belongs to the simulator gates.

const PACKAGE = "FlipSuspensionRequirements";
const VERIFICATION = "Verify_FLIPSuspensionRequirements";
fn own(name) { PACKAGE + "::FlipSuspensionComponent::" + name }
fn simulation_dependencies(me, ctx) { usd_geometry_inspection::dependencies() }

fn fail(me, message) {
    me.done = true;
    report_verdict([t_true(false, message)], "FLIP SUSPENSION REQUIREMENTS", "FLIP_SUSPENSION_REQUIREMENTS");
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    // Every expected value below is read from SysML. The Rhai code only
    // declares generic observation records and never duplicates geometry
    // datums or writes a USD source file.
    let source = sysml_requirements::source();
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let children = sysml_requirement_checks::source_enum_identifiers(source, own("childNames"));
    let arm_scale = sysml_requirement_checks::source_number_list(source, own("armScale"));
    let arm_offset = sysml_requirements::number(source, own("armOffsetM"));
    let knuckle_radius = sysml_requirements::number(source, own("knuckleRadiusM"));
    let knuckle_width = sysml_requirements::number(source, own("knuckleWidthM"));
    let strut_scale = sysml_requirement_checks::source_number_list(source, own("strutScale"));
    let strut_offset = sysml_requirement_checks::source_number_list(source, own("strutOffset"));
    let source_owner = sysml_requirements::attribute(source, own("usdRootPath")).record.owner_handle;
    let physical_rest_source = sysml_requirements::number_from_reference(
        source, source_owner, "physicalRestLength");
    let physical_rest_length = if physical_rest_source.ok == true {
        physical_rest_source.value
    } else { () };
    let physical_rest_status = sysml_requirements::text(source, own("physicalRestLengthStatus"));
    let transform_operations = sysml_requirement_checks::source_enum_identifiers(source, own("transformOrder"));
    let transform_order = [];
    for operation in transform_operations {
        if operation == "Translate" { transform_order.push("xformOp:translate"); }
        else if operation == "Scale" { transform_order.push("xformOp:scale"); }
    }
    let requirement_handle = sysml_requirements::requirement_handle_by_short_name(source, "FSR-001");
    let provenance = if requirement_handle.ok == true {
        sysml_requirements::provenance(source, requirement_handle.handle)
    } else { requirement_handle };
    if root == () || root == "" || children.len() != 3 || arm_scale.len() != 3
        || strut_scale.len() != 3 || strut_offset.len() != 3
        || transform_order.len() != 2
        || arm_offset == () || knuckle_radius == () || knuckle_width == ()
        || physical_rest_length == () || physical_rest_status == () || physical_rest_status == ""
        || physical_rest_source.ok != true || provenance.ok != true
        || provenance.evidence.sources.len() != 2 {
        fail(this, "FlipSuspensionRequirements source contract is incomplete");
        return;
    }
    let arm = root + "/" + children[0];
    let knuckle = root + "/" + children[1];
    let strut = root + "/" + children[2];
    let checks = [];
    checks.push(sysml_requirement_checks::exists("FSR-003-root", "suspension", "fsr003", VERIFICATION, root, "Xform"));
    checks.push(sysml_requirement_checks::children("FSR-003-children", "suspension", "fsr003", VERIFICATION, root, [arm, knuckle, strut]));
    checks.push(sysml_requirement_checks::exists("FSR-003-arm", "suspension", "fsr003", VERIFICATION, arm, "Cube"));
    checks.push(sysml_requirement_checks::exists("FSR-003-knuckle", "suspension", "fsr003", VERIFICATION, knuckle, "Cylinder"));
    checks.push(sysml_requirement_checks::exists("FSR-003-strut", "suspension", "fsr003", VERIFICATION, strut, "Cube"));
    checks.push(sysml_requirement_checks::attribute_equals("FSR-001-source", "suspension", "fsr001", VERIFICATION, root, "lunco:visual:component", "flip_suspension"));
    checks.push(sysml_requirement_checks::attribute_equals("FSR-002-units", "suspension", "fsr002", VERIFICATION, root, "lunco:visual:units", "SI metres, Y-up"));
    for axis in 0..3 {
        checks.push(#{id: "FSR-007-arm-scale-" + axis.to_string(), component: "suspension", requirement: "fsr007", verification: VERIFICATION, kind: "attribute_component", path: arm, attr: "xformOp:scale", index: axis, expected: arm_scale[axis], tolerance: 0.002});
        checks.push(#{id: "FSR-007-strut-scale-" + axis.to_string(), component: "suspension", requirement: "fsr007", verification: VERIFICATION, kind: "attribute_component", path: strut, attr: "xformOp:scale", index: axis, expected: strut_scale[axis], tolerance: 0.002});
        checks.push(#{id: "FSR-007-strut-offset-" + axis.to_string(), component: "suspension", requirement: "fsr007", verification: VERIFICATION, kind: "attribute_component", path: strut, attr: "xformOp:translate", index: axis, expected: strut_offset[axis], tolerance: 0.002});
    }
    checks.push(#{id: "FSR-007-arm-offset", component: "suspension", requirement: "fsr007", verification: VERIFICATION, kind: "attribute_component", path: arm, attr: "xformOp:translate", index: 0, expected: arm_offset, tolerance: 0.002});
    checks.push(sysml_requirement_checks::attribute_equals("FSR-006-arm-order", "suspension", "fsr006", VERIFICATION, arm, "xformOpOrder", transform_order));
    checks.push(sysml_requirement_checks::attribute_equals("FSR-006-strut-order", "suspension", "fsr006", VERIFICATION, strut, "xformOpOrder", transform_order));
    checks.push(#{id: "FSR-007-knuckle-axis", component: "suspension", requirement: "fsr007",
        verification: VERIFICATION, kind: "attribute_equals", path: knuckle,
        attr: "axis", expected_attr: own("knuckleAxis")});
    checks.push(#{id: "FSR-007-knuckle-radius", component: "suspension", requirement: "fsr007", verification: VERIFICATION, kind: "attribute", path: knuckle, attr: "radius", expected: knuckle_radius, tolerance: 0.002});
    checks.push(#{id: "FSR-007-knuckle-width", component: "suspension", requirement: "fsr007", verification: VERIFICATION, kind: "attribute", path: knuckle, attr: "height", expected: knuckle_width, tolerance: 0.002});
    checks.push(sysml_requirements::constraint_check(
        "FSR-008-physical-rest-length", "suspension", "fsr008", VERIFICATION,
        "FlipSuspensionRequirements::FSRC008_PositiveRestLength",
        #{restLengthM: physical_rest_length}, "source_literal", 0.0));
    checks.push(sysml_requirement_checks::coverage("FSR-004-dimensions", "suspension", "fsr004", VERIFICATION));
    for path in [arm, knuckle, strut] {
        checks.push(sysml_requirement_checks::attribute_equals("FSR-005-purpose-" + path, "suspension", "fsr005", VERIFICATION, path, "purpose", "render"));
        checks.push(sysml_requirement_checks::attribute_equals("FSR-005-collision-" + path, "suspension", "fsr005", VERIFICATION, path, "physics:collisionEnabled", false));
    }
    sysml_requirement_checks::finish(source, checks, "FLIP SUSPENSION REQUIREMENTS", "FLIP_SUSPENSION_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
