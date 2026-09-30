# FLIP v5 → LunCoSim recreation and verification guide

**Revision:** 2026-09-30<br>
**Purpose:** translate the source-backed FreeCAD visual study into an inspectable LunCoSim Twin.<br>
**Evidence boundary:** this is a reconstruction guide, not Astrolab flight software, released CAD, a mobility qualification, or a claim that the v5 proportions are as-built.

## 1. Configuration to preserve

Use [the current source ledger](parameters_v5.json), [requirements/flip-recreation.sysml](../../requirements/flip-recreation.sysml), and [the research record](../../research/flip_rover.md) as one revisioned baseline. Copy every number into a Twin parameter manifest together with its unit, source, and one of `PUBLIC`, `STUDY`, or `TBD`. A parameter marked `TBD` must fail a simulation preflight when it controls that run; allow a run only after supplying an explicit unit-bearing study override in its evidence manifest.

The public configuration facts are: four-wheel skid steer; 0.930 m nominal wheel-family diameter; 192 sprung cables and 96 springs per wheel-family member; two battery packs; a 30 kg maximum-payload claim; a Venturi-listed 450 kg vehicle-mass claim; and a separate 480 kg Griffin/VIPER geometry and launch-mass constraint described by LPSC 2026 paper #1874. Astrolab says FLIP uses the full-size FLEX-family wheel and battery. These sources do not expose the flight chassis envelope, wheelbase/track, tire width/profile, loaded radius, cable routes, suspension, actuator ratings, battery energy, solar area/output, component mass properties, complete payload interfaces, or the lander adapter drawing. Keep those quantities `TBD` until matched supplier or mission data is available.

Values used only to place the v5 illustration are not FLIP specifications: 280 mm wheel width, 1.700 m wheelbase, 2.000 m track, 65 mm inner-rim-face inset, 12-spoke study hub, 1,800 × 1,380 mm one-panel backplate, 0–90° CAD pose range, and an 82° shown pose. Its two battery envelopes follow a public count/location statement, but their shape, dimensions, attachment, mass, and whether they move with the array are study/TBD. The coil/wire shapes, 96-per-face allocation, and smooth tire crown are visual only. Do not derive body mass, inertia, wheel compliance, collision, strength, power, or flight clearance from FreeCAD B-rep volume.

The historical Twin currently contains incompatible proxy parameters. Retire the 0.90 m wheel radius in favor of 0.465 m nominal radius; retire front/rear Ackermann or all-wheel steering in favor of the four-wheel skid-steer configuration; do not treat 2.4 × 1.8 × 0.7 m, 28 V / 83.33 Ah, 4.8 m² / 30%, 0.9 N·m, 200:1, or 400 N·m as FLIP data. Do not conflate 450 kg rover mass with the 480 kg launch/available-space constraint. The 15 km/h generic wheel statement conflicts with Venturi's 20 km/h FLIP listing; neither becomes a simulation cap without a configuration decision. See [research/flip_rover.md](../../research/flip_rover.md) for dated citations and the full discrepancy log.

## 2. File, frame, and ownership contract

Treat `FLIP_rover_v5.FCStd` as reference geometry. Its **saved global** FreeCAD frame is X lateral, Y up, Z longitudinal, forward +Z, in millimetres. The imported v4 snapshot was Z-up; v5's root placement contains the coordinate conversion, so downstream exporters should inspect the saved global basis and must not apply a second 90° up-axis rotation. Convert lengths once to right-handed Y-up SI metres at the USD boundary (`1 mm = 0.001 m`); add an automated datum/origin/handedness round-trip test. Do not add an unexplained 90° rotation to fix a render.

The standalone `export_v5_usd.py` exporter writes `FLIP_rover_v5.usdc` beside the FCStd. It preserves the 195 named CAD visual features and their display colors, uses the saved 82° panel pose, authors the stage as Y-up metres, and bakes each feature's saved global transform into its mesh points. The wheel/spring mesh is a tessellated approximation. This USD is a visual snapshot only: it contains no collision, mass, physics joints, articulated panel animation, suspension, or wheel-contact behavior. Do not make the 192 cables, 96 coil details, solar-cell graphics, decals, or hub ornament separate physical bodies or colliders. Before composing it at `/FLIP`, inspect its stage metadata and round-trip bounds, then use the Twin's supported typed asset/assembly workflow. Give each major assembly a stable USD identity so its render may be replaced without changing physics:

```text
FLIP (one chassis/root body)
├── ChassisVisual / deck / payload-rail datum
├── WheelVisual_FL, WheelVisual_FR, WheelVisual_RL, WheelVisual_RR
├── SolarArrayVisual (panel, cells, support, two opposing camera identities)
├── BatteryPack_A_Envelope, BatteryPack_B_Envelope
├── PowerElectronics_Envelope
└── Payload identities: METAL, LRA, LDES, LunarLiDAR
```

