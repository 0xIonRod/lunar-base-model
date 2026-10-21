// Component checkpoint, also usable against an exact inert Editor document.
fn simulation_dependencies(me, ctx) {usd_geometry_inspection::dependencies()}
fn on_start(me, ctx) {
    this.root=if ctx.bus_root==() {griffin_bus_verification::default_root_path()} else {ctx.bus_root};
    this.doc=ctx.doc_id;
    this.started=elapsed_seconds();this.done=false;
}
fn on_tick(me, ctx) {
    if this.done {return;}
    let doc=if this.doc==() {usd_geometry_inspection::document_owner(this.root)} else {this.doc};
    if doc==() {
        if elapsed_seconds()-this.started>10.0 {
            this.done=true;fail_fast("bus document unavailable","GRIFFIN BUS OPEN BAYS","GRIFFIN_BUS_OPEN_BAYS");
        }
        return;
    }
    let source=sysml_requirements::source_with_selection([
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::busStructureInstances",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::frameRails"
    ],["GriffinBusRequirements::gbc009"],["GriffinBusRequirements::Verify_GriffinBusOpenBays"]);
    if source.ok!=true {throw("bus open-bay requirement source unavailable: "+source);}
    this.result=sysml_requirement_checks::finish(source,
        griffin_bus_verification::open_bay_checks(doc,source,this.root),
        "GRIFFIN BUS OPEN BAYS","GRIFFIN_BUS_OPEN_BAYS",this.root,
        "GriffinBusRequirements","Verify_GriffinBusOpenBays");
    this.done=true;
}
