fn w(x) {x.round().to_int().to_string()+" W"}
fn runtime_ui_properties(facts) {
 let out=#{motors:"—",motor_label:"Motors use",equipment:"—",solar:"—",battery:"—",battery_label:"Battery supplying"};
 if facts.surface_id!="drive-power" {return #{};}
 for i in 0..facts.participants.len() {
  let participant=facts.participants[i];let outputs=participant.outputs;
  if outputs["solar_power"]==() || outputs["bus_power"]==() || outputs["equipment_power"]==() {continue;}
  let motors=0.0;let valid=true;
  for side in ["FL","FR","RL","RR"] {let value=outputs["__member_Motor_"+side+"_electrical_power"];if value==() {valid=false;break;}motors+=value;}
  if !valid {continue;}
  out.motor_label=if motors < -0.5 {"Motors return"}else{"Motors use"};out.motors=w(abs(motors));out.equipment=w(outputs["equipment_power"]);out.solar=w(outputs["solar_power"]);out.battery=w(abs(outputs["bus_power"]));out.battery_label=if outputs["bus_power"]>0.0 {"Battery charging"}else{"Battery supplying"};break;
 }
 out
}
