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
    let autopilot = flip_manual_port(ports, "autopilot_enable", "Modelica co-simulation component");
    let program = flip_manual_port(ports, "program_active", "Modelica co-simulation component");
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
