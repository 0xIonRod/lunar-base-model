import "griffin_visual_builder" as visual;
import "griffin_spec" as spec;
import "griffin_ramp_section_component" as section;
import "lunco://scripting/tools/assembly_builder" as frames;
import "lunco://scripting/tools/sysml_requirements" as requirements;

fn owner(){"GriffinVehicleAssemblyRequirements::GriffinRampPackagingStudy::"}
fn component_owner(label){
    if label=="root"{"GriffinRampRootSectionRequirements::RampRootSection"}
    else if label=="middle"{"GriffinRampMiddleSectionRequirements::RampMiddleSection"}
    else if label=="toe"{"GriffinRampToeSectionRequirements::RampToeSection"}
    else{throw("Unknown ramp component identity");}
}
fn bank_names(model){
    let result=[];for item in model.value(owner()+"banks"){
        if !sysml_enum_is(item){throw("Packaging bank identity must be a typed enum");}
        result.push(item.literal);
    }
    if result.len()!=2{throw("Both packaging bank identities are required");}result
}
fn child_pose(model,docs,parent,child,angle){
    let parent_owner=component_owner(parent);let child_owner=component_owner(child);
    let a=frames::mount_local_transform(docs[parent],"/RampSection/"+section::frame_name(model,parent_owner,"exitFrameName"));
    let b=frames::mount_local_transform(docs[child],"/RampSection/"+section::frame_name(model,child_owner,"entryFrameName"));
    if !a.ok || !b.ok{throw("Named source attachment frames are unavailable");}
    let rotate=#{translation:[0.0,0.0,0.0],rotation:quat_array(quat_from_euler_xyz_deg(vec3(0.0,0.0,angle*180.0/acos(-1.0))))};
    frames::mount_transform_compose(frames::mount_transform_compose(a.value,rotate),frames::mount_transform_inverse(b.value))
}
// Solve the raised bearing from the nominal walking corner. Source datums
// stay in SysML; native rigid-frame math owns their geometric composition.
fn bank_placements(model,docs,index){
    if index!=0 && index!=1{throw("Unknown bank side");}
    let own=owner();let ramp="GriffinRampRequirements::GriffinEgressRamp::";
    let entry=frames::mount_local_transform(docs.root,"/RampSection/"+
        section::frame_name(model,component_owner("root"),"entryFrameName"));
    if !entry.ok{throw("Source root entry datum is unavailable");}
    let angle=model.value(ramp+"physicalRampPortDeploymentAngleRad");let sign=if index==0{1.0}else{-1.0};
    let nominal=quat_from_euler_xyz_deg(vec3(0.0,if index==0{0.0}else{180.0},sign*angle*180.0/acos(-1.0)));
    let top=model.value(ramp+"rampSurfaceCenterYM")+spec::ramp_surface_thickness_m()/2.0;
    let target=vec3(sign*(model.value(own+"transitionOutboardX")+model.value(own+"hingeRunningClearanceM")),
        model.value(ramp+"physicalRampDeckTransitionCenterY")+spec::ramp_surface_thickness_m()/2.0,
        model.value(own+"mountZ"));
    let position=target-qrot(nominal,vec3(0.0,top,0.0)-vec3_from(entry.value.translation));
    let deck=frames::mount_transform_inverse(entry.value);
    let folded=model.value(ramp+"physicalRampSectionStowedRelativeAngleRad");
    let stow=model.value(ramp+"physicalRampRootStowedAngleRad");
    let stow_rotation=quat_array(quat_from_euler_xyz_deg(vec3(0.0,if index==0{0.0}else{180.0},sign*stow*180.0/acos(-1.0))));
    #{position:vec3_array(position),rotation:stow_rotation,deck:deck,
        middle:frames::mount_transform_compose(deck,child_pose(model,docs,"root","middle",folded)),
        toe:child_pose(model,docs,"middle","toe",-folded)}
}
fn bank_plan(doc,edit_target,docs,index){
    if index!=0 && index!=1{throw("Packaging bank index must select port or starboard");}
    let model=requirements::model();let own=owner();let lander=model.value(own+"landerPath");
    let names=bank_names(model);let name=names[index];let root=lander+"/"+name;
    let actual=lander+"/"+spec::ramp_names()[index];let old=frames::mount_local_transform(doc,actual);
    if !old.ok{throw("Installed bank frame is unavailable");}
    let placement=bank_placements(model,docs,index);let position=placement.position;
    let contract=query("ReadActiveTwinContract");if contract.open!=true{throw("Active Twin contract is unavailable");}
    let ops=[];
    let found=query("QueryUsdPrim",#{doc_id:doc,path:root});if found.type_name!=(){throw("Packaging bank already exists; revise its explicit placement instead");}
    ops.push(#{SetActive:#{edit_target:edit_target,path:actual,active:false}});
    ops.push(#{AddPrim:#{edit_target:edit_target,parent_path:lander,name:name,type_name:"Xform",reference:(),reference_prim_path:""}});
    let pose=frames::place_plan(edit_target,root,position,frames::mount_xyz_deg_from_quat(placement.rotation),());
    if !pose.ok{return pose;}for op in pose.ops{ops.push(op);}
    for member in [#{label:"root",parent:root,name:"DeckSection",pose:placement.deck},
        #{label:"middle",parent:root,name:"MiddleSection",pose:placement.middle},
        #{label:"toe",parent:root+"/MiddleSection",name:"ToeSection",pose:placement.toe}]{
        let asset=model.value(component_owner(member.label)+"::componentAsset");
        ops.push(#{AddPrim:#{edit_target:edit_target,parent_path:member.parent,name:member.name,type_name:"Xform",
            reference:"twin://"+contract.name+"/"+asset,reference_prim_path:"/RampSection"}});
        let placement=frames::place_plan(edit_target,member.parent+"/"+member.name,
            member.pose.translation,frames::mount_xyz_deg_from_quat(member.pose.rotation),());
        if !placement.ok{return placement;}for op in placement.ops{ops.push(op);}
    }
    let side=if index==0{"port"}else{"starboard"};
    let mount=visual::_griffin_ramp_mount_at_plan(doc,edit_target,lander,side,position,root+"/DeckSection/Looks/RampStructure");
    if !mount.ok{return mount;}for op in mount.ops{ops.push(op);}
    for station in 0..2{let bearing=bearing_station_plan(doc,edit_target,docs,index,station);if !bearing.ok{return bearing;}for op in bearing.ops{ops.push(op);}}
    #{ok:true,ops:ops,root:root,doc_id:doc,generation:query("QueryUsdPrim",#{doc_id:doc,path:lander}).document_generation,
        source_revision:model.source_revision,kind:"griffin_candidate_ramp_bank"}
}

