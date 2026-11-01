// @timing presentation
// Presentation only: native mounted cameras; native GNC, plumes and contact.
fn clean() {
 set_twin_setting("ui.camera_status",false);
 clear_guided_hud_actions("flip-panel:/Griffin1SurfaceOps/FLIP");clear_hint("flip-panel:/Griffin1SurfaceOps/FLIP");
 clear_guided_hud_actions("griffin-controls");clear_hint("griffin-controls");objectives_hud("griffin-controls",[]);
}
fn on_start(me,ctx) {
 clean();cmd("StepSimulation",#{hold:true});cmd("SetTimeTransport",#{playing:true,rate:1.0});
 cmd("ActivatePerspective",#{id:"sandbox_view"});cmd("SetUserCamera",#{name:"ApproachView"});
 cmd("SetTerrainRenderingQuality",#{tile_resolution:65,cinematic_resolution:2049,tile_budget:256,pixel_error:2.0,max_depth:9});
}
fn probe(f) {
   let root="/Griffin1SurfaceOps/Lander";
   let lp=world_pos(find_path(root+"/Nozzle/MainEngineCluster/Engine01/Exhaust/PlumeLight"));
   let np=world_pos(find_path(root+"/Nozzle/MainEngineCluster/Engine01/Exhaust"));
   let ground=query("TerrainHeight",#{x:lp[0],z:lp[2]});
   let light=find_path(root+"/Nozzle/MainEngineCluster/Engine01/Exhaust/PlumeLight");
   print("LIGHT_PROBE|"+f+"|"+lp+"|"+np+"|"+ground+"|"+query("GetPort",#{api_id:light,name:"light_intensity"}).value);
}
fn task(me,ctx) {
 let previous=-1;let held=false;
 seq([once(|m|{cmd("StartOfflineRecording",#{output_dir:"/home/rod/Documents/lunco/griffin-presentation/campaigns/lunar-missions/griffin_flip_v12/renders/evidence/landing-light/landing-terrain-fixed.mp4",fps:30});cmd("StepSimulation",#{hold:false});}),
 #{kind:"step",act:|m|{
  let f=shot_frame();set_twin_setting("ui.camera_status",false);clear_guided_hud_actions("flip-panel:/Griffin1SurfaceOps/FLIP");clear_hint("flip-panel:/Griffin1SurfaceOps/FLIP");clear_guided_hud_actions("griffin-controls");clear_hint("griffin-controls");objectives_hud("griffin-controls",[]);
  if f>=750 && !held {cmd("StepSimulation",#{hold:true});held=true;}
  if f>=0 && f!=previous {previous=f;if f%15==0 {
   let r=find_path("/Griffin1SurfaceOps/Lander");let p=world_pos(r);let s=query("QueryPhysicsState",#{id:r});
   probe(f);
  }}
 },done:|m|shot_frame()>=990},once(|m|cmd("StopOfflineRecording",#{})),once(|m|cmd("StepSimulation",#{hold:true}))])
}
