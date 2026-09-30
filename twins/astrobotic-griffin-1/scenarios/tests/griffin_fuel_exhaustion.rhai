// Stimulus/verdict only. Tank availability, feed flow, combustion and plume are
// solved by the production Griffin Modelica network. Fixture boundary outputs
// expose grouped member observations without creating separate physics models.
fn simulation_dependencies(me,ctx) {
    #{modelica_entities:[find_path("/World/Griffin1"),find_path("/World/Griffin1/MainPropulsion")],
      entity_reads:[],
      entity_writes:[],query_reads:[],required_inputs:[]}
}
fn on_start(me,ctx) {
    this.griffin=find_path("/World/Griffin1");
    this.main=find_path("/World/Griffin1/MainPropulsion");
    this.elapsed=0.0;this.burn_seen=false;this.done=false;
    let control=cmd("AcquireControl",#{target:this.griffin,bind_camera:false});
    let command=cmd("SetPorts",#{target:this.griffin,writes:[["external_throttle",1.0]]});
    this.command_ok=control.ok && command.ok;
}
fn on_tick(me,ctx) {
    if this.done {return;}this.elapsed+=dt();
    let thrust=get(this.main,"thrust_n");let light=get(this.main,"test_intensity");
    if thrust!=() && thrust>1.0 && light>0.0 {this.burn_seen=true;}
    if this.elapsed<3.0 {return;}
    let failures=[];
    failures.push(t_true(this.command_ok,"engine command was rejected"));
    failures.push(t_true(this.burn_seen,"fuel never produced thrust and a plume"));
    failures.push(t_true(get(this.griffin,"throttle")>0.99,"engine command stopped before fuel exhaustion"));
    failures.push(t_true(get(this.main,"test_fuel_mass")==0.0,"fuel tank did not empty"));
    failures.push(t_true(get(this.main,"test_oxidizer_flow")>0.0,"oxidizer did not remain available"));
    failures.push(t_true(thrust==0.0 && get(this.main,"engine_activity")==0.0,
        "engine continued combustion without fuel"));
    failures.push(t_true(light==0.0 && get(this.main,"test_length")==0.0
        && get(this.main,"test_plume_activity")==0.0,"inactive engine left a plume"));
    print("[griffin-fuel-exhaustion] burn_seen="+this.burn_seen+" fuel="+get(this.main,"test_fuel_mass")
        +" thrust="+thrust+" intensity="+light);
    this.done=true;report_verdict(failures,"GRIFFIN FUEL EXHAUSTION","GRIFFIN_FUEL_EXHAUSTION");
}
