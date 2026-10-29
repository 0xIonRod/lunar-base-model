import "twin://astrobotic-griffin-1/scenarios/griffin_1_surface_ops.rhai" as mission;
const ROOT="/Griffin1SurfaceOps";
fn simulation_dependencies(me,ctx) {
    let d=mission::simulation_dependencies(me,ctx);let t=find_path(ROOT+"/EgressTether");
    d.modelica_entities.push(t);d.entity_reads.push(t);d.entity_writes.push(t);d
}
fn on_start(me,ctx) {
    this.requested=false;this.detached=();this.start=();this.descent_target_m=();this.done=false;
    this.grounded_since=();this.released=false;this.max_tension=0.0;this.min_upright=1.0;
    this.anchor_x=griffin_compact_egress::datum("tetherAnchorXM");
    this.anchor_y=griffin_compact_egress::datum("tetherAnchorYM");
    this.anchor_z=abs(griffin_compact_egress::datum("trackCentersZM")[0]);
    this.exit_distance=griffin_tether_study::datum("exitDistanceM");
    this.throttle_limit=griffin_tether_study::datum("driveThrottleLimit");
    this.waypoint_radius=griffin_tether_study::datum("waypointRadiusM");
    this.release_tension=griffin_tether_study::datum("releaseTensionN");
    this.release_energy=griffin_tether_study::datum("releaseElasticEnergyJ");
    this.duration_ticks=griffin_tether_study::datum("testDurationTicks").to_int();
}
fn input_geometry(rover,lander,anchor_x,anchor_y,anchor_z) {
    let rp=query("QueryPhysicsState",#{id:rover});let lp=query("QueryPhysicsState",#{id:lander});
    let rpos=world_pos3(rover);let lpos=world_pos3(lander);
    let rrot=world_rotation_quat(rover);let lrot=world_rotation_quat(lander);
    let rc=rpos+qrot(rrot,vec3_from(rp.center_of_mass_m));
    let lc=lpos+qrot(lrot,vec3_from(lp.center_of_mass_m));
    let rv=vec3_from(rp.linear_velocity_mps);let lv=vec3_from(lp.linear_velocity_mps);
    let rw=vec3_from(rp.angular_velocity_radps);let lw=vec3_from(lp.angular_velocity_radps);
    let writes=[];let index=0;
    // Ideal direct lines attach at the rear-wheel hubs. Fabric wrapping and
    // spool inertia remain outside this reduced study.
    for station in ["RL","RR"] {
        let hub=world_pos3(find_path(ROOT+"/FLIP/Suspension_"+station+"/Wheel_"+station));
        let wheel_local=qrot(quat_inverse(lrot),hub-lpos);
        let side=if wheel_local.z<0.0 {-1.0}else{1.0};
        let anchor=lpos+qrot(lrot,vec3(-anchor_x,anchor_y,side*anchor_z));
        let span=anchor-hub;let distance=vlen(span);let ra=hub-rc;let la=anchor-lc;
        let relative=rv+vcross(rw,ra)-lv-vcross(lw,la);
        writes.push(["rate"+index,-vdot(relative,span)/max(distance,0.000001)]);
        for axis in 0..3 {
            let letter=["x","y","z"][axis];
            writes.push(["span"+index+"_"+letter,vec3_array(span)[axis]]);
            writes.push(["rover_arm"+index+"_"+letter,vec3_array(ra)[axis]]);
            writes.push(["lander_arm"+index+"_"+letter,vec3_array(la)[axis]]);
        }
        index+=1;
    }
    writes
}
fn on_tick(me,ctx) {
    if this.done {return;}
    let rover=find_path(ROOT+"/FLIP");let lander=find_path(ROOT+"/Lander");let tether=find_path(ROOT+"/EgressTether");
    if !this.requested {
        if griffin_surface_ops::landed_status().landed!=true {return;}
        this.requested=true;griffin_surface_ops::on_hud_action("release_rover");return;
    }
    if find_path(ROOT+"/FLIPPayloadAdapterJoint")>=0 {return;}
    if this.detached==() {this.detached=sim_tick();}
    if sim_tick()-this.detached<120 {return;}
    if this.start==() {
        let ramp=find_path(ROOT+"/Lander/CompactEgress");
        let axis=qrot(world_rotation_quat(ramp),vec3(-1.0,0.0,0.0));
        let target=world_pos3(lander)+axis*this.exit_distance;
        let ground=terrain_height(target.x,target.z);
        if ground==() {throw("No terrain height is available at the descent stop target");}
        this.descent_target_m=[target.x,ground,target.z];
        this.start=sim_tick();
        // Release the mission-owned parking hold through its real drive edge.
        cmd("SimulateIntentEdge",#{target:rover,intent:"forward",edge:"pulse"});
    }
    let writes=input_geometry(rover,lander,this.anchor_x,this.anchor_y,this.anchor_z);
    writes.push(["enabled",if !this.released {1.0}else{0.0}]);
    let applied=cmd("SetPorts",#{target:tether,writes:writes});
    if applied==() || applied.ok!=true {throw("Measured tether geometry was rejected");}
    let elapsed=sim_tick()-this.start;
    let physics=query("QueryPhysicsState",#{id:rover});let pos=world_pos3(rover);
    let up=world_up3(rover).y;this.min_upright=min(this.min_upright,up);
    let speed=vlen(physics.linear_velocity_mps);let wheel_ground=0;
    for s in ["FL","FR","RL","RR"] {
        let w=world_pos3(find_path(ROOT+"/FLIP/Suspension_"+s+"/Wheel_"+s));
        let height=w.y-terrain_height(w.x,w.z);
        if height>0.35 && height<0.58 {wheel_ground+=1;}
    }
    let values=read_ports(tether,["tension0","tension1","length0","length1","elastic_energy","spool_power"]);let state=#{};
    for p in values.ports {if p.direction=="out" {state[p.name]=p.value;}}
    if state.tension0!=() {this.max_tension=max(this.max_tension,max(state.tension0,state.tension1));}
    if wheel_ground==4 && up>0.9 {
        if this.grounded_since==() {this.grounded_since=sim_tick();griffin_controls::hold_rover_brake();}
        if sim_tick()-this.grounded_since>120 && state.tension0<this.release_tension
          && state.tension1<this.release_tension && state.elastic_energy<this.release_energy {this.released=true;}
    } else {
        if this.grounded_since!=() {griffin_controls::release_rover_brake();}
        this.grounded_since=();
        if elapsed%6==0 {
            // Persist only numeric target coordinates across hooks. Modelica
            // remains the continuous owner of waypoint steering and throttle.
            let point=this.descent_target_m;
            let command=cmd("SetPorts",#{target:rover,writes:[
              ["program_active",1.0],["autopilot_enable",1.0],
              ["autopilot_target_x",point[0]],["autopilot_target_z",point[2]],
              ["autopilot_speed",this.throttle_limit],["autopilot_radius",this.waypoint_radius],
              ["autopilot_turn_only",0.0],["throttle",0.0],["steer",0.0],["brake",0.0]]});
            if command.ok!=true {throw("Controlled-descent guidance was rejected");}
        }
    }
    if elapsed%30==0 {emit("griffin_tether_descent_trace",#{elapsed:elapsed,position:vec3_array(pos),
      lander_local:vec3_array(qrot(quat_inverse(world_rotation_quat(lander)),pos-world_pos3(lander))),
      upright:up,speed:speed,wheel_ground:wheel_ground,tether:state});}
    let complete=this.released && wheel_ground==4 && up>0.9 && speed<0.1;
    let timeout=elapsed>this.duration_ticks;
    if complete || timeout || up<0.0 {
        griffin_controls::hold_rover_brake();this.done=true;
        let failures=[];
        if !complete {failures.push("Controlled descent did not reach upright, stationary four-wheel surface transfer");}
        if this.max_tension<=0.0 {failures.push("No measured tether load developed");}
        report_structured_verdict(#{ok:failures.len()==0,verdict:if failures.len()==0{"pass"}else{"fail"},
          check_count:2,pass_count:2-failures.len(),failure_count:failures.len(),failures:failures,
          metrics:#{elapsed_ticks:elapsed,wheel_ground:wheel_ground,upright:up,speed:speed,max_tension_n:this.max_tension,
            released:this.released,scope:"Reduced straight-line payout study coupled to native 3D forces; wheel wrapping not modeled"}},
          "GRIFFIN CONTROLLED TETHER DESCENT","GRIFFIN_TETHER_DESCENT");
    }
}
