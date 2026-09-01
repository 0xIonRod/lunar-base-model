# Vehicle requirements

This folder is the canonical creation record for the two vehicles in the
Griffin-1 workstream. Research files hold source notes; these records turn the
useful, verified facts, explicit project assumptions, and open questions into
build requirements.

## Records

- [FLIP Rover](flip-rover.md) — rover body, mobility, power, solar articulation,
  payload interface, and visual/engineering boundaries.
- [Griffin Lander](griffin-lander.md) — lander structure, ramps, payload
  adapter, deployment sequence, and flight-data boundaries.

## Maintenance rule

Before changing CAD, USD, Modelica, Rhai, or scenario behavior, read this index
and the applicable vehicle record. When a new source, visual reference, design
decision, or tested result changes creation work, update the record in the same
change. Each entry should preserve:

- a stable requirement ID;
- fact, project requirement, study proxy, or `TBD` status;
- units and the date learned or changed;
- source/evidence and the implementation impact.

Do not turn an unknown into a precise value without evidence. When a proxy is
needed, label it as a proxy and record what will replace it.

## Articulation rule

Any moving mounted part requires a separate rigid body plus an explicit named
joint. Record the parent body, child body, joint type, axis, limits, stowed and
deployed poses, actuator/lock behavior, and an acceptance check. A hierarchy or
visual parent alone is not a physical attachment. This applies to the FLIP
solar panel and Griffin ramps, and to future articulated parts.

## Current implementation anchors

- FreeCAD study macro: `freecad/FLIP_Rover.py`
- FLIP USD asset: `twins/astrobotic-griffin-1/vehicles/flip.usda`
- Griffin USD asset: `twins/astrobotic-griffin-1/vehicles/griffin_1.usda`
- Griffin surface sequence: `twins/astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda`
- Source records: `research/flip_rover.md` and
  `twins/astrobotic-griffin-1/research/griffin_1_assumptions.md`

## Change log

- 2026-09-01 — created the shared requirements index and initial FLIP/Griffin
  creation records; added the user-provided FLIP visual as visual-only evidence.
