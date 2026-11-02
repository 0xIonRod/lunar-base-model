// Native flight stimulus and observations only; no thermal or gas equations.
const ROOT="/Griffin1SurfaceOps";
fn simulation_dependencies(me,ctx) {
 #{modelica_entities:[find_path(ROOT+"/Lander"),find_path(ROOT+"/Lander/MainPropulsion")],
 entity_reads:[find_path(ROOT+"/Lander/Nozzle/MainEngineCluster/Engine01/Bell")],
 entity_writes:[],query_reads:["ReadPorts"],required_inputs:[]}
}
fn observe() {
 let main=find_path(ROOT+"/Lander/MainPropulsion");
 let names=["engine01_thrust_n","__member_Engine01Wall_wall_temperature_k",
 "__member_Engine01Wall_heating_w","__member_Engine01Wall_radiation_w",
 "__member_Engine01Wall_conduction_w","__member_Engine01Wall_energy_residual_w"];
 print("NOZZLE_STATE|"+clock_snapshot().sim_tick+"|"+query("ReadPorts",#{api_id:main,port_names:names}));
 let bell=find_path(ROOT+"/Lander/Nozzle/MainEngineCluster/Engine01/Bell");
 print("NOZZLE_GPU|"+query("ReadPorts",#{api_id:bell,port_names:["temperature_k","emissivity"]}));
}
fn on_start(me,ctx) {
 this.elapsed=0.0;this.stage=0;this.cooling=0.0;this.sample=0.0;
 set_twin_setting("ui.camera_status",false);set_twin_setting("ui.vehicle_controls",false);
 set_twin_setting("ui.mission_notifications",false);
 cmd("ActivatePerspective",#{id:"sandbox_view"});
 cmd("SetTimeTransport",#{playing:true,rate:1.0});cmd("StepSimulation",#{hold:false});
}
fn on_tick(me,ctx) {
 this.elapsed+=dt();this.sample+=dt();
 if this.stage<3 && this.sample>=0.5 {observe();this.sample=0.0;}
 if this.stage==0 && this.elapsed>=8.0 {
  let p=world_pos(find_path(ROOT+"/Lander"));
  cmd("SetUserCamera",#{name:"Avatar"});
  cmd("SetCameraLookAt",#{camera:find_path(ROOT+"/Avatar"),
   eye:[p[0]+3.0,p[1]-2.5,p[2]+3.0],target:[p[0],p[1]-0.3,p[2]]});
  observe();print("NOZZLE_POWERED_VIEW_READY");
  this.stage=1;cmd("StepSimulation",#{hold:true});
 }else if this.stage==1 {
  // Resuming the held world continues the actual native landing, then cooling.
  let lander=find_path(ROOT+"/Lander");
  if get(lander,"landing_engine_cutoff")>0.5 {this.stage=2;observe();print("NOZZLE_CUTOFF");}
 }else if this.stage==2 {
  this.cooling+=dt();
  if this.cooling>=8.0 {observe();print("NOZZLE_COOLING_VIEW_READY");this.stage=3;cmd("StepSimulation",#{hold:true});}
 }
}
