import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;

fn single_surface(id, component, requirement, verification, wheel) {
    [sysml_requirement_checks::exists(id + "-cylinder", component, requirement, verification, wheel, "Cylinder"),
     sysml_requirement_checks::not_exists(id + "-no-duplicate", component, requirement, verification, wheel + "/Visual"),
     sysml_requirement_checks::attribute_equals(id + "-purpose", component, requirement, verification, wheel, "purpose", "default"),
     #{id:id+"-material",component:component,requirement:requirement,verification:verification,
       kind:"relationship",path:wheel,rel:"material:binding",targets:[wheel+"/TireLook"]}]
}
