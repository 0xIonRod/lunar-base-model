// @timing presentation
const ROOT="/Griffin1SurfaceOps";
fn on_start(me,ctx) {
    cmd("StepSimulation",#{hold:true});
    this.released=false;this.last_frame=-1;
}
fn ready(me) {query("GetReadiness",#{}).ready}
fn settled(me) {clock_snapshot().queued_simulation_steps==0}
fn prepare(me) {
    cmd("SetUserCamera",#{name:"DescentWide"});
    follow_lander();
    cmd("ActivatePerspective",#{id:"sandbox_view"});
    set_twin_setting("ui.camera_status",false);
    set_twin_setting("ui.vehicle_controls",false);
    set_twin_setting("ui.mission_notifications",false);
    clear_guided_hud_actions("griffin-controls");
    clear_hint("griffin-controls");
    objectives_hud("griffin-controls",[]);
    cmd("StepSimulation",#{hold:true,steps:120});
}
fn begin_recording(me) {
    let g=find_path(ROOT+"/Lander/GNC");
    let hud=cmd_data("CreateGraphHud",#{}).hud;
    let entries=[#{target_gid:g,signal:"measured_altitude",caption:"Altitude"},
        #{target_gid:g,signal:"throttle_cmd",caption:"Engine throttle"}];
    let configured=cmd("SetGraphHud",#{hud:hud,visible:true,columns:1,
        width:420.0,height:450.0,x:850.0,y:120.0,signals:entries});
    if configured.ok!=true {throw "Opening telemetry graph rejected";}
}
fn ui_ready(me) {
    let huds=query("InspectGraphHud",#{}).huds;
    if huds.len()==0 {return false;}
    huds[0].rendered
}
fn start_recording(me) {
    cmd("StartOfflineRecording",#{output_dir:"C:/Users/salek/OneDrive/Desktop/NASA-lunar-base-model/output/griffin-flip-review/full_rebuild_v18/sources/opening-native-05.mp4",fps:30});
}
fn follow_lander() {
    let p=world_pos(find_path(ROOT+"/Lander"));
    let camera=find_path(ROOT+"/DescentWide");
    cmd("SetCameraLookAt",#{camera:camera,eye:[p[0]+25.0,p[1]+7.0,p[2]-35.0],target:[p[0]-5.0,p[1]+1.0,p[2]-4.0]});
}
fn record_frame(me) {
    let status=query("GetOfflineRecordingStatus",#{});
    if !status.active {return;}
    if !this.released {cmd("StepSimulation",#{hold:false});this.released=true;}
    let f=status.frame_index.to_int();
    if f==this.last_frame {return;}
    this.last_frame=f;
    follow_lander();
    if f%30==0 {
        let body=find_path(ROOT+"/Lander");let p=world_pos(body);
        let tick=clock_snapshot().sim_tick;
        print("V18_OPENING|"+f+"|"+tick+"|"+p[1]);
    }
}
fn complete(me) {shot_frame()>=480}
fn finish(me) {
    cmd("StopOfflineRecording",#{});cmd("StepSimulation",#{hold:true});
    print("V18_OPENING_CAPTURE_COMPLETE");
}
fn task(me,ctx) {
    seq([wait_until(Fn("ready")),once(Fn("prepare")),wait_until(Fn("settled")),
        once(Fn("begin_recording")),wait_until(Fn("ui_ready")),once(Fn("start_recording")),#{kind:"step",act:Fn("record_frame"),done:Fn("complete")},
        once(Fn("finish"))])
}
