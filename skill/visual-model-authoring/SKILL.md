---
name: visual-model-authoring
description: Build or refine a CAD or 3D visual model against component requirements and reference images, checking geometry and appearance after each component. Use for reference-based model construction and visual CAD review.
---

# Visual model authoring

Read the project's visual contract and selected reference set first. If absent,
establish a compact contract before changing geometry. Keep the user's chosen
modeling application and reference revision.

## Work from the real model

Inspect the saved document before crediting generator features. Identify source,
saved revision, current pose and export. Reuse named component groups and datums.
For review-only tasks, collect evidence without saving geometry changes.

Use native application APIs for exact shapes, global placements, bounds,
distances and intersections; use native rendered views for appearance.
A valid solid does not prove an interference-free or mechanically connected
assembly. Transform shapes into a common frame before measuring them.

When using FreeCAD:
- distinguish nominal Radius/Width/Height properties from shape bounds including
  tread, frames and other appendages;
- distinguish a display group or string saying Revolute from an operative joint;
- ensure visible arms reach the hub/body datums rather than merely sharing a
  compound object;
- account for Y-up models when setting cameras in FreeCAD's usual Z-up viewer;
- allow camera transitions to settle before saving orthographic views;
- save and reopen the intended deliverable to test Python controller persistence;
  do not count a controller that only works in the generating console session.

When editing a LunCoSim USD assembly, follow its existing typed Editor/document
owner procedure. Keep render geometry separate from collision/mass owners.
Do not claim an imported mesh carries CAD constraints or simulator behavior.

## Component loop

1. Select one component and identify its applicable visual requirement IDs.
2. Establish its envelope, origin and mount datums from the selected parameters.
3. Build the major silhouette and connected supports before decorative detail.
4. Inspect measured geometry, relevant object hierarchy and a focused native view.
5. Compare it side-by-side with the selected reference in a comparable view.
   Record what matches, diverges and remains unobservable.
6. Correct the observed discrepancies and recheck that component.
7. Save when authorized, reopen to verify persistence, then record evidence and
   advance to the next dependent component.

Use chassis, one wheel station, repeated stations, array/supports, equipment and
finish as a reasonable default order. Adjust for dependencies rather than
forcing unrelated projects through this sequence.

## Acceptance and evidence

Check full bounds and component counts, connection continuity, unintended
intersections, ground contact datum, and any required poses. For moving geometry
inspect intermediate positions as well as endpoints. Describe sampled sweeps as
sampled tests; they are not a proof of continuous clearance.

Keep purposeful fitted/contact intersections in an explicit pair allowlist.
Do not exclude whole component classes to hide failures. Visual-only parts can
still have unrealistic gaps or penetrations.

Deliver actual saved-model path/hash, application version, parameter/reference
revision, pose, focused images, measured findings and requirement results.
Use Pass, Partial, Fail and Not evaluated at the stated scope. Separate a
visual-fidelity verdict from kinematic, simulation or hardware qualification.

For this repository, tools/freecad/audit_flip_existing.py can inspect an existing
FLIP-style Part::Feature model. Read its scope before reuse: it does not cover all
FreeCAD object types or validate arbitrary assemblies. Use the owning Twin's
visual-build guide for FLIP-specific references and sequence.
