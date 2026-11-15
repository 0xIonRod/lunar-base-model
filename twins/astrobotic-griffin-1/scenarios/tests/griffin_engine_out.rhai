// Engine-out stimulus/verdict for USD valve/chamber assemblies.
// Both valves consume the shared engine health input in one coupled network.
// With full command held, failing one engine must extinguish exactly that
// engine and its plume while the other six keep their thrust, so the cluster
// delivers six sevenths of its nominal thrust.
const FAILED_ENGINE = "Engine03";
const SETTLE_S = 2.0;
// Shared-tank pressure is unchanged by one closed engine, so the surviving
// engines keep their flow; 3% covers valve and chamber settling.
const CLUSTER_SHARE_TOLERANCE = 0.03;
// A commanded-closed valve decays exponentially (0.08 s response), so after
// the settle time the failed engine's plume is extinguished, not exactly zero:
// below this fraction of its nominal light it renders nothing.
const EXTINGUISHED_PLUME_FRACTION = 1.0e-9;

fn simulation_dependencies(me,ctx) {
    #{modelica_entities:[find_path("/World/Griffin1"),find_path("/World/Griffin1/MainPropulsion")],
      entity_reads:[],entity_writes:[],query_reads:["QueryUsdPrim","QueryUsdPrims"],required_inputs:[#{owner: "sysml.twin-analysis", identity: twin_source_identity()}]}
}

fn _threshold() {
    griffin_spec::_typed_model_number(
        "GriffinPropulsionRequirements::GriffinEngineControlStudy::extinguishedThrustThresholdN")
}

fn _engine_thrusts(main) {
    let thrusts=#{};
    for name in griffin_spec::main_engine_names() {
        thrusts[name]=get(main,griffin_spec::main_engine_port(name,"thrust_n"));
    }
    thrusts
}

fn topology_checks(main) {
    let checks=[];
    let network=query("QueryUsdPrim",#{path:main,attrs:[],rels:["collection:components:includes"]});
    let members=network.relationships["collection:components:includes"];
    for name in griffin_spec::main_engine_names() {
        let root=main+"/"+name;
        let fuel=root+"/FuelValve";let oxidizer=root+"/OxidizerValve";let chamber=root+"/Chamber";
        let snapshot=query("QueryUsdPrims",#{paths:[root,fuel,oxidizer,chamber],
            attrs:["info:sourceAsset","connectors:inlet","connectors:fuel_in","connectors:oxidizer_in",
                "inputs:flow_fraction_command","inputs:enabled","inputs:available_mass_kg"],
            connections:true,schemas:true});
        let records=#{};for record in snapshot.records {records[record.path]=record;}
        let f=records[fuel];let o=records[oxidizer];let c=records[chamber];let assembly=records[root];
        checks.push(t_true(f.attrs["info:sourceAsset"].ends_with("/PressureFedValve.mo")
            && o.attrs["info:sourceAsset"].ends_with("/PressureFedValve.mo")
            && c.attrs["info:sourceAsset"].ends_with("/PressureFedCombustionChamber.mo"),
            name+" must expose both valve models and its chamber in USD"));
        checks.push(t_true(f.connections["connectors:inlet"]==[main+"/FuelTank.connectors:outlet"]
            && o.connections["connectors:inlet"]==[main+"/OxidizerTank.connectors:outlet"]
            && c.connections["connectors:fuel_in"]==[fuel+".connectors:outlet"]
            && c.connections["connectors:oxidizer_in"]==[oxidizer+".connectors:outlet"],
            name+" must preserve the complete tank-valve-chamber fluid path"));
        let enabled=main+".inputs:"+griffin_spec::main_engine_port(name,"enabled");
        checks.push(t_true(f.connections["inputs:enabled"]==[enabled] && o.connections["inputs:enabled"]==[enabled]
            && f.connections["inputs:flow_fraction_command"]==[main+".inputs:flow_fraction_command"]
            && o.connections["inputs:flow_fraction_command"]==[main+".inputs:flow_fraction_command"]
            && f.connections["inputs:available_mass_kg"]==[main+"/FuelTank.outputs:mass_kg"]
            && o.connections["inputs:available_mass_kg"]==[main+"/OxidizerTank.outputs:mass_kg"],
            name+" must wire command, health and reservoir availability to both valves"));
        checks.push(t_true(members.contains(fuel) && members.contains(oxidizer) && members.contains(chamber)
            && !members.contains(root) && !assembly.api_schemas.contains("LunCoProgramAPI")
            && !assembly.api_schemas.contains("CollectionAPI:components")
            && assembly.attrs["info:sourceAsset"]==(),
            name+" must be an assembly whose parts share the parent solver"));
    }
    checks
}

fn on_start(me,ctx) {
    this.griffin=find_path("/World/Griffin1");
    this.main=find_path("/World/Griffin1/MainPropulsion");
    this.elapsed=0.0;this.phase="nominal";this.done=false;
    this.topology=topology_checks("/World/Griffin1/MainPropulsion");
    // This static propulsion bench is an authored command producer. Program
    // holds command guidance; selection alone does not take manual authority.
    let command=cmd("SetPorts",#{target:this.griffin,writes:[["guidance_throttle",1.0]]});
    this.command_ok=command.ok;
}

fn on_tick(me,ctx) {
    if this.done {return;}
    this.elapsed+=dt();
    if this.elapsed<SETTLE_S {return;}
    let threshold=_threshold();
    if this.phase=="nominal" {
        this.nominal=_engine_thrusts(this.main);
        this.nominal_total=griffin_spec::main_engine_total(this.main,"thrust_n");
        this.nominal_plume=get(this.main,"test_failed_plume_intensity");
        let failed=cmd("SetPorts",#{target:this.main,
            writes:[[griffin_spec::main_engine_port(FAILED_ENGINE,"enabled"),0.0]]});
        this.failure_ok=failed.ok;
        this.phase="failed";this.elapsed=0.0;
        return;
    }
    let after=_engine_thrusts(this.main);
    let total=griffin_spec::main_engine_total(this.main,"thrust_n");
    let count=griffin_spec::main_engine_names().len();
    let failures=this.topology;
    failures.push(t_true(this.command_ok,"full main-engine command was rejected"));
    failures.push(t_true(this.failure_ok,"engine failure input was rejected"));
    for name in griffin_spec::main_engine_names() {
        failures.push(t_true(this.nominal[name]!=() && this.nominal[name]>threshold,
            name+" did not burn before the failure: "+this.nominal[name]));
    }
    failures.push(t_true(this.nominal_plume!=() && this.nominal_plume>0.0,
        FAILED_ENGINE+" showed no plume before the failure"));
    failures.push(t_true(after[FAILED_ENGINE]!=() && after[FAILED_ENGINE]<threshold,
        FAILED_ENGINE+" kept thrust after failing: "+after[FAILED_ENGINE]));
    // Valve travel decays exponentially; combustion follows that physical
    // tail. Apply the same extinction fraction used for the optical tail.
    failures.push(t_true(get(this.main,griffin_spec::main_engine_port(FAILED_ENGINE,"activity"))
        <=EXTINGUISHED_PLUME_FRACTION,
        FAILED_ENGINE+" kept combustion activity after failing"));
    let failed_plume=get(this.main,"test_failed_plume_intensity");
    failures.push(t_true(failed_plume!=() && this.nominal_plume!=()
        && failed_plume<=this.nominal_plume*EXTINGUISHED_PLUME_FRACTION,
        FAILED_ENGINE+" kept a plume after failing"));
    for name in griffin_spec::main_engine_names() {
        if name==FAILED_ENGINE {continue;}
        failures.push(t_true(after[name]!=() && after[name]>threshold,
            name+" stopped when "+FAILED_ENGINE+" failed: "+after[name]));
    }
    let share=if this.nominal_total!=() && this.nominal_total>0.0 && total!=() {total/this.nominal_total} else {0.0};
    let expected=(count-1).to_float()/count.to_float();
    failures.push(t_true((share-expected).abs()<=CLUSTER_SHARE_TOLERANCE,
        "cluster thrust share after one engine-out was "+share+", expected "+expected));
    print("[griffin-engine-out] nominal="+this.nominal_total+" after="+total+" share="+share
        +" failed_thrust="+after[FAILED_ENGINE]+" plume="+this.nominal_plume
        +" -> "+failed_plume);
    this.done=true;report_verdict(failures,"GRIFFIN ENGINE OUT","GRIFFIN_ENGINE_OUT");
}
