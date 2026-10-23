import "../../tools/flip_airless_wheel_checks.rhai" as wheel;
import "../../tools/usd_geometry_inspection.rhai" as inspection;
import "lunco://scripting/tools/sysml_requirements" as requirements;
fn simulation_dependencies(me,ctx){wheel::dependencies()}
fn on_start(me,ctx){
    let root=if ctx.root==(){requirements::model().value("FlipAirlessWheelRequirements::AirlessWheelVisual::usdPath")}else{ctx.root};
    let doc=if ctx.doc_id==(){inspection::document_owner(root)}else{ctx.doc_id};
    this.state=wheel::begin(doc,root);this.done=false;print("FLIP_AIRLESS_STARTED actor="+me.to_string());
}
fn on_tick(me,ctx){if this.done{return;}try{this.state=wheel::advance(this.state);this.done=this.state.done;}
    catch(error){this.done=true;report_structured_verdict(#{ok:false,verdict:"error",error_count:1,non_pass_count:1,non_pass_results:[#{verdict:"error",id:"airless-wheel-observation",error:error.to_string()}]},"FLIP AIRLESS WHEEL","FLIP_AIRLESS_WHEEL");}}
