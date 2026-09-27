# Griffin SysML-driven workflow handover

**Date:** 2026-09-22
**Repository:** `/home/rod/Documents/models/lunar-base-model`
**Related worktrees:** `/home/rod/Documents/luncosim-workspace/terrain`, `/home/rod/Documents/luncosim-workspace/main`
**Status:** implementation is still active; this report is a handover and design baseline, not an acceptance report.

## 1. Mission and definition of done

The objective is to build one recognizable, componentized Griffin lander Twin
and a supported Griffin-to-FLIP surface mission in LunCoSim:

```text
descent and landing
  -> landed state
  -> ramp deployment
  -> FLIP release
  -> rover egress
  -> first surface operations
```

The lander must be authored as real subsystems rather than one decorative
mesh. At minimum the decomposition is:

- octagonal open structural body/deck;
- separate central tank-support plate with four tank openings;
- four COPV tanks and their mounts;
- seven-engine propulsion cluster and engine skirt;
- four landing legs, including upper clevises, paired canted struts,
  shock absorber, foot yokes, and shallow dished load foot;
- solar arrays, hinges, brackets, and standoffs;
- avionics/equipment deck;
- three-section egress ramp with rails and transition interfaces;
- payload/FLIP interface;
- thermal, power, propulsion, and mission-control model boundaries.

Every component must have:

1. a source-backed or explicitly assumption-labelled SysML definition;
2. typed dimensions, material, finish, mass/thermal/pressure data where
   relevant;
3. relationships to neighboring components instead of duplicated absolute
   placement literals;
4. a reusable positive verification case;
5. a Twin-native source/evidence link;
6. an Editor-perspective visual result that can be inspected immediately.

Do not claim flight fidelity where the public Griffin ICD is unavailable.
Separate public facts, engineering assumptions, visual-study values, and
runtime-proxy values in the model and in the evidence.

## 2. Authoritative architecture

The single source of truth is SysML v2/KerML plus project domain libraries.
The other layers consume it:

```text
SysML source
  structure, requirements, units, materials, relations, constraints,
  modes, mission phases, verification, sources
        |
        v
typed semantic SysML model in Rust
        |
        +--> Rhai policies and generic verification
        |
        +--> Modelica/Rumoca solve-once or dynamic simulation
        |       equations, thermal, power, pressure, motion, degradation
        |
        +--> typed resolved geometry/placement plan
                |
                v
       Rust generic primitive mesh operations
                |
                v
       USD realized assembly and physics representation
```

Responsibilities are deliberately separate:

- **SysML:** authoritative requirements, quantities, units, topology,
  component relationships, constraints, modes, mission phases, evidence
  methods, and provenance.
- **Rust:** generic semantic projection, typed handles, unit/value support,
  primitive geometry kernels, command contracts, and async solver bridges.
- **Rhai:** orchestration, policy, generic requirement enumeration, composite
  shape recipes, and Editor command plans. Rhai must not contain Griffin
  engineering numbers that also exist in SysML.
- **Modelica/Rumoca:** reusable equations and dynamic models. Generated models
  are a backend artifact, not a second requirements source.
- **USD:** realized geometry, transforms, materials, physics, and optional
  provenance references. USD is not the design source.

Do not introduce another requirements language unless a documented SysML
semantic limitation is demonstrated. CAD languages can be used as optional
geometry tools, but they must not become a second Griffin source of truth.

## 3. Requirements must span the whole Twin

The requirement bridge must support multiple semantic levels.

| Level | Example | Required execution path |
|---|---|---|
| Geometry/CAD | leg foot is coincident with its load interface; rail is parallel to ramp edge; tank hole is concentric with tank | typed frame/point/vector relations and geometry checks |
| Component | tank volume, pressure, wall thickness, alloy, finish, solar-panel dimensions | typed SysML values plus algebraic Modelica calculations |
| Subsystem | engine thrust, power balance, thermal rejection, structural loads | Modelica/Rumoca equations and parameterized components |
| Operating mode | engines active in descent; ramp deploys before rover egress | SysML behavior/state model plus Rhai policy |
| Mission | battery reserve, temperature limits, landing deadline, rover egress | dynamic trace plus temporal verification |
| Lifetime | capacity fade, pressure decay, thermal cycling, accumulated energy | time-dependent model and lifecycle analysis |

The executable requirement representation needs typed fields equivalent to:

