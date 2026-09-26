import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
// Standalone FLIP chassis verification.

const PACKAGE = "FlipChassisRequirements";
const VERIFICATION = "Verify_FLIPChassisRequirements";

fn own(name) { PACKAGE + "::FlipChassisComponent::" + name }

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let root = sysml_requirements::text(source, own("usdPath"));
    let source_owner = sysml_requirements::attribute(source, own("usdPath")).record.owner_handle;
    let chassis_width = sysml_requirements::number_from_reference(source,
        source_owner, "lowerFrameWidthM");
    let chassis_length = sysml_requirements::number_from_reference(source,
        source_owner, "lowerFrameLengthM");
    let member_names = sysml_requirement_checks::source_enum_identifiers(source,
        own("childNames"));
    let child_paths = [];
    for name in member_names { child_paths.push(root + "/" + name); }
    let checks = [];
    checks.push(sysml_requirement_checks::exists("FCC-001-root", "chassis", "fcc001", VERIFICATION, root, "Xform"));
    checks.push(sysml_requirement_checks::children("FCC-001-structure", "chassis", "fcc001", VERIFICATION, root, child_paths));
    checks.push(#{id: "FCC-002-width", component: "chassis", requirement: "fcc002",
        verification: VERIFICATION, kind: "extent_component", path: root + "/LowerFrame",
        index: 0, multiplier: 2.0, expected: chassis_width.value,
        tolerance: 0.002});
    checks.push(#{id: "FCC-002-length", component: "chassis", requirement: "fcc002",
        verification: VERIFICATION, kind: "extent_component", path: root + "/LowerFrame",
        index: 2, multiplier: 2.0, expected: chassis_length.value,
        tolerance: 0.002});
    for path in [root + "/LowerFrame", root + "/WhiteEquipmentBox",
        root + "/FrontBumper", root + "/PayloadDeck"] {
        checks.push(sysml_requirement_checks::attribute_equals("FCC-003-collision-" + path,
            "chassis", "fcc003", VERIFICATION, path, "physics:collisionEnabled", true));
    }
    for field in [
        #{id: "FCC-005-box-width", path: root + "/WhiteEquipmentBox", index: 0, attr: "equipmentBoxWidthM"},
        #{id: "FCC-005-box-height", path: root + "/WhiteEquipmentBox", index: 1, attr: "equipmentBoxHeightM"},
        #{id: "FCC-005-box-length", path: root + "/WhiteEquipmentBox", index: 2, attr: "equipmentBoxLengthM"},
        #{id: "FCC-005-deck-width", path: root + "/PayloadDeck", index: 0, attr: "payloadDeckWidthM"},
        #{id: "FCC-005-deck-thickness", path: root + "/PayloadDeck", index: 1, attr: "payloadDeckThicknessM"},
        #{id: "FCC-005-deck-length", path: root + "/PayloadDeck", index: 2, attr: "payloadDeckLengthM"}
    ] {
        checks.push(sysml_requirement_checks::extent_component(field.id, "chassis", "fcc005", VERIFICATION,
            field.path, field.index, own(field.attr), 2.0, 0.002));
    }
    checks.push(#{id: "FCC-005-box-y", component: "chassis", requirement: "fcc005",
        verification: VERIFICATION, kind: "attribute_component", path: root + "/WhiteEquipmentBox",
        attr: "xformOp:translate", index: 1, expected_attr: own("equipmentBoxCenterYM"), tolerance: 0.002});
    checks.push(#{id: "FCC-005-deck-y", component: "chassis", requirement: "fcc005",
        verification: VERIFICATION, kind: "attribute_component", path: root + "/PayloadDeck",
        attr: "xformOp:translate", index: 1, expected_attr: own("payloadDeckCenterYM"), tolerance: 0.002});
    checks.push(sysml_requirement_checks::coverage("FCC-003-ownership", "chassis", "fcc003", VERIFICATION));
    checks.push(sysml_requirement_checks::coverage("FCC-004-traceability", "chassis", "fcc004", VERIFICATION));
    sysml_requirement_checks::finish(source, checks, "FLIP CHASSIS REQUIREMENTS", "FLIP_CHASSIS_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
