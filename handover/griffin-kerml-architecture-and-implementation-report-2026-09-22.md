# Griffin SysML/KerML architecture and implementation report

**Date:** 2026-09-22

**Repository:** `/home/rod/Documents/models/lunar-base-model`

**Audience:** the next agent working on the Griffin Twin from this repository

**Scope:** SysML/KerML source-of-truth work, typed engineering values,
mechanical relations, Rhai policy boundaries, Modelica/Rumoca integration, and
the remaining full-KerML follow-up.  This report intentionally does not cover
the separate USD asset-download policy task.

## Executive result

The Griffin work now has a working vertical slice of the intended architecture:

```text
SysML source values and identities
        |
        v
typed read-only SysML session
        |
        +--> Rhai verification policy
        |      +--> mechanical/CAD relation library
        |      +--> explicit numerical settings
        |      +--> structured requirement evidence
        |
        +--> typed native geometry plan
        |      +--> USD/Editor builder
        |
        +--> bounded typed neutral constraint IR
               +--> Modelica/Rumoca physical solve
```

The current production evidence is positive:

- the Griffin visual-configuration source and verification sources load from
  the Twin;
- the verification observer emits `22` checks with `0` failures;
- the source-backed native plan contains `27` component records and `6` rail
  records;
- generic plane-coincidence, under/clearance, and paired-symmetry checks pass;
- the headless production component test exits with `luncosim test PASS`.
- LunCoSim now provides a bounded, source-linked neutral constraint IR and a
  Rumoca-admitted Modelica lowering backend. This is available on LunCoSim
  `main` at `f244cf683` and is tested by authored Rhai/API assets as well as
  the production scene gate.

This is a successful typed geometry and verification slice, not full KerML
execution and not yet a physically complete Griffin model. The next agent
must preserve that distinction.

## What was implemented for the goal

### 1. Source-of-truth and ownership boundary

The intended authority is now explicit:

- SysML/KerML owns component identity, topology, requirements, verification
  identity, units, tolerances, assumptions, and source provenance.
- Rhai owns changeable verification and orchestration policy, including which
  observations are selected, how a generic relation library is composed, and
  how evidence is reported.
- Rust owns small, reusable, typed mechanisms: native values, finite-vector
  math, unit conversion primitives, semantic handles, safe caches, and typed
  boundary validation.
- Modelica/Rumoca owns continuous equations and dynamic physical models.
- USD owns the realized scene, transforms, materials, physics representation,
  and standard schema data. USD is not the design or requirement source.

The implementation avoids putting Griffin names, tank rules, landing-leg rules,
or requirement identifiers into the Rust kernel. The Griffin-specific choices
remain in SysML and authored Rhai policy.

### 2. Shared engineering values and units

The terrain/main integration adds a small policy-free engineering-value seam:

- `lunco-engineering-values` contains dimension vectors, units, quantities,
  finite-value validation, and dimension-safe conversion.
- `rhai_engineering.rs` exposes the same values to Rhai without introducing a
  second tuple or vector representation.
- `lunco-usd-data` can represent stage lengths through the shared quantity
  seam.
- `engineering_units.rhai` provides the authored bounded vocabulary currently
  needed by the Twin: length, time, mass, temperature, current, amount of
  substance, luminous intensity, force, pressure, energy, power, frequency,
  angle, and common compatible spellings.

The catalog is intentionally bounded. It is not pretending to be a complete
UCUM parser. Unsupported or dimensionally incompatible units fail explicitly.
That gives the project a safe extension point while avoiding a second unit
system in every consumer.

### 3. Native f64 math boundary

The native hot path uses the same f64 Bevy/glam values already used by the
simulator:

- `Vec2` and `Vec3` use native `DVec2`/`DVec3`;
- `Quat` uses native `DQuat`;
- `Transform` uses the shared f64 transform type;
- vector length, dot, cross, cosine, angle, normalization, component access,
  finite checks, and validity checks use Rust-backed primitives;
- scalar conversion is explicit through `f64_from` and strict setting
  validation uses `f64_only`;
- `array_is`, `map_is`, `string_is`, `vec2_is_native`, and `vec3_is_native`
  avoid using `type_of(value)` strings as an ordinary type protocol;
- the SysML adapter also exposes `sysml_model_is`, `sysml_quantity_is`, and
  `sysml_enum_is` for opaque semantic wrappers.

The boundary is deliberately explicit: f32 can remain a rendering or external
serialization format, but the engineering and requirement calculations use
f64 until a documented boundary requires otherwise.

### 4. Authored mechanical/CAD relation library

