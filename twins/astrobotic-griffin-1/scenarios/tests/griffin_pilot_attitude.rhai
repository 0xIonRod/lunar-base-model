// Production pilot regression: take off, tap the semantic pitch intent, then
// hold thrust while observing recovery. The engine study owns flight limits.
fn simulation_dependencies(me, ctx) {
    let deps = griffin_surface_ops::landing_stability_dependencies();
    deps.modelica_entities.push(find_path("/Griffin1SurfaceOps/Lander/AttitudePropulsion"));
    deps.entity_reads.push(find_path("/Griffin1SurfaceOps/Lander/AttitudePropulsion"));
    deps.entity_reads.push(find_path("/Griffin1SurfaceOps/FLIP"));
    for path in _force_actuator_paths() {deps.entity_reads.push(find_path(path));}
    for name in griffin_spec::ramp_root_joint_names() + griffin_spec::ramp_intermediate_joint_names() {
        deps.entity_reads.push(find_path("/Griffin1SurfaceOps/Lander/" + name));
    }
    deps.query_reads.push("ReadPortsBatch");
    deps.query_reads.push("QueryUsdPrims");
    deps.query_reads.push("QueryEntity");
    deps.entity_writes = [find_path("/Griffin1SurfaceOps/Lander"),
        find_path("/Griffin1SurfaceOps/Lander/GNC")];
    if ctx["isolate_leg_joints"] == true {
        for path in _leg_joint_paths() {
            deps.entity_reads.push(find_path(path));
            deps.entity_writes.push(find_path(path));
        }
        for name in griffin_spec::landing_leg_names() {
            let body=find_path("/Griffin1SurfaceOps/Lander/"+name);
            deps.entity_reads.push(body);deps.entity_writes.push(body);
        }
    }
    if ctx["isolate_payload_adapter"] == true {
        deps.entity_reads.push(find_path("/Griffin1SurfaceOps/FLIPPayloadAdapterJoint"));
        deps.entity_writes.push(find_path("/Griffin1SurfaceOps/FLIPPayloadAdapterJoint"));
        deps.entity_writes.push(find_path("/Griffin1SurfaceOps/FLIP"));
    }
    if ctx["isolate_hull"] == true {
        for path in _hull_cut_paths() {
            deps.entity_reads.push(find_path(path));
            deps.entity_writes.push(find_path(path));
        }
        for path in _hull_source_body_paths() {
            deps.entity_reads.push(find_path(path));
            deps.entity_writes.push(find_path(path));
        }
    }
    deps
}

fn _force_actuator_paths() {
    let root="/Griffin1SurfaceOps/Lander/";
    let paths=[];
    for name in ["RcsPitchPos","RcsPitchPosB","RcsPitchNeg","RcsPitchNegB",
        "RcsRollPos","RcsRollPosB","RcsRollNeg","RcsRollNegB",
        "RcsYawPos","RcsYawPosB","RcsYawNeg","RcsYawNegB"] {
        paths.push(root+name);
    }
    for name in ["Engine01","Engine02","Engine03","Engine04","Engine05","Engine06","Engine07"] {
        paths.push(root+"Nozzle/MainEngineCluster/"+name);
    }
    paths
}

fn _backend_wrench(observation) {
    let paths=_force_actuator_paths();
    let thrusts=observation.pitch_rcs_thrust_n+observation.roll_yaw_rcs_thrust_n
        +observation.main_engine_thrust_n;
    let com=observation.center_of_mass_body_m;
    if !vec3_is_valid(com) || thrusts.len()!=19 {throw("native wrench force/COM snapshot invalid");}
    let native_force=[0.0,0.0,0.0];
    let native_rcs_torque=[0.0,0.0,0.0];
    let native_main_torque=[0.0,0.0,0.0];
    let mounts=[];
    for index in 0..19 {
        let path=paths[index];
        let id=find_path(path);
        if id==() || id<0 {throw("native wrench actuator entity unavailable: "+path);}
        let position=get(id,"ForceActuator.local_position");
        let direction=get(id,"ForceActuator.direction_local");
        let capacity=get(id,"ForceActuator.max_force_n");
        if !vec3_is_valid(position) || !vec3_is_valid(direction) || vlen(direction)<=0.0
            || capacity==() || !capacity.is_finite() || capacity<=0.0
            || thrusts[index]==() || !thrusts[index].is_finite() {
            throw("native wrench actuator metadata invalid: "+path);
        }
        let normalized=vec3_array(vnorm(direction));
        let native_position=vec3_array(position);
        let force=vscale(normalized,thrusts[index].clamp(0.0,capacity));
        let torque=vcross(vsub(native_position,com),force);
        native_force=vadd(native_force,force);
        if index<12 {native_rcs_torque=vadd(native_rcs_torque,torque);}
        else {native_main_torque=vadd(native_main_torque,torque);}
        mounts.push([path.split('/').pop(),native_position,normalized,capacity,thrusts[index],torque]);
    }
    #{ok:true,frame:"hull_local",native_force_n:native_force,
        native_rcs_torque_nm:native_rcs_torque,native_main_torque_nm:native_main_torque,
        mount_columns:["name","position_m","direction","capacity_n","solved_force_n","torque_nm"],mounts:mounts}
}

