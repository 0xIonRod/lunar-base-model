import "griffin_tank_finish" as finish;
import "social_surface_finish" as surface;

fn datum(name) {
    let m=sysml_model("twin://astrobotic-griffin-1/requirements/griffin_flip_egress.sysml");
    let v=m.value("GriffinFlipEgressStudy::ControlledDescent::"+name);
    if v==() {throw("Missing controlled-descent study parameter: "+name);}v
}

fn routing_config() {
    #{profile_x:griffin_compact_egress::datum("stationsXM"),profile_y:griffin_compact_egress::datum("heightsYM")}
}

// Stable authored identities and material; live point updates never edit USD.
fn visual_plan(doc) {
    let q=query("InspectUsdDocument",#{doc_id:doc,path:"/Griffin1"});
    if !q.prim.exists {throw("Open the canonical Griffin vehicle");}
    let root="/Griffin1/LiveTethers";
    if query("InspectUsdDocument",#{doc_id:doc,path:root}).prim.exists {return #{doc_id:doc,generation:q.generation,ops:[]};}
    let ops=[surface::add("/Griffin1","LiveTethers","Xform"),surface::add(root,"Looks","Scope")];
    ops.push(#{AddPrim:#{edit_target:"@root@",parent_path:root+"/Looks",name:"Webbing",type_name:"Material",
        reference:"twin://astrobotic-griffin-1/components/lander/griffin_flip_egress_visual.usda",reference_prim_path:"/World/Looks/Webbing"}});
    for side in ["Left","Right"] {
        let holder=root+"/"+side;ops.push(surface::add(root,side,"Xform"));
        for name in ["Span"] {
            let curve=holder+"/"+name;ops.push(surface::add(holder,name,"BasisCurves"));
            ops.push(surface::attr(curve,"type","token","\"linear\""));
            ops.push(surface::attr(curve,"wrap","token","\"nonperiodic\""));
            ops.push(surface::attr(curve,"curveVertexCounts","int[]","[2]"));
            ops.push(surface::attr(curve,"points","point3f[]","[(-0.005, 0.0, 0.0), (0.005, 0.0, 0.0)]"));
            ops.push(surface::attr(curve,"normals","normal3f[]","[(0.0, 1.0, 0.0), (0.0, 1.0, 0.0)]"));
            ops.push(surface::attr(curve,"widths","float[]","[0.04]"));
            ops.push(surface::attr(curve,"doubleSided","bool","true"));
            ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:curve,schemas:["MaterialBindingAPI"]}});
            ops.push(#{SetRelationship:#{edit_target:"@root@",path:curve,name:"material:binding",targets:[root+"/Looks/Webbing"]}});
        }
    }
    #{doc_id:doc,generation:q.generation,ops:ops}
}

