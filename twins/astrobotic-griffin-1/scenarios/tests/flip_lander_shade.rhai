// Exercise the deployed FLIP CAD panel with the flight-body collision assembly
// at the Nobile site. Place the bus across the incident rays at a safe distance
// from the rover, then return it to its clear position.
const ROOT = "/Griffin1SurfaceOps";
const FLIP = ROOT + "/FLIP";
const PROBE = FLIP + "/SolarMechanism/Photovoltaics/Environment";
const BUS = ROOT + "/TestBus";

fn simulation_dependencies(me, ctx) {
    #{ modelica_entities: [find_path(FLIP)], entity_reads: [find_path(PROBE), find_path(FLIP)],
       entity_writes: [find_path(BUS)], query_reads: [], required_inputs: [] }
}

fn on_start(me, ctx) {
    this.probe = find_path(PROBE);
    this.rover = find_path(FLIP);
    this.bus = find_path(BUS);
    this.phase = "clear";
    this.elapsed = 0.0;
    this.done = false;
    this.results = [];
}

fn on_tick(me, ctx) {
    if this.done { return; }
    this.elapsed += dt();
    let visible = get(this.probe, "sun_visibility");
    let available = get(this.rover, "solar_available_power");
    if this.elapsed > 12.0 {
        this.done = true;
        report_verdict(["timed out in " + this.phase + " visibility=" + visible + " available_W=" + available], "FLIP LANDER SHADE", "FLIP_LANDER_SHADE");
        return;
    }
    if this.elapsed < 1.0 { return; }
    if visible == () || available == () { return; }
    if this.phase == "clear" && visible == 1.0 && available > 1.0 {
        let local_sun = vec3(get(this.probe, "sun_mount_x"), get(this.probe, "sun_mount_y"), get(this.probe, "sun_mount_z"));
        let rotation = world_rotation_quat(this.probe);
        let sun = vnorm(qrot(rotation, local_sun));
        let center = world_pos3(this.probe) + qrot(rotation, vec3(-0.7175, 0.022, -0.001));
        // The bus deck is perpendicular to local Y. Its near face covers
        // the complete panel when its normal points along the incident rays.
        let norm = sqrt(2.0 * (1.0 + sun.y));
        let attitude = [sun.z / norm, 0.0, -sun.x / norm, norm * 0.5];
        this.results.push(t_true(visible == 1.0 && available > 1.0, "FLIP initially generates in sunlight"));
        print("[flip-shade] clear visibility=" + visible + " available_W=" + available);
        cmd("TransformEntity", #{ entity_id: this.bus, translation: vec3_array(center + sun * 8.0), rotation: attitude });
        this.phase = "blocked";
        this.elapsed = 0.0;
    } else if this.phase == "blocked" && visible == 0.0 && abs(available) < 1.0e-6 {
        this.results.push(t_true(visible == 0.0 && abs(available) < 1.0e-6, "the bus shadows all panel samples and extinguishes generation"));
        print("[flip-shade] behind Griffin bus visibility=" + visible + " available_W=" + available);
        cmd("MoveEntity", #{ entity_id: this.bus, translation: [40.0, 12.0, 40.0] });
        this.phase = "restored";
        this.elapsed = 0.0;
    } else if this.phase == "restored" && visible == 1.0 && available > 1.0 {
        print("[flip-shade] restored visibility=" + visible + " available_W=" + available);
        this.done = true;
        this.results.push(t_true(visible == 1.0 && available > 1.0, "leaving Griffin shade restores available power"));
        report_verdict(this.results, "FLIP LANDER SHADE", "FLIP_LANDER_SHADE");
    }
}
