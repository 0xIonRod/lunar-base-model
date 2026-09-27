# Griffin implementation and standards gap review

**Reviewed:** 2026-09-27
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

The latest recorded Griffin requirements packet passed for its 37 requirement
usages and 23 verification cases: all 39 emitted evidence checks passed,
including composed geometry and the typed GR-005 source catalog. This checks
the authored study configuration and its verification procedures; it does not
qualify flight behavior or remove the separate geometry, physics, and mission
data gaps below. That packet's solver log also recorded five Avian joint-start
seating errors: three angular residuals of 90° or 180° and two translation
residuals of 3.44 m. No new flight-physics run was performed in this update;
these remain the latest available runtime results, not a new acceptance verdict.

The latest available Editor-loaded combined review scene packet reports 25 of
76 checks failing (11 in GV-002, seven in GV-004, one in GV-006, five in GV-007,
and one in FVG-001). The scene log reports missing or invisible leg subparts
and later finite-world exits for articulated lander bodies. Treat the composed
review as not physically integrated until those failures are resolved and read
back; the older requirements pass does not cover this visual/physics result.
These packet figures are the latest available evidence, not a new run in this
update.

FLIP now has one integrated vehicle asset. Its SysML source owns the published
battery-energy and solar-peak ratings; the Editor builder converts energy to
the battery model's Ah input and projects the solar rating as a finite output
limit. The generic panel defaults to an infinite limit, and the panel's live
Sun direction is routed through the FLIP network boundary from its local
environment probe. The USD and Modelica source validators accept this wiring
and branch-free cap. Dynamic battery/solar performance remains unverified.

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
| Requirement meaning | Five Griffin domain packages plus separate subsystem packages; some definitions provide only an informal `doc` statement | The audit's 154 informational findings mean “no formal SysML `require` membership”; they do not say that no Rhai procedure exists or that it ran. The current review resolves verification links for all 183 definitions, but the CLI does not check procedure execution or evidence freshness. Use a formal predicate for finite, measurable acceptance; use a bounded verification procedure/rubric and revision-linked evidence for visual, temporal, process, and documentary acceptance. Do not invent scalar predicates for those cases |
| Formal constraint ownership | Requirement membership roles are projected as standard `require`/`assume`; the generic IR selects constraints by snapshot-scoped handles, aggregates required memberships, and checks verification coverage through resolved `verify` links. It retains each usage's resolved formal-parameter handle and typed bound expression. Griffin's shared adapter resolves scalar source-feature bindings against those handles and evaluates the bound constraints | Griffin now exercises usage-bound constraints across solar, ramp, landing-leg, and deck geometry requirements; source literals and composed USD measurements enter as typed feature-path observations. Other verification paths still use name-keyed parameter maps. Defaults, output binding, and full specialization/redefinition traversal remain |
| Verification | Requirement `verify` references are inside `objective` blocks; the Rust projection now carries source-linked `require` membership and the landing-stability case targets new requirement `GR-036` | Many text-only requirements still have no executable constraint; `GR-031` remains a separate process gate, while stability values are owned by `GR-036` |
| Traceability | Twin manifest selects source packages, USD fixtures, scripts, and cases; Rust projects snapshot-scoped element handles, resolved references, typed relationship endpoints, and verification-to-requirement handle links. The GR-005 evidence catalog resolves its typed requirement and source references to typed locators and roles | Coverage evaluation compares resolved handles and GR-005 source provenance is exercised in the runtime verifier. Provider observations still do not share one end-to-end identity across source revision, realization, composed-stage generation, physics sampling, and resulting evidence. Status/check catalogs remain authored execution metadata; derive the requirement matrix from requirement, verification, realization, and evidence links |
| Units and frames | SysML type and literal measurement-reference identities use source-snapshot handles. Resolved linear `MeasurementUnit` definitions project SI dimensions, scales, and standard `UnitConversion::isExact` metadata from quantity-power factors, coherent SI base units, reference conversions, prefixes, and supported arithmetic unit initializers. Source quantities retain conversion exactness through typed native `Quantity` operations; the bounded Modelica length-vector adapter requires an exact resolved scale before lowering to SI | Static feature types still do not carry inferred units. Measurement uncertainty and instrument accuracy are not represented by scale exactness. Nonlinear and affine `MeasurementScale` mappings, unsupported definitions, typed frame identity, and end-to-end conversion provenance remain open. Griffin measurements are still mostly normalized to SI at the provider boundary |
| Geometry | Profiles, station vectors, counts, typed source handles, resolved SysML relationships, composed USD queries, effective Avian-cooked Mesh/Cube geometry, exact analytic collider dimensions and poses, and a generic NURBS-to-USD-Mesh collision cook exist | No complete semantic part-usage graph binds every source feature to a USD realization. Griffin currently has no authored NURBS patch to cook. The NURBS planner uses an explicit canonical-metre tolerance and adaptive tessellation, but its successive-level convergence estimate is not a certified upper bound on exact surface deviation |
| Behavioral applicability | Mission order, sampling horizon, route phases, and release are mostly Rhai orchestration | The model cannot yet state and evaluate configuration, mode, phase, or temporal applicability as part of a reusable source-defined verification objective |
| Modelica relationship | Continuous models and parameters are selected through Twin tooling | No complete standard realization/parameter provenance graph ties each equation set and result back to the source feature and requirement revision |

