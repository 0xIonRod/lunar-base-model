// @timing presentation
const R="/Griffin1SurfaceOps/FLIP";
fn on_start(me,ctx) {
 cmd("SetTimeTransport",#{playing:true,rate:1.0});cmd("StepSimulation",#{hold:true,steps:182});
 cmd("SetPorts",#{target:find_path(R),writes:[["program_active",1.0],["autopilot_enable",0.0],["throttle",0.0],["steer",0.0],["brake",1.0]]});
 set_twin_setting("ui.camera_status",false);clear_guided_hud_actions("flip-panel:/Griffin1SurfaceOps/FLIP");clear_hint("flip-panel:/Griffin1SurfaceOps/FLIP");set_twin_setting("ui.vehicle_controls",false);set_twin_setting("ui.mission_notifications",false);cmd("ActivatePerspective",#{id:"sandbox_view"});
}
fn task(me,ctx) {
 let prev=-1;
 seq([wait(2.0),once(|m|{
 let r=find_path(R);let p=world_pos(r);let n=qrot(world_rotation_quat(find_path(R+"/SolarMechanism/Photovoltaics")),vec3(0.0,1.0,0.0));
 cmd("SetUserCamera",#{name:"Avatar"});cmd("SetCameraLookAt",#{camera:find_path("/Griffin1SurfaceOps/Avatar"),eye:[p[0]+7.0*n.x+3.0,p[1]+5.5,p[2]+7.0*n.z+3.0],target:[p[0],p[1]+0.7,p[2]]});
 cmd("SetCelestialClock",#{scale:100000.0,epoch_jd:2461419.5});cmd("StepSimulation",#{hold:false});
 cmd("StartOfflineRecording",#{output_dir:"/home/rod/Documents/lunco/lunco-marketing/campaigns/lunar-missions/griffin_flip_v13/renders/sources/sun/take-02.mp4",fps:30});
 }),#{kind:"step",act:|m|{let f=shot_frame();if f>=0 && f!=prev{prev=f;}},done:|m|shot_frame()>=766},once(|m|{cmd("StopOfflineRecording",#{});cmd("SetCelestialClock",#{scale:1.0});})])
}
