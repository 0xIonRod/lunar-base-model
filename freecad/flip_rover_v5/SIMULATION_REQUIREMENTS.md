# FLIP rover simulation requirements and evidence

Status: functional rigid-body study model, not calibrated hardware certification.
Prepared 2026-09-30. Original CAD and original USDC remain unchanged.

## Deliverables

- `FLIP_rover_v5_simulation.FCStd`: original CAD plus unit-correct SimulationParameters and evaluated FreeCAD expressions.
- `FLIP_simulation.usda`: parked production scene, four independently moving wheel assemblies, standard rigid bodies/colliders/joints, inherited LunCo motor/gearbox/control network.
- `FLIP_visual_Body.usda` and four `FLIP_visual_<station>.usda` files: 195 CAD components, 761,656 triangles, 43,307,009 bytes total.
- `FLIP_test_repeat.usda`, `FLIP_test_obstacle.usda`, `FLIP_test_negative_mass.usda`, `FLIP_test_negative_visual.usda`, `flip_acceptance.rhai`: automated gates. Acceptance is disabled in the normal scene and enabled in test fixtures.
- `prepare_simulation_cad.py`, `author_simulation.py`, `verify_visuals.py`: reproducible conversion/authoring/audit. Authoring uses the production typed USD document API, not direct file rewriting.

Keep the visual layers beside the main scene. They use the Twin identity `flip_rover_v5`; renaming that folder requires updating authored Twin references. LunCo library assets are required: this is not a fully standalone generic-USD physics package.

## Requirements, functional forms, and evidence

| ID | Contract | Evidence / acceptance |
|---|---|---|
| GEO-01 | Preserve CAD wheel parts, webs, springs, hubs and bolts; do not indiscriminately decimate or merge moving assemblies. | Re-tessellate CAD BRep at requested 0.5 mm linear deflection, 0.7 rad angular deflection; all 195 components retained. This is a tessellation setting, not a certified Hausdorff-error measurement. |
| GEO-02 | Exported topology matches the tessellation cache and local wheel coordinates. | `verify_visuals.py`: all triangle indices and points checked, maximum float export error 5.913e-8 m; all components accounted for. |
| GEO-03 | Stay below 256 MiB retained-layer limit. | All new visual layers together 43.31 MB; production scene successfully admitted. Original giant USDA is not referenced. |
| UNIT-01 | Physics uses metres, kg, seconds; CAD properties retain explicit units. | Stage Y-up/metres; CAD radius 465 mm, gravity 1.62 m/s²; assertions in CAD preparation. |
| MASS-01 | Account for all moving masses. | M = M_chassis + M_panel + 4(M_carrier + M_wheel) = 343 + 15 + 4(5 + 18) = 450 kg. Evaluated CAD mass budget feeds typed scene authoring. These are study assumptions, not measured hardware masses. |
| MASS-02 | Positive principal wheel inertia and traceable approximation. | Solid-cylinder equivalent: I_axle = m r²/2 = 1.946025 kg m²; I_transverse = m(3r²+w²)/12 = 1.0906125 kg m². Flexible/open wheel mass distribution is not identified. |
| MASS-03 | Chassis inertia is positive, with stated geometry. | CAD shell envelope 1.476 × 0.396 × 2.116 m, local centre (0, -0.135, 0) m. Uniform-box approximation: I = M/12 times sums of squared dimensions = (132.4629, 190.2516, 66.7533) kg m² for 343 kg. The assumed centre of mass equals the envelope centre; not an exact CAD material-density integral. |
| CONTACT-01 | Visual spring/web meshes do not become expensive contact meshes. | Wheel cylinders serve as rigid contact proxies; CAD meshes have collision disabled and render purpose. Physical ground and obstacle are standard collision geometry. |
| CONTACT-02 | Traceable lunar nominal load and friction. | N = M g/4 = 182.25 N per wheel; friction coefficient 0.65 assumed. This is not validated regolith terramechanics. |
| JOINT-01 | Each wheel can rotate and remains mechanically attached. | Four stock physical carrier slider + axle hinge pairs, local anchors matched to CAD centres, no wheel merge into chassis; dynamic gate checks wheel positions and shaft speeds. |
| COMPLIANCE-01 | Supply a bounded equivalent suspension model, without claiming wheel deformation. | Carrier slider travel ±60 mm, k = 12,000 N/m, c = 1,800 N s/m. Equivalent response F = -kx - cv; N/k = 15.19 mm nominal deflection. Study assumptions. CAD web/spring geometry is rigid in the runtime. |
| CONTROL-01 | Real torque/control network, not teleportation. | Inherited physical skid-rover motor/gearbox/shaft Modelica network and standard throttle/steer/brake port writes. Motor, gearing, brake and battery data are stock study values, not identified FLIP hardware. |
| DYN-01 | Settling, drive, rotation, turning and bounded pose must all be observed. | 1,140 ticks / 19 s at 60 Hz: settle 3 s, straight drive 12 s, turn 4 s; settle speed <0.2 m/s; travel >0.5 m; shaft speed >0.1 rad/s; heading change >2°; max tilt <20°; four wheel masses 18 kg and wheel-body separation <2 m. |
| DYN-02 | Cross a real contact obstacle. | 80 mm high, 0.30 m long cross-track cube at z=-3 m; same dynamics gate plus final chassis z < -4.7 m to clear the trailing wheels. Production verdict PASS. This does not establish maximum obstacle capability. |
| TEST-01 | Test must reject incorrect mass or visible stock graphics, and absence of verdict must not count as pass. | Negative fixtures override chassis mass to 300 kg or unhide Motor_FL/Body. Visual check initializes false and only succeeds after all small scoped queries complete. Runner returns failure for no-verdict. |
| VIS-01 | Load the actual CAD layers, not just stock proxy shapes. | Fresh graphical session reports CAD Baseplate entity and hundreds of mesh entities. Close-up screenshot `FLIP_live_check.png` confirms exposed spokes, webs, springs and bolts; contact-cylinder opacity is zero, with collision retained. Chassis proxy is invisible. |
| VIS-02 | CAD is the only visible rover; physical model stays behind it. | `verify_live_physics.py`: 339 CAD mesh chunks, 96 independently panel-owned, no CAD contact meshes; six hidden contact shapes (chassis + four wheels + panel envelope). Stock motor housings, suspension graphics, battery box and radio graphics stay hidden. |
| PANEL-01 | Physical panel DOF, not visual-only animation. | One standard revolute joint joins chassis and 15 kg panel body; CAD-aligned frames, -90..0-degree native limits, finite 60 Nm study servo cap, 10 deg/s Modelica command slew and explicit radians connection. Native repeated cycle, clamp and deliberate missing-drive/joint/obstacle tests are documented in `PANEL_MECHANISM.md`. |

