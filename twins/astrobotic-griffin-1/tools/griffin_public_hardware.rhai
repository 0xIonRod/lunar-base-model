import "social_geometry_detail" as geometry;
import "social_surface_finish" as surface;
import "griffin_tank_finish" as finish;
import "griffin_bus_detail" as harness;
import "lunco://scripting/tools/assembly_builder" as builder;

// Photo-informed presentation, never a second engineering geometry authority.
fn datum(name) {
    let model=sysml_model("twin://astrobotic-griffin-1/requirements/griffin_presentation_study.sysml");
    let value=model.value("GriffinPresentationStudy::PublicHardwareDetail::"+name);
    if value==() {throw("Missing public-reference appearance datum: "+name);}
    value
}
fn root(group) {
    if group=="panel" {return "/SolarPanel/Frame/EdgeCaps";}
    if group=="bus" {return "/GriffinBus/TankSupportPlate/ExternalServiceLoops";}
    throw("Unknown public hardware group: "+group)
}
fn caps(doc) {
    let q=query("QueryUsdPrim",#{doc_id:doc,path:"/SolarPanel/Frame",attrs:["points"]});
    if q.type_name!="Mesh" || q.attrs.points==() || q.attrs.points.len()%8!=0 {throw("Expected stock-box panel frame geometry");}
    let p=q.attrs.points;let result=[];
    for index in 0..(p.len()/8) {
        let low=[1.0e20,1.0e20,1.0e20];let high=[-1.0e20,-1.0e20,-1.0e20];
        for vertex in 0..8 {for axis in 0..3 {
            low[axis]=min(low[axis],p[index*8+vertex][axis]);
            high[axis]=max(high[axis],p[index*8+vertex][axis]);
        }}
        let depth=datum("TrimLipHeightM");let overhang=datum("TrimOverhangM");
        result.push(geometry::shape("Lip"+index,[(low[0]+high[0])/2.0,high[1]+depth/2.0,(low[2]+high[2])/2.0],
            [high[0]-low[0]+overhang,depth,high[2]-low[2]+overhang],[0.0,0.0,0.0],"/SolarPanel/Looks/PanelFrame"));
    }
    result
}
fn panel_plan(doc) {
    let path=root("panel");let q=query("InspectUsdDocument",#{doc_id:doc,path:"/SolarPanel/Frame"});
    if !q.prim.exists {throw("Open the exact reusable solar panel component");}
    if query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]}).type_name!=() {throw("Panel edging already exists");}
    let ops=[surface::add("/SolarPanel/Frame","EdgeCaps","Xform")];
    let shapes=caps(doc);for spec in shapes {ops=geometry::cube(ops,path,spec);}
    #{doc_id:doc,generation:q.generation,ops:ops,visual_shapes:shapes.len()}
}
fn tube(ops,parent,name,a,b,radius,material) {
    ops=harness::tube(ops,parent,name,a,b,radius,material);
    ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:parent+"/"+name,schemas:["MaterialBindingAPI"]}});ops
}
fn cylinder_detail(ops,parent,spec) {
    ops=harness::append(ops,builder::cylinder_shape_plan("@root@",parent,spec.name,spec.radius,spec.height,[0.0,spec.center,0.0],[0.0,0.0,0.0],[1.0,1.0,1.0],false));
    let path=parent+"/"+spec.name;
    ops.push(surface::attr(path,"axis","token","\"Y\""));
    ops.push(surface::attr(path,"purpose","token","\"render\""));
    ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:path,schemas:["MaterialBindingAPI"]}});
    ops.push(finish::binding(path,spec.material));ops
}
fn bus_routes(doc) {
    let result=[];let radius=datum("CableRadiusM");
    let pairs=[["FrameRailFrontPort","FrameRailFrontStarboard"],
        ["FrameRailRearPort","FrameRailRearStarboard"],
        ["FrameRailStarboardFront","FrameRailStarboardRear"],
        ["FrameRailPortFront","FrameRailPortRear"]];
    for pair in pairs {
        let a=query("QueryUsdPrim",#{doc_id:doc,path:"/GriffinBus/"+pair[0],attrs:["xformOp:translate","xformOp:scale"]}).attrs;
        let b=query("QueryUsdPrim",#{doc_id:doc,path:"/GriffinBus/"+pair[1],attrs:["xformOp:translate","xformOp:scale"]}).attrs;
        if a["xformOp:translate"]==() || b["xformOp:translate"]==() || a["xformOp:scale"]==() || b["xformOp:scale"]==() {throw("Missing structural service-loop mount");}
        let pa=a["xformOp:translate"];let pb=b["xformOp:translate"];let sa=a["xformOp:scale"];let sb=b["xformOp:scale"];
        let mid=[(pa[0]+pb[0])/2.0,0.0,(pa[2]+pb[2])/2.0];let r=sqrt(mid[0]*mid[0]+mid[2]*mid[2]);
        let nx=mid[0]/r;let nz=mid[2]/r;
        let stock=max(sa[0]*abs(nx)+sa[2]*abs(nz),sb[0]*abs(nx)+sb[2]*abs(nz))/2.0;
        let points=[];
        for index in 0..5 {
            let f=index.to_float()/4.0;
            let y=pa[1]-sa[1]/2.0+(pb[1]-sb[1]/2.0-(pa[1]-sa[1]/2.0))*f;
            let sag=datum("CableSagM")*sin(f*acos(-1.0));
            let outset=stock+datum("CableOutsetM");
            points.push([pa[0]+(pb[0]-pa[0])*f+nx*outset,y-sag,pb[2]*f+pa[2]*(1.0-f)+nz*outset]);
        }
        result.push(#{points:points,normal:[nx,0.0,nz],radius:radius});
    }
    result
}
fn bus_plan(doc) {
    let path=root("bus");let q=query("InspectUsdDocument",#{doc_id:doc,path:"/GriffinBus/TankSupportPlate"});
    if !q.prim.exists {throw("Open the canonical Griffin bus");}
    if query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]}).type_name!=() {throw("Exterior service loops already exist");}
    let ops=[surface::add("/GriffinBus/TankSupportPlate","ExternalServiceLoops","Xform")];let i=0;
    for route in bus_routes(doc) {
        for j in 0..4 {ops=tube(ops,path,"Loom"+i+"Segment"+j,route.points[j],route.points[j+1],route.radius,"/GriffinBus/Looks/HarnessJacket");}
        for end in [0,4] {
            let a=route.points[end];let n=route.normal;let length=datum("ConnectorLengthM");
            let b=[a[0]-n[0]*length,a[1],a[2]-n[2]*length];
            ops=tube(ops,path,"Loom"+i+"Connector"+end,a,b,route.radius*datum("ConnectorRadiusFactor"),"/GriffinBus/Looks/ServiceConnectors");
        }
        i+=1;
    }
    #{doc_id:doc,generation:q.generation,ops:ops,visual_shapes:i*6}
}
fn sleeve_specs(doc,name) {
    let q=query("QueryUsdPrim",#{doc_id:doc,path:"/LandingLeg/"+name,attrs:["radius","height","axis"]});
    if q.type_name!="Cylinder" || q.attrs.radius==() || q.attrs.height==() || q.attrs.axis!="Y" {throw("Expected the source-owned Y-axis strut: "+name);}
    let height=q.attrs.height*datum("SleeveFraction");let center=q.attrs.height*datum("SleeveCenterFraction");
    let allowance=if name=="ShockPiston" {datum("PistonSleeveAllowanceM")}else{datum("SmallSleeveAllowanceM")};
    let radius=q.attrs.radius+allowance;
    let cuff=datum("CuffHeightM");let cuffRadius=radius+datum("CuffAllowanceM");
    [#{name:"Blanket",center:center,height:height,radius:radius,material:"/LandingLeg/Looks/UpperStrutBlanket"},
     #{name:"UpperCuff",center:center+height/2.0,height:cuff,radius:cuffRadius,material:"/LandingLeg/Looks/JointMetal"},
     #{name:"LowerCuff",center:center-height/2.0,height:cuff,radius:cuffRadius,material:"/LandingLeg/Looks/PhotoCuffMetal"}]
}
fn barrel_specs(doc,station) {
    let root="/Griffin1/"+station+"_BusMount";
    let path=root+"/ShockBarrel/Tube";
    let a=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:["radius","height","axis"]}).attrs;
    if a.radius==() || a.height==() || a.axis!="Y" {throw("Missing installed shock barrel: "+path);}
    let height=a.height*datum("BarrelCoverageFraction");
    let radius=a.radius+datum("PistonSleeveAllowanceM");let cuff=datum("CuffHeightM");
    [#{name:"Blanket",center:0.0,height:height,radius:radius,material:root+"/Looks/UpperStrutBlanket"},
     #{name:"UpperCuff",center:height/2.0,height:cuff,radius:radius+datum("CuffAllowanceM"),material:root+"/Looks/JointMetal"},
     #{name:"LowerCuff",center:-height/2.0,height:cuff,radius:radius+datum("CuffAllowanceM"),material:root+"/Looks/PhotoCuffMetal"}]
}
fn installed_barrels_plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/Griffin1"});
    if !q.prim.exists {throw("Open the canonical Griffin vehicle");}
    let ops=[];
    for station in ["LegPX","LegNX","LegPZ","LegNZ"] {
        let parent="/Griffin1/"+station+"_BusMount/ShockBarrel/Tube";
        let path=parent+"/ThermalDetail";
        if query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]}).type_name!=() {throw("Installed barrel wrap already exists: "+station);}
        ops.push(surface::add(parent,"ThermalDetail","Xform"));
        for spec in barrel_specs(doc,station) {
            ops=cylinder_detail(ops,path,spec);
        }
    }
    #{doc_id:doc,generation:q.generation,ops:ops,visual_shapes:12}
}
fn leg_material_plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/LandingLeg/Looks"});
    if !q.prim.exists {throw("Open the reusable landing leg");}
    if query("QueryUsdPrim",#{doc_id:doc,path:"/LandingLeg/Looks/UpperStrutBlanket",attrs:[]}).type_name!=() {throw("Thermal sleeves already exist");}
    let material="/LandingLeg/Looks/UpperStrutBlanket";
    let ops=[#{AddPrim:#{edit_target:"@root@",parent_path:"/LandingLeg/Looks",name:"UpperStrutBlanket",type_name:"Material",
        reference:"twin://astrobotic-griffin-1/components/lander/griffin_bus_visual.usda",reference_prim_path:"/GriffinBus/Looks/ExteriorPanels"}}];
    ops=finish::study_material(ops,"/LandingLeg/Looks","PhotoCuffMetal","valve");
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn leg_plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/LandingLeg"});
    let material="/LandingLeg/Looks/UpperStrutBlanket";
    if query("QueryUsdPrim",#{doc_id:doc,path:material+"/Surface",attrs:[]}).type_name!="Shader" {throw("Prepare and project the referenced sleeve material first");}
    if query("QueryUsdPrim",#{doc_id:doc,path:"/LandingLeg/StrutOuter/ThermalDetail",attrs:[]}).type_name!=() {throw("Thermal sleeves already exist");}
    let ops=[#{SetConnection:#{edit_target:"@root@",path:material,name:"outputs:surface",type_name:"token",sources:[material+"/Surface.outputs:surface"]}}];
    for name in ["StrutOuter","StrutInner","ShockPiston"] {
        let parent="/LandingLeg/"+name;let path=parent+"/ThermalDetail";
        ops.push(surface::add(parent,"ThermalDetail","Xform"));
        for spec in sleeve_specs(doc,name) {
            ops=cylinder_detail(ops,path,spec);
        }
    }
    #{doc_id:doc,generation:q.generation,ops:ops,visual_shapes:9}
}
fn visual_check(doc,path,type_name,material) {
    let q=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:["purpose","physics:collisionEnabled"],relationships:true,schemas:true});
    if q.type_name!=type_name || q.attrs.purpose!="render" || q.attrs["physics:collisionEnabled"]!=false || q.api_schemas.contains("PhysicsCollisionAPI") || q.api_schemas.contains("PhysicsRigidBodyAPI") {throw("Invalid visual-only hardware: "+path);}
    if q.relationships["material:binding"]!=[material] {throw("Incorrect hardware finish: "+path);}
    true
}
fn tube_mount_check(doc,path,a,b,radius) {
    let q=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:["radius","height","xformOp:translate"]}).attrs;
    let length=0.0;
    for axis in 0..3 {
        length+=(b[axis]-a[axis])*(b[axis]-a[axis]);
        if abs(q["xformOp:translate"][axis]-(a[axis]+b[axis])/2.0)>0.000001 {throw("Service loom left its source mount: "+path);}
    }
    if abs(q.radius-radius)>0.000001 || abs(q.height-sqrt(length))>0.000001 {throw("Service loom dimensions changed: "+path);}
    true
}
fn check(doc,group) {
    let checks=0;
    if group=="panel" {
        for spec in caps(doc) {
            let p=root(group)+"/"+spec.name;visual_check(doc,p,"Cube",spec.material);
            let a=query("QueryUsdPrim",#{doc_id:doc,path:p,attrs:["xformOp:translate","xformOp:scale"]}).attrs;
            for axis in 0..3 {if abs(a["xformOp:translate"][axis]-spec.position[axis])>0.000001 || abs(a["xformOp:scale"][axis]-spec.scale[axis])>0.000001 {throw("Panel lip left the frame profile");}}
            checks+=1;
        }
    } else if group=="leg" {
        for name in ["StrutOuter","StrutInner","ShockPiston"] {for spec in sleeve_specs(doc,name) {
            let p="/LandingLeg/"+name+"/ThermalDetail/"+spec.name;
            visual_check(doc,p,"Cylinder",spec.material);
            let a=query("QueryUsdPrim",#{doc_id:doc,path:p,attrs:["axis","radius","height","xformOp:translate"]}).attrs;
            if a.axis!="Y" || abs(a.radius-spec.radius)>0.000001 || abs(a.height-spec.height)>0.000001 || abs(a["xformOp:translate"][1]-spec.center)>0.000001 {throw("Thermal sleeve left its source cylinder");}
            checks+=1;
        }}
    } else if group=="barrels" {
        for station in ["LegPX","LegNX","LegPZ","LegNZ"] {for spec in barrel_specs(doc,station) {
            let p="/Griffin1/"+station+"_BusMount/ShockBarrel/Tube/ThermalDetail/"+spec.name;
            visual_check(doc,p,"Cylinder",spec.material);
            let a=query("QueryUsdPrim",#{doc_id:doc,path:p,attrs:["axis","radius","height","xformOp:translate"]}).attrs;
            if a.axis!="Y" || abs(a.radius-spec.radius)>0.000001 || abs(a.height-spec.height)>0.000001 || abs(a["xformOp:translate"][1]-spec.center)>0.000001 {throw("Installed sleeve left the barrel");}
            checks+=1;
        }}
    } else if group=="bus" {
        let routes=bus_routes(doc);
        for i in 0..routes.len() {
            let route=routes[i];
            for j in 0..4 {
                let p=root(group)+"/Loom"+i+"Segment"+j;
                visual_check(doc,p,"Cylinder","/GriffinBus/Looks/HarnessJacket");
                tube_mount_check(doc,p,route.points[j],route.points[j+1],route.radius);checks+=1;
            }
            for end in [0,4] {
                let p=root(group)+"/Loom"+i+"Connector"+end;let a=route.points[end];let n=route.normal;let length=datum("ConnectorLengthM");
                visual_check(doc,p,"Cylinder","/GriffinBus/Looks/ServiceConnectors");
                tube_mount_check(doc,p,a,[a[0]-n[0]*length,a[1],a[2]-n[2]*length],route.radius*datum("ConnectorRadiusFactor"));checks+=1;
            }
        }
    } else {throw("Unknown public hardware group: "+group);}
    #{ok:true,group:group,checks:checks,scope:"Public-image-informed render detail; no engineering dimension or physics qualification"}
}
