// @timing presentation
// Native orbital camera; one presentation update per captured image.
const ROOT="/Griffin1SurfaceOps";
fn on_start(me,unused) {
 cmd("StepSimulation",#{hold:true});cmd("SetTimeTransport",#{playing:true,rate:1.0});
 set_twin_setting("ui.camera_status",false);set_twin_setting("ui.mission_notifications",false);
 cmd("ActivatePerspective",#{id:"sandbox_view"});
 this.phase=0;this.previous_frame=-1;this.previous_image=-1;this.previous_tick=();this.previous_mode="held";this.started=false;
}
fn on_tick(me,unused) {
 let now=clock_snapshot().wall_elapsed_s;
 if this.phase==0 {
  if !query("GetReadiness").ready {return;}
  let capture=query("QueryUsdPrim",#{path:ROOT+"/FilmCapture",attrs:["film:output_path","film:frames","film:pre_steps"]});
  if capture.doc_id==() || capture.attrs["film:output_path"]==() {throw "Orbital recording requires its mounted scene configuration";}
  this.doc=capture.doc_id;this.output_path=capture.attrs["film:output_path"];this.frames=capture.attrs["film:frames"];
  cmd("StepSimulation",#{hold:true,steps:capture.attrs["film:pre_steps"]});this.phase=1;return;
 }
 if this.phase==1 {
  if clock_snapshot().queued_simulation_steps!=0 || !query("GetReadiness").ready {return;}
  this.radius=query("BodyPosition",#{body:301}).radius;if this.radius<=0.0 {throw "Invalid Moon radius";}
  cmd("SetUserCamera",#{name:"Avatar"});cmd("FocusTarget",#{target:find_path_in_document(this.doc,ROOT+"/SolarSystem/Moon")});
  this.deadline=now+1.0;this.phase=2;return;
 }
 if this.phase==2 {
  if now<this.deadline {return;}
  let p=query("ReadExposures",#{surface:"celestial-view"}).surfaces["celestial-view"].properties.site_orbit_position_m;
  if p==() {throw "The native celestial view has no landing-site orbit direction";}
  cmd("AnimateOrbitCameraDirection",#{yaw_rad:atan(p[0],p[2]),pitch_rad:-atan(p[1],sqrt(p[0]*p[0]+p[2]*p[2])),duration_s:1.0});
  cmd("InjectWindowInput",#{event:#{PointerMove:#{x:1000.0,y:500.0}}});
  this.deadline=now+1.2;this.phase=3;return;
 }
 if this.phase==3 {
  if now<this.deadline {return;}
  let distance=get(find_path_in_document(this.doc,ROOT+"/Avatar"),"OrbitCamera.distance");
  if distance==() || distance-this.radius<100000.0 {throw "The approach must start above the complete Moon";}
  this.initial_altitude=distance-this.radius;this.previous_distance=distance;
  cmd("StartOfflineRecording",#{output_dir:this.output_path,fps:30});this.phase=4;return;
 }
 if this.phase==5 {return;}
 let status=query("GetOfflineRecordingStatus");if !status.active {return;}
 let f=status.frame_index.to_int();
 if status.last_capture_sim_tick==() {
  if f!=0 || status.is_waiting_for_frame {throw "An orbital image is missing its native simulation tick";}
  return;
 }
 let tick=status.last_capture_sim_tick.to_int();let image=if status.is_waiting_for_frame {f}else{f-1};let mode=if this.started {"moving"}else{"held"};
 if image>=0 && image!=this.previous_image {
  let expected=if mode=="held" {0}else{2};
  if this.previous_tick!=() && this.previous_mode==mode && (image!=this.previous_image+1 || tick-this.previous_tick!=expected) {
   throw "Orbital image cadence rejected: image="+image+" tick="+tick+" previous_image="+this.previous_image+" previous_tick="+this.previous_tick;
  }
  print("ZOOM_CAPTURE_IMAGE|"+image+"|"+tick+"|"+mode);
  this.previous_image=image;this.previous_tick=tick;this.previous_mode=mode;
 }
 if f==this.previous_frame {return;}this.previous_frame=f;
 if !this.started && f>=1 {cmd("StepSimulation",#{hold:false});this.started=true;}
 let u=((f-30).to_float()/330.0).clamp(0.0,1.0);let e=u*u*(3.0-2.0*u);
 let altitude=this.initial_altitude*exp(ln(250000.0/this.initial_altitude)*e);let distance=this.radius+altitude;
 let actual=get(find_path_in_document(this.doc,ROOT+"/Avatar"),"OrbitCamera.distance");if actual==() {throw "The shot lost its native orbital camera";}
 cmd("InjectWindowInput",#{event:#{Scroll:#{x:0.0,y:ln(this.previous_distance/distance)/0.05}}});this.previous_distance=distance;
 if f%30==0 {print("MOON_ZOOM|"+f+"|"+world_pos(find_path_in_document(this.doc,ROOT+"/Avatar"))+"|"+actual);}
 if f>=this.frames {
  if abs(actual-distance)>500.0 {throw "The native camera did not reach the regional view";}
  cmd("StepSimulation",#{hold:true});cmd("StopOfflineRecording",#{});this.phase=5;print("MOON_ZOOM_CADENCE_PASS|"+f);
 }
}
