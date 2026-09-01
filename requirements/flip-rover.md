# FLIP Rover requirements

**Last updated:** 2026-09-01
**Scope:** FreeCAD packaging model plus corresponding LunCoSim vehicle asset.
**Boundary:** This is a creation contract for a study proxy, not released
as-built or flight-qualified FLIP CAD.

## Requirements

| ID | Requirement | Status | Creation / acceptance note |
|---|---|---|---|
| FR-001 | Model a low, broad rover body with a replaceable payload deck and visible avionics/battery enclosure. | MUST | Keep body, deck, enclosure, mast, and payload interface separately identifiable in FreeCAD and USD. |
| FR-002 | Use four large wheels with airless/hyper-deformable-tire visual intent and all-wheel-steer study behavior. | STUDY PROXY | Four-wheel count and steering map remain unconfirmed FLIP flight data; preserve the proxy label. |
| FR-003 | Model the top photovoltaic array as its own panel assembly, including frame, cell surface, hinge hardware, sensor bar, and deployed/stowed poses. | IMPLEMENTED IN FREECAD MACRO | The supplied visual shows a large framed dark-cell panel standing behind the body with top-mounted sensor hardware. Treat the image as visual evidence only. |
| FR-004 | Connect the solar panel assembly to the rover body with an explicit revolute joint. | IMPLEMENTED IN FREECAD / OPEN RUNTIME | `SolarArrayPanelBody` is a separate child body driven by `SolarArrayJoint` about the X/lateral hinge axis; limits are 0–90 deg with an 82 deg deployed pose. |
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
| Solar array | 3.0 m², 30% efficiency | FLEX-family / simulator study proxy. FreeCAD now defaults closed and supports a hinged 0–90 deg panel motion. |
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
└── SolarArrayPanelBody (separate rigid body)
    └── SolarArrayJoint (revolute; X/lateral axis; 0–90 deg)
```

Acceptance checks:

1. The panel has a distinct body identity and can be selected separately from
   the chassis.
2. The joint has an explicit hinge axis and bounded stowed/deployed angles.
3. The default saved FreeCAD pose is closed at 0 deg; the deployed pose is 82
   deg upright, with panel sensors moving with the panel.
4. The panel moves without detaching from or silently becoming part of
   chassis; in the deployed pose it clears the fixed mast and wheels, and in
   the closed pose it nests over the payload deck.
5. The same joint/release intent is represented in USD/physics when the
   FreeCAD packaging model is promoted into the Twin.

## Current FreeCAD implementation

- `freecad/FLIP_Rover.py` creates the reference-inspired rover and saves it
  closed/stowed as `freecad/FLIP_Rover.FCStd`.
- `SolarArrayPanelBody` is the child rigid-body group; its backplate, white
  frame, dark cell pattern, and moving sensor bar share the body placement.
- `SolarArrayJoint` is the named FreeCAD revolute-joint controller. Edit its
  `Angle` property or call `deploy_solar_panel()` / `stow_solar_panel()` in the
  Python console.
- The runtime USD asset still needs the equivalent articulated solar joint;
  this remains a promotion task, not a claim that the current Twin has it.

## Simulator import and integration findings

The FreeCAD file is not imported directly by LunCoSim. The exporter selects the
newest project-owned `*.FCStd`, opens it in FreeCAD, exports `Part::Feature`
geometry to OBJ, uses Blender to scale millimetres to metres and normalize the
up-axis, writes a GLB, mirrors it into the runtime Twin, and authors a USD
`twin://.../visuals/flip_freecad.glb` payload. The GLB is visual-only; USD and
Modelica still own collision, joints, mass, and behavior.

Confirmed runtime issues from the 2026-09-01 capture:

- All four FLIP wheel torque wires and all four shaft-speed wires failed port
  binding (`drive` / `shaft_speed` missing at the runtime endpoint), despite
  authored USD connections. Wheel propulsion and telemetry are therefore not
  yet a clean integration result.
- Four wheel prims remained unprocessed for more than 10 seconds. LunCoSim
  recovered by building physics without the missing visual dependency, so this
  was recovery, not a clean visual import.
- The Griffin Modelica compile completed but took about 6 seconds, and the
  runtime retained only the first 2048 telemetry channels.
- The FreeCAD solar-panel joint is not carried into the current runtime Twin:
  `SolarArray` is a fixed/deployed power proxy and explicitly has no physics
  articulation joint. A USD body + revolute joint is still required.

Historical Modelica import issue and fix:

- A `.mo` member declaring `within P;` was incorrectly seated as a second user
  document. Rumoca then rejected the package with `Duplicate class ... with
  non-identical definition`, even for byte-identical sources; geometry could
  still appear while the Modelica model did not solve.
- The loader now reads the source’s `within` and class name, loads the owning
  source root through `LoadSourceRoot`, and compiles the qualified class without
  registering the member file a second time. Modelica `record` classes are
  indexed and viewable but intentionally are not simulation roots; only
  model/block/plain class roots are offered for simulation.

## Open questions

- As-built wheel count, wheel dimensions, loads, steering map, tire stiffness,
  motor constants, battery capacity, thermal limits, and panel joint limits.
- Whether the flight solar array is one panel, two panels, or another
  collapsible geometry; the current FreeCAD representation follows the supplied
  large-panel reference while retaining the earlier two-wing packaging proxy as
  an unresolved runtime question.
- Exact FLIP-to-Griffin payload adapter geometry and release hardware.

## Sources and implementation records

- `research/flip_rover.md` — reviewed public facts and simulator boundary.
- `twins/astrobotic-griffin-1/vehicles/flip.usda` — active four-wheel FLIP
  proxy, EPS, thermal, and sensor composition.
- `freecad/FLIP_Rover.py` — current reference-inspired FreeCAD packaging macro
  with closed/deployed solar-panel articulation.
- `tools/freecad/export_twin_assets_v2.py` — FCStd → OBJ → GLB exporter.
- `luncosim-griffin-1/logs/griffin-1-open-cadfix.err.log` — current runtime
  warnings and recovery evidence.
- Astrolab FLIP: https://www.astrolab.space/flip-rover/
- FLIP design video: https://www.youtube.com/watch?v=UFEMOrg27KE`n