`assets/scripting/tools/mechanical_relations.rhai` is a generic, reloadable
policy library. It does not know Griffin, USD paths, SysML names, or Modelica
components. It currently covers:

- scalar equality and ranges;
- point distance and coincidence;
- signed distance to a plane;
- under/above and clearance relations;
- angle, parallel, same-direction, perpendicular, collinear, and coplanar
  relations;
- line/plane and axis-coincidence relations;
- mirroring and plane symmetry;
- axial half-turn symmetry;
- midpoint-on-plane and paired symmetry.

The library consumes native f64 vectors and a caller-supplied tolerance. It
returns residual/evidence records rather than silently returning a boolean.
This is important for engineering review: the report must show the residual,
expected value, tolerance, units, and relation status.

The library is an extensible policy surface. Unusual checks can be added in
Rhai. Rust should receive a new primitive only when the operation is generic,
hot, safety-critical, or useful across USD, Modelica, and other domains.

### 5. Runtime numerical settings

`numerical_settings.rhai` resolves a live numerical profile from the active Twin
settings. The profile keeps separate f64 values for:

- scalar comparison;
- length comparison;
- angle comparison;
- time comparison; and
- solver residuals.

The profile is resolved once per report or solve and passed down to loops. It
does not use hidden magic epsilons and does not silently replace a normative
SysML tolerance. A requirement tolerance, such as Griffin's
`verificationToleranceM`, remains source-backed and appears in the evidence.

### 6. Source identity and verification provenance

The earlier value-only projection seam is intentionally kept separate from
identity-aware evidence:

- `source_with_attributes(...)` is appropriate when a policy only needs typed
  values;
- `source_with_selection(...)` is used when the evidence must retain selected
  requirement and verification identities.

The Griffin observer now selects the relevant attributes, requirements, and
verification case explicitly. This prevents a geometry check from passing
while losing which requirement or verification case it supports.

### 7. Griffin native-plan repair

The `GVC-T-native-plan` failure was diagnosed as a boundary mismatch, not a
geometry failure. The old Griffin policy expected Rhai type labels such as
`"float"`, `"int"`, `"array"`, and `"Vec3"`, while the current bridge returns
f64/i64 values, native vectors, and typed wrappers. Numeric projection then
returned empty lists, so the plan was empty even though the source data and
relations were present.

The policy now uses explicit conversion and native predicates. It also uses
the SysML wrapper predicates rather than string dispatch for the changed path.
The resulting production evidence is:

```text
GRIFFIN_VISUAL_CONFIGURATION_TYPES_EVIDENCE
  check_count=22
  failure_count=0
  verdict=pass

GVC-T-native-plan
  component_count=27
  rail_count=6
  ok=true
```

The Griffin change is committed as `c1efe88` in this repository. The shared
LunCoSim implementation is now one fast-forwarded commit, `f244cf683`, on
both the `terrain-streaming` worktree and remote `main`; do not resurrect the
old split terrain/main commit sequence.

## Current architecture in detail

### The five representations that must not be conflated

The project needs five related but distinct representations:

1. **Authored semantic source** — SysML/KerML structures, requirements,
   quantities, relationships, constraints, modes, and provenance.
2. **Resolved semantic graph** — upstream-resolved elements, feature handles,
   relationship endpoints, source spans, inferred types, and diagnostics.
3. **Neutral executable constraint IR** — a compact typed graph independent of
   Rhai, USD, and Modelica.
4. **Domain observations and physical models** — USD geometry/poses,
   telemetry, Modelica variables, solver results, and mission traces.
5. **Evidence and verdicts** — requirement-linked results with source,
   subject, actual/expected values, units, residuals, time interval, model
   revision, and verdict state.

The current implementation has parts of (1), (2), (4), and (5), plus a
bounded (3) and a first binding/evaluation contract. The bounded IR is useful
now for scalar/fixed-array constraint slices, but the full KerML semantic
centre is still incomplete: feature navigation, invocation, collections,
applicability, and complete provenance must be added before Griffin can use
the language for its whole assembly.

### Rust kernel responsibilities

Keep Rust minimal and generic. The Rust side should provide:

- stable source-revision and element/feature handles;
- access to the upstream SysML/KerML semantic model;
- typed values and quantities;
- dimension-safe unit conversion;
- native f64 vector/quaternion/transform operations;
- immutable expression/constraint IR validation;
- typed value-binding requests and observation snapshots;
- deterministic compilation/evaluation cache keys;
- execution budgets, cancellation, recursion limits, and cycle detection;
- structured diagnostics and result serialization.

Rust must not contain:

