// @timing presentation
// The recorder owns 1/fps admission. Scene programs own physics and maneuvers.
const ROOT="/Griffin1SurfaceOps";
fn clean() {
 set_twin_setting("ui.camera_status",false);set_twin_setting("ui.vehicle_controls",false);set_twin_setting("ui.mission_notifications",false);
 for name in ["FLIP","FLIP_Amber"] {clear_guided_hud_actions("flip-panel:"+ROOT+"/"+name);clear_hint("flip-panel:"+ROOT+"/"+name);}
 clear_guided_hud_actions("griffin-controls");clear_hint("griffin-controls");objectives_hud("griffin-controls",[]);
}
fn wide() {
 cmd("SetUserCamera",#{name:"Avatar"});
 cmd("SetCameraLookAt",#{camera:find_path(ROOT+"/Avatar"),eye:[-24.0,43.0,18.0],target:[-7.0,-6.0,-12.0]});
}
fn on_start(me,ctx) {
 this.capture_phase=0;
 this.finished_frame=();this.started=false;this.previous_frame=0;this.previous_tick=();this.previous_mode="held";
 this.drop_contact=false;this.drop_samples=0;
 cmd("StepSimulation",#{hold:true});cmd("SetTimeTransport",#{playing:true,rate:1.0});
 if ctx.pre_steps>0 {cmd("StepSimulation",#{hold:true,steps:ctx.pre_steps});}
 clean();cmd("ActivatePerspective",#{id:"sandbox_view"});
 cmd("SetTerrainRenderingQuality",#{tile_resolution:65,cinematic_resolution:2049,tile_budget:256,pixel_error:2.0,max_depth:9});
}
fn initialize_picture(me,ctx) {
 if ctx.scene=="routes" {wide();}
 else if ctx.scene=="landing" {cmd("SetUserCamera",#{name:"ApproachView"});}
 else if ctx.scene=="nozzles" {cmd("SetUserCamera",#{name:"NozzleView"});}
 else if ctx.scene=="drop-low" || ctx.scene=="drop-high" {cmd("SetUserCamera",#{name:"DropView"});}
 else if ctx.scene=="broll" {cmd("SetUserCamera",#{name:"PanelHero"});}
 else if ctx.scene=="sun" {
  let r=find_path(ROOT+"/FLIP");let p=world_pos(r);
  let normal=qrot(world_rotation_quat(find_path(ROOT+"/FLIP/SolarMechanism/Photovoltaics")),vec3(0.0,1.0,0.0));
  cmd("SetUserCamera",#{name:"Avatar"});cmd("SetCameraLookAt",#{camera:find_path(ROOT+"/Avatar"),eye:[p[0]+7.0*normal.x+3.0,p[1]+5.5,p[2]+7.0*normal.z+3.0],target:[p[0],p[1]+0.7,p[2]]});
  cmd("SetCelestialClock",#{scale:100000.0,epoch_jd:2461419.5});
 }
 else if ctx.scene=="moon-day" {
  let radius=query("BodyPosition",#{body:301}).radius;
  if radius<=0.0 {throw "Moon view requires the admitted body radius";}
  cmd("SetUserCamera",#{name:"Avatar"});cmd("SetCameraLookAt",#{camera:find_path(ROOT+"/Avatar"),eye:[0.0,2.0*radius,0.0],target:[0.0,-radius,0.0]});
  cmd("SetCelestialClock",#{scale:100000.0,epoch_jd:2461419.5});
 }
 else if ctx.scene=="moon-region" {
  cmd("SetUserCamera",#{name:"Avatar"});cmd("SetCameraLookAt",#{camera:find_path(ROOT+"/Avatar"),eye:[20000.0,50000.0,45000.0],target:[0.0,-2000.0,0.0]});
  cmd("SetCelestialClock",#{scale:1.0,epoch_jd:2461419.5});
 }
}
fn on_event(me,evt,ctx) {
 if evt.name=="route-comparison-finished" || evt.name=="film-maneuver-finished" {
  this.finished_frame=shot_frame();
  cmd("StepSimulation",#{hold:true});
  print("PHYSICS_FROZEN|"+this.finished_frame+"|"+clock_snapshot().sim_tick);
  if ctx.scene=="routes" {
   cmd("CameraPathTransport",#{path:ROOT+"/ResultOrbit",action:"Rewind"});
   cmd("SetUserCamera",#{name:"ResultView"});
   cmd("CameraPathTransport",#{path:ROOT+"/ResultOrbit",action:"Play"});
  }
 }
}
fn sample_drop(f) {
 let lander=find_path(ROOT+"/Lander");let state=query("QueryPhysicsState",#{id:lander});let p=world_pos(lander);
 let ports=query("ReadPorts",#{api_id:lander,port_names:["any_leg_contact","landing_engine_cutoff","minimum_leg_compression","leg_force_px","leg_force_nx","leg_force_pz","leg_force_nz"]}).ports;
 let engine=query("ReadPorts",#{api_id:find_path(ROOT+"/Lander/MainPropulsion"),port_names:["engine01_thrust_n","engine02_thrust_n","engine03_thrust_n","engine04_thrust_n","engine05_thrust_n","engine06_thrust_n","engine07_thrust_n"]}).ports;
 let thrust=0.0;for port in engine {thrust+=port.value;}
 if !thrust.is_finite() || abs(thrust)>0.01 {throw "Engine-off drop has nonzero or invalid thrust";}
 let values=#{};for port in ports {values[port.name]=port.value;}
 if values.any_leg_contact>0.5 {this.drop_contact=true;}
 this.drop_samples+=1;
 let load=values.leg_force_px+values.leg_force_nx+values.leg_force_pz+values.leg_force_nz;
 print("DROP_CSV|"+f+"|"+p[1]+"|"+state.linear_velocity_mps[1]+"|"+values.any_leg_contact+"|"+values.landing_engine_cutoff+"|"+values.minimum_leg_compression+"|"+load+"|"+thrust);
}
fn picture_step(me,ctx) {
 let status=query("GetOfflineRecordingStatus",#{});let f=status.frame_index.to_int();
 if f==this.previous_frame {return;}
 if !status.active {return;}
 let tick=status.last_capture_sim_tick.to_int();
 let mode=if !this.started || this.finished_frame!=() {"held"}else{"moving"};
 if this.previous_tick!=() && mode==this.previous_mode {
  let expected=if mode=="held" {0}else{(2.0*ctx.rate).to_int()};
  if f!=this.previous_frame+1 || tick-this.previous_tick!=expected {
   throw "Capture cadence rejected: frame="+f+" tick="+status.last_capture_sim_tick+" previous="+this.previous_tick+" expected="+expected;
  }
 }
 print("CAPTURE_FRAME|"+f+"|"+status.last_capture_sim_tick+"|"+mode);
 this.previous_frame=f;this.previous_tick=tick;this.previous_mode=mode;
 if !this.started && f>=ctx.preroll_frames {
  print("CAPTURE_CLOCK_RELEASE|"+clock_snapshot());
  this.started=true;cmd("SetTimeTransport",#{playing:true,rate:ctx.rate});cmd("StepSimulation",#{hold:false});
  if ctx.scene=="broll" {cmd("SetPorts",#{target:find_path(ROOT+"/FLIP"),writes:[["program_active",1.0],["autopilot_enable",0.0],["throttle",0.10],["steer",0.0],["brake",0.0]]});}
 }
 if ctx.scene=="drop-low" || ctx.scene=="drop-high" {this.sample_drop(f);}
 if ctx.scene=="broll" {
  if f==240 {cmd("SetUserCamera",#{name:"WheelDetail"});}
  if f==480 {cmd("SetUserCamera",#{name:"MastForwardCamera"});}
  if f==600 {cmd("SetUserCamera",#{name:"PanelHero"});}
 }
}
fn done(me,ctx) {
 if this.finished_frame!=() {return shot_frame()>=this.finished_frame+ctx.postroll_frames;}
 shot_frame()>=ctx.frames
}
fn finish(me,ctx) {
 if ctx.scene=="drop-low" || ctx.scene=="drop-high" {
  if !this.drop_contact || this.drop_samples<175 {throw "Incomplete native drop/contact evidence";}
  print("DROP_NATIVE_PASS|"+ctx.scene+"|"+this.drop_samples);
 }
 if ctx.scene=="routes" && this.finished_frame==() {throw "Route comparison did not reach its parked result";}
 cmd("StepSimulation",#{hold:true});cmd("StopOfflineRecording",#{});
 if ctx.scene=="sun" || ctx.scene=="moon-day" {cmd("SetCelestialClock",#{scale:1.0});}
 print("CAPTURE_CADENCE_PASS|"+ctx.scene+"|"+this.previous_frame);
}
fn on_tick(me,ctx) {
 // Scenario hooks bind the persistent receiver. Task closures do not carry
 // that receiver; keep recorder state in this presentation hook explicitly.
 if this.capture_phase==3 {return;}
 if this.capture_phase==0 {
  if clock_snapshot().queued_simulation_steps!=0 || !query("GetReadiness",#{}).ready {return;}
  initialize_picture(me,ctx);
  print("CAPTURE_CLOCK_ARM|"+clock_snapshot());
  cmd("StartOfflineRecording",#{output_dir:ctx.output_path,fps:30});
  this.capture_phase=1;return;
 }
 if this.capture_phase==1 {
  if !query("GetOfflineRecordingStatus",#{}).active {return;}
  this.capture_phase=2;
 }
 this.picture_step(me,ctx);
 if this.done(me,ctx) {this.finish(me,ctx);this.capture_phase=3;}
}
