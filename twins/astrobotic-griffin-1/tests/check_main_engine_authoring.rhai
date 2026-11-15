// Run in a mounted Griffin Twin after its SysML source set is ready.
// incomplete_doc has the seven engine groups but omits Engine01/FuelValve;
// complete_doc is the canonical surface scene document. The calls are dry.
fn incomplete_main_feed_ops() {
    let main="/World/MainPropulsion";
    let parts=[#{parent:"/World",name:"MainPropulsion"}];
    for name in ["FuelTank","OxidizerTank","NozzleDesign","PropellantStatus"] {parts.push(#{parent:main,name:name});}
    for name in griffin_spec::main_engine_names() {
        parts.push(#{parent:main,name:name});
        for child in ["FuelValve","OxidizerValve","Chamber"] {
            if name!="Engine01" || child!="FuelValve" {parts.push(#{parent:main+"/"+name,name:child});}
        }
        for suffix in ["Plume","Wall"] {parts.push(#{parent:main,name:name+suffix});}
    }
    let ops=[];
    for part in parts {ops.push(#{AddPrim:#{edit_target:"@root@",parent_path:part.parent,
        name:part.name,type_name:"Scope",reference:(),reference_prim_path:()}});}
    ops
}
fn check_main_engine_authoring(incomplete_doc,complete_doc) {
    let rejected=griffin_visual_builder::griffin_main_engine_feed_plan(incomplete_doc,"@root@","/World");
    let accepted=griffin_visual_builder::griffin_main_engine_feed_plan(complete_doc,"@root@","/Griffin1SurfaceOps/Lander");
    let members=[];
    if accepted.ok {
        for op in accepted.ops {
            if op.contains("SetRelationship") && op.SetRelationship.name=="collection:components:includes" {
                members=op.SetRelationship.targets;
            }
        }
    }
    report_verdict([
        t_true(!rejected.ok && rejected.ops.len()==0,"missing valve rejects the plan before any write"),
        t_true(rejected.to_string().contains("Engine01/FuelValve"),"rejection names the missing composed member"),
        t_true(accepted.ok && members.len()==39,"complete valve/chamber assembly retains one 39-member solver plan")
    ],"GRIFFIN MAIN ENGINE AUTHORING","GRIFFIN_MAIN_ENGINE_AUTHORING");
}
