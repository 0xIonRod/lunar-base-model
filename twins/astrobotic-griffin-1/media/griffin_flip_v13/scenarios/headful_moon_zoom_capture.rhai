// @timing presentation
// Native celestial focus and native wheel zoom; the Moon remains body-fixed.
const ROOT="/Griffin1SurfaceOps";
fn on_start(me,ctx) {
 cmd("SetTimeTransport",#{playing:true,rate:1.0});cmd("StepSimulation",#{hold:true,steps:182});
 cmd("SetUserCamera",#{name:"Avatar"});
 set_twin_setting("ui.camera_status",false);set_twin_setting("ui.mission_notifications",false);cmd("ActivatePerspective",#{id:"sandbox_view"});
}
fn task(me,ctx) {
 let previous=-1;let radius=();let previous_distance=();let initial_altitude=();let began=0.0;let surface_frame=();let surface_altitude=();
 seq([wait_until(|m|query("GetReadiness").ready),
 once(|m|{radius=query("BodyPosition",#{body:301}).radius;if radius<=0.0 {throw "Invalid native Moon radius";}cmd("SetCameraInput",#{surface_mode_engage_altitude_m:0.0,surface_mode_disengage_altitude_m:10.0});cmd("FocusTarget",#{target:find_path(ROOT+"/SolarSystem/Moon")});}),wait(1.0),
 once(|m|{let s=query("ReadExposures",#{surface:"celestial-view"}).surfaces["celestial-view"].properties;let p=s.site_orbit_position_m;if p==() {throw "Celestial view has no landing-site orbit position";}cmd("AnimateOrbitCameraDirection",#{yaw_rad:atan(p[0],p[2]),pitch_rad:-atan(p[1],sqrt(p[0]*p[0]+p[2]*p[2])),duration_s:1.0});cmd("InjectWindowInput",#{event:#{PointerMove:#{x:1000.0,y:500.0}}});}),wait(2.0),
 once(|m|{initial_altitude=world_pos(find_path(ROOT+"/Avatar"))[1];previous_distance=radius+initial_altitude;if initial_altitude<100000.0 {throw "Orbital approach must begin above the complete Moon";}cmd("StartOfflineRecording",#{output_dir:ctx.output_path,fps:30});}),wait_until(|m|query("GetOfflineRecordingStatus",#{}).active),once(|m|cmd("StepSimulation",#{hold:false})),
 #{kind:"step",act:|m|{let f=shot_frame();if f<0 || f==previous {return;}previous=f;
 let u=((f-30).to_float()/330.0).clamp(0.0,1.0);let e=u*u*(3.0-2.0*u);let altitude=initial_altitude*exp(ln(35.0/initial_altitude)*e);let distance=radius+altitude;let camera=find_path(ROOT+"/Avatar");let orbital=get(camera,"OrbitCamera.distance");let delta=0.0;
 if orbital!=() {delta=ln(previous_distance/distance)/0.05;}else{let actual=world_pos(camera);let ground=query("TerrainHeight",#{x:actual[0],z:actual[2]});if !ground.found {throw "Surface zoom requires the loaded terrain";}let clearance=actual[1]-ground.height;if surface_frame==() {surface_frame=f;surface_altitude=clearance;print("MOON_HANDOFF|"+f+"|"+actual);}
 let v=((f-surface_frame-10).to_float()/(380-surface_frame-10).to_float()).clamp(0.0,1.0);let ve=v*v*(3.0-2.0*v);let desired=surface_altitude*exp(ln((35.0-ground.height)/surface_altitude)*ve);if clearance<=0.0 || desired<=0.0 {throw "Surface zoom altitude must remain above terrain";}delta=if f-surface_frame<10 {0.0}else{max(0.0,ln(clearance/desired)/0.05)};}
 previous_distance=distance;
 cmd("InjectWindowInput",#{event:#{Scroll:#{x:0.0,y:delta}}});
 if f%30==0 {print("MOON_ZOOM|"+f+"|"+world_pos(find_path(ROOT+"/Avatar")));}
 },done:|m|shot_frame()>=390},once(|m|{cmd("StepSimulation",#{hold:true});cmd("StopOfflineRecording",#{});})])
}