- Griffin component names;
- hard-coded tank/leg/ramp rules;
- special cases for a specific USD path;
- a hidden list of requirement identifiers;
- a second expression grammar;
- arbitrary filesystem or USD mutation APIs exposed to policy scripts.

### Rhai responsibilities

Rhai is the authored policy and orchestration layer. It should:

- select the active requirements, verification cases, configurations, and
  mission phases;
- choose the observation provider for a feature binding;
- compose generic mechanical relations;
- choose whether an unsupported relation is fatal, inconclusive, or deferred;
- aggregate evidence and publish the verification verdict;
- describe geometry recipes and Editor command plans;
- select a Modelica analysis case and map its typed inputs/outputs;
- provide rare project-specific checkers when the generic relation algebra is
  genuinely insufficient.

Rhai should not parse arbitrary KerML text, implement rollback, directly walk
  the filesystem, or duplicate the typed math kernel. Its normal execution
  unit is a compiled policy over a typed semantic/observation context.

### Modelica/Rumoca responsibilities

Modelica remains the right owner for continuous and coupled physical math:

- mass and centre-of-mass aggregation;
- inertia and rigid-body properties;
- tank pressure and propellant states;
- engine thrust and propellant flow;
- battery, solar generation, and load balance;
- thermal capacitance, conduction, radiation, and operating limits;
- landing-leg stiffness, damping, contact loads, and shock absorption;
- ramp actuator loads and deployment timing;
- degradation, reserve, and lifetime traces.

SysML should define the component parameters, interfaces, requirements, and
analysis-case intent. Modelica should provide equations and state evolution.
The Modelica model is a realization of the authored semantics, not a second
requirements database.

### USD responsibilities

USD should contain the realized assembly and standard scene facts:

- component prim hierarchy and references;
- transforms and authored datums;
- meshes, materials, normals, and render visibility;
- physics schemas and collision/contact representation;
- optional typed provenance links back to source handles and realization IDs.

The USD builder must consume a resolved plan. It must not recreate a second
component table with independent station literals. A component should have one
source identity, one local frame, and one derived placement path.

## Current LunCoSim implementation and agent quickstart

The bounded IR is usable today. The next agent must use it as a generic
compiler boundary and must not re-create its missing features in Griffin Rhai.

### Available implementation

In LunCoSim `main` (`f244cf683`, also present in the `terrain-streaming`
worktree), use these owners:

- `crates/lunco-sysml-ast` — resolved source, source spans, feature handles,
  typed values, relationships, requirements, verification records, and the
  bounded expression tree;
- `crates/lunco-sysml-ir` — source-linked typed constraint IR, type and
  multiplicity checks, fingerprints, diagnostics, and four-state evaluation;
- `crates/lunco-sysml-modelica` — typed IR to standalone Modelica lowering,
  admitted through the repository's Rumoca parser boundary;
- `crates/lunco-sysml-rhai` — immutable native `SysmlModel` methods and
  structured conversion for authored policy;
- `crates/lunco-scripting-rhai-world` — transport-safe path APIs; and
- `assets/scripting/tools/sysml_modelica_constraints.rhai` — authored policy
  that selects and assembles geometry constraints, without owning the
  language semantics.

The in-process Rhai surface is:

```rhai
let model = sysml_model("lunco://scripting/tests/fixtures/sysml_constraint_projection.sysml");
let name = "ConstraintProjection::CoincidentPointTranslation";
let ir = model.constraint_ir(name);
let modelica = model.modelica_constraint(name);
let result = model.evaluate_constraint(name, #{}, 1.0e-9, 1.0e-9);
```

The API/MCP-safe surface is path-based and returns structured maps:
`sysml_constraint_ir(path, qualified_name)`,
`sysml_modelica_constraint(path, qualified_name)`, and
`sysml_evaluate_constraint(path, qualified_name, observations, abs_tol,
rel_tol)`. Use the path surface for transport or one-shot callers; do not
serialize a native `SysmlModel` handle into an ad hoc JSON protocol.

Use `lunco://` for SysML, Rhai, USD asset, and Twin-relative source identity.
Keep a USD prim target as a USD path, for example
`/World/Griffin1/LandingLegPort`, rather than disguising it as an asset URI.

### Canonical validation commands

Run from `/home/rod/Documents/luncosim-workspace/main` with the production
binary, not an old sandbox executable:

```bash
cargo check -p lunco-sysml-ir -p lunco-sysml-modelica \
  -p lunco-sysml-rhai -p lunco-scripting-rhai-world
cargo test -p lunco-sysml-ir -p lunco-sysml-modelica \
  -p lunco-sysml-ast -p lunco-sysml-rhai
cargo build -p lunco-luncosim --bin luncosim
target/debug/luncosim test \
  --scene assets/scenes/tests/sysml_constraint_ir.usda \
  --verdict-channel SYSML_CONSTRAINT_IR \
  --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0
```

