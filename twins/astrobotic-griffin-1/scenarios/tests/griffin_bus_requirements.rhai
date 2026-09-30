// Twin-level entry point for the shared positive bus geometry gate.
// The gate is shared with the Editor tool so tests and live review inspect the
// same composed mesh evidence and typed SysML source.
import "twin://astrobotic-griffin-1/tools/usd_geometry_inspection.rhai" as usd_geometry_inspection;

fn simulation_dependencies(me, ctx) {
    usd_geometry_inspection::dependencies()
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
    this.next_check = 0;
    this.report = ();
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    // Resolve the owner from the tested composed prim, independent of Editor
    // tab focus. Headless fixtures have no active Editor document.
    let doc_id = usd_geometry_inspection::document_owner(griffin_bus_verification::default_root_path());
    if doc_id == () { return; }
    let source = sysml_requirements::source_with_selection([
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::verificationToleranceM",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::geometryVerificationToleranceM",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::appearanceVerificationTolerance",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::doubleSidedFacesMustBe",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::renderOnlyCollisionEnabled",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::renderPurpose",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::bodyDimensions",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::bodySkinThicknessM",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::bodySkinEdgeMarginM",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::bodySkinDisplayColor",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::bodySideFaceAspectRatio",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::bodySideFaceAspectRatioTolerance",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::railDimensions",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::railStations",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::frameRingCenterY",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::deckDimensions",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::deckCenter",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::lowerSkirtDimensions",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::lowerSkirtCenter",
        "GriffinTankRequirements::GriffinPropellantTankAssembly::bandRadiusByCenterM",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::minimumTankFrameClearanceM"
    ], [
        "GriffinBusRequirements::gbc001", "GriffinBusRequirements::gbc002",
        "GriffinBusRequirements::gbc003", "GriffinBusRequirements::gbc004",
        "GriffinBusRequirements::gbc005", "GriffinBusRequirements::gbc006",
        "GriffinBusRequirements::gbc007", "GriffinBusRequirements::gbc008",
        "GriffinBusRequirements::gbc009", "GriffinBusRequirements::gbc010",
        "GriffinBusRequirements::gbc011", "GriffinBusRequirements::gbc012"
    ], ["GriffinBusRequirements::Verify_GriffinBusRequirements"]);
    let checks = griffin_bus_verification::bus_checks(doc_id,
        source, griffin_bus_verification::default_root_path());
    for i in 0..checks.len() { checks[i].doc_id = doc_id; }
    let batch = [];
    let end = if this.next_check + 16 < checks.len() { this.next_check + 16 } else { checks.len() };
    for i in this.next_check..end { batch.push(checks[i]); }
    let result = sysml_requirements::evaluate_stream(source, batch,
        "GRIFFIN_BUS_REQUIREMENTS", "GRIFFIN BUS REQUIREMENTS");
    this.next_check = end;
    this.done = end == checks.len();
    this.report = usd_geometry_inspection::record_batch(result, this.report,
        this.done, "GRIFFIN BUS REQUIREMENTS", "GRIFFIN_BUS_REQUIREMENTS");
}
