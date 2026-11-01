// @timing presentation
// Native exact fixed cycles: two 60 Hz cycles per 30 fps image.
fn on_start(me,ctx) {cmd("SetTimeTransport",#{playing:true,rate:1.0});cmd("StepSimulation",#{hold:true,steps:182});}
fn task(me,ctx) {
 let prev=-1;
 seq([wait(2.0),once(|m|cmd("StartOfflineRecording",#{output_dir:"/home/rod/Documents/lunco/griffin-presentation/campaigns/lunar-missions/griffin_flip_v12/renders/sources/drive/take-03.mp4",fps:30})),
 #{kind:"step",act:|m|{let f=shot_frame();if f>=0 && f!=prev {prev=f;cmd("StepSimulation",#{hold:true,steps:2});}},done:|m|shot_frame()>=2800},once(|m|cmd("StopOfflineRecording",#{}))])
}