fn interface_plan(doc,edit_target,docs,index){
    let model=requirements::model();let lander=model.value(owner()+"landerPath");
    let root=lander+"/"+bank_names(model)[index];let placement=bank_placements(model,docs,index);let ops=[];
    for member in [#{path:root,pose:#{translation:placement.position,rotation:placement.rotation}},
        #{path:root+"/DeckSection",pose:placement.deck},#{path:root+"/MiddleSection",pose:placement.middle},
        #{path:root+"/MiddleSection/ToeSection",pose:placement.toe}]{
        let present=query("QueryUsdPrim",#{doc_id:doc,path:member.path});
        if present.type_name!="Xform"{throw("Existing bank component is unavailable: "+member.path);}
        let plan=frames::place_plan(edit_target,member.path,member.pose.translation,
            if member.pose.rotation==(){()}else{frames::mount_xyz_deg_from_quat(member.pose.rotation)},());
        if !plan.ok{return plan;}for op in plan.ops{ops.push(op);}
    }
    let support=visual::_griffin_ramp_mount_at_plan(doc,edit_target,lander,if index==0{"port"}else{"starboard"},
        placement.position,root+"/DeckSection/Looks/RampStructure");
    if !support.ok{return support;}for op in support.ops{ops.push(op);}
    for station in 0..2{let bearing=bearing_station_plan(doc,edit_target,docs,index,station);if !bearing.ok{return bearing;}for op in bearing.ops{ops.push(op);}}
    #{ok:true,ops:ops,doc_id:doc,generation:query("QueryUsdPrim",#{doc_id:doc,path:root}).document_generation,
        source_revision:model.source_revision,position:placement.position,kind:"griffin_raised_root_interface"}
}

