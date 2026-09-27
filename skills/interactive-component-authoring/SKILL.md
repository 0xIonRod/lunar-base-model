---
name: interactive-component-authoring
description: >
  Build and review an interactive LunCoSim USD assembly one reusable component
  at a time. Use when a visual model, vehicle, payload, or articulated scene
  must be dimensionally credible, easy to correct, and continuously checked in
  the live Editor.
---

# Interactive component authoring

This is the repository-local playbook for building a scene without losing the
design intent that makes a CAD or multiphysics model maintainable. It is a
workflow guide, not a second USD writer. The Editor's document owner remains
the only owner of persistent USD edits; Rhai supplies dry plans, policy, and
tests; SysML supplies normative requirements and named dimensions; Modelica
supplies equations; Rust supplies generic typed capabilities.

## The governing cycle (the agreed editing rule)

Never build a complete vehicle or scene as one opaque batch. Decompose the
work into named, reviewable component tasks and close this cycle for each task:

```text
discover exact document / preview / edit target / generation
  -> read the component contract and its mount datum
  -> inspect the existing composed prim and authored affordances
  -> make one dry, typed Rhai plan
  -> review and apply one small Editor batch
  -> wait for projection_ready and the matching generation
  -> inspect exact paths, transforms, bounds, and relationships
  -> inspect the focused Editor Perspective view
  -> run the component's Rhai/SysML gate
  -> save explicitly through the document owner
  -> record evidence before starting the next component
```

If the visual or typed check is wrong, stop at that component, correct only
that component, and repeat the cycle. Do not accumulate several unverified
changes and diagnose them as a batch. Hot-register Rhai changes in the running
process; restart only when a generic Rust capability has changed.

This is an interactive loop, not a batch-build convention: one visible issue
gets one small command, one projection/readback, and one focused gate. If the
same-generation projection fence remains false after a bounded wait, renew the
exact preview/document/edit-target lease with the typed `OpenUsdPreview`
command and record the capability gap; never restart the app or silently skip
the readback.

The default task granularity is one component or one repeated station, not one
vehicle. For example, a lander pass is ordered as body/bus, one tank group,
one landing leg, the engine cluster, each ramp, and each solar panel. A rover
pass is chassis, each wheel, mast, and solar array. The exact order may change
when a mount dependency requires it, but every task still has its own plan,
readback, screenshot, and gate.

## Contract before geometry

Before authoring a component, write down:

- local coordinate frame, units, up/forward convention, and origin datum;
- envelope and critical dimensions in SI metres, with source or an explicitly
  labelled study assumption;
- mount socket and plug frames, allowed degrees of freedom, and relationship
  to the parent datum;
- visual geometry, collision geometry, mass/inertia owner, and physics role;
- physical material assignment for every relevant role (structure, pressure
  boundary, thermal, electrical, or contact), with typed material identity,
  property units, operating conditions, provenance, and confidence; represent
  a COPV liner and composite overwrap as separate materials, not one sphere
  label;
- ports, controls, deployment limits, variants, and expected initial state;
- component requirement IDs, verification function, and evidence to collect.

Keep these facts in one source. A SysML requirement or parameter is not copied
into a builder as a second literal table. A builder reads the source, validates
the exact values, and returns an error for missing or malformed values. A
relationship or frame is preferable to a guessed absolute translation when
the generic editor supports it.

Do not store engineering material assignments or property vectors in free-form
strings, CSV fields, shader inputs, or comments. USD appearance (`UsdShade`) and
contact material (`UsdPhysicsMaterialAPI`) are separate from structural,
thermal, and electrical properties. Until the shared typed material catalogue
and its cross-domain bindings exist, keep one sourced, typed material record in
the Twin's SysML source set and refer to it from component requirements; record
the missing generic adapter instead of inventing an external library resolver.
Do not create independent numeric copies in USD, Rhai, and Modelica. A visual
sphere's outer radius is not a pressure-wall thickness or a validated pressure
boundary.

Keep material definitions reusable and separate from their component-role
assignments. Record grade/product form/temper or composite layup and direction;
give each used property its unit, operating range, source revision and status
(sourced, derived, or assumed). Separate candidate grades from the selected
material, and do not promote a study assumption into a qualified allowable.
Use one indexed SysML material package as the catalogue source when supported;
until typed import/resolution and downstream projection are available, expose
that as a generic tool gap instead of encoding a material name or property
vector in a string.

