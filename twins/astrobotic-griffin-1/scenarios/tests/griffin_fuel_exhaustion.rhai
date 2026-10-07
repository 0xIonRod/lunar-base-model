// Stimulus/verdict only. Tank availability, feed flow, combustion and plume are
// solved by the production Griffin Modelica network. Fixture boundary outputs
// expose Engine01's plume as the representative per-engine observation without
// creating separate physics models; cluster thrust and activity are summed.
fn simulation_dependencies(me,ctx) {
    #{modelica_entities:[find_path("/World/Griffin1"),find_path("/World/Griffin1/MainPropulsion"),
          find_path("/World/Griffin1/AttitudeActuation"),find_path("/World/Griffin1/AttitudePropulsion")],
      entity_reads:[],
      entity_writes:[],query_reads:[],required_inputs:[]}
}
fn on_start(me,ctx) {
    this.griffin=find_path("/World/Griffin1");
    this.main=find_path("/World/Griffin1/MainPropulsion");
    this.rcs=find_path("/World/Griffin1/AttitudePropulsion");
    this.allocator=find_path("/World/Griffin1/AttitudeActuation");
    this.elapsed=0.0;this.empty_since=();this.burn_seen=false;this.rcs_burn_seen=false;this.done=false;
    let control=cmd("AcquireControl",#{target:this.griffin,bind_camera:false});
    let command=cmd("SetPorts",#{target:this.griffin,writes:[["external_throttle",1.0],["yaw",1.0]]});
    this.command_ok=control.ok && command.ok;
}
fn on_tick(me,ctx) {
    if this.done {return;}this.elapsed+=dt();
    let thrust=griffin_spec::main_engine_total(this.main,"thrust_n");let light=get(this.main,"test_intensity");
    if thrust!=() && thrust>1.0 && light>0.0 {this.burn_seen=true;}
    if get(this.rcs,"yaw_pos_a_thrust_n")>1.0 && get(this.rcs,"test_rcs_intensity")>0.0 {
        this.rcs_burn_seen=true;
    }
    let fuel=get(this.main,"test_fuel_mass");
    let oxidizer=get(this.main,"test_oxidizer_mass");
    // Observe actual depletion, rather than assuming an inherited flow empties
    // the 5 kg fixture in three seconds. A 10 s study timeout bounds a failed
    // feed/command. Rationale: requirements/griffin-size-evidence.md.
    if fuel!=() && oxidizer!=() && fuel>0.0 && oxidizer>0.0 && this.elapsed<10.0 {return;}
    // One second lets the shared availability boundary and .08 s valve
    // response settle; this does not close the still-held command.
    if fuel!=() && oxidizer!=() && (fuel==0.0 || oxidizer==0.0) {
        if this.empty_since==() {this.empty_since=this.elapsed;}
        if this.elapsed-this.empty_since<1.0 && this.elapsed<10.0 {return;}
    }
    if this.elapsed>=3.0 {
        print("[griffin-rcs-feed] t="+this.elapsed+" valve="+get(this.allocator,"yaw_pos_a_valve")
            +" thrust="+get(this.rcs,"yaw_pos_a_thrust_n")
            +" activity="+get(this.rcs,"yaw_pos_a_activity")
            +" light="+get(this.rcs,"test_rcs_intensity"));
    }
    let failures=[];
    failures.push(t_true(this.command_ok,"engine command was rejected"));
    failures.push(t_true(this.burn_seen,"fuel never produced thrust and a plume"));
    failures.push(t_true(get(this.griffin,"throttle")>0.99,"engine command stopped before fuel exhaustion"));
    let fuel_empty=fuel==0.0 && oxidizer>0.0;
    let oxidizer_empty=oxidizer==0.0 && fuel>0.0;
    failures.push(t_true(fuel_empty || oxidizer_empty,
        "exactly one reservoir must deplete while the other remains available"));
    failures.push(t_true((fuel_empty && griffin_spec::main_engine_total(this.main,"oxidizer_flow_kgs")>0.0)
        || (oxidizer_empty && griffin_spec::main_engine_total(this.main,"fuel_flow_kgs")>0.0),
        "the opposite reactant feed must remain available"));
    failures.push(t_true(thrust==0.0 && griffin_spec::main_engine_total(this.main,"activity")==0.0,
        "engine continued combustion without both reactants"));
    failures.push(t_true(light==0.0 && get(this.main,"test_length")==0.0
        && get(this.main,"test_plume_activity")==0.0,"inactive engine left a plume"));
    failures.push(t_true(get(this.rcs,"test_rcs_intensity")!=(),"RCS light telemetry unavailable"));
    failures.push(t_true(this.rcs_burn_seen,"RCS never fired with available propellant"));
    failures.push(t_true(get(this.allocator,"yaw_pos_a_valve")>0.0,
        "RCS valve demand did not remain open after fuel exhaustion"));
    failures.push(t_true(get(this.rcs,"yaw_pos_a_thrust_n")==0.0
        && get(this.rcs,"yaw_pos_a_activity")==0.0
        && get(this.rcs,"test_rcs_intensity")==0.0,
        "RCS useful thrust or shared light persisted without both reactants"));
    print("[griffin-fuel-exhaustion] burn_seen="+this.burn_seen+" fuel="+get(this.main,"test_fuel_mass")
        +" oxidizer="+oxidizer+" thrust="+thrust+" intensity="+light);
    this.done=true;report_verdict(failures,"GRIFFIN FUEL EXHAUSTION","GRIFFIN_FUEL_EXHAUSTION");
}
