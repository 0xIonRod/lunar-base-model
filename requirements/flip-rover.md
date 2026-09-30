# FLIP Rover requirements

**Last updated:** 2026-09-30
**Scope:** FreeCAD packaging model plus corresponding LunCoSim vehicle asset.
**Boundary:** This is a creation contract for a study proxy, not released
as-built or flight-qualified FLIP CAD.

## Requirements

**Current source of truth:** [the public-source SysML baseline](flip-recreation.sysml),
[FLIP source review](../research/flip_rover.md), and the
[LunCoSim recreation and verification guide](../freecad/flip_rover_v5/LUNCO_SIM_RECREATION.md).
The older Twin-local SysML packages that informed the earlier visual build are
not present in this checkout's working tree. Their v4 values are therefore not
silently treated as current flight truth or runtime verification.

| ID | Requirement | Status | Creation / acceptance note |
|---|---|---|---|
| FR-001 | Model a low, broad rover body with a replaceable payload deck and visible avionics/battery enclosure. | MUST | Keep body, deck, enclosure, mast, and payload interface separately identifiable in FreeCAD and USD. |
| FR-002 | Use four large wheels with airless/hyper-deformable-tire visual intent and four-wheel skid-steer study behavior. | PUBLIC CONFIGURATION / STUDY DYNAMICS | LPSC 2026 #1874 identifies a four-wheel skid-steer FLIP; drive sizing, wheel loads and tire law remain TBD. |
| FR-003 | Model a collapsible solar array as an independent visual subassembly with frame, graphic cells, attached cameras and named presentation poses. | V5 VISUAL STUDY | Public sources support a collapsible array and two opposing mast cameras; v5's single-panel geometry and 0/82 deg pose are not a released mechanism drawing. |
| FR-004 | Keep any CAD solar pose controller separate from the runtime physical deployment joint. | CAD STUDY IMPLEMENTED / RUNTIME PLANNED | v5 provides a bounded 0–90 deg presentation controller; flight axis, limits, actuator, latch and harness remain TBD. |
| FR-005 | Model two separately named FLIP battery-pack envelopes and keep their motion ownership unresolved until the packaging ICD is available. | PUBLIC COUNT / STUDY ENVELOPES | Venturi's 2025 media kit says two packs behind the solar panels; that phrase does not establish that packs articulate with the array. |
| FR-006 | Keep FLIP fixed to Griffin through descent/touchdown; release only after a touchdown predicate, then allow direct top-deck egress. | MUST / RUNTIME PLANNED | Astrolab's public 2026 baseline describes direct egress; a ramp is an optional separate study branch and shall not gate baseline release. |
| FR-007 | Make major subassemblies easy to replace: chassis, each wheel station, solar panel/joint, payload deck, mast/sensors, battery, and power electronics. | MUST | Use named groups/parts and stable IDs in CAD and USD. |
| FR-008 | Keep all sourced facts, study values, and unknowns traceable in this record. | MUST | Update this file whenever a source or tested implementation changes a creation-relevant value. |

## Current source-backed values and study parameters