Model a surface finish or coating as a separate typed selection layered on the
substrate, with assignments scoped to the actual component face or region. One
substrate may have several finish options; the selected finish can carry
coating stack/order, thickness or areal mass, process, and environmental limits
when relevant. Keep its sourced optical/thermal properties in the engineering
record. A typed renderer mapping may select a LunCo shader preset for the
finish, but shader color/metallic/roughness are visual controls and never
substitute for absorptance, infrared emittance, coating thickness, or Modelica
thermal inputs. The generic finish catalog and `UsdShade` mapping remain
explicit tooling gaps until implemented.

## Resolve spatial relations in Rhai first; use Modelica when needed

For an anchored placement over typed frames, use the shared
`spatial_relations` Rhai tool rather than repeating coordinate arithmetic:
`coincident` aligns complete datums, `offset` applies a `Vec3` in the fixed
datum frame, `coincident_translation` preserves the moving orientation, and
`point_on_axis` derives a station from a frame, native `Vec3` axis, and metric
distance. Measure the resulting translation/rotation residual with the same
tool. The values stay native `Transform`/`Vec3` throughout; do not encode
stations, vectors, or solved values as CSV or metadata strings.

This is an anchored direct-placement API, not a persistent relation graph or a
general constraint solver. Its current arguments are typed transforms rather
than projected SysML datum handles. Keep dimensions and datum values in SysML;
do not copy them into the Rhai call as an independent source. Use the typed
SysML-to-Modelica path when an explicit SysML constraint usage must be resolved
or coupled equations must be solved and checked independently.

For the supported Modelica coincident-point translation policy:

1. Read only the required SysML facts with
   `sysml_modelica_constraints::analyze_selected(path, attribute_names)` and
   choose the exact qualified constraint usage. Its standard binding
   connectors identify the moving and fixed point features; do not duplicate
   either point in the Rhai caller.
2. Create a scratch Modelica document with
   `modelica_editor::new_scratch(source, name)`, retain its returned `doc_id`,
   and inspect the current source generation. Never assume the active document
   is the scratch document.
3. Call
   `sysml_modelica_constraints::begin_coincident_translation(doc_id,
   generation, report, usage_name)`. It generates the small Modelica source
   from typed facts, verifies the Editor source readback, and returns a bounded
   polling ticket tied to that source generation.
4. Advance `poll_coincident_translation(ticket, generated)` on later editor or
   simulation ticks while `pending` is true. Do not block with a Rhai loop or
   wall-clock sleep. The ticket first resolves the deferred command
   acknowledgement, then polls `RunStatus` and `GetExperimentResult` by their
   exact command/run identities. It rejects a changed source generation and
   checks finite native `f64` samples plus the relation residual.
5. Feed the completed native `Vec3` into
   `coincident_translation_placement_plan` with the exact USD document,
   edit-target, path, and generation. Submit its operations through
   `propose_coincident_translation_plan`; inspect the visible Editor proposal
   and projected result before committing. A solve result is never an implicit
   USD write.

The Modelica source string is the compiler input boundary, not a data store:
SysML facts and result vectors remain typed throughout Rhai and only become
text while emitting valid Modelica syntax. This bounded policy solves one
documented translation relation; it is not a general CAD constraint solver or
an automatic placement engine.

## Reuse typed parametric geometry

Build repeated, axisymmetric, or profile-based solids with the shared native
geometry API before writing component-specific vertex loops. `extrude_profile`
and `revolve_profile` consume native `Vec2` coordinates and return typed mesh
topology; `DVec3`/`DTransform` remain the geometry and placement values until
the Editor's standard `UsdGeomMesh` operation boundary. The design dimensions
come from SysML, while segment counts and sampling density are rendering
policy. Keep the mesh's axis, face winding, normals, bounds, and contact datum
in the positive component gate. Hand-built topology in Twin Rhai is appropriate
only when it represents a genuinely novel, named profile not covered by the
shared primitives; if it recurs, promote the generic operation to Rust and
expose its native type to Rhai.

Do not create a general `ParametricCAD` USD schema for dimensions or mate
equations. Standard USD geometry records the result; SysML remains the design
source, and Modelica remains the solver for coupled physical constraints.

## Lessons carried over from CAD and multiphysics tools

The following principles are deliberately tool-neutral:

