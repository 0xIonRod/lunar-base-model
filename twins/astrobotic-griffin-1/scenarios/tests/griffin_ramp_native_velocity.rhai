// Check completed native hinge rates against the motion of the same coordinate.
// Run on the retained, settled middle-unfold failure cohort.
fn simulation_dependencies(me, ctx) {
    let ids=[];
    for name in griffin_spec::ramp_root_joint_names() {
        ids.push(find_path("/Griffin1SurfaceOps/Lander/"+name));
    }
    for name in griffin_spec::ramp_intermediate_joint_names() {
        ids.push(find_path("/Griffin1SurfaceOps/Lander/"+name));
    }
    #{modelica_entities:[],entity_reads:ids,entity_writes:[],
      query_reads:["ReadPortsBatch","AnalyzeSysml","ValidateSysml","ReadActiveTwinContract"],
      required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_name()}]}
}
fn on_start(me,ctx) {this.first=();this.previous=();this.sums=[];this.count=0;this.done=false;}
fn on_tick(me,ctx) {
    if this.done {return;}
    let current=griffin_surface_ops::physical_ramp_joint_evidence();
    if current.ok!=true {fail_fast("Native hinge sample unavailable","GRIFFIN NATIVE HINGE VELOCITY","GRIFFIN_NATIVE_HINGE_VELOCITY");this.done=true;return;}
    if this.first==() {
        this.first=current;this.previous=current;
        for hinge in current.hinges {this.sums.push(0.0);}
        return;
    }
    let elapsed=(current.sim_tick-this.previous.sim_tick).to_float()*clock_snapshot().simulation_dt_s;
    for i in 0..current.hinges.len() {
        this.sums[i]+=0.5*(this.previous.hinges[i].measured_angular_speed_rad_per_s
            +current.hinges[i].measured_angular_speed_rad_per_s)*elapsed;
    }
    this.previous=current;this.count+=1;
    if this.count<120 {return;}
    this.done=true;
    let duration=(current.sim_tick-this.first.sim_tick).to_float()*clock_snapshot().simulation_dt_s;
    let tolerance=griffin_spec::physical_ramp_hinge_settle_speed_tolerance_rad_per_s();
    let failures=[];
    for i in 0..current.hinges.len() {
        let hinge=current.hinges[i];
        let displacement=hinge.measured_angle_rad-this.first.hinges[i].measured_angle_rad;
        let observed_rate=displacement/duration;
        let native_rate=this.sums[i]/duration;
        let agrees=(observed_rate-native_rate).abs()<=tolerance;
        emit("GRIFFIN_NATIVE_HINGE_VELOCITY_EVIDENCE_RESULT",
            #{result_index:i,result:#{id:hinge.name,ok:agrees,duration_s:duration,
              coordinate_rate_rad_per_s:observed_rate,native_rate_rad_per_s:native_rate,
              tolerance_rad_per_s:tolerance}});
        failures.push(t_true(agrees,hinge.name+" completed velocity disagrees with coordinate motion"));
    }
    report_verdict(failures,"GRIFFIN NATIVE HINGE VELOCITY","GRIFFIN_NATIVE_HINGE_VELOCITY");
}