fn _leg_joint_paths() {
    let paths=[];
    for name in griffin_spec::landing_leg_names() {
        paths.push("/Griffin1SurfaceOps/Lander/"+name+"_Spring");
    }
    paths
}

fn _isolate_leg_joints() {
    let paths=_leg_joint_paths();
    if paths.len()!=4 {throw("pilot isolation requires the four sourced leg identities");}
    let types=[];
    let bodies=[];
    for name in griffin_spec::landing_leg_names() {
        types.push("PhysicsPrismaticJoint");
        bodies.push("/Griffin1SurfaceOps/Lander/"+name);
    }
    let moves=_snapshot_isolation_moves(bodies);
    let retired=_retire_isolation_joints(paths,types,bodies,"GRIFFIN_PILOT_LEG_ISOLATION");
    #{paths:retired,moves:moves}
}

fn _isolate_payload_adapter() {
    let bodies=["/Griffin1SurfaceOps/FLIP"];
    let moves=_snapshot_isolation_moves(bodies);
    let retired=_retire_isolation_joints(["/Griffin1SurfaceOps/FLIPPayloadAdapterJoint"],
        ["PhysicsFixedJoint"],bodies,"GRIFFIN_PILOT_ADAPTER_ISOLATION");
    #{paths:retired,moves:moves}
}