## Current panel mechanism evidence

The physical panel is implemented. `PANEL_MECHANISM.md` and `SOLAR_PANEL_TEST_RESULTS.md` are the current panel contracts and evidence. `read_panel_parameters.py` reads evaluated FreeCAD properties without saving; `author_panel.py parameters` binds mass, inertia, torque cap and controller parameters through the typed document API. The original CAD and USDC are preserved.

The six-leg native panel cycle passes over 4,440 ticks / 74 s, with <0.001-degree endpoint error, <0.86 mm anchor error and no clear-path panel contacts. The test distinguishes reported startup settling from commanded motion; it does not claim the 0.35 rad/s / 10-degree motion bounds hold during startup. CAD-only graphics and hidden contacts pass exhaustive live topology checks. Missing drive, missing joint and real obstruction fixtures fail as required. Wheel repeat and obstacle regressions pass after the mass split; mass and visible-stock-graphics mutants fail. Latest measured results are in the corresponding `test-*.log` files.

The local OpenUSD writer fix now emits bracketed singleton schema lists. On 2026-10-05, all nine saved simulation/test layers opened successfully with Pixar Sdf; the writer's 37 round-trip tests also passed. The LunCoSim dependency still points to a machine-local OpenUSD checkout, so a portable integration commit requires publishing and pinning that fix first. Repeated live editor reloads can still produce duplicate projected identities; fresh production processes are used for final acceptance. Hot reload is an unresolved engine limitation, not a claimed fix.

## Historical CAD-only visual / separate physics correction (before panel implementation)

The earlier scene retained stock rover equipment graphics, creating the apparent rover-inside-rover. These are now suppressed without deleting the motor, gearbox, suspension joints or control network. Stock Battery/Body collision is disabled, leaving only the CAD-derived chassis envelope and four wheel cylinders as rover contact shapes. Wheel CAD children remain visible and move with their physical wheel bodies; marking those parent bodies invisible would incorrectly hide the CAD children too, so the wheel cylinders use zero display opacity instead.

The old chassis scale had incorrectly assumed stock dimensions multiplied a replacement USD scale; the actual Cube.size was 1. The revised proxy explicitly authors size=1 and the actual CAD shell dimensions, plus the shell centre. This changes contact and assumed mass distribution, so old dynamics results below are historical, not evidence for the revised model.

Revised repeat test: PASS, 1,140 ticks / 19 s; visual audit true; settled speed 0.00420 m/s, straight-phase travel 13.2024 m, peak shaft speed 2.6861 rad/s, heading change 55.7463°, maximum tilt 17.6665°; all four wheel attachment and mass predicates pass.

Revised 80 mm obstacle test: PASS, 1,140 ticks / 19 s; visual audit true; settled speed 0.00420 m/s, straight-phase travel 12.0590 m, peak shaft speed 5.3457 rad/s, heading change 55.7316°, maximum tilt 17.6659°; final trailing-wheel clearance predicate passes. Geometry audit remains PASS with all 195 CAD components and maximum coordinate export error 5.913e-8 m.