The authored assets are the contract tests, not just examples:

- `assets/scenarios/tests/sysml_constraint_ir.rhai` and
  `assets/scenes/tests/sysml_constraint_ir.usda` — production native-handle
  scene gate;
- `assets/scripting/tests/test_sysml_constraint_ir_diagnostics.rhai` — valid,
  invalid, missing, and pre-lowering diagnostics;
- `assets/scripting/tests/test_sysml_constraint_ir_evaluation.rhai` — pass,
  fail, inconclusive, stale, and provider-invalid results;
- `assets/scripting/tests/test_sysml_constraint_projection.rhai` — existing
  binding/quantity/Modelica projection contract; and
- `assets/scripting/tests/fixtures/*.sysml` — small standard source fixtures.

For a fresh server session, run the transport tests with
`scripts/api/run_rhai_test.sh` on a free explicit API port. Stop the server
with the typed API `Exit` command and verify the port is released. Current
known passing counts are diagnostics `5`, evaluation `7`, projection `19`,
and the scene gate `11`.

### Tool discipline for the next agent

- Run the generic model-repository check with
  `python3 tools/validate_repository.py` after source/model changes. Review
  Griffin through its typed SysML/USD Editor observations; do not maintain a
  separate Python assertion set for the vehicle model.
- Validate `.sysml`/`.kerml` through the production `luncosim --validate`
  path and the Twin's `ValidateSysml`/`AnalyzeSysml` queries; do not add a
  filesystem walker or parse source text in Rhai.
- Author SysML source edits through the LunCoSim SysML document/editor path
  when working live, so source generations, diagnostics, and undo history are
  preserved. Keep `twin.toml` responsible for source-set and verification
  selection.
- Author USD through LunCoSim's document tools and typed `ApplyUsdOp(s)`/
  Editor workflow. Do not patch USDA text directly, duplicate composed prims,
  or use a screenshot as proof of a source-to-scene realization.
- Use `sysml_modelica_constraints.rhai` and the typed Modelica document/
  experiment APIs for Modelica proposals; read back the exact experiment and
  source generation, not a display-name or run-list position.
- Keep authored policy in Rhai, generic semantic mechanisms in Rust, equations
  and dynamic state in Modelica, and realized scene facts in USD. A new Griffin
  number table or relation parser is a design failure even if it makes one
  scene pass.

### Current bounded semantic contract

The IR currently supports source-linked scalar arithmetic/boolean expressions,
conditionals, typed literals, fixed primitive multiplicities, parameters,
diagnostics, deterministic fingerprints, and provider observations with
`pass`, `fail`, `inconclusive`, and `error` outcomes. Modelica lowering is a
backend for that subset. Rumoca parses/compiles Modelica; it does not resolve
SysML/KerML, infer Griffin intent, navigate SysML features, or provide
requirement provenance.

The following are still generic implementation work, not Griffin workarounds:

1. typed feature chains and reference navigation;
2. constraint invocation, argument binding, defaults, and result typing;
3. collections, indexing, filtering, and aggregate expressions;
4. quantity/unit dimensional checking and conversion across providers;
5. null/invalid/error propagation and observation freshness semantics;
6. requirement/constraint/assert/assume/verify/satisfy membership provenance;
7. configuration, mode, phase, interval, and temporal applicability; and
8. state/action/transition execution and typed Modelica result provenance.

Do not add a Griffin-specific parser branch, a hidden Rhai expression parser,
another qualified-name table, or a second unit/vector representation to avoid
these gaps. Extend the generic AST/IR/provider contract and add a generic
fixture before using the capability in Griffin.

## Next Griffin implementation sequence

### Step 0 — baseline and source audit

Start from Griffin commit `c1efe88` and keep this repository's existing dirty
state visible. Run the current visual-configuration verification and record
the structured baseline (`22` checks, `0` failures, `27` component records,
`6` rail records). Do not interpret the current legacy runtime warnings about
input bindings, rendering quality, or startup prelude classification as SysML
semantic evidence. The existing `assembly_editor_proposal` path still needs
the active Twin setting `numerics.solver.residual_abs` before it can be used as
the numerical Editor gate.

### Step 1 — finish the generic semantic prerequisites

Before authoring a large Griffin model, implement and test the generic
features needed to remove its current workarounds: feature chains, invocation,
collections/aggregates, unit contracts, binding/provider identity, and
constraint-to-requirement provenance. Preserve source spans and stable handles
through every node. Each addition needs an inline mechanism test plus an
authored Rhai/scene/API test if it is visible at that boundary.

