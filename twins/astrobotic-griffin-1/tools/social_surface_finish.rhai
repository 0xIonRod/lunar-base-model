// Presentation-only, dry typed plans. CAD supplier meshes remain untouched.
fn add(parent,name,kind) {
    #{AddPrim:#{edit_target:"@root@",parent_path:parent,name:name,type_name:kind,reference:(),reference_prim_path:()}}
}
fn attr(path,name,kind,value) {
    #{SetAttribute:#{edit_target:"@root@",path:path,name:name,type_name:kind,value:value}}
}
fn datum(name) {
    let m=sysml_model("twin://astrobotic-griffin-1/requirements/griffin_presentation_study.sysml");
    let v=m.value("GriffinPresentationStudy::SocialFinish::"+name);
    if v==() {throw("Missing social appearance datum: "+name);}
    v
}
fn text_color(v) {"("+v[0]+", "+v[1]+", "+v[2]+")"}
fn shader(ops,root,name,asset) {
    let p=root+"/"+name;
    ops.push(add(root,name,"Material"));
    ops.push(add(p,"Surface","Shader"));
    ops.push(attr(p+"/Surface","info:implementationSource","token","\"sourceAsset\""));
    ops.push(attr(p+"/Surface","info:wesl:sourceAsset","asset","@"+asset+"@"));
    ops.push(attr(p+"/Surface","outputs:surface","token","\"\""));
    ops.push(#{SetConnection:#{edit_target:"@root@",path:p,name:"outputs:surface",type_name:"token",sources:[p+"/Surface.outputs:surface"]}});
    ops
}
fn materials_plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/FLIP"});
    if !q.prim.exists {throw("Open the canonical FLIP v5 vehicle");}
    let root="/FLIP/PresentationLooks";
    if query("QueryUsdPrim",#{doc_id:doc,path:root,attrs:[]}).type_name!=() {throw("Presentation materials already exist; inspect before revising");}
    let ops=[add("/FLIP","PresentationLooks","Scope")];
    for name in ["Frame","Chassis","DarkHousing","Tread","Spider","Cable","Fastener","Lens"] {
        ops=shader(ops,root,name,"twin://astrobotic-griffin-1/shaders/hardware_finish.wesl");
        let p=root+"/"+name+"/Surface";
        ops.push(attr(p,"inputs:base_color","color3f",text_color(datum(name+"Color"))));
        ops.push(attr(p,"inputs:diffuseColor","color3f",text_color(datum(name+"Color"))));
        for item in [["metallic","Metallic"],["roughness","Roughness"],["grain_strength","Grain"],["grain_scale","Scale"],["brush_ratio","Brush"]] {
            ops.push(attr(p,"inputs:"+item[0],"float",datum(name+item[1]).to_string()));
        }
    }
    ops=shader(ops,root,"Cell","twin://astrobotic-griffin-1/shaders/photovoltaic_finish.wesl");
    let p=root+"/Cell/Surface";
    for item in [["cell_color","CellColor"],["electrode_color","ElectrodeColor"]] {
        ops.push(attr(p,"inputs:"+item[0],"color3f",text_color(datum(item[1]))));
    }
    ops.push(attr(p,"inputs:diffuseColor","color3f",text_color(datum("CellColor"))));
    for item in [["roughness","CellRoughness"],["metallic","CellMetallic"],["pitch","ElectrodePitchM"],["width","ElectrodeWidthM"]] {
        ops.push(attr(p,"inputs:"+item[0],"float",datum(item[1]).to_string()));
    }
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn standard_channels_plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/FLIP/PresentationLooks"});
    if !q.prim.exists {throw("Missing FLIP presentation materials");}
    let ops=[];
    for name in ["Frame","Chassis","DarkHousing","Tread","Spider","Cable","Fastener","Lens","Cell"] {
        ops.push(attr("/FLIP/PresentationLooks/"+name+"/Surface","inputs:diffuseColor","color3f",text_color(datum(name+"Color"))));
    }
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn group_path(group) {
    if group=="chassis" {return "/FLIP/CADVisuals";}
    if group=="solar" {return "/FLIP/SolarMechanism/CADVisuals";}
    if ["FL","FR","RL","RR"].contains(group) {return "/FLIP/Suspension_"+group+"/Wheel_"+group+"/CADVisuals";}
    throw("Unknown component group: "+group)
}
fn finish(name) {
    if name.starts_with("Cell") {return "Cell";}
    if name.starts_with("Lens") {return "Lens";}
    if name.starts_with("Tire") {return "Tread";}
    if name.starts_with("Spider") {return "Spider";}
    if name.starts_with("CableWeb") || name.starts_with("SpringDetail") {return "Cable";}
    if name.starts_with("HubBolt") || name.contains("HingePin") {return "Fastener";}
    if name.starts_with("Drive") || name.starts_with("HubCap") || name.starts_with("Camera") || name.contains("Enclosure") || name=="BatteryPackB" {return "DarkHousing";}
    if name.starts_with("Skin") || name=="TopDeck" || name=="PayloadDeck" || name=="SolarBackplate" {return "Chassis";}
    for prefix in ["Baseplate","LowerRail","UpperRail","Post","UpperCross","FloorCross",
                   "BatteryTray","AvionicsTray","PowerControllerTray","PayloadMount","PayloadRail",
                   "LanderMount","SolarFrame","HingeSupport","MovingHinge","SensorBar","SensorFoot",
                   "StowRest","SensorMast","AntennaStub"] {
        if name.starts_with(prefix) {return "Frame";}
    }
    throw("Unclassified CAD surface; choose its finish explicitly: "+name)
}
fn assignments(doc,group) {
    let root=group_path(group);
    let q=query("InspectUsdDocument",#{doc_id:doc,path:root});
    if !q.prim.exists {throw("Missing CAD component: "+root);}
    let result=[];
    for path in q.prim.children {
        let p=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]});
        if p.type_name=="Mesh" && p.active==true {
            let name=path.split("/"); name=name[name.len()-1];
            result.push(#{path:path,material:"/FLIP/PresentationLooks/"+finish(name)});
        }
    }
    if result.len()==0 {throw("No active CAD surfaces in "+root);}
    result
}
fn component_plan(doc,group) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:group_path(group)});
    let ops=[];
    for a in assignments(doc,group) {
        ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:a.path,schemas:["MaterialBindingAPI"]}});
        ops.push(#{SetRelationship:#{edit_target:"@root@",path:a.path,name:"material:binding",targets:[a.material]}});
    }
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn check(doc,group) {
    let surfaces=assignments(doc,group);
    for a in surfaces {
        let p=query("QueryUsdPrim",#{doc_id:doc,path:a.path,attrs:[],relationships:true});
        if p.relationships["material:binding"]!=[a.material] {throw("Wrong surface binding: "+a.path);}
    }
    #{ok:true,group:group,checks:surfaces.len(),scope:"Visual material bindings only; CAD geometry and physical properties unchanged"}
}

fn hardware_ops(shader,prefix) {
    let m=sysml_model("twin://astrobotic-griffin-1/requirements/griffin_presentation_study.sysml");
    let owner="GriffinPresentationStudy::HardwareFinish::"+prefix;
    let color=m.value(owner+"Color");
    let metallic=m.value(owner+"Metallic");
    let roughness=m.value(owner+"Roughness");
    if color==() || metallic==() || roughness==() {throw("Missing existing hardware finish: "+prefix);}
    let ops=[attr(shader,"info:implementationSource","token","\"sourceAsset\""),
        attr(shader,"info:wesl:sourceAsset","asset","@twin://astrobotic-griffin-1/shaders/hardware_finish.wesl@"),
        attr(shader,"inputs:base_color","color3f",text_color(color)),
        attr(shader,"inputs:diffuseColor","color3f",text_color(color)),
        attr(shader,"inputs:metallic","float",metallic.to_string()),
        attr(shader,"inputs:roughness","float",roughness.to_string())];
    for item in [["grain_strength","FrameGrain"],["grain_scale","FrameScale"],["brush_ratio","FrameBrush"]] {
        ops.push(attr(shader,"inputs:"+item[0],"float",datum(item[1]).to_string()));
    }
    ops
}
fn griffin_plan(doc,component) {
    let root="";let foil="";let metals=[];
    if component=="tank" {
        root="/PropellantTank";foil=root+"/MliTank/Looks/TankInsulation/Surface";
        for item in [["RetentionMetal","retention"],["MachinedAluminum","aluminum"],["ValveMetal","valve"]] {
            metals.push([root+"/MliTank/Looks/"+item[0]+"/Surface",item[1]]);
        }
    } else if component=="leg" {
        root="/LandingLeg";
        for item in [["BrushedMetal","aluminum"],["PistonSteel","piston"],["PadMetal","pad"],["JointMetal","joint"]] {
            metals.push([root+"/Looks/"+item[0]+"/Surface",item[1]]);
        }
    } else if component=="bus" {
        root="/GriffinBus";foil=root+"/Looks/ExteriorPanels/Surface";
    } else if component=="skirt" {
        root="/World/EngineSkirt";foil=root+"/Looks/BayBlanket/Surface";
    } else {throw("Unknown Griffin component: "+component);}
    let q=query("InspectUsdDocument",#{doc_id:doc,path:root});
    if !q.prim.exists {throw("Open the exact Griffin component: "+root);}
    let ops=[];
    if foil!="" {
        if query("QueryUsdPrim",#{doc_id:doc,path:foil,attrs:[]}).type_name!="Shader" {throw("Missing foil owner: "+foil);}
        ops=griffin_tank_finish::insulation_ops(foil);
    }
    for item in metals {
        if query("QueryUsdPrim",#{doc_id:doc,path:item[0],attrs:[]}).type_name!="Shader" {throw("Missing hardware finish: "+item[0]);}
        for op in hardware_ops(item[0],item[1]) {ops.push(op);}
    }
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn review_lighting_plan(doc) {
    let root="/GriffinFlipVisual";
    let q=query("InspectUsdDocument",#{doc_id:doc,path:root});
    if !q.prim.exists {throw("Open the static visual review scene, not the surface mission");}
    for name in ["VisualCamera","ReviewFill"] {
        if query("QueryUsdPrim",#{doc_id:doc,path:root+"/"+name,attrs:[]}).type_name==() {throw("Missing review rig: "+name);}
    }
    #{doc_id:doc,generation:q.generation,ops:[
        attr(root+"/VisualCamera","exposure","float",datum("ReviewExposureStops").to_string()),
        attr(root+"/ReviewFill","inputs:intensity","float",datum("ReviewFillIntensity").to_string())]}
}
fn bus_hardware_plan(doc) {
    let root="/GriffinBus/Looks";
    let q=query("InspectUsdDocument",#{doc_id:doc,path:root});
    if !q.prim.exists {throw("Open the canonical Griffin bus component");}
    let ops=[];
    for item in [["FrameMetal","aluminum"],["TankCollars","aluminum"],["TankFrame","retention"]] {
        let shader=root+"/"+item[0]+"/Surface";
        if query("QueryUsdPrim",#{doc_id:doc,path:shader,attrs:[]}).type_name!="Shader" {throw("Missing bus finish: "+shader);}
        for op in hardware_ops(shader,item[1]) {ops.push(op);}
    }
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn check_bus_hardware(doc) {
    let m=sysml_model("twin://astrobotic-griffin-1/requirements/griffin_presentation_study.sysml");
    let checks=0;
    for row in [["FrameMetal","aluminum"],["TankCollars","aluminum"],["TankFrame","retention"]] {
        let p=query("QueryUsdPrim",#{doc_id:doc,path:"/GriffinBus/Looks/"+row[0]+"/Surface",
          attrs:["info:wesl:sourceAsset","inputs:base_color","inputs:diffuseColor","inputs:metallic","inputs:roughness"]});
        if p.attrs["info:wesl:sourceAsset"]!="twin://astrobotic-griffin-1/shaders/hardware_finish.wesl" {throw("Wrong bus hardware shader");}
        let prefix="GriffinPresentationStudy::HardwareFinish::"+row[1];
        let color=m.value(prefix+"Color");
        for i in 0..3 {for channel in ["base_color","diffuseColor"] {
            if abs(p.attrs["inputs:"+channel][i]-color[i])>0.000001 {throw("Bus metal color differs from its source");}
        }}
        for field in [["metallic","Metallic"],["roughness","Roughness"]] {
            if abs(p.attrs["inputs:"+field[0]]-m.value(prefix+field[1]))>0.000001 {throw("Bus finish differs from its source");}
        }
        checks+=4;
    }
    #{ok:true,checks:checks}
}
fn blanket_path(component) {
    if component=="bus" {return "/GriffinBus/Looks/ExteriorPanels/Surface";}
    if component=="tank" {return "/PropellantTank/MliTank/Looks/TankInsulation/Surface";}
    if component=="skirt" {return "/World/EngineSkirt/Looks/BayBlanket/Surface";}
    throw("Unknown canonical blanket owner: "+component)
}
fn blanket_detail_plan(doc,component) {
    let shader=blanket_path(component);
    let q=query("InspectUsdDocument",#{doc_id:doc,path:shader});
    if !q.prim.exists {throw("Open the canonical blanket owner: "+shader);}
    let m=sysml_model("twin://astrobotic-griffin-1/requirements/griffin_presentation_study.sysml");
    let ops=[attr(shader,"info:implementationSource","token","\"sourceAsset\""),
        attr(shader,"info:wesl:sourceAsset","asset","@twin://astrobotic-griffin-1/shaders/thermal_blanket.wesl@")];
    for row in [["micro_scale","MicroScalePerM"],["micro_strength","MicroSlope"]] {
        let v=m.value("GriffinPresentationStudy::BlanketFinish::"+row[1]);
        if v==() {throw("Missing fine blanket control: "+row[1]);}
        ops.push(attr(shader,"inputs:"+row[0],"float",v.to_string()));
    }
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn check_blanket_detail(doc,component) {
    let p=query("QueryUsdPrim",#{doc_id:doc,path:blanket_path(component),
      attrs:["info:wesl:sourceAsset","inputs:micro_scale","inputs:micro_strength"]});
    if p.attrs["info:wesl:sourceAsset"]!="twin://astrobotic-griffin-1/shaders/thermal_blanket.wesl" {throw("Wrong blanket shader");}
    let m=sysml_model("twin://astrobotic-griffin-1/requirements/griffin_presentation_study.sysml");
    for row in [["micro_scale","MicroScalePerM"],["micro_strength","MicroSlope"]] {
        let expected=m.value("GriffinPresentationStudy::BlanketFinish::"+row[1]);
        if abs(p.attrs["inputs:"+row[0]]-expected)>0.00001 {throw("Blanket control readback differs from SysML");}
    }
    #{ok:true,checks:3,component:component,generation:p.generation}
}
