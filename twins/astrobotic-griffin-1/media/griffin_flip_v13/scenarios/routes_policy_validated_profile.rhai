// Two independent native vehicles: mission targets and parking policy, with measured acceptance.
const ROOT="/Griffin1SurfaceOps";
fn simulation_dependencies(me,ctx) {
 let a=find_path(ROOT+"/FLIP");let b=find_path(ROOT+"/FLIP_Amber");
 #{modelica_entities:[a,b],entity_reads:[a,b,find_path(ROOT+"/FLIP/SolarMechanism/Photovoltaics"),find_path(ROOT+"/FLIP_Amber/SolarMechanism/Photovoltaics"),find_path(ROOT+"/FlipRoute/P2"),find_path(ROOT+"/AmberRoute/P2")],entity_writes:[a,b],query_reads:["QueryPhysicsState","QueryUsdPrim","GetOfflineRecordingStatus"],required_inputs:[]}
}
fn clean_view() {
 set_twin_setting("ui.camera_status",false);set_twin_setting("ui.vehicle_controls",false);set_twin_setting("ui.mission_notifications",false);
 for p in [ROOT+"/FLIP",ROOT+"/FLIP_Amber"] {clear_guided_hud_actions("flip-panel:"+p);clear_hint("flip-panel:"+p);}
 clear_guided_hud_actions("griffin-controls");clear_hint("griffin-controls");objectives_hud("griffin-controls",[]);
}
fn on_start(me,ctx) {
 if !set_physics_substeps(32) || !set_physics_joint_velocity_iterations(128) {throw "Native contact solver quality rejected";}
 print("PHYSICS_PROFILE|"+physics_substeps()+"|"+physics_joint_velocity_iterations()+"|"+solver_configuration_fingerprint());
 for p in [ROOT+"/FLIP",ROOT+"/FLIP_Amber"] {cmd("SetPorts",#{target:find_path(p),writes:[["program_active",1.0],["autopilot_enable",0.0],["throttle",0.0],["steer",0.0],["brake",1.0]]});}
 this.alignment_gate_ok=true;this.stop_started=();this.crossover=();this.cases=[];this.measuring=false;this.done=false;this.valid=true;this.equal_start=false;this.contact_free=true;this.ground_seen=[false,false];this.blue_bodies=[];
 for item in [["blue","FLIP","FlipRoute"],["amber","FLIP_Amber","AmberRoute"]] {
  this.cases.push(#{name:item[0],rover:find_path(ROOT+"/"+item[1]),route:find_path(ROOT+"/"+item[2]),started:false,route_completed:false,stage:0,completed:false,reported:false,failed:false,park_pose:(),park_drift:0.0,peak_speed:0.0,peak_yaw_rate:0.0,previous:(),motor_wh:0.0,motor_phases:#{turn:0.0,drive:0.0,hold:0.0},regen_wh:0.0,solar_wh:0.0,equipment_wh:0.0,battery_wh:0.0,distance:0.0,peak:0.0,minimum_up:1.0,minimum_solar_cosine:1.0,maximum_solar_cosine_error:0.0,drive_direction:1.0,reverse_distance:0.0,samples:0});
 }
 // These six admitted collider owners are retained in rover-topology.json.
 this.blue_bodies=[ROOT+"/FLIP",ROOT+"/FLIP/SolarMechanism"];
 for side in ["FL","FR","RL","RR"] {this.blue_bodies.push(ROOT+"/FLIP/Suspension_"+side+"/Wheel_"+side);}
 cmd("SetCameraLookAt",#{camera:find_path(ROOT+"/Avatar"),eye:[-16.46215333887149, 49.230282748857086, -39.63182421474647],target:[-7.9558111948738635, -0.7697172511429119, -12.288778602941452]});clean_view();cmd("StepSimulation",#{hold:true});cmd("SetTimeTransport",#{playing:true,rate:1.0});
}
fn on_event(me,evt,ctx) {
 for i in 0..this.cases.len() {
  let s=this.cases[i];
  if evt.source!=s.route {continue;}
  if evt.name=="route_leg_started" {s.drive_direction=evt.value.direction;print("ROUTE_LEG|"+s.name+"|"+shot_frame()+"|"+evt.value.point+"|"+evt.value.direction);}
  if evt.name=="route_started" {s.started=true;}
  if evt.name=="route_completed" {s.route_completed=true;}
  this.cases[i]=s;
 }
}
fn start_dual(me) {
 this.start_s=elapsed_seconds();this.measuring=true;
 for i in 0..this.cases.len() {
  let s=this.cases[i];let enabled=write_ports(s.rover,[["energy_count_enable",1.0]]);if !enabled.ok {throw "Energy meter enable rejected";}s.start_soc=get(s.rover,"battery_soc");s.minimum_soc=s.start_soc;this.cases[i]=s;
 }
 let a=this.cases[0];let b=this.cases[1];
 this.equal_start=abs(a.start_soc-b.start_soc)<1.0e-10;
 let overlap=contact_debug(a.rover,b.rover);
 print("DUAL_INITIAL_CONTACT|"+overlap.to_string());
 print("DUAL_BEGIN|"+this.start_s+"|"+a.start_soc+"|"+b.start_soc);
 emit("route_start");clean_view();
}
fn motion(rover) {
 let v=velocity3(rover);let yaw=get(rover,"angvel_y");
 if v==() || yaw==() {throw "Native rover velocity is unavailable";}
 #{speed:vlen(v),yaw:abs(yaw)}
}
fn prepare_sun_parking(s) {
 let name=if s.name=="blue" {"FLIP"}else{"FLIP_Amber"};
 let q=world_rotation_quat(find_path(ROOT+"/"+name+"/SolarMechanism/Photovoltaics"));
 let normal=qrot(q,vec3(0.0,1.0,0.0));
 let sun=qrot(q,vec3(port(s.rover,"target_mount_x"),port(s.rover,"target_mount_y"),port(s.rover,"target_mount_z")));
 let angle=atan(normal.z*sun.x-normal.x*sun.z,normal.x*sun.x+normal.z*sun.z);
 let f=world_forward3(s.rover);let p=world_pos(s.rover);
 let dx=cos(angle)*f.x+sin(angle)*f.z;let dz=-sin(angle)*f.x+cos(angle)*f.z;
 let result=modelica_waypoint(s.rover,[p[0]+100.0*dx,p[1],p[2]+100.0*dz],0.12,0.25,1.0);
 if !result.ok {throw "Sun parking heading rejected";}
}
fn service_arrival(s) {
 if !s.route_completed || s.completed || s.failed {return s;}
 let now=elapsed_seconds();let p=world_pos(s.rover);let state=motion(s.rover);
 let speed=state.speed;let yaw=state.yaw;
 let point=find_path(ROOT+if s.name=="blue" {"/FlipRoute/P2"}else{"/AmberRoute/P2"});let goal=world_pos(point);
 let dx=p[0]-goal[0];let dz=p[2]-goal[2];let distance=sqrt(dx*dx+dz*dz);
 if s.stage==0 {
  s.stage=-1;s.stage_started=now;print("ARRIVAL_PHASE|"+s.name+"|release_route|"+now);
 } else if s.stage == -1 && now > s.stage_started && port(s.rover,"program_active") < 0.5 && port(s.rover,"autopilot_enable") < 0.5 {
  // Plan the final heading before arrival: a six-metre straight approach.
  let name=if s.name=="blue" {"FLIP"}else{"FLIP_Amber"};
  let q=world_rotation_quat(find_path(ROOT+"/"+name+"/SolarMechanism/Photovoltaics"));
  let normal=qrot(q,vec3(0.0,1.0,0.0));
  let sun=qrot(q,vec3(port(s.rover,"target_mount_x"),port(s.rover,"target_mount_y"),port(s.rover,"target_mount_z")));
  let angle=atan(normal.z*sun.x-normal.x*sun.z,normal.x*sun.x+normal.z*sun.z);
  let f=world_forward3(s.rover);let dx=cos(angle)*f.x+sin(angle)*f.z;let dz=-sin(angle)*f.x+cos(angle)*f.z;
  s.approach=[goal[0]-6.0*dx,goal[1],goal[2]-6.0*dz];
  let af=world_forward3(s.rover);let approach_speed=if (s.approach[0]-p[0])*af.x+(s.approach[2]-p[2])*af.z<0.0 {-0.18}else{0.18};
  let result=modelica_waypoint(s.rover,s.approach,approach_speed,0.20,0.0);if !result.ok {throw "Parking approach rejected";}
  s.stage=1;s.stage_started=now;print("ARRIVAL_PHASE|"+s.name+"|parking_approach|"+now);
 } else if s.stage==1 && sqrt((p[0]-s.approach[0])*(p[0]-s.approach[0])+(p[2]-s.approach[2])*(p[2]-s.approach[2]))<0.36 {
  let result=modelica_waypoint(s.rover,goal,0.18,0.20,0.0);if !result.ok {throw "Final straight approach rejected";}
  s.stage=2;s.stage_started=now;print("ARRIVAL_PHASE|"+s.name+"|final_straight|"+now);
 } else if s.stage==2 && distance<0.36 {
  let result=modelica_waypoint_stop(s.rover);if !result.ok {throw "Arrival brake rejected";}
  s.stage=4;s.stage_started=now;
 } else if s.stage==3 && get(s.rover,"solar_cos_incidence")>=0.97 && abs(get(s.rover,"__member_Drivetrain_guidance_heading_error"))<0.035 && yaw<0.03 {
  let result=modelica_waypoint_stop(s.rover);if !result.ok {throw "Final heading brake rejected";}
  s.stage=4;s.stage_started=now;
 } else if s.stage==4 && now-s.stage_started>=1.0 && speed<0.02 && yaw<0.03 {
  if get(s.rover,"solar_cos_incidence")<0.97 {
   prepare_sun_parking(s);s.stage=3;s.stage_started=now;print("ARRIVAL_PHASE|"+s.name+"|heading_refinement|"+now);
  } else {
   s.stage=5;s.completed=true;s.park_pose=p;
  }
 }
 if s.completed {s.arrival_error=distance;print("PARK_POSE|"+s.name+"|"+now+"|"+p+"|"+distance+"|"+get(s.rover,"solar_cos_incidence"));}
 if s.stage!=0 && !s.completed && now-s.stage_started>120.0 {s.failed=true;modelica_waypoint_stop(s.rover);print("ARRIVAL_FAILED|"+s.name+"|"+now);}
 s
}
fn finished(me) {
 for i in 0..this.cases.len() {this.cases[i]=service_arrival(this.cases[i]);}
 if this.cases[0].reported && this.cases[1].reported && this.stop_started==() {this.stop_started=elapsed_seconds();print("PARK_BEGIN|"+this.stop_started);cmd("SetTimeTransport",#{playing:true,rate:30.0});}
 this.cases[0].failed || this.cases[1].failed || (this.stop_started!=() && elapsed_seconds()-this.stop_started>=60.0) || elapsed_seconds()-this.start_s>420.0
}
fn finish_dual(me) {
 this.measuring=false;this.done=true;this.native_energy_ok=true;this.energy_closure_ok=true;this.balances=[];
 for s in this.cases {
  let solar=get(s.rover,"energy_Solar_wh");let used=0.0;let returned=0.0;
  for side in ["FL","FR","RL","RR"] {used+=get(s.rover,"energy_"+side+"_wh");returned+=get(s.rover,"energy_"+side+"_returned_wh");}
  let equipment=get(s.rover,"energy_Equipment_wh");
  let balance=get(s.rover,"energy_Battery_wh")-get(s.rover,"energy_Battery_returned_wh");
  this.native_energy_ok=this.native_energy_ok && abs(solar-s.solar_wh)<0.2 && abs(used-s.motor_wh)<0.2 && abs(equipment-s.equipment_wh)<0.2 && abs(balance-s.battery_wh)<0.2;
  this.energy_closure_ok=this.energy_closure_ok && abs(solar+returned-used-equipment-balance)<0.2;
  this.balances.push(balance);
  print("PARK_RESULT|"+s.name+"|"+solar+"|"+used+"|"+returned+"|"+balance+"|"+get(s.rover,"battery_soc")+"|"+equipment);
  print("MOTOR_PHASE_ENERGY|"+s.name+"|"+s.motor_phases.turn+"|"+s.motor_phases.drive+"|"+s.motor_phases.hold);
  print("ENERGY_ACCOUNT|"+s.name+"|received="+solar+"|motors="+used+"|equipment="+equipment+"|recovered="+returned+"|battery="+balance);
 }

 let checks=[t_true(this.alignment_gate_ok,"skid guidance aligns before forward drive"),t_true(this.native_energy_ok,"native energy meters agree with independent sampled integration"),t_true(this.energy_closure_ok,"solar and recovered energy minus motors and equipment matches the battery bus"),t_true(this.balances[1]>this.balances[0],"sun-facing forward/reverse traverse has the better measured energy balance"),t_true(this.contact_free && this.blue_bodies.len()==6,"all six collider owners stay free of cross-copy contact"),t_true(this.ground_seen[0] && this.ground_seen[1],"both copies retain loaded wheel contact with terrain"),t_true(this.valid,"finite native power and pose samples"),t_true(this.equal_start,"identical initial battery state at simultaneous departure")];
 for s in this.cases {print("DRIVING_QUALITY|"+s.name+"|"+s.peak_speed+"|"+s.peak_yaw_rate+"|"+s.park_drift+"|"+s.arrival_error+"|"+s.reverse_distance);checks.push(t_true(s.peak_speed<1.0,s.name+" stays below the conservative one metre per second mission limit"));checks.push(t_true(s.park_drift<0.05,s.name+" holds its parked location within five centimetres"));checks.push(t_true(s.arrival_error<0.45,s.name+" stops at the actual destination"));print("SOLAR_ALIGNMENT_RESULT|"+s.name+"|"+s.minimum_solar_cosine+"|"+s.maximum_solar_cosine_error);if s.name=="amber" {checks.push(t_true(s.minimum_solar_cosine>0.65,"zigzag keeps the solar face towards the light"));checks.push(t_true(s.reverse_distance>15.0,"zigzag includes actual native reverse travel"));}checks.push(t_true(get(s.rover,"solar_cos_incidence")>=0.97,s.name+" uses the same Sun-facing parking condition"));checks.push(t_true(s.maximum_solar_cosine_error<0.035,s.name+" solar measurement follows the physical panel normal and Sun direction"));checks.push(t_true(s.started && s.completed && s.reported,s.name+" native route completed"));checks.push(t_true(s.minimum_up>0.906307787,s.name+" remains upright"));}
 report_verdict(checks,"SIMULTANEOUS ROUTE COMPARISON","DUAL_ROUTE_COMPARISON");cmd("StopOfflineRecording",#{});cmd("StepSimulation",#{hold:true});
 cmd("SetTimeTransport",#{playing:true,rate:1.0});
}
fn task(me,ctx) {seq([wait(3.0),wait(0.25),once(Fn("start_dual")),wait_until(Fn("finished")),once(Fn("finish_dual"))])}
fn on_tick(me,ctx) {
 if this.done {return;}
 for path in this.blue_bodies {
  let contact=contact_debug(find_path(path),this.cases[1].rover);
  if contact==() || contact.touching_pair_count!=0 {this.contact_free=false;}
 }
 for i in 0..2 {
  let body=if i==0 {"FLIP"}else{"FLIP_Amber"};
  let wheel=contact_debug(find_path(ROOT+"/"+body+"/Suspension_FL/Wheel_FL"));
  if wheel!=() && wheel.total_normal_impulse>0.0 {this.ground_seen[i]=true;}
 }
 if !this.measuring {return;}
 let now=elapsed_seconds();let frame=shot_frame();
 for i in 0..this.cases.len() {
  let s=this.cases[i];let solar=get(s.rover,"solar_power");let soc=get(s.rover,"battery_soc");let pose=world_pos(s.rover);let equipment=get(s.rover,"equipment_power");let battery=get(s.rover,"bus_power");let power=0.0;let regen=0.0;let travel=get(s.rover,"__member_Drivetrain_guidance_travel_throttle");let steer=get(s.rover,"__member_Drivetrain_guidance_steer");if travel==() || steer==() {throw "Drive-phase measurements unavailable";}let mode=if abs(travel)>0.001 {"drive"}else if abs(steer)>0.001 {"turn"}else{"hold"};
  for side in ["FL","FR","RL","RR"] {
   let p=get(s.rover,"__member_Motor_"+side+"_electrical_power");
   if p==() || !p.is_finite() {this.valid=false;throw "Motor power unavailable";}
   power+=max(p,0.0);regen+=max(-p,0.0);
  }
  if solar==() || soc==() || pose==() || equipment==() || battery==() || !solar.is_finite() || !soc.is_finite() || !equipment.is_finite() || !battery.is_finite() {this.valid=false;throw "Solar/SOC/pose unavailable";}
  if true {
   if s.previous!=() {
    let step=now-s.previous.time;
    s.motor_wh+=(power+s.previous.power)*0.5*step/3600.0;s.motor_phases[s.previous.mode]+=s.previous.power*0.5*step/3600.0;s.motor_phases[mode]+=power*0.5*step/3600.0;s.regen_wh+=(regen+s.previous.regen)*0.5*step/3600.0;s.solar_wh+=(solar+s.previous.solar)*0.5*step/3600.0;s.equipment_wh+=(equipment+s.previous.equipment)*0.5*step/3600.0;s.battery_wh+=(battery+s.previous.battery)*0.5*step/3600.0;
    let dx=pose[0]-s.previous.pose[0];let dy=pose[1]-s.previous.pose[1];let dz=pose[2]-s.previous.pose[2];let travelled=sqrt(dx*dx+dy*dy+dz*dz);s.distance+=travelled;
    let v=velocity3(s.rover);let f=world_forward3(s.rover);
    if v==() {throw "Native reverse-travel velocity is unavailable";}
    if v.x*f.x+v.y*f.y+v.z*f.z < -0.05 && get(s.rover,"__member_Drivetrain_guidance_travel_throttle")<0.0 {s.reverse_distance+=travelled;}
   }
   s.minimum_soc=min(s.minimum_soc,soc);s.peak=max(s.peak,power);
   let up=world_up3(s.rover);if up==() {this.valid=false;}else{s.minimum_up=min(s.minimum_up,up.y);}
   if s.completed && !s.reported {
    s.reported=true;s.arrival_s=now-this.start_s;s.arrival_soc=soc;
    let row="DUAL_RESULT|"+s.name;
    for v in [s.completed,s.arrival_s,s.distance,s.motor_wh,s.regen_wh,s.solar_wh,s.start_soc,soc,s.minimum_soc,s.peak] {row+="|"+v;}
    print(row);
   }
  }
  let physical=motion(s.rover);
  s.peak_speed=max(s.peak_speed,physical.speed);s.peak_yaw_rate=max(s.peak_yaw_rate,physical.yaw);
  let heading=get(s.rover,"__member_Drivetrain_guidance_heading_error");let throttle=get(s.rover,"__member_Drivetrain_guidance_travel_throttle");
  if heading==() || throttle==() {throw "Native guidance measurements are unavailable";}
  if abs(heading)>0.205 && abs(throttle)>1.0e-7 {this.alignment_gate_ok=false;}
  if s.park_pose!=() {let dx=pose[0]-s.park_pose[0];let dy=pose[1]-s.park_pose[1];let dz=pose[2]-s.park_pose[2];s.park_drift=max(s.park_drift,sqrt(dx*dx+dy*dy+dz*dz));}
  let path=if s.name=="blue" {"FLIP"}else{"FLIP_Amber"};
  let q=world_rotation_quat(find_path(ROOT+"/"+path+"/SolarMechanism/Photovoltaics"));
  let normal=qrot(q,vec3(0.0,1.0,0.0));
  let sun=qrot(q,vec3(port(s.rover,"target_mount_x"),port(s.rover,"target_mount_y"),port(s.rover,"target_mount_z")));
  let raw=normal.x*sun.x+normal.y*sun.y+normal.z*sun.z;let incidence=get(s.rover,"solar_cos_incidence");
  if !s.completed {if abs(throttle)>0.01 && abs(heading)<0.20 {s.minimum_solar_cosine=min(s.minimum_solar_cosine,incidence);}}
  s.maximum_solar_cosine_error=max(s.maximum_solar_cosine_error,abs(incidence-max(0.0,raw)));
  if s.samples%6==0 {print("SOLAR_ALIGNMENT|"+s.name+"|"+frame+"|"+incidence+"|"+raw+"|"+normal.x+"|"+normal.y+"|"+normal.z+"|"+sun.x+"|"+sun.y+"|"+sun.z);}
  s.previous=#{mode:mode,time:now,power:power,regen:regen,solar:solar,equipment:equipment,battery:battery,pose:pose};
  if s.samples%6==0 {let row="DUAL_SAMPLE|"+s.name;for v in [frame,now,pose[0],pose[1],pose[2],power,solar,soc,s.completed,equipment,battery] {row+="|"+v;}print(row);}
  s.samples+=1;this.cases[i]=s;
 }
}