### Step 2 — author one real Griffin source slice

Use `twins/astrobotic-griffin-1/requirements/` and start with one landing-leg
or tank-support slice, not the whole lander. The slice must contain actual
typed part/feature usages, multiplicities, frames, endpoint features, a
reusable `constraint def`, a constraint usage with bindings, a requirement,
and a verification case. Numeric values may be study estimates, but each must
carry its data class and provenance; do not turn a public unknown into a
flight fact.

The first recommended slice is one landing leg because it exercises topology,
frames, paired symmetry, endpoint bindings, strut geometry, and the foot load
interface. The model should derive the upper pivot, lower foot interface,
strut axis, damper axis, and contact datum from source relationships. The
builder must not receive a parallel hand-authored station table.

### Step 3 — connect provider observations

Bind each source feature explicitly to `usd`, `modelica`, telemetry, source,
or derived provider, with target identity, frame, unit, and time-validity
contract. A missing/stale/invalid observation must be visible as
inconclusive/error according to the verification policy, never fabricated as
zero or converted silently to ordinary false.

### Step 4 — expand the model in vertical slices

After the first slice passes source, IR, provider, and evidence gates, expand
in this order: body/deck and tank stations; all landing-leg pairs; engine
cluster and skirt; ramp rails/hinges/clearance; payload/FLIP interface; then
mass/COM/inertia, propulsion, power, thermal, and mission behavior. Every
slice must update SysML source, generic constraints, provider bindings,
Modelica/USD realization, and evidence together.

### Step 5 — visible Editor and mission acceptance

Only propose typed USD edits after the source revision, constraint fingerprint,
provider observations, local-frame contract, and Editor document generation
all match. Inspect the result in the requested Edit perspective. A parser
pass, Modelica compile, screenshot, or timer-only mission PASS is not enough;
require geometry, physics, mission trace, and structured requirement evidence.

## What full KerML follow-up means

The current `lunco-sysml-ast` layer is a bounded source-backed projection. It
already has source-spanned `SysmlExpression` and `SysmlConstraint` values,
typed operators, literals, feature references, compound children, and explicit
unsupported reasons. It currently recognizes a limited set of constraint
elements and lowers:

- feature/name references when they resolve to features;
- integer, real, boolean, string, and null literals;
- grouping;
- unary and binary operators;
- conditional expressions.

It explicitly marks calls, indexing, metadata access, arrows/body syntax,
collections, unresolved references, invalid literals, and other unsupported
syntax. That is a good fail-closed starting point. It is not a general KerML
evaluator and must not be presented as one.

The full follow-up should therefore be an incremental semantic compiler, not a
large text-to-Rhai translator.

### Missing semantic capabilities

The next implementation must preserve the upstream KerML/SysML metamodel and
semantic resolver rather than inventing a parallel parser. The missing pieces
are:

1. **Complete constraint membership and provenance**

   Preserve the relationship between requirement, constraint definition,
   constraint usage, assert constraint usage, invariant, verification case,
   satisfy relationship, verify relationship, assumption, and assertion.
   Every lowered predicate must retain its source element handle and source
   span.

2. **Feature chains and typed navigation**

   Support `a.b.c`, owned-feature navigation, reference features, redefinitions,
   subset/union relationships where applicable, and the final feature/value
   target. A chain needs its intermediate types, multiplicities, direction,
   and provenance, not just a flattened name.

3. **Invocation and reusable constraints**

   Support constraint definitions with parameters, invocation expressions,
   argument binding, default values, and result typing. This is necessary for
   reusable predicates such as `symmetric_about_plane`, `concentric`,
   `clearance_at_least`, and `temperature_above_limit` to be represented as
   semantic applications rather than ad hoc Rhai calls.

4. **Type and multiplicity inference**

   Infer scalar/quantity/boolean/string/enum/structure/collection types,
   ordered and unique multiplicity, collection element type, and nullable or
   invalid states. Reject invalid operator combinations before runtime.

5. **Quantity and unit semantics**

   Resolve quantity kind and unit compatibility in the semantic graph. Lower
   compatible quantities through the shared engineering-value seam; retain the
   authored unit and conversion in diagnostics and evidence. Do not reduce
   every quantity to an anonymous f64 too early.

6. **Collection and aggregate expressions**

   Add collection literals, indexing, filtering/selection, mapping/collection,
   `min`, `max`, `sum`, `count`, and other standard aggregate forms with typed
   multiplicity. These are needed for tank arrays, engine clusters, leg pairs,
   mass aggregation, and mission traces.

