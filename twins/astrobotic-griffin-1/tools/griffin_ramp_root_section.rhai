import "griffin_ramp_section_component" as section;
fn plan(doc,edit_target,root,group){
    section::plan(doc,edit_target,root,group,
        "GriffinRampRootSectionRequirements::RampRootSection","DeckSection",0,0.0)
}
fn fittings_plan(doc,edit_target,root,guide_index){
    section::fittings_plan(doc,edit_target,root,"GriffinRampRootSectionRequirements::RampRootSection",0,guide_index)
}
