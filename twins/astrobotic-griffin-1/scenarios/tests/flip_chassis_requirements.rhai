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
    checks.push(component_requirements::exists("FCC-001-root", "chassis", "fcc001", VERIFICATION, root, "Xform"));
    checks.push(component_requirements::children("FCC-001-structure", "chassis", "fcc001", VERIFICATION, root,
        [root + "/LowerFrame", root + "/WhiteEquipmentBox", root + "/PayloadDeck"]));
    checks.push(component_requirements::extent_component("FCC-002-width", "chassis", "fcc002", VERIFICATION,
        root + "/LowerFrame", 0, sysml_requirements::text(source, own("widthSource")), 2.0, 0.002));
    checks.push(component_requirements::extent_component("FCC-002-length", "chassis", "fcc002", VERIFICATION,
        root + "/LowerFrame", 2, sysml_requirements::text(source, own("lengthSource")), 2.0, 0.002));
    checks.push(component_requirements::coverage("FCC-003-ownership", "chassis", "fcc003", VERIFICATION));
    checks.push(component_requirements::coverage("FCC-004-traceability", "chassis", "fcc004", VERIFICATION));
    component_requirements::finish(source, checks, "FLIP CHASSIS REQUIREMENTS", "FLIP_CHASSIS_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