Revised negative tests: both FAIL as required at 1,140 ticks / 19 s, exit 1. The mass mutant reports 300 kg with otherwise passing motion checks (`test-negative-mass.log`). The visual mutant reports `Unexpected non-CAD visual: Motor_FL/Body` and visual audit false, with otherwise passing motion checks (`test-negative-visual.log`). These prove the respective acceptance predicates reject the deliberate faults.

Final parse validation: exit 0, OK. Fresh graphical production session on port 4175 reports ready=true, world_hold=false, faulted=false, pending_count=0; `verify_live_physics.py` passes against that session. `FLIP_CAD_only_check.png` was visually inspected: the stock red battery enclosure, motor cylinders and red suspension graphics are absent; CAD wheel spokes/webs and CAD body remain. The camera-selection telemetry banner remains a separate UI issue; no claim is made that it has been repaired. Python authoring/audit scripts pass syntax compilation.

An initial full-topology query exceeded Rhai's string limit; it was replaced by scoped graphics checks and an external exhaustive read-only topology audit. A subsequent wrong-path query was caught by the fail-closed gate. Neither diagnostic attempt is counted as acceptance evidence.

## Historical production results (before CAD-only correction)

- `luncosim --validate FLIP_simulation.usda`: exit 0, OK.
- Main assembled scene before separating automated driving: FLIP_ACCEPTANCE PASS, 780 ticks, 13 s.
- Final repeat fixture: FLIP_ACCEPTANCE PASS, 1,140 ticks, 19 s (`test-repeat.log`); settled speed 0.00847 m/s, travel 7.851 m, shaft speed 5.662 rad/s, heading change 36.78°, maximum tilt 10.71°.
- Obstacle fixture: FLIP_ACCEPTANCE PASS, 1,140 ticks, 19 s (`test-obstacle.log`); settled speed 0.00501 m/s, straight-phase travel 6.886 m, peak shaft speed 5.810 rad/s, heading change 39.52°, maximum tilt 10.73°.
- Deliberately incorrect mass: FLIP_ACCEPTANCE FAIL as required, 1,140 ticks / 19 s (`test-negative-mass.log`). Measured chassis mass 300 kg while movement, turning, wheel-mass and upright checks remained satisfied; the mass predicate rejects this fixture.
- Geometry audit: PASS, 195 components, 761,656 triangles, 43,307,009 visual bytes.
- Live graphical readiness: ready=true, world_hold=false, faulted=false, pending_count=0.

Earlier failed attempts revealed omitted ground scale in transform order and unresolved relative USD references. Both were fixed. A stock drivetrain-parity baseline also failed in this installed runtime; this is not claimed to pass. One concurrent nested-reference obstacle fixture run had joint-startup seating errors and failed; its serial repeat passed. Final fixtures are full production-document Save-As copies, not extra scene-root reference wrappers; parallel startup reliability is not certified. The original six-second straight-drive gate also sometimes turned before clearing the obstacle; the final gate gives twelve seconds and requires trailing-wheel clearance rather than weakening the predicate. Unrelated antenna tracking was disabled because its target input triplet was not wired. Antenna/power/thermal/flip mechanisms are not accepted by these wheel-motion tests.

Live parked telemetry: chassis 358 kg, each carrier 5 kg, each wheel 18 kg, total 450 kg; chassis speed 1.69e-5 m/s; wheel centres approximately 0.4644 m above the flat contact surface. These are runtime observations, not just authored numbers.

## Reproduction

Run from the LunCoSim repository using its production binary, with an unused explicit API port:

```
target/debug/luncosim.exe test --api 4166 --scene <absolute-folder>/FLIP_test_repeat.usda --max-ticks 1500
target/debug/luncosim.exe test --api 4166 --scene <absolute-folder>/FLIP_test_negative_mass.usda --max-ticks 1500
target/debug/luncosim.exe test --api 4166 --scene <absolute-folder>/FLIP_test_obstacle.usda --max-ticks 1500
target/debug/luncosim.exe test --api 4166 --scene <absolute-folder>/FLIP_test_negative_visual.usda --max-ticks 1500
```

Both negative fixtures must fail, not pass. Repeat and obstacle must pass. Do not interpret asset validation or a socket connection as a dynamics verdict. Run `verify_visuals.py` for exhaustive CAD geometry comparison and `verify_live_physics.py` with FLIP_API_PORT set to the fresh production scene's port for exhaustive composed graphics/contact checks. Keep acceptance scripts and the five CAD visual layers beside the fixtures.

## Hardware calibration still required

Solar-panel study dynamics now pass as recorded in `SOLAR_PANEL_TEST_RESULTS.md`. Supplier actuator torque-speed/gear data, electrical power, bearing/reaction-load telemetry, latch and power-off holding, deformation and strength still require implementation/calibration; they are not established by the native rigid-body servo tests.

Measured mass distribution, flexible wheel force-deflection curves and hysteresis, terrain friction/sinkage, actual motor torque-speed and gearing, steering architecture, braking, and chassis centre of mass must replace study approximations before predictive engineering use. The four wheel geometries are preserved visually; their deformable physics was not present in the original visual-only USDC and has not been fabricated here.
