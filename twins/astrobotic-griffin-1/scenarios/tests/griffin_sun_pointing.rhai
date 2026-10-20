// Production descent: acquire solar azimuth through RCS while preserving landing.
const ROOT = "/Griffin1SurfaceOps/Lander";
fn simulation_dependencies(me, params) {
    let plan=griffin_surface_ops::landing_stability_dependencies();
    plan.modelica_entities.push(find_path(ROOT+"/AttitudeReference"));
    plan.entity_reads.push(find_path(ROOT+"/AttitudeReference"));
    plan.entity_reads.push(find_path(ROOT+"/Environment"));
    plan
}
fn on_start(me, params) {
    this.done=false;this.start=sim_tick();this.samples=0;
    this.acquired=false;this.acquired_at_s=();this.first_error=();this.last_error=();
    this.max_tracking_error=0.0;this.heading_hold_s=0.0;this.max_heading_hold_s=0.0;
    this.manual=false;this.finite=true;this.minimum_upright=1.0;
    this.reference=find_path(ROOT+"/AttitudeReference");
    this.lander=find_path(ROOT);this.gnc=find_path(ROOT+"/GNC");
    let model=sysml_requirements::model();
    let base="GriffinSolarRequirements::GriffinDescentSunPointingStudy::";
    this.tolerance=model.value(base+"azimuthToleranceRad");
    this.acquisition_s=model.value(base+"acquisitionTimeS");
    this.hold_s=model.value(base+"minimumTrackingTimeS");
    this.timeout_s=model.value(base+"testTimeoutS");
    if this.tolerance==() || this.acquisition_s==() || this.hold_s==() || this.timeout_s==() {
        throw("Sun-pointing study acceptance parameters are unavailable");
    }
}
fn finish(state, contact) {
    print("GRIFFIN_SUN_POINTING_METRICS "+#{samples:state.samples,
        initial_error_rad:state.first_error,final_error_rad:state.last_error,
        maximum_tracking_error_rad:state.max_tracking_error,
        maximum_tracking_hold_s:state.max_heading_hold_s,minimum_upright:state.minimum_upright,
        acquired:state.acquired,acquisition_time_s:state.acquired_at_s,landing_handoff:contact});
    let model=sysml_requirements::model();
    let requirement=model.requirement("GriffinSolarRequirements::gsa011");
    let constraint="GriffinSolarRequirements::GSAC011_DescentSolarHeading";
    let ir=sysml_requirements::required_constraint_ir(model,requirement,constraint);
    let observations=[];
    for pair in [["telemetryFinite",state.finite],["automaticAuthority",!state.manual],
        ["acquisitionCompleted",state.acquired],["landingHandoff",contact],
        ["acquisitionTimeS",state.acquired_at_s],
        ["sampleCount",state.samples.to_float()],["initialHeadingErrorRad",state.first_error],
        ["maximumTrackingErrorRad",state.max_tracking_error],["trackingTimeS",state.max_heading_hold_s]] {
        let observation=#{provider:"telemetry",state:if pair[1]==() {"unavailable"} else {"value"},
            value:pair[1],source_revision:model.source_revision,provider_generation:sim_tick(),
            document_id:(),document_generation:(),
            sample_interval:#{clock:"simulation",start_tick:state.start,end_tick:sim_tick()}};
        observations.push(sysml_requirements::scalar_constraint_observation(ir,pair[0],observation));
    }
    for pair in [["azimuthToleranceRad","azimuthToleranceRad"],
        ["minimumTrackingTimeS","minimumTrackingTimeS"],["maximumAcquisitionTimeS","acquisitionTimeS"]] {
        let attribute=model.attribute("GriffinSolarRequirements::GriffinDescentSunPointingStudy::"+pair[1]);
        observations.push(sysml_requirements::scalar_constraint_observation(ir,pair[0],
            model.source_literal_observation(attribute)));
    }
    let check=sysml_requirements::required_constraints_check("GSA-011-descent-solar-heading",
        "lander","gsa011","Verify_GriffinDescentSunPointing",constraint,observations,"typed",0.0);
    let source=sysml_requirements::source_with_selection([], ["GriffinSolarRequirements::gsa011"],
        ["GriffinSolarRequirements::Verify_GriffinDescentSunPointing"]);
    report_structured_verdict(sysml_requirements::evaluate(source,[check]),
        "Griffin descent Sun pointing","GRIFFIN_SUN_POINTING");
}
fn on_tick(me, params) {
    if this.done {return;}
    let elapsed=(sim_tick()-this.start).to_float()*clock_snapshot().simulation_dt_s;
    let enabled=get(this.reference,"heading_enable");
    let error=get(this.reference,"heading_error_rad");
    let valid=get(this.reference,"heading_valid");
    let ready=get(this.reference,"heading_ready");
    let handoff=get(this.gnc,"landing_handoff");
    if enabled!=() && enabled>0.5 && valid!=() && valid>0.5 && error!=() {
        this.samples+=1;this.finite=this.finite && error.is_finite();
        if this.first_error==() {this.first_error=error;}
        this.last_error=error;
        this.manual=this.manual || get(this.lander,"piloted")>0.5;
        let upright=get(this.reference,"estimated_up_y");
        this.minimum_upright=if upright<this.minimum_upright {upright} else {this.minimum_upright};
        if abs(error)<=this.tolerance {
            this.heading_hold_s+=clock_snapshot().simulation_dt_s;
        } else {this.heading_hold_s=0.0;}
        if ready!=() && ready>0.5 && this.acquired_at_s==() {
            this.acquired_at_s=elapsed;
            this.acquired=elapsed<=this.acquisition_s;
        }
        if this.heading_hold_s>this.max_heading_hold_s {this.max_heading_hold_s=this.heading_hold_s;}
        if this.acquired && abs(error)>this.max_tracking_error {
            this.max_tracking_error=abs(error);
        }
    }
    if (sim_tick()-this.start)%300==0 {print("GRIFFIN_SUN_TRACK "+#{elapsed:elapsed,error:error,heading_enable:enabled,upright:get(this.reference,"estimated_up_y"),y:get(this.lander,"position_y")});}
    if handoff!=() && handoff>0.5 {this.done=true;finish(this,true);}
    else if elapsed>=this.timeout_s {this.done=true;finish(this,false);}
}