| Parameter | Value | Status / provenance |
|---|---:|---|
| Wheel count / steering | 4 / four-wheel skid steer | FLIP-specific statement in LPSC 2026 #1874. |
| Wheel nominal diameter | 930 mm | Venturi wheel-family value; Astrolab says FLIP uses the full-size FLEX-family wheels. |
| Wheel construction counts | 192 sprung cables / 96 springs per wheel | Published wheel-family counts. CAD paths, wire sizes and spring geometry remain visual study choices. |
| Wheel axial width | 280 mm | v5 packaging-study choice; no flight value found. |
| Wheelbase / track | 1,700 / 2,000 mm | v5 packaging-study choices; no FLIP dimensioned layout found. |
| Wheel centers in saved global CAD frame | FL (-1000,465,850), FR (1000,465,850), RL (-1000,465,-850), RR (1000,465,-850) mm | Measured from the saved v5 file; study datums; X lateral, Y up, +Z forward. |
| Chassis assembly bounds | 1,460 × 400 × 2,100 mm (X × Y × Z) | Measured v5 body bounds; visual packaging study, excludes wheels/array. |
| Battery envelope bounds | 305 × 220 × 884 mm each (X × Y × Z) | Two separate named v5 envelopes; study geometry only; no pack mass assigned. |
| Overall visual bounds, stowed | 2,332 × 1,107 × 2,630 mm (X × Y × Z) | Measured v5 saved geometry; study pose, not an FLIP envelope claim. |
| Overall visual bounds, deployed | 2,332 × 2,634.311 × 2,630 mm (X × Y × Z) | Measured v5 at 82° CAD pose; study pose, not an FLIP envelope claim. |
| Array backplate | 1,800 × 1,380 mm | v5 CAD backplate study choice; not a released array dimension. |
| Rim face inset | 65 mm each side | Photo-informed CAD study value. The model keeps hub, inner rim and outer band concentric; no eccentric axle or loaded deflection is inferred. |
| Vehicle mass / launch constraint | 450 kg / 480 kg | Venturi lists 450 kg FLIP mass; LPSC #1874 describes a separate Griffin launch/space constraint of 480 kg. Payload inclusion, CG and inertia need an ICD. |
| Max payload | 30 kg | Astrolab 2025 FLIP announcement / current Venturi listing; per-payload allocation TBD. |
| Speed | 20 km/h listing; 15 km/h in general wheel material | Conflicting supplier statements; neither value is selected as the LunCoSim speed cap. |
| Battery packs | 2 packs, behind solar panels | Venturi 2025 media kit. Pack size, mass, voltage, Wh, BMS and mounting frames remain TBD. |
| Chassis envelope | TBD | No dimensioned public FLIP drawing/ICD found. Current v5 bounds are only CAD study dimensions. |
| Solar array | Collapsible; one panel in v5 | Array area, panel segmentation, cell count/power, hinge design and deployment limits are TBD. |
| Panel study pose | 0 deg stowed; 82 deg deployed; 0–90 deg clamp | Presentation control only; not the real flight mechanism. |
| Cameras | Two opposing solar-mast cameras | Canadensys supplier report; exact shape, boresight and camera ICD TBD. |
| Mission payloads | METAL, LRA, LDES, Lunar LiDAR (four NASA identities) | Astrolab 2026 announcement. LPSC reports 13 total payloads; remaining manifest and all envelope/interface details TBD. |
| Motor, gearbox, electrical and thermal ratings | TBD | No FLIP-specific public ratings found. Do not use the old 0.9 N·m / 200:1 / 400 N·m values as flight data. |

The typed parameter ledger and explicit verification conditions are in
[`flip-recreation.sysml`](flip-recreation.sysml). The following historic table
is retained for audit context only; none of its values override the current
v5 table above.

### Archived pre-v5 proxy values (superseded)

| Parameter | Active value | Status / provenance |
|---|---:|---|
| Rover mass | 450 kg | Formerly treated as an inferred midpoint; now a dated Venturi configuration claim, with mass inclusion still TBD. |
| Envelope | 2.4 m × 1.8 m × 0.7 m | Old LunCoSim packaging assumption; not a public FLIP envelope. |
| Wheel count / steering | 4 / all-wheel-steer | Superseded: current LPSC 2026 source says four-wheel skid steer. |
| Wheel radius / width | 0.45 m / 0.28 m | Superseded: public wheel diameter is 0.930 m; width remains study-only. |
| Payload capacity | 30 kg | Public Astrolab description; retain source link in the research record. |
| Battery | 28 V, 83.33 Ah, 85% initial SOC | Old simulator proxy; superseded by TBD FLIP electrical parameters. |
| Solar array | 3.0 m², 30% efficiency | Old FLEX-family / simulator proxy; superseded by TBD FLIP array area and conversion data. |
| Motor / reduction | 0.9 N·m motor, 200:1, 400 N·m output limit | Old simulator proxy; superseded by TBD FLIP actuator data. |

## Visual cues from the supplied reference

The user-provided image is a visual reference, not an engineering source. It
supports these presentation requirements: four very large wheels; a white,
low-profile body; open/spoked wheel centers; a large white-framed dark solar
panel with a dense cell pattern; panel-side hinge/edge hardware; small sensors
above the panel; and a box-like payload/equipment volume between the wheels.
The image does not establish dimensions, wheel count for the flight vehicle,
joint limits, battery placement, or mechanical ICD values.

## Solar-panel representation contract

The FreeCAD presentation controller and runtime mechanism are separate owners.
The CAD tree exposes the study topology:

```text
FLIP body (rigid body)
└── SolarArrayPanelBody (separate rigid body)
    └── SolarArrayJoint (presentation proxy; X/lateral; 0–90 deg study limit)
```

Acceptance checks:

1. The panel has a distinct body identity and can be selected separately from
   the chassis.
