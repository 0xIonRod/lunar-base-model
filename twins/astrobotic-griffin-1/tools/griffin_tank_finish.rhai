// Presentation study only: no measured optical/thermal flight properties.
// Pure, generation-checked plan for the canonical reusable tank component.
// Materials live beneath MliTank so the mechanical direct-child inventory stays intact.
fn add(parent,name,kind) {
    #{AddPrim:#{edit_target:"@root@",parent_path:parent,name:name,type_name:kind,reference:(),reference_prim_path:()}}
}
fn attr(path,name,kind,value) {
    #{SetAttribute:#{edit_target:"@root@",path:path,name:name,type_name:kind,value:value}}
}
fn binding(path,material) {
    #{SetRelationship:#{edit_target:"@root@",path:path,name:"material:binding",targets:[material]}}
}
fn study(name) {
    let legacy=#{insulationColor:"bodySkinDisplayColor",insulationShade:"busFoilValleyColor",
        insulationCrinkle:"busFoilCrinkleDensity",insulationFoldDepth:"busFoilFacetContrast",
        insulationSheen:"busFoilSheen",insulationVerticalScale:"busFoilAxialPatternScale"};
    if legacy[name]!=() {
        let model=sysml_requirements::model();
        let result=model.value("GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::"+legacy[name]);
        if result==(){throw("Missing source-owned insulation appearance: "+name);}
        return result;
    }
    let m=sysml_model("twin://astrobotic-griffin-1/requirements/griffin_presentation_study.sysml");
    let value=m.value("GriffinPresentationStudy::HardwareFinish::"+name);
    if value==(){throw("Missing presentation study datum: "+name);}
    value
}
fn color_text(value) {"("+value[0]+", "+value[1]+", "+value[2]+")"}
fn study_material(ops,root,name,prefix) {
    material(ops,root,name,color_text(study(prefix+"Color")),study(prefix+"Metallic").to_string(),study(prefix+"Roughness").to_string())
}
fn insulation_ops(shader) {
    let ops=[attr(shader,"inputs:foil_color","color3f",color_text(study("insulationColor"))),
             attr(shader,"inputs:shade_color","color3f",color_text(study("insulationShade")))];
    for item in [["crinkle","insulationCrinkle"],["facet_depth","insulationFoldDepth"],
                 ["sheen","insulationSheen"],["v_scale","insulationVerticalScale"]] {
        ops.push(attr(shader,"inputs:"+item[0],"float",study(item[1]).to_string()));
    }
    ops
}
fn material(ops,root,name,color,metallic,roughness) {
    let p=root+"/"+name;
    ops.push(add(root,name,"Material"));
    ops.push(add(p,"Surface","Shader"));
    ops.push(attr(p+"/Surface","info:id","token","\"UsdPreviewSurface\""));
    ops.push(attr(p+"/Surface","outputs:surface","token","\"\""));
    ops.push(attr(p+"/Surface","inputs:diffuseColor","color3f",color));
    ops.push(attr(p+"/Surface","inputs:metallic","float",metallic));
    ops.push(attr(p+"/Surface","inputs:roughness","float",roughness));
    ops.push(#{SetConnection:#{edit_target:"@root@",path:p,name:"outputs:surface",type_name:"token",sources:[p+"/Surface.outputs:surface"]}});
    ops
}
fn plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/PropellantTank/MliTank"});
    if !q.prim.exists {throw("Open the canonical PropellantTank component first");}
    let existing=query("QueryUsdPrim",#{doc_id:doc,path:"/PropellantTank/MliTank/Looks",attrs:[]});
    if existing.type_name!=(){throw("Tank finish is already authored; inspect before revising");}
    let root="/PropellantTank/MliTank/Looks";
    let foil=root+"/TankInsulation";
    let ops=[add("/PropellantTank/MliTank","Looks","Scope"),add(root,"TankInsulation","Material"),add(foil,"Surface","Shader")];
    ops.push(attr(foil+"/Surface","info:implementationSource","token","\"sourceAsset\""));
    ops.push(attr(foil+"/Surface","info:wesl:sourceAsset","asset","@lunco://shaders/mli_foil.wesl@"));
    ops.push(attr(foil+"/Surface","outputs:surface","token","\"\""));
    ops.push(attr(foil+"/Surface","inputs:foil_color","color3f",color_text(study("insulationColor"))));
    ops.push(attr(foil+"/Surface","inputs:shade_color","color3f",color_text(study("insulationShade"))));
    ops.push(attr(foil+"/Surface","inputs:crinkle","float",study("insulationCrinkle").to_string()));
    ops.push(attr(foil+"/Surface","inputs:facet_depth","float",study("insulationFoldDepth").to_string()));
    ops.push(attr(foil+"/Surface","inputs:sheen","float",study("insulationSheen").to_string()));
    ops.push(attr(foil+"/Surface","inputs:v_scale","float",study("insulationVerticalScale").to_string()));
    ops.push(#{SetConnection:#{edit_target:"@root@",path:foil,name:"outputs:surface",type_name:"token",sources:[foil+"/Surface.outputs:surface"]}});
    ops=study_material(ops,root,"RetentionMetal","retention");
    ops=study_material(ops,root,"MachinedAluminum","aluminum");
    ops=study_material(ops,root,"ValveMetal","valve");
    ops.push(binding("/PropellantTank/MliTank",foil));
    for name in ["TankBandA","TankBandB","TankBandC","TankShoulderTop","TankShoulderBottom"] {
        ops.push(binding("/PropellantTank/"+name,root+"/RetentionMetal"));
    }
    for name in ["TankNeckTop","TankNeckBottom","TankCradle","TankSupportPost","TankCradlePad"] {
        ops.push(binding("/PropellantTank/"+name,root+"/MachinedAluminum"));
    }
    for name in ["TankValveTop","TankValveBottom","TankValveCapTop","TankValveCapBottom","TankTransitionTop","TankTransitionBottom"] {
        ops.push(binding("/PropellantTank/"+name,root+"/ValveMetal"));
    }
    #{ok:true,doc_id:doc,generation:q.generation,ops:ops,
      scope:"Presentation study; geometry, collision, mass, interfaces and thermal parameters unchanged"}
}

// Readback gate: reuse the existing mechanical source, not another dimension table.
fn check(doc) {
    let m=sysml_requirements::model();
    let owner="GriffinTankRequirements::GriffinPropellantTankAssembly::";
    let measurements=[];
    for item in [
        ["MliTank","radius","bodyRadiusM"],
        ["TankNeckTop","radius","neckRadiusM"],
        ["TankNeckBottom","radius","neckRadiusM"],
        ["TankValveTop","radius","valveRadiusM"],
        ["TankValveBottom","radius","valveRadiusM"],
        ["TankCradle","radius","cradleRadiusM"],
        ["TankCradle","height","cradleHeightM"],
        ["TankBandA","height","bandHeightM"],
        ["TankBandB","height","bandHeightM"],
        ["TankBandC","height","bandHeightM"]] {
        let path="/PropellantTank/"+item[0];
        let q=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[item[1]],relationships:true});
        let expected=m.value(owner+item[2]);
        if q.attrs==() || q.attrs[item[1]]==() || expected==() {throw("Missing mechanical source or readback: "+path);}
        if abs(q.attrs[item[1]]-expected)>0.000001 {throw("Mechanical datum changed: "+path);}
        if q.relationships["material:binding"]==() || q.relationships["material:binding"].len()!=1 {throw("Missing finish binding: "+path);}
        measurements.push(#{path:path,attribute:item[1],actual:q.attrs[item[1]],expected:expected});
    }
    #{ok:true,source_revision:m.source_revision,checks:measurements.len(),measurements:measurements,
      scope:"Existing source-owned tank dimensions and new material bindings; no flight optical validation"}
}

// The vehicle previously overrode all four shells with one assembly material.
// Remove only those stronger bindings so the component's finishes can propagate.
fn installation_plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/Griffin1"});
    if !q.prim.exists {throw("Open the canonical Griffin vehicle owner");}
    let ops=[];
    for tank in ["TankPX","TankNX","TankPZ","TankNZ"] {
        let path="/Griffin1/"+tank+"/MliTank";
        let shell=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[],relationships:true});
        if shell.type_name!="Sphere" {throw("Missing referenced tank shell: "+path);}
        if shell.relationships["material:binding"]!=["/Griffin1/Looks/MliFoil_Mat"] {throw("Tank binding has changed; inspect before migration: "+path);}
        ops.push(#{RemoveRelationship:#{edit_target:"@root@",path:path,name:"material:binding"}});
    }
    #{ok:true,doc_id:doc,generation:q.generation,ops:ops}
}
