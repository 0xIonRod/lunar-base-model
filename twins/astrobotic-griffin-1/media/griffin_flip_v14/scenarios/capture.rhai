// @timing presentation
// V14 film timing. Physics, electrical response and route verdicts remain native.
const ROOT="/Griffin1SurfaceOps";
fn clean() {
 set_twin_setting("ui.camera_status",false);set_twin_setting("ui.vehicle_controls",false);set_twin_setting("ui.mission_notifications",false);
 for n in ["FLIP","FLIP_Amber"] {clear_guided_hud_actions("flip-panel:"+ROOT+"/"+n);clear_hint("flip-panel:"+ROOT+"/"+n);}
 clear_guided_hud_actions("griffin-controls");clear_hint("griffin-controls");objectives_hud("griffin-controls",[]);
}
fn on_start(me,unused) {cmd("StepSimulation",#{hold:true});this.phase=0;}
fn on_event(me,event,unused) {
 if this.phase<2 || this.phase==9 {return;}
 if event.name=="film-climb-started" && this.config.scene=="drive-slope" {
  cmd("SetUserCamera",#{name:"SlopeWide"});
  cmd("SetTerrainOverlay",#{enabled:true});this.slope_start=shot_frame();
  this.config.rate=1.0;this.previous_tick=();cmd("SetTimeTransport",#{playing:true,rate:1.0});
  print("V14_RATE|"+this.slope_start+"|1.0");
  print("SLOPE_BEGIN|"+this.slope_start);
 }
 if event.name=="film-maneuver-finished" && this.config.scene=="drive-slope" {this.finished=shot_frame();}
 if event.name=="route-comparison-finished" {
  this.finished=shot_frame();cmd("StepSimulation",#{hold:true});
  let hidden=cmd("ApplyUsdOps",#{doc_id:this.doc,label:"Hide the observation inset for the measured result",ops:[#{SetAttribute:#{edit_target:"@runtime@",path:ROOT+"/MissionMoonView",name:"lunco:ui:surfaceId",type_name:"string",value:""}}]});
  if hidden.ok!=true {throw "The result view could not hide its native observation UI";}
  cmd("SetUserCamera",#{name:"ResultView"});
  cmd("CameraPathTransport",#{path:ROOT+"/ResultOrbit",action:"Rewind"});
  cmd("CameraPathTransport",#{path:ROOT+"/ResultOrbit",action:"Play"});
  print("V14_PARKED|"+this.finished+"|"+clock_snapshot().sim_tick);
 }
}
fn record_sample(f) {
 if this.config.scene=="landing" || this.config.scene=="leg" || this.config.scene=="payload" || this.config.scene=="drop-low" || this.config.scene=="drop-high" {
  let p=query("ReadPorts",#{api_id:find_path_in_document(this.doc,ROOT+"/Lander"),port_names:["any_leg_contact","leg_force_px","leg_force_nx","leg_force_pz","leg_force_nz"]});
  let values=#{};for v in p.ports {values[v.name]=v.value;}let line="V14_LANDING|"+f+"|"+clock_snapshot().sim_tick;for name in ["any_leg_contact","leg_force_px","leg_force_nx","leg_force_pz","leg_force_nz"] {let v=values[name];if v==() || !v.is_finite() {throw "Missing native landing observation: "+name;}line+="|"+v;}let state=query("QueryPhysicsState",#{id:find_path_in_document(this.doc,ROOT+"/Lander")});line+="|"+state.linear_velocity_mps[1]+"|"+world_pos(find_path_in_document(this.doc,ROOT+"/Lander"))[1];
  if this.config.scene=="drop-low" || this.config.scene=="drop-high" {
   let thrust=query("ReadPorts",#{api_id:find_path_in_document(this.doc,ROOT+"/Lander/MainPropulsion"),port_names:["engine01_thrust_n","engine02_thrust_n","engine03_thrust_n","engine04_thrust_n","engine05_thrust_n","engine06_thrust_n","engine07_thrust_n"]});let total=0.0;for port in thrust.ports {if !port.value.is_finite() {throw "Invalid engine-off thrust observation";}total+=abs(port.value);}if total>0.01 {throw "Controlled drop has nonzero thrust";}line+="|"+total;
  }
  print(line);
 } else if this.config.scene.starts_with("drive") || this.config.scene=="solar" {
  let p=query("ReadPorts",#{api_id:find_path_in_document(this.doc,ROOT+"/FLIP"),port_names:["__member_Motor_FL_electrical_power","solar_power","bus_power","battery_soc","__member_Motor_FL_terminal_current_a","__member_Shaft_FL_speed_rad_s","bus_voltage","battery_net_power","motor_electrical_power","equipment_power"]});
  let values=#{};for v in p.ports {values[v.name]=v.value;}let line="V14_POWER|"+f+"|"+clock_snapshot().sim_tick;for name in ["__member_Motor_FL_electrical_power","solar_power","bus_power","battery_soc","__member_Motor_FL_terminal_current_a","__member_Shaft_FL_speed_rad_s","bus_voltage","battery_net_power","motor_electrical_power","equipment_power"] {let v=values[name];if v==() || !v.is_finite() {throw "Missing native power observation: "+name;}line+="|"+v;}print(line);
 }
}
fn on_tick(me,unused) {
 if this.phase==9 {return;}
 if this.phase==0 {
  if !query("GetReadiness",#{}).ready {return;}
  let q=query("QueryUsdPrim",#{path:ROOT+"/FilmCapture",attrs:["film:scene","film:output_path","film:frames","film:pre_steps","film:rate","film:preroll_frames","film:postroll_frames","film:camera","film:clock_scale","film:slope_min_deg","film:slope_max_deg","film:slope_opacity"]});
  this.doc=q.doc_id;this.config=#{};
  for k in ["scene","output_path","frames","pre_steps","rate","preroll_frames","postroll_frames","camera","clock_scale"] {
   let v=q.attrs["film:"+k];if v==() {throw "Missing V14 capture field: "+k;}this.config[k]=v;
  }
  if this.config.scene=="drive-slope" {
   for k in ["slope_min_deg","slope_max_deg","slope_opacity"] {
    let v=q.attrs["film:"+k];if v==() || !v.is_finite() {throw "Missing native slope-view setting: "+k;}this.config[k]=v;
   }
   let lo=this.config.slope_min_deg;let hi=this.config.slope_max_deg;let opacity=this.config.slope_opacity;
   if lo<0.0 || hi<=lo || hi>90.0 || opacity<0.0 || opacity>1.0 {throw "Invalid native slope-view range";}
   cmd("SetTerrainOverlay",#{enabled:false,safe_deg:lo,cliff_deg:hi,opacity:opacity,lod_depth:false});
   print("SLOPE_VIEW|"+lo+"|"+hi+"|"+opacity);
  }else{cmd("SetTerrainOverlay",#{enabled:false});}
  let c=this.config;if c.frames<=0 || c.rate<=0.0 || c.clock_scale<=0.0 {throw "Invalid V14 capture budget";}
  this.finished=();this.slope_start=();this.released=false;this.previous_image= -1;this.previous_tick=();this.previous_mode="held";this.previous_frame= -1;
  cmd("SetTheme",#{mode:"dark",persist:false});clean();cmd("ActivatePerspective",#{id:"sandbox_view"});
  cmd("SetTerrainRenderingQuality",#{tile_resolution:65,cinematic_resolution:2049,tile_budget:256,pixel_error:2.0,max_depth:9});
  if c.pre_steps<0 {throw "V14 pre_steps must be nonnegative";}
  if c.pre_steps>0 {cmd("StepSimulation",#{hold:true,steps:c.pre_steps});}else{cmd("StepSimulation",#{hold:true});}
  this.phase=1;return;
 }
 if this.phase==1 {
  if clock_snapshot().queued_simulation_steps!=0 || !query("GetReadiness",#{}).ready {return;}
  cmd("SetUserCamera",#{name:this.config.camera});cmd("SetCelestialClock",#{scale:this.config.clock_scale});
  if this.config.scene=="nobile" || this.config.scene=="closing" || this.config.scene=="leg" {
   cmd("CameraPathTransport",#{path:ROOT+"/FilmPath",action:"Rewind"});cmd("CameraPathTransport",#{path:ROOT+"/FilmPath",action:"Play"});
  }
  if this.config.scene=="landing" {cmd("CameraPathTransport",#{path:ROOT+"/HeroTripod",action:"Rewind"});cmd("CameraPathTransport",#{path:ROOT+"/HeroTripod",action:"Play"});}
  if this.config.scene=="routes" {
   let r=cmd("SetCameraFeed",#{source:find_path_in_document(this.doc,ROOT+"/MissionMoonView"),label:"Mission location",width:600,height:600,minimum_scene_items:1});if r.ok!=true {throw "Mission camera selection failed";}
  }
  this.phase=2;return;
 }
 if this.phase==2 {
  if !query("GetReadiness",#{}).ready {return;}
  if this.config.scene=="routes" {let feeds=cmd_data("InspectCameraFeeds",#{}).views;let ready=false;for v in feeds {if v.feed==1 {ready=v.ready;}}if !ready {return;}}
  cmd("StartOfflineRecording",#{output_dir:this.config.output_path,fps:30});this.phase=3;return;
 }
 let s=query("GetOfflineRecordingStatus",#{});if !s.active {return;}
 let f=s.frame_index.to_int();if s.last_capture_sim_tick==() {if f!=0 {throw "Captured V14 image has no native tick";}return;}
 let image=if s.is_waiting_for_frame {f}else{f-1};let tick=s.last_capture_sim_tick.to_int();
 let mode=if this.released && this.finished==() {"moving"}else{"held"};
 if image>=0 && image!=this.previous_image {
  if this.previous_tick!=() && mode==this.previous_mode {
   let expected=if mode=="held" {0}else{(2.0*this.config.rate).to_int()};
   if image!=this.previous_image+1 || tick-this.previous_tick!=expected {throw "V14 image/tick cadence mismatch: "+image+"|"+tick+"|"+this.previous_image+"|"+this.previous_tick+"|"+expected;}
  }
  print("V14_IMAGE|"+image+"|"+tick+"|"+mode);this.record_sample(image);this.previous_image=image;this.previous_tick=tick;this.previous_mode=mode;
 }
 if f==this.previous_frame {return;}this.previous_frame=f;
 if !this.released && f>=this.config.preroll_frames {
  this.released=true;cmd("SetTimeTransport",#{playing:true,rate:this.config.rate});cmd("StepSimulation",#{hold:false});
 }
 if this.config.scene=="landing" {
  if f==90 {cmd("SetUserCamera",#{name:"DescentHero"});}
  if f==180 {cmd("SetUserCamera",#{name:"GroundEngines"});}
  if f==450 {cmd("SetUserCamera",#{name:"ApproachView"});}
 }
 if (this.config.scene=="later" || this.config.scene=="nobile") && f%15==0 {
  let sun=find_path_in_document(this.doc,ROOT+"/Sun");let v=qrot(world_rotation_quat(sun),vec3(0.0,0.0,1.0));print("V14_SUN|"+f+"|"+v.x+"|"+v.y+"|"+v.z);
 }
 let end=if this.finished==() {f>=this.config.frames}else{f>=this.finished+this.config.postroll_frames};
 if end {
  if this.config.scene=="routes" && this.finished==() {throw "V14 route did not reach its qualified parked result";}
  cmd("StepSimulation",#{hold:true});cmd("StopOfflineRecording",#{});cmd("SetCelestialClock",#{scale:1.0});cmd("SetTerrainOverlay",#{enabled:false});this.phase=9;
  print("V14_CAPTURE_PASS|"+this.config.scene+"|"+f+"|"+tick);
 }
}
