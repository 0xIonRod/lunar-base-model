// Read-only Editor study, with explicit document handles supplied by its owner.
// It does not accept the production vehicle or replace a SysML verification.
import "griffin_ramp_packaging_checks" as observation;
import "griffin_ramp_packaging" as packaging;
import "lunco://scripting/tools/sysml_requirements" as requirements;

fn simulation_dependencies(me,ctx){
    #{modelica_entities:[],entity_reads:[],entity_writes:[],
        query_reads:["AnalyzeSysml","QueryUsdPrim","QueryUsdPrims","ReadActiveTwinContract"],
        required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_name()}]}
}
fn on_start(me,ctx){
    this.done=false;this.stage="capture";this.capture=0;this.verify=0;
    this.state=observation::begin(ctx.fixture_doc,ctx.source_docs);
    this.banks=ctx.banks;
    if !array_is(this.banks) || this.banks.len()==0{throw("Study needs explicit bank coverage");}
    for bank in this.banks{if bank!=0 && bank!=1{throw("Invalid study bank");}}
    this.minimum=[(),()];this.witness=[(),()];this.counts=[0,0];
    this.mode=0;this.bank_index=0;this.phase=0;this.index=0;this.section=0;
}
fn tick_study(me,ctx){
    observation::assert_current(this.state);
    if this.stage=="capture"{
        this.state=observation::add_section(this.state,this.capture);this.capture+=1;
        if this.capture==3{this.stage="verify";}
        return;
    }
    if this.stage=="verify"{
        let bank=this.banks[this.verify/3];let section=this.verify%3;
        let found=observation::verify_installation(this.state,bank,section);
        print("GRIFFIN_INTERFACE_REFERENCE "+found.to_string());this.verify+=1;
        if this.verify==this.banks.len()*3{this.stage="targets";}
        return;
    }
    if this.stage=="targets"{
        this.targets=[this.state.targets,[]];let model=requirements::model();let lander=model.value(packaging::owner()+"landerPath");
        let paths=[];
        for side in ["Port","Starboard"]{for track in ["RampTrackPort","RampTrackStarboard"]{
            paths.push(lander+"/TransitionPlate"+side+"/"+track);
        }}
        let found=query("QueryUsdPrims",#{doc_id:this.state.doc,paths:paths,attrs:[],geometry_bounds:true});
        for part in found.records{
            let b=part.geometry_bounds;
            if part.type_name!="Cube" || b==() || b.frame!="canonical_stage"{throw("Study needs the measured fixed bridge solids");}
            this.targets[1].push(#{path:part.path,box:oriented_bounds3(vec3_from(b.center),vec3_from(b.half_extents),quat_identity())});
        }
        if this.targets[1].len()!=paths.len(){throw("Bridge coverage is incomplete");}
        this.stage="observe";return;
    }
    this.state.targets=this.targets[this.mode];
    this.state.required=if this.mode==0{requirements::model().value(packaging::owner()+"payloadClearanceM")}else{0.0};
    let r=observation::sample(this.state,this.banks[this.bank_index],this.phase,this.index,this.section);
    if this.minimum[this.mode]==() || r.minimum_certified_gap_m<this.minimum[this.mode]{
        this.minimum[this.mode]=r.minimum_certified_gap_m;this.witness[this.mode]=r;
    }
    this.counts[this.mode]+=1;
    if !r.passes{
        this.done=true;report_structured_verdict(#{ok:false,verdict:"fail",check_count:this.counts[0]+this.counts[1],
            pass_count:this.counts[0]+this.counts[1]-1,failure_count:1,non_pass_count:1,
            source_revision:this.state.source_revision,non_pass_results:[#{verdict:"fail",id:"native-clearance",error:r.to_string()}],
            metrics:#{scope:"Editor reconstruction study",failure:r,counts:this.counts,minimum:this.minimum}},
            "GRIFFIN RAMP INTERFACE STUDY","GRIFFIN_RAMP_INTERFACE_STUDY");return;
    }
    if this.counts[this.mode]%600==0{print("GRIFFIN_INTERFACE_PROGRESS mode="+this.mode.to_string()+" count="+this.counts[this.mode].to_string());}
    this.section+=1;
    if this.section==3{
        this.section=0;this.index+=1;
        if this.index>this.state.phases[this.phase].intervals{
            this.index=0;this.phase+=1;
            if this.phase==this.state.phases.len(){
                this.phase=0;this.bank_index+=1;
                if this.bank_index==this.banks.len(){this.bank_index=0;this.mode+=1;}
            }
        }
    }
    if this.mode==2{
        observation::assert_current(this.state);this.done=true;
        report_structured_verdict(#{ok:true,verdict:"pass",check_count:this.counts[0]+this.counts[1],pass_count:this.counts[0]+this.counts[1],
            source_revision:this.state.source_revision,
            metrics:#{scope:"Payload and bridge geometry only; other obstacles and loaded vehicle unaccepted",doc_id:this.state.doc,
            document_generation:this.state.fence.document_generation,stage_generation:this.state.fence.stage_generation,
            banks:this.banks,counts:this.counts,minimum:this.minimum,witness:this.witness,phases:this.state.phases}},
            "GRIFFIN RAMP INTERFACE STUDY","GRIFFIN_RAMP_INTERFACE_STUDY");
    }
}
fn on_tick(me,ctx){
    if this.done{return;}
    try{this.tick_study(me,ctx);}catch(error){
        this.done=true;report_structured_verdict(#{ok:false,verdict:"error",error_count:1,non_pass_count:1,
            source_revision:this.state.source_revision,
            non_pass_results:[#{verdict:"error",id:"study-observation",error:error.to_string()}],
            metrics:#{scope:"Editor reconstruction study"}},
            "GRIFFIN RAMP INTERFACE STUDY","GRIFFIN_RAMP_INTERFACE_STUDY");
    }
}
