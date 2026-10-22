import "griffin_ramp_section_component" as section;
fn plan(doc,edit_target,root,group){
    section::plan(doc,edit_target,root,group,
        "GriffinRampMiddleSectionRequirements::RampMiddleSection","MiddleSection",1,0.0)
}
fn fittings_plan(doc,edit_target,root,guide_index){
    section::fittings_plan(doc,edit_target,root,"GriffinRampMiddleSectionRequirements::RampMiddleSection",1,guide_index)
}
