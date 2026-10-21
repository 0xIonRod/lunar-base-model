// Observe the production vehicle network on the simulation clock. No physics
// or test-only panel equations are substituted by this observer.
const ROOT="/Griffin1SurfaceOps/Lander";
const PACKAGE="GriffinPowerThermalRequirements::";
const VERIFY="Verify_GriffinPowerThermal";

fn simulation_dependencies(me,ctx) {
    let net=find_path(ROOT+"/ElectricalPower");
    #{modelica_entities:[find_path(ROOT),net],entity_reads:[net,find_path(ROOT)],
      entity_writes:[],query_reads:["QueryUsdPrim","QueryUsdPrims","AnalyzeSysml","ReadActiveTwinContract"],
      required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_name()}]}
}
fn wired(record,name,source) {
    record!=() && record.connections!=() && record.connections[name]!=()
        && record.connections[name].len()==1 && record.connections[name][0]==source
}
fn row_area(path) {
    let r=query("QueryUsdPrim",#{path:path,attrs:["points","faceVertexCounts","faceVertexIndices"]});
    if r==() || r.attrs==() {throw("cell row unavailable: "+path);}
    let points=r.attrs.points;let counts=r.attrs.faceVertexCounts;let indices=r.attrs.faceVertexIndices;
    if points==() || points.is_empty() || counts==() || indices==() {throw("cell topology unavailable");}
    let high=-1.0e30;for p in points {high=max(high,p[1]);}
    let cursor=0;let area=0.0;
    // Integrate only the outward (+Y), flat illuminated face. Side walls and
    // the second face of each closed cell contribute no collecting area.
    for count in counts {
        let flat=true;let twice=0.0;
        for i in 0..count {
            let a=points[indices[cursor+i]];let b=points[indices[cursor+(i+1)%count]];
            flat=flat && abs(a[1]-high)<1.0e-7;
            twice+=a[0]*b[2]-b[0]*a[2];
        }
        if flat {area+=abs(twice)/2.0;}
        cursor+=count;
    }
    if cursor!=indices.len() {throw("invalid cell topology");}
    #{area:area,identity:r}
}
fn on_start(me,ctx) {
    this.config=griffin_power_builder::configuration();
    this.names=griffin_spec::solar_array_names();
    this.net=find_path(ROOT+"/ElectricalPower");
    this.root=find_path(ROOT);this.start=sim_tick();this.done=false;
    this.samples=0;this.area_index=0;this.row=0;this.areas=[0.0,0.0,0.0];
    this.initial=[];this.final=[];this.generated=[false,false,false];
    this.temperature_law=true;this.radiant=true;this.thermal=true;
    this.cooling=true;this.electrical=true;this.storage=true;this.load=true;
    this.feedback=true;this.sun=true;this.gate=true;this.geometry=true;
    this.max_power_residual=0.0;this.max_temperature_residual=0.0;
    this.layout=[];this.pv_area=[];this.scale=[];
    let net=ROOT+"/ElectricalPower";
    let root=query("QueryUsdPrim",#{path:ROOT,attrs:[],connections:true});
    this.gate=wired(root,"inputs:control_powered",net+".outputs:avionics_powered");
    for i in 0..this.names.len() {
        let name=this.names[i];let pv=net+"/"+name;
        let panel=query("QueryUsdPrim",#{path:ROOT+"/"+name,attrs:["xformOp:scale"]});
        let scale=panel.attrs["xformOp:scale"];
        if scale==() {throw("explicit installed panel scale unavailable");}
        this.scale.push(abs(scale[0]*scale[2]));
        this.layout.push(griffin_spec::solar_installed_cell_layout(i));
        let record=query("QueryUsdPrim",#{path:pv,attrs:["parameters:area"],connections:true});
        this.pv_area.push(record.attrs["parameters:area"]);
        this.feedback=this.feedback && wired(record,"inputs:cell_temperature_k",pv+"Mass.outputs:temp_k");
        for pair in [["irradiance","sun_irradiance_w_m2"],["sun_visibility","sun_visibility"],
            ["target_mount_x","sun_mount_x"],["target_mount_y","sun_mount_y"],["target_mount_z","sun_mount_z"]] {
            this.sun=this.sun && wired(record,"inputs:"+pair[0],net+".inputs:"+name+"_"+pair[0]);
        }
        let boundary=query("QueryUsdPrim",#{path:net,attrs:[],connections:true});
        this.sun=this.sun && wired(boundary,"inputs:"+name+"_irradiance",ROOT+"/"+name+"/PowerEnvironment.outputs:sun_irradiance_w_m2")
            && wired(boundary,"inputs:"+name+"_sun_visibility",ROOT+"/"+name+"/PowerEnvironment.outputs:sun_visibility");
    }
    print("[griffin-power-thermal] observing production network for "+this.config.duration+" s");
}
fn port(entity,name) {
    let value=get(entity,name);
    if value==() || !value.is_finite() {throw("finite network port unavailable: "+name);}
    value
}
fn observation(value,start) {
    #{provider:"telemetry",state:"value",value:value,provider_generation:sim_tick(),
      document_id:(),document_generation:(),
      sample_interval:#{clock:"simulation",start_tick:start,end_tick:sim_tick()}}
}
fn constraint_check(model,id,requirement,constraint,values,start) {
    let ir=sysml_requirements::required_constraint_ir(model,model.requirement(PACKAGE+requirement),PACKAGE+constraint);
    let observations=[];
    for value in values {
        let o=observation(value[1],start);o.source_revision=model.source_revision;
        observations.push(sysml_requirements::scalar_constraint_observation(ir,value[0],o));
    }
    sysml_requirements::required_constraints_check(id,"griffin_power_thermal",requirement,VERIFY,
        PACKAGE+constraint,observations,"typed",0.0)
}
fn on_tick(me,ctx) {
    if this.done {return;}
    let c=this.config;
    if this.area_index<this.names.len() {
        let i=this.area_index;let name=this.names[i];
        let measured=row_area(ROOT+"/"+name+"/CellRow"+this.row);
        this.areas[i]+=measured.area*this.scale[i];this.row+=1;
        if this.row==this.layout[i].rows {
            this.geometry=this.geometry && abs(this.areas[i]-this.pv_area[i])<=c.area_tolerance;
            this.row=0;this.area_index+=1;
        }
    }
    // Ten-tick samples bound observer overhead while all coupled equations
    // continue to advance at the simulator's own integration rate.
    if (sim_tick()-this.start)%10!=0 {return;}
    let generation=0.0;
    let temperatures=[];
    for i in 0..this.names.len() {
        let prefix=this.names[i]+"_";let e=this.net;
        let power=port(e,prefix+"power_out");let available=port(e,prefix+"available_power_w");
        let incident=port(e,prefix+"incident_power_w");let absorbed=port(e,prefix+"absorbed_power_w");
        let reflected=port(e,prefix+"reflected_power_w");let heat=port(e,prefix+"heat_w");
        let temperature=port(e,prefix+"temperature_k");let factor=port(e,prefix+"temperature_factor");
        let mass_temperature=port(e,prefix+"mass_temp_k");let flow=port(e,prefix+"mass_heat_flow_w");
        let cooling=port(e,prefix+"cooler_heat_rejection_w");
        let expected=max(0.0,1.0+c.power_temperature_coefficient*(temperature-c.reference_temperature));
        let residual=max(abs(incident-absorbed-reflected),abs(absorbed-power-heat));
        this.max_power_residual=max(this.max_power_residual,residual);
        this.max_temperature_residual=max(this.max_temperature_residual,abs(factor-expected));
        this.temperature_law=this.temperature_law && abs(factor-expected)<=c.temperature_tolerance
            && abs(available-min(min(c.absorptivity,c.efficiency*expected)*incident,
                this.pv_area[i]*c.efficiency*c.reference_irradiance*expected))<=c.power_tolerance
            && temperature>=c.reference_temperature-c.temperature_tolerance && temperature<=c.maximum_temperature;
        this.radiant=this.radiant && residual<=c.power_tolerance;
        this.thermal=this.thermal && abs(flow-(heat-cooling))<=c.power_tolerance
            && abs(temperature-mass_temperature)<=c.temperature_tolerance;
        this.cooling=this.cooling && cooling>=-c.power_tolerance && cooling<=c.maximum_cooling+c.power_tolerance
            && (temperature>c.minimum_temperature+c.temperature_tolerance || abs(cooling)<=c.power_tolerance);
        this.generated[i]=this.generated[i] || power>c.power_tolerance;
        temperatures.push(temperature);generation+=power;
    }
    if this.samples==0 {this.initial=temperatures;}
    this.final=temperatures;this.samples+=1;
    let battery=port(this.net,"battery_net_power_w");let load=port(this.net,"avionics_power_draw_w");
    this.electrical=this.electrical && abs(generation-battery-load)<=c.power_tolerance;
    this.storage=this.storage && abs(battery-port(this.net,"battery_stored_power_w")-port(this.net,"battery_heat_w"))<=c.power_tolerance;
    this.load=this.load && abs(load-c.baseline_power-c.guidance_power)<=c.power_tolerance
        && port(this.net,"avionics_powered")==1.0;
    if (sim_tick()-this.start).to_float()*dt()<c.duration {return;}
    let responded=true;let generated=true;
    for i in 0..this.names.len() {
        responded=responded && this.final[i]>this.initial[i]+c.temperature_tolerance;
        generated=generated && this.generated[i];
    }
    let model=sysml_requirements::model();
    let checks=[constraint_check(model,"GEP-001-conversion","gep001","GEP001_ConversionClosed",[
        ["geometryAreaMatches",this.geometry && this.area_index==3],["physicalSunDemand",this.sun],
        ["temperatureLawMatches",this.temperature_law],["radiantBalanceClosed",this.radiant],
        ["generatedPowerObserved",generated]],this.start),
      constraint_check(model,"GEP-002-cooling","gep002","GEP002_CoolingClosed",[
        ["temperatureFeedbackWired",this.feedback],["temperatureResponded",responded],
        ["thermalNodeBalanceClosed",this.thermal],["coolingWithinBounds",this.cooling],
        ["fullHorizonObserved",this.samples>1]],this.start),
      constraint_check(model,"GEP-003-supply","gep003","GEP003_PowerSupplyClosed",[
        ["electricalNodeBalanceClosed",this.electrical],["batteryEnergyBalanceClosed",this.storage],
        ["loadPowerObserved",this.load],["flightPowerGateWired",this.gate]],this.start)];
    let source=sysml_requirements::source_with_selection([],
        [PACKAGE+"gep001",PACKAGE+"gep002",PACKAGE+"gep003"],[PACKAGE+VERIFY]);
    let report=sysml_requirements::evaluate(source,checks);
    report.metrics=#{samples:this.samples,area_m2:this.areas,initial_temperature_k:this.initial,
        final_temperature_k:this.final,maximum_power_residual_w:this.max_power_residual,
        maximum_temperature_factor_residual:this.max_temperature_residual};
    print("GRIFFIN_POWER_THERMAL_METRICS "+to_json(report.metrics));
    report_structured_verdict(report,"GRIFFIN POWER THERMAL","GRIFFIN_POWER_THERMAL");
    this.done=true;
}
