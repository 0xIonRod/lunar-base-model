import "griffin_ramp_section_checks" as section;
import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;
fn profile(){#{owner:"GriffinRampMiddleSectionRequirements::RampMiddleSection",package_name:"GriffinRampMiddleSectionRequirements",verification:"Verify_GriffinRampMiddleSection",
    requirement:"gms001",short_name:"GMS-001",constraint:"GMSC001_PositiveSpan",component:"ramp_middle_section",section_index:1}}
fn dependencies(){section::dependencies()}
fn observe(doc,root){section::observe(doc,root,profile())}
fn fixture_path(){sysml_requirements::model().value(profile().owner+"::usdPath")}
fn inspect(doc,root,batch){section::inspect(doc,root,profile(),batch)}
