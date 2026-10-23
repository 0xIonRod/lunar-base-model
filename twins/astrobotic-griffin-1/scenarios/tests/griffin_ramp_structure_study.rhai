// Read-only Editor structure study. Explicit handles/target coverage are
// supplied by the authoring owner; this is not a full GVA or loaded verdict.
import "../../tools/griffin_ramp_packaging_checks.rhai" as observation;
import "../../tools/griffin_ramp_root_bearing_fit.rhai" as mating;
fn simulation_dependencies(me,ctx){#{modelica_entities:[],entity_reads:[],entity_writes:[],query_reads:["AnalyzeSysml","QueryUsdPrim","QueryUsdPrims","ReadActiveTwinContract"],required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_name()}]}}
fn on_start(me,ctx){
    if ctx.mode!="probe" && ctx.mode!="full"{throw("Select explicit probe or full coverage");}
    if !array_is(ctx.sections) || ctx.sections.len()==0{throw("Explicit section coverage is required");}
    let seen=[];for section in ctx.sections{if section<0 || section>2 || seen.contains(section){throw("Invalid or repeated section coverage");}seen.push(section);}
    if ctx.fixed_paths.len()==0{throw("Structure target coverage is required");}
    this.state=observation::begin(ctx.fixture_doc,ctx.source_docs);this.state.required=0.0;
    this.state.targets=[];this.stage="capture";this.capture=0;this.verify=0;this.target_index=0;
    this.bank=0;this.phase=0;this.position=0;this.section_position=0;this.count=0;this.minimum=();this.witness=();this.done=false;this.mating_index=0;this.root_mates=[[],[]];
    this.indices=[];
    for p in 0..this.state.phases.len(){let n=this.state.phases[p].intervals;let indices=[];
        if ctx.mode=="probe"{if p==3{indices=[0,n/4,n/2,n*3/4,n];}else{indices=[0,n/2,n];}}
        this.indices.push(indices);
    }
    print("GRIFFIN_STRUCTURE_STUDY_STARTED actor="+me.to_string()+" mode="+ctx.mode);
}
fn tick_study(me,ctx){
    observation::assert_current(this.state);
    if this.stage=="capture"{this.state=observation::add_section(this.state,this.capture);this.capture+=1;if this.capture==3{this.stage="verify";}return;}
    if this.stage=="verify"{
        let r=observation::verify_installation(this.state,this.verify/3,this.verify%3);
        print("GRIFFIN_STRUCTURE_REFERENCE "+r.to_string());this.verify+=1;if this.verify==6{this.stage=if ctx.sections.contains(0){"mating"}else{"targets"};}return;
    }
    if this.stage=="mating"{
        let bank=this.mating_index/2;let station=this.mating_index%2;
        let r=mating::inspect(this.state.doc,ctx.source_docs.root,ctx.bearing_doc,bank,station);
        if !r.passes || r.document_generation!=this.state.fence.document_generation || r.stage_generation!=this.state.fence.stage_generation{throw("Root mating prerequisite is not qualified in this snapshot");}
        for path in r.target_paths{this.root_mates[bank].push(path);}
        print("GRIFFIN_STRUCTURE_ROOT_MATING "+r.to_string());this.mating_index+=1;if this.mating_index==4{this.stage="targets";}return;
    }
    if this.stage=="targets"{
        let paths=[];for i in this.target_index..min(this.target_index+20,ctx.fixed_paths.len()){paths.push(ctx.fixed_paths[i]);}
        let found=query("QueryUsdPrims",#{doc_id:this.state.doc,paths:paths,geometry_bounds:true,attrs:[]});
        for part in found.records{let b=part.geometry_bounds;
            if b==() || b.frame!="canonical_stage" || part.document_generation!=this.state.fence.document_generation || part.stage_generation!=this.state.fence.stage_generation{throw("Target snapshot is missing or changed");}
            this.state.targets.push(#{path:part.path,box:oriented_bounds3(vec3_from(b.center),vec3_from(b.half_extents),quat_identity())});
        }
        if found.records.len()!=paths.len(){throw("Fixed target coverage is incomplete");}
        this.target_index+=paths.len();if this.target_index==ctx.fixed_paths.len(){this.stage="observe";}return;
    }
    let section=ctx.sections[this.section_position];let current=this.state;
    if section==0{let selected=[];for target in current.targets{if !this.root_mates[this.bank].contains(target.path){selected.push(target);}}current.targets=selected;}
    let sample_index=if ctx.mode=="full"{this.position}else{this.indices[this.phase][this.position]};
    let r=observation::sample(current,this.bank,this.phase,sample_index,section);this.count+=1;
    if this.minimum==() || r.minimum_certified_gap_m<this.minimum{this.minimum=r.minimum_certified_gap_m;this.witness=r;}
    if !r.passes{this.done=true;print("GRIFFIN_STRUCTURE_STUDY_UNCERTAIN "+#{mode:ctx.mode,count:this.count,observation:r,
        doc_id:this.state.doc,document_generation:this.state.fence.document_generation,stage_generation:this.state.fence.stage_generation,
        scope:"Conservative envelope uncertainty; not proof of solid intersection"}.to_string());return;}
    this.section_position+=1;if this.section_position==ctx.sections.len(){this.section_position=0;this.position+=1;
        let sample_count=if ctx.mode=="full"{this.state.phases[this.phase].intervals+1}else{this.indices[this.phase].len()};
        if this.position==sample_count{this.position=0;this.phase+=1;
            if this.phase==this.state.phases.len(){this.phase=0;this.bank+=1;}
        }
    }
    if this.count%400==0{print("GRIFFIN_STRUCTURE_STUDY_PROGRESS "+this.count.to_string());}
    if this.bank==2{this.done=true;observation::assert_current(this.state);print("GRIFFIN_STRUCTURE_STUDY_DONE "+#{mode:ctx.mode,
        observations:this.count,fixed_targets:this.state.targets.len(),sections:ctx.sections,root_mating_targets:this.root_mates,minimum_certified_gap_m:this.minimum,witness:this.witness,
        doc_id:this.state.doc,document_generation:this.state.fence.document_generation,stage_generation:this.state.fence.stage_generation,
        source_revision:this.state.source_revision,scope:"Selected sections versus measured fixed structures; root mating certified separately; unmeasured NURBS and other moving interfaces remain unaccepted"}.to_string());}
}
fn on_tick(me,ctx){if this.done{return;}try{this.tick_study(me,ctx);}catch(error){this.done=true;print("GRIFFIN_STRUCTURE_STUDY_ERROR "+error.to_string());}}