```text
RequirementId
SubjectRef
ApplicabilityScope(configuration, mode, mission_phase)
TypedPredicate
Quantity/Unit/Tolerance
EvidenceSpecification
Source/Revision/Span
VerdictPolicy
```

The predicate algebra should eventually cover:

- scalar comparisons and ranges;
- equality of typed quantities with unit conversion;
- point/vector/transform relations;
- distance, angle, area, volume, mass, center of mass;
- equations and reusable constraint definitions;
- min/max/sum/integral/average over a trace;
- `always`, `eventually`, `until`, `before`, `after`, and duration windows;
- event and mode applicability;
- solver convergence and residual requirements;
- structured evidence and verdicts.

For example, “battery must not drain” is not an adequate requirement. The
model should express a precise condition such as:

```text
During mission phases powered by the battery:
    stateOfCharge >= reserveLimit
```

Likewise, component temperature should be expressed as a bounded condition
over a defined mode or lifetime interval, not as a one-time number.

SysML v2 already provides requirements, reusable constraints, analysis cases,
verification cases, and structured verdict concepts. The primary gap is our
semantic execution and readback layer, not the absence of a suitable language.

## 4. What already exists in the LunCoSim core

As of 2026-09-22, the generic SysML foundation is available on LunCoSim
remote `main` at `f244cf683`. The `terrain-streaming` worktree and remote
`main` point to the same commit; future core changes should continue in
`terrain-streaming` and be integrated with a fast-forward, not a cherry-pick.

The core contains these foundations:

- `SysmlElementHandle` and `SysmlFeatureHandle`;
- source revision and content fingerprinting;
- cached immutable analyses;
- typed primitive/quantity/collection classification;
- recursive literal projections for vectors and nested values;
- `SysmlRelationship` with typed endpoint handles;
- `SysmlConstraint` with source-spanned expression trees;
- requirement and verification records;
- Rhai registration of SysML handles, types, quantities, attributes,
  requirements, verifications, relationships, and expressions;
- `lunco-sysml-ir`: source-linked typed constraint compilation, multiplicity
  and operator validation, deterministic fingerprints, diagnostics, and
  provider-neutral four-state evaluation;
- `lunco-sysml-modelica`: typed IR lowering to standalone Modelica admitted
  through the Rumoca parser boundary;
- native Rhai methods on `SysmlModel` plus path-level structured APIs
  (`sysml_constraint_ir`, `sysml_modelica_constraint`, and
  `sysml_evaluate_constraint`);
- canonical `lunco://` source/asset identity in the authored fixtures and
  production scene test; USD prim targets remain `/World/...` paths;
- generic procedural profile extrusion/revolution and tapered-beam geometry.

These are foundations, not proof of full SysML execution. The bounded IR
currently handles typed scalar/boolean expression slices, conditional
expressions, fixed primitive multiplicities, source diagnostics, and provider
observations. It still lacks feature-chain navigation, invocation/default
arguments, collection/index/aggregate semantics, complete quantity conversion,
constraint membership provenance, applicability, and behavioral execution.

## 5. Required core changes, in order

### P0 — establish a clean integration baseline

1. Inspect all dirty paths before touching them.
2. Keep model-repository work separate from terrain/core work.
3. Verify that the core baseline is `f244cf683` (or a descendant containing
   it). If a core change is needed, make it in `terrain-streaming`, then
   fast-forward `main`; do not create an equivalent cherry-pick commit.
4. Do not merge the current specialized `SphericalCapMesh` experiment as-is.
   A spherical foot should be authored in Rhai from the generic
   `RevolveProfileMesh` primitive; Rust should expose generic kernels rather
   than Griffin-specific shape operations.
5. Run `git diff --check` and focused package tests before every integration.

### P1 — complete the typed SysML semantic model

Extend the existing AST projection, without introducing engineering strings,
to expose:

- requirement-owned assumed and required constraints;
- constraint definitions/usages and typed parameters;
- calculation and analysis-case definitions/usages;
- feature binding and reference chains;
- typed vectors, points, directions, frames, transforms, and matrices;
- quantity dimensions and unit conversion;
- relation kind and endpoint semantics;
- source spans and revision on every derived fact;
- applicability by configuration, operating mode, and mission phase.

Do not encode vectors as CSV, metadata as escaped JSON, or component paths as
engineering data. Text is acceptable only at a true boundary such as a file
path, USD path, source URI, or human documentation.

### P2 — use and extend the generic IR policy surface

Rhai can now consume a bounded neutral IR without Griffin-specific number
tables:

