// @timing presentation
// Bounded identical-scene capture: no physics or quality changes.
fn on_start(me,ctx) {
 cmd("SetTimeTransport",#{playing:true,rate:1.0});cmd("StepSimulation",#{hold:true});
 cmd("ActivatePerspective",#{id:"sandbox_view"});cmd("SetUserCamera",#{name:"Avatar"});
 let r=find_path("/Griffin1SurfaceOps/FLIP");cmd("SetPorts",#{target:r,writes:[["program_active",1.0],["autopilot_enable",0.0],["throttle",0.0],["steer",0.0],["brake",1.0]]});let p=world_pos(r);let n=qrot(world_rotation_quat(find_path("/Griffin1SurfaceOps/FLIP/SolarMechanism/Photovoltaics")),vec3(0.0,1.0,0.0));cmd("SetCameraLookAt",#{camera:find_path("/Griffin1SurfaceOps/Avatar"),eye:[p[0]+7.0*n.x+3.0,p[1]+5.5,p[2]+7.0*n.z+3.0],target:[p[0],p[1]+0.7,p[2]]});
 set_twin_setting("ui.camera_status",false);set_twin_setting("ui.vehicle_controls",false);set_twin_setting("ui.mission_notifications",false);
}
fn task(me,ctx) {
 let prev=-1;
 seq([once(|m|cmd("StartOfflineRecording",#{output_dir:"/home/rod/Documents/lunco/lunco-marketing/campaigns/lunar-missions/griffin_flip_v13/renders/evidence/headful-proofs/mode-proof-1440p-01.mp4",fps:30})),#{kind:"step",act:|m|{let f=shot_frame();if f>=0 && f!=prev {prev=f;print("HEADFUL_PROOF|"+f+"|"+clock_snapshot().sim_tick);cmd("StepSimulation",#{hold:true,steps:2});}},done:|m|shot_frame()>=60},once(|m|cmd("StopOfflineRecording",#{}))])
}
