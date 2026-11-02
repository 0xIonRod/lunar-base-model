// @timing presentation
// Controlled engine-off drop: identical lander, terrain and camera per case.
fn on_start(me,ctx) {
 set_twin_setting("ui.camera_status",false);set_twin_setting("ui.vehicle_controls",false);set_twin_setting("ui.mission_notifications",false);clear_guided_hud_actions("griffin-controls");clear_hint("griffin-controls");objectives_hud("griffin-controls",[]);
 cmd("StepSimulation",#{hold:true});
 cmd("SetTimeTransport",#{playing:true,rate:1.0});
 cmd("SetUserCamera",#{name:"DropView"});
 cmd("SetTerrainRenderingQuality",#{tile_resolution:65,cinematic_resolution:2049,tile_budget:256,pixel_error:2.0,max_depth:9});
}
fn task(me,ctx) {
 let previous=-1;let seen_contact=false;let samples=0;
 seq([
  once(|m|{cmd("StartOfflineRecording",#{output_dir:"/home/rod/Documents/lunco/lunco-marketing/campaigns/lunar-missions/griffin_flip_v13/renders/sources/drop-high/take-headful-02.mp4",fps:30});}),
  #{kind:"step",act:|m|{
   let f=shot_frame();set_twin_setting("ui.camera_status",false);set_twin_setting("ui.vehicle_controls",false);set_twin_setting("ui.mission_notifications",false);clear_guided_hud_actions("flip-panel:/Griffin1SurfaceOps/FLIP");clear_hint("flip-panel:/Griffin1SurfaceOps/FLIP");clear_guided_hud_actions("griffin-controls");clear_hint("griffin-controls");objectives_hud("griffin-controls",[]);
   if f>=0 && f!=previous {
    previous=f;cmd("StepSimulation",#{hold:true,steps:2});
    let lander=find_path("/Griffin1SurfaceOps/Lander");
    let state=query("QueryPhysicsState",#{id:lander});
    let p=query("QueryEntity",#{id:lander}).position;
    let ports=query("ReadPorts",#{api_id:lander,port_names:["any_leg_contact","landing_engine_cutoff","minimum_leg_compression","leg_force_px","leg_force_nx","leg_force_pz","leg_force_nz"]}).ports;
    let propulsion=find_path("/Griffin1SurfaceOps/Lander/MainPropulsion");
    let engine=query("ReadPorts",#{api_id:propulsion,port_names:["engine01_thrust_n","engine02_thrust_n","engine03_thrust_n","engine04_thrust_n","engine05_thrust_n","engine06_thrust_n","engine07_thrust_n"]}).ports;
    let thrust=0.0; for e in engine { thrust+=e.value; }
    if !thrust.is_finite() || thrust.abs()>0.01 {throw "Engine-off drop has nonzero or invalid thrust";}
    let values=#{};
    for port in ports { values[port.name]=port.value; }
    if values.any_leg_contact>0.5 {seen_contact=true;}
    samples+=1;
    let load=values.leg_force_px+values.leg_force_nx;
    load+=values.leg_force_pz+values.leg_force_nz;
    let row="DROP_CSV|"+f+"|"+p[1];
    row+="|"+state.linear_velocity_mps[1];
    row+="|"+values.any_leg_contact+"|"+values.landing_engine_cutoff;
    row+="|"+values.minimum_leg_compression+"|"+load+"|"+thrust;
    print(row);
   }
  },done:|m|shot_frame()>=180},
  once(|m|{if !seen_contact || samples<175 {throw "Incomplete drop/contact evidence";}print("DROP_NATIVE_PASS|high|"+samples);cmd("StopOfflineRecording",#{});}),
  once(|m|cmd("StepSimulation",#{hold:true}))
 ])
}
