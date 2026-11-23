// @timing presentation
const ROOT="/Griffin1SurfaceOps";
fn on_start(me,ctx) {
    cmd("StepSimulation",#{hold:true});
    if !set_physics_substeps(32) {throw "Required native substeps rejected";}
    if !set_physics_joint_velocity_iterations(128) {throw "Required joint iterations rejected";}
    this.released=false;this.previous_frame=-1;this.samples=[];
}
fn ready(me) {query("GetReadiness",#{}).ready}
fn begin(me) {
    this.doc=query("QueryUsdPrim",#{path:ROOT}).doc_id;
    cmd("SetGraphHud",#{visible:false});
    cmd("ActivatePerspective",#{id:"sandbox_view"});
    set_twin_setting("ui.camera_status",false);
    set_twin_setting("ui.vehicle_controls",false);
    set_twin_setting("ui.mission_notifications",false);
    cmd("SetUserCamera",#{name:"V18Camera"});
    let camera=find_path(ROOT+"/V18Camera");
    cmd("SetCameraLookAt",#{camera:camera,eye:[-9, 4, -12],target:[0.0,1.3,0.0]});
    cmd("StartOfflineRecording",#{output_dir:"C:/Users/salek/OneDrive/Desktop/NASA-lunar-base-model/output/griffin-flip-review/full_rebuild_v18/sources/drop_high-native-01.mp4",fps:30});
}
fn force(name) {
    let id=find_path_in_document(this.doc,ROOT+"/Lander/"+name);
    let result=query("ReadPorts",#{api_id:id,port_names:["contact_force"]});
    for row in result.ports {
        if row.name=="contact_force" && row.direction=="out" {
            if row.value==() || !row.value.is_finite() {throw "Invalid footpad force";}
            return row.value;
        }
    }
    throw "Missing measured footpad contact force";
}
fn observe(me) {
    let status=query("GetOfflineRecordingStatus",#{});
    if !status.active {return;}
    let f=status.frame_index.to_int();
    if f==this.previous_frame {return;}
    this.previous_frame=f;
    if !this.released && f>=1 {cmd("StepSimulation",#{hold:false});this.released=true;}
    let r=find_path_in_document(this.doc,ROOT+"/Lander");
    let velocity=query("QueryPhysicsState",#{id:r}).linear_velocity_mps;let tick=clock_snapshot().sim_tick;
    let forces=[this.force("LegPX"),this.force("LegNX"),this.force("LegPZ"),this.force("LegNZ")];
    this.samples.push(#{frame:f,tick:tick,velocity:velocity,forces:forces});
}
fn complete(me) {shot_frame()>=180}
fn finish(me) {
    cmd("StopOfflineRecording",#{});cmd("StepSimulation",#{hold:true});
    this.complete=true;
}
fn task(me,ctx) {
    seq([wait_until(Fn("ready")),once(Fn("begin")),
        #{kind:"step",act:Fn("observe"),done:Fn("complete")},once(Fn("finish"))])
}
