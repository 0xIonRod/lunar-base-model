import "twin://astrobotic-griffin-1/scenarios/griffin_1_surface_ops.rhai" as mission;
const ROOT="/Griffin1SurfaceOps";
fn simulation_dependencies(me,ctx) {mission::simulation_dependencies(me,ctx)}
fn on_start(me,ctx) {this.requested=false;this.done=false;this.detached_tick=();this.release_events=0;this.drive_tick=();this.drive_start=();this.drive_forward=();this.park_start=();subscribe("griffin_flip_released");}
fn on_event(me,event,ctx) {if event.name=="griffin_flip_released" {this.release_events+=1;}}
fn on_tick(me,ctx) {
    if this.done {return;}
    if !this.requested {
        if griffin_surface_ops::landed_status().landed!=true {return;}
        this.requested=true;this.request_tick=sim_tick();
        let result=griffin_surface_ops::on_hud_action("release_rover");
        if result.ok!=true {throw("HUD release callback rejected manual detach: "+result);}
        return;
    }
    let detached=find_path(ROOT+"/FLIPPayloadAdapterJoint")<0;
    if detached && this.detached_tick==() {
        this.detached_tick=sim_tick();
        this.park_start=world_pos(find_path(ROOT+"/FLIP"));
    }
    if !detached && sim_tick()-this.request_tick<180 {return;}
    if detached && sim_tick()-this.detached_tick<600 {return;}
    let rover=find_path(ROOT+"/FLIP");
    if detached && this.drive_tick==() {
        if !is_controlled(rover) {throw("Detach did not transfer possession to FLIP");}
        let ports=read_ports(rover,["brake"]);
        for p in ports.ports {if p.direction=="in" && p.name=="brake" && p.value!=1.0 {throw("Detached FLIP did not retain its parking brake");}}
        this.park_drift=vlen(vsub(world_pos(rover),this.park_start));
        let ramp=find_path(ROOT+"/Lander/CompactEgress");
        let direction=qrot(world_rotation_quat(ramp),vec3(-1.0,0.0,0.0));
        let lateral=qrot(world_rotation_quat(ramp),vec3(0.0,0.0,1.0));
        let shift=vsub(world_pos(rover),this.park_start);
        this.park_rollback=-vdot(shift,vec3_array(direction));
        this.park_lateral=abs(vdot(shift,vec3_array(lateral)));
        let wheel=query("QueryUsdPrim",#{path:ROOT+"/FLIP/Suspension_FL/Wheel_FL",attrs:["height"]});
        this.park_lateral_limit=(griffin_compact_egress::datum("trackWidthM")-wheel.attrs.height)/2.0
          -griffin_compact_egress::datum("curbWidthM");
        this.drive_start=world_pos(rover);this.drive_tick=sim_tick();
        this.drive_forward=vec3_array(qrot(world_rotation_quat(rover),vec3(0.0,0.0,-1.0)));
        // Semantic input uses the same USD Controls bindings as the W key.
        let drive=cmd("SimulateIntent",#{intent:"forward",held:true,target:rover});
        if drive==() || drive.ok!=true {throw("Possessed forward input was rejected");}
        return;
    }
    if detached && sim_tick()-this.drive_tick<60 {return;}
    if this.drive_tick!=() {cmd("SimulateIntent",#{intent:"forward",held:false,target:rover});}
    let failures=[];
    if !detached {failures.push("Manual HUD request did not retire the adapter");}
    if this.release_events!=1 {failures.push("Expected exactly one confirmed release event");}
    let topology=query("PhysicsPerformance",#{});
    if topology.pending_joints!=0 || topology.detach_requests!=0 || topology.joints!=topology.joint_graph_edges {failures.push("Solver topology is not settled after release");}
    let state=query("QueryPhysicsState",#{id:rover});
    if state.body_mode!="dynamic" || state.rigid_body_disabled==true {failures.push("Released FLIP is not a live dynamic body");}
    let ports=read_ports(rover,["brake","autopilot_enable"]);let brake=();let autopilot=();
    for p in ports.ports {if p.direction=="in" && p.name=="brake" {brake=p.value;}if p.direction=="in" && p.name=="autopilot_enable" {autopilot=p.value;}}
    if brake!=0.0 || autopilot!=0.0 {failures.push("Manual release retained a brake or engaged autopilot");}
    let displacement=if this.drive_start==() {0.0}else{vdot(vsub(world_pos(rover),this.drive_start),this.drive_forward)};
    if !is_controlled(rover) || displacement<0.05 {failures.push("Possessed FLIP did not advance 5 cm under forward input");}
    if this.park_rollback==() || this.park_rollback>griffin_compact_egress::datum("maximumParkedRollbackM")
        || this.park_lateral>this.park_lateral_limit {failures.push("Detached FLIP rolled backward or exceeded its actual track lateral clearance during the parked hold");}
    let lander=find_path(ROOT+"/Lander");let ramp=find_path(ROOT+"/Lander/CompactEgress");
    let ramp_direction=qrot(world_rotation_quat(ramp),vec3(-1.0,0.0,0.0));
    let toward_ramp=vdot(vsub(world_pos(rover),this.drive_start),vec3_array(ramp_direction));
    if toward_ramp<0.05 {failures.push("Forward departure did not move toward the actual ramp instance");}
    let route_frame=griffin_surface_ops::landed_surface_route_frame();
    let marker_delta=world_pos3(find_path(ROOT+"/RoverRampApproach"))-world_pos3(lander);
    let marker_forward=vdot(marker_delta,route_frame.forward);
    let marker_lateral=abs(vdot(marker_delta,route_frame.lateral));
    if abs(marker_forward-abs(griffin_compact_egress::datum("stationsXM")[1]))>0.01
      || marker_lateral>0.01 {failures.push("Ramp-entry marker is not on the actual landed ramp side");}
    this.done=true;
    report_structured_verdict(#{ok:failures.len()==0,verdict:if failures.len()==0{"pass"}else{"fail"},
      check_count:9,pass_count:9-failures.len(),failure_count:failures.len(),failures:failures,
      metrics:#{request_tick:this.request_tick,detached_tick:this.detached_tick,release_events:this.release_events,
        joints:topology.joints,graph_edges:topology.joint_graph_edges,brake:brake,autopilot:autopilot,drive_displacement_m:displacement,
        parked_drift_m:this.park_drift,travel_toward_ramp_m:toward_ramp,
        parked_rollback_m:this.park_rollback,parked_lateral_m:this.park_lateral,lateral_clearance_m:this.park_lateral_limit,
        ramp_marker_forward_m:marker_forward,ramp_marker_lateral_m:marker_lateral,
        scope:"HUD detach, ten seconds parked, deliberate drive releases brake and advances toward actual ramp; tethered descent not qualified"}},
      "GRIFFIN COMPACT MANUAL RELEASE","GRIFFIN_COMPACT_MANUAL_RELEASE");
}
