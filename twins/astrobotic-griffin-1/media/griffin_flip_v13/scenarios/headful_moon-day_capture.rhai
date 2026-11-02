// @timing presentation
fn on_start(me,ctx) {
 cmd("SetTimeTransport",#{playing:true,rate:1.0});cmd("StepSimulation",#{hold:true,steps:182});
 set_twin_setting("ui.camera_status",false);set_twin_setting("ui.vehicle_controls",false);set_twin_setting("ui.mission_notifications",false);cmd("ActivatePerspective",#{id:"sandbox_view"});
}
fn task(me,ctx) {
 let previous=-1;
 seq([wait_until(|m|query("GetReadiness").ready),wait(2.0),once(|m|{
 let radius=query("BodyPosition",#{body:301}).radius;let camera=find_path("/Griffin1SurfaceOps/Avatar");
 if radius<=0.0 || camera<0 {throw "Lunar lighting view requires the admitted Moon and camera";}
 cmd("SetUserCamera",#{name:"Avatar"});cmd("SetCameraLookAt",#{camera:camera,eye:[0.0,2.0*radius,0.0],target:[0.0,-radius,0.0]});
 cmd("SetCelestialClock",#{scale:100000.0,epoch_jd:2461419.5});
 cmd("StartOfflineRecording",#{output_dir:ctx.output_path,fps:30});
 }),#{kind:"step",act:|m|{let f=shot_frame();if f<0 || f==previous {return;}previous=f;cmd("StepSimulation",#{hold:true,steps:2});},done:|m|shot_frame()>=766},once(|m|{cmd("StopOfflineRecording",#{});cmd("SetCelestialClock",#{scale:1.0});})])
}
