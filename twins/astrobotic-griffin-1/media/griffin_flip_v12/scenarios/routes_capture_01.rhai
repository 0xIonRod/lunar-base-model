// @timing presentation
// Five times normal motion, using ten native 60 Hz cycles per 30 fps image.
fn on_start(me,ctx) {cmd("ActivatePerspective",#{id:"sandbox_view"});cmd("SetUserCamera",#{name:"Avatar"});cmd("SetTimeTransport",#{playing:true,rate:1.0});cmd("StepSimulation",#{hold:true});}
fn task(me,ctx) {let prev=-1;seq([once(|m|cmd("StartOfflineRecording",#{output_dir:"/home/rod/Documents/lunco/griffin-presentation/campaigns/lunar-missions/griffin_flip_v12/renders/sources/routes/take-01.mp4",fps:30})),#{kind:"step",act:|m|{let f=shot_frame();if f>=0 && f!=prev {prev=f;cmd("StepSimulation",#{hold:true,steps:10});}},done:|m|shot_frame()>=4800},once(|m|cmd("StopOfflineRecording",#{}))])}
