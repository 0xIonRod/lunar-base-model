import "lunco://scripting/tools/assembly_builder" as assembly;
import "lunco://scripting/tools/sysml_requirements" as requirements;
fn owner(){"FlipWheelRequirements::FlipDirectionalWheelAssembly::"}
fn render_name(){let name=requirements::model().value(owner()+"renderRootName");if !sysml_enum_is(name){throw("Wheel render-root identity is unavailable");}name.literal}
fn plan(doc,target,path){
    let model=requirements::model();let vehicle=model.value("FlipRequirements::FlipRover::componentAsset");
    let origin=query("InspectUsdDocument",#{doc_id:doc}).origin;
    if origin.File==() || !origin.File.path.ends_with("/"+vehicle){throw("Wheel installation requires the canonical source vehicle document");}
    let record=query("QueryUsdPrim",#{doc_id:doc,path:path,schemas:true,children:true,attrs:[]});
    if record.type_name!="Cylinder" || !record.api_schemas.contains("PhysxVehicleWheelAPI"){throw("Select a composed physical wheel cylinder");}
    let name=render_name();let root=path+"/"+name;
    if record.children.contains(root){throw("The selected wheel already has its render root");}
    let folders=vehicle.split("/");folders.pop();let relative="";for folder in folders{relative+="../";}
    relative+=model.value("FlipAirlessWheelRequirements::AirlessWheelVisual::componentAsset");
    let schemas=record.api_schemas;if !schemas.contains("VisibilityAPI"){schemas.push("VisibilityAPI");}
    let ops=[#{SetApiSchemas:#{edit_target:target,path:path,schemas:schemas}},
        #{SetAttribute:#{edit_target:target,path:path,name:"purpose",type_name:"token",value:"\"proxy\""}},
        #{SetAttribute:#{edit_target:target,path:path,name:"proxyVisibility",type_name:"token",value:"\"invisible\""}},
        #{AddPrim:#{edit_target:target,parent_path:path,name:name,type_name:"Xform",reference:relative,reference_prim_path:""}},
        #{SetApiSchemas:#{edit_target:target,path:root,schemas:["VisibilityAPI"]}},
        #{SetAttribute:#{edit_target:target,path:root,name:"purpose",type_name:"token",value:"\"render\""}},
        #{SetAttribute:#{edit_target:target,path:root,name:"renderVisibility",type_name:"token",value:"\"visible\""}}];
    let pose=assembly::place_plan(target,root,[0.0,0.0,0.0],[0.0,0.0,0.0],[1.0,1.0,1.0]);if !pose.ok{return pose;}for op in pose.ops{ops.push(op);}
    #{ok:true,doc_id:doc,generation:query("InspectUsdDocument",#{doc_id:doc}).generation,source_revision:model.source_revision,ops:ops}
}
