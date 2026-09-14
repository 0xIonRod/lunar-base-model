# Typed Editor authoring procedure

1. Launch the production `luncosim` binary from the main checkout in headful
   mode and open the derived Griffin Editor scene.
2. Use `ListOpenDocuments` and the exact numeric `doc_id`; do not use a title as
   an identifier and do not close/reload the open document during an edit loop.
3. Focus the USD preview and confirm `InspectUsdViewport` reports projection
   readiness before judging a screenshot.
4. Query the affected prims, then create a typed `assembly_edit` or
   `assembly_builder` plan. Use the existing generic tools for transforms,
   schemas, attributes, relationships, add/remove/move, bodies, and joints.
5. Apply one coherent change set, wait for projection, query the affected paths,
   run the focused live contract, and capture a fresh screenshot.
6. Save only after the live contract passes and the change has been visually
   inspected. Saving is an explicit persistence step; it is not implied by an
   in-memory pass.

The procedure forbids direct USDA editing, filesystem mutation of the authored
model, direct ECS mutation, and Rust-specific Griffin fallbacks. If the typed
Editor lacks a required generic operation, record the exact missing operation
as a Rust/tooling gap instead of bypassing the workflow.
