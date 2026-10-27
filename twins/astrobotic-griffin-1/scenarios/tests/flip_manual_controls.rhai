// Read-only assertions after native InjectWindowInput key press/release.
// The driver owns key delivery and settling; this file never synthesizes input.

fn flip_manual_port(record, name, source) {
    if record == () || record.ok == false || record.ports == () {
        return #{ ok: false, error: "FLIP ReadPorts failed or returned no port rows" };
    }
    let matches = [];
    for row in record.ports {
        if row.name == name && row.direction == "in" && row.metadata != ()
            && row.metadata.source == source {
            matches.push(row);
        }
    }
    if matches.len() != 1 {
        return #{ ok: false, error: name + " requires exactly one inbound "
            + source + " row; found " + matches.len().to_string() };
    }
    let row = matches[0];
    if row.value == () || row.metadata.type != "scalar" || row.metadata.writable != true {
        return #{ ok: false, error: name + " has no writable scalar owner sample" };
    }
    #{ ok: true, value: row.value, source: row.metadata.source }
}

fn flip_manual_assert(label, port_name, expected) {
    let target = find_path("/Griffin1SurfaceOps/FLIP");
    let checks = [t_true(target >= 0, "FLIP manual-control target is missing")];
    let names = ["throttle", "steer", "brake", "autopilot_enable", "program_active"];
    let ports = query("ReadPorts", #{ api_id: target, port_names: names });
    let input = flip_manual_port(ports, port_name, "input surface");
    let throttle = flip_manual_port(ports, "throttle", "input surface");
    let steer = flip_manual_port(ports, "steer", "input surface");
    let brake = flip_manual_port(ports, "brake", "input surface");
    let autopilot = flip_manual_port(ports, "autopilot_enable", "Co-simulation participant");
    let program = flip_manual_port(ports, "program_active", "Co-simulation participant");
    checks.push(t_true(input.ok == true,
        if input.ok == true { "" } else { input.error }));
    checks.push(t_true(input.ok == true && input.value == expected,
        label + ": input owner " + port_name + " does not equal " + expected.to_string()));
    for sample in [#{ name: "throttle", port: throttle },
        #{ name: "steer", port: steer }, #{ name: "brake", port: brake }] {
        let value = if sample.name == port_name { expected } else { 0.0 };
        checks.push(t_true(sample.port.ok == true && sample.port.value == value,
            label + ": " + sample.name + " owner sample is missing or differs from " + value.to_string()));
    }
    checks.push(t_true(target >= 0 && is_controlled(target),
        label + ": FLIP is not possessed by the local controller"));
    checks.push(t_true(autopilot.ok == true,
        if autopilot.ok == true { "" } else { autopilot.error }));
    checks.push(t_true(autopilot.ok == true && autopilot.value == 0.0,
        label + ": autopilot remains enabled"));
    checks.push(t_true(program.ok == true,
        if program.ok == true { "" } else { program.error }));
    checks.push(t_true(program.ok == true && program.value == 0.0,
        label + ": route program remains active"));
    let passed = true;
    for check in checks { if check != "" { passed = false; } }
    print("FLIP_NATIVE_MANUAL sample=" + label + " port=" + port_name
        + " expected=" + expected.to_string() + " input=" + input
        + " autopilot=" + autopilot + " program=" + program);
    report_verdict(checks, "FLIP NATIVE MANUAL " + label, "FLIP_NATIVE_MANUAL");
    if !passed { throw "FLIP native manual assertion failed: " + label; }
    #{ ok: passed, label: label, input: input, autopilot: autopilot, program: program }
}

// Runtime observations for the window driver. Assert motion and measured roll,
// rather than accepting an input port change as proof that the rover moves.
fn flip_motion_snapshot() {
    let target = find_path("/Griffin1SurfaceOps/FLIP");
    let state = query("QueryPhysicsState", #{id:target});
    let wheels = [];
    let forward = ();
    for station in ["FL","FR","RL","RR"] {
        let path = "/Griffin1SurfaceOps/FLIP/Suspension_"+station+"/Wheel_"+station;
        let wheel = find_path(path);
        let physical = get(wheel,"PhysicalWheel") != ();
        let visual = find_path(path + if physical {"/CADVisuals"} else {"/Render"});
        let component = if physical {"PhysicalWheel"} else {"WheelRaycast"};
        let spin = ();let rate=();let axle=();let base=();
        if physical {
            let joint=find_path("/Griffin1SurfaceOps/FLIP/Wheel_"+station+"_Hinge");
            let ports=query("ReadPorts",#{api_id:joint,port_names:["angle","angular_velocity"]});
            spin=();rate=();
            for row in ports.ports {
                if row.direction=="out" && row.name=="angle" {spin=row.value;}
                if row.direction=="out" && row.name=="angular_velocity" {rate=row.value;}
            }
            base=quat_from(get(wheel,"PhysicalWheel.geometry_basis"));
            axle=vec3_array(qrot(quat_from(get(wheel,"PhysicalWheel.axis_rot")),vec3(0.0,1.0,0.0)));
        } else {
            spin=get(wheel,"WheelRaycast.spin_angle");
            rate=get(wheel,"WheelRaycast.spin_velocity");
            axle=vec3_array(get(wheel,"WheelRaycast.axle_axis"));
            base=quat_from(get(wheel,"WheelRaycast.visual_base_rotation"));
        }
        let actual = quat_array(get(visual,"Transform.rotation"));
        if spin==() || rate==() || axle==() || base==() || actual==() {
            throw("FLIP wheel roll observation is unavailable at "+path);
        }
        if forward==() {
            if physical {
                forward=vec3_array(qrot(world_rotation_quat(target),vec3(0.0,0.0,-1.0)));
            } else {
                let up=get(wheel,"WheelRaycast.heading_axis");
                forward=vec3_array(qrot(world_rotation_quat(wheel),vcross(up,vec3_from(axle))));
            }
        }
        let sine = sin(-spin/2.0);
        let expected = quat_array(quat(axle[0]*sine,axle[1]*sine,axle[2]*sine,cos(spin/2.0))*base);
        // Physical roll is the native wheel body's rotation. Its CAD child
        // keeps the authored rest basis; adding spin here would double it.
        if physical {expected=quat_array(base);}
        let dot = 0.0;
        for i in 0..4 {dot+=actual[i]*expected[i];}
        wheels.push(#{station:station,rate:rate,
            angle:spin,rotation_dot:abs(dot),
            bound:get(wheel,component+".visual_entity").to_string()!="None"});
    }
    #{tick:sim_tick(),position:world_pos(target),forward:forward,
      upright:world_up3(target).y,velocity:state.linear_velocity_mps,wheels:wheels}
}

fn flip_motion_assert(before, after, label, direction) {
    let travel = vdot(vsub(after.position,before.position),before.forward)*direction;
    let checks = [t_true(after.tick>before.tick,label+": simulation did not advance"),
        t_true(travel>0.05,label+": signed travel did not exceed the 5 cm observation margin"),
        t_true(after.upright>=0.906307787,label+": exceeded the route test's 25 degree tip margin")];
    for wheel in after.wheels {
        checks.push(t_true(wheel.bound && abs(wheel.rate)>0.1,
            label+": "+wheel.station+" has no measured wheel roll"));
        checks.push(t_true(wheel.rotation_dot>0.9999,
            label+": "+wheel.station+" render root does not follow measured axle roll"));
    }
    report_verdict(checks,"FLIP MOTION "+label,"FLIP_MOTION");
    let passed=true;for check in checks {if check!="" {passed=false;}}
    #{ok:passed,travel_m:travel,before:before,after:after}
}

fn flip_brake_assert(before, after) {
    let initial = vlen(before.velocity);
    let final = vlen(after.velocity);
    let checks = [t_true(after.tick>before.tick,"braking: simulation did not advance"),
        t_true(initial>0.1,"braking: test did not establish moving-wheel momentum"),
        t_true(final<initial && final<0.1,"braking: rover did not stop below 0.1 m/s")];
    report_verdict(checks,"FLIP PHYSICAL STOP","FLIP_MOTION");
    let passed=true;for check in checks {if check!="" {passed=false;}}
    #{ok:passed,initial_speed_mps:initial,final_speed_mps:final}
}
