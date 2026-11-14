import "griffin_1_surface_ops.rhai" as mission;
const TEST_KIND="headless";
const ROOT="/Griffin1SurfaceOps";

fn simulation_dependencies(me,ctx) {
    let dependencies=mission::simulation_dependencies(me,ctx);
    dependencies.query_reads.push("InspectUsdCurveView");
    dependencies.query_reads.push("ScriptingCatalog");
    dependencies.entity_writes.push(find_path(ROOT+"/Lander"));
    for station in ["FL","FR","RL","RR"] {
        let wheel=find_path(ROOT+"/FLIP/Suspension_"+station+"/Wheel_"+station);
        dependencies.entity_reads.push(wheel);dependencies.entity_writes.push(wheel);
        let bridle=find_path(usd_path(wheel)+"/CADVisuals/LiveBridle");
        if bridle>=0 {dependencies.entity_reads.push(bridle);dependencies.entity_writes.push(bridle);}
    }
    for side in ["Left","Right"] {for name in ["","/Span"] {
        let entity=find_path(ROOT+"/Lander/LiveTethers/"+side+name);
        if entity>=0 {dependencies.entity_reads.push(entity);dependencies.entity_writes.push(entity);}
    }}
    dependencies
}

fn input_geometry(rover,lander,anchor_x,anchor_y,anchor_z) {
    let config=griffin_tether_study::routing_config();
    input_geometry(rover,lander,anchor_x,anchor_y,anchor_z,config)
}

