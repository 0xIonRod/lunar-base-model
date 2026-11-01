// Native mission stimulus and bounded physical verification.
const ROOT="/Griffin1SurfaceOps";
fn simulation_dependencies(me,ctx) {
 let r=find_path(ROOT+"/FLIP");let t=find_path(ROOT+"/EgressTethers");let c=find_path(ROOT+"/Avatar");
 #{modelica_entities:[r,t],entity_reads:[r,t,c,find_path(ROOT+"/Lander"),find_path(ROOT+"/FLIPPayloadAdapterJoint")],entity_writes:[r,t,c,find_path(ROOT+"/FLIPPayloadAdapterJoint")],query_reads:[],required_inputs:[]}
}
fn clean() {set_twin_setting("ui.vehicle_controls",false);set_twin_setting("ui.camera_status",false);set_twin_setting("ui.mission_notifications",false);}
fn on_start(me,ctx) {clean();cmd("ActivatePerspective",#{id:"sandbox_view"});this.n=0;this.control_start=elapsed_seconds();cmd("SetPorts",#{target:find_path(ROOT+"/FLIP"),writes:[["program_active",1.0],["autopilot_enable",0.0],["throttle",0.0],["steer",0.0],["brake",1.0]]});set_physics_substeps(32);set_physics_joint_velocity_iterations(128);cmd("SetPorts",#{target:find_path(ROOT+"/EgressTethers"),writes:[["attached",0.0]]});cmd("StepSimulation",#{hold:false});cmd("SetTimeTransport",#{playing:true,rate:1.0});}
fn task(me,ctx) {
 seq([wait(4.0),once(|m|{
  let r=find_path(ROOT+"/FLIP");let p=world_pos(r);print("EGRESS_START|"+p);
  cmd("SetUserCamera",#{name:"Avatar"});
  cmd("SetCameraLookAt",#{camera:find_path(ROOT+"/Avatar"),eye:[p[0]+7.0,p[1]+3.0,p[2]+10.0],target:[p[0],p[1]-1.0,p[2]]});
  cmd("SetPorts",#{target:r,writes:[["program_active",1.0],["autopilot_enable",0.0],["throttle",0.0],["steer",0.0],["brake",1.0]]});
  cmd("SetPorts",#{target:find_path(ROOT+"/EgressTethers"),writes:[["attached",1.0]]});
  cmd("DetachJoint",#{target:find_path(ROOT+"/FLIPPayloadAdapterJoint"),intent:"Interactive"});
 }),wait(2.0),once(|m|cmd("SetPorts",#{target:find_path(ROOT+"/FLIP"),writes:[["throttle",0.025],["brake",0.0]]})),wait(50.0),once(|m|{cmd("StepSimulation",#{hold:true});cmd("SetPorts",#{target:find_path(ROOT+"/FLIP"),writes:[["throttle",0.0],["brake",1.0]]});print("EGRESS_TRIAL_END");})])
}
fn on_tick(me,ctx) {
 this.n+=1;
 if elapsed_seconds()-this.control_start>6.0 {
  let r=find_path(ROOT+"/FLIP");let f=world_forward3(r);let v=velocity3(r);let speed=v.x*f.x+v.z*f.z;
  let brake=((speed-0.09)*5.0).clamp(0.0,1.0);
  cmd("SetPorts",#{target:r,writes:[["throttle",0.025],["steer",0.0],["brake",brake]]});
 }
 if this.n%30!=0 {return;}
 let r=find_path(ROOT+"/FLIP");let t=find_path(ROOT+"/EgressTethers");
 print("EGRESS_SAMPLE|"+elapsed_seconds()+"|"+world_pos(r)+"|"+velocity3(r)+"|"+get(t,"rl_tension")+"|"+get(t,"rr_tension"));
}
