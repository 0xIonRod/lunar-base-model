import "lunco://scripting/tools/sysml_requirements" as requirements;
const STUDY="GriffinSolarRequirements::GriffinSolarCollisionStudy::";
fn simulation_dependencies(me,ctx){
    let reads=[];for panel in 0..3{for side in ["Top","Bottom"]{reads.push(find_path("/World/Panel"+panel.to_string()+"/Probe"+side));}reads.push(find_path("/World/Panel"+panel.to_string()+"/OpeningProbe"));}
    #{modelica_entities:[],entity_reads:reads,entity_writes:[],query_reads:["QueryUsdPrim","QueryPhysicsState","AnalyzeSysml"],required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_name()}]}
}
fn on_start(me,ctx){
    let model=requirements::model();this.duration=model.value(STUDY+"observationS");this.minimum_travel=model.value(STUDY+"minimumProbeTravelM");
    this.started=elapsed_seconds();this.done=false;this.probes=[];this.openings=[];this.radius=model.value(STUDY+"probeRadiusM");
    for panel in 0..3{
        let root="/World/Panel"+panel.to_string();let plate=query("QueryUsdPrim",#{path:root+"/ArrayBackplane",attrs:[],geometry_bounds:true});
        if plate.geometry_bounds==(){throw("Panel backplane geometry unavailable");}
        for side in ["Top","Bottom"]{
            let path=root+"/Probe"+side;let sign=if side=="Top"{1.0}else{-1.0};
            let body=query("QueryUsdPrim",#{path:path,attrs:[]});
            if body.spawned!=true || body.world_position==(){throw("Contact probe not admitted: "+path);}
            this.probes.push(#{path:path,sign:sign,plane:plate.geometry_bounds.center[1],start_y:body.world_position[1],minimum_gap:(),maximum_travel:0.0});
        }
        this.openings.push(#{path:root+"/OpeningProbe",plane:plate.geometry_bounds.center[1],minimum_gap:()});
    }
}
fn on_tick(me,ctx){
    if this.done{return;}
    for i in 0..this.probes.len(){
        let probe=this.probes[i];let record=query("QueryUsdPrim",#{path:probe.path,attrs:[]});
        if record.spawned!=true || record.world_position==(){throw("Contact probe disappeared");}
        let gap=probe.sign*(record.world_position[1]-probe.plane);
        probe.minimum_gap=if probe.minimum_gap==(){gap}else{min(probe.minimum_gap,gap)};
        probe.maximum_travel=max(probe.maximum_travel,probe.sign*(probe.start_y-record.world_position[1]));this.probes[i]=probe;
    }
    for i in 0..this.openings.len(){
        let probe=this.openings[i];let record=query("QueryUsdPrim",#{path:probe.path,attrs:[]});
        if record.spawned!=true || record.world_position==(){throw("Opening probe disappeared");}
        let gap=record.world_position[1]-probe.plane;probe.minimum_gap=if probe.minimum_gap==(){gap}else{min(probe.minimum_gap,gap)};this.openings[i]=probe;
    }
    if elapsed_seconds()-this.started<this.duration{return;}
    let checks=[];
    for probe in this.probes{
        checks.push(t_true(probe.maximum_travel>=this.minimum_travel,probe.path+": moved toward the panel under native physics"));
        checks.push(t_true(probe.minimum_gap>=0.0,probe.path+": cannot cross the actual backplane plane; minimum signed centre gap "+probe.minimum_gap.to_string()+" m"));
    }
    for probe in this.openings{checks.push(t_true(probe.minimum_gap < -this.radius,probe.path+": the leg opening or equipment recess stays physically open"));}
    print("GRIFFIN_SOLAR_CONTACT_SAMPLES "+this.probes.to_string());this.done=true;
    report_verdict(checks,"GRIFFIN SOLAR COLLISION","GRIFFIN_SOLAR_COLLISION");
}
