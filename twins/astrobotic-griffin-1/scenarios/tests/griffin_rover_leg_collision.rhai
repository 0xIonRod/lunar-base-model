// Real FLIP contact with the landed Griffin's structural landing gear.
// The fixture points the authored wheel rolling axis (+X with Z axles)
// toward the PX leg; the avatar supplies its normal drive controller.
const TEST_KIND="headless";
const ROOT="/Griffin1SurfaceOps";
fn simulation_dependencies(me,ctx) {
    #{modelica_entities:[find_path(ROOT+"/Lander"),find_path(ROOT+"/FLIP")],
      entity_reads:[],entity_writes:[],query_reads:["QueryUsdPrim","QueryPhysicsState","TerrainHeight","Raycast"],required_inputs:[]}
}
fn on_start(me,ctx) {
    this.rover=find_path(ROOT+"/FLIP");this.start_tick=sim_tick();
    this.checks=[];this.done=false;this.started=false;this.hit=false;this.baseline_contacts=0;
    this.minimum_separation=100.0;this.maximum_speed=0.0;this.maximum_demand=0.0;
    this.checks.push(t_true(cmd("AcquireControl",#{source:find_path(ROOT+"/Avatar"),target:this.rover,bind_camera:false}).ok,
        "FLIP manual control is acquired"));
    for suffix in ["PX","NX","PZ","NZ"] {
        let leg=ROOT+"/Lander/Leg"+suffix;let mount=leg+"_BusMount";
        let sources=[leg+"/LandingLegVisual/StrutOuter",leg+"/LandingLegVisual/StrutInner",
            leg+"/LandingLegVisual/FootPadPlate",leg+"/ShockPiston/Tube",
            mount+"/BodyMountArm",mount+"/MountAxle",mount+"/MountClevisOuter",
            mount+"/MountClevisInner",mount+"/ShockBarrel/Tube"];
        for source in sources {
            let attributes=["radius","height","axis","size","xformOpOrder",
                "xformOp:translate","xformOp:rotateXYZ","xformOp:scale",
                "physics:collisionEnabled","purpose","visibility"];
            let visible=query("QueryUsdPrim",#{path:source,attrs:attributes});
            let proxy=query("QueryUsdPrim",#{path:source+"Collider",collision_geometry:true,
                attrs:attributes,relationships:true});
            let matches=assembly_builder::query_ok(visible) && assembly_builder::query_ok(proxy)
                && visible.type_name==proxy.type_name && proxy.collision_geometry!=()
                && visible.attrs["xformOpOrder"]==proxy.attrs["xformOpOrder"];
            for name in ["radius","height","axis","size"] {
                if visible.attrs[name]!=() {matches=matches && visible.attrs[name]==proxy.attrs[name];}
            }
            for name in visible.attrs["xformOpOrder"] {
                matches=matches && visible.attrs[name]==proxy.attrs[name];
            }
            this.checks.push(t_true(matches
                && proxy.attrs["physics:collisionEnabled"]==true
                && proxy.attrs.purpose=="proxy" && proxy.attrs.visibility=="invisible"
                && proxy.relationships["lunco:collider:geometrySource"]==[source],
                source+": hidden collider follows its composed geometry source"));
        }
    }
}
fn on_tick(me,ctx) {
    if this.done {return;}
    let elapsed=sim_tick()-this.start_tick;
    let leg=find_path(ROOT+"/Lander/LegPX");
    if elapsed<180 {return;}
    if !this.started {
        this.started=true;
        this.baseline_contacts=contact_debug(leg).touching_pair_count;
        this.start_position=world_pos3(this.rover);
        this.checks.push(t_true(griffin_controls::release_rover_brake().ok,
            "the parking brake is released before the drive"));
        this.checks.push(t_true(cmd("SimulateIntent",#{target:this.rover,intent:"forward",held:true}).ok,
            "FLIP drives forward toward the PX landing leg"));
    }
    let pose=world_pos3(this.rover);let leg_pose=world_pos3(leg);
    let separation=(pose.x-leg_pose.x+pose.z-leg_pose.z)/sqrt(2.0);
    this.minimum_separation=min(this.minimum_separation,separation);
    this.maximum_speed=max(this.maximum_speed,vlen(velocity(this.rover)));
    this.maximum_demand=max(this.maximum_demand,get(this.rover,"drive_left"));
    let contacts=contact_debug(leg);
    if contacts.touching_pair_count>this.baseline_contacts {this.hit=true;}
    if elapsed<900 {return;}
    this.done=true;
    cmd("SimulateIntent",#{target:this.rover,intent:"forward",held:false});
    this.checks.push(t_true(this.maximum_speed>0.1 && this.maximum_demand>0.1 && vlen(pose-this.start_position)>0.25,
        "the rover physically advances under its normal drive controller"));
    this.checks.push(t_true(this.hit,"the PX leg gains a physical contact with the rover"));
    this.checks.push(t_true(this.minimum_separation>0.0,
        "the rover cannot cross through the landing leg while driving into it"));
    print("GRIFFIN ROVER LEG CONTACT "+#{contact_observed:this.hit,baseline_contacts:this.baseline_contacts,
        minimum_separation_m:this.minimum_separation,maximum_speed_mps:this.maximum_speed,maximum_drive_demand:this.maximum_demand,
        rover:vec3_array(pose),leg:vec3_array(leg_pose)});
    report_verdict(this.checks,"Griffin rover landing-leg collision","GRIFFIN_ROVER_LEG_COLLISION");
}
