// @timing presentation
// Camera-only take. Native orbital view, native input, native terrain and ephemeris.
fn zoom_altitude(f,initial) {
 if f<120 {let u=(f-30).to_float()/90.0;return initial*exp(ln(160000.0/initial)*u);}
 if f<150 {let u=(f-120).to_float()/30.0;return 160000.0*exp(ln(1000.0/160000.0)*u);}
 let u=((f-150).to_float()/180.0).clamp(0.0,1.0);let e=u*u*(3.0-2.0*u);1000.0*exp(ln(35.0/1000.0)*e)
}
fn task(me,ctx) {
 let previous=-1;let previous_radius=5212200.0;let initial_altitude=3474800.0;
 seq([
 once(|m|cmd("SetCameraInput",#{surface_mode_engage_altitude_m:5.0,surface_mode_disengage_altitude_m:10.0})),
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
  initial_altitude=world_pos(find_path("/Griffin1SurfaceOps/Avatar"))[1];previous_radius=1737400.0+initial_altitude;
  cmd("StartOfflineRecording",#{output_dir:"/home/rod/Documents/lunco/griffin-presentation/campaigns/lunar-missions/griffin_flip_v12/renders/sources/moon-zoom/take-03.mp4",fps:30});
 }),#{kind:"step",act:|m|{
  let f=shot_frame();if f<0 || f==previous {return;}previous=f;
  if f>=30 && f<=330 {
   let altitude=zoom_altitude(f,initial_altitude);
   let radius=1737400.0+altitude;let delta=(previous_radius/radius).ln()/0.05;
   previous_radius=radius;
   cmd("InjectWindowInput",#{event:#{Scroll:#{x:0.0,y:delta}}});
  }
  if f%30==0 {print("MOON_ZOOM|"+f+"|"+world_pos(find_path("/Griffin1SurfaceOps/Avatar")));}
 },done:|m|shot_frame()>=390},once(|m|cmd("StopOfflineRecording",#{}))])
}
