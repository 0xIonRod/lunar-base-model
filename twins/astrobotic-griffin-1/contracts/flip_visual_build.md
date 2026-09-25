# FLIP visual-model build contract

Current focus: build a recognizable, coherent visual CAD model. Power, thermal,
radiation, autonomy and qualification contracts remain separate later work.
Unknown flight performance is not a blocker for a clearly labelled visual study.

Normative visual outcomes: [20 visual-build requirements](../requirements/flip_visual_build_requirements.sysml).
Verification status: **Planned**; these declarations do not create a runtime test.
Do not register an executable twin.toml case until its fixture/observer exist.

## Reference selection

Primary target: the Astrolab FLIP product-page render set captured in the
[2026-09-25 review](../../../research/flip-review-2026-09-25/REVIEW.md):
[drive-out](../../../research/flip-review-2026-09-25/reference_astrolab_driveout.jpg)
and [elevated view](../../../research/flip-review-2026-09-25/reference_astrolab_detail.jpg).
These establish the upright array, low central body and large open wheels.
The June 2025 URL path is an asset-path date, not a verified flight configuration date.

Secondary wheel-construction evidence:
[Venturi IAC development prototype, 15 October 2024](../../../research/flip-review-2026-09-25/reference_venturi_iac2024.jpg).
Use its open spoke/web construction for visible detail. It is marked Not for
flight; do not transfer its exact dimensions, gold finish or array segmentation
to the primary target without documenting the decision.

The [Venturi render](../../../research/flip-review-2026-09-25/reference_venturi_flip.jpg)
is comparison evidence for design variation. It is not a second simultaneous
silhouette/finish target. For any replacement reference, update this selection
and its affected requirements before changing the model.

Source pages:
- https://www.astrolab.space/flip-rover/
- https://venturi.space/en/article/venturi-space-and-venturi-astrolab-introduce-lunar-rover/
- https://venturi.space/rovers/

## Build choices to record

The next author can make and document reasonable visual-study choices without
waiting for a flight ICD. Choose a coherent scale and proportions, signed forward
axis, wheel/body spacing, panel segmentation and stowed/deployed angles. Mark
them as study choices and inspect them against the primary references.

Do not automatically reuse either the old 1.8/2.4 m CAD chassis or the 4.40/2.76 m
SysML visual chassis. Those belong to inconsistent representations. Record the
chosen values once in the visual model's parameter source, with component/overall
bounds distinguished. Future builders and checks consume that source.

Numeric inspection tolerances and allowed mating/contact pairs must be recorded
before geometry checks. They are computational study settings, not supplier
manufacturing tolerances. Do not increase them to conceal visible defects.

## Component order and checkpoints

| Step | Work | Requirements | Evidence before advancing |
|---|---|---|---|
| 1 | Pin saved model, references, axes and selected parameters | FVB-001–003 | Input paths/hashes, source record, chosen study dimensions and frame |
| 2 | Block out chassis and component hierarchy | FVB-004–005 | Front/side/three-quarter silhouette, measured bounds, component map |
| 3 | Build one complete wheel station | FVB-007–010 | Open wheel face, band detail, connected supports, wheel/body interference result |
| 4 | Repeat validated station at the other mounts | FVB-006,009–010 | Four named stations, symmetry and clearance checks |
| 5 | Build upright array, frame and cells | FVB-011–012 | Reference comparison in deployed pose, panel face and edge views |
| 6 | Add connected hinge/support and study pose control | FVB-013–015 | Stowed/deployed views, intermediate-pose clearance checks, connected hardware |
| 7 | Place sensors and equipment envelopes | FVB-016–017 | Mounted/visible sensor views, no camera-panel or controller-box overlap |
| 8 | Match finish and review complete model | FVB-018,020 | Neutral views alongside primary references; explain remaining differences |
| 9 | Save and reopen; verify the actual deliverable | FVB-019–020 | Reopened document, working pose controls, hash and final requirement matrix |

## Required component map

Use stable names and an explicit map rather than forcing identical object types
in FreeCAD and USD. At minimum identify:
- chassis assembly and reference/root datum;
- four wheel stations, each wheel geometry and its visible mount/support;
- solar assembly, backing/frame/cells, support/hinge and pose-control owner;
- camera/antenna-like visual hardware and its mount;
- separate battery-pack envelopes and power-controller envelope.

Supplier media-kit text describes two FLIP packs behind solar panels. Treat
that as dated packaging evidence; it does not establish battery articulation.
A generic single BatteryBox is not enough to show the allocated packs.
Do not invent internal battery or electronics construction.
Mission payload details may use labelled envelopes when requested; a visual
build does not require an operational sensor model or a complete mission ICD.

## Existing model findings that the build must close

From the saved FCStd audit, not merely its generator:
- two horizontal fixed array wings; no saved solar-joint controller;
- disconnected arm/knuckle solids at every station;
- wheel/chassis, sensor/array and controller/equipment intersections;
- coarse tread blocks and solid hub faces unlike the selected visible wheel;
- nominal wheel dimensions do not include full tread bounds;
- saved model and newer generator are different revisions.

The existing [audit script](../../../tools/freecad/audit_flip_existing.py)
supports Part::Feature geometry inspection and native FreeCAD captures. Its
valid-shape result is not an assembly pass. Adapt measurement coverage for other
object types or new joints before using it as an acceptance gate.

## Evidence record

For each component record: requirement IDs, saved-model revision/hash, reference
file/revision, pose, numerical checks and tolerances, allowed contacts, focused
views, visual feedback and result (Pass/Partial/Fail/Not evaluated).
A requirement closes only at the scope actually inspected.

The older visual SysML packages remain the current USD fixture contracts.
FVB is the selected next visual-build target. Existing dimension/topology
conflicts must be reconciled when authoring the corresponding component;
this file does not silently change their runtime bindings.

## Skills

Canonical portable sources:
- [visual-model-requirements](../../../skill/visual-model-requirements/SKILL.md)
- [visual-model-authoring](../../../skill/visual-model-authoring/SKILL.md)

Use the first to revise reference-based requirements. Use the second to build
and inspect one component at a time. For LunCoSim geometry, retain the existing
typed Editor/document-owner procedure in [authoring](authoring.md).
