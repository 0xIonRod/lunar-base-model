// Engine-out stimulus/verdict. Each main engine is its own PressureFedEngine
// member fed by the shared tanks; `engineNN_enabled` is its health input.
// With full command held, failing one engine must extinguish exactly that
// engine and its plume while the other six keep their thrust, so the cluster
// delivers six sevenths of its nominal thrust.
const FAILED_ENGINE = "Engine03";
const SETTLE_S = 2.0;
// Shared-tank pressure is unchanged by one closed engine, so the surviving
// engines keep their flow; 3% covers valve and chamber settling.
const CLUSTER_SHARE_TOLERANCE = 0.03;
// A commanded-closed valve decays exponentially (0.08 s response), so after
// the settle time the failed engine's plume is extinguished, not exactly zero:
// below this fraction of its nominal light it renders nothing.
const EXTINGUISHED_PLUME_FRACTION = 1.0e-9;

fn simulation_dependencies(me,ctx) {
    #{modelica_entities:[find_path("/World/Griffin1"),find_path("/World/Griffin1/MainPropulsion")],
      entity_reads:[],entity_writes:[],query_reads:[],required_inputs:[]}
}

fn _threshold() {
    griffin_spec::_typed_model_number(
        "GriffinPropulsionRequirements::GriffinEngineControlStudy::extinguishedThrustThresholdN")
}

fn _engine_thrusts(main) {
    let thrusts=#{};
    for name in griffin_spec::main_engine_names() {
        thrusts[name]=get(main,griffin_spec::main_engine_port(name,"thrust_n"));
    }
    thrusts
}

fn on_start(me,ctx) {
    this.griffin=find_path("/World/Griffin1");
    this.main=find_path("/World/Griffin1/MainPropulsion");
    this.elapsed=0.0;this.phase="nominal";this.done=false;
    let control=cmd("AcquireControl",#{target:this.griffin,bind_camera:false});
    let command=cmd("SetPorts",#{target:this.griffin,writes:[["external_throttle",1.0]]});
    this.command_ok=control.ok && command.ok;
}

fn on_tick(me,ctx) {
    if this.done {return;}
    this.elapsed+=dt();
    if this.elapsed<SETTLE_S {return;}
    let threshold=_threshold();
    if this.phase=="nominal" {
        this.nominal=_engine_thrusts(this.main);
        this.nominal_total=griffin_spec::main_engine_total(this.main,"thrust_n");
        this.nominal_plume=get(this.main,"test_failed_plume_intensity");
        let failed=cmd("SetPorts",#{target:this.main,
            writes:[[griffin_spec::main_engine_port(FAILED_ENGINE,"enabled"),0.0]]});
        this.failure_ok=failed.ok;
        this.phase="failed";this.elapsed=0.0;
        return;
    }
    let after=_engine_thrusts(this.main);
    let total=griffin_spec::main_engine_total(this.main,"thrust_n");
    let count=griffin_spec::main_engine_names().len();
    let failures=[];
    failures.push(t_true(this.command_ok,"full main-engine command was rejected"));
    failures.push(t_true(this.failure_ok,"engine failure input was rejected"));
    for name in griffin_spec::main_engine_names() {
        failures.push(t_true(this.nominal[name]!=() && this.nominal[name]>threshold,
            name+" did not burn before the failure: "+this.nominal[name]));
    }
    failures.push(t_true(this.nominal_plume!=() && this.nominal_plume>0.0,
        FAILED_ENGINE+" showed no plume before the failure"));
    failures.push(t_true(after[FAILED_ENGINE]!=() && after[FAILED_ENGINE]<threshold,
        FAILED_ENGINE+" kept thrust after failing: "+after[FAILED_ENGINE]));
    failures.push(t_true(get(this.main,griffin_spec::main_engine_port(FAILED_ENGINE,"activity"))==0.0,
        FAILED_ENGINE+" kept combustion activity after failing"));
    let failed_plume=get(this.main,"test_failed_plume_intensity");
    failures.push(t_true(failed_plume!=() && this.nominal_plume!=()
        && failed_plume<=this.nominal_plume*EXTINGUISHED_PLUME_FRACTION,
        FAILED_ENGINE+" kept a plume after failing"));
    for name in griffin_spec::main_engine_names() {
        if name==FAILED_ENGINE {continue;}
        failures.push(t_true(after[name]!=() && after[name]>threshold,
            name+" stopped when "+FAILED_ENGINE+" failed: "+after[name]));
    }
    let share=if this.nominal_total!=() && this.nominal_total>0.0 && total!=() {total/this.nominal_total} else {0.0};
    let expected=(count-1).to_float()/count.to_float();
    failures.push(t_true((share-expected).abs()<=CLUSTER_SHARE_TOLERANCE,
        "cluster thrust share after one engine-out was "+share+", expected "+expected));
    print("[griffin-engine-out] nominal="+this.nominal_total+" after="+total+" share="+share
        +" failed_thrust="+after[FAILED_ENGINE]+" plume="+this.nominal_plume
        +" -> "+failed_plume);
    this.done=true;report_verdict(failures,"GRIFFIN ENGINE OUT","GRIFFIN_ENGINE_OUT");
}
