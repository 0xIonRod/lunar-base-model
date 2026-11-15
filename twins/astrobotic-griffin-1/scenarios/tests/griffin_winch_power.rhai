import "lunco://scripting/tools/sysml_requirements" as source;
const TEST_KIND="headless";
const NET="/World/WinchPower";
const TETHER="/World/Tether";
const PACKAGE="GriffinWinchRequirements::";

fn simulation_dependencies(me,ctx) {
    let net=find_path(NET);let tether=find_path(TETHER);
    #{modelica_entities:[net,tether],entity_reads:[net,tether,me],entity_writes:[tether],
      query_reads:["QueryUsdPrim","AnalyzeSysml","ReadActiveTwinContract"],
      required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_source_identity()}]}
}
fn value(entity,name) {
    let v=get(entity,name);
    if v==() || !v.is_finite() {throw("Missing finite winch observation: "+name);} v
}
fn command(tether,writes) {
    let r=cmd("SetPorts",#{target:tether,writes:writes});
    if r==() || r.ok!=true {throw("Winch fixture stimulus rejected: "+r);}
}
fn on_start(me,ctx) {
    let authored=query("QueryUsdPrim",#{path:usd_path(me)+"/Program",attrs:["inputs:initially_unpowered"]});
    let mode=authored.attrs["inputs:initially_unpowered"];
    if mode!=true && mode!=false {throw("Winch fixture requires an explicit initially_unpowered boolean");}
    this.empty=mode;this.config=griffin_winch_builder::configuration();
    this.net=find_path(NET);this.tether=find_path(TETHER);this.start=sim_tick();this.done=false;
    this.initial_energy=();this.final_energy=();this.initial_temperature=();this.final_temperature=();
    this.powered=0;this.unpowered=0;this.last_powered=sim_tick();this.sustained_off=();
    this.hold=true;this.passive=false;this.empty_never_powered=true;
    this.balance=true;this.heat_balance=true;this.bounded=true;this.demand_held=true;
    this.peak_motor=0.0;this.peak_draw=0.0;this.peak_brake=0.0;this.peak_heat=0.0;
    this.max_bus_residual=0.0;this.max_thermal_residual=0.0;
}
fn on_tick(me,ctx) {
    if this.done {return;}
    let c=this.config;let seconds=(sim_tick()-this.start).to_float()*dt();
    let available=value(this.net,"winch_available");let draw=value(this.net,"winch_power_draw_w");
    let battery=value(this.net,"battery_net_power_w");let storage=value(this.net,"battery_stored_power_w");
    let battery_heat=value(this.net,"battery_heat_w");let energy=value(this.net,"battery_stored_energy_j");
    let temperature=value(this.net,"winch_temperature_k");let heat=value(this.net,"winch_heat_w");
    let thermal=value(this.net,"winch_thermal_storage_w");let rejected=value(this.net,"winch_heat_rejection_w");
    let brake=value(this.net,"winch_brake_power_w");
    if this.initial_energy==() {this.initial_energy=energy;this.initial_temperature=temperature;}
    this.final_energy=energy;this.final_temperature=temperature;
    this.peak_draw=max(this.peak_draw,draw);this.peak_heat=max(this.peak_heat,heat);this.peak_brake=max(this.peak_brake,brake);
    this.empty_never_powered=this.empty_never_powered && available<0.5 && abs(draw)<c.power_tolerance;
    let bus_residual=max(abs(battery+draw),abs(battery-storage-battery_heat));
    this.max_bus_residual=max(this.max_bus_residual,bus_residual);
    this.max_thermal_residual=max(this.max_thermal_residual,abs(thermal-(heat-rejected)));
    this.balance=this.balance && bus_residual<c.power_tolerance
        && abs(value(this.net,"winch_power_residual_w"))<c.power_tolerance;
    this.heat_balance=this.heat_balance && abs(thermal-(heat-rejected))<c.power_tolerance && heat>=-c.power_tolerance;
    let powers=[];let rates=[];let lengths=[];let tensions=[];
    for i in 0..2 {
        let n=i.to_string();let spool=value(this.tether,"spool_power"+n);
        let rate=value(this.tether,"paid_rate"+n);let tension=value(this.tether,"tension"+n);
        powers.push(spool);rates.push(rate);tensions.push(tension);lengths.push(value(this.tether,"length"+n));
        this.peak_motor=max(this.peak_motor,max(0.0,-spool));
        this.bounded=this.bounded && max(0.0,-spool)<=c.test_power+c.power_tolerance;
    }
    if available>0.5 {
        this.powered+=1;this.last_powered=sim_tick();
    } else {
        this.unpowered+=1;
        // RegulatedLoad may restart during the battery's reserve taper.
        // Qualify a sustained supply loss across completed coupled intervals.
        if sim_tick()-this.last_powered>6 {
            if this.sustained_off==() {this.sustained_off=sim_tick();}
            this.hold=this.hold && abs(rates[0])<=c.rate_tolerance && abs(rates[1])<=c.rate_tolerance
                && abs(draw)<c.power_tolerance;
            this.passive=this.passive || (tensions[0]>c.preload*0.5 && tensions[1]>c.preload*0.5);
        }
    }
    let span=c.initial_span-c.approach_speed*max(0.0,seconds-c.payout_duration);
    let regulate=if seconds<c.payout_duration {0.0}else{1.0};
    let radial=if seconds<c.payout_duration {0.0}else{-c.approach_speed};
    if this.empty || this.sustained_off!=() {
        span=lengths[0]+c.post_loss_extension;radial=0.0;
    }
    command(this.tether,[["span0_x",span],["span1_x",span],["rate0",radial],["rate1",radial],
        ["payout_speed0",c.payout_speed],["payout_speed1",c.payout_speed],["regulate",regulate],["enabled",1.0]]);
    this.demand_held=this.demand_held && abs(value(this.tether,"payout_speed0")-c.payout_speed)<c.rate_tolerance
        && abs(value(this.tether,"payout_speed1")-c.payout_speed)<c.rate_tolerance;
    if seconds<c.duration {return;}
    let checks=[];let names=[];let model=source::model();
    let verify=if this.empty {"Verify_GriffinWinchUnpowered"}else{"Verify_GriffinWinchPower"};
    let supply_ok=this.sustained_off!=() && this.unpowered>6 && this.hold && this.passive && this.demand_held;
    if this.empty {supply_ok=supply_ok && this.empty_never_powered;}
    let conditions=[this.powered>6 && this.peak_draw>c.idle_power && this.final_energy<this.initial_energy && this.balance,
        this.bounded && this.peak_motor>c.test_power*0.8,
        this.heat_balance && this.peak_brake>c.power_tolerance && this.peak_heat>c.power_tolerance
            && abs(this.final_temperature-this.initial_temperature)>0.0000001,
        supply_ok];
    let selected=if this.empty {[3]}else{[0,1,2,3]};
    for i in selected {
        let name=PACKAGE+"gwp00"+(i+1).to_string();names.push(name);
        let ir=source::required_constraint_ir(model,model.requirement(name),PACKAGE+"GWPObservedAcceptance");
        let observed=#{provider:"telemetry",state:"value",value:conditions[i],
            source_revision:model.source_revision,provider_generation:sim_tick(),
            document_id:(),document_generation:(),
            sample_interval:#{clock:"simulation",start_tick:this.start,end_tick:sim_tick()}};
        let binding=source::scalar_constraint_observation(ir,"accepted",observed);
        checks.push(source::required_constraints_check(name,"winch_energy",name,PACKAGE+verify,
            PACKAGE+"GWPObservedAcceptance",[binding],"typed",0.0));
    }
    let selection=source::source_with_selection([],names,[PACKAGE+verify]);
    let report=source::evaluate(selection,checks);
    report.metrics=#{initially_unpowered:this.empty,powered_samples:this.powered,unpowered_samples:this.unpowered,
        peak_motor_power_per_drum_w:this.peak_motor,maximum_motor_power_per_drum_w:c.test_power,
        peak_bus_draw_w:this.peak_draw,peak_brake_heat_w:this.peak_brake,peak_heat_w:this.peak_heat,
        initial_battery_energy_j:this.initial_energy,final_battery_energy_j:this.final_energy,
        initial_temperature_k:this.initial_temperature,final_temperature_k:this.final_temperature,
        maximum_bus_residual_w:this.max_bus_residual,maximum_thermal_residual_w:this.max_thermal_residual,
        sustained_off_tick:this.sustained_off,passive_load_observed:this.passive,hold_observed:this.hold};
    report_structured_verdict(report,"GRIFFIN WINCH POWER","GRIFFIN_WINCH_POWER");
    this.done=true;
}
