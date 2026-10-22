import "griffin_ramp_section_checks" as section;
import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;
fn profile(){#{owner:"GriffinRampRootSectionRequirements::RampRootSection",package_name:"GriffinRampRootSectionRequirements",verification:"Verify_GriffinRampRootSection",
    requirement:"grs001",short_name:"GRS-001",constraint:"GRSC001_PositiveSpan",component:"ramp_root_section",section_index:0}}
fn dependencies(){section::dependencies()}
fn observe(doc,root){section::observe(doc,root,profile())}
fn fixture_path(){sysml_requirements::model().value(profile().owner+"::usdPath")}
fn inspect(doc,root,batch){section::inspect(doc,root,profile(),batch)}
