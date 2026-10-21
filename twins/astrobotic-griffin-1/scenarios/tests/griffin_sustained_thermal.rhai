// Qualify the exact USD-generated network for one hour under a held snapshot
// of its real Sun inputs. This is a subsystem experiment, not a one-hour
// replay of flight/terrain/attitude. No panel or thermal equations are copied.
const ROOT="/Griffin1SurfaceOps/Lander/ElectricalPower";
const PACKAGE="GriffinPowerThermalRequirements::";
const VERIFY="Verify_GriffinSustainedThermal";

fn simulation_dependencies(me,ctx) {
    let net=find_path(ROOT);
    #{modelica_entities:[net],entity_reads:[net],entity_writes:[],
      query_reads:["GeneratedModelicaSource","QueryUsdPrim","CompileStatus","RunStatus",
        "GetExperimentResult","AnalyzeSysml","ReadActiveTwinContract"],
      required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_name()}]}
}
fn ack(value) {
    if value!=() && value.status=="pending" && value.id!=() {return command_result(value.id);}
    value
}
fn node(record,sources) {
    if record==() || record.connections==() || record.connections["connectors:port"]==()
        || record.connections["connectors:port"].len()!=sources.len() {return false;}
    for source in sources {if !record.connections["connectors:port"].contains(source) {return false;}}
    true
}
fn on_start(me,ctx) {
    this.config=griffin_power_builder::configuration();this.model=sysml_requirements::model();
    this.names=griffin_spec::solar_array_names();this.net=find_path(ROOT);
    this.done=false;this.phase="parse";this.ticks=0;this.index=0;this.row=0;
    this.topology=true;this.area=true;this.law=true;this.balance=true;this.range=true;
    this.settled=true;this.complete=true;this.final=[];this.rates=[];this.areas=[];
    let sources=query("GeneratedModelicaSource",#{network_root:ROOT,include_source:false});
    if sources==() || sources.networks.len()!=1 {throw("exact generated power network unavailable");}
    let network=sources.networks[0];
    if network.projection_error!=() || network.components.len()!=20 {throw("closed twenty-member power network required");}
    this.class=network.model_name;this.inputs=#{};
    for name in network.boundary_inputs {
        let value=get(this.net,name);
        if value==() || !value.is_finite() {throw("physical Sun boundary unavailable: "+name);}
        this.inputs[name]=value;
    }
    for i in 0..this.names.len() {
        let pv=ROOT+"/"+this.names[i];let targets=[pv+"Heat.connectors:port",pv+"Cooler.connectors:port",
            pv+"SkyRadiation.connectors:port",pv+"GroundRadiation.connectors:port"];
        this.topology=this.topology && node(query("QueryUsdPrim",#{path:pv+"Mass",attrs:[],connections:true}),targets);
        let panel=query("QueryUsdPrim",#{path:pv,attrs:["parameters:area"]});
        let area=panel.attrs["parameters:area"];
        if area==() || area<=0.0 {throw("source collecting area unavailable");}
        this.areas.push(area);
        for boundary in [["SkyRadiation",this.config.sky_view_factor,this.config.sky_temperature,"sky"],
            ["GroundRadiation",this.config.ground_view_factor,this.config.ground_temperature,"ground"]] {
            let path=pv+boundary[0];
            let record=query("QueryUsdPrim",#{path:path,attrs:["parameters:area","parameters:emissivity","parameters:T_sink","parameters:sigma"]});
            this.area=this.area && abs(record.attrs["parameters:area"]-area*boundary[1])<this.config.area_tolerance
                && abs(record.attrs["parameters:emissivity"]-this.config.infrared_emissivity)<1.0e-12
                && abs(record.attrs["parameters:T_sink"]-boundary[2])<this.config.temperature_tolerance
                && record.attrs["parameters:sigma"]==this.config.radiation_constant;
            let declarations=[];
            for candidate in network.members {if candidate.prim==path {declarations.push(candidate);}}
            this.topology=this.topology && declarations.len()==1
                && declarations[0].class=="LunCo.Thermal.Radiator";
        }
    }
    // Use the projection owner's exact document and registry source check.
    if network.document_id==() || network.document_generation==()
        || network.document_source_matches!=true {throw("generated power document is not current");}
    this.doc=network.document_id;this.generation=network.document_generation;
}
fn finish_report(state) {
    let model=state.model;let constraint=PACKAGE+"GEP005_SustainedHeatRejection";
    let ir=sysml_requirements::required_constraint_ir(model,model.requirement(PACKAGE+"gep005"),constraint);
    let values=[["radiationTopologyClosed",state.topology],["emittingAreaMatches",state.area],
        ["radiativeLawMatches",state.law],["thermalBalanceClosed",state.balance],
        ["referenceRangeMaintained",state.range],["settledAtHorizon",state.settled],
        ["fullHorizonObserved",state.complete]];
    let observations=[];
    for pair in values {
        let observation=#{provider:"modelica",state:"value",value:pair[1],source_revision:model.source_revision,
            provider_generation:state.generation,document_id:state.doc.to_string(),document_generation:state.generation,
            sample_interval:#{clock:"experiment-sample/"+state.run,start_tick:0,end_tick:state.sample_intervals}};
        observations.push(sysml_requirements::scalar_constraint_observation(ir,pair[0],observation));
    }
    let check=sysml_requirements::required_constraints_check("GEP-005-sustained","griffin_sustained_thermal",
        "gep005",VERIFY,constraint,observations,"typed",0.0);
    let source=sysml_requirements::source_with_selection([],[PACKAGE+"gep005"],[PACKAGE+VERIFY]);
    let report=sysml_requirements::evaluate(source,[check]);
    report.metrics=#{experiment:state.run,source_cid:state.source_cid,held_inputs:state.inputs,
        duration_s:state.config.sustained_duration,output_interval_s:10.0,sample_intervals:state.sample_intervals,
        final_temperature_k:state.final,final_temperature_rate_k_per_s:state.rates,conditions:values};
    print("GRIFFIN_SUSTAINED_THERMAL_METRICS "+report.metrics);
    report_structured_verdict(report,"GRIFFIN SUSTAINED THERMAL","GRIFFIN_SUSTAINED_THERMAL");
    state.done=true;state
}
fn on_tick(me,ctx) {
    if this.done {return;}
    this.ticks+=1;if this.ticks>6000 {throw("sustained thermal experiment did not finish at "+this.phase);}
    if this.phase=="parse" {
        let compile=query("CompileStatus",#{doc_id:this.doc});
        if compile.state=="error" {throw("thermal witness parse failed: "+compile);}
        if compile.ast_parsed!=true {return;}
        let current=query("GeneratedModelicaSource",#{network_root:ROOT,include_source:false}).networks;
        if current.len()!=1 || current[0].document_id!=this.doc
            || current[0].document_generation!=this.generation || current[0].document_source_matches!=true {
            throw("generated power document changed before experiment admission");
        }
        this.pending=cmd("RunModelicaSolve",#{doc_id:this.doc,class:this.class,source_generation:this.generation,
            inputs:this.inputs,t_start:0.0,t_end:this.config.sustained_duration,dt:10.0,
            tolerance:1.0e-8,label:"Griffin exact radiative network one hour"});
        this.phase="dispatch";return;
    }
    if this.phase=="dispatch" {
        let result=ack(this.pending);if result==() || result.status=="pending" {return;}
        if result.ok!=true || result.data.experiment_id==() {throw("thermal experiment rejected: "+result);}
        this.run=result.data.experiment_id;this.phase="run";
    }
    if this.phase=="run" {
        let status=query("RunStatus",#{experiment_id:this.run});
        if status.state=="failed" || status.state=="cancelled" {throw("thermal experiment failed: "+status);}
        if status.state!="done" {return;}
        let current=query("GeneratedModelicaSource",#{network_root:ROOT,include_source:false}).networks;
        if current.len()!=1 || current[0].document_id!=this.doc
            || current[0].document_generation!=this.generation || current[0].document_source_matches!=true {
            throw("generated power document changed during experiment");
        }
        this.source_cid=status.source_cid;this.phase="read";
    }
    if this.phase=="read" {
        let name=this.names[this.index];let prefix=name+"_";
        this.variables=[prefix+"temperature_k",prefix+"heat_w",prefix+"cooler_heat_rejection_w",
            prefix+"SkyRadiation_heat_rejection_w",prefix+"GroundRadiation_heat_rejection_w",
            prefix+"mass_heat_flow_w"];
        let result=query("GetExperimentResult",#{experiment_id:this.run,variables:this.variables,max_points:4000});
        let intervals=(this.config.sustained_duration/10.0).to_int();
        if result.times==() || result.times.len()<intervals+1 || result.downsampled || !result.missing_variables.is_empty()
            || result.times[0]!=0.0 || abs(result.times[result.times.len()-1]-this.config.sustained_duration)>1.0e-8 {
            throw("complete sustained thermal trajectory required");
        }
        // Event localization may add before/after rows between regular grid
        // points. Check all returned rows and require every requested point.
        let grid=0;let previous=0.0;
        for time in result.times {
            this.complete=this.complete && time.is_finite() && time>=previous
                && time>=0.0 && time<=this.config.sustained_duration;
            if grid<=intervals && abs(time-10.0*grid)<=1.0e-8 {grid+=1;}
            previous=time;
        }
        this.complete=this.complete && grid==intervals+1;
        this.sample_intervals=result.times.len()-1;
        for variable in this.variables {
            if result.series[variable]==() || result.series[variable].len()!=result.times.len() {
                throw("complete thermal variable required: "+variable);
            }
        }
        this.series=result.series;this.rows=result.times.len();this.row=0;this.phase="check";
    }
    if this.phase=="check" {
        let s=this.series;let v=this.variables;let c=this.config;let area=this.areas[this.index];
        let end=min(this.rows,this.row+40);
        for row in this.row..end {
            for variable in v {if !s[variable][row].is_finite() {throw("nonfinite thermal trajectory");}}
            let t=s[v[0]][row];let heat=s[v[1]][row];let cooling=s[v[2]][row];
            let sky=s[v[3]][row];let ground=s[v[4]][row];let flow=s[v[5]][row];
            let expected_sky=c.infrared_emissivity*area*c.sky_view_factor*c.radiation_constant*(t**4-c.sky_temperature**4);
            let expected_ground=c.infrared_emissivity*area*c.ground_view_factor*c.radiation_constant*(t**4-c.ground_temperature**4);
            this.law=this.law && abs(sky-expected_sky)<=c.power_tolerance
                && abs(ground-expected_ground)<=c.power_tolerance;
            this.balance=this.balance && abs(flow-heat+cooling+sky+ground)<=c.power_tolerance;
            this.range=this.range && t>=c.reference_temperature-c.temperature_tolerance && t<=c.maximum_temperature;
        }
        this.row=end;if this.row<this.rows {return;}
        let final=this.rows-1;let rate=s[v[5]][final]/c.heat_capacity;
        this.final.push(s[v[0]][final]);this.rates.push(rate);
        this.settled=this.settled && abs(rate)<=c.settling_rate;
        this.index+=1;
        if this.index<this.names.len() {this.phase="read";return;}
        this=finish_report(this);
    }
}
