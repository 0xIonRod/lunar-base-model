// @timing presentation
// Native selected-body mass display and a gentle camera orbit; physics held.
fn on_start(me,ctx) {
 cmd("StepSimulation",#{hold:true});cmd("SetTimeTransport",#{playing:true,rate:1.0});
 cmd("ActivatePerspective",#{id:"sandbox_view"});cmd("SetUserCamera",#{name:"Avatar"});set_twin_setting("ui.camera_status",false);
}
fn view_at(t) {
 let a=0.45+0.28*t;let p=world_pos(find_path("/Griffin1SurfaceOps/Lander"));
 cmd("SetCameraLookAt",#{camera:find_path("/Griffin1SurfaceOps/Avatar"),eye:[p[0]+14.0*cos(a),p[1]+5.0,p[2]-14.0*sin(a)],target:[p[0],p[1]+1.8,p[2]]});
}
fn recording_started(me) {query("GetOfflineRecordingStatus",#{}).active}
fn select_body(me) {
 cmd("SelectEntity",#{entity_id:find_path("/Griffin1SurfaceOps/Lander")});
 cmd("SetDiagnosticLayers",#{enabled:true,layers:["physics_mass"]});view_at(0.0);
}
fn begin_recording(me) {cmd("StartOfflineRecording",#{output_dir:"/home/rod/Documents/lunco/griffin-presentation/campaigns/lunar-missions/griffin_flip_v12/renders/sources/mass/take-01.mp4",fps:30});}
fn orbit(me) {view_at(max(0.0,min(1.0,shot_frame().to_float()/359.0)));}
fn orbit_done(me) {shot_frame()>=360}
fn end_recording(me) {cmd("StopOfflineRecording",#{});cmd("SetDiagnosticLayers",#{enabled:false,layers:["physics_mass"]});}
fn task(me,ctx) {
 seq([wait(0.25),once(Fn("select_body")),wait(0.2),once(Fn("begin_recording")),
 wait_until(Fn("recording_started")),#{kind:"step",act:Fn("orbit"),done:Fn("orbit_done")},once(Fn("end_recording"))])
}
