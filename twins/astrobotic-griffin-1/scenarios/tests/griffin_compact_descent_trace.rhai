import "twin://astrobotic-griffin-1/scenarios/griffin_1_surface_ops.rhai" as mission;
const ROOT="/Griffin1SurfaceOps";
fn simulation_dependencies(me,ctx) {mission::simulation_dependencies(me,ctx)}
fn on_start(me,ctx) {this.requested=false;this.detached=();this.drive=();this.done=false;}
fn on_tick(me,ctx) {
    if this.done {return;}
    let rover=find_path(ROOT+"/FLIP");let lander=find_path(ROOT+"/Lander");
    if !this.requested {
        if griffin_surface_ops::landed_status().landed!=true {return;}
        this.requested=true;griffin_surface_ops::on_hud_action("release_rover");return;
    }
    if find_path(ROOT+"/FLIPPayloadAdapterJoint")>=0 {return;}
    if this.detached==() {this.detached=sim_tick();}
    if sim_tick()-this.detached<120 {return;}
    if this.drive==() {this.drive=sim_tick();cmd("SimulateIntent",#{intent:"forward",held:true,target:rover});}
    let elapsed=sim_tick()-this.drive;
    if elapsed%15==0 {
        let origin=world_pos3(lander);let inv=quat_inverse(world_rotation_quat(lander));
        let wheels=[];
        for s in ["FL","FR","RL","RR"] {
            let w=find_path(ROOT+"/FLIP/Suspension_"+s+"/Wheel_"+s);
            wheels.push(#{name:s,lander_local:vec3_array(qrot(inv,world_pos3(w)-origin))});
        }
        let state=query("QueryPhysicsState",#{id:rover});
        emit("griffin_compact_descent_trace",#{tick:sim_tick(),elapsed_ticks:elapsed,
          rover_local:vec3_array(qrot(inv,world_pos3(rover)-origin)),
          forward_local:vec3_array(qrot(inv,qrot(world_rotation_quat(rover),vec3(0.0,0.0,-1.0)))),
          velocity:state.linear_velocity_mps,upright:world_up3(rover).y,wheels:wheels,contacts:state.wheel_contacts});
    }
    if elapsed>=600 {
        cmd("SimulateIntent",#{intent:"forward",held:false,target:rover});this.done=true;
        report_structured_verdict(#{ok:true,verdict:"pass",check_count:1,pass_count:1,failure_count:0,
          metrics:#{scope:"Diagnostic trace only, not descent acceptance",drive_ticks:elapsed}},
          "COMPACT DESCENT TRACE","GRIFFIN_COMPACT_DESCENT_TRACE");
    }
}
