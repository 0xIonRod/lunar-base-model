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
// One bank is the authoring unit. Its body paths survive, while obsolete local
// geometry overrides are retired rather than shadowing the new components.
fn bank_plan(doc,root,docs,index){
    let model=requirements::model();let paths=installed_paths(root,index);let bank=paths[0];
    let found=query("QueryUsdPrim",#{doc_id:doc,path:bank,attrs:[]});
    if found.type_name!="Xform"{throw("Existing ramp body required");}
    let placement=packaging::bank_placements(model,docs,index);let ops=[];
    ops.push(#{RemovePrim:#{edit_target:"@root@",path:bank}});
    ops.push(add(root,spec::ramp_names()[index],()));
    for op in pose_ops(bank,#{translation:placement.position,rotation:placement.rotation}){ops.push(op);}
    let contract=query("ReadActiveTwinContract");if contract.open!=true{throw("Active Twin required");}
    for section in [#{label:"root",parent:bank,name:"DeckSection",path:bank+"/DeckSection",pose:placement.deck},
        #{label:"middle",parent:bank,name:"MiddleSection",path:paths[1],pose:placement.middle},
        #{label:"toe",parent:paths[1],name:"ToeSection",path:paths[2],pose:placement.toe}]{
        ops.push(add(section.parent,section.name,"twin://"+contract.name+"/"+model.value(packaging::component_owner(section.label)+"::componentAsset")));
        for op in pose_ops(section.path,section.pose){ops.push(op);}
        let body=if section.label=="root"{bank}else{section.path};
        let schemas=["PhysicsRigidBodyAPI","PhysxRigidBodyAPI","PhysicsMassAPI"];
        if section.label=="root"{schemas.push("PhysicsFilteredPairsAPI");}
        ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:body,schemas:schemas}});
        for op in section_mass_ops(model,body,section.label,placement.deck){ops.push(op);}
    }
    let side=if index==0{"port"}else{"starboard"};
    ops.push(#{SetRelationship:#{edit_target:"@root@",path:bank,name:"physics:filteredPairs",targets:[root+"/"+spec::physical_ramp_transition_body_name(side)]}});
    let r="GriffinRampRequirements::GriffinEgressRamp::";
    ops.push(scalar(bank,"lunco:operational_width_m","double",model.value(r+"rampSurfaceWidthM")));
    ops.push(scalar(bank,"lunco:wheel_clearance_m","double",model.value(r+"rampWheelClearanceM")));
    ops.push(scalar(bank,"lunco:deployment_angle_rad","float",0.0));
    // Explicit mount frame coincides with the solved root bearing axis.
    ops.push(add(bank,"MountFrame",()));
    for op in pose_ops(bank+"/MountFrame",#{translation:[0.0,0.0,0.0],rotation:quat_array(quat_identity())}){ops.push(op);}
    ops.push(#{SetRelationship:#{edit_target:"@root@",path:bank,name:"lunco:mount:frame",targets:[bank+"/MountFrame"]}});
    ops.push(#{SetAttribute:#{edit_target:"@root@",path:bank,name:"lunco:mount:plug",type_name:"token",value:"\"egress_ramp\""}});
    let bus=frames::mount_local_transform(doc,root+"/Bus");if !bus.ok{throw("Bus mount required");}
    let socket=frames::mount_transform_compose(frames::mount_transform_inverse(bus.value),#{translation:placement.position,rotation:placement.rotation});
    for op in pose_ops(root+"/Bus/RampSocket"+if index==0{"Port"}else{"Starboard"},socket){ops.push(op);}
    #{ok:true,ops:ops,doc_id:doc,generation:found.document_generation,source_revision:model.source_revision,kind:"griffin_unequal_ramp_bank",root:bank}
}

// Each joint and its parallel flight latch are a single interface task.
fn joint_plan(doc,root,docs,bank,index){
    if index<0 || index>2{throw("Select root, middle or toe hinge");}
    let model=requirements::model();let paths=installed_paths(root,bank);
    let placement=packaging::bank_placements(model,docs,bank);
    let names=spec::ramp_intermediate_joint_names();
    let name=if index==0{spec::ramp_root_joint_names()[bank]}else{names[bank*2+index-1]};
    let joint=root+"/"+name;let current=query("QueryUsdPrim",#{doc_id:doc,path:joint,attrs:[]});
    if current.type_name!="PhysicsRevoluteJoint"{throw("Existing native hinge required");}
    let body0=if index==0{root}else{paths[index-1]};let body1=paths[index];
    let parent=();let child=();let physical=();let offset=();let stow=();
    if index==0{parent=placement.position;child=[0.0,0.0,0.0];physical=placement.rotation;
        stow=if bank==0{spec::physical_ramp_port_root_stowed_angle_rad()}else{-spec::physical_ramp_starboard_root_stowed_angle_rad()};}
    else{
        let labels=["root","middle","toe"];
        let a=datum(model,docs,labels[index-1],"exitFrameName");let b=datum(model,docs,labels[index],"entryFrameName");
        parent=a.translation;child=b.translation;
        if index==1{parent=vec3_array(vec3_from(parent)+vec3_from(placement.deck.translation));}
        physical=if index==1{placement.middle.rotation}else{placement.toe.rotation};
        let sign=if index==1{1.0}else{-1.0};
        offset=spec::physical_ramp_section_joint_frame_offset_rad(if index==1{"middle"}else{"toe"});
        stow=sign*spec::physical_ramp_section_stowed_relative_angle_rad()+offset;
    }
    let ops=[];
    for rel in [#{name:"physics:body0",targets:[body0]},#{name:"physics:body1",targets:[body1]}]{ops.push(#{SetRelationship:#{edit_target:"@root@",path:joint,name:rel.name,targets:rel.targets}});}
    ops.push(vector(joint,"physics:localPos0","point3f",parent));ops.push(vector(joint,"physics:localPos1","point3f",child));
    if index>0{
        ops.push(vector(joint,"physics:localRot0","quatf",[1.0,0.0,0.0,0.0]));
        ops.push(vector(joint,"physics:localRot1","quatf",usd_quat(quat_from_euler_xyz_deg(vec3(0.0,0.0,offset*180.0/acos(-1.0))))));
    }
    ops.push(scalar(joint,"drive:angular:physics:targetPosition","float",stow*180.0/acos(-1.0)));
    let binding=();for b in spec::ramp_flight_latch_bindings(){if b.hinge==name{binding=b;}}
    if binding==(){throw("Hinge has no source flight latch pairing");}
    let latch=root+"/"+binding.latch;let fixed=query("QueryUsdPrim",#{doc_id:doc,path:latch,attrs:[]});
    if fixed.type_name!="PhysicsFixedJoint"{throw("Existing native flight latch required");}
    ops.push(vector(latch,"physics:localPos0","point3f",parent));ops.push(vector(latch,"physics:localPos1","point3f",child));
    ops.push(vector(latch,"physics:localRot0","quatf",[1.0,0.0,0.0,0.0]));
    ops.push(vector(latch,"physics:localRot1","quatf",usd_quat(quat_inverse(quat_from(physical)))));
    #{ok:true,ops:ops,doc_id:doc,generation:current.document_generation,source_revision:model.source_revision,kind:"griffin_unequal_ramp_interface",joint:joint,latch:latch}
}

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
