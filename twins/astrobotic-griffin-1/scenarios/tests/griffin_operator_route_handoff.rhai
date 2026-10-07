// Attach to CameraTrack immediately after a fresh default-scene load. Exercise
// the shared HUD action while the mission drives after adapter retirement.

const FLIP = "/Griffin1SurfaceOps/FLIP";
const ROUTE = "/Griffin1SurfaceOps/FlipRoute";

fn simulation_dependencies(me, ctx) {
    let flip = find_path(FLIP);
    #{modelica_entities:[flip],entity_reads:[flip,find_path(ROUTE)],
      entity_writes:[flip],query_reads:["ReadPorts"],required_inputs:[]}
}

fn on_start(me, ctx) {
    this.point=ctx.point_path;
    if this.point==() {throw("pass an admitted runtime waypoint as point_path");}
    this.done=false;
    this.phase="mission";
    this.ticks=0;
    this.stable=0;
    this.started=false;
    this.stopped=false;
    subscribe_from("route_started",find_path(ROUTE));
    subscribe_from("route_stopped",find_path(ROUTE));
}

fn on_event(me, evt, ctx) {
    if evt.name=="route_started" {this.started=true;}
    if evt.name=="route_stopped" {this.stopped=true;}
}

fn declared_throttle(flip) {
    let read=query("ReadPorts",#{api_id:flip,port_names:["throttle"]});
    let values=[];
    for row in read.ports {
        if row.name=="throttle" && row.direction=="in"
            && row.metadata.source=="input surface" {values.push(row.value);}
    }
    if values.len()!=1 {throw("FLIP declared throttle owner unavailable");}
    values[0]
}

fn on_tick(me, ctx) {
    if this.done {return;}
    this.ticks+=1;
    let flip=find_path(FLIP);
    try {
        if this.ticks>12000 {throw("operator handoff timeout in "+this.phase);}
        let active=port(flip,"program_active");
        let guidance=port(flip,"autopilot_enable");
        if active==() || guidance==() {throw("FLIP guidance inputs unavailable");}
        if this.phase=="mission" {
            if active<0.5 || find_path("/Griffin1SurfaceOps/FLIPPayloadAdapterJoint")>=0 {return;}
            if !is_controlled(flip) {throw("deployed FLIP is not possessed");}
            if find_path(this.point+"/Trigger")<0 {return;}
            print("GRIFFIN_OPERATOR_HANDOFF mission active after detach");
            emit("runtime.ui.action",#{action:"program.toggle",parameters:#{}});
            this.phase="start";
            return;
        }
        if this.phase=="start" {
            if !this.started {return;}
            emit("runtime.ui.action",#{action:"program.toggle",parameters:#{}});
            this.stop_tick=sim_tick();
            this.phase="stop";
            return;
        }
        if this.phase=="stop" {
            if sim_tick()-this.stop_tick>120 {throw("HUD stop did not release guidance after detach");}
            if !this.stopped || active!=0.0 || guidance!=0.0 {return;}
            this.phase="stable";
            return;
        }
        if active!=0.0 || guidance!=0.0 {throw("mission reasserted guidance after HUD stop");}
        if this.phase=="stable" {
            this.stable+=1;
            if this.stable<120 {return;}
            input_key_press("KeyW");
            this.key_tick=sim_tick();
            this.phase="pressed";
            return;
        }
        if sim_tick()-this.key_tick<8 {return;}
        if this.phase=="pressed" {
            this.press_ok=declared_throttle(flip)==1.0;
            input_key_release("KeyW");
            this.key_tick=sim_tick();
            this.phase="released";
            return;
        }
        report_verdict([
            t_true(this.started,"operator route did not start after detach"),
            t_true(this.stopped,"operator route did not stop after detach"),
            t_true(this.stable>=120,"HUD stop was not stable for 120 ticks"),
            t_true(this.press_ok,"native W did not reach deployed FLIP"),
            t_true(declared_throttle(flip)==0.0,"native W release did not clear FLIP"),
            t_true(active==0.0 && guidance==0.0,"mission guidance remains active")
        ],"GRIFFIN OPERATOR HANDOFF","GRIFFIN_OPERATOR_HANDOFF");
        this.done=true;
    } catch (error) {
        input_key_release("KeyW");
        report_verdict([t_true(false,error)],"GRIFFIN OPERATOR HANDOFF","GRIFFIN_OPERATOR_HANDOFF");
        this.done=true;
    }
}

fn on_stop(me, ctx) {input_key_release("KeyW");}
