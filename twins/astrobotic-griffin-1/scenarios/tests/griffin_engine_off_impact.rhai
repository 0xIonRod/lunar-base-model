// Engine-off startup drop through the production terrain and suspension.
const TEST_KIND="headless";
fn simulation_dependencies(me,ctx) {
    let deps=griffin_surface_ops::landing_stability_dependencies();
    deps.query_reads.push("TerrainHeight");
    deps.query_reads.push("TerrainHeights");
    deps
}
fn on_start(me,ctx) {
    this.geometry=griffin_visual_builder::physical_landing_leg_pad_geometry();
    if !this.geometry.ok {throw(this.geometry.error);}
    this.contact_tolerance=sysml_requirements::model().value("GriffinLandingLegRequirements::GriffinLandingLegAssembly::runtimeContactToleranceM");
    if this.contact_tolerance==() || this.contact_tolerance<=0.0 {throw("runtime contact tolerance unavailable");}
    this.start_tick=sim_tick();
    this.lander=find_path("/Griffin1SurfaceOps/Lander");
    this.checks=[];this.done=false;this.minimum_clearance=100.0;
    this.maximum_penetration=0.0;this.travel_error_tick=0;this.minimum_clearance_tick=0;
    this.maximum_travel_error=0.0;this.maximum_thrust=0.0;this.samples=0;
    let control=griffin_controls::control_lander();
    this.checks.push(t_true(control.ok==true,"pilot owns zero-throttle engine-off drop"));
    let invalid=assembly_builder::collision_proxy_plan((),"@root@","/missing","/missing");
    this.checks.push(t_true(invalid.ok==false && invalid.ops.len()==0,
        "invalid collider source is rejected before any document edit"));
}
fn on_tick(me,ctx) {
    if this.done {return;}
    let sample=griffin_surface_ops::landing_stability_sample();
    if !sample.ok {throw(sample.error);}
    this.maximum_thrust=max(this.maximum_thrust,sample.engine_thrust_n);
    for suffix in ["PX","NX","PZ","NZ"] {
        let path="/Griffin1SurfaceOps/Lander/Leg"+suffix;
        let leg=find_path(path);
        let q=world_rotation_quat(leg);
        let position=world_pos3(leg);
        let points=[];let xs=[];
        for h in [this.geometry.center_y_m-this.geometry.height_m/2.0,
            this.geometry.center_y_m+this.geometry.height_m/2.0] {
            let center=position+qrot(q,vec3(0.0,h,0.0));
            points.push(center);xs.push([center.x,center.z]);
            for i in 0..16 {
                let angle=i.to_float()*6.283185307179586/16.0;
                let point=position+qrot(q,vec3(this.geometry.radius_m*cos(angle),h,this.geometry.radius_m*sin(angle)));
                points.push(point);xs.push([point.x,point.z]);
            }
        }
        let grounds=query("TerrainHeights",#{points:xs});
        for i in 0..points.len() {
            if grounds[i].found!=true {throw("pad has no authoritative terrain sample");}
            let clearance=points[i].y-grounds[i].height;
            if clearance<this.minimum_clearance {
                this.minimum_clearance=clearance;this.minimum_clearance_tick=sim_tick();
            }
        }
        let contact=contact_debug(leg);
        if contact==() {throw("live leg contact facts unavailable");}
        this.maximum_penetration=max(this.maximum_penetration,contact.max_penetration);
        let displacement=get(this.lander,"leg_displacement_"+suffix.to_lower());
        if displacement==() {throw("suspension displacement unavailable");}
        let travel_error=max(this.geometry.spring_lower_limit_m-displacement,
            displacement-this.geometry.spring_upper_limit_m);
        if travel_error>this.maximum_travel_error {
            this.maximum_travel_error=travel_error;this.travel_error_tick=sim_tick();
        }
    }
    this.samples+=1;
    if sim_tick()-this.start_tick<1800 {return;}
    this.done=true;
    this.checks.push(t_true(this.samples>=1800 && this.maximum_thrust==0.0,
        "the complete drop runs with extinguished engines"));
    this.checks.push(t_true(this.minimum_clearance>=-this.contact_tolerance,
        "footpad rims and centers stay above terrain within the authored solver tolerance"));
    this.checks.push(t_true(this.maximum_penetration<=this.contact_tolerance,
        "native narrow-phase penetration stays within the authored solver tolerance"));
    this.checks.push(t_true(sample.all_legs_contact==1.0 && sample.leg_contacts==[1.0,1.0,1.0,1.0],
        "all four legs are in physical contact after settling"));
    this.checks.push(t_true(sample.ground_speed<=griffin_spec::landing_max_ground_speed_mps()
        && sample.angular_speed<=griffin_spec::landing_max_angular_speed_rad_per_sec(),
        "the engine-off lander settles within its authored landing speed limits"));
    this.checks.push(t_true(this.maximum_travel_error<=this.geometry.spring_pose_tolerance_m,
        "suspension respects its authored hard-stop travel within 1 mm tolerance"));
    this.checks.push(t_true(sample.position[1]-query("TerrainHeight",#{x:sample.position[0],z:sample.position[2]}).height>0.3,
        "the lander remains supported above its ground datum"));
    print("GRIFFIN ENGINE-OFF IMPACT "+#{minimum_clearance_m:this.minimum_clearance,
        maximum_travel_error_m:this.maximum_travel_error,maximum_thrust_n:this.maximum_thrust,
        maximum_penetration_m:this.maximum_penetration,travel_error_tick:this.travel_error_tick,minimum_clearance_tick:this.minimum_clearance_tick,
        final:sample});
    report_verdict(this.checks,"Griffin engine-off impact","GRIFFIN_ENGINE_OFF_IMPACT");
}
