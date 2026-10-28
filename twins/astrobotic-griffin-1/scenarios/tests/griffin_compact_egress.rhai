const ROOT="/Griffin1SurfaceOps";
fn simulation_dependencies(me,ctx) {
    #{modelica_entities:[find_path(ROOT+"/Lander")],entity_writes:[],entity_reads:[find_path(ROOT+"/Lander"),find_path(ROOT+"/FLIP"),find_path(ROOT+"/FLIPPayloadAdapterJoint"),find_path(ROOT+"/Lander/CompactEgress")],
      query_reads:["QueryUsdPrim","PhysicsPerformance","ReadPorts","ReadPortsBatch"],required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_name()}]}
}
fn on_start(me,ctx) {this.held=false;this.done=false;subscribe("griffin_compact_egress_held");}
fn on_event(me,event,ctx) {if event.name=="griffin_compact_egress_held" {this.held=true;}}
fn on_tick(me,ctx) {
    if this.done || griffin_surface_ops::landed_status().landed!=true {return;}this.done=true;let failures=[];
    if find_path(ROOT+"/Lander/CompactEgress")<0 {failures.push("Compact egress assembly missing");}
    if find_path(ROOT+"/FLIPPayloadAdapterJoint")<0 {failures.push("Payload released without a tether restraint");}
    for name in ["EgressRampPort","EgressRampStarboard","RampHingePort","RampHingeStarboard","RampSectionHingePort01","RampSectionHingeStarboard01"] {
        if find_path(ROOT+"/Lander/"+name)>=0 {failures.push("Superseded folding mechanism remains active: "+name);}
    }
    let proxies=0;
    for track in ["TrackPort","TrackStarboard"] {for i in 0..6 {
        let q=query("QueryUsdPrim",#{path:ROOT+"/Lander/CompactEgress/"+track+"/Contact"+i,attrs:["physics:collisionEnabled"]});
        if q.attrs["physics:collisionEnabled"]==true {proxies+=1;}
    }}
    if proxies!=12 {failures.push("Expected twelve attached track contact proxies");}
    let topology=query("PhysicsPerformance",#{});
    if topology.pending_joints!=0 || topology.detach_requests!=0 || topology.joints!=topology.joint_graph_edges {failures.push("Joint topology is not settled");}
    report_structured_verdict(#{ok:failures.len()==0,verdict:if failures.len()==0{"pass"}else{"fail"},
        check_count:5,pass_count:5-failures.len(),failure_count:failures.len(),failures:failures,
        metrics:#{contact_proxies:proxies,joints:topology.joints,graph_edges:topology.joint_graph_edges,scope:"Measured landing and attached compact egress; tether payout unqualified"}},
        "GRIFFIN COMPACT EGRESS HOLD","GRIFFIN_COMPACT_EGRESS");
}
