# Griffin implementation and standards gap review

**Reviewed:** 2026-09-23
**Scope:** Griffin as the active model, FLIP as a separately loaded hosted
vehicle, and the generic Rust/Rhai/Editor capabilities needed to build and
verify the model.

## Finding

The Twin has useful source-owned parameters, a split requirement set, a
componentized visual assembly, a reusable FLIP asset, and a first executable
SysML constraint slice. It is still an integration study, not a complete
Griffin system model. Several engineering facts remain encoded as prose,
parallel values, path/name tables, Rhai predicates, and hand-authored USD
relationships. The missing work is primarily generic semantic resolution,
typed provider observation, and a real composed engineering graph.

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
| Traceability | Twin manifest selects source packages, USD fixtures, scripts, and cases; requirement provenance and implementation-status arrays remain authored catalogs | `twin.toml`, provider strings, USD path tables, `RequirementEvidence` qualified-name strings, and status/check ID arrays are LunCoSim integration metadata, not standard SysML relationships. They duplicate identities that a resolved model graph should expose; replace them with generated views over typed requirement, verification, realization, and provenance links |
| Units and frames | SI intent is frequently carried by names such as `...M`, `...Kg`, `...Rad`, plus comments and frame strings | Suffixes and documentation are not dimensional typing. Numerically plausible values can still use the wrong unit, origin, axis, or observation frame |
| Geometry | Profiles, station vectors, counts, and USD prim names exist in source/configuration | No complete semantic part-usage graph binds every geometric feature to the realized USD feature; several layout and mesh acceptance rules are still Rhai loops |
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
  octagonal perimeter colliders plus a separate payload-deck collider; GRR-012
  remains blocked on composed transition/contact observation, not deck topology.
- Twin verification observers bind authored requirements to composed source
  and USD observations. The generic evaluator owns requirement membership,
  constraint evaluation, and verdict classification; observers supply the
  component-specific measurements that the shared provider surface exposes.
- GRR-012's 1.05 m transition length is now a SysML study datum spanning the
  2.20 m payload-deck half-width to the 3.20 m hinge with 0.05 m contact
  overlap. The generic provider still cannot observe the composed transition
  contact or wheel envelope, so GRR-012 remains inconclusive; geometry authoring
  alone is not acceptance evidence.
- Requirement status and check catalogs are still parallel string arrays in
  SysML. Their label is now explicit and they are not used as per-run verdicts,
  but they remain a manual status table. A generic coverage report should
  derive checked, unverified, planned, and blocked views from resolved
  requirement, verification, realization, and evidence records.
- A previous runtime report echoed its expected requirement-ID catalog as
  `checked_rules`, and the test emitted a synthetic pass row for each ID.
  That was not execution evidence. The field and fabricated rows are removed;
  the authored check catalog is labeled separately, and payload/ramp boundary
  results now carry focused SysML verification-case identities. Structural
  reports remain report-level evidence rather than per-requirement verdicts.

## Generic Rust features Griffin needs

### P0 — semantic source and requirement graph

- Resolve feature chains, owned/inherited members, type/specialization,
  redefinition, subsetting, multiplicity, and stable source handles across the
  full project and standard library.
- Project requirement, `require`/`assume`, verification `objective`, `verify`,
  `satisfy`, `refine`, and realization relationships as typed graph edges, not
  short-name strings. The current membership projection is an initial slice;
  inherited constraint membership currently follows one direct requirement
  usage-to-definition type edge.
- Add a generic requirement audit that reports uncovered requirements,
  duplicate/missing IDs, absent subjects, unverified required constraints,
  invalid objective links, and source members that cannot be resolved.
- Execute reusable constraint definitions through typed usage bindings and
  argument/default/direction/result checks. The evaluator currently binds a
  named parameter map from Rhai; it does not yet execute SysML binding
  relationships or general constraint invocations.

### P1 — quantities, frames, and provider observations

- Add quantity kinds and unit definitions/conversion with dimensional type
  checking; do not infer dimension from attribute suffixes.
- Represent points, directions, lengths, angles, mass properties, frames,
  time-validity, and coordinate transforms as typed values with explicit
  errors for incompatible operations.
- Add a generic USD feature provider for composed attributes, relationships,
  transforms, mesh points/indices, topology, purpose, material assignment,
  collision ownership, and document generation. Provider queries should
  resolve source feature handles to targets and return provenance with each
  value.
- Add a physics provider for mass, center of mass, inertia, collider identity,
  contacts, impulses, solver configuration, and body ownership, including
  sample time and readiness/staleness.
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
  and visual/run artifacts.

## Editor and workflow tools still missing

- A model browser that navigates the resolved SysML feature graph beside its
  USD/Modelica realizations and shows unresolved/multiple provider mappings.
- A source impact view from edited feature to affected constraints, USD
  builders, Modelica parameters, verification cases, and stale results.
- Typed observation inspection that shows value, unit, frame, timestamp,
  source feature, provider, and source/document generation together.
- A geometry comparison view that overlays the source-derived design envelope
  with composed render and collision geometry, including an explicit physical
  versus visual discrepancy report.
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
   opening clear. GRR-012 still needs a typed composed contact observer.
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
  frame, generation, and provenance. Unsupported SysML remains a visible
  diagnostic.
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
