// Source-equivalence and coincident native joint-frame checks for installation.
import "griffin_ramp_packaging_checks" as observation;
import "griffin_spec" as spec;
import "lunco://scripting/tools/assembly_builder" as frames;
import "lunco://scripting/tools/sysml_requirements" as requirements;
import "lunco://scripting/tools/sysml_requirement_checks" as checks;
import "usd_geometry_inspection" as inspection;
import "griffin_ramp_packaging" as packaging;

fn state(doc,root,docs,index){
    let model=requirements::model();let fences=[];let sections=[];let banks=[];
    let labels=["root","middle","toe"];
    for i in 0..labels.len(){let label=labels[i];
        fences.push(query("QueryUsdPrim",#{doc_id:docs[label],path:"/RampSection",attrs:[]}));
        sections.push(if i==index{observation::source_section(docs[label],false)}else{()});
    }
    for name in spec::ramp_names(){let p=frames::mount_local_transform(doc,root+"/"+name);if !p.ok{throw("Ramp body missing");}banks.push(p.value);}
    #{doc:doc,scene:root,source_revision:model.source_revision,docs:docs,sections:sections,banks:banks,
        source_fences:fences,fence:query("QueryUsdPrim",#{doc_id:doc,path:root,attrs:[]})}
}
fn component(doc,root,docs,bank,index){
    observation::verify_installation_at(state(doc,root,docs,index),bank,index,root,spec::ramp_names())
}
fn body_pose(doc,root,path){
    if path==root{return transform_identity();}
    let pose=frames::mount_frame_in_body(doc,root,path);if !pose.ok{throw("Joint body frame unavailable");}
    transform(vec3_from(pose.value.translation),quat_from(pose.value.rotation),vec3(1.0,1.0,1.0))
}
fn direction(pose,vector){transform_apply_point(pose,vector)-transform_apply_point(pose,vec3(0.0,0.0,0.0))}
fn joint(doc,root,name){
    let path=root+"/"+name;
    let r=query("QueryUsdPrim",#{doc_id:doc,path:path,
        attrs:["physics:localPos0","physics:localPos1","physics:localRot0","physics:localRot1"],rels:["physics:body0","physics:body1"]});
    if r.type_name!="PhysicsRevoluteJoint" && r.type_name!="PhysicsFixedJoint"{throw("Native joint required");}
    let a=body_pose(doc,root,r.relationships["physics:body0"][0]);let b=body_pose(doc,root,r.relationships["physics:body1"][0]);
    let error=vlen(transform_apply_point(a,vec3_from(r.attrs["physics:localPos0"]))-transform_apply_point(b,vec3_from(r.attrs["physics:localPos1"])));
    // Query quatf values retain USD (w,x,y,z); native quaternions use (x,y,z,w).
    let ra=r.attrs["physics:localRot0"];let rb=r.attrs["physics:localRot1"];
    let qa=quat_from([ra[1],ra[2],ra[3],ra[0]]);let qb=quat_from([rb[1],rb[2],rb[3],rb[0]]);
    let world_a=transform_compose(a,transform(vec3(0.0,0.0,0.0),qa,vec3(1.0,1.0,1.0)));
    let world_b=transform_compose(b,transform(vec3(0.0,0.0,0.0),qb,vec3(1.0,1.0,1.0)));
    let va=direction(world_a,vec3(0.0,0.0,1.0));let vb=direction(world_b,vec3(0.0,0.0,1.0));
    let axis_error=vlen(va-vb);let rest_error=0.0;
    if r.type_name=="PhysicsFixedJoint"{
        for v in [vec3(1.0,0.0,0.0),vec3(0.0,1.0,0.0)]{rest_error=max(rest_error,vlen(direction(world_a,v)-direction(world_b,v)));}
    }
    let model=requirements::model();let tolerance=model.value("GriffinRampRootSectionRequirements::RampRootSection::geometryToleranceM");
    let axis_tolerance=model.value("GriffinRampRequirements::GriffinEgressRamp::physicalRampRootAxisMirrorTolerance");
    #{passes:error<=tolerance && axis_error<=axis_tolerance && rest_error<=axis_tolerance,
        path:path,anchor_residual_m:error,axis_residual:axis_error,fixed_rest_residual:rest_error,
        doc_id:doc,document_generation:r.document_generation,stage_generation:r.stage_generation,source_revision:model.source_revision}
}

fn mass(doc,root,bank,index){
    let labels=["root","middle","toe"];let label=labels[index];let own="GriffinRampRequirements::GriffinEgressRamp::";
    let model=requirements::model();let component=packaging::component_owner(label)+"::";
    let paths=[root+"/"+spec::ramp_names()[bank]];paths.push(paths[0]+"/MiddleSection");paths.push(paths[1]+"/ToeSection");
    let path=paths[index];let r=query("QueryUsdPrim",#{doc_id:doc,path:path,
        attrs:["physics:mass","physics:diagonalInertia","physics:centerOfMass"]});
    let inertia=r.attrs["physics:diagonalInertia"];
    if inertia==() || inertia.len()!=3{throw("Authored section inertia unavailable");}
    let constraint="GriffinRampRequirements::GRC020_RampSectionInertiaMatchesEnvelope";
    let values=[["measuredXKgM2",inertia[0]],["measuredYKgM2",inertia[1]],["measuredZKgM2",inertia[2]],
        ["sectionMassKg",model.value(own+"physicalRampSectionMassKg")],["sectionLengthM",model.value(component+"lengthM")],
        ["outsideWidthM",model.value(own+"rampSurfaceWidthM")],["thicknessM",model.value(own+"rampSurfaceThicknessM")],
        ["toleranceKgM2",model.value(own+"physicalRampSectionMassPropertiesToleranceKgM2")]];
    let ir=model.constraint_ir(constraint);ir.ok=ir.valid;
    let observations=requirements::scalar_constraint_observations(ir,values);
    for i in 0..observations.len(){observations[i].provider=if i<3{"usd"}else{"source_literal"};observations[i].state="value";
        if i<3{observations[i].stage_generation=r.stage_generation;observations[i].doc_id=doc;observations[i].document_generation=r.document_generation;}
        else{observations[i].source_revision=model.source_revision;observations[i].provider_generation=model.source_revision;}}
    // These are authored USD mass attributes, not measured runtime inertia.
    // The evidence retains the exact source document generation separately.
    let result=model.evaluate_constraint(constraint,observations,0.0,0.0);
    let centre=vec3(model.value(component+"lengthM")/2.0,model.value(own+"rampSurfaceCenterYM")-
        if index==0{model.value(component+"entryAxisYM")}else{0.0},0.0);
    let centre_error=vlen(vec3_from(r.attrs["physics:centerOfMass"])-centre);
    let mass_error=abs(r.attrs["physics:mass"]-model.value(own+"physicalRampSectionMassKg"));
    #{passes:result.verdict=="pass" && centre_error<=model.value(component+"geometryToleranceM") && mass_error<=model.value(own+"physicalRampSectionMassPartitionToleranceKg"),
        constraint_ok:result.verdict=="pass",constraint_verdict:result.verdict,path:path,centre_residual_m:centre_error,mass_residual_kg:mass_error,
        mass_kg:r.attrs["physics:mass"],inertia_kg_m2:inertia,source_revision:model.source_revision,
        doc_id:doc,document_generation:r.document_generation,stage_generation:r.stage_generation}
}
