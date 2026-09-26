# FLIP rover requirements
Updated 2026-09-17. Current artifact: [FreeCAD v3](../freecad/flip_v3/README.md).
Scope: editable reference-informed CAD study and requirements for later Twin promotion.
Neither the CAD nor its sampled checks constitutes flight qualification.
SysML contract: [FlipCadRequirements](../twins/astrobotic-griffin-1/requirements/flip_cad_requirements.sysml).

## Sources and authority
- S1: [Astrolab LPSC 2026 project update](https://www.hou.usra.edu/meetings/lpsc2026/pdf/1874.pdf):
  four wheels, skid steer, and a 480 kg launch-mass constraint.
- S2: [Astrolab official rendering](https://www.astrolab.space/wp-content/uploads/2025/06/Picture1-1.jpg):
  deployed panel along one side. This is visual orientation evidence, not an engineering drawing.
- S3: [Astrolab FLIP](https://www.astrolab.space/flip-rover/):
  flexible wheels and battery-enclosure context.
- S4: [Astrolab Griffin-1 announcement](https://www.astrolab.space/2025/02/05/astrolabs-flip-rover-joins-astrobotics-griffin-1-to-the-moon/):
  historical public 30 kg payload capacity.
- S5: [Astrolab mission announcement](https://www.astrolab.space/2026/05/18/astrolab-announces-nasa-payloads-for-upcoming-mission-to-the-moon/):
  direct top-deck egress. Ramp use is a separate study scenario, not a required flight sequence.
- D1: v3 CAD geometry and native controls; detailed dimensions are estimated study values.
- L1: retained USD/Modelica/Editor visual-study configuration. It is not promoted to v3 by this change.

## Requirements and verification allocation
All statements are requirements for the stated scope. PASS below means only the listed
evidence supports the bounded CAD criterion; OPEN means not implemented or verified.
IDs FR-001 through FR-008 are retained with corrected intent.

| ID | Requirement | Allocated subject / basis | Verification and status |
|---|---|---|---|
| FR-001 | The CAD shall identify chassis, removable skins, battery, power controller and payload deck as separate named components. | Chassis, Exterior, Equipment / D1 | V1 inventory; PASS CAD |
| FR-002 | The CAD shall contain exactly four wheel stations with fixed lateral roll axes and independent left/right roll controls representing skid-steer kinematics. | Mobility, Motion / S1,D1 | V2 inventory and asymmetric roll poses; PASS CAD, traction dynamics OPEN |
| FR-003 | The solar assembly shall contain backing, frame, cells, moving hinge members and a sensor bar whose sensors follow the panel. | SolarArrayPanelBody / S2,D1 | V1 membership and V3 pose cycle; PASS CAD |
| FR-004 | The panel shall rotate about the longitudinal side hinge specified below, with bounded effective angle and saved closed pose. | Power, SolarArrayPanelBody, Motion / S2,D1 | V3 native expression and 0/82/0 reopen cycle; PASS CAD |
| FR-005 | Battery and power-controller placements shall remain body-fixed throughout panel actuation. | Equipment / D1 | V3 global-placement comparison; PASS CAD |
| FR-006 | A promoted Twin shall constrain FLIP to the lander before release and release only after touchdown and an authorized egress transition. | Future lander/rover interface / S5 | V6 integration test; OPEN, no CAD release mechanism or ramp interlock claim |
| FR-007 | The CAD shall preserve separately selectable chassis, wheel stations, solar assembly, payload deck and equipment groups. | FLIP assembly / D1 | V1 inventory; PASS CAD |
| FR-008 | Each specification shall identify units, applicable configuration, source or estimate, and verification status. | Requirements / S1-S5,D1,L1 | V7 independent AI review and static cross-check; review record linked below |
| FR-009 | Wheel geometry shall match the explicitly defined CAD radii, width, track and wheelbase below within 0.01 mm numerical tolerance. | Mobility / D1 | V2 direct geometry measurements; PASS CAD study, supplier values OPEN |
| FR-010 | The requirements shall distinguish the 480 kg source constraint, unknown actual mass and legacy 450 kg runtime assumption. | Mass record / S1,L1 | V7 provenance review; PASS documentation only, mass compliance OPEN |
| FR-011 | The CAD shall match the chassis and panel dimensions below within 0.01 mm numerical tolerance. | Chassis, Power / D1 | V2 measurement; PASS CAD study |
| FR-012 | Every modeled physical solid shall be valid and connected to the baseplate through its named attachment chain with gaps no larger than 0.01 mm. | Entire CAD / D1 | V4 per-solid attachment graph; PASS |
| FR-013 | At the listed panel and wheel poses, tested geometry shall have no pair intersection exceeding 1 mm^3. | Panel versus fixed parts; wheel versus other parts; all stowed pairs / D1 | V4 sampled BRep checks; PASS, continuous clearance OPEN |
| FR-014 | The delivered CAD shall reopen with visible physical components and retain native motion expressions. | Saved FCStd / D1 | V3 GUI cycle and V5 archive/geometry equality; PASS |
| FR-015 | Future USD/Modelica promotion shall preserve the side hinge, units, separate panel identity and skid-steer behavior and verify release, drive, energy and telemetry behavior. | Future runtime / S1,D1 | V6 runtime tests; OPEN |
| FR-016 | The handoff shall preserve the baseline and all non-Power geometry and placements. | v2 to v3 / D1 | V5 exact fingerprints of 84 non-Power components; PASS |

## Current CAD specification (D1)
Coordinates: right-handed, millimetres, X lateral, Y longitudinal, front = -Y,
Z up. Ground datum Z = 0. These are geometric study definitions, not manufacturer tolerances.

| Parameter | Value | Meaning / provenance |
|---|---:|---|
| Wheel count | 4 | Source fact S1; CAD LF, LR, RF, RR |
| Steering architecture | skid steer | Source S1; no steer-yaw joint in this CAD |
| Wheel main-band radius / diameter | 450 / 900 mm | D1 estimate, excluding raised ribs |
| Wheel maximum rib radius / diameter | 458 / 916 mm | D1 estimate, nominal rotational envelope |
| Wheel tire width | 280 mm | D1 axial width; caps/bolts excluded |
| Wheel center height | 458 mm | D1; rib-tip nominal ground envelope |
| Wheelbase | 1700 mm | D1 front-to-rear center distance |
| Track | 2000 mm | D1 left-to-right center distance |
| Wheel centers | X = ±1000, Y = ±850, Z = 458 mm | D1 four combinations; front negative Y |
| Wheel controls | LeftWheelRoll, RightWheelRoll (degrees) | D1; same value applied to both wheels on a side around +X; no imposed vehicle translation |
| Baseplate plan / thickness | 1460 × 2100 / 20 mm | D1 X × Y; Z 360 to 380 |
| Skinned body envelope | 1476 × 2116 × 396 mm | D1 X × Y × Z; Z 360 to 756; excludes wheels, panel, payload and lander mounts |
| Wheel-band overall lateral span | 2280 mm | D1; full vehicle max span also includes caps/bolts |
| Panel backing nominal plan / thickness | 1800 × 1380 / 20 mm | D1 along hinge × folding span; before hinge relief cuts |
| Panel frame outer plan, closed | 1840 × 1420 mm | D1 along hinge × folding span; excludes sensors |
| Panel nominal backing area | 2.484 m² | Derived gross rectangle; not active cell area or power rating |
| Hinge origin | (-690, 0, 950) mm | D1 world coordinates |
| Hinge axis | global Y, longitudinal | S2 orientation; location D1 estimate |
| Panel angle control | SolarAngle = 0…90 degrees | D1; saved 0, example deployment 82; not flight limits |
| Rotation convention | Rz(+90°) Rx(-clamp(SolarAngle,0,90)) | Native parent/local composition; positive control raises panel from deck, equivalent negative global-Y rotation |
| Free-edge center | (690,0,950) mm at 0° | D1 hinge-frame point (0,-1380,0) |
| Free-edge at 82° | approximately (-497.94,0,2316.57) mm | Derived pose, excluding frame and sensors |

The effective geometry angle is clamped to 0-90 degrees by the native expression,
even if scripted assignments retain an out-of-range value in SolarAngle.
The panel moves as one assembly; fixed bearings/pins and deck rests remain fixed.
The moving knuckles rotate about the pins. The panel closes over the deck, rises
along the rover side, and returns to the same closed pose. The sensor bar and both
camera groups move with the panel. The underlying control is a native placement
expression, not a solved dynamic revolute constraint, actuator model, latch or harness.

## Mass, payload, power and unknown performance
| Parameter | Value / status | Scope and evidence |
|---|---|---|
| Available launch-mass constraint | 480 kg | S1 mission constraint; not a measured actual rover mass and not a CAD mass calculation |
| Actual rover launch / dry / loaded mass | TBD | Payload inclusion, consumables, margins and as-built breakdown require supplier data |
| Payload capacity | 30 kg | Historical S4 public value; current ICD and allocation remain to be confirmed |
| Per-wheel mass, chassis mass, panel mass | TBD | No densities or component mass properties assigned/validated |
| Center of mass / inertia tensor | TBD | Must be established before predictive dynamics |
| Legacy runtime mass | 450 kg | L1 historical assumption, unchanged; does not demonstrate 480 kg compliance |
| Legacy battery | 28 V, 83.33 Ah, initial SOC 85% | L1 assumed values, not validated hardware specification |
| Legacy solar input | 3.0 m², efficiency 30% | L1 power proxy; not the v3 backing area or measured power |
| Legacy motor / gearbox | 0.9 N·m, 200:1, 400 N·m limit | L1 simulation assumptions, not measured torque |
| Max speed, grade, payload load cases, suspension travel, tire stiffness | TBD | Supplier/test data required |
| Battery energy, charging limits, thermal limits, panel deployment speed/torque | TBD | CAD actuation has no time/energy/thermal model |
| Adapter dimensions, release hardware, latch and hinge flight range | TBD | Requires rover/lander ICD and mechanism data |

## Verification records
All paths below are under [freecad/flip_v3](../freecad/flip_v3/).
- V1/V2/V3: requirements_check.py and requirements_check.json measure native objects,
  dimensions, topology, controls and frame behavior after reopening.
- V4: audit.py and v3_audit_latest.json: 224 components, 225 per-solid attachment checks;
  panel angles 0,5,10,20,30,40,50,60,70,82,90 degrees; wheel angles
  0,15,45,90,180,270 degrees (right = negative left), panel closed for wheel tests.
  These are separate pose sets, not every combined panel/wheel configuration.
- V3/V5: v3_presentation.json, v3_geometry_comparison.json, v3_delivery.json,
  v3_change_report.json and published_geometry_comparison.json; rendered closed/deployed views.
  The latter links final-file geometry at all 17 poses to audited_source.FCStd.
  source_v3_delivery.json preserves pre-clamp provenance; v3_delivery.json identifies the final file.
- V6: OPEN; no simulator export, dynamic integration, lander release, torque-port,
  thermal, energy, terrain or telemetry acceptance run accompanies this CAD change.
- V7: [independent AI SysML review](flip-sysml-review.md). This is a traceability review,
  not a formal SysML parser or solver certification.

## Existing Twin divergence
Existing flip_requirements.sysml and component requirements remain the **legacy runtime**
contract consumed by the Editor/Rhai pipeline. Their 4.40 m chassis width, 2.76 m
length, directional steering, Y-up coordinates, fixed solar proxy and 450 kg mass
must not be interpreted as v3 CAD facts. They are retained to avoid silently changing
simulation behavior. The additive FlipCadRequirements package is the current CAD
contract. Promotion requires an explicit frame conversion and updated runtime
acceptance results; no existing runtime test proves the corrected CAD behavior.

## Historical runtime integration findings (2026-09-01; not rerun)

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