SysML allows informal requirement documentation; prose is not itself a
standards violation. The mismatch is claiming implementation or verification
coverage where that prose has not been connected to a resolved predicate,
realized feature, and evidence result.

## Griffin-1 evidence and construction blockers

### Main-engine plume runtime status

The vehicle declares the four typed `PlumePhotometry` outputs used by the seven
flame pairs and engine lights: `render_throttle`,
`visual_length_fraction`, `intensity`, and `radius`. The generated Modelica
network exposes all four member outputs and the USD connections target them.
The active Griffin surface-operations document still fails Modelica
compilation with `299 equations, 302 unknowns` (balance `-3`); its
`CompileStatus` has no compiled model or latest run. A reversible diagnostic
that removed `PlumePhotometry` left the same `-3` balance, so the remaining
equation deficit is elsewhere in the propulsion network. No simulated plume
values or visible engine plume have been verified. Resolve that network
balance before treating GPP-008 as dynamically demonstrated.

Astrobotic's current Griffin product page gives a seven-main-engine design,
four shock-absorbing legs, a flexible isogrid payload deck, and optional
egress ramps. Astrobotic's [solar setup post](https://lnkd.in/p/dJHz9duN)
describes transit Sun-pointing and places the surface panels in the quadrant
crossed by the mission-window Sun path. Its two-installed/one-remaining
statement records status at publication. The June 2026 integration photograph
shows three upright panel faces across adjacent sides of one lander sector,
with structural supports and clearance-shaped lower outlines. That is useful
qualitative installation evidence; perspective, occlusion, and the lack of a
scale datum prevent extracting exact panel dimensions, mount stations, hinge
axes, or load paths. Sources: [Astrobotic Griffin-1 integration photo](https://www.astrobotic.com/wp-content/uploads/2026/06/26.06.15_Griffin-1_PressConference_1348_Edit-scaled.jpg), [Astrobotic solar integration post](https://lnkd.in/p/dJHz9duN) ([canonical LinkedIn activity](https://www.linkedin.com/posts/astrobotic_two-solar-panels-integrated-to-griffin-just-activity-7450595533745975296-qBEA)), and [current Griffin product page](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/).

The authored source configuration and composed vehicle now contain three
referenced panel instances on consecutive forward, forward-starboard bevel,
and starboard faces. Their identities and stations come from SysML; each
instance's width is computed from its ordered pair of source-owned bus rails.
The reusable panel asset provides a centered lower clearance opening shared by
the structural frame, backplane, and cell field; the internal divider members
terminate at or split around the opening. The width and depth are currently
controlled by typed dimensionless study fractions (0.32 of frame width and
0.28 of frame depth), so the same component scales consistently on all three
faces. Those fractions reproduce only the qualitative silhouette in the public
image; they are not measured or approved Griffin-1 dimensions. The exact
installed station offsets, panel contour/cutout dimensions, support dimensions,
hinge/lock details, and electrical behavior still require controlled mission
data. The render-only panel surfaces have no collision proxy.

### Data package needed to make the vehicle construction-ready

The next model update should be driven by a Griffin-1 configuration-controlled
engineering package. Requirements should bind every measurement to that
baseline and declare one of `as-built`, `as-designed`, `mission requirement`,
or `replaceable study assumption` status.

| Requirement area | Required source data and acceptance evidence |
|---|---|
| Configuration and applicability | Vehicle/mission identifier, hardware revision, document revision/date, applicability, supersession, units, frames, uncertainty, and evidence role for each datum. Keep the Griffin-1 flight vehicle distinct from earlier Griffin/VIPER user-guide configurations. |
| As-built geometry | Controlled 3D CAD or dimensioned orthographic drawings; root datum/orientation; leg, tank, engine, solar, adapter, and payload stations; member profiles; panel cutouts; hole/bolt patterns; tolerances; and view/camera references. Compare composed mesh and collider against that source geometry with stated deviation tolerances. |
| Solar installation and power | Three panel identities, panel-local frames/normals, installed transforms on adjacent lander sides, support/hinge/lock geometry, stowed/deployed and cruise/surface states, keep-out envelopes, harness/electrical interfaces, panel I-V/temperature behavior, battery usable capacity, attitude-control law and keep-outs, time-aligned Sun/attitude/power telemetry, and mission Sun azimuth/elevation. The post establishes qualitative transit Sun-pointing and surface-quadrant behavior; it does not publish installation datums, pointing limits, or an electrical power budget. |
| Mechanical interfaces | Payload-deck isogrid/bolt pattern and rated load; Griffin-to-FLIP adapter, release datum and loads; leg joints, travel/damping and foot contact; engine and attitude-thruster stations/cant/loads; tank vessels/restraints; and optional ramp hinge and rover-clearance interfaces. Preserve source-mesh-derived collision and prove clearances after composition. |
| Mass properties | Measured total/dry/propellant/payload masses, center of mass, full inertia tensor with declared body frame, uncertainty, and configuration/propellant state. NASA says Griffin-1 completed mass-properties testing, but public numerical results are unavailable. |
| Flight and surface behavior | Engine thrust and throttle maps, propellant properties, RCS thrust/impulse locations, GNC/landing state transitions, terminal velocities/attitude/drift criteria, payload release sequence, and the operational mode each value applies to. |
| Site, lighting, and hazard detection | Confirmed touchdown coordinates and local frame; terrain coverage and resolution appropriate to the 15 cm hazard-detection threshold; time/epoch and Sun ephemeris; thermal and shadow/eclipses; and communications visibility. The current 4 m/pixel regional DEM cannot verify a 15 cm hazard threshold. |
| Verification record | Requirement-specific acceptance procedure, measured source and configuration revision, uncertainty/tolerance, provider/document generation, sample interval where dynamic, raw evidence link, and distinct pass/fail/inconclusive/error outcomes. Image comparison can verify qualitative silhouette only unless calibrated. |

The surface-operations and combined visual-review scenes are time-aligned for
the same deterministic study snapshot: each root selects the solar-system
ephemeris, authored TDB epoch, and NOBILE03 site anchor. The visual-review
scene derives its typed site/time values from the composed surface-operations
root. At JD 2461395.5 TDB (2026-12-21 TDB calendar date), the simulator
ephemeris gives Sun azimuth 7.52° clockwise from north and elevation 6.49° at
that anchor. Astrobotic's [manifest](https://www.astrobotic.com/lunar-delivery/manifest/)
lists Nobile Region 2026 and NASA's [Moon Base update](https://www.nasa.gov/news-release/nasa-provides-update-on-moon-base-rovers-landers-missions/)
describes a launch planned later in 2026, but neither publishes the surface
landing timestamp; the authored epoch is not flight timeline data. The current
solar observer checks array geometry and visible support overlap, but does not
evaluate GSA-003 across the actual mission-window Sun envelope and approved
installation frames. GSA-010 also needs time-aligned transit attitude and
electrical-power observations. Verification against the flight configuration
requires the mission landing epoch/site and installation definition, plus
transit attitude and EPS data.

### Configuration conflicts to resolve

- Astrobotic's current product page specifies seven main engines. The earlier
  [Griffin lunar-lander User Guide](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf)
  describes a five-engine propulsion baseline for its then-current
  polar/VIPER configuration. Do not blend those
  configurations: retain seven for the current product baseline, and require
  Griffin-1-specific propulsion drawings before asserting the as-built count,
  engine stations, or cant angles.
- The product page supports four legs but does not publish their station
  coordinates, shock travel, stiffness, damping, foot size, or structural
  loads. The Twin's four study stations are not installation data.
- Public photos establish the three-array silhouette and qualitative sector
  arrangement. The Twin now composes the three adjacent faces through one
  reusable referenced panel asset, with rail-pair-derived widths and connected
  study support geometry. The shared frame, backplane, and cell mesh now include
  one matching lower clearance opening driven by SysML study fractions; no
  public scale datum supports treating these fractions or the rest of the
  installation geometry as as-built dimensions.
- NASA confirms completion of Griffin-1 mass-properties testing, but no public
  mass/CG/inertia table was found. Keep inherited lander values explicitly
  surrogate until that measured dataset is supplied.

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
  and interface margin. Generic `QueryUsdPrims` now returns the geometry
  produced by the same Avian collider cook used for runtime projection, with
  composed transforms applied into canonical-stage coordinates. Convex
  decomposition remains separate hull parts, not a filled envelope. The shared
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
- NURBS collision derivation now uses the shared USD NURBS parser and trim
  handling, but a separate physical tessellation profile; it never reuses the
  Graphics quality setting. `PlanNurbsCollisionProxy` returns a read-only
  plan for an explicit document generation. `nurbs.rhai` turns it into normal
  `CreateUsdProposal` operations, so the generated child `UsdGeomMesh` is
  reviewable, journaled, and refreshable through the Editor. The proxy carries
  `PhysicsCollisionAPI`, `PhysicsMeshCollisionAPI`, `purpose = "proxy"`, and
  `visibility = "invisible"`; its typed `lunco:derived:source` relationship,
  cook settings, and `uint64` geometry fingerprint are authored on the proxy.
  Avian re-cooks the source, checks the generated fingerprint against the
  recorded value, and compares the authored proxy mesh before admission,
  rejecting stale or modified proxies. The Avian reader and proxy planner now
  share one typed capability contract and the plan reports the implemented
  modes. These are `none` (static/kinematic triangle mesh), `convexHull`,
  `convexDecomposition`, and `boundingCube`. OpenUSD also defines
  `boundingSphere` and `meshSimplification`; both remain explicitly unsupported
  by Avian. The current `boundingCube` cook now uses an oriented principal-axis
  fit instead of a mesh-axis AABB. This fit is deterministic but does not
  guarantee a globally minimum-volume box; exact [OpenUSD schema parity](https://openusd.org/dev/api/class_usd_physics_mesh_collision_a_p_i.html)
  remains open. Rhai authoring obtains structured mode records from one Rust
  capability contract: each record includes the USD token, cooked geometry,
  and rigid-body compatibility. `PlanNurbsCollisionProxy` returns the same
  records, so authoring and planning use the runtime's contract without a
  second allow-list or locally duplicated body restrictions.

  The planner now requires a canonical-metre deviation tolerance and adaptively
  refines untrimmed U/V grids or trimmed curve/grid settings. It records the
  selected resolution and symmetric sampled vertex-to-triangle distance
  between the last two levels; physics admission re-cooks and checks that
  result. This is a convergence estimate, not a certified upper bound on exact
  NURBS surface deviation, so geometric-error certification remains open. A
  collision API cannot infer meaningful fitted box partitions from a surface
  alone. Griffin itself currently contains no
  `UsdGeomNurbsPatch`/`LunCoLatheAPI` source, so no Griffin geometry was changed
  to exercise the new generic path.
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
  and four-state results. Dotted feature chains and navigation through a
  path-valued argument to a scalar structured predicate input now preserve the
  resolved call-site path and provider dependency; the latter is compile-
  checked but not yet runtime-verified. Whole structured values and
  collection-valued navigation remain unsupported. This is not full-project
  KerML navigation: inherited/owned members, specialization, redefinition, and
  subsetting are not resolved as a complete reusable graph. Griffin still has
  qualified-name selection and manually maintained attribute-name lists in
  `griffin_spec.rhai`.
- The parser projects requirement `require`/`assume` memberships, verification
  target names for display, and snapshot-scoped resolved verification-to-
  requirement handles for coverage. Constraint membership inheritance
  currently follows one direct requirement usage-to-definition type edge.
- `SysmlModel.audit_requirements(policy)` now reports duplicate short names,
  optional project rules for short names, typed subjects and verification
  coverage, text-only requirements, unresolved verification targets, and
  unresolved names inside requirement definitions. The Griffin requirements
  tool exposes this as an explicit review operation; normal Twin startup does
  not enforce it. The `sysml-audit --engineering-review` CLI was run on the 21
  Twin requirement sources: it found no source diagnostics or policy errors,
  and resolved verification links for all 183 definitions. It reported 29
  definitions with formal `require` constraints and 154 informational
  text-only findings. Those findings mean no formal `require` membership; they
  do not imply that no procedure exists. The exact Griffin runtime verifier
  now executes and checks its evidence, but the CLI still does not run mapped
  Rhai procedures or assess evidence freshness, and the in-Editor audit action
  was not run. Standard usage-level feature-value bindings project through
  resolved formal-parameter handles; diagnostics for inherited defaults and
  general binding relationships remain open.
- The asset-level `luncosim --validate` path does not assemble the Twin's SysML
  package context: validating all requirement files together still reports
  cross-file names such as `GriffinRequirementSources::TwinAssetPath` and
  `FlipRequirements::FlipRover` as unresolved. The Twin-loaded review path
  resolves these sources, so this CLI result is not a project verdict. Add a
  manifest-aware validation mode that resolves imports before reporting
  semantic names. Standalone validation also flags the reusable SolarPanel
  mass API as outside a rigid body; its FLIP instance is nested beneath the
  rover body. Asset-context validation must distinguish reusable components
  from unmassed scene roots.
- The generic IR now compiles by exact snapshot-scoped constraint handle and
  evaluates every standard `require` membership on a requirement as one
  four-state result. It can validate the associated verification case through
  resolved `verify` handles. `assume` memberships remain context, not acceptance
  predicates. The Rhai `SysmlModel.evaluate_requirement` boundary accepts the
  typed requirement and verification objects plus typed feature-path
  observations.
- The generic IR now exposes `compile_required_constraints` and the Rhai
  `SysmlModel.required_constraint_irs(requirement)` method. Both the provider
  and evaluator use the same requirement membership selection and apply the
  same standard usage bindings, so a provider can inspect the exact effective
  dependencies instead of compiling a reusable definition in isolation.
  `SysmlModel.source_literal_observation(attribute)` emits a source-revision-
  scoped typed feature path and value for resolved scalar literals.
- Griffin's shared requirements adapter uses this path for source-bound
  constraints across solar, ramp, landing-leg, and deck geometry checks. The
  exact `luncosim test` run passed all 39 evidence checks against 37 requirement
  usages and 23 verification cases, including composed geometry measurements
  and typed GR-005 source provenance. This is runtime verification of the
  authored study fixture, not an interactive Editor audit or flight
  qualification. The source audit resolved all 183 verification links with no
  source diagnostics. Other Griffin checks still use name-keyed parameter maps.
  User-defined predicate calls rebase structured member paths onto resolved
  feature-valued actuals; that path has compile evidence only. Defaults, output
  parameters, and broader redefinition traversal remain open.
- The opt-in generic requirement audit is implemented and exposed from the
  Griffin requirements tool. Run it explicitly and review findings before
  using its policy as a gate. Text-only requirements are reported separately
  from unresolved names and invalid verification targets.

### P1 — quantities, geometry, and provider observations

- `lunco-engineering-values` and the neutral evaluator carry typed `Quantity`
  values and `Unit` contracts. Compatible dimensions are converted for
  arithmetic/comparison; multiplication, division, powers, and square root use
  coherent SI units. Observations reject a separate unit field and textual
  `{ value, unit }` quantity maps. The SysML source projection now resolves
  linear `MeasurementUnit` dimensions and scales into typed definitions for
  source literals; supported literal quantities enter the evaluator as native
  `Quantity` values. The Griffin Modelica length-vector adapter uses that
  reference and converts to SI without a parallel symbol table. Static feature
  type unit inference, affine/nonlinear `MeasurementScale` mappings, and typed
  frame/conversion provenance remain open. Standard conversion exactness now
  remains attached to native units and quantities through arithmetic; this is
  not a measurement-uncertainty or instrument-accuracy model. Most Griffin
  provider measurements still normalize to SI explicitly.
- `QueryUsdPrims` reads one composed snapshot and exposes the effective Avian
  collider for active collision Mesh, Cube, Sphere, Cylinder, Cone, Capsule,
  and finite Plane prims. Meshes return cooked triangle topology or convex
  hull vertices; convex decomposition retains each hull; analytic shapes
  return exact cooked dimensions and a collider-local-to-stage pose. Composed
  transforms and authored scale are included in the query result. It returns
  the document generation and canonical-stage generation as separate values,
  including for live-stage reads. The SysML evaluator now retains tagged source
  and USD-stage provenance and flags mixed generations for one document.
  Griffin's GR-018 observer now batches its eight perimeter beams, payload
  collider, and hierarchy root into
  one query. A source-owned GR-018 constraint checks the body's effective
  eight-vertex Cube hull and exact canonical-stage bounds. The deck observer
  checks each Avian-cooked shape and frame, verifies beam source dimensions and
  transforms, and compares the adapter's authored mesh points
  and topology to its SysML-derived geometry. It passes the batch's document
  and stage revisions through typed provider provenance. The broader SysML
  feature-to-USD mapping, static unit inference, `MeasurementScale` conversion,
  and frame resolution remain open. Interactive Editor preview
  and joined source/render/collider comparison remain unavailable.
- `QueryPhysics` already exposes mass, center of mass, principal inertia,
  readiness, support state, and FLIP wheel-ray samples with sample ticks. It
  does not expose general collider-pair manifolds, per-point impulses, full
  inertia tensors with their body frame, or the solver configuration needed
  to qualify those observations. A real FLIP run can inspect wheel hit target,
  normal force, tire force, and suspension compression; what is still missing
  is an evidence recorder and temporal reducer that proves the required wheels
  contacted the ramp over the full traversal interval. A static fit check is
  not traversal acceptance.
- The generic `UsdGeomNurbsPatch` collision cook uses tolerance-driven adaptive
  tessellation and records a symmetric sampled convergence estimate. That
  estimate is not a certified bound on the exact surface deviation. Editor
  preview/readback of the error and applying the tool to a real Griffin NURBS
  source remain open; Griffin currently authors no NURBS patch.
- Preserve provider result states end to end. Inconclusive and error are not
  false requirements and must not be collapsed into a boolean.

### P2 — collections, behavior, and cross-tool provenance

- The generic IR already supports homogeneous scalar collections,
  one-based indexing, `size`, emptiness, `sum`, `product`, Boolean aggregates,
  and scalar `min`/`max`. Remaining collection work is feature-valued and
  structured collections, collection navigation, filtering/selection, and
  reusable reductions over modeled part usages. Apply the remaining semantics
  only when the Griffin source model needs them; keep cardinality and ordering
  from the resolved SysML multiplicity.
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

- A model browser that navigates the resolved SysML feature graph beside its
  USD/Modelica realizations and shows unresolved/multiple provider mappings.
- A source impact view from edited feature to affected constraints, USD
  builders, Modelica parameters, verification cases, and stale results.
- Typed observation inspection that shows value, unit, frame, timestamp,
  source feature, provider, and source/document generation together.
- A geometry comparison view that overlays the source-derived design envelope
  with composed render and collision geometry, including an explicit physical
  versus visual discrepancy report.
- An Editor panel that previews the NURBS source beside the generated collider,
  reports measured geometric deviation and cooked collider readback, and makes
  an explicitly selected approximation easy to inspect. The Rhai planner and
  proposal path exist; the joined visual readback and tolerance report do not.
- A requirements matrix generated from SysML relations, with pass/fail/
  inconclusive/error/unverified shown separately and links to evidence.
- Editor verification actions for structural checks and controlled physics
  trials that use the active document, record the exact clock/solver settings,
  and reject stale generations.
- Reusable typed builders for octagonal structural members, support rings,
  contact proxies, interfaces, and joints. Builders should consume typed source
  values and return previewable, undoable `ApplyUsdOps` plans; Griffin-local
  Rhai should only select and compose these generic builders.
- The solar-panel refiner is now instance-driven: it consumes canonical typed
  identities, stations, orientations, ordered bus-rail pairs, and a shared
  component asset, then computes each panel width and local support attachment
  from those source values. The generic `SysmlModel.value` projection now
  preserves `Position[n]` as an array of native `DVec3` values; the Griffin
  Rhai tool consumes that typed projection and no longer reconstructs stations
  from `AnalyzeSysml` AST records. Broader object-valued and feature-valued
  collection mapping remains open in the generic SysML subset.
  The visual component now models a matching lower clearance opening through
  the frame, backplane, and cell field, using source-owned study fractions.
  Replace those fractions and refine the contour from the controlled panel
  drawing before as-built acceptance. The standalone solar observer now reads
  the three configured panel identities/stations and their paired bus rails;
  GSA-003 remains verification-link coverage only until the approved
  installation frames and mission-window Sun envelope are authored. The
  visual-configuration type scenario reads the canonical solar count and
  checks the forward identity.

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
