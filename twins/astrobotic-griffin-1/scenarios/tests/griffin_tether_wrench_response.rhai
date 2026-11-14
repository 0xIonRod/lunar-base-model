const ROOT="/Griffin1SurfaceOps";
const PROBE_FORCE_N=120.0;
const PROBE_TORQUE_NM=30.0;

fn simulation_dependencies(me,ctx) {
    let rover=find_path(ROOT+"/FLIP");
    let probe=find_path(ROOT+"/WrenchProbe");
    #{modelica_entities:[probe],entity_reads:[rover,probe],entity_writes:[rover,probe],
      query_reads:["QueryPhysicsState","ReadPorts"],required_inputs:[]}
}

fn output_value(probe,name) {
    let snapshot=read_ports(probe,[name]);
    for port in snapshot.ports {
        if port.name==name && port.direction=="out" && port.value!=() && port.value.is_finite() {
            return port.value;
        }
    }
    throw("Wrench probe output is missing or non-finite: "+name);
}

fn write_probe(probe,force,torque) {
    let result=cmd("SetPorts",#{target:probe,writes:[["force_x",force],["torque_y",torque]]});
    if result==() || result.ok!=true {throw("Wrench probe input was rejected: "+result);}
}

fn write_body_wrench(rover,force,torque) {
    let result=cmd("SetPortsBatch",#{batches:[#{target:rover,writes:[["force_x",force],["torque_y",torque]]},
        #{target:find_path(ROOT+"/WrenchProbe"),writes:[["force_x",force],["torque_y",torque]]}]});
    if result==() || result.ok!=true {throw("Native FLIP wrench write was rejected: "+result);}
    let snapshot=read_ports(rover,["force_x","torque_y"]);
    let inputs=#{};
    for port in snapshot.ports {if port.direction=="in" {inputs[port.name]=port.value;}}
    if inputs.force_x==() || inputs.torque_y==() {throw("Native wrench input readback is unavailable");}
    inputs
}

fn release_body_wrench(rover) {
    for name in ["force_x","torque_y"] {
        let result=cmd("ReleasePort",#{target:rover,name:name});
        if result==() || result.ok!=true {throw("Native FLIP wrench release was rejected: "+result);}
    }
}

fn verdict(state) {
    state.done=true;
    let failures=[];
    if abs(state.force_output-PROBE_FORCE_N)>0.01 {failures.push("Modelica force output did not match the bounded pulse");}
    if abs(state.torque_output-PROBE_TORQUE_NM)>0.01 {failures.push("Modelica torque output did not match the bounded pulse");}
    if state.delta_v_x<state.one_step_delta_v*0.50 {failures.push("Native FLIP force sink produced no expected x-velocity response");}
    if state.delta_omega_y<state.one_step_delta_omega*0.50 {failures.push("Native FLIP torque sink produced no expected y-angular-rate response");}
    if abs(state.cancel_v_x)>max(state.one_step_delta_v*2.5,0.0001) {failures.push("Zero force did not stop additional velocity change after the sampled handoff");}
    if abs(state.cancel_omega_y)>max(state.one_step_delta_omega*2.5,0.0001) {failures.push("Zero torque did not stop additional angular-rate change after the sampled handoff");}
    let ok=failures.len()==0;
    report_structured_verdict(#{ok:ok,verdict:if ok {"pass"} else {"fail"},
        check_count:6,pass_count:6-failures.len(),failure_count:failures.len(),failures:failures,
        metrics:#{force_output_n:state.force_output,torque_output_nm:state.torque_output,
          expected_delta_v_x_mps:state.expected_delta_v,measured_delta_v_x_mps:state.delta_v_x,
          expected_delta_omega_y_radps:state.expected_delta_omega,measured_delta_omega_y_radps:state.delta_omega_y,
          velocity_change_after_zero_v_x_mps:state.cancel_v_x,angular_rate_change_after_zero_radps:state.cancel_omega_y,
          native_force_after_positive_set_n:state.positive_native_force,native_torque_after_positive_set_nm:state.positive_native_torque,
          native_force_after_zero_set_n:state.zero_native_force,native_torque_after_zero_set_nm:state.zero_native_torque,
          probe_force_n:PROBE_FORCE_N,probe_torque_nm:PROBE_TORQUE_NM,
          scope:"Modelica output sampled by the scenario and applied through native SetPorts to FLIP Avian body sinks; open-air response, not tether or flight qualification"}},
        "GRIFFIN NATIVE TETHER WRENCH RESPONSE","GRIFFIN_TETHER_WRENCH_RESPONSE");
}

fn on_start(me,ctx) {
    this.started=sim_tick();this.stage="settle";this.done=false;
    this.rover=find_path(ROOT+"/FLIP");this.probe=find_path(ROOT+"/WrenchProbe");
    if this.rover<0 || this.probe<0 {throw("Wrench-response fixture is missing FLIP or its Modelica probe");}
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
        write_probe(this.probe,PROBE_FORCE_N,PROBE_TORQUE_NM);
        this.stage="observe_pulse";return;
    }
    if this.stage=="observe_pulse" {
        let force=output_value(this.probe,"body_force_x");
        let torque=output_value(this.probe,"body_torque_y");
        if abs(force-PROBE_FORCE_N)>0.01 || abs(torque-PROBE_TORQUE_NM)>0.01 {return;}
        let pending=write_body_wrench(this.rover,force,torque);
        this.positive_native_force=pending.force_x;this.positive_native_torque=pending.torque_y;
        this.pulse_tick=sim_tick();this.stage="hold_pulse";return;
    }
    if this.stage=="hold_pulse" {
        if sim_tick()-this.pulse_tick<3 {return;}
        let physics=query("QueryPhysicsState",#{id:this.rover});
        this.delta_v_x=physics.linear_velocity_mps[0]-this.baseline_v;
        this.delta_omega_y=physics.angular_velocity_radps[1]-this.baseline_w;
        this.force_output=output_value(this.probe,"body_force_x");
        this.torque_output=output_value(this.probe,"body_torque_y");
        write_probe(this.probe,0.0,0.0);
        this.stage="prepare_cancel";return;
    }
    if this.stage=="prepare_cancel" {
        let force=output_value(this.probe,"body_force_x");
        let torque=output_value(this.probe,"body_torque_y");
        if abs(force)>0.01 || abs(torque)>0.01 {return;}
        let pending=write_body_wrench(this.rover,force,torque);
        this.zero_native_force=pending.force_x;this.zero_native_torque=pending.torque_y;
        release_body_wrench(this.rover);
        this.cancel_tick=sim_tick();this.stage="observe_cancel";return;
    }
    if this.stage=="observe_cancel" {
        if sim_tick()-this.cancel_tick<6 {return;}
        let physics=query("QueryPhysicsState",#{id:this.rover});
        this.cancel_v_x=(physics.linear_velocity_mps[0]-this.baseline_v)-this.delta_v_x;
        this.cancel_omega_y=(physics.angular_velocity_radps[1]-this.baseline_w)-this.delta_omega_y;
        write_probe(this.probe,0.0,0.0);
        write_body_wrench(this.rover,0.0,0.0);
        verdict(this);
    }
}
