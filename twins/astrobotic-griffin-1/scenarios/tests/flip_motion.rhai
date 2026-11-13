// Native motion and physical stopping against the Twin-owned study envelope.
import "twin://astrobotic-griffin-1/scenarios/tests/flip_manual_controls" as checks;
const FLIP="/Griffin1SurfaceOps/FLIP";
const PI=3.141592653589793;
fn simulation_dependencies(me,ctx) {
    let rover=find_path(FLIP);let reads=[rover,find_path(FLIP+"/PanelHinge"),
        find_path(FLIP+"/SolarMechanism/Controller")];
    for station in ["FL","FR","RL","RR"] {
        let path=FLIP+"/Suspension_"+station+"/Wheel_"+station;
        reads.push(find_path(path));reads.push(find_path(path+"/CADVisuals"));
        reads.push(find_path(FLIP+"/Wheel_"+station+"_Hinge"));
    }
    #{modelica_entities:[rover,find_path(FLIP+"/Thermal"),find_path(FLIP+"/SolarMechanism/Controller")],
      entity_reads:reads,entity_writes:[rover],
      query_reads:["QueryPhysicsState","ReadPorts","ReadActiveTwinContract","AnalyzeSysml","QueryUsdPrim"],
      required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_source_identity()}]}
}
fn intent(name,held) {
    let result=cmd("SimulateIntent",#{target:find_path(FLIP),intent:name,held:held});
    if result.ok!=true {throw("FLIP motion input rejected: "+name+" "+result);}
}
fn finish(state) {
    state.done=true;
    if state.config.maximumPanelAngleErrorDeg!=() {
        state.checks.push(t_true(state.panel_samples>0,"panel has no driving/stopping samples"));
        state.checks.push(t_true(state.panel_max_error_deg<=state.config.maximumPanelAngleErrorDeg,
            "panel holding error="+state.panel_max_error_deg+" deg limit="+state.config.maximumPanelAngleErrorDeg));
        state.checks.push(t_true(state.panel_max_rate_deg_s<=state.config.maximumPanelRateDegPerS,
            "panel relative rate="+state.panel_max_rate_deg_s+" deg/s limit="+state.config.maximumPanelRateDegPerS));
        state.evidence.panel=#{samples:state.panel_samples,maximum_error_deg:state.panel_max_error_deg,
            maximum_rate_deg_s:state.panel_max_rate_deg_s};
    }
    for name in ["forward","backward"] {
        let result=cmd("SimulateIntent",#{target:find_path(FLIP),intent:name,held:false});
        state.checks.push(t_true(result.ok==true,"release "+name+" rejected: "+result));
    }
    let brake=cmd("SimulateIntent",#{target:find_path(FLIP),intent:"brake",held:true});
    state.checks.push(t_true(brake.ok==true,"terminal brake rejected: "+brake));
    emit("FLIP_MOTION_EVIDENCE_RESULT",#{requirement:"FlipMotionRequirements::fmr001",
        phase:state.phase,config:state.config,result:state.evidence});
    report_verdict(state.checks,"FLIP MOTION COMPLETE","FLIP_MOTION_COMPLETE");
    state
}
fn fail(state,message) {state.checks.push(message);finish(state)}
fn collect(state,result) {
    for check in result.checks {state.checks.push(check);}
    state
}
// Read native output ports, never the commanded hinge input or render pose.
fn panel_output(path,name) {
    let result=query("ReadPorts",#{api_id:find_path(path),port_names:[name]});
    let values=[];
    for row in result.ports {
        if row.direction=="out" && row.name==name {values.push(row.value);}
    }
    if values.len()!=1 || values[0]==() || !values[0].is_finite() {
        throw("panel needs one finite native output "+path+"."+name);
    }
    values[0]
}
fn observe_panel(state) {
    let actual=panel_output(FLIP+"/PanelHinge","angle");
    let requested=panel_output(FLIP+"/SolarMechanism/Controller","angle");
    let rate=panel_output(FLIP+"/PanelHinge","angular_velocity");
    let degrees_per_rad=180.0/PI;
    state.panel_samples+=1;
    state.panel_max_error_deg=max(state.panel_max_error_deg,abs(actual-requested)*degrees_per_rad);
    state.panel_max_rate_deg_s=max(state.panel_max_rate_deg_s,abs(rate)*degrees_per_rad);
    if state.panel_max_error_deg>state.config.maximumPanelAngleErrorDeg
        || state.panel_max_rate_deg_s>state.config.maximumPanelRateDegPerS {
        return fail(state,"panel oscillation during "+state.phase);
    }
    state
}
fn on_start(me,ctx) {
    this.phase="settle";this.time=0.0;this.done=false;this.evidence=#{};
    this.checks=[];this.config=#{};this.direction=1.0;
    this.panel_samples=0;this.panel_max_error_deg=0.0;this.panel_max_rate_deg_s=0.0;
    try {
        this.config=checks::flip_motion_config();
        this.apply_brake=query("QueryUsdPrim",#{path:"/Griffin1SurfaceOps/Scenario/Test",
            attrs:["inputs:apply_brake"]}).attrs["inputs:apply_brake"];
        if type_of(this.apply_brake)!="bool" {throw("motion fixture requires explicit inputs:apply_brake");}
        let acquired=cmd("AcquireControl",#{target:find_path(FLIP),
            source:find_path("/Griffin1SurfaceOps/Avatar"),bind_camera:false});
        if acquired.ok!=true {throw("control acquisition rejected: "+acquired);}
        intent("forward",false);intent("backward",false);intent("brake",true);
    } catch(error) {this=fail(this,"FLIP motion setup: "+error);}
}
fn advance(state) {
    let current=checks::flip_motion_snapshot();let c=state.config;
    if state.phase!="settle" {
        state=observe_panel(state);
        if state.done {return state;}
    }
    let speed=vlen(current.velocity);
    if state.phase=="settle" {
        if state.time>=c.settleTimeoutS {return fail(state,"FLIP did not settle: speed="+speed+" m/s");}
        if state.time<c.settleDurationS || speed>c.stoppedSpeedMps {return state;}
        state.before=current;intent("brake",false);intent("forward",true);
        state.phase="drive";state.time=0.0;return state;
    }
    if state.phase=="drive" {
        let longitudinal=vdot(current.velocity,state.before.forward)*state.direction;
        if state.time>=c.driveTimeoutS {return fail(state,"FLIP drive timeout: signed speed="+longitudinal+" m/s");}
        if longitudinal<c.brakeEntrySpeedMps {return state;}
        let label=if state.direction>0.0 {"forward"} else {"reverse"};
        let motion=checks::flip_motion_assert(state.before,current,label,state.direction,c);
        state.evidence[label]=motion;
        intent(if state.direction>0.0 {"forward"} else {"backward"},false);intent("brake",state.apply_brake);
        state=collect(state,motion);
        if !motion.ok {return finish(state);}
        state.before=current;state.previous=current;state.distance=0.0;
        state.deadline=(speed-c.stoppedSpeedMps)/c.minimumAverageDecelerationMps2+c.brakeResponseAllowanceS;
        state.phase="brake";state.time=0.0;return state;
    }
    if state.phase=="brake" {
        state.distance+=vlen(vsub(current.position,state.previous.position));state.previous=current;
        if speed>c.stoppedSpeedMps && state.time<state.deadline && state.distance<c.maximumStoppingDistanceM {return state;}
        let stop=checks::flip_brake_assert(state.before,current,state.time,state.distance,c);
        state.evidence[if state.direction>0.0 {"forward_stop"} else {"reverse_stop"}]=stop;
        state=collect(state,stop);
        if !stop.ok {return finish(state);}
        state.held=current;state.phase="hold";state.time=0.0;
        state.maximum_hold_speed=speed;state.maximum_hold_drift=0.0;return state;
    }
    if state.phase=="hold" {
        state.maximum_hold_speed=max(state.maximum_hold_speed,speed);
        state.maximum_hold_drift=max(state.maximum_hold_drift,vlen(vsub(current.position,state.held.position)));
        if state.time<c.stoppedDwellS {return state;}
        state.checks.push(t_true(state.maximum_hold_speed<=c.stoppedSpeedMps,
            "braked dwell speed="+state.maximum_hold_speed+" m/s limit="+c.stoppedSpeedMps));
        state.checks.push(t_true(state.maximum_hold_drift<=c.maximumStoppedDriftM,
            "braked dwell drift="+state.maximum_hold_drift+" m limit="+c.maximumStoppedDriftM));
        state.evidence[if state.direction>0.0 {"forward_hold"} else {"reverse_hold"}]=
            #{maximum_speed_mps:state.maximum_hold_speed,maximum_drift_m:state.maximum_hold_drift};
        if state.maximum_hold_speed>c.stoppedSpeedMps || state.maximum_hold_drift>c.maximumStoppedDriftM {return finish(state);}
        if state.direction<0.0 {return finish(state);}
        state.direction=-1.0;state.before=current;intent("brake",false);intent("backward",true);
        state.phase="drive";state.time=0.0;
    }
    state
}
fn on_tick(me,ctx) {
    if this.done {return;}this.time+=dt();
    try {this=advance(this);} catch(error) {this=fail(this,"FLIP motion "+this.phase+": "+error);}
}
