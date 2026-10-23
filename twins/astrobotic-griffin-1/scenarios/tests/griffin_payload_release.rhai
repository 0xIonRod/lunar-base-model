// Observe the production descent, ramp gates, solver release and egress.
// No detach, drive, pose or port commands are issued by this observer.
import "twin://astrobotic-griffin-1/scenarios/griffin_1_surface_ops.rhai" as mission;
import "twin://astrobotic-griffin-1/tools/griffin_surface_ops.rhai" as surface;
import "twin://astrobotic-griffin-1/tools/griffin_spec.rhai" as spec;
import "lunco://scripting/tools/sysml_requirements" as requirements;
const ROOT="/Griffin1SurfaceOps";
fn simulation_dependencies(me,ctx){let deps=mission::simulation_dependencies(me,ctx);deps.entity_writes=[];deps}
fn on_start(me,ctx){
    this.done=false;this.failed=false;this.ready=false;this.release_count=0;this.route_count=0;this.exited=false;
    this.start_position=();this.release_tick=();this.exit_tick=();this.landed=false;
    for name in ["griffin_ramp_deployment_settled","griffin_flip_released","griffin_surface_route_started",
        "griffin_ramp_exit_reached","griffin_phase_timeout","griffin_surface_route_stalled","griffin_surface_route_control_failed"]{subscribe(name);}
}
fn on_event(me,event,ctx){
    if this.done{return;}
    if event.name=="griffin_ramp_deployment_settled"{this.ready=true;this.landed=surface::landed_status().landed;}
    if event.name=="griffin_flip_released"{
        this.release_count+=1;this.release_tick=event.sim_tick;
        this.start_position=vec3_array(world_pos3(find_path(ROOT+"/FLIP")));
        this.release_after_ready=this.ready;
        this.adapter_absent_at_release=find_path(ROOT+"/FLIPPayloadAdapterJoint")<0;
    }
    if event.name=="griffin_surface_route_started"{this.route_count+=1;this.route_after_release=this.release_count==1;}
    if event.name=="griffin_ramp_exit_reached"{this.exited=true;this.exit_tick=event.sim_tick;}
    if event.name=="griffin_phase_timeout" || event.name=="griffin_surface_route_stalled" || event.name=="griffin_surface_route_control_failed"{this.failed=true;this.failure_event=event.name;}
}
fn on_tick(me,ctx){
    if this.done || (!this.exited && !this.failed){return;}
    let failures=[];let count=10;
    if this.failed{failures.push("Production mission failed before physical egress: "+this.failure_event);}
    if !this.landed{failures.push("Release lacked qualified landing");}
    if this.release_count!=1{failures.push("Payload release did not complete exactly once");}
    if this.route_count!=1{failures.push("Egress authority did not start exactly once");}
    if this.release_after_ready!=true || this.route_after_release!=true{failures.push("Readiness/release/control sequence was violated");}
    if this.adapter_absent_at_release!=true || find_path(ROOT+"/FLIPPayloadAdapterJoint")>=0{failures.push("Live adapter entity remains after claimed release");}
    let rover=world_pos3(find_path(ROOT+"/FLIP"));let lander=world_pos3(find_path(ROOT+"/Lander"));
    let distance=if this.start_position==(){0.0}else{let d=rover-vec3_from(this.start_position);sqrt(d.x*d.x+d.z*d.z)};
    // Crossing the actual source-owned deck width distinguishes retirement
    // from a detached body that remains stuck on or coupled to the deck.
    if distance<spec::visual_lander_deck_width_m(){failures.push("Released rover did not move independently beyond the deck envelope");}
    if !this.exited || this.exit_tick<=this.release_tick{failures.push("No physical ramp-exit milestone followed release");}
    let topology=query("PhysicsPerformance",#{});
    if topology.detach_requests!=0 || topology.pending_joints!=0 || topology.joints!=topology.joint_graph_edges{failures.push("Physics topology retained pending or inconsistent edges");}
    let support=surface::rover_route_settle_report(find_path(ROOT+"/FLIP"));
    if support.support_contact_count==() || support.support_contact_count.to_int()<=0{failures.push("Ramp exit has no measured wheel support");}
    report_structured_verdict(#{ok:failures.len()==0,verdict:if failures.len()==0{"pass"}else{"fail"},check_count:count,
        failure_count:failures.len(),pass_count:count-failures.len(),failures:failures,source_revision:requirements::model().source_revision,
        metrics:#{release_tick:this.release_tick,exit_tick:this.exit_tick,release_count:this.release_count,route_count:this.route_count,
            start_position_m:this.start_position,rover_position_m:vec3_array(rover),lander_position_m:vec3_array(lander),travel_m:distance,
            joint_count:topology.joints,graph_edges:topology.joint_graph_edges,pending_joints:topology.pending_joints,
            detach_requests:topology.detach_requests,support_contacts:support.support_contact_count}},
        "GRIFFIN PRODUCTION PAYLOAD RELEASE","GRIFFIN_PAYLOAD_RELEASE");this.done=true;
}