| Practice in established tools | LunCoSim consequence |
| --- | --- |
| Blender keeps objects in named collections and makes origins/transforms explicit. Applying a transform changes the modelling basis, so it is a deliberate boundary operation. | Give every component a stable USD root and local origin. Keep authoring transforms on the assembly instance; do not bake a correction into a mesh or silently apply scale. Use SI units and inspect the composed result. |
| FreeCAD's Part Design uses constrained sketches and datum planes; robust parametric work is anchored to stable references rather than a long chain of incidental faces. | Express mount datums, station arrays, and named frames explicitly in SysML/USD. Prefer stable parent paths and frames over leaf-name inference or a chain of guessed offsets. |
| SOLIDWORKS assemblies solve mates as relationships. Good practice anchors parts to one or two fixed references, avoids mate loops and redundant constraints, and uses subassemblies. | Attach components to explicit sockets/plugs, keep the parent assembly responsible for placement, and avoid duplicate constraints or transform opinions. Use a separate component file and a small subassembly root. |
| Fusion uses components, user parameters, joints, and a parametric timeline. Position capture is an explicit design-history event, not an untracked drag. | Treat each Editor batch as a small journaled design-history event. Use named parameters and typed relationship operations; never treat an interactive drag or screenshot as the source of truth. |
| COMSOL separates a geometry sequence from materials, physics, mesh, and named selections. Geometry labels and reusable selections prevent fragile entity-number edits. | Keep visual topology, collision/physics, materials, and requirements as separate concerns. Give important frames, ports, and groups stable names and test them by path/relationship, not by incidental child order. |

These tools also share a practical rule: build a simple, constrained skeleton
first, then add recognizable detail, and verify each dependency before adding
the next one. A pretty screenshot cannot replace a valid relationship,
collision envelope, or runtime contract.

## LunCoSim authoring rules

1. Use **Editor Perspective** for component and assembly edits. Build/View are
   for composition and operation, not for silently changing authored topology.
2. Discover and retain the exact `DocumentId`, `UsdPreviewId`, view, edit target,
   and document generation. A display name or an old screenshot is not an
   identity. Reject stale generation rather than applying over it.
3. Plan with generic typed tools such as `assembly_builder`,
   `component_editor`, `assembly_edit`, frame-alignment, and measurement
   helpers. Apply only through the document command/journal owner. Never edit
   `.usd`/`.usda` text directly, use a hidden second writer, mutate ECS to make
   a view look correct, or flatten a referenced component to save time.
4. Keep a dry plan separate from apply, inspection, and test. A plan is pure and
   idempotent; an apply result reports the acknowledged command and new
   generation; an inspector is read-only; a test fails closed on missing,
   stale, or unavailable evidence.
5. Build reusable components as separate assets with a stable root, explicit
   default prim, standard USD schemas, provenance, and named mount/functional
   frames. The parent assembly owns instance placement, relationships, variants,
   and cross-component wiring.
6. Use standard USD schemas for geometry, physics, materials, lights, and
   relationships. Add a project field only when USD has no suitable concept,
   and keep the field names and ownership documented.
7. Keep visual and physical representations distinct but co-located in the
   contract. A render-only proxy may be simple; it must not hide a missing
   dynamic body, collider, joint, port, or reference in a physics scene.
8. Measure from composed USD facts (`QueryUsdPrim`, bounds, authored primitive
   dimensions and scale, or the generic measurement report). Do not infer
   dimensions from a screenshot or an uncomposed source layer.
   Author measurement stages with explicit `metersPerUnit` and `upAxis` values
   that match the source datums. For physics acceptance, query the effective
   Avian collider geometry with
   `QueryUsdPrims.collision_geometry` from the same composed snapshot as the
   visible source geometry. Compare cooked shape, dimensions, and pose after
   mapping both observations to the same frame and SI units; authored proxy
   attributes alone do not prove what the solver will use. Check the typed
   source relationship and contact ownership separately. Use exact cooked
   dimensions when the collider is analytic, and preserve the returned mesh
   or hull topology for mesh colliders. Treat missing cooked geometry as
   unavailable evidence, and do not substitute a conservative bounds envelope
   for an available exact analytic shape.
9. Use SysML for requirement identity, units, thresholds, datums, and
   verification selection. Use Rhai for executable observation and structured
   verdicts. Keep one requirement file and one observer per owning component;
   assembly tests cover interfaces and integration rather than duplicating
   internal part checks. After editing SysML in Editor, confirm that the
   Twin-level `AnalyzeSysml` snapshot has the saved source revision and source
   locations before citing constraint handles or verdicts; single-document
   analysis and the Twin source-set snapshot can differ.
