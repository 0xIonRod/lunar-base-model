// Standalone Griffin main-propulsion visual verification.  Thrust and
// collision remain owned by the flight model; this observer checks only the
// replaceable bell/throat presentation components.

const PACKAGE = "GriffinPropulsionRequirements";
const VERIFICATION = "GriffinPropulsionRequirements::Verify_GriffinPropulsionRequirements";

fn own(name) { PACKAGE + "::GriffinMainPropulsionAssembly::" + name }

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
    checks.push(component_requirements::source_list_count("GPP-001-count", "propulsion", "GriffinPropulsionRequirements::gpp001", VERIFICATION, names_source, count_source));
    for name in names {
        let path = root + "/" + name;
        checks.push(component_requirements::exists("GPP-001-" + name, "engine", "GriffinPropulsionRequirements::gpp001", VERIFICATION, path, "Xform"));
        checks.push(component_requirements::children("GPP-002-" + name, "engine", "GriffinPropulsionRequirements::gpp002", VERIFICATION, path,
            [path + "/Bell", path + "/Throat"]));
        checks.push(component_requirements::attribute_equals("GPP-002-" + name + "-purpose", "engine", "GriffinPropulsionRequirements::gpp002", VERIFICATION,
            path + "/Bell", "purpose", "render"));
    }
    checks.push(component_requirements::coverage("GPP-003-ownership", "propulsion", "GriffinPropulsionRequirements::gpp003", VERIFICATION));
    checks.push(component_requirements::coverage("GPP-004-traceability", "propulsion", "GriffinPropulsionRequirements::gpp004", VERIFICATION));
    component_requirements::finish(source, checks, "GRIFFIN PROPULSION REQUIREMENTS", "GRIFFIN_PROPULSION_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
