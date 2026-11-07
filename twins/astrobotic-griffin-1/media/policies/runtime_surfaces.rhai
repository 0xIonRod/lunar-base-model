// Twin-owned film surface decisions. Each admitted fact snapshot is evaluated once.
// Helpers receive selected fields; participant/output trees stay in the entry.
fn film_visible(surface, available, status, blockers, mode, owner) {
    if surface == "camera-status" { return true; }
    if status == "compiling" { return true; }
    if blockers != () {
        for blocker in blockers {
            if ["SceneLifecycle", "SceneReferences", "TerrainPreparation", "DocumentPreparation", "ModelicaPreparation", "ScriptPreparation"].contains(blocker.owner) { return true; }
        }
    }
    if !available { return false; }
    if mode == "always" { return true; }
    if mode == "possessed" { return owner == "local"; }
    false
}
fn film_decision(visible, properties) { #{visible: visible, properties: properties} }

fn power_surface(facts) {
 let visible = film_visible(facts.surface_id, facts.available, facts.status,
     facts.simulation_progress, facts.visibility_mode, facts.control_owner);
 if facts.surface_id == "camera-status" {
     return film_decision(visible, #{active_name: facts.active_name, active_label: facts.active_label});
 }
 if facts.surface_id!="film-motor" && facts.surface_id!="film-solar" {return film_decision(visible, #{});}
 for index in 0..facts.participants.len() {

  let p=if facts.surface_id=="film-motor" {facts.participants[index].outputs["__member_Motor_FL_electrical_power"]}else{facts.participants[index].outputs["solar_power"]};
  if p==() {continue;}
  let label=if facts.surface_id=="film-motor" {if p < -0.5 {"Front motor returns"}else{"Front motor uses"}}else{"Solar panel produces"};
  return film_decision(visible, #{label:label,value:abs(p).round().to_int().to_string()+" W"});
 }
 film_decision(visible, #{label:"Waiting for measurement",value:"—"})
}

fn route_energy_number(v) {let n=(v*10.0).round()/10.0;if abs(n)<0.05 {n=0.0;}n.to_string()}
fn route_energy_surface(facts) {
 let visible = film_visible(facts.surface_id, facts.available, facts.status,
     facts.simulation_progress, facts.visibility_mode, facts.control_owner);
 if facts.surface_id == "camera-status" {
     return film_decision(visible, #{active_name: facts.active_name, active_label: facts.active_label});
 }
 if facts.surface_id!="route-short" && facts.surface_id!="route-long" {return film_decision(visible, #{});}
 let blue=facts.surface_id=="route-short";
 for index in 0..facts.participants.len() {
 if facts.participants[index].outputs["energy_Battery_wh"]==() {continue;}
 for name in ["energy_Battery_returned_wh","energy_elapsed_s","energy_Solar_wh","energy_Equipment_wh","energy_FL_wh","energy_FR_wh","energy_RL_wh","energy_RR_wh","energy_FL_returned_wh","energy_FR_returned_wh","energy_RL_returned_wh","energy_RR_returned_wh"] {if facts.participants[index].outputs[name]==() {throw "Route HUD is missing native meter: "+name;}}
 let net=facts.participants[index].outputs.energy_Battery_wh-facts.participants[index].outputs.energy_Battery_returned_wh;
 let used=facts.participants[index].outputs.energy_Equipment_wh;for side in ["FL","FR","RL","RR"] {used+=facts.participants[index].outputs["energy_"+side+"_wh"]-facts.participants[index].outputs["energy_"+side+"_returned_wh"];}
 let sec=facts.participants[index].outputs.energy_elapsed_s.round().to_int();
 let out=#{};out.title=if blue {"Blue · short"}else{"Yellow · long"};
 out.solar=route_energy_number(facts.participants[index].outputs.energy_Solar_wh);out.used=route_energy_number(used);out.balance=route_energy_number(net);if net>0.05 {out.balance="+"+out.balance;}
 out.elapsed=(sec/60).to_string()+"m "+(sec%60).to_string()+"s · Wh";
 out.case_color=if blue {"#45C7FF"}else{"#FFE34D"};out.balance_color=if net>=0.0 {"#74E6B7"}else{"#BCA5FF"};return film_decision(visible, out);
 }
 film_decision(visible, #{title:if blue {"Blue · short"}else{"Yellow · long"},solar:"—",used:"—",balance:"—",elapsed:"Loading",case_color:"#FFFFFF",balance_color:"#FFFFFF"})
}

// This policy formats authoritative Modelica state for retained native UI.
fn route_drive_fmt(x) {((x*100.0).round()/100.0).to_string()}
fn route_drive_watts(x) {x.round().to_int().to_string()+" W"}
fn route_drive_drive_label(throttle, steer, heading) {
 if throttle==() || steer==() {return "";}
 if heading!=() && abs(heading)>0.2 && abs(steer)>0.001 {return "Turning";}
 if throttle < -0.001 {return "Reverse";}
 if throttle > 0.001 {return "Forward";}
 if abs(steer)>0.001 {return "Turning";}
 "Hold"
}
fn route_drive_surface(facts) {
 let visible = film_visible(facts.surface_id, facts.available, facts.status,
     facts.simulation_progress, facts.visibility_mode, facts.control_owner);
 if facts.surface_id == "camera-status" {
     return film_decision(visible, #{active_name: facts.active_name, active_label: facts.active_label});
 }
 let out=#{title:if facts.surface_id=="energy-amber" {"YELLOW · LONG ROUTE"} else {"BLUE · SHORT ROUTE"},case_color:if facts.surface_id=="energy-amber" {"#FFAA40"}else{"#38BDFF"},collected:"—",used:"—",balance:"—",charge:"—",current:"Preparing power measurements",elapsed:"0m 0s",solar_width:"0px",used_width:"0px",balance_color:"#b7a3ff"};
 if !facts.surface_id.starts_with("energy-") {return film_decision(visible, #{});}
 for i in 0..facts.participants.len() {

  if facts.participants[i].outputs["energy_Solar_wh"]==() {continue;}
  let solar=facts.participants[i].outputs["energy_Solar_wh"];
  let used=0.0;let recovered=0.0;let demand=0.0;let valid=true;
  for side in ["FL","FR","RL","RR"] {
   let value=facts.participants[i].outputs["energy_"+side+"_wh"];
   let back=facts.participants[i].outputs["energy_"+side+"_returned_wh"];
   let power=facts.participants[i].outputs["__member_Motor_"+side+"_electrical_power"];
   if value==() || back==() || power==() {valid=false;break;}
   used+=value;recovered+=back;demand+=power;
  }
  let solar_w=facts.participants[i].outputs["solar_power"];let soc=facts.participants[i].outputs["battery_soc"];let elapsed=facts.participants[i].outputs["energy_elapsed_s"];
  if !valid || solar_w==() || soc==() || elapsed==() {continue;}
  let equipment=facts.participants[i].outputs["energy_Equipment_wh"];let charged=facts.participants[i].outputs["energy_Battery_wh"];let discharged=facts.participants[i].outputs["energy_Battery_returned_wh"];let battery_w=facts.participants[i].outputs["bus_power"];let equipment_w=facts.participants[i].outputs["equipment_power"];
  if equipment==() || charged==() || discharged==() || battery_w==() || equipment_w==() {continue;}
  let net=charged-discharged;used+=equipment-recovered;
  out.collected=route_drive_fmt(solar)+" Wh";out.used=route_drive_fmt(used)+" Wh";out.balance=if net>=0.0 {"+"+route_drive_fmt(net)+" Wh"}else{route_drive_fmt(net)+" Wh"};
  out.charge=route_drive_fmt(soc*100.0)+"%";out.current="Solar "+route_drive_watts(solar_w)+" · Motors "+route_drive_watts(demand)+" · Other "+route_drive_watts(equipment_w)+" · Battery "+route_drive_watts(battery_w);
  let seconds=elapsed.round().to_int();out.elapsed=(seconds/60).to_string()+"m "+(seconds%60).to_string()+"s";
  let mode=route_drive_drive_label(facts.participants[i].outputs["__member_Drivetrain_guidance_throttle"], facts.participants[i].outputs["__member_Drivetrain_guidance_steer"], facts.participants[i].outputs["__member_Drivetrain_guidance_heading_error"]);
  if mode!="" {out.elapsed+=" · "+mode;}
  out.solar_width=(min(solar,50.0)/50.0*170.0).to_string()+"px";out.used_width=(min(used,50.0)/50.0*170.0).to_string()+"px";
  out.balance_color=if net>=0.0 {"#79edaf"}else{"#b7a3ff"};
  break;
 }
 film_decision(visible, out)
}

fn route_balance_surface(facts) {
 let visible = film_visible(facts.surface_id, facts.available, facts.status,
     facts.simulation_progress, facts.visibility_mode, facts.control_owner);
 if facts.surface_id == "camera-status" {
     return film_decision(visible, #{active_name: facts.active_name, active_label: facts.active_label});
 }
 if facts.surface_id!="route-short" && facts.surface_id!="route-long" {return film_decision(visible, #{});}
 let out=#{title:if facts.surface_id=="route-short" {"Short route"}else{"Long route"},balance:"—",elapsed:"—",case_color:if facts.surface_id=="route-short" {"#45C7FF"}else{"#FFE34D"},balance_width:"0px"};
 for index in 0..facts.participants.len() {
  if facts.participants[index].outputs["energy_Battery_wh"]==() || facts.participants[index].outputs["energy_Battery_returned_wh"]==() || facts.participants[index].outputs["energy_elapsed_s"]==() {continue;}
  let net=facts.participants[index].outputs["energy_Battery_wh"]-facts.participants[index].outputs["energy_Battery_returned_wh"];
  let v=(net*10.0).round()/10.0;if abs(v)<0.05 {v=0.0;}
  out.balance=(if v>0.0 {"+"}else{""})+v.to_string()+" Wh";
  let sec=facts.participants[index].outputs["energy_elapsed_s"].round().to_int();out.elapsed=(sec/60).to_string()+"m "+(sec%60).to_string()+"s";
  out.balance_width=(max(0.0,min(10.0,net))/10.0*572.0).to_string()+"px";return film_decision(visible, out);
 }
 film_decision(visible, out)
}

fn drive_power_w(x) {x.round().to_int().to_string()+" W"}
fn drive_power_surface(facts) {
 let visible = film_visible(facts.surface_id, facts.available, facts.status,
     facts.simulation_progress, facts.visibility_mode, facts.control_owner);
 if facts.surface_id == "camera-status" {
     return film_decision(visible, #{active_name: facts.active_name, active_label: facts.active_label});
 }
 let out=#{motors:"—",motor_label:"Motors use",equipment:"—",solar:"—",battery:"—",battery_label:"Battery supplying"};
 if facts.surface_id!="drive-power" {return film_decision(visible, #{});}
 for i in 0..facts.participants.len() {

  if facts.participants[i].outputs["solar_power"]==() || facts.participants[i].outputs["bus_power"]==() || facts.participants[i].outputs["equipment_power"]==() {continue;}
  let motors=0.0;let valid=true;
  for side in ["FL","FR","RL","RR"] {let value=facts.participants[i].outputs["__member_Motor_"+side+"_electrical_power"];if value==() {valid=false;break;}motors+=value;}
  if !valid {continue;}
  out.motor_label=if motors < -0.5 {"Motors return"}else{"Motors use"};out.motors=drive_power_w(abs(motors));out.equipment=drive_power_w(facts.participants[i].outputs["equipment_power"]);out.solar=drive_power_w(facts.participants[i].outputs["solar_power"]);out.battery=drive_power_w(abs(facts.participants[i].outputs["bus_power"]));out.battery_label=if facts.participants[i].outputs["bus_power"]>0.0 {"Battery charging"}else{"Battery supplying"};break;
 }
 film_decision(visible, out)
}

// This policy formats authoritative Modelica state for retained native UI.
fn route_dual_fmt(x) {((x*100.0).round()/100.0).to_string()}
fn route_dual_watts(x) {x.round().to_int().to_string()+" W"}
fn route_dual_drive_label(throttle, steer, heading) {
 if throttle==() || steer==() {return "";}
 if heading!=() && abs(heading)>0.2 && abs(steer)>0.001 {return "Turning";}
 if throttle < -0.001 {return "Reverse";}
 if throttle > 0.001 {return "Forward";}
 if abs(steer)>0.001 {return "Turning";}
 "Hold"
}
fn route_dual_surface(facts) {
 let visible = film_visible(facts.surface_id, facts.available, facts.status,
     facts.simulation_progress, facts.visibility_mode, facts.control_owner);
 if facts.surface_id == "camera-status" {
     return film_decision(visible, #{active_name: facts.active_name, active_label: facts.active_label});
 }
 let out=#{title:if facts.surface_id=="energy-amber" {"AMBER · ZIGZAG"} else {"BLUE · DIRECT"},case_color:if facts.surface_id=="energy-amber" {"#FFAA40"}else{"#38BDFF"},collected:"—",used:"—",balance:"—",charge:"—",current:"Preparing power measurements",elapsed:"0m 0s",solar_width:"0px",used_width:"0px",balance_color:"#b7a3ff"};
 if !facts.surface_id.starts_with("energy-") {return film_decision(visible, #{});}
 for i in 0..facts.participants.len() {

  if facts.participants[i].outputs["energy_Solar_wh"]==() {continue;}
  let solar=facts.participants[i].outputs["energy_Solar_wh"];
  let used=0.0;let recovered=0.0;let demand=0.0;let valid=true;
  for side in ["FL","FR","RL","RR"] {
   let value=facts.participants[i].outputs["energy_"+side+"_wh"];
   let back=facts.participants[i].outputs["energy_"+side+"_returned_wh"];
   let power=facts.participants[i].outputs["__member_Motor_"+side+"_electrical_power"];
   if value==() || back==() || power==() {valid=false;break;}
   used+=value;recovered+=back;demand+=power;
  }
  let solar_w=facts.participants[i].outputs["solar_power"];let soc=facts.participants[i].outputs["battery_soc"];let elapsed=facts.participants[i].outputs["energy_elapsed_s"];
  if !valid || solar_w==() || soc==() || elapsed==() {continue;}
  let equipment=facts.participants[i].outputs["energy_Equipment_wh"];let charged=facts.participants[i].outputs["energy_Battery_wh"];let discharged=facts.participants[i].outputs["energy_Battery_returned_wh"];let battery_w=facts.participants[i].outputs["bus_power"];let equipment_w=facts.participants[i].outputs["equipment_power"];
  if equipment==() || charged==() || discharged==() || battery_w==() || equipment_w==() {continue;}
  let net=charged-discharged;used+=equipment-recovered;
  out.collected=route_dual_fmt(solar)+" Wh";out.used=route_dual_fmt(used)+" Wh";out.balance=if net>=0.0 {"+"+route_dual_fmt(net)+" Wh"}else{route_dual_fmt(net)+" Wh"};
  out.charge=route_dual_fmt(soc*100.0)+"%";out.current="Solar "+route_dual_watts(solar_w)+" · Motors "+route_dual_watts(demand)+" · Other "+route_dual_watts(equipment_w)+" · Battery "+route_dual_watts(battery_w);
  let seconds=elapsed.round().to_int();out.elapsed=(seconds/60).to_string()+"m "+(seconds%60).to_string()+"s";
  let mode=route_dual_drive_label(facts.participants[i].outputs["__member_Drivetrain_guidance_throttle"], facts.participants[i].outputs["__member_Drivetrain_guidance_steer"], facts.participants[i].outputs["__member_Drivetrain_guidance_heading_error"]);
  if mode!="" {out.elapsed+=" · "+mode;}
  out.solar_width=(min(solar,50.0)/50.0*170.0).to_string()+"px";out.used_width=(min(used,50.0)/50.0*170.0).to_string()+"px";
  out.balance_color=if net>=0.0 {"#79edaf"}else{"#b7a3ff"};
  break;
 }
 film_decision(visible, out)
}
