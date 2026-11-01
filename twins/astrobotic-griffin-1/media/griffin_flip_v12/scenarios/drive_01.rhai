// Native stimulus + test observer. Camera motion is owned by the USD path.
const R="/Griffin1SurfaceOps/FLIP";
fn simulation_dependencies(me,ctx) {let r=find_path(R);let cam=find_path("/Griffin1SurfaceOps/Avatar");#{modelica_entities:[r],entity_reads:[r,cam,find_path(R+"/SolarMechanism/Photovoltaics")],entity_writes:[r,cam],query_reads:["GetOfflineRecordingStatus","TerrainHeights"],required_inputs:[]}}
fn clean_view() {
 set_twin_setting("ui.camera_status",false);set_twin_setting("ui.vehicle_controls",false);set_twin_setting("ui.mission_notifications",false);clear_guided_hud_actions("flip-panel:"+R);clear_hint("flip-panel:"+R);
 clear_guided_hud_actions("griffin-controls");clear_hint("griffin-controls");objectives_hud("griffin-controls",[]);
}
fn on_start(me,ctx) {
 if !set_physics_substeps(32) || !set_physics_joint_velocity_iterations(128) {throw "Native contact solver quality rejected";}
 print("PHYSICS_PROFILE|"+physics_substeps()+"|"+physics_joint_velocity_iterations()+"|"+solver_configuration_fingerprint());
 this.done=false;this.samples=0;
 cmd("StepSimulation",#{hold:true});cmd("SetTimeTransport",#{playing:false,rate:1.0});clean_view();cmd("ActivatePerspective",#{id:"sandbox_view"});cmd("SetUserCamera",#{name:"PanelHero"});
}
fn drive(throttle,steer,brake) {
 let result=cmd("SetPorts",#{target:find_path(R),writes:[["program_active",1.0],["autopilot_enable",0.0],["throttle",throttle],["steer",steer],["brake",brake]]});
 if result.ok!=true {throw result.to_string();}
}
fn capture_is_running(me) {query("GetOfflineRecordingStatus",#{}).active}
fn wait_for_capture(me) {
 print("DRIVE_READY|"+elapsed_seconds());
 cmd("StepSimulation",#{hold:true});cmd("SetTimeTransport",#{playing:false,rate:1.0});
}
fn phase(name) {print("DRIVE_PHASE|"+shot_frame()+"|"+elapsed_seconds()+"|"+name);}
fn begin_turn(me) {
 let r=find_path(R);let pv=find_path(R+"/SolarMechanism/Photovoltaics");let q=world_rotation_quat(pv);
 let normal=qrot(q,vec3(0.0,1.0,0.0));
 let sun=qrot(q,vec3(port(r,"target_mount_x"),port(r,"target_mount_y"),port(r,"target_mount_z")));
 let angle=atan(normal.z*sun.x-normal.x*sun.z,normal.x*sun.x+normal.z*sun.z);
 let f=world_forward3(r);let p=world_pos(r);let dx=cos(angle)*f.x+sin(angle)*f.z;let dz=-sin(angle)*f.x+cos(angle)*f.z;
 this.turn_start=elapsed_seconds();phase("turn");
 let result=modelica_waypoint(r,[p[0]+100.0*dx,p[1],p[2]+100.0*dz],0.25,0.3,1.0);if !result.ok {throw result.to_string();}
}
fn sun_facing(me) {
 let c=get(find_path(R),"solar_cos_incidence");if c==() {throw "Solar incidence unavailable";}
 if elapsed_seconds()-this.turn_start>20.0 && c<0.94 {throw "The native controller did not reach the Sun-facing heading";}
 c>=0.94
}
fn turn_interval_finished(me) {elapsed_seconds()-this.turn_start>=20.0}
fn plan_climb(me) {
 let r=find_path(R);let p=world_pos(r);let offsets=[[24.0,0.0],[17.0,17.0],[0.0,24.0],[-17.0,17.0],[-24.0,0.0],[-17.0,-17.0],[0.0,-24.0],[17.0,-17.0]];let points=[[p[0],p[2]]];
 for d in offsets {points.push([p[0]+d[0],p[2]+d[1]]);}
 let heights=query("TerrainHeights",#{points:points});let best=();
 for i in 1..heights.len() {if heights[i].found && (best==() || heights[i].height>heights[best].height) {best=i;}}
 if best==() || !heights[0].found || heights[best].height-heights[0].height<0.25 {throw "The sampled terrain does not provide a measurable climb";}
 this.climb_goal=[points[best][0],heights[best].height,points[best][1]];this.climb_turn_start=elapsed_seconds();
 print("CLIMB_TARGET|"+p+"|"+this.climb_goal);phase("climb_align");
 let result=modelica_waypoint(r,this.climb_goal,0.25,0.3,1.0);if !result.ok {throw result.to_string();}
}
fn climb_aligned(me) {
 let error=get(find_path(R),"__member_Drivetrain_guidance_heading_error");
 if error==() {throw "Native heading feedback unavailable";}
 if elapsed_seconds()-this.climb_turn_start>30.0 {throw "Climb heading did not converge";}
 abs(error)<0.15
}
fn begin_climb(me) {
 let r=find_path(R);let goal=this.climb_goal;
 // A stationary side view makes the real climb visible against the ground.
 let p=world_pos(r);let dx=goal[0]-p[0];let dz=goal[2]-p[2];let length=sqrt(dx*dx+dz*dz);
 let normal=qrot(world_rotation_quat(find_path(R+"/SolarMechanism/Photovoltaics")),vec3(0.0,1.0,0.0));
 let horizontal=sqrt(normal.x*normal.x+normal.z*normal.z);
 if length<0.1 || horizontal<0.1 {throw "Climb camera cannot resolve travel and cell-side directions";}
 let mx=p[0]+4.0*dx/length;let mz=p[2]+4.0*dz/length;
 cmd("SetCameraLookAt",#{camera:find_path("/Griffin1SurfaceOps/Avatar"),eye:[mx+9.0*normal.x/horizontal,p[1]+4.0,mz+9.0*normal.z/horizontal],target:[mx,p[1]+0.8,mz]});
 cmd("SetUserCamera",#{name:"Avatar"});
 let result=modelica_waypoint(r,goal,0.10,0.3,0.0);if !result.ok {throw result.to_string();}phase("climb");
}
fn task(me,ctx) {
 seq([wait(3.0),once(Fn("wait_for_capture")),wait_until(Fn("capture_is_running")),once(|m|{clean_view();phase("start");drive(0.10,0.0,0.0);}),wait(8.0),once(|m|cmd("SetUserCamera",#{name:"WheelDetail"})),wait(7.0),once(|m|{cmd("SetUserCamera",#{name:"PanelHero"});phase("first_stop");drive(0.0,0.0,1.0);}),wait(5.0),once(Fn("begin_turn")),wait_until(Fn("sun_facing")),once(|m|{phase("sun_facing");drive(0.0,0.0,1.0);}),wait_until(Fn("turn_interval_finished")),wait(8.0),once(Fn("plan_climb")),wait_until(Fn("climb_aligned")),once(Fn("begin_climb")),wait(15.0),once(|m|{phase("finish");drive(0.0,0.0,1.0);this.done=true;cmd("StopOfflineRecording",#{});cmd("SetTimeTransport",#{playing:false,rate:1.0});})])
}
fn on_tick(me,ctx) {
 if this.done {return;}
 if this.samples%6==0 {
  let r=find_path(R);let p=world_pos(r);let motor=0.0;
  for side in ["FL","FR","RL","RR"] {let v=get(r,"__member_Motor_"+side+"_electrical_power");if v==() || !v.is_finite() {throw "Native motor power unavailable";}motor+=v;}
  let row="DRIVE_SAMPLE";
  for v in [shot_frame(),elapsed_seconds(),p[0],p[1],p[2],get(r,"solar_power"),get(r,"bus_power"),get(r,"battery_soc"),motor,get(r,"__member_Shaft_FL_speed_rad_s"),get(r,"__member_Motor_FL_electrical_power"),get(r,"equipment_power")] {row+="|"+v;}
  print(row);
 }
 this.samples+=1;
}
