// Standalone Griffin landing-leg verification.  The identity list and count
// are read from GriffinLanderRequirements; no leg names are duplicated here.

const PACKAGE = "GriffinLandingLegRequirements";
const VERIFICATION = "GriffinLandingLegRequirements::Verify_GriffinLandingLegRequirements";

fn own(name) { PACKAGE + "::GriffinLandingLegAssembly::" + name }

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
    checks.push(component_requirements::source_list_count("GLL-001-count", "landing_legs", "GriffinLandingLegRequirements::gll001", VERIFICATION, names_source, count_source));
    for name in names {
        let path = root + "/" + name;
        checks.push(component_requirements::exists("GLL-001-" + name, "landing_leg", "GriffinLandingLegRequirements::gll001", VERIFICATION, path, "Xform"));
        checks.push(component_requirements::children("GLL-002-" + name, "landing_leg", "GriffinLandingLegRequirements::gll002", VERIFICATION, path,
            [path + "/StrutOuter", path + "/StrutInner", path + "/ShockPiston", path + "/FootPad"]));
    }
    checks.push(component_requirements::coverage("GLL-003-frame", "landing_leg", "GriffinLandingLegRequirements::gll003", VERIFICATION));
    checks.push(component_requirements::coverage("GLL-004-traceability", "landing_leg", "GriffinLandingLegRequirements::gll004", VERIFICATION));
    component_requirements::finish(source, checks, "GRIFFIN LANDING LEG REQUIREMENTS", "GRIFFIN_LANDING_LEG_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
