// Standalone Griffin bus verification.  Geometry is observed from the
// composed visual vehicle; metric envelope values come from the existing
// Griffin lander SysML source through qualified names.

const PACKAGE = "GriffinBusRequirements";
const VERIFICATION = "Verify_GriffinBusRequirements";

fn own(name) { PACKAGE + "::GriffinBusComponent::" + name }
fn lander(name) { "GriffinLanderRequirements::GriffinLanderComponent::" + name }

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let root = sysml_requirements::text(source, own("usdPath"));
    let checks = [];
    checks.push(component_requirements::exists("GBC-001-root", "bus", "gbc001", VERIFICATION, root, "Xform"));
    checks.push(component_requirements::children("GBC-001-structure", "bus", "gbc001", VERIFICATION, root,
        [root + "/PerimeterFrame", root + "/WhiteEquipmentBox", root + "/TopDeck"]));
    checks.push(#{id: "GBC-001-profile", component: "bus",
        requirement: "gbc001", verification: VERIFICATION,
        kind: "attribute_equals", path: root, attr: sysml_requirements::text(source, own("profileAttribute")),
        expected_attr: own("profileValue")});
    checks.push(component_requirements::bounds_component("GBC-002-width", "bus", "gbc002", VERIFICATION,
        root + "/WhiteEquipmentBox", 0, lander("bodyWidthM"), 2.0, 0.002));
    checks.push(component_requirements::bounds_component("GBC-002-depth", "bus", "gbc002", VERIFICATION,
        root + "/WhiteEquipmentBox", 2, lander("bodyDepthM"), 2.0, 0.002));
    checks.push(component_requirements::bounds_component("GBC-002-height", "bus", "gbc002", VERIFICATION,
        root + "/WhiteEquipmentBox", 1, lander("bodyHeightM"), 2.0, 0.002));
    checks.push(component_requirements::coverage("GBC-003-ownership", "bus", "gbc003", VERIFICATION));
    checks.push(component_requirements::coverage("GBC-004-traceability", "bus", "gbc004", VERIFICATION));
    component_requirements::finish(source, checks, "GRIFFIN BUS REQUIREMENTS", "GRIFFIN_BUS_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
