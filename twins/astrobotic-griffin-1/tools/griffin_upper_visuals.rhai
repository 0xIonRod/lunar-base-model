import "griffin_tank_finish" as finish;
import "social_surface_finish" as surface;
import "social_geometry_detail" as geometry;
import "griffin_bus_detail" as harness;
import "lunco://scripting/tools/assembly_builder" as builder;

fn datum(name) {
    let m=sysml_model("twin://astrobotic-griffin-1/requirements/griffin_upper_visuals.sysml");
    let v=m.value("GriffinUpperVisualStudy::UpperHardware::"+name);
    if v==() {throw("Missing upper-hardware study datum: "+name);}v
}
fn reference(parent,name,asset,prim,kind) {
    #{AddPrim:#{edit_target:"@root@",parent_path:parent,name:name,type_name:kind,reference:asset,reference_prim_path:prim}}
}
fn visual(ops,path,material) {
    ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:path,schemas:["MaterialBindingAPI"]}});
    ops.push(surface::attr(path,"purpose","token","\"render\""));
    ops.push(surface::attr(path,"physics:collisionEnabled","bool","false"));
    ops.push(finish::binding(path,material));ops
}
fn body_profile() {
    let r=datum("BottleRadiusM");let half=datum("BottleBarrelLengthM")/2.0;
    let n=datum("DomeStations").to_int();let profile=[[0.0,-half-r]];
    for i in 1..n+1 {
        let a=acos(-1.0)*0.5*i.to_float()/n.to_float();
        profile.push([r*sin(a),-half-r*cos(a)]);
    }
    profile.push([r,half]);
    for i in 1..n {let a=acos(-1.0)*0.5*i.to_float()/n.to_float();profile.push([r*cos(a),half+r*sin(a)]);}
    profile.push([0.0,half+r]);profile
}
fn revolve(ops,parent,name,profile,position,material,crease) {
    let path=parent+"/"+name;ops.push(surface::add(parent,name,"Mesh"));
    ops.push(#{RevolveProfileMesh:#{edit_target:"@root@",path:path,profile:profile,axis:[1.0,0.0,0.0],
        angular_segments:datum("AngularSegments").to_int(),normal_crease_angle_deg:crease,
        display_color:finish::study("insulationColor"),collision_enabled:false}});
    ops=harness::append(ops,builder::place_plan("@root@",path,position,[0.0,0.0,0.0],[1.0,1.0,1.0]));
    visual(ops,path,material)
}
fn looks_plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/World"});let ops=[surface::add("/World","Looks","Scope")];
    let asset="twin://astrobotic-griffin-1/components/lander/griffin_tank_visual.usda";
    for row in [["Insulation","TankInsulation"],["Retention","RetentionMetal"],["Aluminum","MachinedAluminum"],["Valve","ValveMetal"]] {
        ops.push(reference("/World/Looks",row[0],asset,"/PropellantTank/MliTank/Looks/"+row[1],"Material"));
    }
    for row in [["crinkle","UpperFoilCrinkle"],["facet_depth","UpperFoilFacet"],["sheen","UpperFoilSheen"]] {
        ops.push(surface::attr("/World/Looks/Insulation/Surface","inputs:"+row[0],"float",datum(row[1]).to_string()));
    }
    ops.push(surface::attr("/World","documentation","string","\"Two visible upper pressurant bottles reconstructed from public imagery. Three helium tanks are confirmed in the architecture; third placement unresolved. Render-only study geometry, no gas or pressure model.\""));
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn bottle_plan(doc,index) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/World"});
    let name=if index==0 {"UpperBottlePort"}else{"UpperBottleStarboard"};let root="/World/"+name;
    let ops=[surface::add("/World",name,"Xform")];
    ops=harness::append(ops,builder::place_plan("@root@",root,[0.0,datum("BottleCenterYM"),datum("BottleCentersZM")[index]],[0.0,0.0,0.0],[1.0,1.0,1.0]));
    ops=revolve(ops,root,"Blanket",body_profile(),[0.0,0.0,0.0],"/World/Looks/Insulation",datum("NormalCreaseDeg"));
    let r=datum("BottleRadiusM");let width=datum("BandWidthM");let t=datum("BandThicknessM");
    let ring=[[r,-width/2.0],[r+t,-width/2.0],[r+t,width/2.0],[r,width/2.0]];
    let n=0;for x in datum("BandStationsXM") {
        ops=revolve(ops,root,"RetentionBand"+n,ring,[x,0.0,0.0],"/World/Looks/Retention",20.0);
        let pos=[x,datum("FootCenterYM")-datum("BottleCenterYM"),0.0];
        ops=geometry::cube(ops,root,geometry::shape("Foot"+n,pos,[datum("FootWidthM"),datum("FootHeightM"),datum("FootDepthM")],[0.0,0.0,0.0],"/World/Looks/Aluminum"));
        n+=1;
    }
    let length=datum("ValveLengthM");let x=datum("BottleBarrelLengthM")/2.0+r+length/2.0;
    ops=harness::append(ops,builder::cylinder_shape_plan_axis("@root@",root,"ServiceBoss",datum("ValveRadiusM"),length,[x,0.0,0.0],[0.0,0.0,0.0],[1.0,1.0,1.0],"X",false));
    ops=visual(ops,root+"/ServiceBoss","/World/Looks/Valve");
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn install_plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/GriffinBus"});
    if !q.prim.exists {throw("Open canonical bus source");}
    let ops=[reference("/GriffinBus","UpperPressurantVisuals","twin://astrobotic-griffin-1/components/lander/griffin_upper_pressurant_visual.usda","/World","Xform")];
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn deck_plan(doc) {
    let root="/GriffinBus/RoverPayloadDeck";let q=query("InspectUsdDocument",#{doc_id:doc,path:root});
    if !q.prim.exists {throw("Missing existing payload support deck");}
    let h=datum("DeckHalfWidthM");let c=datum("DeckCornerStationM");
    let profile=[[-c,-h],[c,-h],[h,-c],[h,c],[c,h],[-c,h],[-h,c],[-h,-c]];
    let path=root+"/Infill";let ops=[surface::add(root,"Infill","Mesh")];
    let metal=query("QueryUsdPrim",#{doc_id:doc,path:"/GriffinBus/Looks/TankCollars/Surface",attrs:["inputs:diffuseColor"]});
    ops.push(#{ExtrudeProfileMesh:#{edit_target:"@root@",path:path,profile:profile,length:datum("DeckThicknessM"),plane:"XZ",display_color:metal.attrs["inputs:diffuseColor"],collision_enabled:false}});
    ops=harness::append(ops,builder::place_plan("@root@",path,[0.0,datum("DeckLocalYM"),0.0],[0.0,0.0,0.0],[1.0,1.0,1.0]));
    ops=visual(ops,path,"/GriffinBus/Looks/TankCollars");
    let i=0;for side in [-1.0,1.0] {for station in -2..3 {for axis in 0..2 {
        let along=station.to_float()*datum("BoltPitchM");let rail=side*datum("BoltRailStationM");
        let p=if axis==0 {[along,datum("BoltCenterYM"),rail]}else{[rail,datum("BoltCenterYM"),along]};
        ops=harness::append(ops,builder::cylinder_shape_plan_axis("@root@",root,"MountBolt"+i,datum("BoltRadiusM"),datum("BoltHeightM"),p,[0.0,0.0,0.0],[1.0,1.0,1.0],"Y",false));
        ops=visual(ops,root+"/MountBolt"+i,"/GriffinBus/Looks/FrameMetal");i+=1;
    }}}
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn skirt_plan(doc) {
    let path="/World/EngineSkirt/Looks/BayBlanket/Surface";
    let q=query("InspectUsdDocument",#{doc_id:doc,path:path});if !q.prim.exists {throw("Missing existing skirt insulation shader");}
    let ops=[];for row in [["crinkle","SkirtFoilCrinkle"],["facet_depth","SkirtFoilFacet"],["sheen","SkirtFoilSheen"],["v_scale","SkirtFoilAxialScale"]] {
        ops.push(surface::attr(path,"inputs:"+row[0],"float",datum(row[1]).to_string()));
    }
    #{doc_id:doc,generation:q.generation,ops:ops}
}
fn check_bottle(doc,index) {
    let root="/World/"+if index==0 {"UpperBottlePort"}else{"UpperBottleStarboard"};
    let q=query("QueryUsdPrim",#{doc_id:doc,path:root+"/Blanket",attrs:["points","physics:collisionEnabled","purpose"],relationships:true,schemas:true});
    if q.type_name!="Mesh" || q.attrs.purpose!="render" || q.attrs["physics:collisionEnabled"]!=false {throw("Invalid render-only bottle");}
    let lo=[1.0e20,1.0e20,1.0e20];let hi=[-1.0e20,-1.0e20,-1.0e20];
    // Shared revolution topology has two unique poles and complete station rings.
    // Read the poles and four cardinal points of the equator; avoid walking
    // thousands of face corners inside the bounded Rhai observation hook.
    let seg=datum("AngularSegments").to_int();let first=(datum("DomeStations").to_int()-1)*seg+1;
    let samples=[q.attrs.points[0],q.attrs.points[q.attrs.points.len()-1]];
    for i in 0..4 {samples.push(q.attrs.points[first+i*(seg/4)]);}
    for p in samples {for a in 0..3 {lo[a]=min(lo[a],p[a]);hi[a]=max(hi[a],p[a]);}}
    if abs(hi[0]-lo[0]-datum("BottleBarrelLengthM")-2.0*datum("BottleRadiusM"))>0.00001 {throw("Bottle length differs from source");}
    if abs(hi[1]-lo[1]-2.0*datum("BottleRadiusM"))>0.00001 {throw("Bottle diameter differs from source");}
    #{ok:true,bounds:[lo,hi],vertex_count:q.attrs.points.len(),scope:"Two visible pressurant envelopes only; third location and pressure dynamics unresolved"}
}
fn check_deck(doc) {
    let root="/GriffinBus/RoverPayloadDeck";
    let q=query("QueryUsdPrim",#{doc_id:doc,path:root+"/Infill",attrs:["points","normals","purpose","physics:collisionEnabled"],relationships:true});
    if q.type_name!="Mesh" || q.attrs.points.len()!=16 || q.attrs.normals.len()==0 || q.attrs.purpose!="render" || q.attrs["physics:collisionEnabled"]!=false {throw("Invalid deck infill");}
    if q.relationships["material:binding"]!=["/GriffinBus/Looks/TankCollars"] {throw("Deck finish is not bound");}
    for p in q.attrs.points {
        if abs(p[0])>datum("DeckHalfWidthM")+0.00001 || abs(p[2])>datum("DeckHalfWidthM")+0.00001 || abs(p[1])>datum("DeckThicknessM")/2.0+0.00001 {throw("Deck infill exceeds its study envelope");}
    }
    for i in 0..20 {
        let b=query("QueryUsdPrim",#{doc_id:doc,path:root+"/MountBolt"+i,attrs:["radius","height","purpose","physics:collisionEnabled"]});
        if b.type_name!="Cylinder" || b.attrs.purpose!="render" || b.attrs["physics:collisionEnabled"]!=false || abs(b.attrs.radius-datum("BoltRadiusM"))>0.000001 || abs(b.attrs.height-datum("BoltHeightM"))>0.000001 {throw("Invalid deck mounting head");}
    }
    #{ok:true,mounting_heads:20,scope:"Source-owned render infill and mounting details; original physical deck retained"}
}
