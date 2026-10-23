import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;

import "lunco://scripting/tools/sysml_requirements" as requirements;
fn render_surface(id, component, requirement, verification, wheel) {
    render_surface(id,component,requirement,verification,wheel,())
}
fn render_surface(id, component, requirement, verification, wheel, doc) {
    let name=requirements::model().value("FlipWheelRequirements::FlipDirectionalWheelAssembly::renderRootName");
    if !sysml_enum_is(name){throw("Wheel render-root identity is unavailable");}
    let root=wheel+"/"+name.literal;
    let result=[sysml_requirement_checks::exists(id + "-cylinder", component, requirement, verification, wheel, "Cylinder"),
     sysml_requirement_checks::not_exists(id + "-no-duplicate", component, requirement, verification, wheel + "/Visual"),
     sysml_requirement_checks::attribute_equals(id + "-purpose", component, requirement, verification, wheel, "purpose", "proxy"),
     sysml_requirement_checks::attribute_equals(id + "-proxy-hidden", component, requirement, verification, wheel, "proxyVisibility", "invisible"),
     sysml_requirement_checks::exists(id + "-render-root", component, requirement, verification, root, "Xform"),
     sysml_requirement_checks::attribute_equals(id + "-render-purpose", component, requirement, verification, root, "purpose", "render"),
     sysml_requirement_checks::attribute_equals(id + "-render-visible", component, requirement, verification, root, "renderVisibility", "visible")];
    for field in [#{name:"xformOp:translate",expected:0.0},#{name:"xformOp:rotateXYZ",expected:0.0},#{name:"xformOp:scale",expected:1.0}]{for i in 0..3{
        result.push(sysml_requirement_checks::array_component(id+"-"+field.name+"-"+i.to_string(),component,requirement,verification,root,field.name,[i],field.expected,0.000001));
    }}
    let request=#{path:wheel,attrs:[],schemas:true,children:true};if doc!=(){request.doc_id=doc;}
    let owner=query("QueryUsdPrim",request);
    let roots=0;
    for child in owner.children {
        request.path=child;request.attrs=["purpose"];request.schemas=false;request.children=false;
        let record=query("QueryUsdPrim",request);
        if record.attrs.purpose=="render" {roots+=1;}
    }
    for field in [#{name:"one-render-root",actual:roots},
        #{name:"visibility-api",actual:if owner.api_schemas.contains("VisibilityAPI"){1}else{0}}] {
        result.push(#{id:id+"-"+field.name,component:component,requirement:requirement,
            verification:verification,kind:"source_collection_count",actual_count:field.actual,expected_count:1});
    }
    if doc!=(){for i in 0..result.len(){result[i].doc_id=doc;}}
    result
}
