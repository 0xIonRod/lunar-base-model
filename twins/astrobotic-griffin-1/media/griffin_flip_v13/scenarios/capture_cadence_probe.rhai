// @timing presentation
// Observe native recorder cadence without a second per-image step requester.
fn on_start(me,ctx) {
 this.samples=0;
 cmd("StepSimulation",#{hold:true});
 cmd("SetTimeTransport",#{playing:true,rate:1.0});
}
fn task(me,ctx) {
 let previous=0;
 seq([once(|m|cmd("StartOfflineRecording",#{output_dir:ctx.output_path,fps:30})),
 wait_until(|m|query("GetOfflineRecordingStatus",#{}).active),
 once(|m|cmd("StepSimulation",#{hold:false})),
 #{kind:"step",act:|m|{
  let status=query("GetOfflineRecordingStatus",#{});
  if status.frame_index>previous {
   previous=status.frame_index;
   let clock=clock_snapshot();
   print("CAPTURE_IMAGE|"+status.frame_index+"|"+status.last_capture_sim_tick+"|"+clock.sim_tick+"|"+clock.queued_simulation_steps);
  }
 },done:|m|shot_frame()>=ctx.frames},
 once(|m|cmd("StepSimulation",#{hold:true})),once(|m|cmd("StopOfflineRecording",#{}))])
}
fn on_tick(me,ctx) {
 this.samples+=1;
 if this.samples%6!=0 {return;}
 for side in ["FL","FR","RL","RR"] {
  let wheel=find_path("/Griffin1SurfaceOps/FLIP/Suspension_"+side+"/Wheel_"+side);
  let p=world_pos(wheel);let ground=query("TerrainHeight",#{x:p[0],z:p[2]});
  if !ground.found {throw "Wheel probe requires measured terrain";}
  let n=vec3(ground.normal[0],ground.normal[1],ground.normal[2]);
  let axle=qrot(world_rotation_quat(wheel),vec3(1.0,0.0,0.0));
  let a=abs(axle.x*n.x+axle.y*n.y+axle.z*n.z);
  let support=0.465*sqrt(max(0.0,1.0-a*a))+0.14*a;
  let gap=(p[1]-ground.height)*n.y-support;
  let contact=contact_debug(wheel);
  print("WHEEL_GAP|"+shot_frame()+"|"+side+"|"+gap+"|"+contact);
 }
}
