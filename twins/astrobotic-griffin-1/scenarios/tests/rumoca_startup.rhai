// Startup acceptance for the complete Griffin surface-operations Twin.
fn participants() {
    let participants = [];
    for path in ["Lander", "Lander/IMU", "Lander/Altimeter/Model",
                 "Lander/AttitudeReference", "Lander/GNC", "Lander/MainPropulsion",
                 "Lander/AttitudeActuation", "Lander/AttitudePropulsion", "FLIP"] {
        participants.push(find_path("/Griffin1SurfaceOps/" + path));
    }
    participants
}
fn simulation_dependencies(me, ctx) {
    #{modelica_entities: participants(), entity_reads: [], entity_writes: [],
      query_reads: ["CosimStatus"], required_inputs: []}
}
fn on_start(me, ctx) {
    this.elapsed = 0.0; this.done = false;
}
fn on_tick(me, ctx) {
    if this.done { return; }
    this.elapsed += dt();
    if this.elapsed < 1.0 { return; }
    this.done = true;
    let failures = [];
    let status = query("CosimStatus", #{include_values: false, include_entities: false});
    failures.push(t_true(status.synchronization.active_participants.to_float() == 9.0,
        "all nine Modelica participants are active"));
    failures.push(t_true(status.synchronization.shared_clock_participants.to_float() == 9.0,
        "all nine participants share the master clock"));
    failures.push(t_true(status.modelica_step_profile.participants.to_float() == 9.0
        && status.modelica_step_profile.samples.to_float() >= 9.0,
        "every participant committed a real solver step"));
    report_verdict(failures, "GRIFFIN RUMOCA STARTUP", "GRIFFIN_RUMOCA_STARTUP");
}
