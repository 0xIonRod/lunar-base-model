// Twin-level entry point for the shared positive bus geometry gate.
// The gate is shared with the Editor tool so tests and live review inspect the
// same composed mesh evidence and typed SysML source.

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let doc_id = -1;
    let docs = query("ListOpenDocuments");
    if docs != () && docs.open_documents != () {
        for item in docs.open_documents {
            if item.kind == "usd" && item.active == true { doc_id = item.doc_id; }
        }
    }
    if doc_id < 0 { return; }
    let result = griffin_bus_verification::verify_bus(doc_id,
        sysml_requirements::source(), griffin_bus_verification::default_root_path());
    print(#{verdict: if result.ok { "PASS" } else { "FAIL" },
        checks: result.check_count, failures: result.failure_count,
        evidence: result.evidence});
    this.done = true;
}