fn input_geometry(rover,lander,anchor_x,anchor_y,anchor_z,config) {
    let rp=query("QueryPhysicsState",#{id:rover});
    let lp=query("QueryPhysicsState",#{id:lander});
    let rpos=world_pos3(rover);let lpos=world_pos3(lander);
    let rrot=world_rotation_quat(rover);let lrot=world_rotation_quat(lander);
    let rc=rpos+qrot(rrot,vec3_from(rp.center_of_mass_m));
    let lc=lpos+qrot(lrot,vec3_from(lp.center_of_mass_m));
    let rv=vec3_from(rp.linear_velocity_mps);let lv=vec3_from(lp.linear_velocity_mps);
    let rw=vec3_from(rp.angular_velocity_radps);let lw=vec3_from(lp.angular_velocity_radps);
    let writes=[];let index=0;
    let ramp=find_path(ROOT+"/Lander/CompactEgress");
    let ramp_position=world_pos3(ramp);let ramp_rotation=world_rotation_quat(ramp);
    let inboard=qrot(ramp_rotation,vec3(1.0,0.0,0.0));
    let up=qrot(ramp_rotation,vec3(0.0,1.0,0.0));
    let pitch_axis=vcross(inboard*(-1.0),vec3(0.0,1.0,0.0));
    writes.push(["body_angular_speed",vlen(rw)]);
    writes.push(["up_vertical",qrot(rrot,vec3(0.0,1.0,0.0)).y]);
    writes.push(["nose_down_rate",-vdot(rw,pitch_axis)/vlen(pitch_axis)]);
    for i in 0..3 {
        let letter=["x","y","z"][i];
        writes.push(["inboard_"+letter,vec3_array(inboard)[i]]);
        writes.push(["up_"+letter,vec3_array(up)[i]]);
        writes.push(["lander_omega_"+letter,vec3_array(lw)[i]]);
    }
    // Modelica resolves cylindrical tangency and material speed, including
    // wheel rotation. Native wheel endpoints receive the resulting wrench.
    for station in ["RL","RR"] {
        let wheel=find_path(ROOT+"/FLIP/Suspension_"+station+"/Wheel_"+station);
        let wp=query("QueryPhysicsState",#{id:wheel});
        let hub=world_pos3(wheel);
        let waxis=qrot(world_rotation_quat(wheel),vec3(1.0,0.0,0.0));
        let omega=vec3_from(wp.angular_velocity_radps);
        let wheel_com=qrot(world_rotation_quat(wheel),vec3_from(wp.center_of_mass_m));
        let wv=vec3_from(wp.linear_velocity_mps)-vcross(omega,wheel_com);
        let wheel_local=qrot(quat_inverse(lrot),hub-lpos);
        let side=if wheel_local.z<0.0 {-1.0}else{1.0};
        let anchor=lpos+qrot(lrot,vec3(-anchor_x,anchor_y,side*anchor_z));
        for j in 0..config.profile_x.len() {
            let guide=ramp_position+qrot(ramp_rotation,vec3(config.profile_x[j],config.profile_y[j],-side*anchor_z));
            let offset=guide-hub;
            for i in 0..3 {writes.push(["guide"+index+"_"+j+"_"+["x","y","z"][i],vec3_array(offset)[i]]);}
        }
        let span=anchor-hub;let distance=vlen(span);let ra=hub-rc;let la=anchor-lc;
        let relative=wv-lv-vcross(lw,la);
        writes.push(["rate"+index,-vdot(relative,span)/max(distance,0.000001)]);
        for axis in 0..3 {
            let letter=["x","y","z"][axis];
            writes.push(["span"+index+"_"+letter,vec3_array(span)[axis]]);
            writes.push(["axis"+index+"_"+letter,vec3_array(waxis)[axis]]);
            writes.push(["relative"+index+"_"+letter,vec3_array(relative)[axis]]);
            writes.push(["omega"+index+"_"+letter,vec3_array(omega)[axis]]);
            writes.push(["rover_arm"+index+"_"+letter,vec3_array(ra)[axis]]);
            writes.push(["lander_arm"+index+"_"+letter,vec3_array(la)[axis]]);
        }
        index+=1;
    }
    writes
}

fn geometry_span(geometry,index) {
    let x=0.0;let y=0.0;let z=0.0;
    for row in geometry {
        if row[0]=="span"+index+"_x" {x=row[1];}
        if row[0]=="span"+index+"_y" {y=row[1];}
        if row[0]=="span"+index+"_z" {z=row[1];}
    }
    sqrt(x*x+y*y+z*z)
}

fn geometry_rate(geometry,index) {
    for row in geometry {if row[0]=="rate"+index {return row[1];}}
    0.0
}

fn rail_attitude(rover,exit_axis,config) {
    let up=world_up3(rover);
    // The retained flip_v5 assembly uses native -Z travel and X wheel axles.
    let forward=qrot(world_rotation_quat(rover),vec3(0.0,0.0,-1.0));
    let horizontal=vec3(exit_axis[0],0.0,exit_axis[2]);
    horizontal=horizontal*(1.0/vlen(horizontal));
    let expected_side=vcross(horizontal,vec3(0.0,1.0,0.0));
    let side=vcross(forward,up);
    let alignment=vdot(side,expected_side);
    let radians=acos(-1.0)/180.0;
    let over=sin(config.maximum_over_center_deg*radians);
    let nose_up=sin(config.maximum_nose_up_deg*radians);
    #{ok:alignment>=config.minimum_rail_alignment
        && up.y>=-over && forward.y<=nose_up && vdot(up,horizontal)>=-nose_up,
      side_alignment_cos:alignment,forward_vertical:forward.y,up_vertical:up.y}
}

fn rail_center_path(xs,ys,radius) {
    let nx=[];let ny=[];
    for i in 0..xs.len()-1 {
        let dx=xs[i+1]-xs[i];let dy=ys[i+1]-ys[i];let length=sqrt(dx*dx+dy*dy);
        nx.push(dy/length);ny.push(-dx/length);
    }
    let px=[xs[0]+radius*nx[0]];let py=[ys[0]+radius*ny[0]];
    for i in 1..xs.len()-1 {
        // The hub rolls around convex rail corners at one tire radius.
        // Its closest point on the un-offset rail would stay at the vertex.
        for j in 0..13 {
            let u=j.to_float()/12.0;
            let x=(1.0-u)*nx[i-1]+u*nx[i];let y=(1.0-u)*ny[i-1]+u*ny[i];
            let length=sqrt(x*x+y*y);
            px.push(xs[i]+radius*x/length);py.push(ys[i]+radius*y/length);
        }
    }
    let last=xs.len()-1;
    px.push(xs[last]+radius*nx[last-1]);py.push(ys[last]+radius*ny[last-1]);
    #{x:px,y:py}
}

fn rail_progress(config) {
    let ramp=find_path(ROOT+"/Lander/CompactEgress");
    let origin=world_pos3(ramp);let rotation=quat_inverse(world_rotation_quat(ramp));
    let rear=(world_pos3(find_path(ROOT+"/FLIP/Suspension_RL/Wheel_RL"))
        +world_pos3(find_path(ROOT+"/FLIP/Suspension_RR/Wheel_RR")))*0.5;
    let p=qrot(rotation,rear-origin);
    let xs=config.rail_x;let ys=config.rail_y;
    let best_distance=1.0e30;let best_progress=0.0;let arc=0.0;
    for i in 0..xs.len()-1 {
        let dx=xs[i+1]-xs[i];let dy=ys[i+1]-ys[i];let squared=dx*dx+dy*dy;
        let u=max(0.0,min(1.0,((p.x-xs[i])*dx+(p.y-ys[i])*dy)/squared));
        let ex=p.x-xs[i]-u*dx;let ey=p.y-ys[i]-u*dy;
        let distance=ex*ex+ey*ey;let length=sqrt(squared);
        if distance<best_distance {best_distance=distance;best_progress=arc+u*length;}
        arc+=length;
    }
    best_progress
}

fn set_rear_brakes(value) {
    let batches=[];
    for station in ["RL","RR"] {
        batches.push(#{target:find_path(ROOT+"/FLIP/Suspension_"+station+"/Wheel_"+station),writes:[["brake",value]]});
    }
    let result=cmd("SetPortsBatch",#{batches:batches});
    if result==() || result.ok!=true {throw("Independent rear restraint brake command was rejected: "+result);}
}

fn set_egress_brakes(front,rear) {
    let batches=[];let i=0;
    for station in ["FL","FR","RL","RR"] {
        let value=if i<2 {front[i]}else{rear};
        batches.push(#{target:find_path(ROOT+"/FLIP/Suspension_"+station+"/Wheel_"+station),writes:[["brake",value]]});
        i+=1;
    }
    let result=cmd("SetPortsBatch",#{batches:batches});
    if result==() || result.ok!=true {throw("Egress wheel brake transaction was rejected: "+result);}
}

fn check_rear_brake_admission() {
    let batches=[];
    for station in ["RL","RR"] {batches.push(#{target:find_path(ROOT+"/FLIP/Suspension_"+station+"/Wheel_"+station),writes:[["brake",1.1]]});}
    let rejected=cmd("SetPortsBatch",#{batches:batches});
    if rejected==() || rejected.ok!=false {set_rear_brakes(0.0);throw("Out-of-range local brake request was not rejected");}
    for station in ["RL","RR"] {
        let ports=read_ports(find_path(ROOT+"/FLIP/Suspension_"+station+"/Wheel_"+station),["brake"]).ports;
        let value=();
        for port in ports {if port.direction=="in" && port.name=="brake" {value=port.value;}}
        if value==() || value!=0.0 {throw("Rejected local brake transaction changed its native input");}
    }
}

fn read_tether(tether) {
    let names=[];
    for i in 0..2 {for axis in ["x","y","z"] {names.push("routing"+i+"_"+axis);}}
    for i in 0..2 {for field in ["wheel_force","wheel_torque"] {for axis in ["x","y","z"] {
        names.push(field+i+"_"+axis);
    }}}
    for i in 0..2 {for field in ["material_rate","paid_rate","extension"] {names.push(field+i);}}
    names+= ["tension0","tension1","length0","length1",
        "elastic_energy","drive_scale","force_x","force_y","force_z","reaction_x","reaction_y","reaction_z",
        "torque_x","torque_y","torque_z","reaction_torque_x","reaction_torque_y","reaction_torque_z"];
    let snapshot=read_ports(tether,names);
    let state=#{};
    for p in snapshot.ports {if p.direction=="out" {state[p.name]=p.value;}}
    let required=names;
    for name in required {
        if state[name]==() || !state[name].is_finite() {throw("Tether telemetry is missing or non-finite: "+name);}
    }
    if state.tension0==() || state.tension1==() || state.elastic_energy==()
        || state.length0==() || state.length1==() {
        throw("Tether telemetry is incomplete");
    }
    if !state.tension0.is_finite() || !state.tension1.is_finite()
        || !state.elastic_energy.is_finite() || !state.length0.is_finite()
        || !state.length1.is_finite() {
        throw("Tether telemetry is non-finite");
    }
    state
}

fn apply_tether_wrenches(tether,rover,lander) {
    let state=read_tether(tether);
    let i=0;let batches=[];
    for station in ["RL","RR"] {
        let wheel=find_path(ROOT+"/FLIP/Suspension_"+station+"/Wheel_"+station);
        let writes=[];
        for field in ["force","torque"] {for axis in ["x","y","z"] {
            writes.push([field+"_"+axis,state["wheel_"+field+i+"_"+axis]]);
        }}
        let wp=query("QueryPhysicsState",#{id:wheel});
        let com=qrot(world_rotation_quat(wheel),vec3_from(wp.center_of_mass_m));
        let force=vec3(state["wheel_force"+i+"_x"],state["wheel_force"+i+"_y"],state["wheel_force"+i+"_z"]);
        let correction=vcross(com,force);
        for j in 0..3 {writes[j+3][1]-=vec3_array(correction)[j];}
        batches.push(#{target:wheel,writes:writes});
        i+=1;
    }
    let lander_writes=[["force_x",state.reaction_x],["force_y",state.reaction_y],["force_z",state.reaction_z],
        ["torque_x",state.reaction_torque_x],["torque_y",state.reaction_torque_y],["torque_z",state.reaction_torque_z]];
    batches.push(#{target:lander,writes:lander_writes});
    let result=cmd("SetPortsBatch",#{batches:batches});
    if result==() || result.ok!=true {throw("Atomic wheel/lander tether wrench transaction was rejected: "+result);}
}

fn release_tether_wrenches(rover,lander) {
    set_egress_brakes([0.0,0.0],0.0);
    for station in ["FL","FR","RL","RR"] {
        let result=cmd("ReleasePort",#{target:find_path(ROOT+"/FLIP/Suspension_"+station+"/Wheel_"+station),name:"brake"});
        if result==() || result.ok!=true {throw("Rear restraint brake release was rejected");}
    }
    let bodies=[find_path(ROOT+"/FLIP/Suspension_RL/Wheel_RL"),
        find_path(ROOT+"/FLIP/Suspension_RR/Wheel_RR"),lander];
    let batches=[];
    for body in bodies {
        batches.push(#{target:body,writes:[["force_x",0.0],["force_y",0.0],["force_z",0.0],
            ["torque_x",0.0],["torque_y",0.0],["torque_z",0.0]]});
    }
    let zero=cmd("SetPortsBatch",#{batches:batches});
    if zero==() || zero.ok!=true {throw("Native tether cut could not clear all pending wrenches atomically");}
    for body in bodies {
        for name in ["force_x","force_y","force_z","torque_x","torque_y","torque_z"] {
            let result=cmd("ReleasePort",#{target:body,name:name});
            if result==() || result.ok!=true {throw("Native tether wrench release was rejected: "+result);}
        }
    }
}

fn safe_hold_tether(tether,rover,lander,anchor_x,anchor_y,anchor_z) {
    try {
        let geometry=input_geometry(rover,lander,anchor_x,anchor_y,anchor_z);
        write_tether(tether,geometry,1.0,0.0,0.0,rover,lander);
        #{ok:true,error:""}
    } catch(error) {
        #{ok:false,error:error.to_string()}
    }
}

fn write_tether(tether,geometry,enabled,speed0,speed1,rover,lander) {
    write_tether(tether,geometry,enabled,speed0,speed1,rover,lander,0.0,0.0)
}

fn write_tether(tether,geometry,enabled,speed0,speed1,rover,lander,regulate,body_speed) {
    write_tether(tether,geometry,enabled,speed0,speed1,rover,lander,regulate,body_speed,0.0)
}

fn write_tether(tether,geometry,enabled,speed0,speed1,rover,lander,regulate,body_speed,angular_govern) {
    write_tether(tether,geometry,enabled,speed0,speed1,rover,lander,regulate,body_speed,angular_govern,0.0)
}

fn write_tether(tether,geometry,enabled,speed0,speed1,rover,lander,regulate,body_speed,angular_govern,front_grounded) {
    geometry.push(["angular_govern_enabled",angular_govern]);
    geometry.push(["front_grounded",front_grounded]);
    geometry.push(["regulate",regulate]);geometry.push(["body_speed",body_speed]);
    geometry.push(["enabled",enabled]);
    geometry.push(["payout_speed0",speed0]);geometry.push(["payout_speed1",speed1]);
    let result=cmd("SetPorts",#{target:tether,writes:geometry});
    if result==() || result.ok!=true {throw("Measured tether inputs were rejected: "+result);}
    apply_tether_wrenches(tether,rover,lander);
}

fn on_start(me,ctx) {
    let authored=query("QueryUsdPrim",#{path:usd_path(me)+"/Program",attrs:["inputs:verification_mode"]});
    this.verification=authored.attrs["inputs:verification_mode"]==true;
    let tether_config=query("QueryUsdPrim",#{path:ROOT+"/EgressTether",attrs:["inputs:balanced_wrap"]});
    let balanced=tether_config.attrs["inputs:balanced_wrap"];
    if balanced==() || (balanced!=0.0 && balanced!=1.0) {throw("Explicit balanced-wrap mode must be authored as 0.0 or 1.0");}
    this.balanced_sling=balanced>0.5;
    this.egress_requested=this.verification;this.request_pending=false;
    this.disconnect_requested=this.verification;this.disconnect_ready=false;
    this.motion_granted=false;this.brake_clear_since=();
    this.stage="wait_landing";this.started=sim_tick();this.done=false;
    this.failure=();this.failure_reported=false;this.restraint_armed=false;this.impact_ratio=();this.pause_reason=();
    this.arm_since=();this.ground_since=();this.release_since=();
    this.ground_requalify_since=();this.ground_requalifications=0;
    this.requested=false;this.detached_tick=();this.descent_start=();
    this.cut_tick=();
    this.front_transfer_start=();this.front_transfer_base=0.0;this.front_ground_confirmed=false;
    this.ground_wheels_down=false;this.speed_braking=false;this.restraint_lost_since=();this.rear_restraint_brake=false;this.saw_dynamic_support=false;this.brake_probe_done=false;
    this.unlock_seen=false;this.unlock_tick=();this.drive_start=();this.drive_forward=();
    this.drive_done_tick=();this.blocked_after_unlock=0;
    this.max_tension=0.0;this.max_imbalance=0.0;this.min_upright=1.0;this.max_speed=0.0;this.max_descent_speed=0.0;
    this.max_descent_distance=0.0;
    this.descent_progress=0.0;this.descent_progress_tick=();
    this.anchor_x=griffin_compact_egress::datum("tetherAnchorXM");
    this.anchor_y=griffin_compact_egress::datum("tetherAnchorYM");
    this.anchor_z=abs(griffin_compact_egress::datum("trackCentersZM")[0]);
    this.exit_distance=griffin_tether_study::datum("exitDistanceM");
    this.waypoint_radius=griffin_tether_study::datum("waypointRadiusM");
    this.initial_length=griffin_tether_study::datum("initialLengthM");
    this.max_spool_rate=griffin_tether_study::datum("payoutSpeedMps");
    this.preload_rate=griffin_tether_study::datum("preloadRateMps");
    this.target_pretension=griffin_tether_study::datum("targetPretensionN");
    this.minimum_pretension=griffin_tether_study::datum("minimumPretensionN");
    this.restraint_loss_dwell=griffin_tether_study::datum("restraintLossDwellTicks").to_int();
    this.maximum_pretension=griffin_tether_study::datum("maximumPretensionN");
    this.pretension_difference=griffin_tether_study::datum("maximumPretensionDifferenceN");
    this.pretension_dwell=griffin_tether_study::datum("pretensionDwellTicks").to_int();
    this.maximum_arming=griffin_tether_study::datum("maximumArmingTicks").to_int();
    this.maximum_arming_radial_speed=griffin_tether_study::datum("maximumArmingRadialSpeedMps");
    this.post_detach=griffin_tether_study::datum("postDetachSettleTicks").to_int();
    this.minimum_ground_dwell=griffin_tether_study::datum("minimumGroundDwellTicks").to_int();
    this.unload_rate=griffin_tether_study::datum("unloadPayoutSpeedMps");
    this.release_tension=griffin_tether_study::datum("releaseTensionN");
    this.release_energy=griffin_tether_study::datum("releaseElasticEnergyJ");
    this.maximum_line_load=griffin_tether_study::datum("maximumMissionTensionN");
    this.maximum_line_imbalance=griffin_tether_study::datum("maximumLineTensionDifferenceN");
    this.maximum_descent_speed=griffin_tether_study::datum("maximumDescentSpeedMps");
    this.minimum_upright=griffin_tether_study::datum("minimumUprightCos");
    this.maximum_distance=griffin_tether_study::datum("maximumDriveDistanceM");
    this.minimum_unlock_distance=griffin_tether_study::datum("minimumUnlockDriveDistanceM");
    this.ground_min=griffin_tether_study::datum("groundedWheelCenterMinM");
    this.ground_max=griffin_tether_study::datum("groundedWheelCenterMaxM");
    this.transfer_speed=griffin_tether_study::datum("groundTransferSpeedMps");
    this.transfer_rate=griffin_tether_study::datum("groundTransferRateRadps");
    this.minimum_descent_progress=griffin_tether_study::datum("minimumDescentProgressM");
    this.minimum_transfer_progress=griffin_tether_study::datum("minimumGroundTransferProgressM");
    this.descent_stall_ticks=griffin_tether_study::datum("descentStallTicks").to_int();
    this.duration=griffin_tether_study::datum("testDurationTicks").to_int();
    this.stiffness=griffin_tether_study::datum("stiffnessNPerM");
    this.maximum_over_center_deg=griffin_tether_study::datum("maximumOverCenterPitchDeg");
    this.maximum_nose_up_deg=griffin_tether_study::datum("maximumNoseUpPitchDeg");
    this.minimum_rail_alignment=griffin_tether_study::datum("minimumRailAlignmentCos");
    this.drive_throttle=griffin_tether_study::datum("driveThrottleLimit");
    this.profile_x=griffin_compact_egress::datum("stationsXM");
    this.profile_y=griffin_compact_egress::datum("heightsYM");
    this.track_end_x=this.profile_x[this.profile_x.len()-1];
    this.minimum_clearance=griffin_tether_study::datum("minimumTrackClearanceM");
    this.transfer_payout=griffin_tether_study::datum("groundTransferPayoutSpeedMps");
    this.transfer_throttle=griffin_tether_study::datum("groundTransferDriveThrottleLimit");
    this.rear_lowering_margin=griffin_tether_study::datum("rearLoweringBrakeMarginM");
    this.rear_brake_pitch_cos=cos(griffin_tether_study::datum("rearBrakePitchDeg")*acos(-1.0)/180.0);
    let dimensions=query("QueryUsdPrim",#{path:ROOT+"/FLIP/Suspension_RL/Wheel_RL",attrs:["radius","height"]}).attrs;
    this.wheel_radius=dimensions["radius"];this.wheel_width=dimensions["height"];
    this.parked_rollback=griffin_compact_egress::datum("maximumParkedRollbackM");
    let front=(world_pos3(find_path(ROOT+"/FLIP/Suspension_FL/Wheel_FL"))
        +world_pos3(find_path(ROOT+"/FLIP/Suspension_FR/Wheel_FR")))*0.5;
    let rear=(world_pos3(find_path(ROOT+"/FLIP/Suspension_RL/Wheel_RL"))
        +world_pos3(find_path(ROOT+"/FLIP/Suspension_RR/Wheel_RR")))*0.5;
    this.half_wheelbase=vlen(front-rear)*0.5;
    this.landed_tick=();
    this.lander=find_path(ROOT+"/Lander");
    this.rover=find_path(ROOT+"/FLIP");
    this.tether=find_path(ROOT+"/EgressTether");
    this.visuals=griffin_tether_visuals::setup();this.visual_error=false;this.visual_requested=false;
    this.validity=find_path(ROOT+"/Lander/ContactValidity");
    subscribe("griffin.contact-validity-exceeded");
    subscribe("simulation-object-paused");
    subscribe_from("griffin_flip_egress_unlocked",find_path(ROOT+"/Scenario"));
    subscribe("griffin_flip_egress_blocked");
    subscribe_from("griffin_flip_tether_motion_granted",find_path(ROOT+"/Scenario"));
    subscribe_from("griffin_flip_tether_egress_requested",find_path(ROOT+"/Scenario"));
    subscribe_from("griffin_flip_tether_disconnect_granted",find_path(ROOT+"/Scenario"));
}

fn on_event(me,event,ctx) {
    if event.name=="griffin_flip_tether_disconnect_granted" && event.source==find_path(ROOT+"/Scenario") {
        this.disconnect_requested=true;
    }
    if event.name=="griffin_flip_tether_egress_requested" && event.source==find_path(ROOT+"/Scenario") {
        // HUD events can arrive on the lifecycle route, where the fixed-step
        // clock is deliberately unavailable. Timestamp in the next BT step.
        if !this.egress_requested {this.request_pending=true;}
    }
    if event.name=="griffin_flip_tether_motion_granted" {
        this.motion_granted=true;
    }
    if event.name=="griffin.contact-validity-exceeded" {
        this.impact_ratio=event.value;
        this.failure="Powered landing exceeded the authored contact-model validity envelope before tether egress";
    }
    if event.name=="simulation-object-paused" && this.failure==() {
        this.pause_reason=event.value;
        this.failure="Lander paused during powered landing before the tether sequence could arm";
    }
    if event.name=="griffin_flip_egress_unlocked" {this.unlock_seen=true;this.unlock_tick=();}
    if event.name=="griffin_flip_egress_blocked" && this.unlock_seen {this.blocked_after_unlock+=1;}
}

fn pause_egress_objects(rover,lander,tether,detail) {
    // The sampled command bridge is not a native connection-graph edge.
    // Pause transport explicitly to include its independent Modelica scope;
    // Scope prims are not valid PauseSimulationObject rigid-body targets.
    let transport=cmd("SetTimeTransport",#{playing:false});
    let results=[];
    for target in [rover,lander] {
        let result=cmd("PauseSimulationObject",#{target:target,condition:"griffin:egress-fault",detail:detail});
        results.push(result);
    }
    #{transport:transport,bodies:results}
}

fn on_stop(me,ctx) {
    if this.done==true || this.restraint_armed!=true || this.cut_tick!=() {return;}
    if find_path(ROOT+"/FLIP")<0 || find_path(ROOT+"/Lander")<0 {return;}
    griffin_controls::hold_rover_brake();
    pause_egress_objects(this.rover,this.lander,this.tether,"Automatic tether egress was stopped before release; reset the scene before retrying.");
}

fn task(me,ctx) {
    wait_until(|m| {this.advance_egress(m,ctx);this.done})
}

fn advance_egress(me,ctx) {
    try {this.step_egress(me,ctx);} catch(error) {
        this.failure="Tether egress controller error: "+error.to_string();
        if !this.verification {cmd("SetTimeTransport",#{playing:false});}
        this.step_egress(me,ctx);
    }
}

fn refresh_visuals(geometry) {
    if this.visuals.len()!=2 || this.cut_tick!=() || sim_tick()%3!=0 {return;}
    try {
        // Each snapshot must publish before another supersedes it. Physics can
        // run several fixed steps per render frame; a tick-only throttle would
        // continually invalidate the asynchronous renderer's pending result.
        if this.visual_requested && !griffin_tether_visuals::ready(this.visuals) {return;}
        let result=griffin_tether_visuals::update(this.visuals,geometry,read_tether(this.tether),this.lander);
        if result.ok!=true {
            if !this.visual_error {emit("griffin_tether_visual_error",result);}
            this.visual_error=true;
        } else {this.visual_error=false;if result.rendered {this.visual_requested=true;}}
    } catch(error) {
        if !this.visual_error {emit("griffin_tether_visual_error",error.to_string());}
        this.visual_error=true;
    }
}

fn step_egress(me,ctx) {
    if this.done {return;}
    if this.request_pending {
        this.started=sim_tick();this.egress_requested=true;this.request_pending=false;
    }
    if this.unlock_seen && this.unlock_tick==() {this.unlock_tick=sim_tick();}
    if this.failure!=() {
        let safe_hold=if this.cut_tick!=() {#{ok:true,state:"tethers already cut"}}
        else if !this.restraint_armed {#{ok:find_path(ROOT+"/FLIPPayloadAdapterJoint")>=0,state:"unarmed restraint remains disabled"}}
        else if this.tether>=0 && this.rover>=0 && this.lander>=0 {
            safe_hold_tether(this.tether,this.rover,this.lander,this.anchor_x,this.anchor_y,this.anchor_z)
        } else {#{ok:false,error:"Tether or body path is unavailable"}};
        if this.rover>=0 {
            cmd("SimulateIntent",#{intent:"forward",held:false,target:this.rover});
            cmd("SimulateIntent",#{intent:"backward",held:false,target:this.rover});
        }
        let brake=griffin_controls::hold_rover_brake();
        if this.restraint_armed && this.cut_tick==() {
            try {set_egress_brakes([1.0,1.0],1.0);} catch(error) {
                this.failure+="; rear brake request failed during stop: "+error.to_string();
            }
        }
        if !this.verification {
            let paused=pause_egress_objects(this.rover,this.lander,this.tether,this.failure);
            emit("griffin_flip_egress_fault",#{reason:this.failure,stage:this.stage,tether_hold:safe_hold,brake:brake,paused:paused});
            notify_kind("FLIP egress stopped: "+this.failure+" Reset the scene before retrying.","error");
            this.failure_reported=true;this.stage="fault_hold";this.done=true;
            return;
        }
        this.done=true;
        report_structured_verdict(#{ok:false,verdict:"fail",check_count:1,pass_count:0,failure_count:1,non_pass_count:1,
            failures:[this.failure],metrics:#{stage:this.stage,tick:sim_tick(),impact_ratio:this.impact_ratio,
              pause_reason:this.pause_reason,safe_tether_hold:safe_hold,parking_brake:brake,
              mission_unlock_seen:this.unlock_seen,
              scope:"Controlled egress stopped; the stage and mission unlock state identify the completed boundary"}},
            "GRIFFIN CONTROLLED TETHER EGRESS","GRIFFIN_TETHER_DESCENT");
        return;
    }
    if this.tether<0 || this.lander<0 || this.rover<0 {
        this.failure="Tether study fixture is incomplete";return;
    }
    if this.stage=="wait_landing" {
        if this.visuals.len()==2 && sim_tick()%6==0 {
            this.refresh_visuals(input_geometry(this.rover,this.lander,this.anchor_x,this.anchor_y,this.anchor_z,this));
        }
        if !this.egress_requested {return;}
        let landing=griffin_surface_ops::landed_status();
        if landing.landed!=true {
            if sim_tick()-this.started>this.duration {this.failure="No valid landed state was reached before the study timeout";}
            return;
        }
        let held=griffin_controls::hold_rover_brake();
        if this.verification && !this.brake_probe_done {check_rear_brake_admission();this.brake_probe_done=true;}
        if held==() || held.ok!=true {this.failure="Parking brake could not be confirmed before tether arming";return;}
        if find_path(ROOT+"/FLIPPayloadAdapterJoint")<0 {
            this.failure="FLIP adapter was absent before pretension qualification";return;
        }
        if this.landed_tick==() {this.landed_tick=sim_tick();}
        let preflight=input_geometry(this.rover,this.lander,this.anchor_x,this.anchor_y,this.anchor_z,this);
        write_tether(this.tether,preflight,0.0,0.0,0.0,this.rover,this.lander);
        let before=read_tether(this.tether);
        let actual_initial_length=min(before.length0,before.length1);
        this.initial_length=actual_initial_length;
        let span0=geometry_span(preflight,0);let span1=geometry_span(preflight,1);
        let extension0=max(0.0,span0-actual_initial_length);let extension1=max(0.0,span1-actual_initial_length);
        let max_preload_extension=this.maximum_pretension/this.stiffness;
        if extension0>max_preload_extension || extension1>max_preload_extension {
            this.failure="Measured mounted tether span would exceed the preload force bound; tether remains disabled and FLIP stays docked";return;
        }
        if abs(geometry_rate(preflight,0))>this.maximum_arming_radial_speed
            || abs(geometry_rate(preflight,1))>this.maximum_arming_radial_speed {
            if sim_tick()-this.landed_tick>this.maximum_arming {
                this.failure="Mounted tether geometry did not settle to the low-speed arming envelope";
            }
            return;
        }
        this.arm_tick=sim_tick();this.stage="arm_pretension";
    }

    let geometry=input_geometry(this.rover,this.lander,this.anchor_x,this.anchor_y,this.anchor_z,this);
    this.refresh_visuals(geometry);
    if this.stage=="arm_pretension" {
        let before=read_tether(this.tether);
        // Modelica continuously reduces take-up as elastic preload is reached.
        // A second sampled relay on total (elastic plus viscous) tension
        // chatters and can qualify a line before its elastic load settles.
        let s0=-this.preload_rate;let s1=-this.preload_rate;
        write_tether(this.tether,geometry,1.0,s0,s1,this.rover,this.lander);
        this.restraint_armed=true;
        let state=read_tether(this.tether);
        let hi=max(state.tension0,state.tension1);let lo=min(state.tension0,state.tension1);
        this.max_tension=max(this.max_tension,hi);this.max_imbalance=max(this.max_imbalance,hi-lo);
        if hi>this.maximum_pretension || abs(hi-lo)>this.pretension_difference {
            this.failure="Pretension exceeded its per-line or balance gate while FLIP was still docked";return;
        }
        if lo>=max(this.minimum_pretension,0.9*this.target_pretension) && hi<=this.maximum_pretension {
            if this.arm_since==() {this.arm_since=sim_tick();}
            if sim_tick()-this.arm_since>=this.pretension_dwell {
                write_tether(this.tether,geometry,1.0,0.0,0.0,this.rover,this.lander);
                emit("griffin_flip_tether_adapter_release_requested");
                this.requested=true;this.stage="detach_settle";
            }
        } else {this.arm_since=();}
        if sim_tick()-this.arm_tick>this.maximum_arming {
            this.failure="Both tether lines did not reach balanced pretension before the arming deadline";
        }
        return;
    }

    let detached=find_path(ROOT+"/FLIPPayloadAdapterJoint")<0;
    if !detached {
        // Keep preload engaged and the brake held while the live joint retires.
        write_tether(this.tether,geometry,1.0,0.0,0.0,this.rover,this.lander);
        griffin_controls::hold_rover_brake();
        if sim_tick()-this.arm_tick>this.maximum_arming+this.post_detach {
            this.failure="Preloaded adapter did not retire within the bounded handoff interval";
        }
        return;
    }
    if this.detached_tick==() {this.detached_tick=sim_tick();this.stage="detach_settle";}

    let state=read_tether(this.tether);
    let hi=max(state.tension0,state.tension1);let lo=min(state.tension0,state.tension1);
    this.max_tension=max(this.max_tension,hi);this.max_imbalance=max(this.max_imbalance,hi-lo);
    let physics=query("QueryPhysicsState",#{id:this.rover});
    let speed=vlen(physics.linear_velocity_mps);let upright=world_up3(this.rover).y;
    this.max_speed=max(this.max_speed,speed);this.min_upright=min(this.min_upright,upright);
    if this.stage=="controlled_descent" {this.max_descent_speed=max(this.max_descent_speed,speed);}
    if hi>this.maximum_line_load || hi-lo>this.maximum_line_imbalance {
        write_tether(this.tether,geometry,1.0,0.0,0.0,this.rover,this.lander);
        griffin_controls::hold_rover_brake();
        this.failure="A descent line exceeded the modeled load or imbalance gate: "+#{stage:this.stage,tension0:state.tension0,tension1:state.tension1,material_rate0:state.material_rate0,material_rate1:state.material_rate1,paid0:state.paid_rate0,paid1:state.paid_rate1,extension0:state.extension0,extension1:state.extension1,speed:speed};return;
    }
    if this.stage=="detach_settle" {
        griffin_controls::hold_rover_brake();
        // Hold both spool coordinates while adapter/contact transients settle.
        write_tether(this.tether,geometry,1.0,0.0,0.0,this.rover,this.lander);
        if sim_tick()-this.detached_tick<this.post_detach {return;}
        this.descent_start=world_pos3(this.rover);
        let ramp=find_path(ROOT+"/Lander/CompactEgress");
        let axis=qrot(world_rotation_quat(ramp),vec3(-1.0,0.0,0.0));
        this.descent_axis=vec3_array(axis);
        let target=this.descent_start+axis*this.exit_distance;
        let ground=terrain_height(target.x,target.z);
        if ground==() {this.failure="No terrain elevation is available at the controlled transfer target";return;}
        this.target=[target.x,ground,target.z];
        let ground_local=qrot(quat_inverse(world_rotation_quat(ramp)),vec3_from(this.target)-world_pos3(ramp));
        let xs=this.profile_x;let ys=this.profile_y;xs.push(ground_local.x);ys.push(ground_local.y);
        let path=rail_center_path(xs,ys,this.wheel_radius);this.rail_x=path.x;this.rail_y=path.y;
        let released=griffin_controls::release_rover_brake();
        if released==() || released.ok!=true {this.failure="Parking brake release was rejected after tethered adapter clearance";return;}
        emit("griffin_flip_tether_motion_requested");
        this.motion_requested_tick=sim_tick();this.stage="await_motion_authority";
        return;
    }

    if this.stage=="await_motion_authority" {
        write_tether(this.tether,geometry,1.0,0.0,0.0,this.rover,this.lander);
        let brake=1.0;
        for port in read_ports(this.rover,["brake"]).ports {
            if port.direction=="out" && port.name=="brake" {brake=port.value;}
        }
        if brake>0.5 || !this.motion_granted {
            this.brake_clear_since=();
            if sim_tick()-this.motion_requested_tick>60 {this.failure="Mission did not release its native brake hold for tethered motion";}
            return;
        }
        if this.brake_clear_since==() {this.brake_clear_since=sim_tick();}
        if sim_tick()-this.brake_clear_since<3 {return;}
        // Neutral manual stick levels also retain control priority. Retire
        // those levels once, after the mission's explicit motion grant, so
        // this program can own straight drive. New operator edges still win.
        for name in ["throttle","steer"] {
            let released=cmd("ReleasePort",#{target:this.rover,name:name});
            if released==() || released.ok!=true {this.failure="Drive input handoff was rejected";return;}
        }
        this.descent_start=world_pos3(this.rover);
        this.rail_start=rail_progress(this);
        this.descent_progress=0.0;this.descent_progress_tick=sim_tick();
        this.stage="controlled_descent";
    }

    let rover_position=world_pos3(this.rover);
    let along=vdot(rover_position-this.descent_start,this.descent_axis);
    let drop=max(0.0,this.descent_start.y-rover_position.y);
    let progress=rail_progress(this)-this.rail_start;
    this.max_descent_distance=max(this.max_descent_distance,along);
    let transfer=griffin_controls::compact_rover_transfer_status(this);
    if transfer.wheel_count==() {this.failure=transfer.reason;return;}
    if transfer.front_count==2 {this.front_ground_confirmed=true;}
    let front_can_catch=transfer.front_count==2 || (transfer.front_supported==[true,true]
        && transfer.front_toe_clearance_m>=0.0);
    if front_can_catch && this.front_transfer_start==() {
        this.front_transfer_start=vec3_from(transfer.front_center_m);
        this.front_transfer_base=progress;
        this.descent_progress_tick=sim_tick();
    }
    // This is a measured mechanical handoff, not a per-sample mode switch.
    // Brief unloading while rolling off the toe cannot return to deck pose
    // control, which would pull the front axle back before terrain touchdown.
    front_can_catch=this.front_transfer_start!=();
    if this.front_transfer_start!=() {
        let horizontal=vec3(this.descent_axis[0],0.0,this.descent_axis[2]);
        horizontal=horizontal*(1.0/vlen(horizontal));
        // After loaded toe or terrain contact the rear axle can remain at its
        // restraint while the front axle rolls out and the chassis uprights.
        progress=max(progress,this.front_transfer_base+
            vdot(vec3_from(transfer.front_center_m)-this.front_transfer_start,horizontal));
    }
    if this.stage=="controlled_descent" || this.stage=="ground_unload" {
        if min(state.tension0,state.tension1)<this.minimum_pretension && transfer.rear_supported_count<2 {
            if this.restraint_lost_since==() {this.restraint_lost_since=sim_tick();}
            if sim_tick()-this.restraint_lost_since+1>=this.restraint_loss_dwell {
                this.failure="Unsupported rear axle lost minimum tether restraint: "+#{tension0:state.tension0,tension1:state.tension1,transfer:transfer};return;
            }
        } else {this.restraint_lost_since=();}
    }
    if this.stage=="controlled_descent" {
        if is_controlled(this.rover) {
            this.failure="Operator took control during automatic tether egress; restraint and parking hold retained";return;
        }
        if transfer.rear_supported_count==2 && transfer.fixed_count<2 {this.saw_dynamic_support=true;}
        if !this.ground_wheels_down && transfer.mechanically_stable {
            this.ground_wheels_down=true;
            this.descent_progress=progress;this.descent_progress_tick=sim_tick();
        }
        let attitude=rail_attitude(this.rover,this.descent_axis,this);
        if speed>this.maximum_descent_speed || attitude.ok!=true {
            this.envelope_failure=#{speed_mps:speed,attitude:attitude};
            write_tether(this.tether,geometry,1.0,0.0,0.0,this.rover,this.lander);
            griffin_controls::hold_rover_brake();
            this.failure="Rover speed or attitude left the controlled tether-descent envelope: "+this.envelope_failure;return;
        }
        if along>this.maximum_distance+0.10 {
            write_tether(this.tether,geometry,1.0,0.0,0.0,this.rover,this.lander);
            griffin_controls::hold_rover_brake();
            this.failure="Controlled descent exceeded its maximum transfer distance";return;
        }
        let minimum_progress=if (this.front_transfer_start!=() || upright<=this.rear_brake_pitch_cos) && !this.ground_wheels_down {
            this.minimum_transfer_progress
        }else{this.minimum_descent_progress};
        if progress>=this.descent_progress+minimum_progress {
            this.descent_progress=progress;this.descent_progress_tick=sim_tick();
        }
        let velocity=vec3_from(physics.linear_velocity_mps);
        let direction=vec3(this.descent_axis[0],0.0,this.descent_axis[2]);
        direction=direction*(1.0/vlen(direction));
        let upright_motion=if this.front_transfer_start!=() {
            vdot(vec3_from(physics.angular_velocity_radps),vcross(direction,vec3(0.0,1.0,0.0)))*this.half_wheelbase
        }else{0.0};
        let motion=max(vdot(velocity,direction),max(-velocity.y,upright_motion));
        let minimum_motion=minimum_progress/(this.descent_stall_ticks.to_float()*dt());
        // A restrained body can rebound slightly during wheel-down. Motion
        // toward the next physical handoff is not a stationary stall merely
        // because its configuration has not surpassed the previous peak.
        if motion>=minimum_motion {
            this.descent_progress=progress;this.descent_progress_tick=sim_tick();
        }
        if sim_tick()-this.descent_progress_tick>=this.descent_stall_ticks {
            this.failure="Tethered descent made no measurable progress before the stall deadline";return;
        }
        let speed_gate=state.drive_scale;
        let lowering_rear=this.front_transfer_start!=() && !this.ground_wheels_down;
        if !this.balanced_sling && !this.ground_wheels_down && (upright<=this.rear_brake_pitch_cos
            || (lowering_rear && transfer.track_clearance_m>=-this.rear_lowering_margin)) {
            this.rear_restraint_brake=true;
        }
        if this.ground_wheels_down {this.rear_restraint_brake=false;}
        // Avoid storing front-wheel spin while unloaded and later dumping its
        // angular momentum into chassis pitch through the vehicle brake.
        let front_brakes=[];
        for supported in transfer.front_supported {front_brakes.push(if supported {0.0}else{1.0});}
        set_egress_brakes(front_brakes,if this.rear_restraint_brake {1.0}else{0.0});
        let nose_down_rate=0.0;
        for row in geometry {if row[0]=="nose_down_rate" {nose_down_rate=row[1];}}
        let upright_braking=lowering_rear && front_can_catch && nose_down_rate<=0.0;
        if speed>this.transfer_speed || (upright_braking && transfer.angular_speed_radps>this.transfer_rate) {this.speed_braking=true;}
        else if speed<this.transfer_speed*0.6 && (!upright_braking || transfer.angular_speed_radps<this.transfer_rate*0.6) {this.speed_braking=false;}
        let brake_command=if this.speed_braking {1.0}else{0.0};
        let throttle=if lowering_rear && front_can_catch {this.transfer_throttle}else{this.drive_throttle};
        // Ideal controlled payout is a study actuator. The cylindrical wrap
        // and wheel rotation remain in the line material-speed balance.
        let spool_rate=if lowering_rear {this.transfer_payout}else{this.max_spool_rate};
        // The tracks define the travel direction. Waypoint yaw is singular
        // near vertical and must not request a skid pivot on these rails.
        let c=cmd("SetPorts",#{target:this.rover,writes:[["program_active",1.0],["autopilot_enable",0.0],
            ["throttle",if this.speed_braking {0.0}else{throttle*speed_gate}],["steer",0.0],["brake",brake_command]]});
        if c==() || c.ok!=true {this.failure="Controlled-descent guidance command was rejected";return;}
        write_tether(this.tether,geometry,1.0,spool_rate,spool_rate,
            this.rover,this.lander,1.0,speed,if lowering_rear && front_can_catch {1.0}else{0.0},
            if this.front_ground_confirmed {1.0}else{0.0});
        if transfer.ok==true && transfer.track_clearance_m>=this.minimum_clearance+this.parked_rollback {
            griffin_controls::hold_rover_brake();
            let stop=cmd("SetPorts",#{target:this.rover,writes:[["program_active",0.0],
                ["autopilot_enable",0.0],["throttle",0.0],["steer",0.0],["brake",1.0]]});
            if stop==() || stop.ok!=true {this.failure="Ground-transfer hold was rejected";return;}
            this.ground_since=sim_tick();this.stage="ground_unload";
        }
    } else if this.stage=="ground_unload" {
        let held=griffin_controls::hold_rover_brake();
        if held==() || held.ok!=true {this.failure="Ground unloading parking hold was rejected";return;}
        if is_controlled(this.rover) || speed>this.maximum_descent_speed
            || rail_attitude(this.rover,this.descent_axis,this).ok!=true {
            this.failure="Operator takeover or descent-envelope violation during ground unloading";return;
        }
        if transfer.ok!=true {
            if this.disconnect_ready {
                this.disconnect_ready=false;
                emit("griffin_flip_tethers_requalifying");
            }
            // Wheel-down can briefly unload a tire or rebound across the
            // stable-motion threshold. Retain restraint and parking, stop
            // payout, and restart BOTH continuous qualification dwells.
            // A persistent loss still stops the deployment; never cut on
            // stale support or merely accumulated good samples.
            set_egress_brakes([1.0,1.0],1.0);
            write_tether(this.tether,geometry,1.0,0.0,0.0,this.rover,this.lander);
            this.ground_since=sim_tick();this.release_since=();
            if this.ground_requalify_since==() {
                this.ground_requalify_since=sim_tick();this.ground_requalifications+=1;
                emit("griffin_flip_egress_requalifying",#{transfer:transfer,restraint_retained:true});
            }
            if sim_tick()-this.ground_requalify_since>=this.minimum_ground_dwell {
                this.failure="Ground support, clearance or stability did not recover within the bounded unloading hold; restraint retained";
            }
            return;
        }
        this.ground_requalify_since=();
        write_tether(this.tether,geometry,1.0,this.unload_rate,this.unload_rate,this.rover,this.lander);
        let unloaded=state.tension0<=this.release_tension && state.tension1<=this.release_tension
            && state.elastic_energy<=this.release_energy;
        if unloaded {
            if this.release_since==() {this.release_since=sim_tick();}
        } else {
            this.release_since=();
            if this.disconnect_ready {this.disconnect_ready=false;emit("griffin_flip_tethers_requalifying");}
        }
        if this.release_since!=() && sim_tick()-this.ground_since>=this.minimum_ground_dwell
            && sim_tick()-this.release_since>=30 {
            if !this.disconnect_ready {
                this.disconnect_ready=true;
                emit("griffin_flip_tethers_ready_to_disconnect");
            }
            if this.disconnect_requested {
                write_tether(this.tether,geometry,0.0,0.0,0.0,this.rover,this.lander);
                release_tether_wrenches(this.rover,this.lander);
                griffin_tether_visuals::clear(this.visuals);
                this.stage="verify_cut";this.cut_tick=sim_tick();
            }
        }
    } else if this.stage=="verify_cut" {
        griffin_controls::hold_rover_brake();
        let cut=read_tether(this.tether);
        let restraint=griffin_controls::compact_tether_release_status();
        if restraint.ok==true && transfer.ok==true {
            emit("griffin_flip_egress_restraint_released",#{tether:cut,transfer:transfer,
                maximum_tension_n:this.max_tension,maximum_imbalance_n:this.max_imbalance});
            this.stage="await_unlock";this.unlock_requested_tick=sim_tick();return;
        }
        if sim_tick()-this.cut_tick>10 {this.failure="Cut tether telemetry did not settle to zero load";return;}
    } else if this.stage=="await_unlock" {
        if !this.unlock_seen {
            if sim_tick()-this.unlock_requested_tick>60 {
                this.failure="Mission did not confirm the grounded restraint-release handoff";
            }
            return;
        }
        let released=griffin_controls::release_rover_brake();
        if released==() || released.ok!=true {this.failure="Observer could not retire its ground-transfer brake hold";return;}
        if !this.verification {
            this.done=true;
            emit("griffin_flip_egress_complete",#{maximum_tension_n:this.max_tension,
                maximum_speed_mps:this.max_speed,descent_distance_m:this.max_descent_distance,
                ground_requalifications:this.ground_requalifications});
            griffin_controls::show_hint("FLIP egress complete. Tethers released; manual drive enabled.");
            return;
        }
        this.drive_start=world_pos3(this.rover);
        this.drive_forward=vec3_array(qrot(world_rotation_quat(this.rover),vec3(0.0,0.0,-1.0)));
        let drive=cmd("SimulateIntent",#{intent:"forward",held:true,target:this.rover});
        if drive==() || drive.ok!=true {this.failure="Post-egress operator drive request was rejected";return;}
        this.stage="verify_manual_drive";
    } else if this.stage=="verify_manual_drive" {
        let displacement=vdot(world_pos3(this.rover)-this.drive_start,this.drive_forward);
        if displacement>=this.minimum_unlock_distance || displacement>=0.20 {
            cmd("SimulateIntent",#{intent:"forward",held:false,target:this.rover});
            griffin_controls::hold_rover_brake();
            this.drive_done_tick=sim_tick();this.drive_distance=displacement;this.stage="finish";
        } else if sim_tick()-this.unlock_tick>300 {
            cmd("SimulateIntent",#{intent:"forward",held:false,target:this.rover});
            this.failure="Drive remained locked after the restraint and ground-transfer gates";return;
        }
    } else if this.stage=="finish" && sim_tick()-this.drive_done_tick>=30 {
        let failures=[];
        if !this.unlock_seen {failures.push("Mission did not emit the qualified egress unlock event");}
        if this.blocked_after_unlock!=0 {failures.push("A drive block was emitted after the qualified unlock");}
        if this.drive_distance<this.minimum_unlock_distance {failures.push("FLIP did not travel the minimum proof distance after unlock");}
        if this.max_tension>this.maximum_line_load {failures.push("Modeled tether load exceeded the per-line operating gate");}
        let final_restraint=griffin_controls::compact_tether_release_status();
        if final_restraint.ok!=true || transfer.ok!=true {failures.push("Final native restraint release or stable fixed-world support was not confirmed");}
        if !this.brake_probe_done {failures.push("Invalid local brake admission was not checked");}
        if !this.saw_dynamic_support || transfer.fixed_count!=4 {failures.push("Wheel telemetry did not distinguish the dynamic lander from fixed ground");}
        this.done=true;
        report_structured_verdict(#{ok:failures.len()==0,verdict:if failures.len()==0{"pass"}else{"fail"},
            check_count:7,pass_count:7-failures.len(),failure_count:failures.len(),failures:failures,
            metrics:#{stage:this.stage,maximum_tension_n:this.max_tension,maximum_imbalance_n:this.max_imbalance,
              maximum_rover_speed_mps:this.max_speed,maximum_controlled_descent_speed_mps:this.max_descent_speed,
              minimum_upright_cos:this.min_upright,ground_requalifications:this.ground_requalifications,
              descent_distance_m:this.max_descent_distance,manual_proof_distance_m:this.drive_distance,
              final_grounded_wheels:transfer.wheel_count,final_fixed_support_wheels:transfer.fixed_count,
              final_track_clearance_m:transfer.track_clearance_m,final_tension0_n:state.tension0,final_tension1_n:state.tension1,
              invalid_local_brake_rejected:this.brake_probe_done,dynamic_support_distinguished:this.saw_dynamic_support,
              scope:"Two reduced balanced rear-wheel bridles apply native wheel resultants and equal/opposite lander reactions; assumed rigging and ideal powered winches, no fabric or attachment failure, no flight qualification"}},
            "GRIFFIN CONTROLLED TETHER EGRESS","GRIFFIN_TETHER_DESCENT");
    }

    if sim_tick()%30==0 {
        emit("griffin_tether_descent_trace",#{tick:sim_tick(),stage:this.stage,
            speed_mps:speed,upright_cos:upright,distance_m:this.max_descent_distance,
            drop_m:drop,progress_m:progress,
            tension0_n:state.tension0,tension1_n:state.tension1,
            length0_m:state.length0,length1_m:state.length1,
            material_rate0_mps:state.material_rate0,material_rate1_mps:state.material_rate1,
            paid_rate0_mps:state.paid_rate0,paid_rate1_mps:state.paid_rate1,
            extension0_m:state.extension0,extension1_m:state.extension1,transfer:transfer});
    }
    if sim_tick()-this.started>this.duration && !this.done && !this.disconnect_ready {
        this.failure="Tethered egress did not complete before its study timeout";
    }
}
