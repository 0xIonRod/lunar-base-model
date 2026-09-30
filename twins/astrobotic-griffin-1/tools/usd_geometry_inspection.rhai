// Shared fixed-tick dependency contract for read-only USD geometry gates.
// Scene identity comes from a composed prim, never Editor tab focus.
fn dependencies() {
    #{modelica_entities: [], entity_reads: [], entity_writes: [],
      query_reads: ["AnalyzeSysml", "QueryUsdPrim", "QueryUsdPrims", "ReadActiveTwinContract"], required_inputs: []}
}

fn document_owner(path) {
    let owner = query("QueryUsdPrim", #{path: path});
    if owner == () || owner.error != () || owner.doc_id == () { return (); }
    owner.doc_id
}

// SysML enum names are identifiers; USD purpose tokens are lowercase.
fn purpose_token(value) {
    if sysml_enum_is(value) { return value.literal.to_lower(); }
    if string_is(value) { return value.to_lower(); }
    throw("USD purpose requires a typed enum or token");
}

fn measurement(value, record, detail) {
    if value == () || record == () || record.doc_id == ()
        || record.document_generation == () || record.stage_generation == () {
        return #{provider: "usd", state: "unavailable", detail: detail};
    }
    #{provider: "usd", state: "value", value: value,
        doc_id: record.doc_id, document_generation: record.document_generation,
        stage_generation: record.stage_generation}
}

fn same_snapshot(records) {
    if !array_is(records) || records.len() == 0 { return false; }
    let first = records[0];
    if first.doc_id == () || first.document_generation == () || first.stage_generation == () { return false; }
    for record in records {
        if record.doc_id != first.doc_id || record.document_generation != first.document_generation
            || record.stage_generation != first.stage_generation { return false; }
    }
    true
}

// Accumulate bounded evaluation batches. Publish exactly one terminal verdict
// after all batches, so an early passing batch cannot accept a partial review.
fn record_batch(report, state, done, title, channel) {
    if state == () {
        state = #{ok: true, verdict: "pass", check_count: 0, failure_count: 0,
            error_count: 0, inconclusive_count: 0, unverified_count: 0,
            non_pass_count: 0, pass_count: 0, non_pass_results: [], failures: [],
            source_revision: report.source_revision, verification: report.verification};
    }
    if state.source_revision != report.source_revision {
        throw("Geometry review source changed between evaluation batches");
    }
    for key in ["check_count", "failure_count", "error_count", "inconclusive_count",
        "unverified_count", "non_pass_count", "pass_count"] {
        if report[key] != () { state[key] += report[key]; }
    }
    for failure in report.non_pass_results {
        if state.non_pass_results.len() < 8 { state.non_pass_results.push(failure); }
    }
    state.ok = state.ok && report.ok;
    state.verdict = if state.error_count > 0 { "error" }
        else if state.failure_count > 0 { "fail" }
        else if state.inconclusive_count > 0 { "inconclusive" }
        else if state.unverified_count > 0 { "unverified" } else { "pass" };
    if done { report_structured_verdict(state, title, channel); }
    state
}