7. **Conditional, null, invalid, and error semantics**

   Distinguish a false requirement from unavailable telemetry, an unresolved
   binding, an invalid unit, and an execution error. Missing data must never be
   converted silently into a pass or an ordinary false result.

8. **Temporal and behavioral expressions**

   Add the semantic boundary for state/mode applicability and temporal checks:
   `always`, `eventually`, `until`, before/after, duration windows, event
   ordering, and trace aggregates. These are needed for thermal limits,
   battery reserve, ramp deployment, landing, and FLIP release.

9. **Analysis and solver result semantics**

   A Modelica result must carry variable identity, units, time interval,
   solver/model revision, residual, convergence status, and provenance. A
   scalar result without this context is not enough for requirement evidence.

### Neutral IR: current bounded contract and extensions

The dedicated `lunco-sysml-ir` crate now provides the initial
`ConstraintIR`/`ExpressionIR` layer. It is serializable, source-linked,
fingerprinted, and independent of Rhai syntax. Extend that owner rather than
creating a Griffin-specific evaluator or moving the IR into generic core.

The current implementation covers typed literals, feature references, unary
and binary operators, conditionals, parameters, fixed primitive
multiplicities, diagnostics, and provider-neutral evaluation. The nodes below
are the required next extensions for full Griffin use; they are not a reason
to duplicate the semantics in `griffin_spec.rhai`.

The minimum expression nodes should be:

```text
Literal(value, type, unit)
FeatureRef(handle)
FeatureChain(base, step, result_type, multiplicity)
Invocation(definition, arguments, result_type)
Unary(operator, operand)
Binary(operator, left, right)
Conditional(condition, when_true, when_false)
Collection(items, element_type, multiplicity)
Index(collection, index)
Aggregate(operator, collection, result_type)
Relation(kind, operands, tolerance, units)
Temporal(operator, trace, interval, predicate)
```

Every node should include:

- source element handle and source span;
- inferred type and multiplicity;
- quantity kind and unit where applicable;
- dependency feature handles;
- a stable structural fingerprint;
- diagnostics or an explicit unsupported reason.

The minimum constraint object should include:

```text
ConstraintId
owner/definition handle
application/membership handle
subject handles
applicability: configuration, mode, phase, interval
expression root(s)
required evidence kind
normative tolerance/limits
source provenance
```

The IR must be usable by three consumers:

1. a Rhai checker/evidence policy;
2. a Modelica/Rumoca lowering adapter for supported algebraic and dynamic
   equations; and
3. a USD/observation adapter for geometry and live-value bindings.

No consumer should reparse the source or inspect raw expression text.

### Binding protocol

An IR feature reference is not automatically a USD path or a Modelica
variable. Add a typed binding layer:

```text
SysmlFeatureHandle
        |
        +--> authored binding declaration
        |      provider = source | usd | modelica | telemetry | derived
        |      target = typed provider identifier
        |      frame/unit/time contract
        |
        +--> observation
               value | unavailable | invalid | stale
               source revision / sample time / provider revision
```

Bindings should be structural Twin data, not hidden name conventions. A Rhai
policy may select an observation provider, but Rust must validate the binding
shape, units, frames, and authority. A binding result should support at least:

```text
passable value
unknown/unavailable
invalid
stale
provider error
```

This is the seam that will let one requirement be checked against source
values, a composed USD pose, a Modelica variable, or a live telemetry sample
without making the requirement language aware of a backend.

### Verdict model

Use a four-state result for normal requirement evaluation:

- `pass` — predicate evaluated and satisfied;
- `fail` — predicate evaluated and violated;
- `inconclusive` — required observation or model result is unavailable/stale;
- `error` — malformed source, invalid binding, incompatible units, unsupported
  execution, or runtime failure.

`unsupported` should be attached as a structured diagnostic and normally map
to `inconclusive` or `error` according to the verification policy. It must not
be hidden as `false`.

## How this produces a meaningful Griffin model

The goal is not just to make a visually plausible lander. The model should
remain coherent when dimensions, estimates, mission phase, or a physical
assumption changes.

### Data classification

Every important Griffin value should carry one of these classes:

1. **Public fact** — directly supported by an accessible supplier or mission
   source.
2. **Reference observation** — inferred from an image, video, or public
   drawing and labelled as such.
3. **Engineering estimate** — chosen to make a bounded model executable when
   no public value exists.
4. **Derived value** — calculated from other authored values or a physical
   model.
5. **Runtime observation** — measured from the current USD, simulation, or
   telemetry state.

