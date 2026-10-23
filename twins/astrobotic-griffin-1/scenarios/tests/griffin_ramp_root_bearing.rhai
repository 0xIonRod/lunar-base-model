import "../../tools/griffin_ramp_root_bearing_checks.rhai" as bearing;
import "lunco://scripting/tools/sysml_requirement_checks" as checks;
import "lunco://scripting/tools/sysml_requirements" as requirements;
fn simulation_dependencies(me,ctx){bearing::dependencies()}
fn on_start(me,ctx){this.done=false;this.started=elapsed_seconds();}
fn on_tick(me,ctx){if this.done || elapsed_seconds()-this.started<0.1{return;}
    this.done=true;try{
    let doc=ctx.doc_id;
    let root=if doc==(){requirements::model().value("GriffinRampRootBearingRequirements::RampRootBearing::usdPath")}else{ctx.root};
    let found=bearing::observe(doc,root);print("GRIFFIN_ROOT_BEARING_MEASUREMENTS "+found.measurements.to_string());
    checks::finish(found.source,found.checks,"GRIFFIN ROOT BEARING","GRIFFIN_ROOT_BEARING",found.path,found.package_name,found.verification);
    }catch(error){report_structured_verdict(#{ok:false,verdict:"error",error_count:1,non_pass_count:1,non_pass_results:[#{verdict:"error",id:"bearing-observation",error:error.to_string()}]},"GRIFFIN ROOT BEARING","GRIFFIN_ROOT_BEARING");}
}
