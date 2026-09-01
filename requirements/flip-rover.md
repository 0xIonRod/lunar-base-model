# FLIP Rover requirements

**Last updated:** 2026-09-01
**Scope:** FreeCAD packaging model plus the corresponding LunCoSim vehicle
asset.
**Boundary:** This is a creation contract for a study proxy, not released
as-built or flight-qualified FLIP CAD.

## Requirements

| ID | Requirement | Status | Creation / acceptance note |
|---|---|---|---|
| FR-001 | Model a low, broad rover body with a replaceable payload deck and visible avionics/battery enclosure. | MUST | Keep body, deck, enclosure, mast, and payload interface separately identifiable in FreeCAD and USD. |
| FR-002 | Use four large wheels with airless/hyper-deformable-tire visual intent and all-wheel-steer study behavior. | STUDY PROXY | Four-wheel count and steering map remain unconfirmed FLIP flight data; preserve the proxy label. |
| FR-003 | Model the top photovoltaic array as its own panel assembly, including frame, cell surface, hinge hardware, and deployed/stowed poses. | MUST | The supplied visual shows a large framed dark-cell panel standing behind the body with top-mounted sensor hardware. Treat the image as visual evidence only. |
| FR-004 | Connect the solar panel assembly to the rover body with an explicit revolute joint. | MUST / OPEN IMPLEMENTATION | The panel and body must be separate rigid bodies. Record joint axis, limits, stowed angle, deployed angle, lock/actuator placeholder, and a motion test. A visual hierarchy alone is insufficient. |
| FR-005 | Keep the battery pack and power controller body-mounted unless a source shows that the battery itself articulates. | REQUIREMENT CLARIFICATION | “Moving solar battery” is interpreted as a moving solar panel/array; do not invent a moving battery from that phrase. |
| FR-006 | Preserve the Griffin payload interface: FLIP is fixed to the lander adapter during descent and released after touchdown/ramp deployment. | MUST | The physical release boundary belongs to the Griffin scene; FreeCAD should show the adapter datum and mounting points. |
| FR-007 | Make major subassemblies easy to replace: chassis, each wheel station, solar panel/joint, payload deck, mast/sensors, battery, and power electronics. | MUST | Use named groups/parts and stable IDs in CAD and USD. |
| FR-008 | Keep all sourced facts, study values, and unknowns traceable in this record. | MUST | Update this file whenever a source or tested implementation changes a creation-relevant value. |

## Active study values

| Parameter | Active value | Status / provenance |
|---|---:|---|
| Rover mass | 450 kg | Engineering midpoint around Astrolab’s public “nearly half a metric ton”; not measured. |
| Envelope | 2.4 m × 1.8 m × 0.7 m | LunCoSim packaging assumption. |
| Wheel count / steering | 4 / all-wheel-steer | Architecture proxy; FLIP-specific count is not published in the reviewed sources. |
| Wheel radius / width | 0.45 m / 0.28 m | Simulator packaging proxy. |
| Payload capacity | 30 kg | Public Astrolab description; retain source link in the research record. |
| Battery | 28 V, 83.33 Ah, 85% initial SOC | Simulator electrical proxy; replace with the FLIP battery ICD. |
| Solar array | 3.0 m², 30% efficiency | FLEX-family / simulator study proxy. The current FreeCAD representation must add the articulated panel contract above. |
| Motor / reduction | 0.9 N·m motor, 200:1, 400 N·m output limit | Simulator actuator proxy, not flight data. |

## Visual cues from the supplied reference

The user-provided image is a visual reference, not an engineering source. It
supports these presentation requirements: four very large wheels; a white,
low-profile body; open/spoked wheel centers; a large white-framed dark solar
panel with a dense cell pattern; panel-side hinge/edge hardware; small sensors
above the panel; and a box-like payload/equipment volume between the wheels.
The image does not establish dimensions, wheel count for the flight vehicle,
joint limits, battery placement, or mechanical ICD values.

## Solar-panel articulation contract

The FreeCAD and runtime representations should expose the same named topology:

```text
FLIP body (rigid body)
└── SolarArrayPanel (separate rigid body)
    └── SolarArrayJoint (revolute; axis/limits/poses recorded here)
```

Acceptance checks:

1. The panel has a distinct solid/body identity and can be selected separately
   from the chassis.
2. The joint has an explicit hinge axis and bounded stowed/deployed angles;
   `TBD` is allowed until a source or design decision supplies the values.
3. The panel can move without detaching from or silently becoming part of the
   chassis, and the deployed pose clears the mast, payload deck, and wheels.
4. The same joint/release intent is represented in USD/physics when the
   FreeCAD packaging model is promoted into the Twin.

## Open questions

- As-built wheel count, wheel dimensions, loads, steering map, tire stiffness,
  motor constants, battery capacity, thermal limits, and panel joint limits.
- Whether the flight solar array is one panel, two panels, or another
  collapsible geometry; the current two-wing FreeCAD macro is a packaging
  placeholder that must be reconciled with the large-panel visual reference.
- Exact FLIP-to-Griffin payload adapter geometry and release hardware.

## Sources and implementation records

- `research/flip_rover.md` — reviewed public facts and simulator boundary.
- `twins/astrobotic-griffin-1/vehicles/flip.usda` — active four-wheel FLIP
  proxy, EPS, thermal, and sensor composition.
- `freecad/FLIP_Rover.py` — current packaging macro; solar-joint work remains
  an explicit next implementation step under FR-004.
- Astrolab FLIP: https://www.astrolab.space/flip-rover/
- FLIP design video: https://www.youtube.com/watch?v=UFEMOrg27KE
