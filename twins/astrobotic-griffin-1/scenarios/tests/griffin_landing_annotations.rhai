// Attach to the scene root in a production graphics session. This observer
// checks annotation publication without replacing the mission program.
const TEST_KIND = "graphics";
const ROOT = "/Griffin1SurfaceOps";
const TARGET = ROOT + "/LandingTarget";
const CURVE = TARGET + "/SurfaceMark/Geometry";

fn simulation_dependencies(me, ctx) {
    let reads = [find_path(TARGET), find_path(CURVE), find_path(ROOT+"/Lander"),
        find_path(ROOT+"/Lander/EgressRampPort")];
    for name in ["RoverRampApproach", "RoverRampExit", "RoverTarget1", "RoverTarget2", "BaseSite"] {
        reads.push(find_path(ROOT + "/" + name));
    }
    #{modelica_entities: [], entity_reads: reads, entity_writes: [],
      query_reads: ["QueryUsdPrim", "TerrainHeight", "InspectUsdCurveView",
        "AnalyzeSysml", "ValidateSysml", "ReadActiveTwinContract", "ScriptInspect", "GetReadiness", "SceneCameraAudit"],
      required_inputs: [#{owner:"sysml.twin-analysis",identity:twin_name()}]}
}

fn on_start(me, ctx) {
    subscribe("landing_annotation_ready");this.done=false; this.ticks=0;
    this.landed=ctx.landed==true;this.presented=false;
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
    let target=query("QueryUsdPrim",#{path:TARGET,attrs:["xformOp:translate"]});
    let curve=find_path(CURVE);
    if target==() || target.doc_id==() || curve<0 {return;}
    let view=query("InspectUsdCurveView",#{doc_id:target.doc_id,entity_id:curve});
    if view==() || view.state=="pending" {
        if this.ticks>1800 {this.done=true;report_verdict(["landing annotation publication timed out"],"GRIFFIN LANDING ANNOTATIONS","GRIFFIN_LANDING_ANNOTATIONS");}
        return;
    }
    this.done=true;
    let checks=[];
    checks.push(t_true(view.state=="ready" && view.projection=="terrain_surface"
        && view.applied_revision==view.requested_revision
        && view.result_segment_count==64 && view.displayed_surface_binding_count>0,
        "landing footprint publishes on the terrain surface"));
    checks.push(t_true(view.local_visibility=="hidden",
        "no independent landing mesh intersects the terrain"));
    let pose=world_pos3(find_path(TARGET));let ground=terrain_height(pose.x,pose.z);
    checks.push(t_true(abs(pose.y-ground-griffin_spec::_sysml_attribute("landingVehicleReferenceTouchdownY"))<0.001,
        "surface presentation preserves the navigation touchdown reference"));
    let dome=query("QueryUsdPrim",#{path:TARGET+"/Dome",attrs:["visibility","xformOp:translate"]});
    checks.push(t_true(dome.attrs.visibility=="invisible" && dome.attrs["xformOp:translate"]==(),
        "the footprint template carries no vehicle-height offset"));
    for name in ["RoverRampApproach", "RoverRampExit", "RoverTarget1", "RoverTarget2", "BaseSite"] {
        let p=world_pos3(find_path(ROOT+"/"+name));let h=terrain_height(p.x,p.z);
        let marker=query("QueryUsdPrim",#{path:ROOT+"/"+name,attrs:["lunco:billboard:fadeEnd"]});
        checks.push(t_true(h!=() && p.y-h>=0.049
            && marker.attrs["lunco:billboard:fadeEnd"]==griffin_spec::_sysml_attribute("surfaceRouteMarkerFadeEndM"),
            name+" has surface support and the descent display range"));
    }
    if this.landed {
        let entry=world_pos3(find_path(ROOT+"/RoverRampApproach"));
        checks.push(t_true(vlen(entry-vec3_from(this.plan.points[0].position_m))<0.03
            && entry.y-griffin_surface_ops::surface_route_entry_height(entry)>=0.049,
            "landed entry follows the payload deck while other markers follow terrain"));
    }
    let rejected=false;
    try {griffin_surface_ops::surface_route_target(vec3(0.0,0.0,0.0),
        #{origin:vec3(1.0e15,0.0,1.0e15),forward:vec3(1.0,0.0,0.0),lateral:vec3(0.0,0.0,1.0)});}
    catch(error){rejected=true;}
    checks.push(t_true(rejected,"missing terrain cannot fabricate a route support height"));
    let invalid=cmd("UpdateUsdCurveView",#{doc_id:target.doc_id,
        root_entity_id:find_path(TARGET+"/SurfaceMark"),curve_entity_id:curve,
        points:[[0.0,0.0,0.0],[1.0,0.0,0.0]],width_m:-1.0});
    let after=query("InspectUsdCurveView",#{doc_id:target.doc_id,entity_id:curve});
    checks.push(t_true(invalid.ok==false && after.requested_revision==view.requested_revision
        && after.surface_texture==view.surface_texture,
        "invalid footprint width rejects without replacing the displayed surface"));
    report_verdict(checks,"GRIFFIN LANDING ANNOTATIONS","GRIFFIN_LANDING_ANNOTATIONS");
}
