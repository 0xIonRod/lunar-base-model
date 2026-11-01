// @timing presentation
// Inspect retained results from the fresh V12 landing. No simulation state edits.
fn on_start(me,ctx) {
 cmd("StepSimulation",#{hold:true});
 set_twin_setting("ui.vehicle_controls",false);
 set_twin_setting("ui.camera_status",false);
 set_twin_setting("ui.mission_notifications",false);
 cmd("SetUserCamera",#{name:"Avatar"});
 cmd("SetCameraLookAt",#{camera:find_path("/Griffin1SurfaceOps/Avatar"),eye:[11.0,6.0,-14.0],target:[2.0,-2.6,0.0]});
}
fn graph(signal,caption,axis) {
 let lander=find_path("/Griffin1SurfaceOps/Lander");
 cmd("SetPlotSignals",#{plot:1,signals:[signal],target_gid:lander});
 cmd("ConfigurePlotBinding",#{plot:1,signal:signal,label:caption,color:[117,212,255]});
 cmd("ConfigureLinePlot",#{plot:1,x_label:"Time (s)",y_label:axis,show_controls:false,show_legend:true,simplified_grid:true,line_width:3.0,text_size:18.0,follow_latest:false,show_latest_value:false,caption:caption});
 cmd("SetTelemetryBrowserView",#{filter:signal,show_internal:true,show_preview:true});
}
fn task(me,ctx) {
 let shown=false;
 seq([
  once(|m|graph("descent_speed","13 connected models · 7,350 model values","Downward speed (m/s)")),
  wait(0.5),
  once(|m|cmd("StartOfflineRecording",#{output_dir:"/home/rod/Documents/lunco/griffin-presentation/campaigns/lunar-missions/griffin_flip_v12/renders/sources/analytics/inspection-01.mp4",fps:30})),
  #{kind:"step",act:|m|{
   let f=shot_frame();
   if f>=240 && !shown {shown=true;graph("minimum_leg_compression","How much do the landing legs compress?","Compression (m)");}
  },done:|m|shot_frame()>=600},
  once(|m|cmd("StopOfflineRecording",#{}))
 ])
}
