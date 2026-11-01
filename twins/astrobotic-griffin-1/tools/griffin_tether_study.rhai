import "griffin_tank_finish" as finish;
import "social_surface_finish" as surface;
fn datum(name) {
    let m=sysml_model("twin://astrobotic-griffin-1/requirements/griffin_flip_egress.sysml");
    let v=m.value("GriffinFlipEgressStudy::ControlledDescent::"+name);
    if v==() {throw("Missing controlled-descent study parameter: "+name);}v
}
fn install_plan(doc) {
    let root="/Griffin1SurfaceOps";let t=root+"/EgressTether";
    let q=query("InspectUsdDocument",#{doc_id:doc,path:root});if !q.prim.exists {throw("Open a Griffin mission fixture");}
    let ops=[surface::add(root,"EgressTether","Scope")];
    ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:t,schemas:["LunCoProgramAPI"]}});
    ops.push(surface::attr(t,"info:implementationSource","token","\"sourceAsset\""));
    ops.push(surface::attr(t,"info:sourceAsset","asset","@twin://astrobotic-griffin-1/tests/GriffinTetherPairStudy.mo@"));
    for row in [["stiffness","stiffnessNPerM"],["damping","dampingNsPerM"],["initial_length","initialLengthM"],
      ["payout_speed","payoutSpeedMps"],["payout_extension","payoutExtensionM"],["tension_limit","tensionLimitN"]] {
        ops.push(surface::attr(t,"inputs:"+row[0],"float",datum(row[1]).to_string()));
    }
    ops.push(surface::attr(t,"inputs:enabled","float","0.0"));
    for i in 0..2 {for axis in ["x","y","z"] {for prefix in ["span","rover_arm","lander_arm"] {
        ops.push(surface::attr(t,"inputs:"+prefix+i+"_"+axis,"float","0.0"));
    }}ops.push(surface::attr(t,"inputs:rate"+i,"float","0.0"));}
    for output in ["force_x","force_y","force_z","reaction_x","reaction_y","reaction_z",
      "torque_x","torque_y","torque_z","reaction_torque_x","reaction_torque_y","reaction_torque_z",
      "tension0","tension1","length0","length1","elastic_energy","spool_power","damper_power"] {
        ops.push(surface::attr(t,"outputs:"+output,"float","0.0"));
    }
    for body in ["FLIP","Lander"] {for axis in ["x","y","z"] {
        for quantity in ["force","torque"] {
            let input="inputs:"+quantity+"_"+axis;
            let output=if body=="FLIP" {quantity+"_"+axis}else{if quantity=="force" {"reaction_"+axis}else{"reaction_torque_"+axis}};
            ops.push(surface::attr(root+"/"+body,input,"float","0.0"));
            ops.push(#{SetConnection:#{edit_target:"@root@",path:root+"/"+body,name:input,type_name:"float",sources:[t+".outputs:"+output]}});
        }
    }}
    ops.push(surface::attr(root+"/CompactEgressObservation/Program","info:sourceAsset","asset","@twin://astrobotic-griffin-1/scenarios/tests/griffin_tether_descent.rhai@"));
    #{doc_id:doc,generation:q.generation,ops:ops}
}
