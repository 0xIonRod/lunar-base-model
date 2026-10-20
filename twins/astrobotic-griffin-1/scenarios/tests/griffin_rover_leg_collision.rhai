// Real FLIP contact with the landed Griffin's structural landing gear.
// The fixture points the authored wheel rolling axis (+X with Z axles)
// toward the landing gear; the avatar supplies its normal drive controller.
// The Sun-oriented bus can present any named leg or its bus-owned mounting hardware.
const TEST_KIND="headless";
const ROOT="/Griffin1SurfaceOps";
fn simulation_dependencies(me,ctx) {
    #{modelica_entities:[find_path(ROOT+"/Lander"),find_path(ROOT+"/FLIP")],
      entity_reads:[find_path(ROOT+"/Lander"),find_path(ROOT+"/FLIP"),find_path(ROOT+"/Lander/LegPX"),find_path(ROOT+"/Lander/LegNX"),find_path(ROOT+"/Lander/LegPZ"),find_path(ROOT+"/Lander/LegNZ")],entity_writes:[],query_reads:["QueryUsdPrim","QueryPhysicsState","TerrainHeight","Raycast"],required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_name()}]}
}
fn on_start(me,ctx) {
    this.rover=find_path(ROOT+"/FLIP");this.start_tick=sim_tick();
    this.checks=[];this.done=false;this.started=false;this.hit=false;this.maximum_penetration=0.0;
    this.contact_tolerance=sysml_requirements::model().value("GriffinLandingLegRequirements::GriffinLandingLegAssembly::runtimeContactToleranceM");
    if this.contact_tolerance==() || this.contact_tolerance<=0.0 {throw("runtime contact tolerance unavailable");}
    this.proxy_owners=[];
    this.maximum_contact_impulse=0.0;this.hit_source="";this.maximum_speed=0.0;this.maximum_demand=0.0;
    for fixture in [#{path:ROOT+"/Lander",datum:"collisionBenchLanderStart"},
                    #{path:ROOT+"/FLIP",datum:"collisionBenchRoverStart"}] {
        let expected=assembly_builder::vector3(sysml_requirements::model().value(
            "GriffinLandingLegRequirements::GriffinLandingLegAssembly::"+fixture.datum),fixture.datum);
        let observed=query("QueryUsdPrim",#{path:fixture.path,attrs:["xformOp:translate"]});
        if !assembly_builder::query_ok(observed) || expected.ok!=true {
            throw("collision-bench authored start pose unavailable: "+fixture.path);
        }
        let actual=assembly_builder::vector3(observed.attrs["xformOp:translate"],fixture.path);
        this.checks.push(t_true(actual.ok==true && actual.value==expected.value,
            fixture.path+": authored start pose matches the terrain-clearance study datum"));
    }
    this.checks.push(t_true(cmd("AcquireControl",#{source:find_path(ROOT+"/Avatar"),target:this.rover,bind_camera:false}).ok,
        "FLIP manual control is acquired"));
    for suffix in ["PX","NX","PZ","NZ"] {
        let leg=ROOT+"/Lander/Leg"+suffix;let mount=leg+"_BusMount";
        let sources=[leg+"/LandingLegVisual/FootPad",leg+"/LandingLegVisual/StrutOuter",leg+"/LandingLegVisual/StrutInner",
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
            this.proxy_owners.push(#{path:source+"Collider",owner:if source.starts_with(mount+"/") {ROOT+"/Lander"} else {leg}});
            this.checks.push(t_true(matches
                && proxy.attrs["physics:collisionEnabled"]==true
                && proxy.attrs.purpose=="proxy" && proxy.attrs.visibility=="invisible"
                && proxy.relationships["lunco:derived:source"]==[source],
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
        this.checks.push(t_true(get(find_path(ROOT+"/Lander"),"all_legs_contact")>=0.5,
            "all four lander pads settle before the rover approach"));
        for proxy in this.proxy_owners {
            let body=query("QueryPhysicsState",#{id:find_path(proxy.owner)});
            this.checks.push(t_true(body.physics_state_ready==true && body.collider_present==true
                && body.collider_source_paths!=() && body.collider_source_paths.contains(proxy.path),
                proxy.path+": the intended live body actually admitted this collider"));
        }
        this.checks.push(t_true(contact_debug(leg,this.rover).touching_pair_count==0,
            "terrain contact is excluded from the rover pair query"));
        this.start_position=world_pos3(this.rover);
        this.checks.push(t_true(griffin_controls::release_rover_brake().ok,
            "the parking brake is released before the drive"));
        this.checks.push(t_true(cmd("SimulateIntent",#{target:this.rover,intent:"forward",held:true}).ok,
            "FLIP drives forward toward the landing gear"));
    }
    let pose=world_pos3(this.rover);let leg_pose=world_pos3(leg);
    this.maximum_speed=max(this.maximum_speed,vlen(velocity(this.rover)));
    this.maximum_demand=max(this.maximum_demand,get(this.rover,"drive_left"));
    // Body identity alone cannot identify landing gear: barrels and brackets
    // belong to the bus, while translating feet and pistons belong to a leg.
    // Require a source-derived structural proxy in the native part records.
    for suffix in ["", "/LegPX", "/LegNX", "/LegPZ", "/LegNZ"] {
        let sample=contact_debug(find_path(ROOT+"/Lander"+suffix),this.rover);
        if sample==() || sample.parts==() {throw("native landing-gear contact part identities unavailable");}
        this.maximum_penetration=max(this.maximum_penetration,sample.max_penetration);
        for part in sample.parts {
            for proxy in this.proxy_owners {
                if part.source1==proxy.path || part.source2==proxy.path {
                    if sample.touching_pair_count>0 {this.hit=true;}
                    if part.normal_impulse>this.maximum_contact_impulse {
                        this.maximum_contact_impulse=part.normal_impulse;this.hit_source=proxy.path;
                    }
                }
            }
        }
    }
    if elapsed<900 {return;}
    this.done=true;
    cmd("SimulateIntent",#{target:this.rover,intent:"forward",held:false});
    this.checks.push(t_true(this.maximum_speed>0.1 && this.maximum_demand>0.1 && vlen(pose-this.start_position)>0.25,
        "the rover physically advances under its normal drive controller"));
    this.checks.push(t_true(this.hit,"a source-derived landing-gear collider gains a physical contact with the rover"));
    this.checks.push(t_true(this.maximum_penetration<=this.contact_tolerance,
        "the rover's actual collision envelope does not penetrate the leg beyond the authored tolerance"));
    this.checks.push(t_true(this.maximum_contact_impulse>0.0,
        "an admitted structural landing-gear collider applies a physical collision impulse"));
    print("GRIFFIN ROVER LEG CONTACT "+#{contact_observed:this.hit,maximum_penetration_m:this.maximum_penetration,
        maximum_contact_impulse_ns:this.maximum_contact_impulse,collision_source:this.hit_source,final_velocity:velocity(this.rover),maximum_speed_mps:this.maximum_speed,maximum_drive_demand:this.maximum_demand,
        rover:vec3_array(pose),leg:vec3_array(leg_pose)});
    report_verdict(this.checks,"Griffin rover landing-leg collision","GRIFFIN_ROVER_LEG_COLLISION");
}
