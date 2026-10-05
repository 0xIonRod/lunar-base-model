# Solar-panel opening and closing test

Date: 2026-09-30–2026-10-01 (local). Current verdict: CAD kinematics PASS within sampled scope; native LunCoSim physical cycle PASS after verified settling. Actuator hardware sizing and strength are NOT EVALUATED. The earlier failed structural preflight below is historical and has been superseded by the independent panel body and ninth joint.

## Current physical implementation and acceptance

See `PANEL_MECHANISM.md` for frames, native joint/drive ownership, assumptions and remaining engine limitations. There is one operative hinge, one independent 15 kg panel body, 96 preserved moving CAD graphics and an invisible contact envelope. Chassis mass is 343 kg; total remains 450 kg. Evaluated CAD functional forms feed `author_panel.py` through `read_panel_parameters.py`; the controller explicitly declares degrees at the request and radians at the hinge connection.

The completed physical cycle ran 4,440 fixed ticks / 74 s: close/hold, open/hold, repeat, then clamp requests -10 and 100 degrees. Native measured endpoints were 0 and 89.999 degrees; endpoint error <0.001 degrees; hold rate 0.0103 rad/s; maximum hinge-anchor error 0.856 mm; body-axis disagreement 0.0231 degrees; no panel contacts on the clear path. Commanded-motion peak rate 0.195 rad/s and chassis tilt 1.40 degrees. Total mass measured 450 kg. Evidence: `test-panel-cycle.log` (reruns replace the log with the latest CAD-derived revision).

Scope matters: the original all-run 0.35 rad/s / 10-degree gate failed during suspension settling. Starting on wheel contact reduced the drop shock, but settling still peaked at 0.574 rad/s / 10.72 degrees. The explicit qualification now requires whole-run tilt <20 degrees (unchanged rover safety bound), then speed <0.2 m/s, tilt <3 degrees and hinge rate <0.03 rad/s before commanding. The tighter 0.35 rad/s / 10-degree bounds apply to commanded motion, not startup. This is not an all-time rate guarantee.

Missing drive and missing joint fixtures fail at structural admission as required. A solid obstacle in the closing path produces native panel contact and stops closure about 15 degrees short, causing the physical gate to fail. Wheel repeat and 80 mm obstacle regressions pass with the panel present; mass and visible-stock-graphics mutants fail as required. Logs: `test-panel_missing_drive.log`, `test-panel_missing_joint.log`, `test-panel_blocked.log`, `test-repeat.log`, `test-obstacle.log`, `test-negative_mass.log`, `test-negative_visual.log`.

The fresh graphical scene's topology audit passes: 339 CAD mesh chunks, 96 panel-owned chunks, six hidden contact shapes and nine joints. Actual 0-degree and 90-degree live poses were inspected in `FLIP_panel_closed.png` / `FLIP_panel_open.png`. Native readiness was true with no hold, fault or pending participant. Screenshots are appearance evidence, not the dynamics verdict.

## Actual saved CAD tested

`FLIP_rover_v5_simulation.FCStd`, FreeCAD 1.1.1. SHA-256 before and after:
`b17f77f404ea63f3df2182b574efd6c84ab0904a37632ef37fa9976ee627f969`.
This read-only retest follows the addition of panel mass/inertia/actuator study parameters. The test did not save or modify the file. Its saved pose remains 82 degrees.

`test_solar_panel_cad.py` returned exit 0. The 23 samples cover opening at 0,10,...,90 degrees plus the 82-degree presentation pose; closing at 90,80,...,0; and out-of-range commands -10 and 100 degrees.

- Measured orientation agrees with commanded study angle to <1e-5 degrees.
- Closed/open/closed return-tip error: 0 mm at the checked points.
- Hinge-origin drift: 0 mm. Fixed-part placement change: 0 within numerical tolerance.
- Hinge origin in saved CAD Y-up global frame: (-690,957,0) mm. Increasing CAD angle rotates about global +Z; the rover heading conversion makes it -Z in simulation. Principal signed rotation is used (350 degrees about -Z equals 10 degrees about +Z).
- Both moving hinges remain in contact with their respective pins: sampled minimum solid distance ranges from 0 to 2.274e-13 mm, effectively zero at numerical precision. This is a geometric mating observation, not a bearing-load or coaxial-tolerance qualification.
- Native 0..90-degree expression clamps work: -10 commands 0; 100 commands 90. These are study controls, not supplier hinge limits.
- All ten named moving structural shapes remain valid. No unexpected common-solid volume >1 mm³ was found against the 29 named blockers in the 11 opening samples. The test contains an exact fitted-hinge pair allowlist; no volumetric exceptions were needed in this run.

The log lists the exact moving-part and blocker scope. Cell graphics, detailed wheel spiders, cable/spring webs and unlisted equipment are excluded. This is not a continuous swept-volume proof or an all-parts clearance qualification. Closing checks pose retracing, not a second independent collision sweep. CAD motion is a placement expression, not a dynamics solver or a force-bearing assembly joint.

Evidence: `test-solar-panel-cad.log`.

## Earlier simulator preflight (before physical mechanism implementation)

`test_solar_panel_sim.py`, live owned production session port 4175, returned exit 1 / FAIL. Readiness is true, with no physics hold, pending participants or runtime fault.

The fully composed scene has exactly eight joints: four wheel hinges and four carrier sliders. The actual CAD panel `/World/FLIP/CADVisuals/SolarBackplate` belongs to chassis body `/World/FLIP`, not an independent panel body. No revolute joint or contact shape belongs to an independently moving panel. A scoped USD read also reports no mass or inertia on the panel mesh and collision disabled. This is correct visual-only mesh ownership, but it is not a panel mechanism.

Therefore there is no physical panel DOF or hinge actuator to command. Dynamic opening/closing, torque/reaction loads, speed, stop/latch behavior, self-contact, power-off holding and strength were not run and must not be reported as passing. Existing wheel dynamics tests do not cover these functions. The scene/CAD originals were left unchanged.

Evidence: `test-solar-panel-sim.log`. This test is intentionally a read-only structural preflight, not a completed dynamics acceptance gate.

## Historical implementation request from the earlier preflight

Keep CAD meshes as visuals. Re-parent the panel, frames, cells, moving hinges and attached sensors beneath one explicit panel rigid body, leaving support/pin graphics on the chassis. Add one operative standard revolute joint with both CAD-derived local frames; do not add redundant joints for the two visible bearings. Provide a hidden panel collision envelope and only explicitly justified collision filters. Split panel mass and inertia out of the existing chassis mass budget instead of adding mass twice.

Panel mass/distribution, motor torque-speed/gear ratio, damping/friction, limit/stop behavior and latch/hold behavior need sourced values or explicitly approved study assumptions. Use the existing solver/Modelica joint-control path, not mesh/Euler animation. Then test repeated open/hold/close cycles, intermediate clearance/contact, anchor error, limits, rate, torque saturation, reaction loads, loss of actuation and deliberate broken-joint/drive cases. This implementation was not performed by the read-only test request.