```text
model = twin.sysml_model(source_set)
requirements = model.requirements()
for requirement in requirements:
    evidence = verify_requirement(requirement, twin_observables)
```

Use the existing path-level API for transport/API callers and a native
`SysmlModel` for repeated in-process access. Extend the generic AST/IR/provider
surface for feature chains, invocation, collections, units, provenance, and
applicability before asking Griffin Rhai to depend on them. Specialized
functions are reserved for real domain semantics such as tank pressure, ramp
deployment, or landing stability; they must not hide absent language support.

Positive tests are the default. Negative tests are appropriate only when
checking an important obsolete behavior, safety boundary, or diagnostic path.
Do not add meaningless tests such as “body is not Cube”; test positively that
the body is an octagonal frame.

### P3 — extend the typed Modelica/Rumoca bridge

The bounded `lunco-sysml-modelica` adapter already accepts valid IR and emits
Rumoca-admitted standalone Modelica. Extend the bridge toward a typed solve
request containing:

- source revision/fingerprint;
- selected constraint/analysis IDs;
- typed parameters and units;
- initial conditions and operating mode;
- requested outputs.

It must return:

- typed values and units;
- convergence status;
- residuals;
- warnings/errors;
- solve duration and backend revision;
- source constraint provenance.

Execution must be asynchronous, cancellable, timeout-bounded, and cached by
source revision, model revision, inputs, and solver version. Modelica should
be used for equations, coupled physical models, and dynamic traces—not as a
mesh generator or a replacement for USD.

### P4 — complete structured Twin-native evidence

Every verification result should carry:

- requirement ID and qualified name;
- verification-case ID;
- subject/component identity;
- source URI, file, span, and revision;
- actual value and required value with units;
- time interval or mission phase;
- solver/model revision;
- residual or tolerance;
- realization path in the Twin/USD stage;
- evidence kind: inspect, analyze, demonstrate, or test;
- verdict: pass, fail, inconclusive, or error.

Do not hide engineering evidence in comments or free-form metadata strings.
Rhai may format a human-readable report, but the underlying result must be a
typed structure.

## 6. Griffin geometry contract

### Body and deck

The Griffin outer frame and central tank-support perimeter use the same
eight-point octagonal profile at different source-owned radii. The central
perimeter remains open around four tank openings. One SysML profile and
relationship graph derives the visible members, stations, and checks.
of them.

### Tanks

Tanks must be sized and positioned from SysML component parameters, including
volume, pressure, material, wall thickness, finish, envelope, and clearances.
The exact supplier ICD is not public; these values must be labelled as
assumptions and reused by visual, mass, pressure, and thermal models.

### Landing legs

The real visual reference shows upper structural attachments, paired canted
load struts, a central damper, side foot yokes, and a shallow round load foot
with a slightly raised/rolled rim. The foot is not a plain cylinder and not a
full sphere.

The leg geometry must be generated from endpoint and frame relationships:

```text
upper pivot -> strut axis/length -> lower foot interface
damper axis -> body/lower interface
foot yokes -> foot load plate
```

The builder should derive beam transforms from those relations, not repeat
hand-authored station arrays.

### Ramp

The supplied reference video shows a three-section ramp. The ramp must have
separate sections, rails, hinges, side supports, traction surfaces, and a
deck-to-ramp transition interface. A single green block or oversized plate is
not an acceptable representation.

### Panels and finish

Solar panels must be separate framed assemblies with correct dimensions,
hinges, standoffs, orientation, cell material, and deployment state. The
lighting problem previously made the model appear white/blurred; material,
normal orientation, exposure, camera/render-target readiness, and stale runtime
overlays must all be validated separately.

### Duplicate lander

The landing demo must compose exactly one Griffin lander source. The visual
assembly, mission scene, and test scene must not each introduce another hidden
lander. Add a positive identity/cardinality check against the composed Twin
root and verify the Editor selection path before visual acceptance.

## 7. Editor and USD rules

- Use the LunCoSim typed Editor/Edit-perspective API for scene edits.
- Do not edit USDA directly unless the API genuinely cannot express a required
  operation; document that exception.
- Query composed state and edit-target ownership before removing or replacing
  prims.
- Do not remove a referenced child merely because it appears in composed USD.
- Use a layer-local clear/override operation when replacing inherited content.
- Validate the active document generation, focused preview, render-target size,
  and image generation when diagnosing blur or stale geometry.
- Keep component USD assets independently inspectable and referenced by the
  assembly rather than duplicated into the mission scene.
