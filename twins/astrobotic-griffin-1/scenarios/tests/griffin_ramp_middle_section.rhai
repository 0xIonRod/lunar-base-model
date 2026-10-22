import "twin://astrobotic-griffin-1/tools/griffin_ramp_middle_section_checks.rhai" as root_section;
import "lunco://scripting/tools/sysml_requirement_checks" as checks;

fn simulation_dependencies(me,ctx){root_section::dependencies()}
fn on_start(me,ctx){this.done=false;this.started=elapsed_seconds();}
fn on_tick(me,ctx){
    if this.done || elapsed_seconds()-this.started<0.1{return;}
    let found=root_section::observe((),root_section::fixture_path());
    checks::finish(found.source,found.checks,"GRIFFIN MIDDLE SECTION","GRIFFIN_RAMP_MIDDLE_SECTION",
        found.path,found.package_name,found.verification);
    this.done=true;
}
