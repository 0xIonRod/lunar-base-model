import "griffin_tank_finish" as finish;
import "lunco://scripting/tools/assembly_builder" as builder;
// Lightweight, render-only service harness and connector reconstruction.
// Routes follow existing structural stations; exact flight routing is unpublished.
fn append(ops,plan) {
    if !plan.ok {throw("Generic shape planner rejected service detail");}
    for op in plan.ops {ops.push(op);} ops
}
fn angle(y,x) {
    if x>0.0 {atan(y/x)}
    else if x<0.0 {atan(y/x)+if y>=0.0 {acos(-1.0)}else{-acos(-1.0)}}
    else if y>0.0 {acos(-1.0)/2.0}
    else if y<0.0 {-acos(-1.0)/2.0}
    else {0.0}
}
fn tube(ops,parent,name,a,b,radius,material) {
    let dx=b[0]-a[0];let dy=b[1]-a[1];let dz=b[2]-a[2];
    let horizontal=sqrt(dx*dx+dz*dz);let length=sqrt(horizontal*horizontal+dy*dy);
    if length<=0.0 {throw("Zero-length harness segment");}
    let rotation=[-angle(dy,horizontal)*180.0/acos(-1.0),angle(dx,dz)*180.0/acos(-1.0),0.0];
    let center=[(a[0]+b[0])/2.0,(a[1]+b[1])/2.0,(a[2]+b[2])/2.0];
    ops=append(ops,builder::cylinder_shape_plan("@root@",parent,name,radius,length,center,rotation,[1.0,1.0,1.0],false));
    ops.push(finish::attr(parent+"/"+name,"purpose","token","\"render\""));
    ops.push(finish::binding(parent+"/"+name,material));ops
}
fn plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/GriffinBus"});
    if !q.prim.exists {throw("Open the canonical bus component");}
    let root="/GriffinBus/TankSupportPlate/ServiceHarness";
    let old=query("QueryUsdPrim",#{doc_id:doc,path:root,attrs:[]});
    if old.type_name!=(){throw("Service detail already exists; inspect before revising");}
    let radius=finish::study("harnessRadiusM");let drop=finish::study("harnessDropM");
    let ops=[finish::add("/GriffinBus/TankSupportPlate","ServiceHarness","Xform")];
    ops=finish::study_material(ops,"/GriffinBus/Looks","HarnessJacket","harness");
    ops=finish::study_material(ops,"/GriffinBus/Looks","ServiceConnectors","connector");
    let material="/GriffinBus/Looks/HarnessJacket";
    // Clockwise structural stations, measured from the current component.
    let stations=[];
    for name in ["FrameRailFrontPort","FrameRailFrontStarboard","FrameRailStarboardFront","FrameRailStarboardRear",
                 "FrameRailRearStarboard","FrameRailRearPort","FrameRailPortRear","FrameRailPortFront"] {
        let rail=query("QueryUsdPrim",#{doc_id:doc,path:"/GriffinBus/"+name,attrs:["xformOp:translate","xformOp:scale"]});
        if rail.attrs==() || rail.attrs["xformOp:translate"]==() {throw("Missing bus rail station: "+name);}
        let p=rail.attrs["xformOp:translate"];let s=rail.attrs["xformOp:scale"];
        // Keep the jacket on the inboard surface, inside the existing envelope.
        let x=p[0]-sign(p[0])*(s[0]/2.0+radius);
        let z=p[2]-sign(p[2])*(s[2]/2.0+radius);
        stations.push([x,p[1]-s[1]*0.15,z]);
    }
    for i in 0..stations.len() {
        let a=stations[i];let b=stations[(i+1)%stations.len()];
        let mid=[(a[0]+b[0])/2.0,(a[1]+b[1])/2.0-drop,(a[2]+b[2])/2.0];
        ops=tube(ops,root,"Bundle"+i+"A",a,mid,radius,material);
        ops=tube(ops,root,"Bundle"+i+"B",mid,b,radius,material);
        // An endpoint clamp visually seats each bundle against its structural rail.
        let p=root+"/Clamp"+i;
        ops=append(ops,builder::cube_shape_plan("@root@",root,"Clamp"+i,1.0,[radius*3.0,radius*2.0,radius*3.0],false));
        ops=append(ops,builder::place_plan("@root@",p,a,(),[radius*3.0,radius*2.0,radius*3.0]));
        ops.push(finish::attr(p,"purpose","token","\"render\""));
        ops.push(finish::binding(p,"/GriffinBus/Looks/FrameMetal"));
    }
    let pod=query("QueryUsdPrim",#{doc_id:doc,path:"/GriffinBus/AvionicsPod",attrs:["xformOp:translate","xformOp:scale"]});
    let p=pod.attrs["xformOp:translate"];let s=pod.attrs["xformOp:scale"];
    if p==() || s==(){throw("Missing avionics interface envelope");}
    for i in 0..6 {
        let x=p[0]+s[0]*(-0.35+i.to_float()*0.14);
        let y=p[1];let z=p[2]-s[2]/2.0;
        ops=tube(ops,root,"Connector"+i,[x,y,z],[x,y,z-radius*3.0],radius*1.5,"/GriffinBus/Looks/ServiceConnectors");
        ops=tube(ops,root,"Pigtail"+i,[x,y,z-radius*3.0],[x,y-s[1]*0.35,z-radius*5.0],radius*0.45,material);
    }
    ops.push(finish::attr(root,"documentation","string","\"Photo-inspired service harness. Estimated routing and connectors, non-colliding and massless; not an electrical or pressure network.\""));
    #{ok:true,doc_id:doc,generation:q.generation,ops:ops,segments:28,clamps:8}
}
fn check(doc) {
    let root="/GriffinBus/TankSupportPlate/ServiceHarness";
    let checks=0;
    for i in 0..8 {
        for suffix in ["A","B"] {
            let p=root+"/Bundle"+i+suffix;
            let q=query("QueryUsdPrim",#{doc_id:doc,path:p,attrs:["radius","height","physics:collisionEnabled","purpose"],schemas:true});
            if q.type_name!="Cylinder" || q.attrs["radius"]!=finish::study("harnessRadiusM") || q.attrs["height"]<=0.0 || q.attrs["physics:collisionEnabled"]!=false || q.attrs["purpose"]!="render" || q.api_schemas.contains("PhysicsRigidBodyAPI") {throw("Invalid render-only service tube: "+p);}
            checks+=1;
        }
    }
    #{ok:true,checks:checks,scope:"Service-bundle geometry and separation from physics only"}
}

fn bay_material_plan(doc) {
    let material="/World/EngineSkirt/Looks/BayBlanket";
    let q=query("InspectUsdDocument",#{doc_id:doc,path:material});
    if !q.prim.exists {throw("Open the canonical engine-skirt component");}
    // Retain the shared material reference, with explicit instance parameters
    // and local output connection for the nested engine-bay installation.
    let ops=finish::insulation_ops(material+"/Surface");
    ops.push(#{SetConnection:#{edit_target:"@root@",path:material,name:"outputs:surface",type_name:"token",sources:[material+"/Surface.outputs:surface"]}});
    #{ok:true,doc_id:doc,generation:q.generation,ops:ops}
}

fn adapter_material_plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/Griffin1/PayloadAdapter/AdapterPlate"});
    if !q.prim.exists {throw("Open the canonical Griffin vehicle owner");}
    let ops=finish::study_material([],"/Griffin1/Looks","PayloadInterfaceMetal","aluminum");
    ops.push(finish::binding("/Griffin1/PayloadAdapter/AdapterPlate","/Griffin1/Looks/PayloadInterfaceMetal"));
    ops.push(finish::attr("/Griffin1/PayloadAdapter/AdapterPlate","primvars:displayColor","color3f[]","["+finish::color_text(finish::study("aluminumColor"))+"]"));
    #{ok:true,doc_id:doc,generation:q.generation,ops:ops}
}
