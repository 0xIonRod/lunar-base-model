// Standalone Griffin dual solar-array visual verification.

const PACKAGE = "GriffinSolarRequirements";
const VERIFICATION = "GriffinSolarRequirements::Verify_GriffinSolarRequirements";

fn own(name) { PACKAGE + "::GriffinSolarArrayAssembly::" + name }

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
    checks.push(component_requirements::source_list_count("GSA-001-count", "lander_solar", "GriffinSolarRequirements::gsa001", VERIFICATION, names_source, count_source));
    for name in names {
        let path = root + "/" + name;
        checks.push(component_requirements::exists("GSA-001-" + name, "solar_array", "GriffinSolarRequirements::gsa001", VERIFICATION, path, "Xform"));
        checks.push(component_requirements::children("GSA-002-" + name, "solar_array", "GriffinSolarRequirements::gsa002", VERIFICATION, path,
            [path + "/Frame", path + "/Cells"]));
    }
    checks.push(component_requirements::coverage("GSA-003-symmetry", "solar_array", "GriffinSolarRequirements::gsa003", VERIFICATION));
    checks.push(component_requirements::coverage("GSA-004-traceability", "solar_array", "GriffinSolarRequirements::gsa004", VERIFICATION));
    component_requirements::finish(source, checks, "GRIFFIN SOLAR REQUIREMENTS", "GRIFFIN_SOLAR_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
