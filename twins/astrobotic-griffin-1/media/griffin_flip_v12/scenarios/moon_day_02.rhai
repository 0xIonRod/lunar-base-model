// @timing presentation
// Camera-only take. Native orbital view, native input, native terrain and ephemeris.
fn task(me,ctx) {
 let previous=-1;
 seq([
 once(|m|cmd("ReturnFromOrbit",#{camera:find_path("/Griffin1SurfaceOps/Avatar")})),wait(1.0),
 once(|m|cmd("FocusTarget",#{target:find_path("/Griffin1SurfaceOps/SolarSystem/Moon")})),wait(1.0),
 once(|m|{
  let s=query("ReadExposures",#{surface:"celestial-view"}).surfaces["celestial-view"].properties;
  let p=s.site_orbit_position_m;
  cmd("AnimateOrbitCameraDirection",#{yaw_rad:atan(p[0],p[2]),pitch_rad:-atan(p[1],sqrt(p[0]*p[0]+p[2]*p[2])),duration_s:1.0});
  cmd("InjectWindowInput",#{event:#{PointerMove:#{x:1000.0,y:500.0}}});
 }),wait(2.0),#{kind:"step",act:|m|{
  let altitude=world_pos(find_path("/Griffin1SurfaceOps/Avatar"))[1];
  let delta=ln((1737400.0+altitude)/5212200.0)/0.05*0.3;
  cmd("InjectWindowInput",#{event:#{Scroll:#{x:0.0,y:delta.clamp(-2.0,2.0)}}});
 },done:|m|abs(world_pos(find_path("/Griffin1SurfaceOps/Avatar"))[1]-3474800.0)<200.0},wait(1.0),once(|m|{
  cmd("SetCelestialClock",#{scale:100000.0,epoch_jd:2461419.5});
  cmd("SetTimeTransport",#{playing:true,rate:1.0});cmd("StepSimulation",#{hold:true});
  cmd("StartOfflineRecording",#{output_dir:"/home/rod/Documents/lunco/griffin-presentation/campaigns/lunar-missions/griffin_flip_v12/renders/sources/moon-day/take-02.mp4",fps:30});
 }),#{kind:"step",act:|m|{
  let f=shot_frame();if f>=0 && f!=previous {previous=f;cmd("StepSimulation",#{hold:true,steps:2});}
 },done:|m|shot_frame()>=766},once(|m|{cmd("StopOfflineRecording",#{});cmd("SetCelestialClock",#{scale:1.0});})])
}