- Keep surface normals right-handed, double-sided policy explicit, and closed
  contact geometry checked before blaming lighting.

## 8. Mission simulation acceptance

The mission should be accepted only when evidence proves, separately:

1. source analysis has no relevant diagnostics;
2. SysML requirements and verification cases are loaded from the Twin;
3. exactly one Griffin lander is composed;
4. component cardinalities and source paths match SysML;
5. the landing dynamics remain within world bounds;
6. landing legs and contact geometry are stable;
7. ramp deployment reaches the required three-section state;
8. FLIP remains attached during descent and releases through a supported
   physical/runtime transition after landing;
9. rover egress and first-operation route complete;
10. mission-level power/thermal/mass predicates produce trace-backed evidence;
11. the final Editor view visibly shows the intended component assembly;
12. a deterministic test emits a structured PASS with no hidden timer-only
   success.

Compile success, a parser snapshot, or a visually plausible screenshot is not
evidence for the complete mission objective.

## 9. Current worktree state at handover

At the time of writing:

- model repository branch: `main`, HEAD `c1efe88`, ahead of its remote by nine
  commits; the only current working-tree files are these two untracked
  handover reports;
- LunCoSim `terrain-streaming` and remote `main`: `f244cf683`, clean;
- LunCoSim local `main` is a descendant containing `f244cf683`; inspect its
  status before making another core change;
- Griffin's implementation baseline remains `c1efe88`, including the native
  typed-plan repair and the passing visual-configuration evidence;
- no Griffin source, USD, Rhai, or Rust model file is changed by this report.

The next agent must preserve unrelated dirty work, identify ownership of each
path, and commit model changes in focused units only when explicitly asked.
The handover documents themselves are intentionally left as working-tree
documentation for agent continuity.

## 10. Source and standards references

Project references supplied during the Griffin review:

- Astrobotic Griffin page: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/
- Astrobotic PUG PDF: https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf
- supplied Griffin reference video: https://www.youtube.com/watch?v=zd3RFsNnccE
- honeycomb reference: https://www.researchgate.net/figure/Honeycomb-strength-vs-crush-angle-7_fig4_338209202

Relevant standards/tools:

- OMG SysML v2: https://www.omg.org/sysml/sysmlv2/
- OMG SysML v2 specification and machine-readable libraries:
  https://www.omg.org/spec/SysML/2.0/About-SysML
- Modelica language: https://modelica.org/language/
- Modelica equations: https://specification.modelica.org/maint/3.5/equations.html
- FMI: https://fmi-standard.org/docs/main/
- ISO 10303-242 managed model-based 3D engineering:
  https://www.iso.org/standard/84300.html
- FreeCAD Sketcher: https://github.com/FreeCAD/FreeCAD-documentation/blob/main/wiki/Sketcher_Workbench.md
- CadQuery: https://cadquery.readthedocs.io/en/stable/
- OpenSCAD: https://openscad.org/documentation.html
- SolveSpace exposed solver documentation:
  https://github.com/solvespace/solvespace/blob/master/exposed/DOC.txt

These references support the architecture, but public Griffin imagery is not
an exact supplier ICD. Preserve that distinction in every requirement and
verification report.

## 11. First actions for the next agent

1. Read this report, the architecture report beside it, the Twin `handover.md`,
   `contracts/`, `instructions.md`, and the authoring skills.
2. Verify LunCoSim `main` contains `f244cf683` and run the bounded IR scene
   gate before changing Griffin source.
3. Do not add a Griffin-specific workaround for feature navigation,
   invocation, collections, units, or provenance. Extend the generic
   AST/IR/provider owner first and add its source/Rhai/scene tests.
4. Author one standard Griffin constraint slice in
   `twins/astrobotic-griffin-1/requirements/`, preferably one landing-leg
   endpoint/frame/symmetry/load-foot slice.
5. Bind that slice to USD observations using explicit provider, target, frame,
   unit, and time contracts; keep `lunco://` for source assets and
   `/World/...` for USD prim targets.
6. Prove the slice through source resolution, IR fingerprint, provider result,
   requirement-linked evidence, and a visible Edit-perspective proposal before
   expanding to the full lander.
7. Keep the existing legacy observer as a baseline only; remove its manual
   qualified-name tables and parallel geometry arrays as each slice becomes
   IR-driven.

Do not solve a source-of-truth problem by adding another hardcoded builder
table, string-encoded vector, duplicate requirement literal, or direct USDA
patch.
