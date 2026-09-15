// Standalone Griffin propellant-tank visual verification.

const PACKAGE = "GriffinTankRequirements";
const VERIFICATION = "GriffinTankRequirements::Verify_GriffinTankRequirements";

fn own(name) { PACKAGE + "::GriffinPropellantTankAssembly::" + name }

fn on_start(me) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let names_source = sysml_requirements::text(source, own("namesSource"));
    let count_source = sysml_requirements::text(source, own("countSource"));
    let names = component_requirements::source_text_list(source, names_source);
    let checks = [];
    checks.push(component_requirements::source_list_count("GPT-001-count", "propellant_tank", "GriffinTankRequirements::gpt001", VERIFICATION, names_source, count_source));
    for name in names {
        let path = root + "/" + name;
        checks.push(component_requirements::exists("GPT-001-" + name, "tank", "GriffinTankRequirements::gpt001", VERIFICATION, path, "Xform"));
        checks.push(component_requirements::children("GPT-002-" + name, "tank", "GriffinTankRequirements::gpt002", VERIFICATION, path,
            [path + "/MliTank", path + "/TankBandA", path + "/TankBandB", path + "/TankBandC"]));
        checks.push(component_requirements::exists("GPT-002-" + name + "-cradle", "tank", "GriffinTankRequirements::gpt002", VERIFICATION, path + "/TankCradle", "Cube"));
    }
    checks.push(component_requirements::coverage("GPT-003-status", "tank", "GriffinTankRequirements::gpt003", VERIFICATION));
    checks.push(component_requirements::coverage("GPT-004-traceability", "tank", "GriffinTankRequirements::gpt004", VERIFICATION));
    component_requirements::finish(source, checks, "GRIFFIN TANK REQUIREMENTS", "GRIFFIN_TANK_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
