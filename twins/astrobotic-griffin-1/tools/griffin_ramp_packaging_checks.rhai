// Read-only reconstruction study. Native f64 bounds are conservative solid
// envelopes; a failed envelope test is not proof of solid intersection.
import "griffin_ramp_packaging" as packaging;
import "griffin_ramp_section_component" as component;
import "lunco://scripting/tools/assembly_builder" as frames;
import "lunco://scripting/tools/sysml_requirements" as requirements;
import "usd_geometry_inspection" as inspection;

fn labels(){["root","middle","toe"]}
fn native_pose(p){transform(vec3_from(p.translation),quat_from(p.rotation),vec3(1.0,1.0,1.0))}
fn rotation(angle){#{translation:[0.0,0.0,0.0],rotation:quat_array(quat_from_euler_xyz_deg(vec3(0.0,0.0,angle*180.0/acos(-1.0))))}}
fn joined(parent,a,b,angle){
    frames::mount_transform_compose(parent,frames::mount_transform_compose(
        frames::mount_transform_compose(a,rotation(angle)),frames::mount_transform_inverse(b)))
}
fn datum(doc,name){
    let found=frames::mount_local_transform(doc,"/RampSection/"+name);
    if !found.ok{throw("Named source ramp datum is unavailable");}found.value
}
fn component_datum(model,docs,label,feature){
    datum(docs[label],component::frame_name(model,packaging::component_owner(label),feature))
}
fn corners(b){
    let result=[];
    for x in [b.min.x,b.max.x]{for y in [b.min.y,b.max.y]{for z in [b.min.z,b.max.z]{result.push(vec3(x,y,z));}}}
    result
}
fn source_section(doc){
    let parent=query("QueryUsdPrim",#{doc_id:doc,path:"/RampSection",children:true});
    if parent.type_name!="Xform" || parent.children.len()==0{throw("Source section geometry is unavailable");}
    let found=query("QueryUsdPrims",#{doc_id:doc,paths:parent.children,geometry_bounds:true});
    if !inspection::same_snapshot(found.records){throw("Source section snapshot is incoherent");}
    let parts=[];let lo=();let hi=();
    for record in found.records{
        let b=record.geometry_bounds;
        if b==(){
            if record.type_name!="Xform" && record.type_name!="Scope"{throw("Source section has unmeasured geometry");}
            continue;
        }
        if b.frame!="canonical_stage"{throw("Source section bounds are in the wrong frame");}
        let bounds=bounds3(vec3_from(b.min),vec3_from(b.max));
        parts.push(#{path:record.path,bounds:bounds});
        if lo==(){lo=bounds.min;hi=bounds.max;}else{
            lo=vec3(min(lo.x,bounds.min.x),min(lo.y,bounds.min.y),min(lo.z,bounds.min.z));
            hi=vec3(max(hi.x,bounds.max.x),max(hi.y,bounds.max.y),max(hi.z,bounds.max.z));
        }
    }
    if parts.len()==0{throw("Source section has no measured stock");}
    #{parts:parts,envelope:bounds3(lo,hi),fence:found.records[0]}
}
fn begin(doc,docs){
    let model=requirements::model();let own=packaging::owner();let ramp="GriffinRampRequirements::GriffinEgressRamp::";
    let scene=model.value(own+"usdRootPath");let rover=model.value(own+"roverPath");
    let lander=model.value(own+"landerPath");
    let pose=frames::mount_local_transform(doc,scene);
    let parent=frames::mount_frame_in_body(doc,scene,lander);
    if !pose.ok || !parent.ok{throw("Packaging fixture frame is unavailable");}
    let world=frames::mount_transform_compose(pose.value,parent.value);
    let topology=query("QueryUsdPrim",#{doc_id:doc,path:rover,topology:true});
    let targets=[];
    for part in topology.topology.parts{if part.path.starts_with(rover+"/"){targets.push(part.path);}}
    if targets.len()==0{throw("Payload geometry is unavailable");}
    let measured=query("QueryUsdPrims",#{doc_id:doc,paths:targets,geometry_bounds:true});
    if !inspection::same_snapshot(measured.records){throw("Payload snapshot is incoherent");}
    let boxes=[];
    for record in measured.records{
        let b=record.geometry_bounds;
        if b==() || b.frame!="canonical_stage"{throw("Every payload part needs native geometry bounds");}
        boxes.push(#{path:record.path,box:oriented_bounds3(vec3_from(b.center),vec3_from(b.half_extents),quat_identity())});
    }
    let banks=[];
    for name in packaging::bank_names(model){
        let found=frames::mount_local_transform(doc,lander+"/"+name);
        if !found.ok{throw("Candidate bank frame is unavailable");}
        banks.push(found.value);
    }
    let upper=model.value(ramp+"physicalRampRootStowedAngleRad");
    let upright=model.value(own+"rootClearanceAngleRad");
    let folded=model.value(ramp+"physicalRampSectionStowedRelativeAngleRad");
    let nominal=model.value(ramp+"physicalRampPortDeploymentAngleRad");
    let phases=[#{name:"root-clear",from:upper,to:upright,step:model.value(own+"rootClearanceStepRad"),moving:0},
        #{name:"middle",from:folded,to:0.0,step:model.value(own+"sectionStepRad"),moving:1},
        #{name:"toe",from:-folded,to:0.0,step:model.value(own+"sectionStepRad"),moving:2},
        #{name:"root-lower",from:upright,to:nominal,step:model.value(own+"sectionStepRad"),moving:0}];
    for i in 0..phases.len(){
        if phases[i].step<=0.0 || phases[i].step>acos(-1.0){throw("Invalid source sampling step");}
        let intervals=abs(phases[i].to-phases[i].from)/phases[i].step;
        phases[i].intervals=intervals.to_int();
        if phases[i].intervals.to_float()<intervals{phases[i].intervals+=1;}
        if phases[i].intervals<1{throw("Deployment phase has no angular coverage");}
        phases[i].delta=(phases[i].to-phases[i].from)/phases[i].intervals;
    }
    #{doc:doc,source_revision:model.source_revision,scene:scene,world:world,banks:banks,targets:boxes,
        docs:docs,sections:[],fence:measured.records[0],phases:phases,
        upper:upper,upright:upright,folded:folded,required:model.value(own+"payloadClearanceM"),
        root_exit:component_datum(model,docs,"root","exitFrameName"),middle_entry:component_datum(model,docs,"middle","entryFrameName"),
        middle_exit:component_datum(model,docs,"middle","exitFrameName"),toe_entry:component_datum(model,docs,"toe","entryFrameName")}
}
// Load one component per bounded Editor call or test callback.
fn add_section(state,index){
    if index!=state.sections.len() || index>=labels().len(){throw("Section capture must be complete and ordered");}
    state.sections.push(source_section(state.docs[labels()[index]]));state
}
fn assert_current(state){
    if requirements::model().source_revision!=state.source_revision{throw("Packaging source revision changed");}
    let records=[query("QueryUsdPrim",#{doc_id:state.doc,path:state.scene})];
    let expected=[state.fence];
    for i in 0..state.sections.len(){
        records.push(query("QueryUsdPrim",#{doc_id:state.docs[labels()[i]],path:"/RampSection"}));
        expected.push(state.sections[i].fence);
    }
    for i in 0..records.len(){
        let a=records[i];let b=expected[i];
        if a.doc_id!=b.doc_id || a.document_generation!=b.document_generation || a.stage_generation!=b.stage_generation{
            throw("Packaging document or stage changed during observation");
        }
    }
}
// Check every installed member's complete geometry attributes, including its
// local transform, against the measured component. Native reference provenance
// is checked separately: the full lander topology exceeds the one-shot query
// string limit, so it must not silently disappear from a claimed GVA verdict.
fn verify_installation(state,bank,section_index){
    assert_current(state);
    let model=requirements::model();let label=labels()[section_index];
    let root=model.value(packaging::owner()+"landerPath")+"/"+packaging::bank_names(model)[bank];
    let member=root+if section_index==0{"/DeckSection"}else if section_index==1{"/MiddleSection"}else{"/MiddleSection/ToeSection"};
    let source_paths=[];let target_paths=[];
    for part in state.sections[section_index].parts{
        source_paths.push(part.path);target_paths.push(member+part.path.sub_string("/RampSection".len()));
    }
    let source=query("QueryUsdPrims",#{doc_id:state.docs[label],paths:source_paths});
    let installed=query("QueryUsdPrims",#{doc_id:state.doc,paths:target_paths});
    if !inspection::same_snapshot(source.records) || !inspection::same_snapshot(installed.records){throw("Reference check snapshot changed");}
    if source.records.len()!=target_paths.len() || installed.records.len()!=target_paths.len(){throw("Reference members are missing");}
    for i in 0..source.records.len(){
        let a=source.records[i];let b=installed.records[i];
        if a.type_name!=b.type_name || a.attrs!=b.attrs{throw("Installed member differs from its measured component: "+b.path);}
    }
    let children=query("QueryUsdPrim",#{doc_id:state.doc,path:member,children:true});
    let source_children=query("QueryUsdPrim",#{doc_id:state.docs[label],path:"/RampSection",children:true});
    let expected_children=[];
    for path in source_children.children{expected_children.push(member+path.sub_string("/RampSection".len()));}
    if section_index==1{expected_children.push(member+"/ToeSection");}
    if children.children.len()!=expected_children.len(){throw("Installed component has unexpected children");}
    for path in expected_children{if !children.children.contains(path){throw("Installed component child is missing: "+path);}}
    // Attachment poses must be the source-owned named-datum composition.
    let expected=if section_index==0{frames::mount_transform_identity()}
        else{packaging::child_pose(model,state.docs,if section_index==1{"root"}else{"middle"},label,
            if section_index==1{state.folded}else{-state.folded})};
    let actual=frames::mount_local_transform(state.doc,member);
    if !actual.ok{throw("Installed section frame is unavailable");}
    let residual=0.0;
    for corner in corners(state.sections[section_index].envelope){
        residual=max(residual,vlen(transform_apply_point(native_pose(expected),corner)-transform_apply_point(native_pose(actual.value),corner)));
    }
    assert_current(state);
    #{bank:bank,section:label,part_count:source_paths.len(),maximum_placement_residual_m:residual,
        doc_id:state.doc,document_generation:state.fence.document_generation,stage_generation:state.fence.stage_generation,
        source_revision:state.source_revision}
}
fn sample(state,bank,phase_index,index,section_index){
    if state.sections.len()!=3 || bank<0 || bank>=state.banks.len(){throw("Both banks and all source sections are required");}
    let phase=state.phases[phase_index];
    if index<0 || index>phase.intervals || section_index<0 || section_index>=3{throw("Invalid path sample");}
    let angle=phase.from+phase.delta*index;
    let root_angle=if phase_index==0 || phase_index==3{angle}else{state.upright};
    let middle_angle=if phase_index==0{state.folded}else if phase_index==1{angle}else{0.0};
    let toe_angle=if phase_index<2{-state.folded}else if phase_index==2{angle}else{0.0};
    let local=state.banks[bank];local.rotation=quat_array(quat_from(local.rotation)*quat_from(rotation(root_angle-state.upper).rotation));
    let root=frames::mount_transform_compose(state.world,local);
    let middle=joined(root,state.root_exit,state.middle_entry,middle_angle);
    let toe=joined(middle,state.middle_exit,state.toe_entry,toe_angle);
    let poses=[root,middle,toe];let pose=native_pose(poses[section_index]);
    let pivot=if phase.moving==0{root}else if phase.moving==1{
        frames::mount_transform_compose(root,state.root_exit)
    }else{frames::mount_transform_compose(middle,state.middle_exit)};
    let pivot_inverse=quat_inverse(quat_from(pivot.rotation));
    let section=state.sections[section_index];let displacement=0.0;
    // Each phase has one fixed axis. Native quaternion rotation gives the
    // maximum corner displacement to its nearest sample, half an interval.
    // Corner maxima bound the entire convex box and every enclosed member.
    if section_index>=phase.moving{
        let half=quat_from(rotation(abs(phase.delta)*0.5).rotation);
        for corner in corners(section.envelope){
            let offset=qrot(pivot_inverse,transform_apply_point(pose,corner)-vec3_from(pivot.translation));
            displacement=max(displacement,vlen(qrot(half,offset)-offset));
        }
    }
    let envelope=oriented_bounds_from_local(section.envelope,pose);let minimum=();let witness=();let refinements=0;
    for target in state.targets{
        let gap=bounds_relation(envelope,target.box).greatest_axis_margin-displacement;
        if gap<state.required{
            // A filled section envelope may cross an empty lattice opening.
            // Resolve only this uncertain target against every real member.
            for part in section.parts{
                let refined=bounds_relation(oriented_bounds_from_local(part.bounds,pose),target.box).greatest_axis_margin-displacement;
                refinements+=1;
                if minimum==() || refined<minimum{minimum=refined;witness=#{ramp:part.path,payload:target.path};}
            }
        }else if minimum==() || gap<minimum{minimum=gap;witness=#{ramp:"section-envelope",payload:target.path};}
    }
    if minimum==() || !minimum.is_finite(){throw("No finite payload clearance observation");}
    #{source_revision:state.source_revision,bank:bank,phase:phase.name,index:index,section:labels()[section_index],
        minimum_certified_gap_m:minimum,maximum_displacement_m:displacement,required_gap_m:state.required,
        passes:minimum>=state.required,witness:witness,refined_pairs:refinements}
}