10. Keep physics and clocks deterministic: fixed tick rate, explicit clock
    contract, stable seed/thread policy, no wall-clock sleeps in tests, and
    report the source revision, horizon, ticks, and tolerance in evidence.

## Verification strategy

Make positive conformance evidence the normal test shape: read the normative
SysML/USD source, observe the composed result, and prove that the required
component, geometry, relationship, datum, or runtime outcome is present and
correct. Do not add a negative test merely to prove that an obsolete
implementation name or old shape is absent; update the positive requirement
and assert the required type/profile/topology instead.

Use a negative case only when rejection or safe failure is itself a real
contract, such as malformed source, non-finite data, a missing safety-critical
relationship, stale-generation mutation, unsupported command, invalid units,
or a required fail-safe response. Such a case must be bounded, non-destructive,
and end at the public diagnostic/verdict boundary. A historical regression
example is not enough by itself to justify a negative test.

Write geometry, SysML-projection, and Twin-model acceptance checks as Rhai test
assets in the production scripting/scene gate. Do not embed Griffin dimensions,
mesh expectations, or relationship scenarios in Rust tests. Rust owns reusable
typed algorithms and API registration; Rhai owns positive contract evidence at
the public model/tool boundary.

## Visual review order

At every component checkpoint inspect in this order:

1. silhouette and orientation (body profile, wheel count, nozzle direction,
   panel/ramp opening direction);
2. origin and mount interface (no floating gap, penetration, or unexplained
   offset; the socket and plug frames agree);
3. metric envelope and symmetry (left/right or fore/aft station pairs, clearances,
   ground contact, and reachable deployment range);
4. topology and ownership (the expected root, references, schemas, materials,
   colliders, ports, and no obsolete proxy);
5. materials, camera, lighting, and composition.

Use a focused preview or frame the selected component. An overview is useful
only after the focused checks pass; occlusion and perspective can hide a bad
mount. Screenshots are evidence paired with a document/generation, never a
replacement for typed readback.

## Verification matrix

Every component task should leave a small record containing:

```text
component, source revision, document/view/generation
plan operation count and command acknowledgement
projected readback: paths, transforms, bounds, relationships, references
focused screenshot path
component verdict and evidence channel
assembly checks affected (if any)
```

Run the component gate immediately. Then run the smallest affected assembly or
physics fixture. Run the complete mission only after the component sequence is
closed and all lower-level gates pass. A failed runtime watchdog is evidence of
an incomplete contract; do not turn it into a pass by widening a limit or
adding a timer-only fallback without a requirement change and review.

## Completion checklist

- [ ] Contract and dimensions are in the owning SysML/source file.
- [ ] Component has its own asset/root, mount frame, visual/physics roles, and
      Rhai verifier.
- [ ] The change was made in Editor Perspective through a typed plan and save.
- [ ] Readback and focused visual review match the same projected generation.
- [ ] Component and affected assembly tests pass with fixed-clock evidence.
- [ ] No raw USDA edit, duplicated literal, hidden fallback, or stale-generation
      write was used.
- [ ] Evidence and `git diff --check` are recorded before commit.

## References

This workflow is consistent with the documented design-history and relationship
practices in [Blender transform application](https://docs.blender.org/manual/en/3.6/scene_layout/object/editing/apply.html),
[FreeCAD Part Design](https://github.com/FreeCAD/FreeCAD-documentation/blob/main/wiki/PartDesign_Workbench.md),
[Fusion design history](https://help.autodesk.com/view/fusion360/ENU/?contextId=DESIGN_HISTORY),
[Fusion components](https://help.autodesk.com/view/fusion360/ENU/?contextId=ASM-COMPONENTS),
[SOLIDWORKS assemblies](https://help.solidworks.com/2015/english/solidworks/sldworks/c_Assemblies_first_map_topic.htm),
[SOLIDWORKS mate best practices](https://help.solidworks.com/2024/English/SolidWorks/sldworks/c_Best_Practices_for_Mates_SWassy.htm),
[COMSOL geometry sequences](https://www.comsol.com/support/learning-center/article/geometry-concepts-and-nomenclature-in-comsol-multiphysics-36081),
and [COMSOL named selections](https://www.comsol.com/support/learning-center/article/how-to-select-geometry-34341).
The repository's `assembly-quality`, `author-usd-component`,
`author-rhai-tool`, `edit-usd-assembly`, and `sysml-requirements` skills remain
the executable LunCoSim-specific contracts; this guide supplies their
interactive sequencing and review discipline.