The **raycast rover** is the first physical implementation: one chassis root, four generic wheel stations, four tire/contact definitions, and four explicit drive endpoints. Use simple, named, non-overlapping collision proxies owned by the chassis/wheel component contract. Keep fixed internal battery, motor, gearbox, mast, and array support under the chassis body unless a sourced or explicitly approved study mechanism moves independently. Do not turn the FreeCAD presentation controller into a runtime joint.

If a later study physically articulates the array or uses wheel-carrier rigid bodies, author those as typed USD bodies/joints with explicit local frames, axes, limits, mass/collider ownership, actuator policy, and sampled clearance evidence. Public evidence confirms a collapsible array but does not define a revolute axis, hinge position, actuator, latch, harness, segmentation, or deployed angle. Keep `0° stowed / 82° deployed` as CAD pose labels only.

## 3. Authoring workflow in the Twin

Work in the current Griffin Twin source/Editor and its normal document-owner workflow. Follow the project's [Griffin/FLIP simulation plan](../../handover/griffin-flip-basic-simulation-plan.md), which documents the typed Editor authoring procedure: inspect the exact numeric document ID and generation; query composed topology; lint/preflight; draft a typed assembly plan; review and commit one coherent change; query and run the affected contract; inspect a fresh viewport capture; save only after evidence passes. Use the Editor's typed `assembly_edit`, `assembly_builder`, or component tools for authored USD. Do not hand-edit a live USDA file, patch Editor state through the filesystem, mutate ECS state, or change Rust as a shortcut around a missing typed operation.

The repository's previous Griffin/FLIP planning record recommends `editor_workflow`, `assembly_audit`, and `physics_acceptance` where available. Use one reference/assembly source for vehicle components and avoid duplicate scene geometry. Update the Twin's component catalog and entry scene only through its normal authoring/review contract. At each checkpoint preserve the Twin revision, numeric document ID, Editor generation, manifest, lint/audit output, screenshot and simulation verdict.

### Stage A — baseline and configuration

1. Confirm the actual Twin working tree and source revision. Inspect its manifest, component catalog, `vehicles/flip.usda`, Griffin/FLIP assembly scene, and runtime component library. The user may have local Twin edits; preserve them while finding a clean way to edit.
2. Query the composed `/FLIP` subtree with topology and collision bounds. Record all source paths, unresolved references, body owners, joint targets/frames, collider roles, visual purposes, ports and diagnostics before editing.
3. Create the parameter manifest from `parameters_v5.json` plus the public source table. Reclassify every legacy value; do not import old geometry or component numbers just because they already occur in USD. Mark any chosen dynamic study override explicitly and include it in each run record.
4. Establish the rover datum: X right/lateral, Y up, Z forward. Check a point at each wheel station and the +Z forward vector through FreeCAD → exported mesh → USD. Check m/mm scaling numerically, not by camera appearance.

### Stage B — visual assembly and physicality audit

5. Rebuild `FLIP_rover_v5.usdc` from the exact saved FCStd with `export_v5_usd.py` when the source changes. The old 2026-09-01 handover path `tools/freecad/export_twin_assets_v2.py` is absent; the v5 script is a standalone snapshot exporter, not a Twin composition pipeline. It records source SHA-256, uses the already-global X-lateral/Y-up/+Z-forward frame, converts mm to metres once, and is checked against the wheel datums and overall bounds. Compose only the `/FLIP` visual representation through the Twin's typed workflow. Keep the editable FCStd and current Twin visual as named variants/references until the new stage is inspected in the target runtime.
6. Put the chassis, four wheel components, one named panel visual, two battery envelopes, electronics, mast cameras, and each publicly named payload into distinct, replaceable identities. Preserve four wheel locations but clearly record that wheelbase/track are study choices.
7. Produce the physicality manifest before enabling physics: every visual-only part has no collider or independent body; every collider has one owner; every dynamic body has mass, centre of mass and inertia; every joint has exactly two intended bodies and authored local frames. No body property may be inferred from USD tessellation or visual volume. Keep detailed wheel cabling as render geometry and use the generic tire/contact representation for physics.
8. Use a composed-USD audit for reference closure, standard schemas, body/joint coverage, collision bounds, mass ownership, mount reciprocity and the physical/visual split. Resolve all errors before running a rover.

### Stage C — smallest mobility proof

