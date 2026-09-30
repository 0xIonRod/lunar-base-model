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

fn unfold_middle_sections() {
    // Keep the root decks in their transport pose while unfolding the middle
    // sections. Leave the toe sections stowed until the middle sections settle.
    let angle = griffin_spec::physical_ramp_section_deployment_joint_angle_rad();
    let toe_stowed = griffin_spec::physical_ramp_section_stowed_joint_angle_rad();
    let names = griffin_spec::ramp_intermediate_joint_names();
    if angle == () || toe_stowed == () || names.len() != 4 {
        return #{ok: false, error: "SysML must name all four physical ramp-section hinges"};
    }
    let expected = [
        #{name: names[0], target_rad: angle},
        #{name: names[1], target_rad: toe_stowed},
        #{name: names[2], target_rad: angle},
        #{name: names[3], target_rad: toe_stowed},
    ];
    let command = griffin_surface_ops::set_physical_ramp_hinge_angles([
        #{name: names[0], target_rad: angle},
        #{name: names[2], target_rad: angle},
    ]);
    if command == () || command.ok != true {
        return #{ok: false, error: "atomic middle-section unfold command was rejected",
            expected_angles: expected, command: command};
    }
    emit(unfold_event_contract().middle_commanded);
    notify_kind("Griffin ramp middle sections are unfolding; the toes remain stowed.", "info");
    print("[griffin] atomic middle-section unfold command accepted; toe sections remain stowed");
    #{ok: true, command: command, angle_rad: angle, expected_angles: expected}
}

fn unfold_toes() {
    // The middle sections are verified straight before the distal hinges move.
    let names = griffin_spec::ramp_intermediate_joint_names();
    let angle = griffin_spec::physical_ramp_section_deployment_joint_angle_rad();
    if names.len() != 4 || angle == () {
        return #{ok: false, error: "SysML must define both ramp toe hinges and their deployed target"};
    }
    let expected = [
        #{name: names[1], target_rad: angle},
        #{name: names[3], target_rad: angle},
    ];
    let command = griffin_surface_ops::set_physical_ramp_hinge_angles(expected);
    if command == () || command.ok != true {
        return #{ok: false, error: "atomic ramp-toe unfold command was rejected",
            expected_angles: expected, command: command};
    }
    emit(unfold_event_contract().toes_commanded);
    print("[griffin] atomic ramp-toe unfold command accepted after middle-section settlement");
    #{ok: true, command: command, expected_angles: section_angle_expectations()}
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

fn section_angle_expectations() {
    let target = griffin_spec::physical_ramp_section_deployment_joint_angle_rad();
    let names = griffin_spec::ramp_intermediate_joint_names();
    if target == () || names.len() != 4 { return (); }
    let expected = [];
    for name in names {
        expected.push(#{name: name, target_rad: target});
    }
    expected
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
