// @timing presentation
const R="/Griffin1SurfaceOps/FLIP";
fn on_start(me,ctx) {
 cmd("SetTimeTransport",#{playing:true,rate:1.0});cmd("StepSimulation",#{hold:true,steps:182});
 cmd("SetPorts",#{target:find_path(R),writes:[["program_active",1.0],["autopilot_enable",0.0],["throttle",0.0],["steer",0.0],["brake",1.0]]});
 set_twin_setting("ui.camera_status",false);set_twin_setting("ui.vehicle_controls",false);set_twin_setting("ui.mission_notifications",false);cmd("ActivatePerspective",#{id:"sandbox_view"});
}
fn task(me,ctx) {
 let prev=-1;
 seq([wait(2.0),once(|m|{
 cmd("FocusTarget",#{target:find_path("/Griffin1SurfaceOps/SolarSystem/Moon")});
 cmd("SetCelestialClock",#{scale:100000.0,epoch_jd:2461419.5});
 cmd("StartOfflineRecording",#{output_dir:"/home/rod/Documents/lunco/griffin-presentation/campaigns/lunar-missions/griffin_flip_v12/renders/sources/moon-day/take-01.mp4",fps:30});
 }),#{kind:"step",act:|m|{let f=shot_frame();if f>=0 && f!=prev{prev=f;cmd("StepSimulation",#{hold:true,steps:2});}},done:|m|shot_frame()>=766},once(|m|{cmd("StopOfflineRecording",#{});cmd("SetCelestialClock",#{scale:1.0});})])
}