9. Start from the shared **generic `skid_rover` raycast** contract. Remove the old Ackermann schema and any front/rear steering values; FLIP uses left/right wheel-side drive. Create only four named stations `FL`, `FR`, `RL`, `RR`. Connect the two left stations to the left command and the two right stations to the right command using explicit USD connections. Every port and expected unit must be verified from the live component schema; never infer a port name from this document.
10. Set public wheel radius to `0.465 m` as nominal geometry, while distinguishing its unloaded-family value from the effective study contact radius. Width, wheel mass, wheel inertia, spring/damping, tire stiffness, friction, rolling resistance, motor torque/speed, gear ratio and braking remain unknown. The runtime preflight must require named study overrides for every value the generic component requires. Put overrides in the run configuration, never silently in a shared Rust default.
11. Retest all four wheel command and shaft-speed bindings in the current runtime. A 2026-09-01 capture reported missing `drive` / `shaft_speed` endpoint ports and delayed visual import; that is historical evidence, not proof those failures still occur. Stop the acceptance run if any of four commands or speed sensors does not resolve; fix the USD connection/schema using typed authoring before any movement verdict.
12. Prove contact and command signs on flat terrain: settle without initial overlap, forward, reverse, stop, counter-rotating pivot, and a left/right arc. With +Z forward, +X right and +Y up, if left and right mean longitudinal wheel-edge speeds, the ideal kinematic reference is `v = (vL+vR)/2` and `yawRate = (vR-vL)/track`. Use it as a sign/parity oracle only; the study track is 2.000 m and wheel/soil slip is not represented by this ideal expression. Assert each station receives the correct signed command and produces the expected wheel-speed polarity; record displacement, heading, contact count, penetration and peak speed. Do not call this lunar terramechanics validation.

## 4. Modelica, Rust, and Rhai responsibilities

**Modelica owns continuous physical domains:** wheel/motor torque and speed relationships when using the physical drivetrain; battery current, charge state and voltage; solar electrical generation; continuous thermal storage and heat flow; and any parameterized continuous wheel compliance study. Split electrical and thermal networks according to the current library's supported connector boundaries. Put parameters in a qualified, Twin-owned Modelica source root and compile that root through the project loader. A package member declaring `within P;` must not also be loaded as a second independent source root. Confirm the qualified model class and each generated input/output mapping before simulating.

Do not ship pretend component constants. Before an electrical result can pass, the configuration must provide battery topology, pack nominal voltage, usable capacity/energy, current and temperature limits, solar active area, conversion efficiency, orientation/incidence, shading policy and motor electrical load. Public evidence supports **two packs** and solar charging only; it does not support a numeric voltage, Ah/Wh, panel area or output. A simplified study may use a declared scenario irradiance and chosen study values, but its result must remain tagged `STUDY` and must not be presented as FLIP range, lunar-night survival, or mission energy closure.

For thermal simulation, connect motor/battery loss outputs to thermal mass/conductor/radiator components with explicit units. The Moon's broad environmental temperature span is not a component allowable band. A pass requires sourced component temperature limits and mission duration; otherwise report a sensitivity study only. LRA is a passive retroreflector and has no electrical load.

**Rust remains generic:** the existing projection, rigid-body/vehicle, port-binding, component-schema and command runtime. First use current generic raycast/skid-rover components and the typed assembly tools. Add reusable Rust capability only after a focused minimal fixture demonstrates a missing generic operation/API and that gap is approved. Do not add `Flip*` or `Griffin*` runtime branches, duplicate Modelica equations, hard-code these study dimensions in a kernel, or mutate ECS state to make a single Twin pass.

**Rhai owns discrete Twin policy and acceptance:** mission phase gating, remote/autonomy command selection, safety interlocks, touchdown/release sequence, scenario timing, and orchestration of reusable physics evidence helpers. It may configure an explicitly named study variant and inspect measured outputs; it must not integrate battery SOC, motor dynamics or temperatures. Keep release timing from continuous contact/pose predicates and the approved mission event, not from a fixed sleep that assumes touchdown.

## 5. Griffin mount and rover egress

Keep the rover fixed to its payload adapter during descent and touchdown. Require a tested touchdown predicate before the Twin-local Rhai scenario requests the typed detach operation. After release verify the adapter joint is gone, the rover owns an independent body, contact/pose remain valid, and FLIP can move from the top deck by the currently public **direct egress** baseline. A ramp can be a separately named alternate study, but does not gate baseline release. Lander adapter envelope, restraint/release mechanism, loads and exact deck clearances are TBD. A render or successful detach command alone is not a pass.

## 6. Payload, sensing, solar, and thermal interfaces

