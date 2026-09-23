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
    let checks = [];
    checks.push(sysml_requirement_checks::exists("FCC-001-root", "chassis", "fcc001", VERIFICATION, root, "Xform"));
    checks.push(sysml_requirement_checks::children("FCC-001-structure", "chassis", "fcc001", VERIFICATION, root,
        [root + "/LowerFrame", root + "/WhiteEquipmentBox", root + "/FrontBumper",
         root + "/PayloadDeck", root + "/ServicePanel"]));
    checks.push(sysml_requirement_checks::extent_component("FCC-002-width", "chassis", "fcc002", VERIFICATION,
        root + "/LowerFrame", 0, sysml_requirements::text(source, own("widthSource")), 2.0, 0.002));
    checks.push(sysml_requirement_checks::extent_component("FCC-002-length", "chassis", "fcc002", VERIFICATION,
        root + "/LowerFrame", 2, sysml_requirements::text(source, own("lengthSource")), 2.0, 0.002));
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
