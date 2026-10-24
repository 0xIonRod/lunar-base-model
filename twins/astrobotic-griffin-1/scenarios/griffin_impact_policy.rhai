// Study validity and physical damage are separate: this model cannot qualify a crash.
import "lunco://scenarios/lander_subsystems.rhai" as lander;

fn simulation_dependencies(me, ctx) {
    let dependencies = lander::simulation_dependencies(me, ctx);
    dependencies.modelica_entities.push(find_path(usd_path(me) + "/ContactValidity"));
    dependencies.entity_reads.push(me);
    dependencies.entity_writes.push(me);
    dependencies.query_reads.push("ReadPorts");
    dependencies
}
fn on_start(me, ctx) {
    for event in ["lander_engine_cutoff", "lander_flight_handoff", "lander_touchdown",
        "lander_low_fuel", "lander_depleted", "griffin.contact-validity-exceeded"] {
        subscribe(event);
    }
}
fn on_event(me, evt, ctx) {
    if evt.name != "griffin.contact-validity-exceeded" {
        lander::on_event(me, evt, ctx);
        return;
    }
    let model = find_path(usd_path(me) + "/ContactValidity");
    if evt.source != model { return; }
    let ports = query("ReadPorts", #{api_id: model, port_names: ["speed_limit_mps"]}).ports;
    if ports.len() != 1 { throw("Griffin contact-model validity limit is unavailable"); }
    let limit = ports[0].value;
    let result = cmd("PauseSimulationObject", #{target: me,
        condition: "griffin:impact-outside-model-validity",
        detail: "Impact normal approach speed=" + (evt.value * limit).to_string()
          + " m/s exceeds the authored contact-model study limit=" + limit.to_string()
          + " m/s at tick " + evt.sim_tick.to_string()
          + ". The complete coupled lander is paused, including Modelica. Impact results beyond this envelope are unqualified; use a lower-speed landing or a suitable impact/absorption model before restarting."});
    if result.ok != true { throw("Griffin impact could not pause its coupled system: " + result); }
}
