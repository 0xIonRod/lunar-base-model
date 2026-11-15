import "lunco://scripting/tools/sysml_requirements" as source;
import "griffin_power_builder" as power;
import "griffin_assembly_support" as support;

fn configuration() {
    let m=source::model();
    if !sysml_model_is(m) {throw("Winch source model unavailable");}
    let p="GriffinWinchRequirements::WinchStudy::";
    let watts=[2,1,-3,0,0,0,0];let volts=[2,1,-3,-1,0,0,0];
    let kelvin=[0,0,0,0,1,0,0];let seconds=[0,0,1,0,0,0,0];
    let c=#{maximum_motor_power:power::si(m,p+"maximumMotorPower",watts),
      efficiency:power::number(m,p+"motorEfficiency"),idle_power:power::si(m,p+"enabledIdlePower",watts),
      voltage_off:power::si(m,p+"voltageOff",volts),voltage_on:power::si(m,p+"voltageOn",volts),
      heat_capacity:power::si(m,p+"heatCapacity",[2,1,-2,0,-1,0,0]),
      initial_temperature:power::si(m,p+"initialTemperature",kelvin),
      radiator_area:power::si(m,p+"radiatorArea",[2,0,0,0,0,0,0]),
      emissivity:power::number(m,p+"radiatorEmissivity"),sink:power::si(m,p+"sinkTemperature",kelvin),
      bus_voltage:power::si(m,"GriffinPowerThermalRequirements::GriffinPowerThermalStudy::busVoltage",volts),
      battery_resistance:power::si(m,"GriffinPowerThermalRequirements::GriffinPowerThermalStudy::batteryResistance",[2,1,-3,-2,0,0,0]),
      power_tolerance:power::si(m,p+"powerTolerance",watts),rate_tolerance:power::number(m,p+"rateToleranceMps"),
      duration:power::si(m,p+"observationDuration",seconds),test_power:power::si(m,p+"testMotorPower",watts),
      test_charge_ah:power::si(m,p+"testBatteryCharge",[0,0,1,1,0,0,0])/3600.0,
      test_epoch:power::number(m,p+"testEpochJd"),test_soc:power::number(m,p+"testInitialSoc"),initial_length:power::number(m,p+"testInitialLengthM"),
      initial_span:power::number(m,p+"testInitialSpanM"),approach_speed:power::number(m,p+"testApproachSpeedMps"),
      payout_speed:power::number(m,p+"testPayoutSpeedMps"),payout_duration:power::si(m,p+"testPayoutDuration",seconds),
      post_loss_extension:power::number(m,p+"testPostLossSpanExtensionM"),
      stiffness:power::number(m,p+"testStiffnessNPerM"),damping:power::number(m,p+"testDampingNsPerM"),
      preload:power::number(m,p+"testPreloadN"),tension_limit:power::number(m,p+"testTensionLimitN"),
      payout_extension:power::number(m,p+"testPayoutExtensionM"),source_revision:m.source_revision};
    for name in ["maximum_motor_power","heat_capacity","initial_temperature","radiator_area","sink",
        "bus_voltage","battery_resistance","duration","test_power","test_charge_ah","initial_length",
        "initial_span","approach_speed","payout_speed","payout_duration","stiffness","preload","tension_limit"] {
        if c[name]<=0.0 {throw("Winch configuration requires positive "+name);}
    }
    for name in ["idle_power","power_tolerance","rate_tolerance","damping","post_loss_extension","payout_extension"] {
        if c[name]<0.0 {throw("Winch configuration requires nonnegative "+name);}
    }
    if c.efficiency<=0.0 || c.efficiency>1.0 || c.emissivity<=0.0 || c.emissivity>1.0
        || c.test_soc<=0.0 || c.test_soc>1.0 || c.voltage_off<=0.0 || c.voltage_on<=c.voltage_off
        || c.bus_voltage<=c.voltage_on || c.payout_duration>=c.duration || c.test_epoch<=0.0 {
        throw("Winch configuration has invalid efficiency, emissivity, SOC, voltage hysteresis, duration or epoch");
    }
    c
}
fn program(edit,net,name,asset) {
    let path=net+"/"+name;
    [support::add(edit,net,name,"Scope"),#{SetApiSchemas:#{edit_target:edit,path:path,schemas:["LunCoProgramAPI"]}},
      support::attribute(edit,path,"info:implementationSource","token","\"sourceAsset\""),
      support::attribute(edit,path,"info:sourceAsset","asset","@"+asset+"@"),
      support::attribute(edit,path,"lunco:program:realtimeSafe","bool","true")]
}
fn thermal_drive_ops(edit,net,c) {
    let drive=net+"/WinchDrive";let mass=net+"/WinchMass";let heat=net+"/WinchHeat";let radiator=net+"/WinchRadiator";
    let ops=program(edit,net,"WinchDrive","twin://astrobotic-griffin-1/models/GriffinWinchDrive.mo");
    ops+=program(edit,net,"WinchMass","lunco://models/LunCo/Thermal/ThermalMass.mo");
    ops+=program(edit,net,"WinchHeat","lunco://models/LunCo/Thermal/HeatLoad.mo");
    ops+=program(edit,net,"WinchRadiator","lunco://models/LunCo/Thermal/Radiator.mo");
    for p in [["efficiency",c.efficiency],["idle_power_w",c.idle_power],["voltage_off_v",c.voltage_off],["voltage_on_v",c.voltage_on]] {
        ops.push(support::scalar(edit,drive,"parameters:"+p[0],p[1]));
    }
    ops.push(support::attribute(edit,drive,"connectors:p","token","\"\""));
    for pair in [["spool_power0_w","winch_spool_power0_w"],["spool_power1_w","winch_spool_power1_w"],
        ["damper_power_w","winch_damper_power_w"],["enabled","winch_enabled"]] {
        ops.push(support::scalar(edit,net,"inputs:"+pair[1],0.0));
        ops.push(support::connection(edit,drive,"inputs:"+pair[0],"double",[net+".inputs:"+pair[1]]));
    }
    let names=["available","power_draw_w","heat_w","mechanical_output_power_w","brake_power_w","power_residual_w"];
    ops+=support::outputs(edit,drive,names);
    for name in names {ops.push(support::connection(edit,net,"outputs:winch_"+name,"double",[drive+".outputs:"+name]));}
    for row in [[mass,"parameters:c_th",c.heat_capacity],[mass,"parameters:T_init",c.initial_temperature],
        [radiator,"parameters:area",c.radiator_area],[radiator,"parameters:emissivity",c.emissivity],[radiator,"parameters:T_sink",c.sink]] {
        ops.push(support::scalar(edit,row[0],row[1],row[2]));
    }
    for path in [mass,heat,radiator] {ops.push(support::attribute(edit,path,"connectors:port","token","\"\""));}
    ops.push(support::connection(edit,mass,"connectors:port","token",[heat+".connectors:port",radiator+".connectors:port"]));
    ops.push(support::connection(edit,heat,"inputs:heat_w","double",[drive+".outputs:heat_w"]));
    ops+=support::outputs(edit,mass,["temp_k","heat_flow_w"]);ops+=support::outputs(edit,heat,["heat_in_w"]);
    ops+=support::outputs(edit,radiator,["heat_rejection_w","temperature_k"]);
    for row in [["winch_temperature_k",mass,"temp_k"],["winch_thermal_storage_w",mass,"heat_flow_w"],
        ["winch_heat_rejection_w",radiator,"heat_rejection_w"]] {
        ops.push(support::connection(edit,net,"outputs:"+row[0],"double",[row[1]+".outputs:"+row[2]]));
    }
    ops
}
fn member_names(net) {[net+"/WinchDrive",net+"/WinchMass",net+"/WinchHeat",net+"/WinchRadiator"]}
fn vehicle_plan(doc,edit,root) {
    try {
        let net=root+"/ElectricalPower";let battery=net+"/Battery";
        let q=query("QueryUsdPrim",#{doc_id:doc,path:net,attrs:[],rels:["collection:components:includes"],connections:true});
        let b=query("QueryUsdPrim",#{doc_id:doc,path:battery,attrs:[],connections:true});
        if q==() || q.relationships==() || b==() || b.connections==() || q.relationships["collection:components:includes"]==() || b.connections["connectors:p"]==() {
            throw("Winch installation requires the composed electrical collection and connected battery");
        }
        let members=q.relationships["collection:components:includes"];let pins=b.connections["connectors:p"];
        for member in member_names(net) {if !members.contains(member) {members.push(member);}}
        let pin=net+"/WinchDrive.connectors:p";if !pins.contains(pin) {pins.push(pin);}
        let ops=thermal_drive_ops(edit,net,configuration());
        ops.push(#{SetRelationship:#{edit_target:edit,path:net,name:"collection:components:includes",targets:members}});
        ops.push(support::connection(edit,battery,"connectors:p","token",pins));
        return #{ok:true,ops:ops,kind:"griffin_winch_energy",members:members};
    } catch(error) {return #{ok:false,error:error,ops:[]};}
}
fn mission_plan(doc,edit,root) {
    let net=root+"/Lander/ElectricalPower";let tether=root+"/EgressTether";let c=configuration();let ops=[];
    for pair in [["winch_spool_power0_w","spool_power0"],["winch_spool_power1_w","spool_power1"],
        ["winch_damper_power_w","damper_power"],["winch_enabled","actuator_enabled"]] {
        ops.push(support::connection(edit,net,"inputs:"+pair[0],"double",[tether+".outputs:"+pair[1]]));
    }
    ops.push(support::connection(edit,tether,"inputs:drive_powered","double",[net+".outputs:winch_available"]));
    ops.push(support::scalar(edit,tether,"inputs:maximum_motor_power_w",c.maximum_motor_power));
    ops+=support::outputs(edit,tether,["spool_power0","spool_power1","damper_power0","damper_power1","actuator_enabled"]);
    #{ok:true,ops:ops,kind:"griffin_winch_mission_bindings"}
}
fn fixture_plan(doc,edit,unpowered) {
    let c=configuration();let net="/World/WinchPower";let tether="/World/Tether";let ops=[];
    ops.push(#{SetApiSchemas:#{edit_target:edit,path:"/World",schemas:["LunCoEpochAPI"]}});
    ops.push(support::scalar(edit,"/World","lunco:time:epochJd",c.test_epoch));
    ops.push(support::add(edit,"/World","Sun","DistantLight"));
    ops.push(support::add(edit,"/World","WinchPower","Scope"));
    ops.push(#{SetApiSchemas:#{edit_target:edit,path:net,schemas:["CollectionAPI:components"]}});
    ops.push(support::attribute(edit,net,"collection:components:expansionRule","token","\"explicitOnly\""));
    ops+=program(edit,net,"Battery","lunco://models/LunCo/Electrical/Battery.mo");
    let battery=net+"/Battery";
    for row in [["voltage_nom",c.bus_voltage],["R_internal",c.battery_resistance],["capacity",c.test_charge_ah],["soc_init",if unpowered {0.0}else{c.test_soc}]] {
        ops.push(support::scalar(edit,battery,"parameters:"+row[0],row[1]));
    }
    ops+=support::outputs(edit,battery,["terminal_voltage_v","net_power_w","stored_power_w","stored_energy_j","heat_w","soc_out"]);
    for name in ["terminal_voltage_v","net_power_w","stored_power_w","stored_energy_j","heat_w","soc_out"] {
        ops.push(support::connection(edit,net,"outputs:battery_"+name,"double",[battery+".outputs:"+name]));
    }
    ops+=thermal_drive_ops(edit,net,c);
    ops.push(support::connection(edit,battery,"connectors:p","token",[net+"/WinchDrive.connectors:p"]));
    let members=[battery];members+=member_names(net);
    ops.push(#{SetRelationship:#{edit_target:edit,path:net,name:"collection:components:includes",targets:members}});
    ops+=program(edit,"/World","Tether","twin://astrobotic-griffin-1/models/GriffinTetherPairStudy.mo");
    ops.push(support::attribute(edit,tether,"lunco:program:realtimeSafe","bool","false"));
    for row in [["stiffness",c.stiffness],["damping",c.damping],["initial_length",c.initial_length],
        ["preload_tension",c.preload],["payout_extension",c.payout_extension],["tension_limit",c.tension_limit],
        ["maximum_motor_power_w",c.test_power],["span0_x",c.initial_span],["span1_x",c.initial_span],
        ["enabled",1.0],["regulate",0.0],["payout_speed0",c.payout_speed],["payout_speed1",c.payout_speed]] {
        ops.push(support::scalar(edit,tether,"inputs:"+row[0],row[1]));
    }
    ops+=support::outputs(edit,tether,["actuator_enabled","spool_power0","spool_power1","damper_power","paid_rate0","paid_rate1", "length0","length1","tension0","tension1"]);
    for pair in [["winch_spool_power0_w","spool_power0"],["winch_spool_power1_w","spool_power1"],
        ["winch_damper_power_w","damper_power"],["winch_enabled","actuator_enabled"]] {
        ops.push(support::connection(edit,net,"inputs:"+pair[0],"double",[tether+".outputs:"+pair[1]]));
    }
    ops.push(support::connection(edit,tether,"inputs:drive_powered","double",[net+".outputs:winch_available"]));
    ops.push(support::add(edit,"/World","WinchObservation","Scope"));
    ops+=program(edit,"/World/WinchObservation","Program","twin://astrobotic-griffin-1/scenarios/tests/griffin_winch_power.rhai");
    ops.push(support::attribute(edit,"/World/WinchObservation/Program","inputs:initially_unpowered","bool",if unpowered {"true"}else{"false"}));
    #{ok:true,ops:ops,kind:"griffin_winch_power_fixture",source_revision:c.source_revision}
}
