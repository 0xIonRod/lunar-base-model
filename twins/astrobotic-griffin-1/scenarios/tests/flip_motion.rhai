// Live, fixed-tick motion acceptance. Keyboard delivery is qualified separately
// by flip_manual_controls; this observer measures the resulting vehicle motion.
import "twin://astrobotic-griffin-1/scenarios/tests/flip_manual_controls" as checks;
const FLIP="/Griffin1SurfaceOps/FLIP";
fn simulation_dependencies(me,ctx) {
    let rover=find_path(FLIP);let reads=[rover];
    for station in ["FL","FR","RL","RR"] {
        let path=FLIP+"/Suspension_"+station+"/Wheel_"+station;
        reads.push(find_path(path));reads.push(find_path(path+"/CADVisuals"));
        reads.push(find_path(FLIP+"/Wheel_"+station+"_Hinge"));
    }
    #{modelica_entities:[rover,find_path(FLIP+"/Thermal"),find_path(FLIP+"/SolarMechanism/Controller")],
      entity_reads:reads,entity_writes:[rover],
      query_reads:["QueryPhysicsState","ReadPorts"],required_inputs:[]}
}
fn intent(name,held) {
    let result=cmd("SimulateIntent",#{target:find_path(FLIP),intent:name,held:held});
    if result.ok!=true {throw("FLIP motion input rejected: "+name);}
}
fn on_start(me,ctx) {
    this.phase="settle";this.time=0.0;this.done=false;this.evidence=#{};
    let acquired=cmd("AcquireControl",#{target:find_path(FLIP),
        source:find_path("/Griffin1SurfaceOps/Avatar"),bind_camera:false});
    if acquired.ok!=true {throw("FLIP motion control acquisition failed");}
    intent("forward",false);intent("backward",false);intent("brake",true);
}
fn on_tick(me,ctx) {
    if this.done {return;}this.time+=dt();
    if this.phase=="settle" {
        if this.time<2.0 {return;}
        this.before=checks::flip_motion_snapshot();
        intent("brake",false);intent("forward",true);
        this.phase="forward";this.time=0.0;return;
    }
    if this.phase=="forward" {
        if this.time<3.0 {return;}
        let after=checks::flip_motion_snapshot();
        intent("forward",false);intent("brake",true);
        this.evidence.forward=checks::flip_motion_assert(this.before,after,"forward",1.0);
        if this.evidence.forward.ok!=true {this.done=true;return;}
        this.before=after;
        this.phase="brake";this.time=0.0;return;
    }
    if this.phase=="brake" {
        if this.time<3.0 {return;}
        let after=checks::flip_motion_snapshot();
        this.evidence.brake=checks::flip_brake_assert(this.before,after);
        if this.evidence.brake.ok!=true {this.done=true;return;}
        this.before=after;intent("brake",false);intent("backward",true);
        this.phase="reverse";this.time=0.0;return;
    }
    if this.phase=="reverse" {
        if this.time<3.0 {return;}
        let after=checks::flip_motion_snapshot();
        intent("backward",false);intent("brake",true);
        this.evidence.reverse=checks::flip_motion_assert(this.before,after,"reverse",-1.0);
        if this.evidence.reverse.ok!=true {this.done=true;return;}
        this.before=after;this.phase="reverse_brake";this.time=0.0;return;
    }
    if this.phase=="reverse_brake" {
        if this.time<3.0 {return;}
        this.evidence.reverse_brake=checks::flip_brake_assert(this.before,checks::flip_motion_snapshot());
        this.done=true;
        if this.evidence.reverse_brake.ok!=true {return;}
        emit("FLIP_MOTION_EVIDENCE_RESULT",#{result:this.evidence});
        report_verdict([t_true(true,"forward, reverse, four-wheel roll and both physical stops passed")],
            "FLIP MOTION COMPLETE","FLIP_MOTION_COMPLETE");
    }
}
