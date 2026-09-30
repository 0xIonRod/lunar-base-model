// Shared fixed-tick dependency contract for read-only USD geometry gates.
// Scene identity comes from a composed prim, never Editor tab focus.
fn dependencies() {
    #{modelica_entities: [], entity_reads: [], entity_writes: [],
      query_reads: ["AnalyzeSysml", "QueryUsdPrim", "QueryUsdPrims"], required_inputs: []}
}

fn document_owner(path) {
    let owner = query("QueryUsdPrim", #{path: path});
    if owner == () || owner.error != () || owner.doc_id == () { return (); }
    owner.doc_id
}
