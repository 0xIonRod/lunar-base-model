// @timing presentation
// Episode capture policy only. Native physics and Modelica own vehicle motion.
const ROOT="/Griffin1SurfaceOps";
fn on_start(me,ctx) {
 cmd("StepSimulation",#{hold:true});
 this.phase=0;this.previous_image= -1;this.finished_frame=();this.panel_start=();this.panel_end=();
 subscribe("griffin_powered_descent_started");
 subscribe("route-comparison-finished");
 set_twin_setting("ui.camera_status",false);
 set_twin_setting("ui.vehicle_controls",false);
 set_twin_setting("ui.mission_notifications",false);
 for name in ["FLIP","FLIP_Amber"] {
  clear_guided_hud_actions("flip-panel:"+ROOT+"/"+name);
  clear_hint("flip-panel:"+ROOT+"/"+name);
 }
 clear_guided_hud_actions("griffin-controls");
 clear_hint("griffin-controls");objectives_hud("griffin-controls",[]);
}
fn on_event(me,event,ctx) {
 if this.phase==0 {return;}
 if event.name=="griffin_powered_descent_started" {
  cmd("SetUserCamera",#{name:this.config.camera});
 }
 if event.name=="route-comparison-finished" && this.config.scene=="routes" {
  this.finished_frame=query("GetOfflineRecordingStatus",#{}).frame_index.to_int();
  cmd("StepSimulation",#{hold:true});
  cmd("SetUserCamera",#{name:"ResultView"});
  cmd("CameraPathTransport",#{path:ROOT+"/ResultOrbit",action:"Rewind"});
  cmd("CameraPathTransport",#{path:ROOT+"/ResultOrbit",action:"Play"});
 }
}
fn is_ready(me) {query("GetReadiness",#{}).ready}
fn configure(me) {
 let q=query("QueryUsdPrim",#{path:ROOT+"/V24Capture",attrs:["film:scene","film:frames","film:pre_steps","film:camera","film:rate","film:clock_scale"]});
 this.doc=q.doc_id;this.config=#{};
 for key in ["scene","frames","pre_steps","camera","rate","clock_scale"] {
  let value=q.attrs["film:"+key];
  if value==() {throw "Missing V24 capture input: "+key;}
  this.config[key]=value;
 }
 if this.config.frames<2 || this.config.pre_steps<0 || this.config.rate<=0.0 || this.config.clock_scale<=0.0 {throw "Invalid V24 capture budget";}

}
fn flight_scene() {["opening","landing","payload","leg","ground-landing"].contains(this.config.scene)}
fn mass_ready(me) {
 if !this.flight_scene() {return true;}
 griffin_surface_ops::guidance_assembly_mass_report().ready==true
}
fn admit_guidance(me) {
 if this.flight_scene() {
  let geometry=griffin_requirements::landing_setup_geometry_check((),ROOT+"/LandingTarget",ROOT+"/Lander");
  if geometry.ok!=true {throw "V24 landing geometry rejected: "+geometry;}
  let mass=griffin_surface_ops::guidance_assembly_mass_report();
  if mass.ok!=true {throw "V24 guidance mass rejected: "+mass;}
  let arm=griffin_surface_ops::arm_descent_guidance();
  if arm.ok!=true {throw "V24 native guidance arming rejected: "+arm;}
  print("V24_GUIDANCE_PREFLIGHT|"+this.config.scene+"|"+mass+"|"+arm);
 }
 if this.config.scene=="sun" {
  cmd("SetPorts",#{target:find_path(ROOT+"/FLIP"),writes:[["program_active",1.0],["autopilot_enable",0.0],["throttle",0.0],["steer",0.0],["brake",1.0]]});
 }
 if this.config.pre_steps>0 {cmd("StepSimulation",#{hold:true,steps:this.config.pre_steps});}
}
fn publish_mass(me) {if this.flight_scene() {cmd("StepSimulation",#{hold:true,steps:4});}}
fn prepared(me) {query("GetReadiness",#{}).ready && clock_snapshot().queued_simulation_steps==0}
fn camera(me) {
 cmd("SetUserCamera",#{name:this.config.camera});
 cmd("SetCelestialClock",#{epoch_jd:2461419.5,scale:1.0});
 if this.config.scene=="sun" {
  let rover=find_path(ROOT+"/FLIP");let p=world_pos(rover);
  let normal=qrot(world_rotation_quat(find_path(ROOT+"/FLIP/SolarMechanism/Photovoltaics")),vec3(0.0,1.0,0.0));
  cmd("SetCameraLookAt",#{camera:find_path(ROOT+"/Avatar"),eye:[p[0]+7.0*normal.x+3.0,p[1]+5.5,p[2]+7.0*normal.z+3.0],target:[p[0],p[1]+0.7,p[2]]});
 }
 print("V24_CAPTURE_READY|"+this.config.scene+"|"+clock_snapshot().sim_tick);
}
fn first_image_saved(me) {
 let status=query("GetOfflineRecordingStatus",#{});
 status.active && status.frame_index>=1 && status.last_capture_sim_tick!=()
}
fn release(me) {
 if this.config.scene=="sun" {
  cmd("PauseSimulationObject",#{target:find_path(ROOT+"/FLIP"),condition:"lunar-day-illumination-pose-hold",detail:"Settled braked rover pose held for changing celestial illumination only; not a dynamics or battery result."});
 }
 cmd("SetTimeTransport",#{playing:true,rate:this.config.rate});
 cmd("StepSimulation",#{hold:false});
 if this.config.scene=="mechanisms" || this.config.scene=="sun" {
  cmd("SetPorts",#{target:find_path(ROOT+"/FLIP"),writes:[["program_active",1.0],["autopilot_enable",0.0],["throttle",0.0],["steer",0.0],["brake",1.0]]});
 }
 this.phase=1;
}
fn record_sample(f) {
 if this.config.scene=="opening" || this.config.scene=="landing" || this.config.scene=="leg" || this.config.scene=="payload" || this.config.scene=="drop-low" || this.config.scene=="drop-high" {
  let p=query("ReadPorts",#{api_id:find_path(ROOT+"/Lander"),port_names:["any_leg_contact","leg_force_px","leg_force_nx","leg_force_pz","leg_force_nz"]});
  let values=#{};for v in p.ports {values[v.name]=v.value;}let line="V24_LANDING|"+f+"|"+clock_snapshot().sim_tick;for name in ["any_leg_contact","leg_force_px","leg_force_nx","leg_force_pz","leg_force_nz"] {let v=values[name];if v==() || !v.is_finite() {throw "Missing native landing observation: "+name;}line+="|"+v;}let state=query("QueryPhysicsState",#{id:find_path(ROOT+"/Lander")});line+="|"+state.linear_velocity_mps[1]+"|"+world_pos(find_path(ROOT+"/Lander"))[1];
  if this.config.scene=="drop-low" || this.config.scene=="drop-high" {
   let thrust=query("ReadPorts",#{api_id:find_path(ROOT+"/Lander/MainPropulsion"),port_names:["engine01_thrust_n","engine02_thrust_n","engine03_thrust_n","engine04_thrust_n","engine05_thrust_n","engine06_thrust_n","engine07_thrust_n"]});let total=0.0;for port in thrust.ports {if !port.value.is_finite() {throw "Invalid engine-off thrust observation";}total+=abs(port.value);}if total>0.01 {throw "Controlled drop has nonzero thrust";}line+="|"+total;
  }
  print(line);
  if this.flight_scene() {
   let gnc=query("ReadPorts",#{api_id:find_path(ROOT+"/Lander/GNC"),port_names:["measured_altitude","throttle_cmd"]});
   if gnc.ports==() {throw "Native guidance observation unavailable: "+gnc;}
   let values=#{};for port in gnc.ports {values[port.name]=port.value;}
   print("V24_GNC|"+f+"|"+clock_snapshot().sim_tick+"|"+values.measured_altitude+"|"+values.throttle_cmd);
  }
 } else if this.config.scene.starts_with("drive") || this.config.scene=="solar" {
  let p=query("ReadPorts",#{api_id:find_path(ROOT+"/FLIP"),port_names:["__member_Motor_FL_electrical_power","solar_power","bus_power","battery_soc","__member_Motor_FL_terminal_current_a","__member_Shaft_FL_speed_rad_s","bus_voltage","battery_net_power","motor_electrical_power","equipment_power"]});
  let values=#{};for v in p.ports {values[v.name]=v.value;}let line="V24_POWER|"+f+"|"+clock_snapshot().sim_tick;for name in ["__member_Motor_FL_electrical_power","solar_power","bus_power","battery_soc","__member_Motor_FL_terminal_current_a","__member_Shaft_FL_speed_rad_s","bus_voltage","battery_net_power","motor_electrical_power","equipment_power"] {let v=values[name];if v==() || !v.is_finite() {throw "Missing native power observation: "+name;}line+="|"+v;}print(line);
 }
}
fn sample(me) {
 let status=query("GetOfflineRecordingStatus",#{});
 if status.failure!=() {throw status.failure.to_string();}
 if !status.active {throw "V24 recorder stopped before its frame budget";}
 let frame=status.frame_index.to_int();
 let image=if status.is_waiting_for_frame {frame}else{frame-1};
 if image>=0 && image!=this.previous_image {
  print("V24_IMAGE|"+this.config.scene+"|"+image+"|"+status.last_capture_sim_tick);

 if this.config.scene=="mechanisms" {
  let rover=find_path(ROOT+"/FLIP");
  if frame==15 {
   let config=query("QueryUsdPrim",#{path:ROOT+"/FLIP/PanelControls",attrs:["inputs:open_angle_deg"]});
   let target=config.attrs["inputs:open_angle_deg"];
   if target==() || !target.is_finite() || target<=0.0 || target>90.0 {throw "Invalid authored solar deployment target";}
   let result=cmd("SetPorts",#{target:find_path(ROOT+"/FLIP/SolarMechanism/Controller"),writes:[["command_deg",target]]});
   if result.ok!=true {throw "Solar deployment command rejected";}
  }
  if frame==360 {
   cmd("SetUserCamera",#{name:"WheelRollingView"});
   cmd("SetPorts",#{target:rover,writes:[["throttle",0.10],["steer",0.0],["brake",0.0]]});
  }
  if frame==600 {cmd("SetUserCamera",#{name:"PanelHero"});}
  if frame==780 {cmd("SetUserCamera",#{name:"MastForwardCamera"});}
  if frame==900 {cmd("SetPorts",#{target:rover,writes:[["throttle",0.0],["brake",1.0]]});}
  if frame%15==0 {
   let panel=query("ReadPorts",#{api_id:find_path(ROOT+"/FLIP/SolarMechanism/Controller"),port_names:["deployment_deg"]}).ports[0].value;
   let state=query("QueryPhysicsState",#{id:rover});
   if this.panel_start==() {this.panel_start=panel;}
   this.panel_end=panel;
   print("MECHANISM_SAMPLE|"+frame+"|"+status.last_capture_sim_tick+"|"+panel+"|"+state.linear_velocity_mps+"|"+world_pos(rover));
  }
 }

  if this.config.scene=="sun" {
   let day_image=image-15;
   if image==14 {cmd("SetCelestialClock",#{epoch_jd:2461419.5,scale:82142.857142857});}
   if day_image>=419 && day_image<443 {
   let f=(day_image-419).to_float();
   let seconds=1150000.0+f*52083.333333333;
   let date=2461419.5+seconds/86400.0;
   cmd("SetCelestialClock",#{scale:100000.0,epoch_jd:date});
  }
   if day_image==443 {cmd("SetCelestialClock",#{scale:38333.333333333,epoch_jd:2461447.277777778});}
  }
  this.record_sample(image);
  this.previous_image=image;
  if this.config.scene=="landing" {
   if image==302 {cmd("SetUserCamera",#{name:"GroundEngines"});}
   if image==492 {cmd("SetUserCamera",#{name:"GroundTouchdown"});}
  }
 }
}
fn finished(me) {
 let frame=query("GetOfflineRecordingStatus",#{}).frame_index.to_int();
 if this.finished_frame!=() {return frame>=this.finished_frame+540;}
 frame>=this.config.frames
}
fn finish(me) {
 if this.config.scene=="routes" && this.finished_frame==() {throw "V24 route comparison did not reach its native parked result";}
 if this.config.scene=="mechanisms" {
  if this.panel_start==() || abs(this.panel_start)>0.1 || this.panel_end<81.9 {throw "Incomplete native panel deployment evidence";}
  print("V24_MECHANISM_DEPLOYMENT_PASS|"+this.panel_start+"|"+this.panel_end);
 }
 let saved_count=query("GetOfflineRecordingStatus",#{}).frame_index;
 cmd("StepSimulation",#{hold:true});
 print("V24_CAPTURE_COMPLETE|"+this.config.scene+"|"+saved_count+"|"+clock_snapshot().sim_tick);
 cmd("StopOfflineRecording",#{});
 cmd("SetCelestialClock",#{scale:1.0});
}
fn task(me,ctx) {
 seq([wait_until(Fn("is_ready")),once(Fn("configure")),once(Fn("publish_mass")),wait_until(Fn("prepared")),wait_until(Fn("mass_ready")),once(Fn("admit_guidance")),wait_until(Fn("prepared")),once(Fn("camera")),
      wait_until(Fn("first_image_saved")),once(Fn("release")),
      #{kind:"step",act:Fn("sample"),done:Fn("finished")},once(Fn("finish"))])
}
