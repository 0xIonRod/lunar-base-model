import "lunco://scripting/tools/assembly_builder" as builder;
import "social_surface_finish" as surface;
import "griffin_tank_finish" as finish;
fn datum(name) {
    let m=sysml_model("twin://astrobotic-griffin-1/requirements/griffin_flip_egress.sysml");
    let v=m.value("GriffinFlipEgressStudy::CompactEgress::"+name);
    if v==() {throw("Missing compact-egress datum: "+name);} v
}
fn enabled() {find_path("/Griffin1SurfaceOps/Lander/CompactEgress")>=0}
fn append(ops,p) {if p.ok!=true {throw("Compact-egress shape rejected: "+p);}for op in p.ops {ops.push(op);}ops}
fn reference(ops,parent,name,asset,prim,kind) {
    ops.push(#{AddPrim:#{edit_target:"@root@",parent_path:parent,name:name,type_name:kind,reference:asset,reference_prim_path:prim}});ops
}
fn cube(ops,parent,name,position,size,rotation,material,collision) {
    ops=append(ops,builder::cube_shape_plan("@root@",parent,name,1.0,size,collision));
    let path=parent+"/"+name;
    ops=append(ops,builder::place_plan("@root@",path,position,rotation,size));
    if collision {
        ops.push(surface::attr(path,"purpose","token","\"proxy\""));
        ops.push(surface::attr(path,"visibility","token","\"invisible\""));
    }
    else {ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:path,schemas:["MaterialBindingAPI"]}});ops.push(surface::attr(path,"purpose","token","\"render\""));}
    if material!="" {ops.push(finish::binding(path,material));}ops
}
fn sweep_geometry(x,y,width,thickness) {
    let rings=[];let faces=[];let slopes=[];
    for i in 0..x.len() {
        rings.push([x[i],y[i],0.0]);rings.push([x[i],y[i],width]);
        rings.push([x[i],y[i]-thickness,width]);rings.push([x[i],y[i]-thickness,0.0]);
        let n=vec3(0.0,0.0,0.0);
        for k in [i-1,i] {if k>=0 && k<x.len()-1 {
            let s=vec3(y[k+1]-y[k],x[k]-x[k+1],0.0);n+=s*(1.0/vlen(s));
        }}
        slopes.push(n*(1.0/vlen(n)));
    }
    faces.push([0,1,2,3]);
    for i in 0..x.len()-1 {for j in 0..4 {faces.push([i*4+j,(i+1)*4+j,(i+1)*4+(j+1)%4,i*4+(j+1)%4]);}}
    let end=(x.len()-1)*4;faces.push([end+3,end+2,end+1,end]);
    // Split the thin plate's top/side/bottom vertices. Smooth only along the
    // bend, retaining sharp sheet edges; default flat normals facet the bend.
    let points=[];let normals=[];let counts=[];let indices=[];
    for f in 0..faces.len() {
        counts.push(4);
        for v in faces[f] {
            let n=if f==0 {vec3(1.0,0.0,0.0)}else if f==faces.len()-1 {vec3(-1.0,0.0,0.0)}else{
                let side=(f-1)%4;
                if side==0 {slopes[v/4]}else if side==2 {slopes[v/4]*(-1.0)}else{vec3(0.0,0.0,if side==1{1.0}else{-1.0})}
            };
            indices.push(points.len());points.push(rings[v]);normals.push(vec3_array(n));
        }
    }
    #{points:points,normals:normals,counts:counts,indices:indices}
}
fn normals_text(normals) {let text="[";for i in 0..normals.len() {if i>0 {text+=", ";}text+=surface::text_color(normals[i]);}text+"]"}
fn strip(ops,root,name,x,y,z,width,thickness,material) {
    strip_mode(ops,root,name,x,y,z,width,thickness,material,false)
}
fn flat_geometry(x,y,width,thickness) {
    let points=[];let counts=[];let indices=[];
    for i in 0..x.len() {for p in [[x[i],y[i],0.0],[x[i],y[i],width],[x[i],y[i]-thickness,width],[x[i],y[i]-thickness,0.0]] {points.push(p);}}
    counts.push(4);for j in 0..4 {indices.push(j);}
    for i in 0..x.len()-1 {for j in 0..4 {counts.push(4);for v in [i*4+j,(i+1)*4+j,(i+1)*4+(j+1)%4,i*4+(j+1)%4] {indices.push(v);}}}
    counts.push(4);for j in 0..4 {indices.push((x.len()-1)*4+3-j);}
    #{points:points,counts:counts,indices:indices}
}
fn strip_mode(ops,root,name,x,y,z,width,thickness,material,smooth) {
    // Native extrude_profile accepts convex outlines only. This bent plate is
    // a nonconvex rectangular sweep: one explicit ring per source station.
    let mesh=if smooth {sweep_geometry(x,y,width,thickness)}else{flat_geometry(x,y,width,thickness)};
    ops=append(ops,builder::mesh_shape_plan("@root@",root,name,mesh.points,mesh.counts,mesh.indices,[0.1,0.12,0.14],false));
    let path=root+"/"+name;
    if smooth {ops.push(surface::attr(path,"normals","normal3f[]",normals_text(mesh.normals)));}
    ops=append(ops,builder::place_plan("@root@",path,[0.0,0.0,z-width/2.0],[0.0,0.0,0.0],[1.0,1.0,1.0]));
    ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:path,schemas:["MaterialBindingAPI"]}});
    ops.push(surface::attr(path,"purpose","token","\"render\""));ops.push(finish::binding(path,material));ops
}
fn track_plan(doc,index) {
    let root="/World";let name=if index==0 {"TrackPort"}else{"TrackStarboard"};let path=root+"/"+name;
    let q=query("InspectUsdDocument",#{doc_id:doc,path:root});if !q.prim.exists {throw("Component root missing");}
    let ops=[];
    if index==0 && !query("InspectUsdDocument",#{doc_id:doc,path:root+"/Looks"}).prim.exists {
        ops=reference(ops,root,"Looks",(),"","Scope");
        let asset="twin://astrobotic-griffin-1/components/lander/griffin_ramp_root_section_visual.usda";
        ops=reference(ops,root+"/Looks","Structure",asset,"/RampSection/Looks/RampStructure","Material");
        ops=reference(ops,root+"/Looks","Walking",asset,"/RampSection/Looks/RampWalkingPlate","Material");
    }
    ops=reference(ops,root,name,(),"","Xform");
    let x=datum("stationsXM");let y=datum("heightsYM");let z=datum("trackCentersZM")[index];
    let width=datum("trackWidthM");let thickness=datum("plateThicknessM");
    ops=strip(ops,path,"WalkingPlate",x,y,z,width,thickness,root+"/Looks/Walking");
    let curb_y=[];for v in y {curb_y.push(v+datum("curbHeightM"));}
    for side in [-1.0,1.0] {
        ops=strip(ops,path,if side<0.0 {"CurbNegativeZ"}else{"CurbPositiveZ"},x,curb_y,z+side*(width-datum("curbWidthM"))/2.0,datum("curbWidthM"),datum("curbHeightM"),root+"/Looks/Structure");
    }
    // Independent box proxies follow the side profile; a single convex hull
    // would fill the curved undercut and create an incorrect invisible wedge.
    for i in 0..x.len()-1 {
        let dx=x[i]-x[i+1];let dy=y[i]-y[i+1];let length=sqrt(dx*dx+dy*dy);
        let angle=atan(dy/dx);let nx=-sin(angle);let ny=cos(angle);
        ops=cube(ops,path,"Contact"+i,[(x[i]+x[i+1])/2.0-nx*thickness/2.0,(y[i]+y[i+1])/2.0-ny*thickness/2.0,z],
            [length,thickness,width],[0.0,0.0,angle*180.0/acos(-1.0)],"",true);
    }
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn tether_plan(doc) {
    let root="/World";let q=query("InspectUsdDocument",#{doc_id:doc,path:root});let ops=[];
    ops=reference(ops,root,"TetherRestRouting",(),"","Xform");
    for i in 0..2 {
        let z=datum("trackCentersZM")[i];let dx=datum("rearWheelWrapXM")-datum("tetherAnchorXM");let dy=datum("rearWheelWrapYM")-datum("tetherAnchorYM");
        let length=sqrt(dx*dx+dy*dy);let angle=atan(dx/dy)*180.0/acos(-1.0);
        ops=cube(ops,root+"/TetherRestRouting","Webbing"+i,[(datum("rearWheelWrapXM")+datum("tetherAnchorXM"))/2.0,(datum("rearWheelWrapYM")+datum("tetherAnchorYM"))/2.0,z],
            [datum("webbingThicknessM"),length,datum("webbingWidthM")],[0.0,0.0,-angle],root+"/Looks/Walking",false);
        ops=cube(ops,root+"/TetherRestRouting","Anchor"+i,[datum("tetherAnchorXM"),datum("tetherAnchorYM"),z],[0.1,0.05,0.12],[0.0,0.0,0.0],root+"/Looks/Structure",false);
    }
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn install_plan(doc) {
    let root="/Griffin1";let q=query("InspectUsdDocument",#{doc_id:doc,path:root});let ops=[];let retired=[];
    for path in q.prim.children {
        let name=path.split("/");name=name[name.len()-1];
        if name.starts_with("EgressRamp") || name.starts_with("RampHinge") || name.starts_with("RampSectionHinge") || name.starts_with("RampFlightLatch") || name.starts_with("RampTransitionJoint") || name.starts_with("TransitionPlate") || name.starts_with("RampMount") {
            ops.push(#{SetActive:#{edit_target:"@root@",path:path,active:false}});retired.push(path);
        }
    }
    if retired.len()<30 {throw("Expected the complete legacy articulated installation");}
    ops=reference(ops,root,"CompactEgress","twin://astrobotic-griffin-1/components/lander/griffin_flip_egress_visual.usda","/World","Xform");
    ops=append(ops,builder::place_plan("@root@",root+"/CompactEgress",[0.0,0.0,0.0],[0.0,datum("installationYawDeg"),0.0],[1.0,1.0,1.0]));
    ops.push(surface::attr(root,"lunco:egress","string","\"Compact steep FLIP tracks; fabric tether rest routing; restrained descent not yet qualified\""));
    #{doc_id:doc,generation:q.generation,ops:ops,retired:retired}
}
fn check_track(doc,index) {
    let path="/World/"+if index==0 {"TrackPort"}else{"TrackStarboard"};
    let q=query("QueryUsdPrim",#{doc_id:doc,path:path+"/WalkingPlate",attrs:["points","faceVertexCounts","faceVertexIndices"]});
    let x=datum("stationsXM");let y=datum("heightsYM");let width=datum("trackWidthM");
    if q.type_name!="Mesh" || (q.attrs.points.len()!=(2+4*(x.len()-1))*4 && q.attrs.points.len()!=x.len()*4) {throw("Incorrect plate topology");}
    for i in 0..x.len() {
        let found=false;for p in q.attrs.points {if abs(p[0]-x[i])<0.000001 && abs(p[1]-y[i])<0.000001 {found=true;}}
        if !found {throw("Walking profile differs from source");}
    }
    for i in 0..x.len()-1 {
        let c=query("QueryUsdPrim",#{doc_id:doc,path:path+"/Contact"+i,attrs:["physics:collisionEnabled","xformOp:scale"]});
        if c.attrs["physics:collisionEnabled"]!=true || abs(c.attrs["xformOp:scale"][2]-width)>0.000001 {throw("Missing track contact proxy");}
    }
    #{ok:true,stations:x.len(),contact_segments:x.len()-1,scope:"source profile and attached contact proxies; not tether dynamics"}
}
fn refresh_track_plan(doc,index) {
    let p=track_plan(doc,index);let name=if index==0 {"TrackPort"}else{"TrackStarboard"};
    let ops=[#{RemovePrim:#{edit_target:"@root@",path:"/World/"+name}}];
    for op in p.ops {ops.push(op);}#{doc_id:doc,generation:p.generation,ops:ops}
}
fn shading_plan(doc,index,part) {
    let name=if index==0 {"TrackPort"}else{"TrackStarboard"};let root="/World/"+name;
    let x=datum("stationsXM");let y=datum("heightsYM");let z=datum("trackCentersZM")[index];
    let width=datum("trackWidthM");let thickness=datum("plateThicknessM");let material="/World/Looks/Walking";
    if part!="WalkingPlate" {
        if part!="CurbNegativeZ" && part!="CurbPositiveZ" {throw("Unknown ramp surface");}
        let next=[];for v in y {next.push(v+datum("curbHeightM"));}y=next;
        z+=if part=="CurbNegativeZ" {-(width-datum("curbWidthM"))/2.0}else{(width-datum("curbWidthM"))/2.0};
        width=datum("curbWidthM");thickness=datum("curbHeightM");material="/World/Looks/Structure";
    }
    let q=query("InspectUsdDocument",#{doc_id:doc,path:root+"/"+part});
    if !q.prim.exists {throw("Missing existing ramp surface");}
    // One mesh per batch keeps normal authoring inside the shared Rhai budget.
    // After building or refreshing a track, finish all three shading plans.
    let ops=[];for op in strip_mode([],root,part,x,y,z,width,thickness,material,true) {if op.AddPrim==() {ops.push(op);}}
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn hide_proxy_plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/World"});let ops=[];
    for track in ["TrackPort","TrackStarboard"] {for i in 0..6 {
        let path="/World/"+track+"/Contact"+i;
        let p=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:["physics:collisionEnabled"]});
        if p.attrs["physics:collisionEnabled"]!=true {throw("Expected active contact proxy");}
        ops.push(surface::attr(path,"visibility","token","\"invisible\""));
    }}
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn idle_coast_plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/FLIP"});if !q.prim.exists {throw("Open FLIP v5 vehicle source");}
    let ops=[];let value=if datum("idleMotorCoast")==true {"1.0"}else{"0.0"};
    for station in ["FL","FR","RL","RR"] {
        ops.push(surface::attr("/FLIP/Motor_"+station,"inputs:coast_at_zero","float",value));
    }
    #{doc_id:doc,generation:q.generation,ops:ops}
}
