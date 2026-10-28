import "griffin_tank_finish" as finish;
// June 2026 hardware-inspired presentation. Dome profile is a study silhouette,
// not a replacement for the separately owned cylindrical contact geometry.
fn plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/LandingLeg"});
    if !q.prim.exists {throw("Open the canonical landing-leg component");}
    let m=sysml_requirements::model();
    let own="GriffinLandingLegRequirements::GriffinLandingLegAssembly::";
    let radius=m.value(own+"footPadRadiusM");
    let height=m.value(own+"footPadHeightM");
    if radius==() || height==() || radius<=0.0 || height<=0.0 {throw("Missing pad source dimensions");}
    let existing=query("QueryUsdPrim",#{doc_id:doc,path:"/LandingLeg/FootPadCover",attrs:[]});
    if existing.type_name!=(){throw("Leg finish already exists; inspect before editing");}
    let root="/LandingLeg/Looks";
    let ops=[];
    ops=finish::study_material(ops,root,"PistonSteel","piston");
    ops=finish::study_material(ops,root,"PadMetal","pad");
    ops=finish::study_material(ops,root,"JointMetal","joint");
    ops.push(finish::binding("/LandingLeg/ShockPiston",root+"/PistonSteel"));
    for name in ["FootPad","FootPadPlate"] {ops.push(finish::binding("/LandingLeg/"+name,root+"/PadMetal"));}
    for name in ["MountClevisOuter","MountClevisInner","MountAxle"] {ops.push(finish::binding("/LandingLeg/"+name,root+"/JointMetal"));}
    let path="/LandingLeg/FootPadCover";
    let profile=[];
    let radii=finish::study("padProfileRadiusFractions");
    let heights=finish::study("padProfileHeightFractions");
    for i in 0..radii.len(){profile.push([radius*radii[i],height*heights[i]]);}
    profile.reverse(); // outward-facing winding for the closed revolution profile
    ops.push(finish::add("/LandingLeg","FootPadCover","Mesh"));
    ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:path,schemas:["MaterialBindingAPI"]}});
    ops.push(#{RevolveProfileMesh:#{edit_target:"@root@",path:path,
        profile:profile,axis:[0.0,1.0,0.0],angular_segments:finish::study("padAngularSegments").to_int(),normal_crease_angle_deg:60.0,
        display_color:finish::study("padColor"),collision_enabled:false}});
    ops.push(finish::attr(path,"xformOp:translate","double3","(0.0, "+m.value(own+"footPadCenterYM")+", 0.0)"));
    ops.push(finish::attr(path,"xformOpOrder","token[]","[\"xformOp:translate\"]"));
    ops.push(finish::attr(path,"purpose","token","\"render\""));
    ops.push(finish::binding(path,root+"/PadMetal"));
    ops.push(finish::attr(path,"documentation","string","\"Photo-inspired domed pad cover; estimated profile, render-only. Original source-owned pad collider and dynamics remain authoritative.\""));
    #{ok:true,doc_id:doc,generation:q.generation,ops:ops,source_revision:m.source_revision}
}
fn check(doc) {
    let m=sysml_requirements::model();
    let own="GriffinLandingLegRequirements::GriffinLandingLegAssembly::";
    let results=[];
    for row in [["FootPad","radius","footPadRadiusM"],["FootPad","height","footPadHeightM"],
                ["StrutOuter","radius","strutRadiusM"],["StrutInner","radius","strutRadiusM"],
                ["ShockPiston","radius","shockPistonRadiusM"]] {
        let p="/LandingLeg/"+row[0];
        let q=query("QueryUsdPrim",#{doc_id:doc,path:p,attrs:[row[1],"physics:collisionEnabled"]});
        let expected=m.value(own+row[2]);
        if expected==() || q.attrs[row[1]]==() || abs(q.attrs[row[1]]-expected)>0.000001 {throw("Leg mechanical datum changed: "+p);}
        if q.attrs["physics:collisionEnabled"]!=false {throw("Visual component acquired collision: "+p);}
        results.push(#{path:p,attribute:row[1],actual:q.attrs[row[1]],expected:expected});
    }
    let cap=query("QueryUsdPrim",#{doc_id:doc,path:"/LandingLeg/FootPadCover",attrs:["purpose","physics:collisionEnabled"],schemas:true});
    if cap.type_name!="Mesh" || cap.attrs["purpose"]!="render" || cap.attrs["physics:collisionEnabled"]!=false || cap.api_schemas.contains("PhysicsRigidBodyAPI") {throw("Pad cap must remain render-only");}
    #{ok:true,checks:results.len()+1,measurements:results,source_revision:m.source_revision}
}
