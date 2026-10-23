import "griffin_visual_builder" as visual;
import "griffin_spec" as spec;
import "lunco://scripting/tools/assembly_builder" as assembly;
import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;

fn frame_name(model,owner,feature) {
    let value=model.value(owner+"::"+feature);
    if !sysml_enum_is(value) {throw("Ramp-section datum identity must be a typed enum");}
    value.literal
}

// A detached section component owns its geometry. The mounted mechanism is a
// separate assembly task; this plan never writes bodies, joints or latches.
fn plan(doc, edit_target, root, group, owner, identity, section_index, deployment_angle) {
    let model=sysml_requirements::model();
    let length=f64_from(model.value(owner+"::lengthM"));
    if length==() || !length.is_finite() || length<=0.0 {
        throw("Ramp section span is unavailable from the typed requirement source");
    }
    let part=query("QueryUsdPrim",#{doc_id:doc,path:root});
    if part==() || part.type_name!="Xform" {throw("Ramp section Xform is required");}
    let result=visual::_isolated_ramp_section_geometry_ops(doc,edit_target,
        root,identity,length,section_index,deployment_angle,group);
    if result.ok!=true {return result;}
    if group=="base" {
        let stale=query("QueryUsdPrim",#{doc_id:doc,path:root,
            attrs:["lunco:section:length_m","lunco:section:outside_width_m"]});
        for name in ["lunco:section:length_m","lunco:section:outside_width_m"] {
            if stale.attrs[name]!=() {result.ops.push(#{RemoveAttribute:#{edit_target:edit_target,path:root,name:name}});}
        }
        let datums=datums_plan(doc,edit_target,root,owner);
        if !datums.ok{return datums;}for op in datums.ops{result.ops.push(op);}
    }
    result.source_revision=model.source_revision;
    result.doc_id=doc;
    result.generation=part.document_generation;
    result
}


// Interface revisions reuse the same native datum plan as a full rebuild.
fn datums_plan(doc,edit_target,root,owner){
    let model=sysml_requirements::model();let length=f64_from(model.value(owner+"::lengthM"));
    if length==() || !length.is_finite() || length<=0.0{throw("Section length is unavailable");}
    let result=#{ok:true,ops:[]};
    let own=owner+"::";
    for datum in [#{name:frame_name(model,owner,"entryFrameName"),x:0.0,y:model.value(own+"entryAxisYM")},
        #{name:frame_name(model,owner,"exitFrameName"),x:length,y:model.value(own+"exitAxisYM")}] {
        let frame=query("QueryUsdPrim",#{doc_id:doc,path:root+"/"+datum.name});
        if frame.type_name!=() && frame.type_name!="Xform" {throw("Ramp-section datum must be an Xform");}
        let pose=if frame.type_name=="Xform" {
            assembly::place_plan(edit_target,root+"/"+datum.name,[datum.x,datum.y,0.0],(),())
        } else {
            assembly::frame_plan(edit_target,root,datum.name,[datum.x,datum.y,0.0],(),())
        };
        if pose.ok!=true {return pose;}
        for op in pose.ops {result.ops.push(op);}
    }

    result.source_revision=model.source_revision;result.doc_id=doc;
    result.generation=query("QueryUsdPrim",#{doc_id:doc,path:root}).document_generation;
    result
}

// Cheeks meet the parent rail through an inboard heel web. The child tongue
// attaches outboard of its own axis, leaving the selected fold sweep open.
fn fittings_plan(doc,edit_target,root,owner,section_index,guide_index){
    let model=sysml_requirements::model();let own=owner+"::";
    let has_exit=model.value(own+"hasExitHinge");
    if has_exit!=true && has_exit!=false{throw("Section exit-hinge topology must be Boolean");}
    let length=f64_from(model.value(own+"lengthM"));
    let entry=f64_from(model.value(own+"entryAxisYM"));
    let exit=f64_from(model.value(own+"exitAxisYM"));
    let run=f64_from(model.value(own+"plateAttachmentRunM"));
    let web=f64_from(model.value(own+"forkWebSizeM"));
    let ramp="GriffinRampRequirements::GriffinEgressRamp::";
    let width=f64_from(model.value(ramp+"rampPivotLugWidthM"));
    let tongue=f64_from(model.value(ramp+"rampPivotLugThicknessM"));
    let cheek=f64_from(model.value(ramp+"rampRailWidthM"));
    let lower=f64_from(model.value(ramp+"assemblySideTrussLowerChordCenterYM"));
    if length==() || entry==() || exit==() || run==() || web==() || width==()
        || tongue==() || cheek==() || lower==() || length<=run || run<=width
        || web<=0.0 || width<=0.0 || tongue<=0.0 || cheek<=0.0 {
        throw("Section fitting datums and positive connected stock are required");
    }
    let guides=spec::ramp_guide_stations();
    if guide_index<0 || guide_index>=guides.len(){throw("Section fitting guide is unavailable");}
    let guide=guides[guide_index];let parts=[];
    let entry_support=if entry<0.0 {lower}else{spec::ramp_guide_center_y_m(section_index,run,length)};
    let exit_support=if exit<0.0 {lower}else{spec::ramp_guide_center_y_m(section_index,length-run,length)};
    parts.push(#{name:guide.pin+"Lug",a:vec3(0.0,entry,0.0),b:vec3(run,entry_support,0.0),z:guide.z,stock:tongue});
    if has_exit {
    for side in [#{name:"Negative",sign:-1.0},#{name:"Positive",sign:1.0}]{
        parts.push(#{name:guide.pin+"Distal"+side.name+"Lug",a:vec3(length,exit,0.0),b:vec3(length-run,exit_support,0.0),
            z:guide.z+side.sign*(tongue+cheek)/2.0,stock:cheek});
    }
    }
    let color=model.value("GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::silverDisplayColor");
    let ops=[];
    for part in parts{
        let delta=part.b-part.a;let span=vlen(delta);let centre=(part.a+part.b)*0.5;
        let shape=visual::_ramp_round_plate_visual_ops(doc,edit_target,root,part.name,
            width,part.stock,-(span+width)/2.0,(span+width)/2.0,part.z,color);
        if !shape.ok{return shape;} for op in shape.ops{ops.push(op);}
        let angle=-atan(delta.x,delta.y)*180.0/acos(-1.0);
        let pose=assembly::place_plan(edit_target,root+"/"+part.name,[centre.x,centre.y,part.z],[0.0,0.0,angle],[1.0,1.0,1.0]);
        if !pose.ok{return pose;} for op in pose.ops{ops.push(op);}
        ops.push(#{SetRelationship:#{edit_target:edit_target,path:root+"/"+part.name,
            name:"material:binding",targets:[root+"/Looks/RampStructure"]}});
    }
    ops.push(#{SetTranslate:#{edit_target:edit_target,path:root+"/"+guide.pin,value:[0.0,entry,guide.z]}});
    ops.push(#{SetRelationship:#{edit_target:edit_target,path:root+"/"+guide.pin,
        name:"material:binding",targets:[root+"/Looks/RampStructure"]}});
    if guide_index==0{
        ops.push(#{SetTranslate:#{edit_target:edit_target,path:root+"/HingeBarrel",value:[0.0,entry,0.0]}});
    }
    if has_exit {
    let heel=visual::_component_cube_visual_ops(doc,edit_target,root,guide.pin+"ForkWeb",
        [length-run,exit_support,guide.z],(),[web,web,tongue+2.0*cheek],color);
    if !heel.ok{return heel;}for op in heel.ops{ops.push(op);}
    ops.push(#{SetRelationship:#{edit_target:edit_target,path:root+"/"+guide.pin+"ForkWeb",
        name:"material:binding",targets:[root+"/Looks/RampStructure"]}});
    } else {
        for suffix in ["DistalNegativeLug","DistalPositiveLug","ForkWeb"]{
            let path=root+"/"+guide.pin+suffix;let old=query("QueryUsdPrim",#{doc_id:doc,path:path});
            if old.type_name!=(){ops.push(#{RemovePrim:#{edit_target:edit_target,path:path}});}
        }
    }
    #{ok:true,ops:ops,doc_id:doc,generation:query("QueryUsdPrim",#{doc_id:doc,path:root}).document_generation,
        source_revision:model.source_revision,kind:"griffin_section_connected_fittings"}
}
