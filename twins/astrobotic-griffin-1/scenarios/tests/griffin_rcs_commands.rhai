// Observe the production geometry-derived allocator and Newton-valued jet outputs.
// The fixture disables rigid-body motion so each signed demand can be inspected
// in the same authored body frame; no substitute propulsion equations are used.
fn simulation_dependencies(me,ctx) {
    #{modelica_entities:[find_path("/World/Griffin1"),
        find_path("/World/Griffin1/AttitudeActuation"),find_path("/World/Griffin1/AttitudePropulsion")],
      entity_reads:[],entity_writes:[],query_reads:["QueryUsdPrim","AnalyzeSysml"],required_inputs:[]}
}
fn command_axis(target,row) {
    let values=[0.0,0.0,0.0];values[row.axis]=row.sign;
    cmd("SetPorts",#{target:target,writes:[["pitch",values[0]],
        ["yaw",values[1]],["roll",values[2]],["external_throttle",0.0]]});
}
fn on_start(me,ctx) {
    this.griffin=find_path("/World/Griffin1");
    this.rcs=find_path("/World/Griffin1/AttitudePropulsion");
    this.cases=[#{name:"pitch_pos",axis:0,sign:1.0},#{name:"pitch_neg",axis:0,sign:-1.0},
        #{name:"yaw_pos",axis:1,sign:1.0},#{name:"yaw_neg",axis:1,sign:-1.0},
        #{name:"roll_pos",axis:2,sign:1.0},#{name:"roll_neg",axis:2,sign:-1.0}];
    this.index=0;this.done=false;this.failures=[];this.stations=[];
    this.settling=griffin_spec::_typed_model_number(
        "GriffinPropulsionRequirements::GriffinAttitudeEngineAssembly::commandSettlingS");
    this.tolerance=griffin_spec::_typed_model_number(
        "GriffinPropulsionRequirements::GriffinAttitudeEngineAssembly::wrenchRelativeTolerance");
    if this.settling==() || this.tolerance==() {throw("RCS command acceptance source unavailable");}
    let own="GriffinPropulsionRequirements::GriffinAttitudeEngineAssembly::";
    this.nominal=griffin_spec::_typed_model_number(own+"nominalForceN");
    this.flow=griffin_spec::_typed_model_number(own+"nominalFuelFlowKgs")
        +griffin_spec::_typed_model_number(own+"nominalOxidizerFlowKgs");
    this.mixture=griffin_spec::_typed_model_number(own+"oxidizerToFuelRatio");
    if this.nominal==() || this.flow==() || this.mixture==() {
        throw("A110 vendor operating point is unavailable");
    }
    for jet in griffin_spec::rcs_port_mapping() {
        let name=jet.model_name.sub_string(0,jet.model_name.len()-5);
        let record=query("QueryUsdPrim",#{path:"/World/Griffin1/"+name,
            attrs:["xformOp:translate","xformOp:rotateXYZ","lunco:forceActuator:direction","lunco:forceActuator:maxForce"]});
        let position=vec3_from(record.attrs["xformOp:translate"]);
        let rotation=quat_from_euler_xyz_deg(vec3_from(record.attrs["xformOp:rotateXYZ"]));
        let direction=qrot(rotation,vec3_from(record.attrs["lunco:forceActuator:direction"]));
        this.stations.push(#{position:position,direction:direction,port:jet.thrust_port,
            nominal:f64_from(record.attrs["lunco:forceActuator:maxForce"])});
    }
    let control=cmd("AcquireControl",#{target:this.griffin,bind_camera:false});
    this.failures.push(t_true(control.ok,"attitude control acquisition rejected"));
    let demand=command_axis(this.griffin,this.cases[this.index]);
    this.failures.push(t_true(demand.ok,"initial attitude command rejected"));
    this.elapsed=0.0;
}
fn on_tick(me,ctx) {
    if this.done {return;}this.elapsed+=dt();if this.elapsed<this.settling {return;}
    let moment=vec3(0.0,0.0,0.0);let net=moment;let force_capacity=0.0;
    let delivered=0.0;
    for station in this.stations {
        let thrust=get(this.rcs,station.port);
        if thrust==() {throw("RCS thrust telemetry unavailable: "+station.port);}
        let force=station.direction*thrust;
        moment+=vcross(station.position,force);net+=force;force_capacity+=station.nominal;
        delivered+=thrust;
    }
    let row=this.cases[this.index];let components=vec3_array(moment);
    let wanted=components[row.axis]*row.sign;let unwanted=0.0;
    for index in 0..3 {if index!=row.axis {unwanted+=components[index].abs();}}
    let requested=[get(this.griffin,"torque_x"),get(this.griffin,"torque_y"),get(this.griffin,"torque_z")];
    this.failures.push(t_true(wanted>0.0
        && (components[row.axis]-requested[row.axis]).abs()<=wanted*this.tolerance
        && unwanted<=wanted*this.tolerance
        && vlen(net)<=force_capacity*this.tolerance,
        "command did not produce the requested pure moment: "+row.name));
    let expected_flow=delivered/this.nominal*this.flow;
    let measured_flow=get(this.rcs,"mass_flow_kgs");
    let fuel_flow=get(this.rcs,"fuel_mass_flow_kgs");
    let oxidizer_flow=get(this.rcs,"oxidizer_mass_flow_kgs");
    this.failures.push(t_true(measured_flow!=() && fuel_flow!=() && oxidizer_flow!=()
        && expected_flow>0.0
        && (measured_flow-expected_flow).abs()<=expected_flow*this.tolerance
        && (oxidizer_flow-fuel_flow*this.mixture).abs()<=expected_flow*this.tolerance,
        "A110 propellant consumption does not follow delivered impulse: "+row.name));
    print("[griffin-rcs-command] case="+row.name+" moment_Nm="+vec3_array(moment)
        +" net_force_N="+vec3_array(net)+" desired_Nm="
        +[get(this.griffin,"torque_x"),get(this.griffin,"torque_y"),get(this.griffin,"torque_z")]);
    this.index+=1;
    if this.index<this.cases.len() {
        let demand=command_axis(this.griffin,this.cases[this.index]);
        this.failures.push(t_true(demand.ok,"attitude command rejected"));
        this.elapsed=0.0;return;
    }
    cmd("SetPorts",#{target:this.griffin,writes:[["pitch",0.0],["yaw",0.0],["roll",0.0]]});
    this.done=true;report_verdict(this.failures,"GRIFFIN RCS COMMANDS","GRIFFIN_RCS_COMMANDS");
}
