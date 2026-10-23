import "griffin_ramp_section_checks" as section;
import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;
fn profile(){#{owner:"GriffinRampToeSectionRequirements::RampToeSection",package_name:"GriffinRampToeSectionRequirements",verification:"Verify_GriffinRampToeSection",
    requirement:"gts001",short_name:"GTS-001",constraint:"GTSC001_PositiveSpan",component:"ramp_toe_section",section_index:2}}
fn dependencies(){section::dependencies()}
fn observe(doc,root){section::observe(doc,root,profile())}
fn fixture_path(){sysml_requirements::model().value(profile().owner+"::usdPath")}
fn inspect(doc,root,batch){section::inspect(doc,root,profile(),batch)}
