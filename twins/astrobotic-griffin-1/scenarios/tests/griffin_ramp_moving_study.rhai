// Source geometry study; native loaded deployment remains a separate gate.
import "twin://astrobotic-griffin-1/tools/griffin_ramp_packaging_checks.rhai" as observation;
import "twin://astrobotic-griffin-1/tools/griffin_ramp_packaging.rhai" as packaging;
import "lunco://scripting/tools/sysml_requirements" as requirements;
fn simulation_dependencies(me,ctx){#{modelica_entities:[],entity_reads:[],entity_writes:[],query_reads:["AnalyzeSysml","QueryUsdPrim","QueryUsdPrims","ReadActiveTwinContract"],required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_name()}]}}
fn on_start(me,ctx){
    if ctx.mode!="probe" && ctx.mode!="full"{throw("Choose explicit moving-path coverage");}
    this.state=observation::begin(ctx.fixture_doc,ctx.source_docs);
    this.state.required=requirements::model().value(packaging::owner()+"nonAdjacentClearanceM");
    this.stage="capture";this.capture=0;this.verify=0;this.phase=0;this.index=0;this.pair=0;this.count=0;this.minimum=();this.witness=();this.done=false;
    this.sweep_index=0;this.sweeps=[];this.cross_checks=0;this.cross_minimum=();this.last_refined=0;
    this.pairs=[[0,0,0,2],[1,0,1,2]];
    print("GRIFFIN_MOVING_STUDY_STARTED actor="+me.to_string()+" mode="+ctx.mode);
}
fn tick_study(me,ctx){
    observation::assert_current(this.state);
    if this.stage=="capture"{this.state=observation::add_section(this.state,this.capture);this.capture+=1;if this.capture==3{this.stage="verify";}return;}
    if this.stage=="verify"{let r=observation::verify_installation(this.state,this.verify/3,this.verify%3);print("GRIFFIN_MOVING_REFERENCE "+r.to_string());this.verify+=1;if this.verify==6{this.stage="sweeps";}return;}
    if this.stage=="sweeps"{
        let r=observation::independent_sweep(this.state,this.sweep_index/3,this.sweep_index%3);
        r.native_corner_cross_checks=observation::check_sweep_samples(this.state,this.sweep_index/3,this.sweep_index%3,r);
        this.sweeps.push(r);print("GRIFFIN_INDEPENDENT_SWEEP "+r.to_string());
        this.sweep_index+=1;if this.sweep_index==6{this.stage="cross";}return;
    }
    if this.stage=="cross"{
        for a in 0..3{for b in 0..3{
            let left=this.sweeps[a].interval;let right=this.sweeps[3+b].interval;
            let gap=max(left[0]-right[1],right[0]-left[1]);this.cross_checks+=1;
            if this.cross_minimum==() || gap<this.cross_minimum{this.cross_minimum=gap;}
            if gap<this.state.required{throw("Independent cross-bank swept envelopes do not establish required separation");}
        }}
        this.stage="observe";return;
    }
    let selected=this.pairs[this.pair];let phase=this.state.phases[this.phase];
    let rigid=phase.moving==0;
    let sample_index=if rigid{0}else if ctx.mode=="full"{this.index}else{[0,phase.intervals/4,phase.intervals/2,phase.intervals*3/4,phase.intervals][this.index]};
    // A root-only phase is one common rigid transform. The relative
    // geometry and gap are invariant; the observer's displacement is zero.
    let r=observation::moving_sample(this.state,selected[0],selected[1],selected[2],selected[3],this.phase,sample_index);
    this.last_refined=r.refined_pairs;
    this.count+=1;
    if this.minimum==() || r.minimum_certified_gap_m<this.minimum{this.minimum=r.minimum_certified_gap_m;this.witness=r;}
    if !r.passes{this.done=true;report_structured_verdict(#{ok:false,verdict:"inconclusive",check_count:this.count,inconclusive_count:1,non_pass_count:1,
        non_pass_results:[#{id:"moving-clearance",verdict:"inconclusive",error:"Measured bounding envelopes do not establish the required gap",observation:r}],
        metrics:#{mode:ctx.mode,scope:"Planned source path; no solid collision or loaded outcome is inferred"}},"GRIFFIN MOVING RAMP STUDY","GRIFFIN_RAMP_MOVING_STUDY");return;}
    this.pair+=1;
    if this.pair==this.pairs.len(){this.pair=0;this.index+=1;
        if rigid || (ctx.mode=="full" && this.index>phase.intervals) || (ctx.mode=="probe" && this.index==5){this.index=0;this.phase+=1;}
    }
    if this.count%500==0{print("GRIFFIN_MOVING_PROGRESS count="+this.count.to_string());}
    if this.phase==this.state.phases.len(){this.done=true;report_structured_verdict(#{ok:true,verdict:"pass",check_count:this.count+this.cross_checks,pass_count:this.count+this.cross_checks,
        source_revision:this.state.source_revision,metrics:#{mode:ctx.mode,minimum_certified_gap_m:this.minimum,witness:this.witness,
            cross_bank_minimum_certified_gap_m:this.cross_minimum,independent_sweeps:this.sweeps,
            scope:"Continuous own-bank root/toe gap and independent full-path cross-bank swept separation; loaded motion remains unaccepted",doc_id:this.state.doc,
            document_generation:this.state.fence.document_generation,stage_generation:this.state.fence.stage_generation}},
        "GRIFFIN MOVING RAMP STUDY","GRIFFIN_RAMP_MOVING_STUDY");}
}
fn on_tick(me,ctx){
    if this.done{return;}
    try{
        // A stock-refined sample consumes its own callback. Small broad-phase
        // observations share a bounded batch, preserving the normal op ceiling.
        for batch in 0..8{this.tick_study(me,ctx);if this.done || this.stage!="observe" || this.last_refined>0{break;}}
    }catch(error){this.done=true;report_structured_verdict(#{ok:false,verdict:"error",error_count:1,non_pass_count:1,
        non_pass_results:[#{id:"moving-observation",verdict:"error",error:error.to_string()}]},"GRIFFIN MOVING RAMP STUDY","GRIFFIN_RAMP_MOVING_STUDY");}
}
