// @timing presentation
// V24 capture policy. Flight dynamics and guidance remain native Modelica.
fn on_start(me,ctx) {
 cmd("StepSimulation",#{hold:true});
 cmd("SetTimeTransport",#{playing:true,rate:1.0});
 set_twin_setting("ui.camera_status",false);
 set_twin_setting("ui.vehicle_controls",false);
 set_twin_setting("ui.mission_notifications",false);
 clear_guided_hud_actions("griffin-controls");
 clear_hint("griffin-controls");
 objectives_hud("griffin-controls",[]);
 clear_guided_hud_actions("flip-panel:/Griffin1SurfaceOps/FLIP");
 clear_hint("flip-panel:/Griffin1SurfaceOps/FLIP");
 cmd("SetUserCamera",#{name:"Avatar"});
 cmd("SetCameraLookAt",#{camera:find_path("/Griffin1SurfaceOps/Avatar"),eye:[40.0,23.0,-40.0],target:[0.0,25.0,0.0]});
 print("V24_LANDING_READY|"+find_path("/Griffin1SurfaceOps/Lander"));
}