fn install_plan(doc) {
    let root="/Griffin1SurfaceOps";let tether=root+"/EgressTether";
    let observer=root+"/CompactEgressObservation";let program=observer+"/Program";
    let q=query("InspectUsdDocument",#{doc_id:doc,path:root});
    if !q.prim.exists {throw("Open a Griffin mission fixture");}
    let existing_tether=query("InspectUsdDocument",#{doc_id:doc,path:tether});
    let existing_observer=query("InspectUsdDocument",#{doc_id:doc,path:observer});
    let ops=[];
    if !existing_tether.prim.exists {
        ops.push(surface::add(root,"EgressTether","Scope"));
        ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:tether,schemas:["LunCoProgramAPI"]}});
    }
    for station in ["FL","FR","RL","RR"] {
        let wheel=root+"/FLIP/Suspension_"+station+"/Wheel_"+station;
        ops.push(surface::attr(wheel,"outputs:fixed_contact","double","0.0"));
        ops.push(surface::attr(wheel,"outputs:loaded_contact","double","0.0"));
        ops.push(surface::attr(wheel,"inputs:brake","double","0.0"));
    }
    ops.push(surface::attr(tether,"info:implementationSource","token","\"sourceAsset\""));
    ops.push(surface::attr(tether,"info:sourceAsset","asset","@twin://astrobotic-griffin-1/models/GriffinTetherPairStudy.mo@"));
    for row in [["stiffness","stiffnessNPerM"],["damping","dampingNsPerM"],["initial_length","initialLengthM"],
      ["preload_tension","targetPretensionN"],["governor_tension","governorTensionN"],["pose_tension","poseTensionN"],
      ["loading_response_time","loadingResponseTimeS"],["unloading_response_time","unloadingResponseTimeS"],
      ["reel_speed_limit","maximumTakeupSpeedMps"],["payout_extension","payoutExtensionM"],["tension_limit","tensionLimitN"]] {
        ops.push(surface::attr(tether,"inputs:"+row[0],"double",datum(row[1]).to_string()));
    }
    let radius=query("QueryUsdPrim",#{path:root+"/FLIP/Suspension_RL/Wheel_RL",attrs:["radius"]}).attrs["radius"];
    ops.push(surface::attr(tether,"inputs:wheel_radius","double",radius.to_string()));
    ops.push(surface::attr(tether,"inputs:balanced_wrap","double","1.0"));
    ops.push(surface::attr(tether,"inputs:tangent_branch","double","-1.0"));
    ops.push(surface::attr(tether,"inputs:routed","double","1.0"));
    for axis in ["x","y","z"] {
        for field in ["inboard","up","lander_omega"] {
            let value=if (field=="inboard" && axis=="x") || (field=="up" && axis=="y") {"1.0"}else{"0.0"};
            ops.push(surface::attr(tether,"inputs:"+field+"_"+axis,"double",value));
        }
        for i in 0..2 {for j in 0..7 {
            ops.push(surface::attr(tether,"inputs:guide"+i+"_"+j+"_"+axis,"double","0.0"));
        }}
    }
    for i in 0..2 {for field in ["wheel_force","wheel_torque"] {for axis in ["x","y","z"] {
        ops.push(surface::attr(tether,"outputs:"+field+i+"_"+axis,"double","0.0"));
    }}}
    ops.push(surface::attr(tether,"inputs:enabled","double","0.0"));
    for i in 0..2 {
        for axis in ["x","y","z"] {
            for prefix in ["span","rover_arm","lander_arm","axis","relative","omega"] {
                ops.push(surface::attr(tether,"inputs:"+prefix+i+"_"+axis,"double","0.0"));
            }
        }
        ops.push(surface::attr(tether,"inputs:rate"+i,"double","0.0"));
    }
    for i in 0..2 {ops.push(surface::attr(tether,"inputs:axis"+i+"_x","double","1.0"));}
    if !existing_observer.prim.exists {
        ops.push(surface::add(root,"CompactEgressObservation","Scope"));
        ops.push(surface::add(observer,"Program","Scope"));
        ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:program,schemas:["LunCoProgramAPI"]}});
    }
    ops.push(surface::attr(program,"info:implementationSource","token","\"sourceAsset\""));
    ops.push(surface::attr(tether,"inputs:payout_speed0","double","0.0"));
    ops.push(surface::attr(tether,"inputs:payout_speed1","double","0.0"));
    ops.push(surface::attr(tether,"inputs:regulate","double","0.0"));
    ops.push(surface::attr(tether,"inputs:body_speed","double","0.0"));
    ops.push(surface::attr(tether,"inputs:body_angular_speed","double","0.0"));
    ops.push(surface::attr(tether,"inputs:angular_govern_enabled","double","0.0"));
    ops.push(surface::attr(tether,"inputs:front_grounded","double","0.0"));
    ops.push(surface::attr(tether,"inputs:governed_angular_speed","double",datum("groundTransferRateRadps").to_string()));
    ops.push(surface::attr(tether,"inputs:payout_stop_angular_speed","double",datum("payoutStopAngularSpeedRadps").to_string()));
    for i in 0..2 {for field in ["material_rate","paid_rate","extension"] {
        ops.push(surface::attr(tether,"outputs:"+field+i,"double","0.0"));
    }}
    ops.push(surface::attr(tether,"inputs:up_vertical","double","1.0"));
    ops.push(surface::attr(tether,"inputs:nose_down_rate","double","0.0"));
    ops.push(surface::attr(tether,"inputs:governed_speed","double",datum("governedDescentSpeedMps").to_string()));
    ops.push(surface::attr(tether,"inputs:payout_stop_speed","double",datum("payoutStopSpeedMps").to_string()));
    ops.push(surface::attr(tether,"outputs:drive_scale","double","1.0"));
    ops.push(surface::attr(program,"info:sourceAsset","asset","@twin://astrobotic-griffin-1/scenarios/griffin_tether_egress.rhai@"));
    ops.push(surface::attr(program,"inputs:verification_mode","bool","false"));
    for output in ["force_x","force_y","force_z","reaction_x","reaction_y","reaction_z",
      "torque_x","torque_y","torque_z","reaction_torque_x","reaction_torque_y","reaction_torque_z",
      "tension0","tension1","length0","length1","elastic_energy","spool_power","damper_power"] {
        ops.push(surface::attr(tether,"outputs:"+output,"double","0.0"));
    }
    #{doc_id:doc,generation:q.generation,ops:ops}
}