fn _retire_isolation_joints(paths, types, bodies, category) {
    let snapshot=query("QueryUsdPrims",#{paths:paths,rels:["physics:body0","physics:body1"]});
    if snapshot==() || snapshot.error!=() || snapshot.records==() || snapshot.records.len()!=paths.len() {
        throw("pilot joint isolation topology unavailable");
    }
    let targets=[];
    for index in 0..paths.len() {
        let record=snapshot.records[index];
        let target=find_path(paths[index]);
        if record.type_name!=types[index] || record.active!=true
            || record.relationships==()
            || record.relationships["physics:body0"]!=["/Griffin1SurfaceOps/Lander"]
            || record.relationships["physics:body1"]!=[bodies[index]]
            || target==() || target<0 {
            throw("pilot isolation joint contract invalid: "+paths[index]);
        }
        targets.push(target);
    }
    let results=[];
    for target in targets {
        let result=cmd("DetachJoint",#{target:target,intent:"Interactive"});
        if result==() || result.ok!=true {throw("pilot isolation detach rejected: "+result);}
        results.push(result);
    }
    print(category+" "+#{sim_tick:sim_tick(),paths:paths,results:results});
    paths
}

fn _hull_cut_paths() {
    let root="/Griffin1SurfaceOps/Lander";
    let paths=_leg_joint_paths();
    let roots=griffin_spec::ramp_root_joint_names();
    for name in roots {paths.push(root+"/"+name);}
    for binding in griffin_spec::ramp_flight_latch_bindings() {
        if roots.contains(binding.hinge) {paths.push(root+"/"+binding.latch);}
    }
    for name in griffin_spec::ramp_transition_joint_names() {paths.push(root+"/"+name);}
    paths.push("/Griffin1SurfaceOps/FLIPPayloadAdapterJoint");
    if paths.len()!=11 {throw("hull isolation source root-cut cardinality invalid");}
    paths
}

fn _hull_source_body_paths() {
    let root="/Griffin1SurfaceOps/Lander";
    let bodies=[];
    for name in griffin_spec::landing_leg_names() {bodies.push(root+"/"+name);}
    for name in griffin_spec::ramp_names() {
        let path=root+"/"+name;
        let sections=griffin_spec::ramp_section_paths(path);
        if sections==() || sections.len()!=3 {throw("hull isolation sourced ramp body paths unavailable");}
        bodies.push(path);
        bodies.push(sections[1]);
        bodies.push(sections[2]);
    }
    for side in ["port","starboard"] {
        let name=griffin_spec::physical_ramp_transition_body_name(side);
        if name==() || name=="" {throw("hull isolation sourced transition body unavailable");}
        bodies.push(root+"/"+name);
    }
    bodies.push("/Griffin1SurfaceOps/FLIP");
    if bodies.len()!=13 {throw("hull isolation sourced body cardinality invalid");}
    bodies
}

fn _hull_isolation_plan() {
    let root="/Griffin1SurfaceOps/Lander";
    let paths=_hull_cut_paths();
    let bodies=_hull_source_body_paths();
    let endpoints=[];
    let types=[];
    for name in griffin_spec::landing_leg_names() {
        endpoints.push(root+"/"+name);types.push("PhysicsPrismaticJoint");
    }
    let ramps=griffin_spec::ramp_names();
    let hinges=griffin_spec::ramp_root_joint_names();
    if ramps.len()!=2 || hinges.len()!=2 {throw("hull root ramp identity cardinality invalid");}
    for name in ramps {endpoints.push(root+"/"+name);types.push("PhysicsRevoluteJoint");}
    for binding in griffin_spec::ramp_flight_latch_bindings() {
        for index in 0..hinges.len() {
            if binding.hinge==hinges[index] {
                endpoints.push(root+"/"+ramps[index]);types.push("PhysicsFixedJoint");
            }
        }
    }
    for side in ["port","starboard"] {
        endpoints.push(root+"/"+griffin_spec::physical_ramp_transition_body_name(side));
        types.push("PhysicsFixedJoint");
    }
    endpoints.push("/Griffin1SurfaceOps/FLIP");types.push("PhysicsFixedJoint");
    if endpoints.len()!=11 || types.len()!=11 {throw("hull root endpoint cardinality invalid");}
    let snapshot=query("QueryUsdPrims",#{paths:paths,attrs:[],rels:["physics:body0","physics:body1"]});
    if snapshot==() || snapshot.error!=() || snapshot.records==() || snapshot.records.len()!=11 {
        throw("hull root-cut authored endpoint snapshot unavailable");
    }
    let cut=[];
    for index in 0..11 {
        let record=snapshot.records[index];
        if record.path!=paths[index] || record.active!=true || record.type_name!=types[index]
            || record.relationships==() || record.relationships["physics:body0"]!=[root]
            || record.relationships["physics:body1"]!=[endpoints[index]]
            || !bodies.contains(endpoints[index]) {
            throw("hull root-cut standard type or endpoint invalid: "+paths[index]);
        }
        cut.push(#{path:paths[index],type_name:types[index],body0:root,body1:endpoints[index]});
    }
    #{cut:cut,bodies:bodies}
}

fn _isolate_hull() {
    let plan=_hull_isolation_plan();
    let paths=[];
    for joint in plan.cut {paths.push(joint.path);}
    let snapshot=query("QueryUsdPrims",#{paths:paths,rels:["physics:body0","physics:body1"]});
    if snapshot==() || snapshot.error!=() || snapshot.records==()
        || snapshot.records.len()!=paths.len() {throw("hull cut endpoint snapshot unavailable");}
    let targets=[];
    for index in 0..paths.len() {
        let record=snapshot.records[index];
        let joint=plan.cut[index];
        let target=find_path(joint.path);
        if record.active!=true || record.type_name!=joint.type_name || record.relationships==()
            || record.relationships["physics:body0"]!=[joint.body0]
            || record.relationships["physics:body1"]!=[joint.body1] || target==() || target<0 {
            throw("hull cut standard joint endpoints invalid: "+joint.path);
        }
        targets.push(target);
    }
    let moves=_snapshot_isolation_moves(plan.bodies);
    for target in targets {
        let result=cmd("DetachJoint",#{target:target,intent:"Interactive"});
        if result==() || result.ok!=true {throw("hull isolation root detach rejected: "+result);}
    }
    print("GRIFFIN_PILOT_HULL_ISOLATION "+#{sim_tick:sim_tick(),cut:paths,moves:moves});
    #{paths:paths,moves:moves}
}

fn _snapshot_isolation_moves(paths) {
    let moves=[];
    for path in paths {
        let target=find_path(path);
        let pose=query("QueryEntity",#{id:target});
        let physics=query("QueryPhysicsState",#{id:target});
        if target==() || target<0 || pose==() || pose.usd_prim_path!=path
            || pose.position_frame!="active_physics" || pose.position==() || pose.position.len()!=3
            || pose.rotation==() || pose.rotation.len()!=4 || physics==()
            || physics.physics_state_ready!=true || physics.body_mode!="dynamic" {
            throw("hull isolation dynamic body pose unavailable: "+path);
        }
        for value in pose.position+pose.rotation {
            if !value.is_finite() {throw("hull isolation body pose is nonfinite: "+path);}
        }
        let destination=[pose.position[0]+150.0,pose.position[1]+150.0,pose.position[2]];
        if !destination[0].is_finite() || !destination[1].is_finite()
            || ((destination[0]-pose.position[0])*(destination[0]-pose.position[0])
                +(destination[1]-pose.position[1])*(destination[1]-pose.position[1]))>500.0*500.0 {
            throw("hull isolation move exceeds the finite native displacement bound: "+path);
        }
        moves.push(#{path:path,target:target,before:pose.position,translation:destination,rotation:pose.rotation});
    }
    moves
}

fn _park_isolation_branches(moves, category) {
    for movement in moves {
        let result=cmd("TransformEntity",#{entity_id:movement.target,translation:movement.translation,rotation:movement.rotation});
        if result==() || result.ok!=true {throw("hull isolation body move rejected: "+#{path:movement.path,result:result});}
    }
    print(category+"_PARKING "+#{sim_tick:sim_tick(),moves:moves});
}

fn _verify_isolation_clearance(lander, moves, verify_rover, category) {
    let hull=query("QueryEntity",#{id:lander});
    if hull==() || hull.position==() {throw("hull isolation hull pose unavailable");}
    let minimum=500.0;
    let observed=[];
    for movement in moves {
        let pose=query("QueryEntity",#{id:movement.target});
        let physics=query("QueryPhysicsState",#{id:movement.target});
        if pose==() || pose.usd_prim_path!=movement.path || pose.position_frame!="active_physics"
            || pose.position==() || pose.position.len()!=3 || pose.rotation==() || pose.rotation.len()!=4
            || physics==() || physics.physics_state_ready!=true {
            throw("hull isolation move has no admitted native pose: "+movement.path);
        }
        for value in pose.position+pose.rotation {
            if !value.is_finite() {throw("hull isolation native pose is nonfinite: "+movement.path);}
        }
        let squared=0.0;
        for axis in 0..3 {
            let difference=pose.position[axis]-hull.position[axis];
            squared+=difference*difference;
        }
        let separation=squared.sqrt();
        if !separation.is_finite() || separation<100.0 {
            throw("hull isolation disconnected body remains near the hull: "+#{path:movement.path,separation:separation});
        }
        minimum=min(minimum,separation);
        observed.push(#{path:movement.path,commanded_position:movement.translation,
            native_position:pose.position,native_rotation:pose.rotation,separation_m:separation});
    }
    if verify_rover {
    let rover=query("QueryPhysicsState",#{id:find_path("/Griffin1SurfaceOps/FLIP")});
    if rover==() || rover.wheel_contacts==() {throw("hull isolation FLIP contact state unavailable");}
    for wheel in rover.wheel_contacts {
        if wheel.contact_valid==true || wheel.normal_force_n!=0.0 || vlen(wheel.tire_force_n)>0.0 {
            throw("hull isolation FLIP still carries native wheel contact: "+wheel);
        }
    }
    }
    print(category+"_CLEARANCE "+#{sim_tick:sim_tick(),minimum_separation_m:minimum,bodies:observed});
    minimum
}

fn _study(name) {
    let value = griffin_spec::_typed_model_number(
        "GriffinPropulsionRequirements::GriffinEngineControlStudy::" + name);
    if value == () || !value.is_finite() || value <= 0.0 {
        throw("missing pilot attitude study datum: " + name);
    }
    value
}

fn _elapsed(tick) {
    let clock = clock_snapshot();
    if clock.fixed_dt_s == () || !clock.fixed_dt_s.is_finite() || clock.fixed_dt_s <= 0.0 {
        throw("pilot attitude test has no admitted fixed clock");
    }
    (sim_tick() - tick).to_float() * clock.fixed_dt_s
}

fn _intent(target, name, held) {
    let result = cmd("SimulateIntent", #{target: target, intent: name, held: held});
    if result == () || result.ok != true {throw("pilot intent rejected: " + result);}
}

fn _values(target, names) {
    let values = [];
    for name in names {
        let value = get(target, name);
        values.push(value);
    }
    values
}

fn _diagnostic(lander, hull_isolated, clearance_verified) {
    let physics = query("QueryPhysicsState", #{id: lander});
    let rover = query("QueryPhysicsState", #{id: find_path("/Griffin1SurfaceOps/FLIP")});
    let hinges = ();
    if !hull_isolated {hinges=griffin_surface_ops::physical_ramp_hinge_report();}
    if physics == () || physics.physics_state_ready != true
        || physics.angular_velocity_radps == () || physics.mass_kg==()
        || !physics.mass_kg.is_finite() || physics.mass_kg<=0.0
        || (!hull_isolated && (hinges == () || hinges.ok != true)) {
        return #{ok: false, error: "pilot attitude physical or hinge observation unavailable",
            physics: physics, hinges: hinges};
    }
    if rover==() || rover.ok==false || rover.wheel_contacts==() {
        return #{ok:false,error:"pilot FLIP native wheel observation unavailable",rover:rover};
    }
    let wheel_observations=[];
    for wheel in rover.wheel_contacts {
        if clearance_verified && wheel.hit_available==true
            && (wheel.hit_usd_prim_path=="/Griffin1SurfaceOps/Lander"
                || wheel.hit_usd_prim_path.starts_with("/Griffin1SurfaceOps/Lander/")) {
            return #{ok:false,error:"isolated FLIP wheel ray still intersects hull",wheel:wheel};
        }
        wheel_observations.push(#{path:wheel.wheel_usd_prim_path,contact_valid:wheel.contact_valid,
            hit_available:wheel.hit_available,hit_path:wheel.hit_usd_prim_path,
            normal_force_n:wheel.normal_force_n,tire_force_n:wheel.tire_force_n,
            excluded_entity_count:wheel.raycast_filter_excluded_entity_count,
            sample_tick:wheel.sample_tick});
    }
    let hinge_observations=[];
    if !hull_isolated {for hinge in hinges.hinges {
        hinge_observations.push(#{name:hinge.name,
            drive_target_rad:hinge.drive_target_rad,
            measured_angle_rad:hinge.measured_angle_rad,
            measured_angular_speed_rad_per_s:hinge.measured_angular_speed_rad_per_s});
    }}
    let rcs = find_path("/Griffin1SurfaceOps/Lander/AttitudePropulsion");
    let observation = #{ok: true, sim_tick: sim_tick(),
        rotation_xyzw: world_rotation(lander),
        angular_velocity_navigation_rad_s: physics.angular_velocity_radps,
        mass_kg:physics.mass_kg,
        center_of_mass_body_m:physics.center_of_mass_m,
        inertia_principal_kgm2:physics.inertia_principal_kgm2,
        controller_inertia_kgm2:_values(lander,["controller_inertia_xx","controller_inertia_yy","controller_inertia_zz"]),
        gyro_body_rad_s: _values(lander, ["gyro_x", "gyro_y", "gyro_z"]),
        error_body: _values(lander, ["attitude_error_x", "attitude_error_y", "attitude_error_z"]),
        requested_torque_nm: _values(lander, ["torque_x", "torque_y", "torque_z"]),
        commanded_tilt_rad: _values(lander, ["desired_tilt_x", "desired_tilt_z"]),
        pilot_inputs: _values(lander, ["piloted", "external_throttle", "pitch"]),
        pitch_rcs_thrust_n: _values(rcs, ["pitch_pos_a_thrust_n", "pitch_pos_b_thrust_n",
            "pitch_neg_a_thrust_n", "pitch_neg_b_thrust_n"]),
        roll_yaw_rcs_thrust_n:_values(rcs,["roll_pos_a_thrust_n","roll_pos_b_thrust_n",
            "roll_neg_a_thrust_n","roll_neg_b_thrust_n","yaw_pos_a_thrust_n",
            "yaw_pos_b_thrust_n","yaw_neg_a_thrust_n","yaw_neg_b_thrust_n"]),
        main_engine_thrust_n:_values(find_path("/Griffin1SurfaceOps/Lander/MainPropulsion"),
            ["engine01_thrust_n","engine02_thrust_n","engine03_thrust_n","engine04_thrust_n",
             "engine05_thrust_n","engine06_thrust_n","engine07_thrust_n"]),
        leg_rate_mps: _values(lander, ["leg_velocity_px", "leg_velocity_nx",
            "leg_velocity_pz", "leg_velocity_nz"]),
        rover:#{physics_state_ready:rover.physics_state_ready,
            angular_velocity_radps:rover.angular_velocity_radps,wheel_contacts:wheel_observations},
        hinges:if hull_isolated {()} else {#{ok:true,sim_tick:hinges.sim_tick,hinges:hinge_observations}},
        hinge_observation_state:if hull_isolated {"root_hinge_checks_excluded_for_isolation"} else {"measured"}};
    for name in ["gyro_body_rad_s", "error_body", "requested_torque_nm",
        "commanded_tilt_rad", "pilot_inputs", "pitch_rcs_thrust_n", "leg_rate_mps",
        "roll_yaw_rcs_thrust_n","main_engine_thrust_n","controller_inertia_kgm2",
        "center_of_mass_body_m","inertia_principal_kgm2"] {
        for value in observation[name] {
            if value == () || !value.is_finite() {
                observation.ok = false;
                observation.error = "pilot attitude observation unavailable: " + name;
                return observation;
            }
        }
    }
    try {observation.backend_wrench=_backend_wrench(observation);}
    catch (error) {
        observation.backend_wrench=#{ok:false,error:error};
        if hull_isolated {observation.ok=false;observation.error="native hull wrench observation unavailable: "+error;}
    }
    observation
}

fn on_start(me, ctx) {
    let isolate=ctx["isolate_leg_joints"];
    let adapter=ctx["isolate_payload_adapter"];
    let hull=ctx["isolate_hull"];
    if isolate!=() && type_of(isolate)!="bool" {throw("isolate_leg_joints must be a boolean");}
    if adapter!=() && type_of(adapter)!="bool" {throw("isolate_payload_adapter must be a boolean");}
    if hull!=() && type_of(hull)!="bool" {throw("isolate_hull must be a boolean");}
    if (isolate==true && adapter==true) || (hull==true && (isolate==true || adapter==true)) {
        throw("pilot isolation trial selects one attachment group");
    }
    this.isolate_leg_joints=isolate==true;
    this.isolate_payload_adapter=adapter==true;
    this.isolate_hull=hull==true;
    this.hull_isolated=false;
    this.hull_clearance_verified=false;
    this.isolation_clearance_verified=false;
    this.verdict_category=if this.isolate_leg_joints {"GRIFFIN_PILOT_LEG_ISOLATION"}
        else if this.isolate_payload_adapter {"GRIFFIN_PILOT_ADAPTER_ISOLATION"}
        else if this.isolate_hull {"GRIFFIN_PILOT_HULL_ISOLATION"} else {"GRIFFIN_PILOT_ATTITUDE"};
    print("GRIFFIN_PILOT_TRIAL_MODE "+#{isolate_leg_joints:this.isolate_leg_joints,
        isolate_payload_adapter:this.isolate_payload_adapter,isolate_hull:this.isolate_hull});
    this.lander = find_path("/Griffin1SurfaceOps/Lander");
    this.phase = "descent_setup";
    this.start_tick = sim_tick();
    this.phase_tick = sim_tick();
    this.done = false;
    this.minimum_up = 1.0;
    this.maximum_rate = 0.0;
    this.maximum_lift = 0.0;
    this.maximum_tap_tilt = 0.0;
    this.pitch_released = false;
    this.ramp_peak_error_rad = 0.0;
    this.ramp_peak_rate_rad_s = 0.0;
    this.horizon_s = _study("pilotAttitudeRecoveryDurationS");
    this.tap_duration_s = _study("pilotPitchTapDurationS");
}

fn _finish(state, sample, error) {
    _intent(state.lander, "forward", false);
    _intent(state.lander, "thrust", false);
    print("GRIFFIN_PILOT_ATTITUDE_METRICS " + #{minimum_upright_y: state.minimum_up,
        maximum_rate_rad_s: state.maximum_rate, maximum_lift_m: state.maximum_lift,
        maximum_tap_tilt_rad: state.maximum_tap_tilt,
        ramp_peak_error_rad:if state.isolate_hull {()} else {state.ramp_peak_error_rad},
        ramp_peak_rate_rad_s:if state.isolate_hull {()} else {state.ramp_peak_rate_rad_s},
        final_sample: sample, terminal_error: error});
    let checks=[
        t_true(error == "", error),
        t_true(state.pitch_released, "pitch tap was not released"),
        t_true(state.maximum_tap_tilt > 0.0, "semantic pitch tap did not reach controller"),
        t_true(state.maximum_lift >= _study("minimumSustainedLiftM"), "pilot never lifted off"),
        t_true(state.minimum_up >= _study("minimumBurnUprightY"),
            "pilot tap exceeded study tilt envelope: " + state.minimum_up),
        t_true(state.maximum_rate <= _study("maximumBurnAngularSpeedRadS"),
            "pilot tap exceeded study rate envelope: " + state.maximum_rate),
        t_true(sample.upright_axis_y >= _study("minimumBurnUprightY"),
            "pilot did not recover upright")
    ];
    if state.isolate_hull {
        checks.push(t_true(state.isolation_clearance_verified,"hull isolation did not retire and clear the attachment branches"));
    } else {
        checks.push(t_true(state.ramp_peak_error_rad <= griffin_spec::physical_ramp_hinge_settle_angle_tolerance_rad(),
            "flight latch allowed ramp stow angle drift: " + state.ramp_peak_error_rad));
        checks.push(t_true(state.ramp_peak_rate_rad_s <= griffin_spec::physical_ramp_hinge_settle_speed_tolerance_rad_per_s(),
            "flight latch allowed ramp relative motion: " + state.ramp_peak_rate_rad_s));
    }
    if state.isolate_leg_joints || state.isolate_payload_adapter {
        checks.push(t_true(state.isolation_clearance_verified,"attachment isolation did not retire and clear its bodies"));
    }
    report_verdict(checks,"GRIFFIN PILOT ATTITUDE",state.verdict_category);
}

fn on_tick(me, ctx) {
    if this.done {return;}
    try {
    if this.phase == "descent_setup" {
        let mass = griffin_surface_ops::guidance_assembly_mass_report();
        if mass != () && mass.ready == false {
            if _elapsed(this.start_tick) >= _study("touchdownTimeoutS") {
                throw("pilot descent mass propagation timed out: " + mass);
            }
            return;
        }
        if mass == () || mass.ok != true || mass.ready != true {
            throw("pilot descent assembly mass contract unavailable: " + mass);
        }
        let arm = griffin_surface_ops::arm_descent_guidance();
        if arm == () || arm.ok != true {throw("pilot descent guidance arm rejected: " + arm);}
        print("GRIFFIN_PILOT_DESCENT_SETUP " + #{mass:mass,arm:arm});
        this.phase = "landing";
        this.start_tick = sim_tick();
        return;
    }
    let sample = griffin_surface_ops::landing_stability_sample();
    if sample == () || sample.ok != true {throw("pilot physical sample unavailable: " + sample);}
    if sample.touchdown == () || sample.all_legs_contact == () {
        throw("pilot landing qualification unavailable");
    }
    if this.phase == "landing" {
        if sample.touchdown < 0.999 || sample.all_legs_contact < 0.999 {
            if _elapsed(this.start_tick) > _study("touchdownTimeoutS") {
                this.done = true;
                _finish(this, sample, "no settled touchdown before pilot trial");
            }
            return;
        }
        this.rest_y = sample.position[1];
        let avatar = find_path("/Griffin1SurfaceOps/Avatar");
        let acquired = cmd("AcquireControl", #{target: this.lander, source: avatar, bind_camera: false});
        if acquired == () || acquired.ok != true {throw("pilot acquisition rejected: " + acquired);}
        this.phase = "acquiring";
        this.phase_tick = sim_tick();
        return;
    }
    if this.phase == "acquiring" {
        if sim_tick() - this.phase_tick < 2 {return;}
        _intent(this.lander, "thrust", true);
        this.phase = "liftoff";
        this.phase_tick = sim_tick();
        this.burn_tick = sim_tick();
        return;
    }
    this.minimum_up = min(this.minimum_up, sample.upright_axis_y);
    this.maximum_rate = max(this.maximum_rate, sample.angular_speed);
    this.maximum_lift = max(this.maximum_lift, sample.position[1] - this.rest_y);
    if this.phase == "liftoff" && sample.position[1] - this.rest_y >= _study("minimumSustainedLiftM") {
        print("GRIFFIN_PILOT_LIFTOFF_DIAGNOSTIC "+_diagnostic(this.lander,false,false));
        if this.isolate_leg_joints || this.isolate_payload_adapter || this.isolate_hull {
            if this.isolate_hull {
                let plan=_isolate_hull();
                this.retired_paths=plan.paths;
                this.isolation_moves=plan.moves;
                this.hull_isolated=true;
            } else {
                let plan=if this.isolate_leg_joints {_isolate_leg_joints()}
                    else {_isolate_payload_adapter()};
                this.retired_paths=plan.paths;
                this.isolation_moves=plan.moves;
            }
            this.phase="isolating_attachment";
            this.phase_tick=sim_tick();
        } else {
            _intent(this.lander, "forward", true);
            this.phase = "tap";
            this.phase_tick = sim_tick();
        }
    }
    let attachment_retired=this.phase=="isolating_attachment" && sim_tick()-this.phase_tick>=2;
    if attachment_retired {
        for path in this.retired_paths {
            if find_path(path)>=0 {throw("pilot isolation solver edge was not retired: "+path);}
        }
        _park_isolation_branches(this.isolation_moves,this.verdict_category);
        this.phase="parking_isolation_branches";
        this.phase_tick=sim_tick();
        return;
    }
    if this.phase=="parking_isolation_branches" && sim_tick()-this.phase_tick>=2 {
        _verify_isolation_clearance(this.lander,this.isolation_moves,
            this.isolate_hull || this.isolate_payload_adapter,this.verdict_category);
        this.isolation_clearance_verified=true;
        this.hull_clearance_verified=this.isolate_hull || this.isolate_payload_adapter;
        print("GRIFFIN_PILOT_ISOLATION_DIAGNOSTIC "+_diagnostic(this.lander,this.hull_isolated,this.hull_clearance_verified));
        _intent(this.lander, "forward", true);
        this.phase = "tap";
        this.phase_tick = sim_tick();
    }
    if this.phase == "tap" && _elapsed(this.phase_tick) >= this.tap_duration_s {
        _intent(this.lander, "forward", false);
        this.pitch_released = true;
        this.phase = "recovery";
        this.phase_tick = sim_tick();
    }
    // Tests observe at fixed cadence; this is verdict data, not a control law.
    if (sim_tick() - this.burn_tick) % 6 == 0 {
        let observation = _diagnostic(this.lander,this.hull_isolated,this.hull_clearance_verified);
        if observation.ok != true {
            print("GRIFFIN_PILOT_ATTITUDE_OBSERVATION_ERROR " + observation);
            this.done = true;
            _finish(this, sample, observation.error);
            return;
        }
        for tilt in observation.commanded_tilt_rad {
            this.maximum_tap_tilt = max(this.maximum_tap_tilt, tilt.abs());
        }
        if !this.hull_isolated {for hinge in observation.hinges.hinges {
            this.ramp_peak_error_rad = max(this.ramp_peak_error_rad,
                griffin_surface_ops::_ramp_angle_error_rad(hinge.measured_angle_rad, hinge.drive_target_rad).abs());
            this.ramp_peak_rate_rad_s = max(this.ramp_peak_rate_rad_s,
                hinge.measured_angular_speed_rad_per_s.abs());
        }}
        print("GRIFFIN_PILOT_ATTITUDE_SAMPLE " + #{phase: this.phase,
            physical: sample, diagnostic: observation});
    }
    if sample.upright_axis_y <= 0.0 {
        this.done = true;
        _finish(this, sample, "pilot attitude crossed horizontal under held thrust");
        return;
    }
    if this.phase == "recovery" && _elapsed(this.phase_tick) >= this.horizon_s {
        this.done = true;
        _finish(this, sample, "");
    } else if this.phase == "liftoff" && _elapsed(this.phase_tick) >= this.horizon_s {
        this.done = true;
        _finish(this, sample, "pilot liftoff timed out");
    }
    } catch (error) {
        let message=error.to_string();
        if message.len()>512 {message=message.sub_string(0,512);}
        this.done = true;
        let stops = [];
        if this.phase != "descent_setup" && this.phase != "landing" && this.phase != "acquiring" {
            for name in ["forward", "thrust"] {
                stops.push(cmd("SimulateIntent", #{target: this.lander, intent: name, held: false}));
            }
        }
        print("GRIFFIN_PILOT_ATTITUDE_OBSERVATION_ERROR " + #{error: message, stops: stops});
        report_verdict([t_true(false, "pilot observation or command failed: " + message)],
            "GRIFFIN PILOT ATTITUDE", this.verdict_category);
    }
}

fn on_stop(me, ctx) {
    if this.lander != () && this.lander >= 0 {
        _intent(this.lander, "forward", false);
        _intent(this.lander, "thrust", false);
    }
}