Give the two opposite-pointing mast cameras separate identities and explicit camera frames; exact boresight, field of view and camera housing are TBD. Provide independent, replaceable payload slots/identity and do not invent dimensions: METAL, LRA, LDES and Lunar LiDAR are the four NASA payload identities publicly announced in 2026. METAL is reported downward-facing on the payload rail; LRA is passive; LDES monitors dust effects; LiDAR supports mapping, obstacle detection and hazard avoidance. LPSC 2026 reports thirteen payloads total; the unannounced nine entries and all detailed ICD data stay unknown.

Treat the CAD array as reference geometry. If runtime deployment becomes an approved study, author a separate USD moving body and typed joint, use an explicit source or `STUDY` mechanism, and sweep clearance across the full interval with reported sample count. A sampled sweep is not continuous proof. Add deployment actuator, latch, harness, mass and collision only with named parameters and owners.

## 7. Required evidence and acceptance matrix

Every evidence package identifies Twin Git revision, selected scene/configuration, numeric document ID/generation, parameter manifest with units and provenance, composed paths, test duration, outputs, verdict and capture paths. Never mark an unrun verification as PASS.

| Gate | Evidence required | Pass condition |
|---|---|---|
| Asset/units | composed visual paths, `usd_export_report.json`, coordinate/length round trip | USD resolves once, direction and metre scale match FreeCAD, no duplicated geometry |
| Physicality | topology + collision + mass manifest | all bodies/colliders/joints owned; visual details have no physical role; no missing dynamic mass or unapproved overlap |
| Runtime ports | authored connection/schema report for FL/FR/RL/RR | 4/4 left/right drive inputs and 4/4 speed outputs resolve; signs checked |
| Rover contact | settle and flat-terrain maneuver measurements | no initial penetration; all required contacts persist; forward/reverse/pivot/arc/stop meet explicitly chosen study bounds |
| Lander release | before/after topology plus touchdown/contact/pose trace | adapter fixed before predicate; detach only after predicate; joint absent and independent drive-away confirmed |
| Solar/electrical | Modelica compile + inputs/outputs + energy balance | only a configured study or sourced parameter set; power/SOC signs and bounds correct; no flight claim from assumed values |
| Thermal | Modelica compile + energy/temperature trace | conservative energy balance; sourced allowable band for a survival pass; otherwise sensitivity result only |
| Payload/sensing | composed identity/frame/output report | public identities exist, passive LRA has no load, unknown payload interfaces remain open |
| Visual inspection | fresh Editor viewport capture, deployed/stowed views and bounds | no geometry/collider mismatch, visible unresolved exceptions logged; inspected generation is the saved one |

Minimum Rhai negative fixtures: a missing wheel drive port fails; a missing speed output fails; a unitless override fails; `TBD` physical mass fails preflight; unowned collider/body fails topology; wrong handedness or `mm`/`m` scale fails datum checks; release before touchdown fails; and the LRA cannot create a power load. Keep all sweep/sample reports labelled as sampled. These contracts are listed in [FVR001–FVR013](../../requirements/flip-recreation.sysml); a written requirement is not executable verification until its named fixture and observer exist and pass.

## 8. Suggested implementation order

1. Reconcile existing Twin and source manifest; lock units, axes and evidence revision.
2. Export/compose v5 visual; audit scale and replaceable identities.
3. Clean component topology and physics ownership; resolve lint and composed audits.
4. Prove the generic raycast skid rover and the eight wheel ports on level terrain.
5. Validate lander touchdown, fixed adapter, typed detach, direct egress and short drive-away.
6. Add separately bounded Modelica battery/solar/motor study; expose values at stable Twin ports.
7. Add thermal analysis with declared assumptions; add payload and camera data interfaces.
8. Only then consider physical drivetrain, calibrated compliant tire, payload detail or array joint.

At each step, modify one coherent change through typed Editor tools, inspect composed results, run the smallest affected tests, capture evidence, then save. Do not substitute a large Rust change for authored-data repair.

## 9. Sources

The evidence URLs and the exact claims they support are indexed in [REFERENCES.md](REFERENCES.md). The most material sources are Astrolab's current [FLIP page](https://www.astrolab.space/flip-rover/), [2025 Griffin/FLIP announcement](https://www.astrolab.space/2025/02/05/astrolabs-flip-rover-joins-astrobotics-griffin-1-to-the-moon/), [May 2026 NASA-payload announcement](https://www.astrolab.space/2026/05/18/astrolab-announces-nasa-payloads-for-upcoming-mission-to-the-moon/), Venturi's current [FLIP listing](https://venturi.space/rovers/) and [wheel technical page](https://venturi.space/en/wheel/), plus the [LPSC 2026 FLIP update #1874](https://www.hou.usra.edu/meetings/lpsc2026/pdf/1874.pdf). Marketing imagery supports appearance only; it does not establish the missing general arrangement or as-built ICD.
