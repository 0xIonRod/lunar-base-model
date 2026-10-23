// Articulated installation of the independently authored unequal sections.
// Geometry stays referenced; this owner supplies bodies, datums and joints.
import "griffin_ramp_packaging" as packaging;
import "griffin_ramp_section_component" as component;
import "griffin_spec" as spec;
import "griffin_visual_builder" as visual;
import "lunco://scripting/tools/assembly_builder" as frames;
import "lunco://scripting/tools/sysml_requirements" as requirements;

fn scalar(path,name,kind,value){#{SetAttribute:#{edit_target:"@root@",path:path,name:name,type_name:kind,value:value.to_string()}}}
fn tuple(values){let text="(";for i in 0..values.len(){if i>0{text+=", ";}text+=values[i].to_string();}text+")"}
fn vector(path,name,kind,value){#{SetAttribute:#{edit_target:"@root@",path:path,name:name,type_name:kind,value:tuple(value)}}}
fn usd_quat(q){let a=quat_array(q);[a[3],a[0],a[1],a[2]]}
fn datum(model,docs,label,feature){
    let name=component::frame_name(model,packaging::component_owner(label),feature);
    let result=frames::mount_local_transform(docs[label],"/RampSection/"+name);
    if !result.ok{throw("Source section datum unavailable: "+label+"/"+name);}
    result.value
}
fn installed_paths(root,index){
    if index!=0 && index!=1{throw("Select port or starboard bank");}
    let bank=root+"/"+spec::ramp_names()[index];
    [bank,bank+"/MiddleSection",bank+"/MiddleSection/ToeSection"]
}
fn add(parent,name,asset){#{AddPrim:#{edit_target:"@root@",parent_path:parent,name:name,type_name:"Xform",reference:asset,reference_prim_path:if asset==(){""}else{"/RampSection"}}}}
fn pose_ops(path,pose){
    let placed=frames::place_plan("@root@",path,pose.translation,frames::mount_xyz_deg_from_quat(pose.rotation),[1.0,1.0,1.0]);
    if !placed.ok{throw("Rigid section placement failed");}placed.ops
}
fn section_mass_ops(model,path,label,deck){
    let r="GriffinRampRequirements::GriffinEgressRamp::";
    let mass=model.value(r+"physicalRampSectionMassKg");
    let length=model.value(packaging::component_owner(label)+"::lengthM");
    let width=model.value(r+"rampSurfaceWidthM");let thickness=model.value(r+"rampSurfaceThicknessM");
    if mass<=0.0 || length<=0.0 || width<=0.0 || thickness<=0.0{throw("Invalid section mass proxy inputs");}
    // Existing equal-mass thin rectangular plate proxy, with each actual span.
    // This is an explicit reconstruction estimate, not measured hardware inertia.
    let centre=vec3(length/2.0,model.value(r+"rampSurfaceCenterYM"),0.0);
    if label=="root"{centre=transform_apply_point(transform(vec3_from(deck.translation),quat_from(deck.rotation),vec3(1.0,1.0,1.0)),centre);}
    [scalar(path,"physics:mass","float",mass),
        vector(path,"physics:centerOfMass","point3f",vec3_array(centre)),
        vector(path,"physics:diagonalInertia","float3",[mass*(width*width+thickness*thickness)/12.0,
            mass*(length*length+width*width)/12.0,mass*(length*length+thickness*thickness)/12.0]),
        vector(path,"physics:principalAxes","quatf",[1.0,0.0,0.0,0.0])]
}
// Paired rigid-bank authoring is retired. Preserve explicit diagnostics for
// old authoring callers; the production owner is griffin_ramp_tracks.
fn bank_plan(doc,root,docs,index){throw("Use griffin_ramp_tracks::body_plan for independent tracks");}
fn joint_plan(doc,root,docs,bank,index){throw("Use griffin_ramp_tracks::interface_plan for independent tracks");}

fn transition_plan(doc,root,bank){
    let model=requirements::model();let r="GriffinRampRequirements::GriffinEgressRamp::";let own=packaging::owner();
    let side=if bank==0{"port"}else if bank==1{"starboard"}else{throw("Select one bank");};
    let sign=if bank==0{1.0}else{-1.0};let path=root+"/"+spec::physical_ramp_transition_body_name(side);
    let found=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]});if found.type_name!="Xform"{throw("Transition body required");}
    let length=model.value(own+"transitionLengthM");let width=model.value(own+"transitionTrackWidthM");
    let thickness=spec::ramp_surface_thickness_m();let mass=model.value(r+"physicalRampDeckTransitionMassKg");
    let station=abs(spec::rover_wheel_station_z()[0]);let edge=model.value(own+"transitionOutboardX");
    let position=[sign*(edge-length/2.0),model.value(r+"physicalRampDeckTransitionCenterY"),model.value(own+"mountZ")];
    let ops=pose_ops(path,#{translation:position,rotation:quat_array(quat_identity())});
    let retired=path+"/"+spec::physical_ramp_transition_contact_child_name();
    ops.push(#{RemovePrim:#{edit_target:"@root@",path:retired}});
    for track in [#{name:"RampTrackPort",z:station},#{name:"RampTrackStarboard",z:-station}]{
        let shape=visual::_component_cube_visual_ops(doc,"@root@",path,track.name,[0.0,0.0,track.z],(),[length,thickness,width],model.value(r+"rampTrackDisplayColor"));
        if !shape.ok{throw("Transition track plan rejected");}for op in shape.ops{ops.push(op);}
        let member=path+"/"+track.name;
        ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:member,schemas:["PhysicsCollisionAPI","MaterialBindingAPI"]}});
        ops.push(scalar(member,"physics:collisionEnabled","bool",true));
        ops.push(#{SetAttribute:#{edit_target:"@root@",path:member,name:"purpose",type_name:"token",value:"\"default\""}});
        ops.push(#{SetRelationship:#{edit_target:"@root@",path:member,name:"material:binding",targets:[installed_paths(root,bank)[0]+"/DeckSection/Looks/RampWalkingPlate"]}});
    }
    ops.push(vector(path,"physics:centerOfMass","point3f",[0.0,0.0,0.0]));
    ops.push(vector(path,"physics:diagonalInertia","float3",[mass*((width*width+thickness*thickness)/12.0+station*station),
        mass*((length*length+width*width)/12.0+station*station),mass*(length*length+thickness*thickness)/12.0]));
    let joint=root+"/"+spec::physical_ramp_transition_joint_name(side);
    ops.push(vector(joint,"physics:localPos0","point3f",position));
    ops.push(vector(joint,"physics:localPos1","point3f",[0.0,0.0,0.0]));
    #{ok:true,ops:ops,doc_id:doc,generation:found.document_generation,source_revision:model.source_revision,kind:"griffin_split_track_transition",root:path}
}

fn supports_plan(doc,root,docs,bank){
    let model=requirements::model();let placement=packaging::bank_placements(model,docs,bank);
    let material=installed_paths(root,bank)[0]+"/DeckSection/Looks/RampStructure";
    let plan=visual::_griffin_ramp_mount_at_plan(doc,"@root@",root,if bank==0{"port"}else{"starboard"},placement.position,material);
    if !plan.ok{throw("Ramp mount plan rejected");}let ops=plan.ops;
    for station in 0..2{
        let bearing=packaging::bearing_station_plan_at(doc,"@root@",docs,bank,station,root,material);
        if !bearing.ok{throw("Ramp bearing plan rejected");}for op in bearing.ops{ops.push(op);}
    }
    #{ok:true,ops:ops,doc_id:doc,generation:query("QueryUsdPrim",#{doc_id:doc,path:root,attrs:[]}).document_generation,source_revision:model.source_revision,kind:"griffin_root_supports"}
}
