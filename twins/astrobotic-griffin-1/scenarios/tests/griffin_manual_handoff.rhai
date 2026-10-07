// Prefix this observer with LANDER/ROVER constants and the exact on_event
// function extracted from griffin_1_surface_ops.rhai. RunScenario on FLIP
// supplies the stable actor and admitted simulation input boundary.
fn simulation_dependencies(me, ctx) {
    let rover=find_path("/Griffin1SurfaceOps/FLIP");
    #{modelica_entities:[rover],entity_reads:[rover,
        find_path("/Griffin1SurfaceOps/Lander"),find_path("/Griffin1SurfaceOps/Avatar")],
        entity_writes:[rover],query_reads:["ReadPorts"],required_inputs:[]}
}

fn on_start(me, ctx) {
    this.done=false;
    this.ticks=0;
    this.phase="prepare";
    this.route_engaged=false;
    this.route_interrupted=false;
    this.route_control_error=false;
    this.event_trace=[];
    griffin_handoff_prepare();
}

fn on_tick(me, ctx) {
    if this.done {return;}
    this.ticks+=1;
    try {
        if this.ticks>120 {throw("handoff admission timed out in "+this.phase);}
        if this.phase=="prepare" {
            if griffin_handoff_values()!=[1.0,1.0,0.25,-0.125,0.25] {return;}
            this.probe=griffin_handoff_policy();
            this.phase="release";
            this.release_tick=sim_tick();
            return;
        }
        if this.phase=="release" {
            if sim_tick()-this.release_tick<2 {return;}
            griffin_handoff_ports();
            this.done=true;
        }
    } catch (error) {
        this.done=true;
        report_verdict([t_true(false,"handoff observer failed: "+error)],
            "GRIFFIN MANUAL HANDOFF PORTS","GRIFFIN_MANUAL_HANDOFF_PORTS");
        let result=modelica_waypoint_stop(me);
        if result==() || result.ok!=true {print("GRIFFIN_HANDOFF_CLEANUP_REJECTED");}
    }
}

fn griffin_handoff_values() {
    let rover=find_path("/Griffin1SurfaceOps/FLIP");
    let names=["program_active","autopilot_enable","throttle","steer","brake"];
    let snapshot=read_ports(rover,names);
    if snapshot==() || snapshot.api_id==() || snapshot.api_id.to_int()!=rover || snapshot.ports==() {
        throw("handoff authoritative input snapshot unavailable");
    }
    let values=[];
    for name in names {
        let source=if name=="program_active" || name=="autopilot_enable" {
            "Modelica co-simulation component"
        } else {"input surface"};
        let matches=[];
        for port in snapshot.ports {
            if port.name==name && port.direction=="in" && port.metadata!=()
                && port.metadata.source==source {matches.push(port);}
        }
        if matches.len()!=1 {throw("handoff requires one declared input owner: "+name);}
        let value=matches[0].value;
        if value==() || !value.is_finite() {throw("handoff port unavailable: "+name);}
        values.push(value);
    }
    values
}

fn griffin_handoff_prepare() {
    let rover=find_path("/Griffin1SurfaceOps/FLIP");
    if rover<0 || !is_controlled(rover) {throw("handoff fixture needs the controlled FLIP");}
    let pose=world_pos3(rover);
    if !vec3_is_valid(pose) {throw("handoff fixture has no native FLIP pose");}
    let target=vec3_array(pose);
    let result=cmd("SetPorts",#{target:rover,writes:[
        ["program_active",1.0],["autopilot_enable",1.0],
        ["autopilot_target_x",target[0]],["autopilot_target_z",target[2]],
        ["throttle",0.25],["steer",-0.125],["brake",0.25]]});
    if result==() || result.ok!=true {throw("handoff fixture input admission rejected");}
    print("GRIFFIN_HANDOFF_PREPARED "+result);
    result
}

fn griffin_handoff_policy() {
    let rover=find_path("/Griffin1SurfaceOps/FLIP");
    let foreign=find_path("/Griffin1SurfaceOps/Avatar");
    if rover<0 || foreign<0 || !is_controlled(rover) {throw("handoff exact subject/foreign fixture unavailable");}
    let before=griffin_handoff_values();
    if before!=[1.0,1.0,0.25,-0.125,0.25] {throw("handoff preparation has not committed: "+before);}
    let state=#{route_engaged:true,route_interrupted:false,route_control_error:false,event_trace:[]};
    let checks=[];
    let program=find_path("/Griffin1SurfaceOps/FlipRoute");
    if program<0 {throw("handoff operator program unavailable");}
    for event_name in ["route_started", "route_stopped"] {
        let operator=#{route_engaged:true,route_interrupted:false,route_control_error:false,event_trace:[]};
        operator.on_event(0,#{name:event_name,source:foreign,sim_tick:sim_tick(),value:true},#{});
        checks.push(t_true(operator.route_engaged && !operator.route_interrupted,
            "foreign program must not interrupt the mission on "+event_name));
        operator.on_event(0,#{name:event_name,source:program,sim_tick:sim_tick(),value:true},#{});
        checks.push(t_true(operator.route_interrupted && !operator.route_engaged,
            "the exact operator program cancels the mission on "+event_name));
        checks.push(t_true(griffin_handoff_values()==before,
            "mission retirement preserves the operator program inputs on "+event_name));
    }
    for item in [#{source:foreign,target:rover,edge:"pressed",label:"foreign source"},
        #{source:rover,target:foreign,edge:"pressed",label:"wrong target"},
        #{source:rover,target:rover,edge:"released",label:"release edge"}] {
        let evt=#{name:"intent.edge",source:item.source,sim_tick:sim_tick(),
            value:#{target_gid:item.target,intent:"forward",edge:item.edge}};
        state.on_event(0,evt,#{});
        checks.push(t_true(state.route_engaged && !state.route_interrupted
            && griffin_handoff_values()==before,item.label+" must not interrupt mission guidance"));
    }
    let pressed=#{name:"intent.edge",source:rover,sim_tick:sim_tick(),
        value:#{target_gid:rover,intent:"forward",edge:"pressed"}};
    state.on_event(0,pressed,#{});
    checks.push(t_true(state.route_interrupted && !state.route_engaged && !state.route_control_error,
        "pressed exact controlled FLIP cancels mission authority"));
    report_verdict(checks,"GRIFFIN MANUAL HANDOFF POLICY","GRIFFIN_MANUAL_HANDOFF_POLICY");
    print("GRIFFIN_HANDOFF_RELEASE_QUEUED "+#{state:state,before:before});
    state
}

fn griffin_handoff_ports() {
    let values=griffin_handoff_values();
    report_verdict([
        t_true(values[0]==0.0 && values[1]==0.0,"handoff clears both mission guidance inputs"),
        t_true(values[2]==0.25,"handoff preserves the manual throttle"),
        t_true(values[3]==-0.125,"handoff preserves the manual steer"),
        t_true(values[4]==0.25,"handoff preserves the manual brake")
    ],"GRIFFIN MANUAL HANDOFF PORTS","GRIFFIN_MANUAL_HANDOFF_PORTS");
    print("GRIFFIN_HANDOFF_NATIVE_PORTS "+values);
    let rover=find_path("/Griffin1SurfaceOps/FLIP");
    let cleanup=cmd("SetPorts",#{target:rover,writes:[
        ["program_active",0.0],["autopilot_enable",0.0],
        ["throttle",0.0],["steer",0.0],["brake",1.0]]});
    if cleanup==() || cleanup.ok!=true {throw("handoff fixture cleanup rejected");}
    values
}
