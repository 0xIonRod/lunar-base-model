// Production vehicle and electrical/propulsion networks. The fixture alone
// reduces battery inventory and prescribes eclipse, so depletion is observable
// in seconds without replacing any battery, converter or controller equations.
const ROOT = "/Griffin1SurfaceOps/Lander";
const PACKAGE = "GriffinPowerThermalRequirements::";
const VERIFY = "Verify_GriffinControlPowerLoss";

fn simulation_dependencies(me, ctx) {
    let root=find_path(ROOT);let net=find_path(ROOT+"/ElectricalPower");
    let main=find_path(ROOT+"/MainPropulsion");
    let rcs=find_path(ROOT+"/AttitudePropulsion");
    #{modelica_entities:[root,net,main,rcs],entity_reads:[root,net,main,rcs],
      entity_writes:[root],query_reads:["QueryUsdPrim","AnalyzeSysml","ReadActiveTwinContract"],
      required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_name()}]}
}
fn port(entity,name) {
    let value=get(entity,name);
    if value==() || !value.is_finite() {throw("finite power-loss port unavailable: "+name);}
    value
}
fn on_start(me,ctx) {
    this.root=find_path(ROOT);this.net=find_path(ROOT+"/ElectricalPower");
    this.main=find_path(ROOT+"/MainPropulsion");this.start=sim_tick();this.done=false;
    this.rcs=find_path(ROOT+"/AttitudePropulsion");this.config=griffin_power_builder::configuration();
    this.off_tick=();this.powered_samples=0;this.off_samples=0;
    this.powered_demand=false;this.powered_thrust=false;this.suppressed=true;
    this.off_load=true;this.balance=true;this.demand_held=true;
    this.peak_thrust=0.0;this.final_thrust=();this.cutoff_voltage=();
    this.peak_rcs=0.0;this.final_rcs=();
    let gate=query("QueryUsdPrim",#{path:ROOT,attrs:[],connections:true});
    this.wired=gate.connections["inputs:control_powered"]==[ROOT+"/ElectricalPower.outputs:avionics_powered"];
    let command=cmd("SetPorts",#{target:this.root,writes:[["guidance_throttle",0.35],["guidance_yaw",0.2]]});
    if command==() || command.ok!=true {throw("power-loss stimulus rejected: "+command);}
}
fn on_tick(me,ctx) {
    if this.done {return;}
    let powered=port(this.net,"avionics_powered");
    let volts=port(this.net,"battery_terminal_voltage_v");
    let load=port(this.net,"avionics_power_draw_w");
    let throttle=port(this.root,"throttle");let torque=port(this.root,"torque_y");
    let thrust=griffin_spec::main_engine_total(this.main,"thrust_n");
    if thrust==() || !thrust.is_finite() {throw("cluster delivered thrust unavailable");}
    this.peak_thrust=max(this.peak_thrust,thrust);this.final_thrust=thrust;
    let rcs=0.0;
    for jet in griffin_spec::rcs_port_mapping() {rcs+=abs(port(this.rcs,jet.thrust_port));}
    this.peak_rcs=max(this.peak_rcs,rcs);this.final_rcs=rcs;
    this.demand_held=this.demand_held && abs(port(this.root,"guidance_throttle")-0.35)<1.0e-9
        && abs(port(this.root,"guidance_yaw")-0.2)<1.0e-9;
    if powered==1.0 && this.off_tick==() {
        this.powered_samples+=1;
        this.powered_demand=this.powered_demand || (throttle>0.1 && abs(torque)>1.0e-6);
        this.powered_thrust=this.powered_thrust || thrust>100.0;
    } else if powered==0.0 {
        if this.off_tick==() {this.off_tick=sim_tick();this.cutoff_voltage=volts;}
        this.off_samples+=1;
        this.off_load=this.off_load && abs(load)<1.0e-6;
        // The network output and controller participant cross completed fixed
        // endpoints. Allow at most three fixed intervals for that propagation;
        // do not erase the separate physical valve/chamber shutdown tail.
        if sim_tick()>this.off_tick+3 {
            this.suppressed=this.suppressed && abs(throttle)<1.0e-9 && abs(torque)<1.0e-9
                && abs(port(this.root,"torque_x"))<1.0e-9 && abs(port(this.root,"torque_z"))<1.0e-9;
        }
    } else {this.suppressed=false;}
    let generation=0.0;
    for name in griffin_spec::solar_array_names() {generation+=port(this.net,name+"_power_out");}
    this.balance=this.balance && abs(generation)<1.0e-6
        && abs(generation-port(this.net,"battery_net_power_w")-load)<1.0e-4;
    if (sim_tick()-this.start).to_float()*dt()<8.0 {return;}
    let full=this.off_tick!=() && (sim_tick()-this.off_tick).to_float()*dt()>2.0;
    let values=[
        ["poweredCommandsObserved",this.powered_samples>60 && this.powered_demand && this.powered_thrust],
        ["lowSupplyObserved",full && this.off_samples>60 && this.cutoff_voltage<=this.config.voltage_off],
        ["commandsSuppressed",this.wired && this.demand_held && this.suppressed],
        ["loadDisconnected",this.off_load && this.balance],
        ["actuatorsSettled",this.peak_thrust>100.0 && this.final_thrust<0.001
            && this.peak_rcs>0.01 && this.final_rcs<0.001]];
    let model=sysml_requirements::model();let requirement=model.requirement(PACKAGE+"gep004");
    let constraint=PACKAGE+"GEP004_LowSupplyCommandsOff";
    let ir=sysml_requirements::required_constraint_ir(model,requirement,constraint);
    let observations=[];
    for pair in values {
        let observation=#{provider:"telemetry",state:"value",value:pair[1],provider_generation:sim_tick(),
            source_revision:model.source_revision,document_id:(),document_generation:(),
            sample_interval:#{clock:"simulation",start_tick:this.start,end_tick:sim_tick()}};
        observations.push(sysml_requirements::scalar_constraint_observation(ir,pair[0],observation));
    }
    let check=sysml_requirements::required_constraints_check("GEP-004-power-loss","griffin_control_power_loss", "gep004", VERIFY,
        constraint,observations,"typed",0.0);
    let source=sysml_requirements::source_with_selection([],[PACKAGE+"gep004"],[PACKAGE+VERIFY]);
    let report=sysml_requirements::evaluate(source,[check]);
    report.metrics=#{powered_samples:this.powered_samples,off_samples:this.off_samples,
        cutoff_voltage_v:this.cutoff_voltage,cutoff_tick:this.off_tick,peak_thrust_n:this.peak_thrust,
        final_thrust_n:this.final_thrust,peak_rcs_thrust_n:this.peak_rcs,
        final_rcs_thrust_n:this.final_rcs,conditions:values};
    print("GRIFFIN_CONTROL_POWER_LOSS_METRICS "+to_json(report.metrics));
    report_structured_verdict(report,"GRIFFIN CONTROL POWER LOSS","GRIFFIN_CONTROL_POWER_LOSS");
    this.done=true;
}
