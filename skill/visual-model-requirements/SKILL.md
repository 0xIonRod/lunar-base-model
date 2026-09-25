---
name: visual-model-requirements
description: Turn reference images and an existing CAD or 3D model into component-level visual build requirements with traceable dimensions, poses and acceptance evidence. Use when planning a reference-based visual model or revising its visual specification.
---

# Visual model requirements

Produce requirements an author can use to build and inspect visible geometry.
Keep mission performance and hardware qualification in their own contracts;
their unresolved values need not block a labelled visual study.

## Establish the visual target

- Identify the actual saved model, generator and export separately. Search
  ignored/generated files and relevant parent folders if necessary. Record
  source path, hash, application version and saved pose.
- Inspect pixels, not only image captions. Prefer manufacturer references.
  Record image URL/local file, publication date if known, viewing direction,
  reference type (hardware, prototype, render) and visible features.
- Select one reference revision as the primary silhouette/layout target.
  Document this choice. Use other generations only for expressly identified
  details; never silently combine their panel layouts, equipment or finishes.
- Distinguish visible facts, published dimensions, study choices and hidden
  details. Perspective imagery does not establish absolute dimensions,
  material, steering law, internal equipment or mechanical performance.

## Write a usable contract

Use the repository's existing requirements format and stable IDs. Each visual
requirement should name its owning component, visible outcome, parameter source,
reference, pose and acceptance evidence. Prefer one independently checkable
outcome per requirement.

Cover the features that matter to recognition and build integrity:
silhouette/proportions, component topology, visible wheel construction, support
connections, panel/cell layout, equipment placement, poses, clearances and finish.
Require front, side, top and three-quarter views for the complete model;
focused component views should show otherwise hidden gaps or interference.

Keep dimensions in one owning parameter source. Define whether each dimension
means nominal primitive size, component bounds or whole-model envelope.
State axes, signed forward, origin and units. Image-derived proportions require
documented image selection and measurement assumptions; do not invent precision.

Write deterministic geometric acceptance where available: named object count,
joint/body ownership, bounds versus selected study parameters, disconnected
solids, minimum distance and interference. Exempt intentional contacts by named
pair and reason. Separate visual review judgement from numerical CAD checks.

A visual study may choose dimensions or hinge angles explicitly as assumptions.
Record a coherent selected set before authoring; do not treat mismatched legacy
tables as interchangeable. A missing flight ICD blocks a flight claim, not the
ability to build declared presentation geometry.

## Handoff

Leave a component build order, requirement-to-evidence matrix and unresolved
visual decisions. Mark requirements Planned until actual inspection supports a
result. A new requirement file or matching object label is not implementation.
Do not silently update model geometry while only reviewing/specifying it.

For this repository, start with the owning Twin's visual-build SysML and
visual-build guide when present. Vehicle-specific values belong there, not in
this skill. Canonical skills are under skill/; installed entries are consumers.
