// Separate the one-hour transient and bounded equilibrium questions over the
// exact USD-generated network and held public inputs. Both retain the real
// transient checkpoint; neither replays changing flight/terrain/attitude.
const ROOT="/Griffin1SurfaceOps/Lander/ElectricalPower";
const PACKAGE="GriffinPowerThermalRequirements::";

fn simulation_dependencies(me,ctx) {
    let net=find_path(ROOT);
    #{modelica_entities:[net],entity_reads:[net],entity_writes:[],
      query_reads:["GeneratedModelicaSource","QueryUsdPrim","CompileStatus","RunStatus",
        "GetExperimentResult","AnalyzeSysml","ReadActiveTwinContract"],
      required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_source_identity()}]}
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
    let authored=query("QueryUsdPrim",#{path:"/Griffin1SurfaceOps/SustainedThermal",attrs:["inputs:equilibrium_study"]});
    let equilibrium=authored.attrs["inputs:equilibrium_study"];
    if equilibrium!=true && equilibrium!=false {throw("Thermal observer requires an explicit equilibrium_study boolean");}
    this.equilibrium=equilibrium;
    this.duration=if equilibrium {this.config.equilibrium_duration}else{this.config.sustained_duration};
    this.requirement=if equilibrium {"gep006"}else{"gep005"};
    this.verification=if equilibrium {"Verify_GriffinEquilibriumThermal"}else{"Verify_GriffinSustainedThermal"};
    this.names=griffin_spec::solar_array_names();this.net=find_path(ROOT);
    this.done=false;this.phase="parse";this.ticks=0;this.index=0;this.row=0;
    this.topology=true;this.area=true;this.law=true;this.balance=true;this.range=true;
    this.settled_window=true;this.one_hour_settled_window=true;this.complete=true;
    this.final=[];this.rates=[];this.areas=[];this.cold_limited_rows=0;
    this.one_hour_temperature=[];this.one_hour_rates=[];this.one_hour_seen=[];
    this.window_max_rates=[];this.one_hour_window_max_rates=[];this.window_sample_counts=[];this.window_start_times=[];
    for name in this.names {this.one_hour_temperature.push(());this.one_hour_rates.push(());this.one_hour_seen.push(false);}
    let sources=query("GeneratedModelicaSource",#{network_root:ROOT,include_source:false});
    if sources==() || sources.networks.len()!=1 {throw("exact generated power network unavailable");}
    let network=sources.networks[0];
    let authored=query("QueryUsdPrim",#{path:ROOT,attrs:[],rels:["collection:components:includes"]});
    if authored==() || authored.relationships==() || authored.relationships["collection:components:includes"]==() {
        throw("authored power collection is required");
    }
    let expected=authored.relationships["collection:components:includes"];
    if network.projection_error!=() || network.members.len()!=expected.len() {throw("generated power members differ from the authored collection");}
    for member in network.members {if !expected.contains(member.prim) {throw("generated power member is not authored: "+member.prim);}}
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
// Include the preceding output point only when a window boundary falls
// between grid points, so the checked sampled window covers its full duration.
fn window_contains(times,row,start,end) {
    let time=times[row];
    if time>end+1.0e-8 {return false;}
    if time>=start-1.0e-8 {return true;}
    row+1<times.len() && times[row+1]>start+1.0e-8
}
fn finish_report(state) {
    let model=state.model;let requirement=PACKAGE+state.requirement;
    let values=[["radiationTopologyClosed",state.topology],["emittingAreaMatches",state.area],
        ["radiativeLawMatches",state.law],["thermalBalanceClosed",state.balance],
        ["coefficientRangeMaintained",state.range],["fullHorizonObserved",state.complete]];
    let constraints=[#{name:"GEP005_SustainedHeatRejection",values:values}];
    if state.equilibrium {
        constraints.push(#{name:"GEP006_StableRateWindow",values:[["settledWindowObserved",state.settled_window]]});
    }
    let checks=[];
    for specification in constraints {
        let constraint=PACKAGE+specification.name;
        let ir=sysml_requirements::required_constraint_ir(model,model.requirement(requirement),constraint);
        let observations=[];
        for pair in specification.values {
            let observation=#{provider:"modelica",state:"value",value:pair[1],source_revision:model.source_revision,
                provider_generation:state.generation,document_id:state.doc.to_string(),document_generation:state.generation,
                sample_interval:#{clock:"experiment-sample/"+state.run,start_tick:0,end_tick:state.sample_intervals}};
            observations.push(sysml_requirements::scalar_constraint_observation(ir,pair[0],observation));
        }
        checks.push(sysml_requirements::required_constraint_check(specification.name,"griffin_thermal_study",
            requirement,PACKAGE+state.verification,constraint,observations,"typed",0.0));
    }
    let selected=sysml_requirements::source_with_selection([],[requirement],[PACKAGE+state.verification]);
    let report=sysml_requirements::evaluate(selected,checks);
    report.metrics=#{experiment:state.run,source_cid:state.source_cid,held_inputs:state.inputs,
        equilibrium_study:state.equilibrium,duration_s:state.duration,output_interval_s:10.0,
        sample_intervals:state.sample_intervals,cold_reference_hold_rows:state.cold_limited_rows,
        transient_checkpoint_s:state.config.sustained_duration,
        one_hour_temperature_k:state.one_hour_temperature,one_hour_temperature_rate_k_per_s:state.one_hour_rates,
        one_hour_settled_window:state.one_hour_settled_window,
        final_temperature_k:state.final,final_temperature_rate_k_per_s:state.rates,
        settled_window:state.settled_window,minimum_settled_duration_s:state.config.settled_duration,
        maximum_settled_temperature_rate_k_per_s:state.config.settling_rate,
        settled_window_start_s:state.window_start_times,settled_window_sample_counts:state.window_sample_counts,
        settled_window_maximum_rate_k_per_s:state.window_max_rates,
        one_hour_window_maximum_rate_k_per_s:state.one_hour_window_max_rates,constraints:constraints};
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
            inputs:this.inputs,t_start:0.0,t_end:this.duration,dt:10.0,
            tolerance:1.0e-8,label:if this.equilibrium {"Griffin exact radiative network equilibrium window"}else{"Griffin exact radiative network one-hour transient"}});
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
            prefix+"mass_heat_flow_w",prefix+"curve_temperature_k",prefix+"curve_limited",prefix+"curve_in_range"];
        let result=query("GetExperimentResult",#{experiment_id:this.run,variables:this.variables,max_points:4000});
        let intervals=(this.duration/10.0).to_int();
        if result.times==() || result.times.len()<intervals+1 || result.downsampled || !result.missing_variables.is_empty()
            || result.times[0]!=0.0 || abs(result.times[result.times.len()-1]-this.duration)>1.0e-8 {
            throw("complete sustained thermal trajectory required");
        }
        // Event localization may add before/after rows between regular grid
        // points. Check all returned rows and require every requested point.
        let grid=0;let previous=0.0;
        for time in result.times {
            this.complete=this.complete && time.is_finite() && time>=previous
                && time>=0.0 && time<=this.duration;
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
        this.series=result.series;this.times=result.times;this.rows=result.times.len();this.row=0;
        this.window_max_rate=0.0;this.hour_window_max_rate=0.0;this.window_samples=0;this.hour_window_samples=0;
        this.window_first=();this.hour_window_first=();this.phase="check";
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
            let rate=flow/c.heat_capacity;let time=this.times[row];
            if abs(time-c.sustained_duration)<=1.0e-8 {
                this.one_hour_temperature[this.index]=t;this.one_hour_rates[this.index]=rate;
                this.one_hour_seen[this.index]=true;
            }
            if window_contains(this.times,row,this.duration-c.settled_duration,this.duration) {
                this.settled_window=this.settled_window && abs(rate)<=c.settling_rate;
                this.window_max_rate=max(this.window_max_rate,abs(rate));this.window_samples+=1;
                if this.window_first==() {this.window_first=time;}
            }
            if window_contains(this.times,row,c.sustained_duration-c.settled_duration,c.sustained_duration) {
                this.one_hour_settled_window=this.one_hour_settled_window && abs(rate)<=c.settling_rate;
                this.hour_window_max_rate=max(this.hour_window_max_rate,abs(rate));this.hour_window_samples+=1;
                if this.hour_window_first==() {this.hour_window_first=time;}
            }
            let curve=s[v[6]][row];let limited=s[v[7]][row];let in_range=s[v[8]][row];
            if limited>0.5 {this.cold_limited_rows+=1;}
            this.range=this.range && t>0.0 && t<=c.maximum_temperature
                && curve>=c.reference_temperature-c.temperature_tolerance && curve<=c.maximum_temperature
                && abs(curve-max(c.reference_temperature,t))<=c.temperature_tolerance
                && limited==(if t<c.reference_temperature {1.0}else{0.0})
                && in_range==(if t>=c.reference_temperature {1.0}else{0.0});
        }
        this.row=end;if this.row<this.rows {return;}
        let final=this.rows-1;let rate=s[v[5]][final]/c.heat_capacity;
        this.final.push(s[v[0]][final]);this.rates.push(rate);
        if !this.one_hour_seen[this.index] {throw("one-hour transient checkpoint is missing from the complete trajectory");}
        this.settled_window=this.settled_window && this.window_samples>=2
            && this.window_first!=() && this.window_first<=this.duration-c.settled_duration+1.0e-8;
        this.one_hour_settled_window=this.one_hour_settled_window && this.hour_window_samples>=2
            && this.hour_window_first!=() && this.hour_window_first<=c.sustained_duration-c.settled_duration+1.0e-8;
        this.window_max_rates.push(this.window_max_rate);this.one_hour_window_max_rates.push(this.hour_window_max_rate);
        this.window_sample_counts.push(this.window_samples);this.window_start_times.push(this.window_first);
        this.index+=1;
        if this.index<this.names.len() {this.phase="read";return;}
        this=finish_report(this);
    }
}