// Finish only the static study fixture. The production vehicle keeps its own
// joint, latch, mass and contact acceptance until the mechanism is promoted.
fn fixture_plan(doc,edit_target){
    let model=requirements::model();let own=owner();let lander=model.value(own+"landerPath");
    let scene=model.value(own+"usdRootPath");let ramp="GriffinRampRequirements::GriffinEgressRamp::";
    let ops=[];
    for binding in spec::ramp_flight_latch_bindings(){
        for name in [binding.hinge,binding.latch]{
            ops.push(#{SetActive:#{edit_target:edit_target,path:lander+"/"+name,active:false}});
        }
    }
    let bus=lander+"/Bus";
    let sockets=query("QueryUsdPrim",#{doc_id:doc,path:bus,relationships:true});let retained=[];
    for socket in sockets.relationships["lunco:mount:sockets"]{
        let found=query("QueryUsdPrim",#{doc_id:doc,path:socket,relationships:true});
        let retired=false;
        for name in spec::ramp_names(){if found.relationships["lunco:mount:part"].contains(lander+"/"+name){retired=true;}}
        if retired{ops.push(#{SetActive:#{edit_target:edit_target,path:socket,active:false}});}else{retained.push(socket);}
    }
    ops.push(#{SetRelationship:#{edit_target:edit_target,path:bus,name:"lunco:mount:sockets",targets:retained}});
    let length=model.value(own+"transitionLengthM");let edge=model.value(own+"transitionOutboardX");
    let y=model.value(ramp+"physicalRampDeckTransitionCenterY");let z=model.value(ramp+"physicalRampMountZ");
    let width=model.value(own+"transitionTrackWidthM");let thickness=spec::ramp_surface_thickness_m();
    if length<=0.0 || width<=0.0 || thickness<=0.0 || edge<=length{throw("Transition source dimensions are invalid");}
    for index in 0..2{
        let side=if index==0{"port"}else{"starboard"};let sign=if index==0{1.0}else{-1.0};
        let root=lander+"/"+spec::physical_ramp_transition_body_name(side);
        let pose=frames::place_plan(edit_target,root,[sign*(edge-length/2.0),y,z],(),());
        if !pose.ok{return pose;}for op in pose.ops{ops.push(op);}
        ops.push(#{SetActive:#{edit_target:edit_target,path:root+"/"+spec::physical_ramp_transition_contact_child_name(),active:false}});
        ops.push(#{SetActive:#{edit_target:edit_target,path:lander+"/"+spec::physical_ramp_transition_joint_name(side),active:false}});
        for track in [#{name:"RampTrackPort",station:abs(spec::rover_wheel_station_z()[0])},
            #{name:"RampTrackStarboard",station:-abs(spec::rover_wheel_station_z()[0])}]{
            let shape=visual::_component_cube_visual_ops(doc,edit_target,root,track.name,
                [0.0,0.0,track.station],(),[length,thickness,width],
                model.value(ramp+"rampTrackDisplayColor"));
            if !shape.ok{return shape;}for op in shape.ops{ops.push(op);}
            let path=root+"/"+track.name;
            ops.push(#{SetAttribute:#{edit_target:edit_target,path:path,name:"purpose",type_name:"token",value:"\"default\""}});
            ops.push(#{SetAttribute:#{edit_target:edit_target,path:path,name:"physics:collisionEnabled",type_name:"bool",value:"true"}});
            ops.push(#{SetApiSchemas:#{edit_target:edit_target,path:path,schemas:["PhysicsCollisionAPI","MaterialBindingAPI"]}});
            ops.push(#{SetRelationship:#{edit_target:edit_target,path:path,name:"material:binding",
                targets:[lander+"/"+bank_names(model)[index]+"/DeckSection/Looks/RampWalkingPlate"]}});
        }
    }
    // This is a static review asset. Never run the old installed-bank observer
    // against a fixture whose production banks are intentionally inactive.
    ops.push(#{SetActive:#{edit_target:edit_target,path:scene+"/Scenario/Mission",active:false}});
    #{ok:true,ops:ops,doc_id:doc,generation:query("QueryUsdPrim",#{doc_id:doc,path:scene}).document_generation,
        source_revision:model.source_revision,kind:"griffin_static_packaging_interfaces"}
}

// One inboard housing and stem per inner rail, clear of the rotating tongue
// and walking track. The pin and centre shaft rotate inside its open bore.
fn bearing_station_plan(doc,edit_target,docs,bank,station){
    if (bank!=0 && bank!=1) || (station!=0 && station!=1){throw("Select one root bearing station");}
    let model=requirements::model();let own="GriffinRampRootBearingRequirements::RampRootBearing::";
    let ramp="GriffinRampRequirements::GriffinEgressRamp::";let lander=model.value(owner()+"landerPath");
    let placement=bank_placements(model,docs,bank);let point=vec3_from(placement.position);
    let width=model.value(ramp+"rampPivotLugWidthM");let depth=model.value(own+"axialLengthM");
    let inside=model.value(own+"innerRadiusM");let outside=model.value(own+"outerRadiusM");
    let offset=model.value(own+"inboardOffsetM");let sign=if station==0{-1.0}else{1.0};
    let z=point.z+sign*(model.value(ramp+"rampCenterRailOffsetZM")-offset);
    let bottom=spec::component_bus_mount_y()+spec::visual_deck_center_y_m()+spec::visual_deck_thickness_m()/2.0;
    let top=point.y-(inside+outside)/2.0;if top<=bottom || depth<=0.0{throw("Bearing stem has no positive stock");}
    let name="RampMount"+if bank==0{"Port"}else{"Starboard"}+if station==0{"InnerRear"}else{"InnerFront"};
    let material=lander+"/"+bank_names(model)[bank]+"/DeckSection/Looks/RampStructure";
    let stem=visual::_component_cube_visual_ops(doc,edit_target,lander,name,[point.x,(bottom+top)/2.0,z],(),[width,top-bottom,depth],spec::visual_deck_display_color());
    if !stem.ok{return stem;}let ops=stem.ops;
    ops.push(#{SetApiSchemas:#{edit_target:edit_target,path:lander+"/"+name,schemas:["PhysicsCollisionAPI","MaterialBindingAPI"]}});
    ops.push(#{SetRelationship:#{edit_target:edit_target,path:lander+"/"+name,name:"material:binding",targets:[material]}});
    let path=lander+"/"+name+"Bearing";let present=query("QueryUsdPrim",#{doc_id:doc,path:path});
    if present.type_name==(){ops.push(#{AddPrim:#{edit_target:edit_target,parent_path:lander,name:name+"Bearing",type_name:"Xform",reference:(),reference_prim_path:""}});}
    else if present.type_name!="Xform"{throw("Bearing instance has the wrong standard type");}
    // This fixture lives one level below the Twin root; author a portable
    // USD-relative reference, independent of the live mount authority.
    if model.value(owner()+"fixtureAsset").split("/").len()!=2{throw("Packaging fixture reference base changed");}
    ops.push(#{SetReferenceArcs:#{edit_target:edit_target,path:path,list_op:"Explicit",references:[#{asset_path:"../"+model.value(own+"componentAsset"),prim_path:"/RootBearing"}]}});
    let pose=frames::place_plan(edit_target,path,[point.x,point.y,z],[0.0,0.0,0.0],[1.0,1.0,1.0]);
    if !pose.ok{return pose;}for op in pose.ops{ops.push(op);}
    #{ok:true,ops:ops,doc_id:doc,generation:query("QueryUsdPrim",#{doc_id:doc,path:lander}).document_generation,source_revision:model.source_revision,
        housing:path,stem:lander+"/"+name,position:[point.x,point.y,z],kind:"griffin_root_bearing_station"}
}
