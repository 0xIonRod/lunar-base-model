import "griffin_visual_builder" as visual;
import "lunco://scripting/tools/assembly_builder" as assembly;
import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;

fn frame_name(model,feature) {
    let value=model.value("GriffinRampRootSectionRequirements::RampRootSection::"+feature);
    if !sysml_enum_is(value) {throw("Root-section datum identity must be a typed enum");}
    value.literal
}

// A detached root component owns its geometry. The mounted mechanism is a
// separate assembly task; this plan never writes bodies, joints or latches.
fn plan(doc, edit_target, root, group) {
    let model=sysml_requirements::model();
    let length=f64_from(model.value("GriffinRampRootSectionRequirements::RampRootSection::lengthM"));
    if length==() || !length.is_finite() || length<=0.0 {
        throw("Root section span is unavailable from the typed requirement source");
    }
    let part=query("QueryUsdPrim",#{doc_id:doc,path:root});
    if part==() || part.type_name!="Xform" {throw("Root section Xform is required");}
    let result=visual::_isolated_ramp_section_geometry_ops(doc,edit_target,
        root,"DeckSection",length,0,0.0,group);
    if result.ok!=true {return result;}
    if group=="base" {
        let stale=query("QueryUsdPrim",#{doc_id:doc,path:root,
            attrs:["lunco:section:length_m","lunco:section:outside_width_m"]});
        for name in ["lunco:section:length_m","lunco:section:outside_width_m"] {
            if stale.attrs[name]!=() {result.ops.push(#{RemoveAttribute:#{edit_target:edit_target,path:root,name:name}});}
        }
        let own="GriffinRampRootSectionRequirements::RampRootSection::";
        for datum in [#{name:frame_name(model,"deckFrameName"),x:0.0,y:model.value(own+"deckAxisYM")},
            #{name:frame_name(model,"foldFrameName"),x:length,y:model.value(own+"foldAxisYM")}] {
            let frame=query("QueryUsdPrim",#{doc_id:doc,path:root+"/"+datum.name});
            if frame.type_name!=() && frame.type_name!="Xform" {throw("Root-section datum must be an Xform");}
            let pose=if frame.type_name=="Xform" {
                assembly::place_plan(edit_target,root+"/"+datum.name,[datum.x,datum.y,0.0],(),())
            } else {
                assembly::frame_plan(edit_target,root,datum.name,[datum.x,datum.y,0.0],(),())
            };
            if pose.ok!=true {return pose;}
            for op in pose.ops {result.ops.push(op);}
        }
    }
    result.source_revision=model.source_revision;
    result.doc_id=doc;
    result.generation=part.document_generation;
    result
}
