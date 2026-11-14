const ROOT="/Griffin1SurfaceOps";
const PROBE_FORCE_N=120.0;
const PROBE_TORQUE_NM=30.0;

fn simulation_dependencies(me,ctx) {
    let rover=find_path(ROOT+"/FLIP");
    #{modelica_entities:[],entity_reads:[rover],entity_writes:[rover],
      query_reads:["QueryPhysicsState"],required_inputs:[]}
}

fn write_probe(rover,force,torque) {
    let result=cmd("SetPorts",#{target:rover,writes:[["force_x",force],["torque_y",torque]]});
    if result==() || result.ok!=true {throw("Native body wrench inputs were rejected: "+result);}
}

fn verdict(state) {
    let failures=[];
    if state.delta_v_x<state.one_step_delta_v*0.50 {failures.push("Native FLIP force sink produced no expected x-velocity response");}
    if state.delta_omega_y<state.one_step_delta_omega*0.50 {failures.push("Native FLIP torque sink produced no expected y-angular-rate response");}
    if abs(state.cancel_v_x)>max(state.one_step_delta_v,0.0001) {failures.push("Reverse force did not cancel the probe impulse within one fixed-step tolerance");}
    if abs(state.cancel_omega_y)>max(state.one_step_delta_omega,0.0001) {failures.push("Reverse torque did not cancel the probe impulse within one fixed-step tolerance");}
    let ok=failures.len()==0;
    report_structured_verdict(#{ok:ok,verdict:if ok {"pass"} else {"fail"},
        check_count:4,pass_count:4-failures.len(),failure_count:failures.len(),failures:failures,
        metrics:#{expected_three_tick_delta_v_x_mps:state.expected_delta_v,measured_delta_v_x_mps:state.delta_v_x,
          expected_three_tick_delta_omega_y_radps:state.expected_delta_omega,measured_delta_omega_y_radps:state.delta_omega_y,
          cancel_residual_v_x_mps:state.cancel_v_x,cancel_residual_omega_y_radps:state.cancel_omega_y,
          probe_force_n:PROBE_FORCE_N,probe_torque_nm:PROBE_TORQUE_NM,
          scope:"Three-tick direct SetPorts excitation of native Avian body sinks in open air; not tether or flight qualification"}},
        "GRIFFIN NATIVE BODY WRENCH RESPONSE","GRIFFIN_NATIVE_WRENCH_RESPONSE");
}

fn on_start(me,ctx) {
    this.started=sim_tick();this.stage="settle";this.done=false;
    this.rover=find_path(ROOT+"/FLIP");
    if this.rover<0 {throw("Native wrench-response fixture is missing FLIP");}
}

fn on_tick(me,ctx) {
    if this.done {return;}
    if this.stage=="settle" {
        if sim_tick()-this.started<3 {return;}
        let physics=query("QueryPhysicsState",#{id:this.rover});
        if physics.mass_kg==() || physics.inertia_principal_kgm2==() || physics.mass_kg<=0.0
            || physics.inertia_principal_kgm2[1]<=0.0 {throw("FLIP mass or y-axis inertia is unavailable for a bounded response check");}
        this.baseline_v=physics.linear_velocity_mps[0];
        this.baseline_w=physics.angular_velocity_radps[1];
        this.one_step_delta_v=PROBE_FORCE_N*dt()/physics.mass_kg;
        this.one_step_delta_omega=PROBE_TORQUE_NM*dt()/physics.inertia_principal_kgm2[1];
        this.expected_delta_v=3.0*this.one_step_delta_v;
        this.expected_delta_omega=3.0*this.one_step_delta_omega;
        write_probe(this.rover,PROBE_FORCE_N,PROBE_TORQUE_NM);
        this.pulse_tick=sim_tick();this.stage="observe_pulse";return;
    }
    if this.stage=="observe_pulse" {
        if sim_tick()-this.pulse_tick<3 {return;}
        let physics=query("QueryPhysicsState",#{id:this.rover});
        this.delta_v_x=physics.linear_velocity_mps[0]-this.baseline_v;
        this.delta_omega_y=physics.angular_velocity_radps[1]-this.baseline_w;
        write_probe(this.rover,-PROBE_FORCE_N,-PROBE_TORQUE_NM);
        this.cancel_tick=sim_tick();this.stage="observe_cancel";return;
    }
    if this.stage=="observe_cancel" {
        if sim_tick()-this.cancel_tick<3 {return;}
        let physics=query("QueryPhysicsState",#{id:this.rover});
        this.cancel_v_x=physics.linear_velocity_mps[0]-this.baseline_v;
        this.cancel_omega_y=physics.angular_velocity_radps[1]-this.baseline_w;
        write_probe(this.rover,0.0,0.0);
        this.done=true;verdict(this);
    }
}
