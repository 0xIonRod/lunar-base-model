// Native authoring owner for four independent three-span wheel tracks.
// Qualified stock is composed through six small track adapters. No mesh copies.
// Mounts/drive laws remain reconstruction estimates, not flight actuator data.
import "griffin_ramp_mechanism" as mechanism;
import "griffin_ramp_packaging" as packaging;
import "griffin_spec" as spec;
import "lunco://scripting/tools/sysml_requirements" as requirements;
fn own(){"GriffinRampRequirements::GriffinEgressRamp::"}
fn body_plan(doc,root,docs,index){
    let model=requirements::model();let track=spec::ramp_track_bindings()[index];
    let p=packaging::bank_placements(model,docs,track.bank);let bank=root+"/"+track.body;
    let ops=[];let before=query("QueryUsdPrim",#{doc_id:doc,path:root,attrs:[]});
    let found=query("QueryUsdPrim",#{doc_id:doc,path:bank,attrs:[]});
    if found.type_name!=(){ops.push(#{RemovePrim:#{edit_target:"@root@",path:bank}});}
    ops.push(mechanism::add(root,track.body,()));
    for op in mechanism::pose_ops(bank,#{translation:p.position,rotation:p.rotation}){ops.push(op);}
    let deck=p.deck;deck.translation[2]+=track.station;
    let middle=p.middle;middle.translation[2]+=track.station;
    let thickness=model.value(own()+"rampSurfaceThicknessM");let width=model.value(own()+"physicalTrackEnvelopeWidthM");
    let mass=model.value(own()+"physicalTrackSectionMassKg");
    for section in [#{label:"root",parent:bank,name:"DeckSection",pose:deck},
        #{label:"middle",parent:bank,name:"MiddleSection",pose:middle},
        #{label:"toe",parent:bank+"/MiddleSection",name:"ToeSection",pose:p.toe}]{
        let path=section.parent+"/"+section.name;
        let assets=model.value(own()+if track.track==0{"portTrackAssets"}else{"starboardTrackAssets"});
        let slot=if section.label=="root"{0}else if section.label=="middle"{1}else{2};
        let asset="twin://"+twin_name()+"/"+assets[slot];
        ops.push(mechanism::add(section.parent,section.name,asset));
        for op in mechanism::pose_ops(path,section.pose){ops.push(op);}
        let body=if section.label=="root"{bank}else{path};
        let schemas=["PhysicsRigidBodyAPI","PhysxRigidBodyAPI","PhysicsMassAPI"];
        if section.label=="root"{schemas.push("PhysicsFilteredPairsAPI");}
        ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:body,schemas:schemas}});
        let length=model.value(packaging::component_owner(section.label)+"::lengthM");
        let centre=[length/2.0,model.value(own()+"rampSurfaceCenterYM"),0.0];
        if section.label=="root"{centre[1]+=deck.translation[1];centre[2]=track.station;}
        ops.push(mechanism::scalar(body,"physics:mass","float",mass));
        ops.push(mechanism::vector(body,"physics:centerOfMass","point3f",centre));
        ops.push(mechanism::vector(body,"physics:diagonalInertia","float3",[mass*(width*width+thickness*thickness)/12.0,
            mass*(length*length+width*width)/12.0,mass*(length*length+thickness*thickness)/12.0]));
        ops.push(mechanism::vector(body,"physics:principalAxes","quatf",[1.0,0.0,0.0,0.0]));
    }
    ops.push(#{SetRelationship:#{edit_target:"@root@",path:bank,name:"physics:filteredPairs",targets:[root+"/"+spec::physical_ramp_transition_body_name(if track.bank==0{"port"}else{"starboard"})]}});
    for op in attachment_ops(root,track,model){ops.push(op);}
    #{ok:true,doc_id:doc,generation:before.document_generation,ops:ops,track:track}
}
fn copy_joint(doc,root,from_name,to_name){
    let source=query("QueryUsdPrim",#{doc_id:doc,path:root+"/"+from_name,schemas:true,rels:["physics:body0","physics:body1"]});
    if source.type_name==(){throw("Existing joint template required");}
    let ops=[];let path=root+"/"+to_name;
    if query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]}).type_name!=(){ops.push(#{RemovePrim:#{edit_target:"@root@",path:path}});}
    ops.push(#{AddPrim:#{edit_target:"@root@",parent_path:root,name:to_name,type_name:source.type_name,reference:(),reference_prim_path:()}});
    ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:path,schemas:source.api_schemas}});
    for key in source.attrs.keys(){ops.push(#{CopyProperty:#{edit_target:"@root@",from_path:root+"/"+from_name+"."+key,to_path:path+"."+key}});}
    ops
}
fn interface_plan(doc,root,docs,index,stage){
    let model=requirements::model();let track=spec::ramp_track_bindings()[index];let primary=spec::ramp_track_bindings()[track.bank*2];
    let p=packaging::bank_placements(model,docs,track.bank);let bodies=[root,root+"/"+track.body,root+"/"+track.body+"/MiddleSection",root+"/"+track.body+"/MiddleSection/ToeSection"];
    let names=[track.root,track.middle,track.toe];let template=[primary.root,primary.middle,primary.toe][stage];
    let latch="";let source_latch="";
    for binding in spec::ramp_flight_latch_bindings(){if binding.hinge==names[stage]{latch=binding.latch;}if binding.hinge==template{source_latch=binding.latch;}}
    if latch=="" || source_latch==""{throw("Source latch pairing required");}
    let ops=[];let gen=query("QueryUsdPrim",#{doc_id:doc,path:root,attrs:[]}).document_generation;
    if track.track==1{for pair in [[template,names[stage]],[source_latch,latch]]{for op in copy_joint(doc,root,pair[0],pair[1]){ops.push(op);}}}
    let parent=[];let child=[];let physical=();
    if stage==0{parent=vec3_array(vec3_from(p.position)+qrot(quat_from(p.rotation),vec3(0.0,0.0,track.station)));child=[0.0,0.0,track.station];physical=p.rotation;}
    else{let labels=["root","middle","toe"];
        parent=mechanism::datum(model,docs,labels[stage-1],"exitFrameName").translation;
        child=mechanism::datum(model,docs,labels[stage],"entryFrameName").translation;
        if stage==1{parent=vec3_array(vec3_from(parent)+vec3_from(p.deck.translation)+vec3(0.0,0.0,track.station));}
        physical=if stage==1{p.middle.rotation}else{p.toe.rotation};
    }
    for name in [names[stage],latch]{let path=root+"/"+name;
        ops.push(#{SetRelationship:#{edit_target:"@root@",path:path,name:"physics:body0",targets:[bodies[stage]]}});
        ops.push(#{SetRelationship:#{edit_target:"@root@",path:path,name:"physics:body1",targets:[bodies[stage+1]]}});
        ops.push(mechanism::vector(path,"physics:localPos0","point3f",parent));ops.push(mechanism::vector(path,"physics:localPos1","point3f",child));
    }
    let hinge=root+"/"+names[stage];let fixed=root+"/"+latch;
    ops.push(mechanism::vector(fixed,"physics:localRot0","quatf",[1.0,0.0,0.0,0.0]));
    ops.push(mechanism::vector(fixed,"physics:localRot1","quatf",mechanism::usd_quat(quat_inverse(quat_from(physical)))));
    let count=model.value(own()+"physicalTrackCountPerBank");
    ops.push(mechanism::scalar(hinge,"drive:angular:physics:stiffness","float",model.value(own()+"physicalRampJointDriveStiffnessNmPerDeg")/count));
    ops.push(mechanism::scalar(hinge,"drive:angular:physics:damping","float",model.value(own()+if stage==0{"physicalRampRootJointDriveDampingNmPerDegPerSec"}else{"physicalRampSectionJointDriveDampingNmPerDegPerSec"})/count));
    ops.push(mechanism::scalar(hinge,"drive:angular:physics:maxForce","float",model.value(own()+"physicalRampJointDriveMaxTorqueNm")/count));
    #{ok:true,doc_id:doc,generation:gen,ops:ops,track:track,stage:stage}
}

// Shared shaft datum, separate from each track's local contact/COM station.
fn attachment_ops(root,track,model){
    let path=root+"/"+track.body;let frame=path+"/MountFrame";
    let ops=[mechanism::add(path,"MountFrame",())];
    for op in mechanism::pose_ops(frame,#{translation:[0.0,0.0,0.0],rotation:quat_array(quat_identity())}){ops.push(op);}
    ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:path,schemas:["PhysicsRigidBodyAPI","PhysxRigidBodyAPI","PhysicsMassAPI","PhysicsFilteredPairsAPI","LunCoMountPlugAPI"]}});
    ops.push(#{SetRelationship:#{edit_target:"@root@",path:path,name:"lunco:mount:frame",targets:[frame]}});
    ops.push(#{SetAttribute:#{edit_target:"@root@",path:path,name:"lunco:mount:plug",type_name:"token",value:"\"egress_ramp\""}});
    ops.push(mechanism::scalar(path,"lunco:operational_width_m","double",model.value(own()+"physicalTrackEnvelopeWidthM")));
    ops.push(mechanism::scalar(path,"lunco:wheel_clearance_m","double",model.value(own()+"rampWheelClearanceM")));
    ops.push(mechanism::scalar(path,"lunco:track_station_z_m","double",track.station));ops
}
fn attachment_plan(doc,root,index){
    let track=spec::ramp_track_bindings()[index];let path=root+"/"+track.body;
    let r=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]});let ops=[];
    if query("QueryUsdPrim",#{doc_id:doc,path:path+"/MountFrame",attrs:[]}).type_name!=(){ops.push(#{RemovePrim:#{edit_target:"@root@",path:path+"/MountFrame"}});}
    for op in attachment_ops(root,track,requirements::model()){ops.push(op);}
    #{ok:true,ops:ops,doc_id:doc,generation:r.document_generation}
}
// Build adapters from native source topology, preserving mesh/material owners.
fn adapter_plan(doc,source_doc,label,track_index){
    let model=requirements::model();let side=if track_index==0{1.0}else if track_index==1{-1.0}else{throw("Track index required");};
    let station=abs(spec::rover_wheel_station_z()[0])*side;
    let source=query("QueryUsdPrim",#{doc_id:source_doc,path:"/RampSection",attrs:[],children:true});
    let current=query("QueryUsdPrim",#{doc_id:doc,path:"/RampSection",attrs:[]});
    let ops=[#{RemovePrim:#{edit_target:"@root@",path:"/RampSection"}},mechanism::add("/","RampSection","twin://"+twin_name()+"/"+model.value(packaging::component_owner(label)+"::componentAsset"))];
    for path in source.children{
        let r=query("QueryUsdPrim",#{doc_id:source_doc,path:path,attrs:["xformOp:translate","xformOpOrder"],geometry_bounds:true});
        if r.geometry_bounds==(){continue;}
        if r.geometry_bounds.center[2]*side<=0.0 || path.ends_with("/HingeBarrel"){
            ops.push(#{SetActive:#{edit_target:"@root@",path:path,active:false}});continue;
        }
        let t=r.attrs["xformOp:translate"];if t==(){t=[0.0,0.0,0.0];}t[2]-=station;
        let order=["xformOp:translate"];if r.attrs.xformOpOrder!=(){for op in r.attrs.xformOpOrder{
            if op=="!resetXformStack!"{throw("Track adapter requires source-relative stock frames");}if op!="xformOp:translate"{order.push(op);}
        }}
        ops.push(#{SetTranslate:#{edit_target:"@root@",path:path,value:t}});
        let text="[";for i in 0..order.len(){if i>0{text+=", ";}text+="\""+order[i]+"\"";}text+="]";
        ops.push(#{SetAttribute:#{edit_target:"@root@",path:path,name:"xformOpOrder",type_name:"token[]",value:text}});
    }
    #{ok:true,doc_id:doc,generation:current.document_generation,ops:ops}
}
