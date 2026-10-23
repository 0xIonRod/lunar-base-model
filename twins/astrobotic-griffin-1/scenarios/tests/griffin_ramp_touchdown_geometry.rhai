import "twin://astrobotic-griffin-1/tools/griffin_ramp_installed_checks.rhai" as installed;
fn simulation_dependencies(me,ctx){installed::dependencies()}
fn on_start(me,ctx){this.state=installed::begin("touchdown");this.done=false;}
fn on_tick(me,ctx){
    if this.done{return;}
    try{this.state=installed::step(this.state);if this.state.done{
        report_structured_verdict(installed::verdict(this.state),"GRIFFIN RAMP TOUCHDOWN GEOMETRY","GRIFFIN_RAMP_TOUCHDOWN_GEOMETRY");this.done=true;
    }}catch(error){report_structured_verdict(#{ok:false,verdict:"error",check_count:1,error_count:1,
        non_pass_count:1,non_pass_results:[#{id:"installed-ramp-source",verdict:"error",error:error.to_string()}]},"GRIFFIN RAMP TOUCHDOWN GEOMETRY","GRIFFIN_RAMP_TOUCHDOWN_GEOMETRY");this.done=true;}
}
