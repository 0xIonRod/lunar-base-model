// A real drive followed by a braked hold. No pose, velocity or sleep writes.
const ROOT="/Griffin1SurfaceOps";
fn simulation_dependencies(me,ctx) {
 let r=find_path(ROOT+"/FLIP");let reads=[r];
 for side in ["FL","FR","RL","RR"] {reads.push(find_path(ROOT+"/FLIP/Suspension_"+side+"/Wheel_"+side));}
 #{modelica_entities:[r],entity_reads:reads,entity_writes:[r],query_reads:["QueryPhysicsState"],required_inputs:[]}
}
fn on_start(me,ctx) {
 if !set_physics_substeps(32) || !set_physics_joint_velocity_iterations(128) {throw "Native contact solver quality rejected";}
 let invalid_rejected=false;try {set_physics_joint_velocity_iterations(0);}catch(error){invalid_rejected=true;}
 this.quality_ok=invalid_rejected && physics_substeps()==32 && physics_joint_velocity_iterations()==128;
 print("PHYSICS_PROFILE|"+physics_substeps()+"|"+physics_joint_velocity_iterations()+"|"+solver_configuration_fingerprint());
 this.measuring=false;this.start=();this.maximum_speed=0.0;this.maximum_drift=0.0;this.minimum_up=1.0;this.ground=[false,false,false,false];this.samples=0;
 cmd("StepSimulation",#{hold:false});cmd("SetTimeTransport",#{playing:true,rate:1.0});
}
fn drive(throttle,brake) {
 let result=write_ports(find_path(ROOT+"/FLIP"),[["program_active",1.0],["autopilot_enable",0.0],["throttle",throttle],["steer",0.0],["brake",brake]]);
 if !result.ok {throw result.to_string();}
}
fn begin_hold(me) {this.start=world_pos(find_path(ROOT+"/FLIP"));this.measuring=true;print("BRAKE_HOLD_BEGIN|"+this.start);}
fn finish_hold(me) {
 this.measuring=false;let r=find_path(ROOT+"/FLIP");let state=query("QueryPhysicsState",#{id:r});let contacts=0;for c in this.ground {if c {contacts+=1;}}
 print("BRAKE_HOLD_RESULT|"+this.maximum_drift+"|"+this.maximum_speed+"|"+this.minimum_up+"|"+contacts+"|"+this.samples);
 this.checks=[t_true(this.quality_ok,"native solver quality is explicit and invalid budgets are rejected"),t_true(this.maximum_drift<0.02,"braked rover moves less than two centimetres in sixty seconds"),t_true(this.maximum_speed<0.02,"braked speed remains below two centimetres per second"),t_true(contacts==4,"all four wheels retain loaded ground contact"),t_true(this.minimum_up>0.96,"rover stays upright"),t_true(state.body_mode=="dynamic","holding is native dynamic contact, not a frozen body"),t_true(this.samples>=3500,"complete fixed-step observation horizon")];
}
fn restart(me) {this.restart_position=world_pos(find_path(ROOT+"/FLIP"));drive(0.25,0.0);}
fn confirm_restart(me) {let p=world_pos(find_path(ROOT+"/FLIP"));let dx=p[0]-this.restart_position[0];let dz=p[2]-this.restart_position[2];let distance=sqrt(dx*dx+dz*dz);print("BRAKE_RELEASE_RESULT|"+distance);this.checks.push(t_true(distance>0.2,"releasing brake and commanding drive moves the native dynamic rover again"));report_verdict(this.checks,"FLIP PARKING AND BRAKE RELEASE","FLIP_PARKING_BRAKE");drive(0.0,1.0);cmd("SetTimeTransport",#{playing:false,rate:1.0});cmd("StepSimulation",#{hold:true});}
fn task(me,ctx) {seq([wait(3.0),once(|m|drive(0.25,0.0)),wait(6.0),once(|m|drive(0.0,1.0)),wait(10.0),once(Fn("begin_hold")),wait(60.0),once(Fn("finish_hold")),once(Fn("restart")),wait(3.0),once(Fn("confirm_restart"))])}
fn on_tick(me,ctx) {
 if !this.measuring {return;}
 let r=find_path(ROOT+"/FLIP");let p=world_pos(r);let dx=p[0]-this.start[0];let dz=p[2]-this.start[2];let dy=p[1]-this.start[1];this.maximum_drift=max(this.maximum_drift,sqrt(dx*dx+dy*dy+dz*dz));
 let state=query("QueryPhysicsState",#{id:r});let v=state.linear_velocity_mps;this.maximum_speed=max(this.maximum_speed,sqrt(v[0]*v[0]+v[1]*v[1]+v[2]*v[2]));this.minimum_up=min(this.minimum_up,world_up3(r).y);
 let i=0;for side in ["FL","FR","RL","RR"] {let c=contact_debug(find_path(ROOT+"/FLIP/Suspension_"+side+"/Wheel_"+side));if c!=() && c.total_normal_impulse>0.0 {this.ground[i]=true;}i+=1;}
 this.samples+=1;
}