These classes must not be mixed silently. A derived centre of mass is not a
public Griffin fact, and an image-estimated tank spacing is not an ICD value.
The report and UI should show the class, source, revision, confidence/quality
note, and dependent calculations.

### Recommended Griffin vertical slices

#### Slice A — authoritative topology and frames

Model the following SysML structure first:

- octagonal open structural body/deck;
- separate tank-support plate;
- four tanks and their mounts;
- seven-engine cluster and skirt;
- four landing legs;
- solar-array assemblies;
- three-section egress ramp;
- payload/FLIP interface;
- avionics/equipment deck.

Each component receives a local frame, an interface frame, an envelope, and
source/estimate provenance. Absolute positions should be derived from frame
relations, not repeated in builder tables.

#### Slice B — geometric constraint execution

Express and execute requirements such as:

- tank openings are concentric with tank envelopes;
- tank stations lie on the support-plane datum;
- landing-leg upper pivots lie under the intended body datum;
- paired legs mirror across the authored port/starboard plane;
- other pairs mirror across the forward/aft plane;
- strut axes meet their upper and lower interfaces;
- engine axes share the intended thrust datum and pattern;
- ramp rails are parallel to their section edges;
- adjacent ramp sections satisfy hinge and clearance relations;
- foot load planes reach the contact datum without interpenetration.

The current Rhai mechanical library proves the relation mechanism. The next
step is to express these relations in SysML/KerML constraint definitions and
invoke them through the neutral IR, so the Griffin observer no longer has to
spell out each relation manually.

#### Slice C — mass properties and structural plausibility

Add estimated mass, material, wall/envelope, and centre-of-mass data to each
component. Derive:

- total mass;
- centre of mass;
- principal inertia estimate;
- leg reaction/load distribution;
- tank-support and deck load cases;
- ramp payload load case.

Use Modelica or an equivalent physical analysis backend for equations. Keep
the visual estimate and the physical estimate linked to the same component
identity, while showing uncertainty instead of implying supplier accuracy.

#### Slice D — propulsion, power, and thermal model

Build parameterized Modelica models for:

- propellant/tank pressure and remaining mass;
- engine thrust and consumption;
- battery state of charge and reserve;
- solar generation by deployment state and illumination;
- avionics, heaters, actuators, and motor loads;
- thermal capacitance, heat paths, radiator/solar contributions, and limits.

Then verify temporal predicates such as:

```text
for the powered mission interval:
  battery.state_of_charge >= reserve_limit
  component.temperature >= qualified_minimum
  component.temperature <= qualified_maximum
  tank.pressure remains within the qualified range
```

These are dynamic trace requirements. A single startup value or one Rhai
sample cannot prove them.

#### Slice E — mission state and physical transitions

Represent the mission sequence as explicit states and applicability scopes:

```text
descent -> contact/landing -> landed -> ramp_deploy
        -> FLIP_release -> rover_egress -> surface_operation
```

The mission checks should prove event order, duration bounds, stability,
contact geometry, FLIP release conditions, and rover egress—not merely wait
for a timer and emit PASS.

## Concrete next steps for the next agent

### P0 — establish the current baseline

1. Keep the current Griffin repository state and existing untracked handover
   note separate from new work until ownership is confirmed.
2. Use the committed Griffin slice as the baseline: `c1efe88`.
3. Confirm LunCoSim `main` contains `f244cf683` before changing model code;
   future core changes belong in `terrain-streaming` and must be fast-forwarded
   into `main`.
4. Re-run the production visual-configuration test and retain the structured
   `22 checks / 0 failures / 27 components / 6 rails` evidence.
5. Treat input-binding, rendering-policy, missing-light, and Rhai reload
   warnings as separate runtime cleanup items; do not confuse them with
   semantic or Cargo correctness.

### P1 — complete the semantic constraint graph

1. Audit the current upstream `sysmlv2-model`/semantic APIs and use their
   element, relationship, expression, resolver, and diagnostic objects.
2. Extend the immutable analysis with constraint membership/application,
   requirement/verification links, parameter bindings, feature-chain targets,
   inferred type/multiplicity, quantity kind, and applicability scope.
3. Preserve source spans and stable handles through every projection.
4. Keep unsupported constructs explicit and source-located.
5. Add official KerML/SysML expression and constraint fixtures before adding
   Griffin-specific cases.

### P2 — extend `ExpressionIR`/`ConstraintIR`

1. Extend the existing dedicated `lunco-sysml-ir` crate, not generic core or
   Griffin Rhai.
2. Add feature-chain, invocation, collection/aggregate, quantity, and
   applicability nodes with compile-time type/unit/multiplicity inference.
