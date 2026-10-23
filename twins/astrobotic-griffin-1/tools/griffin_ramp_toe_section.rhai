import "griffin_ramp_section_component" as section;
import "lunco://scripting/tools/sysml_requirements" as requirements;
fn plan(doc,edit_target,root,group){
    let owner="GriffinRampToeSectionRequirements::RampToeSection";
    let angle=f64_from(requirements::model().value(owner+"::deploymentAngleRad"));
    if angle==() || !angle.is_finite(){throw("Toe deployment angle is unavailable");}
    section::plan(doc,edit_target,root,group,owner,"ToeSection",2,angle)
}
fn fittings_plan(doc,edit_target,root,guide_index){
    section::fittings_plan(doc,edit_target,root,"GriffinRampToeSectionRequirements::RampToeSection",2,guide_index)
}
