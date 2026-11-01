// @timing presentation
const R="/Griffin1SurfaceOps/FLIP";
fn drive(t,b) {cmd("SetPorts",#{target:find_path(R),writes:[["program_active",1.0],["autopilot_enable",0.0],["throttle",t],["steer",0.0],["brake",b]]});}
fn on_start(me,ctx) {
 set_physics_substeps(32);set_physics_joint_velocity_iterations(128);
 cmd("SetTimeTransport",#{playing:true,rate:1.0});drive(0.0,1.0);cmd("StepSimulation",#{hold:true,steps:182});
 set_twin_setting("ui.vehicle_controls",false);set_twin_setting("ui.camera_status",false);set_twin_setting("ui.mission_notifications",false);cmd("ActivatePerspective",#{id:"sandbox_view"});
}
fn task(me,ctx) {
 let prev=-1;let moved=false;
 seq([wait(2.0),once(|m|{cmd("SetUserCamera",#{name:"MastForwardCamera"});cmd("StartOfflineRecording",#{output_dir:"/home/rod/Documents/lunco/griffin-presentation/campaigns/lunar-missions/griffin_flip_v12/renders/sources/broll/take-01.mp4",fps:30});}),
 #{kind:"step",act:|m|{
 let f=shot_frame();if f<0 || f==prev {return;}prev=f;
 if !moved {drive(0.10,0.0);moved=true;}
 if f==180 {cmd("SetUserCamera",#{name:"WheelDetail"});}
 if f==360 {cmd("SetUserCamera",#{name:"PanelHero"});}
 cmd("StepSimulation",#{hold:true,steps:2});
 },done:|m|shot_frame()>=540},once(|m|{drive(0.0,1.0);cmd("StopOfflineRecording",#{});})])
}
