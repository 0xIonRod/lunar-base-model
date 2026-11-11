// Attach to the scene root in a production graphics session. This observer
// checks annotation publication without replacing the mission program.
const TEST_KIND = "graphics";
const ROOT = "/Griffin1SurfaceOps";
const TARGET = ROOT + "/LandingTarget";
const PAD = ROOT + "/LandingPad";

fn simulation_dependencies(me, ctx) {
    let reads = [find_path(TARGET), find_path(PAD+"/TopPlate"),
        find_path(PAD+"/SurfaceDecal"), find_path(ROOT+"/Lander")];
    if ctx.landed==true && ctx.headless!=true {
        let ramp = if griffin_compact_egress::enabled() {"CompactEgress"} else {"EgressRampPort"};
        reads.push(find_path(ROOT+"/Lander/"+ramp));
        if griffin_compact_egress::enabled() {reads.push(find_path(ROOT+"/Lander/CompactEgress/RouteEntryAnnotation"));}
    }
    for name in ["RoverRampApproach", "RoverRampExit", "RoverTarget1", "RoverTarget2", "BaseSite"] {
        reads.push(find_path(ROOT + "/" + name));
    }
    #{modelica_entities: [], entity_reads: reads, entity_writes: [],
      query_reads: ["QueryUsdPrim", "TerrainHeight",
        "AnalyzeSysml", "ValidateSysml", "ReadActiveTwinContract", "ScriptInspect", "GetReadiness", "SceneCameraAudit"],
      required_inputs: [#{owner:"sysml.twin-analysis",identity:twin_name()}]}
}

fn on_start(me, ctx) {
    this.done=false;this.ticks=0;this.entry_local=();
    this.landed=ctx.landed==true;this.presented=false;
    this.attached_entry=this.landed && griffin_compact_egress::enabled();
    this.headless=ctx.headless==true;
}

fn on_tick(me, ctx) {
    if this.done {return;}
    this.ticks+=1;
    if this.headless {
        let ready=query("GetReadiness",#{});
        let rendered=false;
        for camera in query("SceneCameraAudit",#{}).candidates {
            if camera.render_camera {rendered=true;}
        }
        let p=world_pos3(find_path(TARGET));let h=terrain_height(p.x,p.z);
        this.done=true;
        report_verdict([
            t_true(!rendered,
                "headless scene has no render camera products"),
            t_true(ready.ready==true && ready.faulted==false && ready.world_hold==false,
                "presentation does not hold headless simulation"),
            t_true(abs(p.y-h-griffin_spec::_sysml_attribute("landingVehicleReferenceTouchdownY"))<0.001,
                "headless navigation retains its touchdown reference"),
        ],"GRIFFIN HEADLESS ANNOTATIONS","GRIFFIN_HEADLESS_ANNOTATIONS");
        return;
    }
    if this.landed && !this.presented {
        let frame=griffin_surface_ops::landed_surface_route_frame();
        this.plan=griffin_surface_ops::surface_route_presentation_plan(frame);
        let result=griffin_surface_ops::present_surface_route(frame);
        if result.ok!=true {throw "Landed route presentation failed: "+result;}
        this.presented=true;return;
    }
    let top=query("QueryUsdPrim",#{path:PAD+"/TopPlate",attrs:["physics:collisionEnabled"]});
    let decal=query("QueryUsdPrim",#{path:PAD+"/SurfaceDecal",attrs:["physics:collisionEnabled"]});
    if top==() || decal==() {return;}
    if this.attached_entry {
        let entry_id=find_path(ROOT+"/Lander/CompactEgress/RouteEntryAnnotation");
        if entry_id<0 {return;}
        let lander=find_path(ROOT+"/Lander");
        let local=qrot(quat_inverse(world_rotation_quat(lander)),world_pos3(entry_id)-world_pos3(lander));
        if this.entry_local==() {this.entry_local=local;this.entry_tick=this.ticks;return;}
        if this.ticks-this.entry_tick<60 {return;}
        this.entry_local_delta=vlen(local-this.entry_local);
    }
    this.done=true;
    let checks=[];
    checks.push(t_true(top.attrs["physics:collisionEnabled"]==false
        && decal.attrs["physics:collisionEnabled"]==false,
        "landing pad presentation leaves contact to the terrain"));
    let mark=query("QueryUsdPrim",#{path:TARGET+"/SurfaceMark",attrs:["visibility"]});
    checks.push(t_true(mark!=() && mark.attrs.visibility=="invisible",
        "the replaced guidance mark stays hidden"));
    let pose=world_pos3(find_path(TARGET));let ground=terrain_height(pose.x,pose.z);
    checks.push(t_true(abs(pose.y-ground-griffin_spec::_sysml_attribute("landingVehicleReferenceTouchdownY"))<0.001,
        "surface presentation preserves the navigation touchdown reference"));
    let dome=query("QueryUsdPrim",#{path:TARGET+"/Dome",attrs:["visibility","xformOp:translate"]});
    checks.push(t_true(dome.attrs.visibility=="invisible" && dome.attrs["xformOp:translate"]==(),
        "the footprint template carries no vehicle-height offset"));
    for name in ["RoverRampApproach", "RoverRampExit", "RoverTarget1", "RoverTarget2", "BaseSite"] {
        let path=if this.attached_entry && name=="RoverRampApproach" {ROOT+"/Lander/CompactEgress/RouteEntryAnnotation"} else {ROOT+"/"+name};
        let p=world_pos3(find_path(path));let h=terrain_height(p.x,p.z);
        let marker=query("QueryUsdPrim",#{path:path,attrs:["lunco:billboard:fadeEnd"]});
        checks.push(t_true(h!=() && p.y-h>=0.049
            && marker.attrs["lunco:billboard:fadeEnd"]==griffin_spec::_sysml_attribute("surfaceRouteMarkerFadeEndM"),
            name+" has surface support and the descent display range"));
    }
    if this.landed {
        let entry_path=if this.attached_entry {ROOT+"/Lander/CompactEgress/RouteEntryAnnotation"}else{ROOT+"/RoverRampApproach"};
        let entry=world_pos3(find_path(entry_path));
        checks.push(t_true(vlen(entry-vec3_from(this.plan.points[0].expected_position_m))<0.03
            && entry.y-griffin_surface_ops::surface_route_entry_height(entry)>=0.049,
            "landed entry follows the payload deck while other markers follow terrain"));
        if this.attached_entry {checks.push(t_true(this.entry_local_delta<0.001,
            "landed entry remains fixed to the moving payload deck"));}
    }
    let rejected=false;
    try {griffin_surface_ops::surface_route_target(vec3(0.0,0.0,0.0),
        #{origin:vec3(1.0e15,0.0,1.0e15),forward:vec3(1.0,0.0,0.0),lateral:vec3(0.0,0.0,1.0)});}
    catch(error){rejected=true;}
    checks.push(t_true(rejected,"missing terrain cannot fabricate a route support height"));
    let decal_pos=world_pos3(find_path(PAD+"/SurfaceDecal"));
    let decal_ground=terrain_height(decal_pos.x,decal_pos.z);
    checks.push(t_true(decal_ground!=() && decal_pos.y>decal_ground
        && decal_pos.y-decal_ground<0.1,
        "landing decal remains just above the terrain"));
    report_verdict(checks,"GRIFFIN LANDING ANNOTATIONS","GRIFFIN_LANDING_ANNOTATIONS");
}
