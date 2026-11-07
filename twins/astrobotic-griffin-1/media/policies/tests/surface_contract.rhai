// Run through the production Rhai bridge with ../runtime_surfaces.rhai loaded.
// Synthetic meter values exercise presentation only; simulation owns real values.
fn film_contract_facts(surface) {
    let outputs = #{solar_power: 200.0, bus_power: -12.0, equipment_power: 50.0,
        battery_soc: 0.5, energy_Battery_wh: 4.0, energy_Battery_returned_wh: 2.0,
        energy_elapsed_s: 125.0, energy_Solar_wh: 7.0, energy_Equipment_wh: 3.0,
        __member_Drivetrain_guidance_throttle: 0.5,
        __member_Drivetrain_guidance_steer: 0.0,
        __member_Drivetrain_guidance_heading_error: 0.0};
    for side in ["FL", "FR", "RL", "RR"] {
        outputs["energy_" + side + "_wh"] = 4.0;
        outputs["energy_" + side + "_returned_wh"] = 1.0;
        outputs["__member_Motor_" + side + "_electrical_power"] = 8.0;
    }
    #{surface_id: surface, available: true, status: "running", simulation_progress: (),
        visibility_mode: "always", control_owner: "local", participants: [#{outputs: outputs}],
        active_name: "film-camera", active_label: "Film camera"}
}
fn verify_film_surface_contract() {
let checks = [];
for row in [#{entry: "power_surface", surface: "film-motor"},
            #{entry: "route_energy_surface", surface: "route-short"},
            #{entry: "route_drive_surface", surface: "energy-blue"},
            #{entry: "route_balance_surface", surface: "route-long"},
            #{entry: "drive_power_surface", surface: "drive-power"},
            #{entry: "route_dual_surface", surface: "energy-amber"}] {
    let project = Fn(row.entry);
    let facts = film_contract_facts(row.surface);
    let ready = project.call(facts);
    checks.push(t_true(ready.visible && type_of(ready.properties) == "map" && ready.properties.len() > 0,
        row.entry + " publishes one complete decision"));
    facts.visibility_mode = "possessed";
    facts.control_owner = "remote";
    let hidden = project.call(facts);
    checks.push(t_true(!hidden.visible && hidden.properties == ready.properties,
        row.entry + " keeps properties while visibility follows authored ownership"));
    facts.available = false;
    facts.simulation_progress = [#{owner: "ModelicaPreparation"}];
    checks.push(t_true(project.call(facts).visible, row.entry + " exposes preparation progress"));
    facts.surface_id = "camera-status";
    let camera = project.call(facts);
    checks.push(t_true(camera.visible && camera.properties.active_name == "film-camera"
        && camera.properties.active_label == "Film camera", row.entry + " retains camera identity"));
}
let power = power_surface(film_contract_facts("film-motor")).properties;
checks.push(t_true(power.label == "Front motor uses" && power.value == "8 W", "motor presentation uses its native meter"));
let solar = power_surface(film_contract_facts("film-solar")).properties;
checks.push(t_true(solar.label == "Solar panel produces" && solar.value == "200 W", "solar presentation uses its native meter"));
let drive = drive_power_surface(film_contract_facts("drive-power")).properties;
checks.push(t_true(drive.motors == "32 W" && drive.battery_label == "Battery supplying", "wheel power and battery direction remain authored"));
let energy = route_energy_surface(film_contract_facts("route-short")).properties;
checks.push(t_true(energy.balance == "+2.0" && energy.used == "15.0", "route presentation retains its energy arithmetic"));
let missing = film_contract_facts("route-short");
missing.participants[0].outputs.remove("energy_FL_wh");
let rejected = false;
try { route_energy_surface(missing); } catch(error) { rejected = error.to_string().contains("missing native meter"); }
checks.push(t_true(rejected, "missing required meters remain visible errors"));
report_verdict(checks, "Film surface contract", "FILM_SURFACE_CONTRACT");

}

fn film_policy_is_current(entry, surface) {
    let facts = film_contract_facts(surface);
    let result = invoke_hook("runtime.ui.surface", [facts]);
    result.ok && result.value == Fn(entry).call(facts)
}
fn verify_film_file_policy(entry, surface) {
    let camera = query("ReadExposures", #{surface: "camera-status"}).surfaces["camera-status"];
    report_verdict([
        t_true(film_policy_is_current(entry, surface), entry + " executes through the installed file-backed hook"),
        t_true(camera.state == "ready" && camera.visible && camera.properties.active_name != ()
            && camera.properties.camera_items == (), "the live consumer uses the complete film camera decision")
    ], "File-backed film policy", "FILM_FILE_POLICY");
}