2. The joint has an explicit hinge axis and bounded stowed/deployed angles.
3. v5 saves in the 82 deg upright presentation pose to match the selected
   Astrolab render. The 0 deg stowed pose remains available for the mission
   launch/stow study; neither CAD angle is asserted as a flight value.
4. The panel, frame, graphic cells and panel-mounted cameras move together. The
   authored study sweep includes 0, 10, 20, 30, 45, 60, 75, 82 and 90 deg.
5. USD/physics deployment requires a separately authored runtime joint and a
   sourced or explicitly tagged study mechanism. Do not import the CAD Python
   pose control as proof of a LunCoSim physics joint.

## Current FreeCAD implementation (v5 visual study)

- [`freecad/flip_rover_v5/FLIP_rover_v5.FCStd`](../freecad/flip_rover_v5/FLIP_rover_v5.FCStd)
  is the checked-in latest CAD deliverable. It opens with the panel deployed.
- `SolarArrayPanelBody` owns the backplate, frame, visible cells, sensor bar,
  two opposed cameras and the presentation-only 0–90 deg controller.
- The four wheels use a 930 mm public wheel-family diameter, 192 cable solids
  and 96 spring solids each; v5 spring geometry is explicitly visual-only.
  Chassis geometry, cable/spring dimensions, tire width, steering physics,
  mass, material density and inertia are not inferred from B-rep volume.
- Rebuild with `build_v5.py` from `FLIP_rover_v4_input.FCStd`, then use
  `present_v5.FCMacro`. `audit_v5.py` reads but never edits the saved deliverable.

## Historical simulator integration findings (2026-09-01 capture)

The FreeCAD file is not imported directly by LunCoSim. A historical 2026-09-01
capture describes a project asset path that exported `Part::Feature` geometry
to OBJ, used Blender to scale millimetres to metres and normalize up-axis,
wrote GLB, and composed it through USD. That exporter file is not present in
this checkout; locate the current supported asset pipeline and verify its
units/axis behavior before use. Do not select an FCStd by modification time or
duplicate the visual under both FreeCAD and USD. The GLB is visual-only; USD and
Modelica own collision, joints, mass, and behavior. The saved v5 CAD is already
globally X-lateral/Y-up/Z-forward, in mm, but exporter behavior still needs a
round-trip check.

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

## Remaining design inputs required for stronger fidelity

- Chassis/general-envelope, wheelbase, track, tire width, suspension travel and
  per-wheel load from the current flight drawing/ICD.
- Tire/cable/spring materials, spring/cable dimensions and curves, wheel load
  deformation, actuator torque/rpm/reduction, braking and soil interaction.
- Flight array segmentation, array area/output/cell topology, deployment axis,
  joint limits, actuator/latch, harness and deployment envelope.
- Battery pack dimensions, mass, cell-series/parallel arrangement, voltage,
  usable energy, BMS protections, survival heaters and thermal paths.
- Component masses, CG/inertia tensors and whether published 450 kg includes
  the maximum 30 kg payload.
- Camera/payload dimensions, payload-rail datums, optical keep-outs, power/data
  buses, electrical loads and the remaining mission payload identities.
- Griffin-to-FLIP adapter, restraint/release interface and validated touchdown
  predicate.
- A dated, configuration-matched as-built render/photo/GA drawing. Perspective
  marketing images are appearance evidence only.

## Sources and implementation records

- `research/flip_rover.md` — current public-source reconciliation, 2026-09-30.
- `requirements/flip-recreation.sysml` — unit-labelled source claims, study
  choices, behavioral contracts and planned verification.
- `freecad/flip_rover_v5/LUNCO_SIM_RECREATION.md` — Rust/Modelica/USD/Rhai
  recreation sequence, interface boundaries and runtime acceptance matrix.
- `twins/astrobotic-griffin-1/vehicles/flip.usda` — active four-wheel FLIP
  proxy, EPS, thermal, and sensor composition.
- `freecad/FLIP_Rover.py` — current reference-inspired FreeCAD packaging macro
  with closed/deployed solar-panel articulation.
- The 2026-09-01 runtime note mentions `tools/freecad/export_twin_assets_v2.py`; that historical exporter file is absent from this checkout and its current replacement must be located/verified before asset import.
- `luncosim-griffin-1/logs/griffin-1-open-cadfix.err.log` — current runtime
  warnings and recovery evidence.
- Astrolab FLIP: https://www.astrolab.space/flip-rover/
- FLIP design video: https://www.youtube.com/watch?v=UFEMOrg27KE