3. Preserve structural fingerprints and caches keyed by source revision, model
   revision, adapter configuration, and solver version.
4. Add deterministic budgets, cycle detection, recursion limits, cancellation,
   and structured diagnostics as the new nodes become executable.
5. Keep the IR read-only to Rhai and Modelica adapters; add generic fixtures
   before adding Griffin-specific source.

### P3 — complete the IR observation contract

1. Extend the existing provider observations to source, USD, Modelica,
   telemetry, and derived-value bindings.
2. Add frame/unit/time contracts to every binding.
3. Preserve pass/fail/inconclusive/error semantics for missing, stale, and
   invalid observations.
4. Include provider revision, sample time, model revision, residual, and
   provenance in evidence.
5. Make `source_with_selection` and the structured IR APIs the standard route
   for requirement-linked reports.

### P4 — compile the first Griffin constraints

Start with a small, high-value set:

1. tank/support-plane coincidence;
2. tank-opening/tank-envelope concentricity;
3. landing-leg paired symmetry and under-body relation;
4. engine thrust-axis and pattern relation;
5. ramp rail parallelism and hinge clearance.

For each one, implement the same path:

```text
SysML constraint definition/usage
  -> semantic graph
  -> neutral IR
  -> Rhai mechanical relation adapter
  -> typed evidence linked to requirement and verification
```

The existing hand-authored Griffin checks may remain as a compatibility
baseline during this migration, but they should be replaced one relation at a
time by IR-driven checks.

### P5 — connect Modelica/Rumoca

1. Define a typed parameter export from SysML values into Modelica.
2. Reuse Modelica Standard Library components wherever applicable.
3. Compile one bounded Griffin physical analysis case at a time.
4. Return typed variables, units, traces, convergence, residuals, and source
   revisions.
5. Add checks for mass properties, battery reserve, temperature limits, tank
   pressure, and landing-leg loads.

### P6 — derive the USD assembly

1. Replace repeated builder station arrays with a resolved component/frame
   plan.
2. Derive beam, tank, engine, leg, ramp, panel, and foot transforms from
   relations and dimensions.
3. Keep component references and provenance visible in the composed stage.
4. Validate one lander cardinality and no hidden duplicate source.
5. Use the Edit perspective for inspection and typed operations for changes.

### P7 — acceptance

Acceptance requires separate evidence for:

- semantic source analysis;
- constraint compilation and unsupported diagnostics;
- geometry relations;
- Modelica convergence and physical bounds;
- USD composition/cardinality;
- Editor visual result;
- mission state transitions;
- thermal/power/pressure traces;
- final structured verdict.

A parser pass, compile pass, screenshot, or timer-only PASS is not sufficient.

## Definition of architectural success

The architecture is successful when a change such as “move the tank plate,”
“change the estimated tank envelope,” “raise the minimum avionics temperature,”
or “change the leg datum” requires changing the authoritative SysML value or
constraint and then regenerating/re-evaluating the affected plans—not editing
Rust, a second Rhai table, Modelica constants, and USDA transforms separately.

The same requirement should be able to produce:

1. a source-backed human-readable report;
2. a generic Rhai geometric verdict;
3. a Modelica physical-analysis predicate where applicable;
4. a USD/Editor realization check; and
5. traceable evidence that identifies the exact source, subject, realization,
   data class, unit, revision, and verdict.

That is the path from the current successful typed Griffin geometry slice to a
proper, extensible, physically meaningful Griffin Twin.

## Standards and source basis

The semantic direction should remain aligned with public standards rather than
becoming a Griffin-specific language:

- [OMG SysML v2 specification overview](https://www.omg.org/spec/SysML/2.0/About-SysML)
  for the SysML/KerML metamodel and normative machine-readable artifacts;
- [official KerML textual grammar](https://github.com/Systems-Modeling/SysML-v2-Release/blob/master/bnf/KerML-textual-bnf.kebnf)
  for source syntax;
- [official KerML expression examples](https://github.com/Systems-Modeling/SysML-v2-Release/blob/master/kerml/src/examples/Simple%20Tests/Expressions.kerml)
  for expression coverage fixtures;
- [Modelica language specification](https://specification.modelica.org/);
- [Modelica equations specification](https://specification.modelica.org/maint/3.5/equations.html);
- [FMI standard](https://fmi-standard.org/docs/main/) for a future typed
  co-simulation boundary where the physical model is external to the current
  process.

Public Griffin imagery and reference material remain useful for proportions
and topology, but they are not a complete supplier ICD. The model must keep
public facts, visual observations, engineering estimates, derived quantities,
and runtime measurements visibly distinct.
