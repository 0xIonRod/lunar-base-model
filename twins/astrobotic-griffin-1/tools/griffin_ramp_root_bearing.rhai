import "lunco://scripting/tools/assembly_builder" as assembly;
import "lunco://scripting/tools/sysml_requirements" as requirements;
fn owner(){"GriffinRampRootBearingRequirements::RampRootBearing::"}
fn plan(doc,edit_target){
    let model=requirements::model();
    let component_folder=model.value(owner()+"componentAsset").split("/");component_folder.pop();
    let material_folder=model.value("GriffinRampRootSectionRequirements::RampRootSection::componentAsset").split("/");material_folder.pop();
    if component_folder!=material_folder{throw("Relative structural material reference requires the selected source component folder");}
    let geometry=geometry();let points=geometry.points;let mesh=geometry.mesh;
    let current=query("QueryUsdPrim",#{doc_id:doc,path:"/RootBearing"});
    if current.type_name!=(){throw("Bearing creation requires a new component document");}
    let ops=[#{SetStageMetrics:#{edit_target:edit_target,metrics:#{meters_per_unit:1.0,up_axis:"Y"}}},
        #{SetStageDocumentation:#{edit_target:edit_target,documentation:"Griffin root bearing housing reconstruction; SI/Y-up, Z bore. Explicit study assumptions: requirements/griffin_ramp_root_bearing_requirements.sysml; no qualified engineering material, lubricant or load rating."}},
        #{AddPrim:#{edit_target:edit_target,parent_path:"/",name:"RootBearing",type_name:"Xform",reference:(),reference_prim_path:""}},
        #{SetDefaultPrim:#{edit_target:edit_target,default_prim:"/RootBearing"}},
        #{SetPrimKind:#{edit_target:edit_target,path:"/RootBearing",kind:"component"}},
        #{AddPrim:#{edit_target:edit_target,parent_path:"/RootBearing",name:"HingeAxis",type_name:"Xform",reference:(),reference_prim_path:""}},
        #{AddPrim:#{edit_target:edit_target,parent_path:"/RootBearing",name:"Looks",type_name:"Scope",reference:(),reference_prim_path:""}},
        #{AddPrim:#{edit_target:edit_target,parent_path:"/RootBearing/Looks",name:"Structure",type_name:"Material",
            reference:model.value("GriffinRampRootSectionRequirements::RampRootSection::componentAsset").split("/").pop(),reference_prim_path:"/RampSection/Looks/RampStructure"}}];
    let empty=query("QueryUsdPrim",#{doc_id:doc,path:"/World",children:true});
    if empty.type_name=="Xform" && empty.children.len()==0{ops.push(#{RemovePrim:#{edit_target:edit_target,path:"/World"}});}
    let shape=assembly::mesh_shape_plan(edit_target,"/RootBearing","Housing",points,mesh.face_vertex_counts,mesh.face_vertex_indices,[0.55,0.58,0.62],false);
    if !shape.ok{return shape;}for op in shape.ops{ops.push(op);}
    let datum=assembly::place_plan(edit_target,"/RootBearing/HingeAxis",[0.0,0.0,0.0],[0.0,0.0,0.0],());
    if !datum.ok{return datum;}for op in datum.ops{ops.push(op);}
    ops.push(#{SetApiSchemas:#{edit_target:edit_target,path:"/RootBearing/Housing",schemas:["PhysicsCollisionAPI","MaterialBindingAPI"]}});
    ops.push(#{SetRelationship:#{edit_target:edit_target,path:"/RootBearing/Housing",name:"material:binding",targets:["/RootBearing/Looks/Structure"]}});
    #{ok:true,ops:ops,source_revision:model.source_revision,doc_id:doc,generation:query("InspectUsdDocument",#{doc_id:doc}).generation}
}

fn geometry(){
    let model=requirements::model();let own=owner();let inner=model.value(own+"innerRadiusM");
    let outer=model.value(own+"outerRadiusM");let length=model.value(own+"axialLengthM");
    if inner<=0.0 || outer<=inner || length<=0.0{throw("Bearing stock is invalid");}
    let profile=[vec2(inner,-length/2.0),vec2(outer,-length/2.0),vec2(outer,length/2.0),vec2(inner,length/2.0)];
    let mesh=revolve_profile(profile,vec3(0.0,0.0,1.0),48);let points=[];
    for p in mesh.points{points.push(vec3_array(p));}
    #{points:points,mesh:mesh}
}
fn update_plan(doc,edit_target){
    let geometry=geometry();let mesh=geometry.mesh;
    let result=assembly::mesh_geometry_update_plan(edit_target,"/RootBearing/Housing",geometry.points,mesh.face_vertex_counts,mesh.face_vertex_indices);
    result.doc_id=doc;result.generation=query("InspectUsdDocument",#{doc_id:doc}).generation;result.source_revision=requirements::model().source_revision;result
}
