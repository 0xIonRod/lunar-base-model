// Griffin surface mission ramp commands.
//
// This module owns the SysML-targeted hinge command batches. The mission
// scenario remains the single owner of sequencing, measured settlement, and
// phase state.

fn unfold_event_contract() {
    let middle_commanded = "griffin_ramp_middle_sections_unfold_commanded";
    let middle_settled = "griffin_ramp_middle_sections_unfold_settled";
    let toes_commanded = "griffin_ramp_toes_unfold_commanded";
    let toes_settled = "griffin_ramp_toes_unfold_settled";
    let roots_commanded = "griffin_ramps_deploy_commanded";
    let roots_settled = "griffin_ramp_deployment_settled";
    #{
        middle_commanded: middle_commanded,
        middle_settled: middle_settled,
        toes_commanded: toes_commanded,
        toes_settled: toes_settled,
        roots_commanded: roots_commanded,
        roots_settled: roots_settled,
        ordered: [middle_commanded, middle_settled, toes_commanded,
            toes_settled, roots_commanded, roots_settled]
    }
}

// Break the antipodal half-turn into two measured quarter-turns. A joint
// frame offset alone cannot disambiguate the motor's shortest-path error.
fn _command_section_unfold(stage, target, publish_start) {
    let names=griffin_spec::ramp_intermediate_joint_names();
    let stowed=griffin_spec::physical_ramp_section_stowed_joint_angle_rad();
    let level=griffin_spec::physical_ramp_section_deployment_joint_angle_rad();
    if names.len()!=4 || target==() || stowed==() || level==()
        || (stage!="middle" && stage!="toe") {
        return #{ok:false,error:"ramp section unfold source or stage is invalid"};
    }
    let expected=[];
    let writes=[];
    for index in 0..4 {
        let moving=if stage=="middle" {index%2==0} else {index%2==1};
        let held=if stage=="middle" {stowed} else {level};
        let item=#{name:names[index],target_rad:if moving {target} else {held}};
        expected.push(item);
        if moving {writes.push(item);}
    }
    let command=griffin_surface_ops::set_physical_ramp_hinge_angles(writes);
    if command==() || command.ok!=true {
        return #{ok:false,error:"atomic section unfold command was rejected",
            expected_angles:expected,command:command};
    }
    if publish_start {
        emit(if stage=="middle" {unfold_event_contract().middle_commanded}
            else {unfold_event_contract().toes_commanded});
    }
    print("[griffin] "+stage+" section unfold target accepted: "+target.to_string()+" rad");
    #{ok:true,command:command,expected_angles:expected}
}

fn unfold_middle_sections() {
    _command_section_unfold("middle",
        griffin_spec::physical_ramp_section_unfold_waypoint_joint_angle_rad(),true)
}

fn unfold_toes() {
    _command_section_unfold("toe",
        griffin_spec::physical_ramp_section_unfold_waypoint_joint_angle_rad(),true)
}

// The scenario owns state and timing. Return the next expected snapshot
// explicitly; do not try to mutate the caller's Rhai map through a parameter.
fn section_unfold_progress(expected, stage, final_commanded, waypoints) {
    let evidence=griffin_surface_ops::physical_ramp_hinges_settled(expected,0.035);
    if evidence.ok!=true {
        return #{ok:false,error:"section hinge settlement evidence is unavailable",
            evidence:evidence};
    }
    if evidence.settled==true && !final_commanded {
        let next=_command_section_unfold(stage,
            griffin_spec::physical_ramp_section_deployment_joint_angle_rad(),false);
        if next.ok!=true {return next;}
        waypoints.push(#{stage:stage,evidence:evidence});
        return #{ok:true,settled:false,evidence:evidence,
            waypoint_evidence:waypoints,expected_angles:next.expected_angles,
            final_commanded:true};
    }
    #{ok:true,settled:evidence.settled && final_commanded,evidence:evidence,
        waypoint_evidence:waypoints,expected_angles:expected,final_commanded:final_commanded}
}

fn deploy_roots() {
    // Lower the roots only after all intermediate sections reach their
    // source-defined level deployment targets.
    let joints = griffin_spec::ramp_root_joint_names();
    if joints.len() != 2 {
        return #{ok: false, error: "SysML must name both top-deck ramp hinges"};
    }
    let expected = [
        #{name: joints[0], target_rad: griffin_spec::physical_ramp_port_deployment_angle_rad()},
        #{name: joints[1], target_rad: griffin_spec::physical_ramp_starboard_deployment_angle_rad()},
    ];
    let port_angle = expected[0].target_rad;
    let starboard_angle = expected[1].target_rad;
    if port_angle == () || starboard_angle == () {
        return #{ok: false, error: "physical ramp deployment angles are missing from SysML"};
    }
    let command = griffin_surface_ops::set_physical_ramp_hinge_angles(expected);
    if command == () || command.ok != true {
        return #{ok: false, error: "atomic physical ramp deployment command was rejected",
            expected_angles: expected, command: command};
    }
    emit(unfold_event_contract().roots_commanded);
    notify_kind("Griffin solid side ramps are deploying after touchdown.", "info");
    print("[griffin] atomic physical egress ramp angle command accepted");
    #{ok: true, command: command,
        port_angle_rad: port_angle, starboard_angle_rad: starboard_angle}
}

fn root_deployment_angle_expectations() {
    let root_names = griffin_spec::ramp_root_joint_names();
    let port = griffin_spec::physical_ramp_port_deployment_angle_rad();
    let starboard = griffin_spec::physical_ramp_starboard_deployment_angle_rad();
    if root_names.len() != 2 || port == () || starboard == () {
        return ();
    }
    [
        #{name: root_names[0], target_rad: port},
        #{name: root_names[1], target_rad: starboard},
    ]
}
