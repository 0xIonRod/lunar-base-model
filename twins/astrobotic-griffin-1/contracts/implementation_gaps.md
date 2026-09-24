# Griffin implementation and standards gap review

**Reviewed:** 2026-09-24
**Scope:** Griffin as the active model, FLIP as a separately loaded hosted
vehicle, and the generic Rust/Rhai/Editor capabilities needed to build and
verify the model.

## Finding

The Twin has source-owned parameters, split requirements, a componentized
visual assembly, a separately loaded FLIP asset, a resolved SysML relationship
projection, a bounded executable-constraint slice, and composed USD geometry
queries. It remains an integration study, not a complete Griffin system model.
The largest gaps are requirement coverage and binding workflows over the
resolved graph, complete typed provider provenance, source-to-realization
mapping, and physically qualified mission evidence.

The source contracts are being aligned with OMG SysML v2.0: formal requirement
constraints use requirement-owned `require` memberships; verification cases
place requirement `verify` memberships in `objective` blocks; and a check must
identify the required constraint that produced its verdict. The current
bounded compiler/evaluator does not implement all of SysML/KerML. It must
report unsupported source constructs explicitly rather than treating them as
valid evidence.

Normative references: [OMG SysML v2.0 Language Specification](https://www.omg.org/spec/SysML/2.0/Language/PDF),
[OMG SysML 2.0 documents](https://www.omg.org/spec/SysML/2.0/About-SysML).

## Standards alignment and current mismatches

| Area | Current state | Gap / consequence |
|---|---|---|
| Requirement meaning | Five Griffin domain packages plus separate subsystem packages; several requirements still contain only `doc` text | Valid as textual requirements, but no executable acceptance predicate or requirement-level evidence mapping exists for most of them |
| Formal constraint ownership | Selected constraints now use `require`; Rust projects membership and reusable definition identity; evaluator rejects an unrelated constraint | Constraint usage argument/binding semantics and specialization/redefinition traversal are not implemented; Rhai still supplies parameters by name |
| Verification | Requirement `verify` references are inside `objective` blocks; the Rust projection now carries source-linked `require` membership and the landing-stability case targets new requirement `GR-036` | Many text-only requirements still have no executable constraint; `GR-031` remains a separate process gate, while stability values are owned by `GR-036` |
| Traceability | Twin manifest selects source packages, USD fixtures, scripts, and cases; Rust projects snapshot-scoped element handles, resolved references, typed relationship endpoints, and verification-to-requirement handle links | Coverage evaluation now compares resolved handles. The Twin status/check catalogs remain authored execution metadata, and `twin.toml`, provider selection, and USD query paths remain configuration. Replace duplicate semantic identity/status catalogs with reports derived from typed requirement, verification, realization, and evidence links |
| Units and frames | `lunco-engineering-values` supports dimension-safe conversion from caller-resolved `Unit` values; the constraint IR and observation contracts still carry unit identity as text, while Griffin often relies on SI field-name suffixes | The unit primitive is present but is not wired from SysML unit resolution through IR type checking and provider values. Names and comments do not prevent dimensional mistakes; frame identity and conversion provenance also need typed contracts |
| Geometry | Profiles, station vectors, counts, typed source handles, resolved SysML relationships, composed USD queries, and exact Mesh/Cube collider points exist | No complete semantic part-usage graph binds every source feature to a USD realization. NURBS patches are tessellated for rendering, but the physics adapter does not cook them into standard USD Mesh collision proxies |
| Behavioral applicability | Mission order, sampling horizon, route phases, and release are mostly Rhai orchestration | The model cannot yet state and evaluate configuration, mode, phase, or temporal applicability as part of a reusable source-defined verification objective |
| Modelica relationship | Continuous models and parameters are selected through Twin tooling | No complete standard realization/parameter provenance graph ties each equation set and result back to the source feature and requirement revision |

SysML allows informal requirement documentation; prose is not itself a
standards violation. The mismatch is claiming implementation or verification
coverage where that prose has not been connected to a resolved predicate,
realized feature, and evidence result.

## Workarounds found

These mechanisms are currently useful migration scaffolding. They must not
become Griffin's permanent source semantics.

- `griffin_spec.rhai` contains a hand-maintained qualified-name ownership map.
  It avoids ambiguous short-name lookup, but it duplicates semantic navigation
  that should come from resolved feature handles.
- Component scripts pass parallel station/name/measurement arrays and compute
  cardinality, clearances, extrema, symmetry, and mesh face counts. A missed
  index or filtering branch can detach evidence from its source feature.
- USD path literals and child-name lists stand in for typed part usages and
  provider bindings. Moving a prim can invalidate verification without a
  compiler finding the affected relationship.
- Several geometric predicates are authored in Rhai even when their bounds
  now live in SysML. This includes mesh topology, layout, frame transforms,
  source-to-USD cardinality, and portions of landing telemetry acceptance.
- Length, angle, mass, and time fields use `Real` plus naming conventions;
  frame axes/origins are strings or comments. This is vulnerable to unit/frame
  errors and does not support safe conversion.
- Some missing runtime data is converted into sentinel values or a local
  Boolean check. Every missing, stale, malformed, or out-of-frame observation
  must instead keep its state (`unavailable`, `invalid`, or `stale`) and produce
  an explicit inconclusive/error result.
- Visual and flight geometry are separate assets, which is a sound ownership
  boundary, but their correspondence is not yet generated or proved from one
  typed feature mapping. The octagonal visual deck and central octagonal tank
  support are source-owned. Editor has migrated the physical deck to eight
  octagonal perimeter colliders plus a separate payload-deck collider, with
  composed readback confirming the source profile and clear tank opening. The
  GRR-012 composed-collider observation path exists; ramp transition changes
  and fresh port/starboard Editor readback remain pending.
- Twin verification observers bind authored requirements to composed source
  and USD observations. The generic evaluator owns requirement membership,
  constraint evaluation, and verdict classification; observers supply the
  component-specific measurements that the shared provider surface exposes.
- Aggregate AABBs overstate adapter contact: the clipped octagon narrows near
  its full-width lateral corners, so contact must be checked across every
  lateral cross-section. SysML owns the transition length, derived from the
  octagonal source profile, adapter width, hinge station, required overlap,
  and interface margin. Generic `QueryUsdPrims` now returns exact
  canonical-stage collision vertices for one Mesh or Cube. The shared
  measurement library builds convex footprints and measures the minimum
  cross-section overlap across the adapter span, alongside transition length,
  top-face step, and hinge seam. This is static geometry evidence only; applying
  and reading back the ramp-side source changes and rover traversal are still
  pending.
- GRR-006/010 now specify a mitered convex-mesh track toe. The standard
  mechanical relation derives the bevel run from track thickness and the
  commanded ramp angle; generic SysML/USD checks read collision bounds and the
  composed mesh's upper/lower toe vertices. The Editor builder plans the Mesh
  migration, but it has not yet been applied or read back in the composed
  vehicle document.
- The GRR-012 footprint and full-span cross-section calculation is a
  Griffin-specific verification relation over the *composed colliders* used by
  the physics scene. It belongs in Griffin's Rhai verification policy; NURBS
  surface geometry is not a better input for this check. Rust's generic job is
  to return exact collider geometry, coordinate frame, and source generation.
  Promote a footprint primitive only if independent Twins need the same
  relation or profiling shows the authored implementation is a bottleneck.
- NURBS patches currently have a rendering tessellator, but the Avian adapter
  consumes `UsdGeomMesh` and primitive colliders and rejects unsupported
  geometry. Rendering tessellation is not a safe physics fallback: it is
  selected by render quality, narrows coordinates, and does not define a
  collision error bound. A generic physics cook should derive a collision
  `UsdGeomMesh` proxy from the source patch, apply the standard
  `UsdPhysicsMeshCollisionAPI` approximation, and retain source path plus
  source/document generation so edits invalidate the cook. Physics owns its
  tessellation tolerance and error bound; render quality remains independent.
  A conservative bounding box is useful for broad phase or a declared
  `boundingCube` approximation, while convex decomposition or a fitted box set
  is needed when the surface shape matters. The proxy must be inspectable and
  refreshable from Editor, with malformed or unsupported NURBS reported as an
  explicit collider error.
- GRR-011 moves ramp mass and diagonal-inertia literals into SysML and checks
  their composed realization. They are explicitly labeled study proxies.
  GR-021 remains planned: authoring queries can read mass-property attributes,
  but Griffin still lacks sourced per-body center of mass and full-frame
  mass-property evidence for acceptance.
- Requirement status and check catalogs are still parallel string arrays in
  SysML. Their label is now explicit and they are not used as per-run verdicts,
  but they remain a manual status table. A generic coverage report should
  derive checked, unverified, planned, and blocked views from resolved
  requirement, verification, realization, and evidence records.

## Generic Rust features Griffin needs

### P0 — semantic source and requirement graph

- `lunco-sysml-ast` already projects snapshot-scoped element/feature handles,
  resolved references, and typed relationship endpoints; the IR provides
  source-linked expressions, scalar/quantity types, multiplicity metadata,
  and four-state results. This is not full-project KerML navigation: feature
  chains, inherited/owned members, specialization, redefinition, and subsetting
  are not resolved as a complete reusable graph. Griffin still has
  qualified-name selection and manually maintained attribute-name lists in
  `griffin_spec.rhai`.
- The parser projects requirement `require`/`assume` memberships, verification
  target names for display, and snapshot-scoped resolved verification-to-
  requirement handles for coverage. Constraint membership inheritance
  currently follows one direct requirement usage-to-definition type edge.
- Add a generic requirement audit over the resolved graph that reports
  uncovered requirements, duplicate/missing IDs, absent subjects, unverified
  required constraints, invalid objective links, and unresolved source
  members. Text-only requirements must remain distinct from malformed
  requirements.
- Execute reusable constraint definitions through typed usage bindings and
  argument/default/direction/result checks. The evaluator accepts named
  parameter maps from Rhai; Griffin manually builds each map and selects
  constraints by string name. Rust does not yet execute SysML binding
  relationships or general constraint invocations.

### P1 — quantities, geometry, and provider observations

- `lunco-engineering-values` has dimension-safe conversion, and the IR carries
  quantity and binding metadata. The evaluator still requires matching unit
  labels for arithmetic/comparison and does not resolve a SysML unit contract
  into the `Unit` primitive. Griffin currently authors normalized metre/radian
  values and relies on field names for unit hints. Connect resolved units to
  IR checking and provider observations before using mixed providers or
  supplier data; never infer a conversion from a symbol string alone.
- `QueryUsdPrims` reads one composed snapshot and exposes exact canonical-stage
  points for active collision Mesh/Cube prims. It now returns the document
  generation and canonical-stage generation as separate values, including
  for live-stage reads. The remaining gap is binding SysML feature handles to
  USD targets and carrying query/document/stage provenance into each typed
  observation. Griffin's observer still supplies explicit paths and labels
  frame/unit instead of resolving those from typed contracts.
- `QueryPhysics` already exposes mass, center of mass, principal inertia,
  readiness, support state, and FLIP wheel-ray samples with sample ticks. It
  does not expose general collider-pair manifolds, per-point impulses, full
  inertia tensors with their body frame, or the solver configuration needed
  to qualify those observations. A real FLIP run can inspect wheel hit target,
  normal force, tire force, and suspension compression; what is still missing
  is an evidence recorder and temporal reducer that proves the required wheels
  contacted the ramp over the full traversal interval. A static fit check is
  not traversal acceptance.
- Physics collision cooking from `UsdGeomNurbsPatch` is absent. Add a
  source-generation-aware derived `UsdGeomMesh` cook with physics-owned
  tessellation tolerance, collider approximation selection, explicit cook
  errors, and an Editor preview/readback path. Do not use render tessellation
  quality as a physics accuracy setting.
- Preserve provider result states end to end. Inconclusive and error are not
  false requirements and must not be collapsed into a boolean.

### P2 — collections, behavior, and cross-tool provenance

- Add typed collection indexing, selection, cardinality, equality, min/max,
  sum, and reductions with defined ordering and empty-set behavior.
- Add configuration/mode/phase/time applicability and temporal sampling
  primitives before relying on scenario state machines for requirement meaning.
- Tie SysML realization/parameter identities to Modelica models, generated
  equations, solver settings, and result snapshots. A successful solve of a
  stale source revision must be rejected.
- Carry one evidence identity across SysML revision, compiled constraint
  fingerprint, provider snapshot/document generation, physics configuration,
  sample tick/time interval, and visual/run artifacts.
- Generate the complete requirement matrix and audit diagnostics from the
  resolved requirement/verification/realization/evidence graph. The shared
  evaluator now checks verify coverage by typed handles, but the Twin
  status/check catalog is manually maintained and each Rhai observer still
  selects authored qualified names and constructs evidence records.

## Editor and workflow tools still missing

- An offline Twin-wide SysML validation command that loads the complete source
  set and standard library before resolving imports and requirement links.
  `luncosim --validate` currently checks each file in isolation, so importing
  Griffin requirement files report unresolved cross-package names unless the
  Twin is loaded through the Workspace validation provider.
- A model browser that navigates the resolved SysML feature graph beside its
  USD/Modelica realizations and shows unresolved/multiple provider mappings.
- A source impact view from edited feature to affected constraints, USD
  builders, Modelica parameters, verification cases, and stale results.
- Typed observation inspection that shows value, unit, frame, timestamp,
  source feature, provider, and source/document generation together.
- A geometry comparison view that overlays the source-derived design envelope
  with composed render and collision geometry, including an explicit physical
  versus visual discrepancy report.
- A NURBS collider cook/preview workflow that exposes the source patch,
  generated collision mesh or box/decomposition, physics tolerance, source
  generation, and collider readback together.
- A requirements matrix generated from SysML relations, with pass/fail/
  inconclusive/error/unverified shown separately and links to evidence.
- Editor verification actions for structural checks and controlled physics
  trials that use the active document, record the exact clock/solver settings,
  and reject stale generations.
- Reusable typed builders for octagonal structural members, support rings,
  contact proxies, interfaces, and joints. Builders should consume typed source
  values and return previewable, undoable `ApplyUsdOps` plans; Griffin-local
  Rhai should only select and compose these generic builders.

## Griffin-specific model work, in order

1. **Completed in this migration:** correct landing-stability ownership and
   verification mapping. `GR-036` now owns the study bounds and required
   constraint; `GR-031` remains the execution determinism gate. Rust projects
   formal requirement constraint memberships, and the stability observer uses
   the generic evaluator.
2. **Completed in Editor:** migrate the physical deck collider to eight
   source-profile perimeter beams plus the separate payload-deck collider.
   Readback confirms source deviation within 0.001 m and leaves the tank
   opening clear. GRR-012 has a shared composed-collider measurement path;
   apply the ramp transition changes and capture fresh port/starboard readback.
3. Build a typed Griffin assembly graph: octagonal bus and deck, separate
   octagonal tank-support perimeter, four tank usages, seven engine usages,
   four landing-leg usages, solar assemblies, ramp options, adapter interface,
   and FLIP boundary. State multiplicity and reference-frame ownership once.
4. Connect source features to reusable component USD references and generic
   provider bindings. Keep FLIP loaded as its own component, with an explicit
   Griffin payload/release relationship rather than copying its assembly into
   the Griffin scene.
5. Replace one Rhai geometric predicate at a time with a typed provider value
   and a source-linked constraint. Preserve the old check only until the new
   generic path proves its positive and negative cases.
6. Add mass, inertia, propulsion, thermal, power, contact, and landing cases
   only when their inputs have real source provenance or are explicitly marked
   replaceable study assumptions. Do not call surrogate data flight accuracy.

## Definition of a proper first Griffin slice

- The source graph contains typed component usages and a formal requirement,
  constraint membership, and verification objective.
- Constraint parameters bind to source/provider features through resolved
  handles; there is no Griffin-specific qualified-name or index relationship
  table.
- Generic Rust resolves the source and returns typed observations with unit,
  frame, source revision, document generation, and stage generation.
  Unsupported SysML remains a visible diagnostic.
- Rhai selects providers and sequences the observation only; it does not
  restate the requirement predicate.
- Editor authors a previewable typed USD plan, applies it undoably, and reads
  back the composed result from the same document generation.
- A result includes all four verdict states, source and document revisions,
  provider snapshot, configuration, and evidence links. Positive, negative,
  missing-data, and stale-generation paths are visible.
- Griffin render, collision, and physical interfaces agree with the same
  source-owned geometry. FLIP remains an independently loaded hosted vehicle.

Until these conditions hold, report Griffin as a structured study model with
explicit unverified and assumption states, not as a validated mission
simulation.
