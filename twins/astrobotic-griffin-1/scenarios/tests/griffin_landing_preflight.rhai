import "twin://astrobotic-griffin-1/tools/usd_geometry_inspection.rhai" as geometry;

fn simulation_dependencies(me, ctx) {
    let plan = geometry::dependencies();
    plan.query_reads.push("TerrainHeight");
    plan
}

fn on_start(me, ctx) { this.done = false; }

fn on_tick(me, ctx) {
    if this.done { return; }
    this.done = true;
    let lander = "/Griffin1SurfaceOps/Lander";
    let valid = griffin_requirements::landing_setup_geometry_check(
        (), "/Griffin1SurfaceOps/LandingTarget", lander);
    if valid.ok != true {
        report_verdict([valid.error], "GRIFFIN LANDING PREFLIGHT", "GRIFFIN_LANDING_PREFLIGHT");
        return;
    }
    let invalid = griffin_requirements::landing_setup_geometry_check((), lander, lander);
    report_verdict([
        t_true(valid.landing_target.ok && valid.landing_surface.ok,
            "the authored target and retained DEM satisfy the landing datums"),
        t_true(valid.landing_gear.ok && valid.landing_gear.spring_targets_m.len() == 4,
            "all four source-owned spring rest poses pass"),
        t_true(invalid.ok == false && invalid.landing_target.ok == false,
            "an elevated target is rejected by the same source constraint"),
        t_true(valid.source_revision == invalid.source_revision,
            "positive and negative checks use one pinned SysML revision")
    ], "GRIFFIN LANDING PREFLIGHT", "GRIFFIN_LANDING_PREFLIGHT");
}
