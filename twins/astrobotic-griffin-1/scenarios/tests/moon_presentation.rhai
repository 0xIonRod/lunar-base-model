// @timing presentation
fn simulation_dependencies(me,params) {
    #{modelica_entities:[],entity_reads:[],entity_writes:[],
      query_reads:["GetReadiness","RuntimeDiagnostics","ReadExposures","SceneCameraAudit","QueryUsdPrim"],
      required_inputs:[]}
}
fn on_start(me,params) {this.done=false;}
fn on_tick(me,params) {
    if this.done {return;}this.done=true;
    let root="/Griffin1SurfaceOps";let path=root+"/MoonView";
    let ready=query("GetReadiness");let diagnostics=query("RuntimeDiagnostics");
    let selected=query("ReadExposures",#{surface:"camera-status"}).surfaces["camera-status"].properties;
    let camera=query("QueryUsdPrim",#{path:path,attrs:["clippingRange","lunco:cameraLookAt"]});
    let range=camera.attrs.clippingRange;
    let distance=vlen(vsub(camera.world_position,camera.attrs["lunco:cameraLookAt"]));
    let active=[];
    for candidate in query("SceneCameraAudit").candidates {
        if candidate.scene_camera && candidate.camera_active && candidate.render_target=="window" {active.push(candidate);}
    }
    let rendered=active.len()==1 && active[0].usd_path==path;
    let sized=rendered && active[0].physical_viewport_size!=()
        && active[0].physical_viewport_size[0]>0 && active[0].physical_viewport_size[1]>0;
    let environment=query("QueryUsdPrim",#{path:root+"/Environment",attrs:[]});
    let terrain=query("QueryUsdPrim",#{path:root+"/Environment/Terrain",attrs:["visibility"]});
    let site=query("QueryUsdPrim",#{path:root,attrs:["lunco:anchor:body","lunco:anchor:lat","lunco:anchor:lon"]});
    let sun=query("QueryUsdPrim",#{path:root+"/Sun",attrs:[]});
    report_verdict([
        t_true(ready.ready && !ready.faulted && !ready.world_hold && ready.pending_count==0,"Moon scene readiness is clear"),
        t_true(diagnostics.errors==0,"Moon scene diagnostics: "+diagnostics),
        t_true(selected.active_name==path,"Moon scene selects its authored MoonView"),
        t_true(rendered,"exactly the selected Moon camera renders the window"),
        t_true(sized,"the Moon camera has a non-empty rendered viewport"),
        t_true(range[0]>0.0 && range[1]>range[0],"Moon camera has a valid positive clipping interval"),
        t_true(range[1]>distance,"Moon camera far plane excludes its authored target: far="+range[1]+" m target="+distance+" m"),
        t_true(environment.active && terrain.active,"real site surface data remains active"),
        t_true(terrain.attrs.visibility=="invisible","local site mesh is hidden for the orbital view"),
        t_true(site.attrs["lunco:anchor:body"]!=() && site.attrs["lunco:anchor:lat"]!=()
            && site.attrs["lunco:anchor:lon"]!=() && sun.active,"site observer and scene Sun remain available")
    ],"MOON PRESENTATION","MOON_PRESENTATION");
}
