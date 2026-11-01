// This policy formats authoritative Modelica state for retained native UI.
fn fmt(x) {((x*100.0).round()/100.0).to_string()}
fn watts(x) {x.round().to_int().to_string()+" W"}
fn runtime_ui_properties(facts) {
 let out=#{title:if facts.surface_id=="energy-amber" {"AMBER · ANGLED"} else {"BLUE · DIRECT"},case_color:if facts.surface_id=="energy-amber" {"#FFAA40"}else{"#38BDFF"},collected:"—",used:"—",balance:"—",charge:"—",current:"Preparing power measurements",elapsed:"0m 0s",solar_width:"0px",used_width:"0px",balance_color:"#b7a3ff"};
 if !facts.surface_id.starts_with("energy-") {return #{};}
 for i in 0..facts.participants.len() {
  let participant=facts.participants[i];let outputs=participant.outputs;
  if outputs["energy_Solar_wh"]==() {continue;}
  let solar=outputs["energy_Solar_wh"];
  let used=0.0;let recovered=0.0;let demand=0.0;let valid=true;
  for side in ["FL","FR","RL","RR"] {
   let value=outputs["energy_"+side+"_wh"];
   let back=outputs["energy_"+side+"_returned_wh"];
   let power=outputs["__member_Motor_"+side+"_electrical_power"];
   if value==() || back==() || power==() {valid=false;break;}
   used+=value;recovered+=back;demand+=power;
  }
  let solar_w=outputs["solar_power"];let soc=outputs["battery_soc"];let elapsed=outputs["energy_elapsed_s"];
  if !valid || solar_w==() || soc==() || elapsed==() {continue;}
  let equipment=outputs["energy_Equipment_wh"];let charged=outputs["energy_Battery_wh"];let discharged=outputs["energy_Battery_returned_wh"];let battery_w=outputs["bus_power"];let equipment_w=outputs["equipment_power"];
  if equipment==() || charged==() || discharged==() || battery_w==() || equipment_w==() {continue;}
  let net=charged-discharged;used+=equipment-recovered;
  out.collected=fmt(solar)+" Wh";out.used=fmt(used)+" Wh";out.balance=if net>=0.0 {"+"+fmt(net)+" Wh"}else{fmt(net)+" Wh"};
  out.charge=fmt(soc*100.0)+"%";out.current="Solar "+watts(solar_w)+" · Motors "+watts(demand)+" · Other "+watts(equipment_w)+" · Battery "+watts(battery_w);
  let seconds=elapsed.round().to_int();out.elapsed=(seconds/60).to_string()+"m "+(seconds%60).to_string()+"s";
  out.solar_width=(min(solar,50.0)/50.0*170.0).to_string()+"px";out.used_width=(min(used,50.0)/50.0*170.0).to_string()+"px";
  out.balance_color=if net>=0.0 {"#79edaf"}else{"#b7a3ff"};
  break;
 }
 out
}
