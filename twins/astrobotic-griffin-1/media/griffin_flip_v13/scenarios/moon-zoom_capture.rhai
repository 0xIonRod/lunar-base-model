// @timing presentation
// Camera-only take. Native orbital view, native input, native terrain and ephemeris.
fn lerp3(a,b,t) {let u=1.0-t;[a[0]*u+b[0]*t,a[1]*u+b[1]*t,a[2]*u+b[2]*t]}
fn zoom_altitude(f,initial) {
 if f<120 {let u=(f-30).to_float()/90.0;return initial*exp(ln(160000.0/initial)*u);}
 if f<150 {let u=(f-120).to_float()/30.0;return 160000.0*exp(ln(1000.0/160000.0)*u);}
 let u=((f-150).to_float()/180.0).clamp(0.0,1.0);let e=u*u*(3.0-2.0*u);1000.0*exp(ln(35.0/1000.0)*e)
}
fn on_start(me,ctx) {
 cmd("SetTimeTransport",#{playing:true,rate:1.0});
 cmd("SetPorts",#{target:find_path("/Griffin1SurfaceOps/FLIP"),writes:[["program_active",1.0],["autopilot_enable",0.0],["throttle",0.0],["steer",0.0],["brake",1.0]]});
 cmd("StepSimulation",#{hold:true,steps:182});
}
fn task(me,ctx) {
 let previous=-1;let previous_radius=5212200.0;let initial_altitude=3474800.0;let eye0=();let target0=();let eye1=();let target1=();
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
  cmd("StartOfflineRecording",#{output_dir:"/home/rod/Documents/lunco/lunco-marketing/campaigns/lunar-missions/griffin_flip_v13/renders/sources/moon-zoom/take-01.mp4",fps:30});
 }),#{kind:"step",act:|m|{
  let f=shot_frame();if f<0 || f==previous {return;}previous=f;
  if f>=30 && f<=330 {
   let altitude=zoom_altitude(f,initial_altitude);
   let radius=1737400.0+altitude;let delta=(previous_radius/radius).ln()/0.05;
   previous_radius=radius;
   cmd("InjectWindowInput",#{event:#{Scroll:#{x:0.0,y:delta}}});
  }
  if f==330 {
   let camera=find_path("/Griffin1SurfaceOps/Avatar");eye0=world_pos(camera);let v=world_forward3(camera);
   target0=[eye0[0]+10.0*v.x,eye0[1]+10.0*v.y,eye0[2]+10.0*v.z];
   let r=world_pos(find_path("/Griffin1SurfaceOps/FLIP"));eye1=[r[0]+5.0,r[1]+5.5,r[2]+8.0];target1=[r[0],r[1]+0.7,r[2]];
  }
  if f>330 {
   let u=((f-330).to_float()/60.0).clamp(0.0,1.0);let e=u*u*(3.0-2.0*u);
   let eye=lerp3(eye0,eye1,e);let target=lerp3(target0,target1,e);
   cmd("SetCameraLookAt",#{camera:find_path("/Griffin1SurfaceOps/Avatar"),eye:eye,target:target});
  }
  if f%30==0 {print("MOON_ZOOM|"+f+"|"+world_pos(find_path("/Griffin1SurfaceOps/Avatar")));}
 },done:|m|shot_frame()>=390},once(|m|cmd("StopOfflineRecording",#{}))])
}
