// @timing presentation
// The recorder owns 1/fps admission. Scene programs own physics and maneuvers.
const ROOT="/Griffin1SurfaceOps";
fn clean() {
 set_twin_setting("ui.camera_status",false);set_twin_setting("ui.vehicle_controls",false);set_twin_setting("ui.mission_notifications",false);
 for name in ["FLIP","FLIP_Amber"] {clear_guided_hud_actions("flip-panel:"+ROOT+"/"+name);clear_hint("flip-panel:"+ROOT+"/"+name);}
 clear_guided_hud_actions("griffin-controls");clear_hint("griffin-controls");objectives_hud("griffin-controls",[]);
}
fn wide(ctx) {cmd("SetUserCamera",#{name:"RouteMaster"});}
fn prepare_capture(me,unused) {
 let capture=query("QueryUsdPrim",#{path:ROOT+"/FilmCapture",attrs:["film:scene","film:output_path","film:frames","film:pre_steps","film:rate","film:preroll_frames","film:postroll_frames"]});
 let scene_document=capture.doc_id;
 if scene_document==() || capture.attrs==() {throw "Capture requires one mounted live scene with its authored configuration";}
 let attrs=capture.attrs;
 let ctx=#{};
 for key in ["scene","output_path","frames","pre_steps","rate","preroll_frames","postroll_frames"] {
  let value=attrs["film:"+key];
  if value==() {throw "Missing authored film capture property: film:"+key;}
  ctx[key]=value;
 }
 if ctx.scene=="" || ctx.output_path=="" || ctx.frames<=0 || ctx.rate<=0 {throw "Invalid authored film capture configuration";}
 ctx.doc_id=scene_document;this.capture_config=ctx;
 this.capture_phase=0;
 this.finished_frame=();this.started=false;this.previous_frame=0;this.previous_tick=();this.previous_image= -1;this.previous_mode="held";
 this.drop_contact=false;this.drop_samples=0;
 this.nozzle_cooling_shown=false;
 this.panel_start=();this.panel_end=();
 if ctx.scene=="mechanisms" {
  for name in ["PanelDeployView","WheelRollingView"] {
   if find_path_in_document(ctx.doc_id,ROOT+"/FLIP/"+name)<0 {throw "Missing authored mechanism camera: "+name;}
  }
  let authored=query("QueryUsdPrim",#{path:ROOT+"/FLIP/SolarMechanism/Controller",attrs:["inputs:initial_deg","inputs:command_deg"]}).attrs;
  if authored["inputs:initial_deg"]!=0.0 || authored["inputs:command_deg"]!=0.0 {throw "Mechanism take must start with the panel stowed";}
 }
 cmd("StepSimulation",#{hold:true});cmd("SetTimeTransport",#{playing:true,rate:1.0});
 print("CAPTURE_NATIVE_INITIAL|"+ctx.scene+"|"+clock_snapshot().world_sim_s);
 let initial_lander=find_path_in_document(ctx.doc_id,ROOT+"/Lander");if initial_lander>=0 {let state=query("QueryPhysicsState",#{id:initial_lander});print("CAPTURE_INITIAL_LANDER|"+world_pos(initial_lander)+"|"+state.body_mode+"|"+state.linear_velocity_mps);}
 if ctx.pre_steps>0 {cmd("StepSimulation",#{hold:true,steps:ctx.pre_steps});}
 clean();cmd("ActivatePerspective",#{id:"sandbox_view"});
 cmd("SetTerrainRenderingQuality",#{tile_resolution:65,cinematic_resolution:2049,tile_budget:256,pixel_error:2.0,max_depth:9});
}
fn initialize_picture(me,ctx) {
 if ctx.scene=="routes" {
  wide(ctx);
  let camera=find_path_in_document(ctx.doc_id,ROOT+"/MissionMoonView");
  if camera<0 {throw "The route comparison requires its native Moon camera";}
  let selected=cmd("SetCameraFeed",#{source:camera,label:"Mission location",width:600,height:600,minimum_scene_items:1});
  if selected.ok!=true {throw "Native mission map camera was rejected";}
 }
 else if ctx.scene=="landing" {cmd("SetUserCamera",#{name:"ApproachView"});}
 else if ctx.scene=="ground-landing" {cmd("SetUserCamera",#{name:"DescentWide"});}
 else if ctx.scene=="nozzles" {cmd("SetUserCamera",#{name:"NozzleView"});}
 else if ctx.scene=="drop-low" || ctx.scene=="drop-high" {cmd("SetUserCamera",#{name:"DropObserve"});}
 else if ctx.scene=="broll" {cmd("SetUserCamera",#{name:"PanelHero"});}
 else if ctx.scene=="mechanisms" {cmd("SetUserCamera",#{name:"PanelDeployView"});}
 else if ctx.scene=="sun" {
  let r=find_path_in_document(ctx.doc_id,ROOT+"/FLIP");let p=world_pos(r);
  let normal=qrot(world_rotation_quat(find_path_in_document(ctx.doc_id,ROOT+"/FLIP/SolarMechanism/Photovoltaics")),vec3(0.0,1.0,0.0));
  cmd("SetUserCamera",#{name:"Avatar"});cmd("SetCameraLookAt",#{camera:find_path_in_document(ctx.doc_id,ROOT+"/Avatar"),eye:[p[0]+7.0*normal.x+3.0,p[1]+5.5,p[2]+7.0*normal.z+3.0],target:[p[0],p[1]+0.7,p[2]]});
  cmd("SetCelestialClock",#{scale:100000.0});
 }
 else if ctx.scene=="moon-day" {
  cmd("SetUserCamera",#{name:"MoonView"});cmd("SetCelestialClock",#{scale:100000.0});
 }
 else if ctx.scene=="moon-region" {
  // The authored path owns this camera pose and aim throughout the shot.
  cmd("SetUserCamera",#{name:"RegionView"});
  cmd("SetCelestialClock",#{scale:1.0});
  cmd("CameraPathTransport",#{path:ROOT+"/RegionFlyover",action:"Rewind"});
  cmd("CameraPathTransport",#{path:ROOT+"/RegionFlyover",action:"Play"});
 }
}
fn on_event(me,evt,unused) {
 if evt.name!="route-comparison-finished" && evt.name!="film-maneuver-finished" && evt.name!="lander_touchdown" {return;}
 let ctx=this.capture_config;
 if ctx.scene=="ground-landing" && evt.name=="lander_touchdown" && evt.source==find_path_in_document(ctx.doc_id,ROOT+"/Lander") {
  this.finished_frame=shot_frame();cmd("StepSimulation",#{hold:true});
  print("LANDING_PHYSICS_FROZEN|"+this.finished_frame+"|"+clock_snapshot().sim_tick);
 }
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
fn sample_drop(f,ctx) {
 let lander=find_path_in_document(ctx.doc_id,ROOT+"/Lander");let state=query("QueryPhysicsState",#{id:lander});let p=world_pos(lander);
 let ports=query("ReadPorts",#{api_id:lander,port_names:["any_leg_contact","landing_engine_cutoff","minimum_leg_compression","leg_force_px","leg_force_nx","leg_force_pz","leg_force_nz"]}).ports;
 let engine=query("ReadPorts",#{api_id:find_path_in_document(ctx.doc_id,ROOT+"/Lander/MainPropulsion"),port_names:["engine01_thrust_n","engine02_thrust_n","engine03_thrust_n","engine04_thrust_n","engine05_thrust_n","engine06_thrust_n","engine07_thrust_n"]}).ports;
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
 if !status.active {return;}
 if status.last_capture_sim_tick==() {
  if f!=0 || status.is_waiting_for_frame {throw "A requested image is missing its native simulation tick";}
  return;
 }
 let tick=status.last_capture_sim_tick.to_int();
 let mode=if !this.started || this.finished_frame!=() {"held"}else{"moving"};
 // The native status exposes completed-image count separately from the
 // latest requested-image tick. Pair the tick with its actual image index.
 let image=if status.is_waiting_for_frame {f}else{f-1};
 if image>=0 && image!=this.previous_image {
  if this.previous_tick!=() && mode==this.previous_mode {
   let expected=if mode=="held" {0}else{(2.0*ctx.rate).to_int()};
   if image!=this.previous_image+1 || tick-this.previous_tick!=expected {
    throw "Capture cadence rejected: image="+image+" tick="+tick+" previous_image="+this.previous_image+" previous_tick="+this.previous_tick+" expected="+expected;
   }
  }
  print("CAPTURE_IMAGE|"+image+"|"+tick+"|"+mode);
  this.previous_image=image;this.previous_tick=tick;this.previous_mode=mode;
 }
 if f==this.previous_frame {return;}
 print("CAPTURE_FRAME|"+f+"|"+tick+"|"+mode);
 this.previous_frame=f;
 if !this.started && f>=ctx.preroll_frames {
  print("CAPTURE_CLOCK_RELEASE|"+clock_snapshot());
  this.started=true;cmd("SetTimeTransport",#{playing:true,rate:ctx.rate});cmd("StepSimulation",#{hold:false});
  if ctx.scene=="broll" {cmd("SetPorts",#{target:find_path_in_document(ctx.doc_id,ROOT+"/FLIP"),writes:[["program_active",1.0],["autopilot_enable",0.0],["throttle",0.10],["steer",0.0],["brake",0.0]]});}
  if ctx.scene=="mechanisms" {cmd("SetPorts",#{target:find_path_in_document(ctx.doc_id,ROOT+"/FLIP"),writes:[["program_active",1.0],["autopilot_enable",0.0],["throttle",0.0],["steer",0.0],["brake",1.0]]});}
 }
 if ctx.scene=="moon-day" && f%30==0 {
  let camera=find_path_in_document(ctx.doc_id,ROOT+"/MoonView");
  print("MOON_BODY_FIXED_VIEW|"+f+"|"+world_pos(camera)+"|"+world_rotation_quat(camera));
 }
 if ctx.scene=="drop-low" || ctx.scene=="drop-high" {this.sample_drop(f,ctx);}
 if ctx.scene=="ground-landing" {
  if f==270 {cmd("SetUserCamera",#{name:"GroundEngines"});}
  if f==405 {cmd("SetUserCamera",#{name:"GearView"});}
  if f==450 {cmd("SetUserCamera",#{name:"PayloadView"});}
  if f==570 {cmd("SetUserCamera",#{name:"GroundTouchdown"});}
  if f%30==0 {
   let p=world_pos(find_path_in_document(ctx.doc_id,ROOT+"/GroundEngines"));
   let h=query("TerrainHeight",#{x:p[0],z:p[2]});
   if h.found!=true || p[1]<=h.height+0.03 {throw "Ground camera is below the measured terrain";}
   print("GROUND_LANDING|"+f+"|"+tick+"|"+world_pos(find_path_in_document(ctx.doc_id,ROOT+"/Lander")));
  }
 }
 if ctx.scene=="nozzles" {
  // Leave the low airborne view before it could enter the soil. Then show
  // the real warm metal after cutoff from a separate, above-ground camera.
  if f==438 {cmd("SetUserCamera",#{name:"GearView"});}
  if f==570 {cmd("SetUserCamera",#{name:"NozzleCoolView"});}
  if f==720 {cmd("SetUserCamera",#{name:"ApproachView"});}
  if f%15==0 {
   let main=find_path_in_document(ctx.doc_id,ROOT+"/Lander/MainPropulsion");
   let sample=query("ReadPorts",#{api_id:main,port_names:[
    "engine01_thrust_n","__member_Engine01Wall_throat_temperature_k",
    "__member_Engine01Wall_middle_temperature_k","__member_Engine01Wall_exit_temperature_k",
    "__member_Engine01Wall_heating_w","__member_Engine01Wall_energy_residual_w"]});
   print("NOZZLE_CAPTURE|"+f+"|"+sample);
   let thrust=();for port in sample.ports {if port.name=="engine01_thrust_n" {thrust=port.value;}}
   if thrust==() || !thrust.is_finite() {throw "Nozzle capture requires actual delivered thrust";}
   if f>720 && !this.nozzle_cooling_shown && thrust<0.01 {
    this.nozzle_cooling_shown=true;cmd("SetUserCamera",#{name:"NozzleCoolView"});
    print("NOZZLE_COOLING_CUT|"+f+"|"+clock_snapshot().sim_tick);
   }
   let camera=if this.nozzle_cooling_shown {"NozzleCoolView"} else if f<438 {"NozzleView"} else if f<570 {"GearView"} else if f<720 {"NozzleCoolView"} else {"ApproachView"};
   let p=world_pos(find_path_in_document(ctx.doc_id,ROOT+"/Lander/"+camera));
   let h=query("TerrainHeight",#{x:p[0],z:p[2]});
   if h.found!=true || !h.height.is_finite() || p[1]<=h.height+0.03 {throw "Nozzle camera is not safely above the measured terrain";}
   print("NOZZLE_CAMERA|"+f+"|"+camera+"|"+p[1]+"|"+h.height);
  }
 }
 if ctx.scene=="mechanisms" {
  let rover=find_path_in_document(ctx.doc_id,ROOT+"/FLIP");
  if f==15 {
   let config=query("QueryUsdPrim",#{path:ROOT+"/FLIP/PanelControls",attrs:["inputs:open_angle_deg"]});
   let target=config.attrs["inputs:open_angle_deg"];
   if target==() || !target.is_finite() || target<=0.0 || target>90.0 {throw "Invalid authored solar deployment target";}
   let result=cmd("SetPorts",#{target:find_path_in_document(ctx.doc_id,ROOT+"/FLIP/SolarMechanism/Controller"),writes:[["command_deg",target]]});
   if result.ok!=true {throw "Solar deployment command rejected";}
  }
  if f==360 {
   cmd("SetUserCamera",#{name:"WheelRollingView"});
   cmd("SetPorts",#{target:rover,writes:[["throttle",0.10],["steer",0.0],["brake",0.0]]});
  }
  if f==600 {cmd("SetUserCamera",#{name:"PanelHero"});}
  if f==780 {cmd("SetUserCamera",#{name:"MastForwardCamera"});}
  if f==900 {cmd("SetPorts",#{target:rover,writes:[["throttle",0.0],["brake",1.0]]});}
  if f%15==0 {
   let panel=query("ReadPorts",#{api_id:find_path_in_document(ctx.doc_id,ROOT+"/FLIP/SolarMechanism/Controller"),port_names:["deployment_deg"]}).ports[0].value;
   let state=query("QueryPhysicsState",#{id:rover});
   if this.panel_start==() {this.panel_start=panel;}
   this.panel_end=panel;
   print("MECHANISM_SAMPLE|"+f+"|"+tick+"|"+panel+"|"+state.linear_velocity_mps+"|"+world_pos(rover));
  }
 }
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
 if ctx.scene=="mechanisms" {
  if this.panel_start==() || abs(this.panel_start)>0.1 || this.panel_end<81.9 {throw "Incomplete native panel deployment evidence";}
  print("MECHANISM_DEPLOYMENT_PASS|"+this.panel_start+"|"+this.panel_end);
 }
 if ctx.scene=="routes" && this.finished_frame==() {throw "Route comparison did not reach its parked result";}
 cmd("StepSimulation",#{hold:true});cmd("StopOfflineRecording",#{});
 if ctx.scene=="sun" || ctx.scene=="moon-day" {cmd("SetCelestialClock",#{scale:1.0});}
 print("CAPTURE_CADENCE_PASS|"+ctx.scene+"|"+this.previous_frame);
}
fn on_start(me,unused) {cmd("StepSimulation",#{hold:true});this.capture_phase=-1;}
fn on_tick(me,unused) {
 if this.capture_phase== -1 {if !query("GetReadiness",#{}).ready {return;}this.prepare_capture(me,unused);return;}
 let ctx=this.capture_config;
 // Scenario hooks bind the persistent receiver. Task closures do not carry
 // that receiver; keep recorder state in this presentation hook explicitly.
 if this.capture_phase==3 {return;}
 if this.capture_phase==0 {
  if clock_snapshot().queued_simulation_steps!=0 || !query("GetReadiness",#{}).ready {return;}
  initialize_picture(me,ctx);
  this.capture_phase=4;return;
 }
 if this.capture_phase==4 {
  if ctx.scene=="routes" {
   let ready=false;for feed in cmd_data("InspectCameraFeeds",#{}).views {if feed.feed==1 {ready=feed.ready;}}
   if !ready {return;}
   let marker=cmd_data("ProjectCameraFeedSubject",#{feed:1,subject:find_path_in_document(ctx.doc_id,ROOT)});
   if marker.projected!=true || marker.inside_frame!=true {throw "Native mission marker is outside the Moon map";}
   print("MISSION_MAP_PROJECTION|"+marker);
  }
  if !query("GetReadiness",#{}).ready {return;}
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
