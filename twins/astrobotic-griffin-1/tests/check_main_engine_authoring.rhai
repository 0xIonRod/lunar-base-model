// Run in a mounted Griffin Twin after its SysML source set is ready.
// incomplete_doc has the seven engine groups but omits Engine01/FuelValve;
// complete_doc is the canonical surface scene document. The calls are dry.
fn incomplete_main_feed_ops() {
    let main="/World/MainPropulsion";
    let group=griffin_propulsion_builder::main_engine_presentation_path("/World");
    let parts=[#{parent:"/World",name:"MainPropulsion"},#{parent:"/World",name:"MainEnginePresentation"}];
    for name in ["FuelTank","OxidizerTank","NozzleDesign","PropellantStatus"] {parts.push(#{parent:main,name:name});}
    for name in griffin_spec::main_engine_names() {
        parts.push(#{parent:main,name:name});
        for child in ["FuelValve","OxidizerValve","Chamber"] {
            if name!="Engine01" || child!="FuelValve" {parts.push(#{parent:main+"/"+name,name:child});}
        }
        parts.push(#{parent:group,name:name});
        for member in ["Plume","Wall"] {parts.push(#{parent:group+"/"+name,name:member});}
    }
    let ops=[];
    for part in parts {ops.push(#{AddPrim:#{edit_target:"@root@",parent_path:part.parent,
        name:part.name,type_name:"Scope",reference:(),reference_prim_path:()}});}
    ops
}
fn _collection_members(plan) {
    if !plan.ok {return [];}
    for op in plan.ops {
        if op.contains("SetRelationship") && op.SetRelationship.name=="collection:components:includes" {
            return op.SetRelationship.targets;
        }
    }
    []
}
fn check_main_engine_authoring(incomplete_doc,complete_doc) {
    let rejected=griffin_propulsion_builder::griffin_main_engine_feed_plan(incomplete_doc,"@root@","/World");
    let accepted=griffin_propulsion_builder::griffin_main_engine_feed_plan(complete_doc,"@root@","/Griffin1SurfaceOps/Lander");
    let members=_collection_members(accepted);
    let presented=true;let shown=[];
    for name in griffin_spec::main_engine_names() {
        let plan=griffin_propulsion_builder::griffin_main_engine_presentation_plan(complete_doc,"@root@","/Griffin1SurfaceOps/Lander",name);
        presented=presented && plan.ok;
        let engine_members=_collection_members(plan);
        presented=presented && engine_members.len()==2;
        for member in engine_members {shown.push(member);}
    }
    report_verdict([
        t_true(!rejected.ok && rejected.ops.len()==0,"missing valve rejects the plan before any write"),
        t_true(rejected.to_string().contains("Engine01/FuelValve"),"rejection names the missing composed member"),
        t_true(accepted.ok && members.len()==25,"complete valve/chamber assembly retains one 25-member physics solver plan"),
        t_true(!members.to_string().contains("Plume") && !members.to_string().contains("Wall"),
            "plume and nozzle-wall programs stay out of the physics solver"),
        t_true(presented && shown.len()==14,"every engine admits its plume and wall to its own presentation network")
    ],"GRIFFIN MAIN ENGINE AUTHORING","GRIFFIN_MAIN_ENGINE_AUTHORING");
}
