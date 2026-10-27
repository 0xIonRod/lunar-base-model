// CAD v5: native panel motion and finite electrical power, observed together.
const R="/Griffin1SurfaceOps/FLIP";
fn simulation_dependencies(me,ctx) {
    let rover=find_path(R);let controller=find_path(R+"/SolarMechanism/Controller");
    #{modelica_entities:[rover,controller,find_path(R+"/Thermal")],
      entity_reads:[rover,controller,find_path(R+"/SolarMechanism"),find_path(R+"/PanelHinge")],
      entity_writes:[rover,controller],query_reads:["ReadPorts","QueryUsdPrim"],required_inputs:[]}
}
fn value(path,name) {
    let result=query("ReadPorts",#{api_id:find_path(path),port_names:[name]});
    let matches=[];
    for row in result.ports {if row.name==name && row.direction=="out" {matches.push(row.value);}}
    if matches.len()!=1 {throw("Expected one native output "+path+"."+name);}
    matches[0]
}
fn command(degrees) {
    let result=cmd("SetPorts",#{target:find_path(R+"/SolarMechanism/Controller"),writes:[["command_deg",degrees]]});
    if result.ok!=true {throw("CAD panel command rejected");}
}
fn on_start(me,ctx) {
    this.time=0.0;this.phase="settle";this.done=false;this.solar_seen=false;this.checks=[];
    this.initial_soc=value(R,"battery_soc");
    this.minimum_soc=this.initial_soc;this.maximum_solar=0.0;
    brake(find_path(R));
}
fn on_tick(me,ctx) {
    if this.done {return;}this.time+=dt();
    let soc=value(R,"battery_soc");
    let power=value(R,"solar_power");
    let voltage=value(R,"bus_voltage");
    this.minimum_soc=min(this.minimum_soc,soc);
    this.maximum_solar=max(this.maximum_solar,power);
    this.solar_seen=this.solar_seen || power>0.0;
    if this.phase=="settle" && this.time>=2.0 {
        command(0.0);this.phase="stow";this.time=0.0;return;
    }
    if this.phase=="stow" && this.time>=12.0 {
        this.stowed=value(R+"/PanelHinge","angle");
        this.checks.push(t_true(abs(this.stowed)<0.035,"native panel reaches stowed position within 2 degrees"));
        command(82.0);drive(find_path(R),0.4,0.0);
        this.phase="deploy";this.time=0.0;return;
    }
    if this.phase=="deploy" && this.time>=12.0 {
        let deployed=value(R+"/PanelHinge","angle");
        this.checks.push(t_true(abs(deployed+82.0*0.017453292519943295)<0.035,"native panel reaches deployed position within 2 degrees"));
        this.checks.push(t_true(abs(deployed-this.stowed)>1.0,"panel body physically moves through its hinge"));
        this.checks.push(t_true(this.minimum_soc<this.initial_soc,"finite battery discharges under wheel load"));
        this.checks.push(t_true(soc>0.0 && soc<1.0,"battery SOC remains within physical bounds"));
        this.checks.push(t_true(voltage>0.0 && voltage<40.0,"finite battery supplies the bus"));
        this.checks.push(t_true(this.solar_seen,"moving CAD panel generates electrical power from its environment probe"));
        brake(find_path(R));this.done=true;
        print("CAD EPS/PANEL: stowed="+this.stowed+" deployed="+deployed+" soc_initial="+this.initial_soc+" soc_min="+this.minimum_soc+" solar_max_w="+this.maximum_solar);
        report_verdict(this.checks,"FLIP CAD CAPABILITIES","FLIP_CAD_CAPABILITIES");
    }
}
