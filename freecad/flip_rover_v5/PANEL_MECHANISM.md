# Physical solar-panel study mechanism

Native LunCoSim acceptance: final CAD-derived parameter/unit-annotated revision passed all eight expected test verdicts. This is a study mechanism, not flight-qualified hardware or a portable OpenUSD certification.

## Ownership and frame contract

CAD is visual only. All 96 CAD members of SolarArrayPanelBody (panel, frames, cells, moving hinge leaves, attached sensors/mast/stub) are composed beneath `/World/FLIP/SolarMechanism/CADVisuals`; stationary bearing supports and pins stay on the chassis. The same CAD layer is referenced, not re-tessellated or duplicated visibly. An inverse presentation-pose transform preserves every mesh's original position at 82 degrees.

SolarMechanism is a standard dynamic PhysicsRigidBodyAPI/PhysicsMassAPI Xform. It has one hidden Cube contact proxy, dimensioned 1.38 × 0.02 × 1.8 m, centred (-0.69,0.01,0) m in the closed panel frame. This proxy covers the backplate, not every protruding visual instrument or hinge leaf.

One PhysicsRevoluteJoint `/World/FLIP/PanelHinge` joins the chassis to that body. Chassis-local anchor (0.69,0.257,0) m; panel-local anchor (0,0,0); identity joint frame bases; +Z cardinal axis; native limits -90..0 degrees. The initial body rotation is -82 degrees about Z. Deployment commands 0..90 degrees map to negative native joint angles in radians. The two physical-looking bearings represent one operative DOF, not two redundant solver hinges.

The correct signed axis for increasing deployment is +Z in the original saved Y-up CAD frame and -Z after the rover's 180-degree heading conversion. A quaternion reporting 350 degrees about -Z represents +10 degrees about +Z; use principal signed rotation, not the raw quaternion axis alone.

The connected panel/chassis pair is collision-disabled through the standard joint policy. Wheel, terrain and unrelated obstacle contacts remain eligible; no rover-wide self-contact exclusion is authored. CAD-sampled clearance provides separate evidence for the panel/chassis geometry, not a contact proof for excluded bearing surfaces.

## Explicit assumptions and functional forms

- Panel moving-assembly mass: 15 kg, uniform backplate-equivalent including attached visual equipment. Not a CAD-density integral or supplier measurement.
- Remaining chassis mass: 343 kg. Total = 343 + 15 + 4(5 + 18) = 450 kg. Wheel and carrier masses are unchanged.
- Panel centre of mass: (-0.69,0.01,0) m. Principal inertia about that centre: (4.0505,6.4305,2.381) kg m², using I_axis = m/12 × the sum of the other two squared dimensions.
- Worst static lunar gravity moment at a horizontal panel: m g L/2 = 16.767 N·m. The 60 N·m servo cap is a study assumption, not actuator sizing certification or a measured reaction torque.
- Modelica FlipPanelController clamps requests to 0..90 degrees and eases/rate-limits the setpoint to 10 degrees/s with a 0.4 s time constant. It initializes at the authored 82-degree pose.
- The native Avian joint servo receives its radians setpoint through an explicit USD connection, with finite maximum torque. The existing runtime joint-port owner uses its 3 Hz, damping-ratio 2 native servo model when wired; authored angular stiffness/damping describe the initial USD drive but are not claimed to remain its wired runtime gains.
- No mesh/Euler animation, teleportation or duplicate hidden panel body is used.

`FLIP_rover_v5_simulation.FCStd` contains evaluated, unit-bearing panel dimensions and mass plus panel inertia, gravity moment and chassis mass functional forms. `read_panel_parameters.py` reads those native evaluated properties without saving the CAD. `author_panel.py` derives body masses/inertias, torque cap and controller parameter overrides from them, and rejects a geometry/pose inconsistent with the retained visual cache. Original CAD/USDC files remain unchanged.

## Required acceptance

Physical cycle fixture: settle; close/hold; open/hold; repeat; then exercise out-of-range requests through the controller clamp. Require measured native angle and rate, rigid-body orientation agreement, attachment-anchor error <5 mm, bounded native limits, no panel contacts during the clear-path run, total mass 450 kg, and at least 4,000 fixed-step samples. Endpoint tolerance is 1 degree and hold-rate tolerance 0.02 rad/s. Before commanding motion at 2 s, require chassis speed <0.2 m/s, tilt <3 degrees and hinge rate <0.03 rad/s. Commanded-motion rate must be <0.35 rad/s and tilt <10 degrees; whole-run tilt must stay below the existing rover gate's 20-degree safety bound.

The first all-run 0.35 rad/s / 10-degree gate failed during suspension settling, despite correct endpoints. Starting the rover at wheel contact (root Y=0.7 m, instead of a 0.25 m drop) reduced that shock. Remaining startup transients are explicitly reported separately, not hidden: 0.574 rad/s / 10.72 degrees in the completed baseline; commanded motion 0.195 rad/s / 1.40 degrees. These tighter bounds are actuation-after-settle acceptance, not an all-time speed/tilt guarantee.

Negative fixtures deliberately remove the drive wire, remove the joint, or put a solid obstacle in the closing path. The first two must reject missing structure; the obstacle must produce physical contact and prevent a passing clear-path verdict. Wheel driving/turning and geometry audits must be repeated against the revised assembled scene.

Not established: flight actuator torque-speed curve, electrical energy consumption, reaction-torque telemetry, bearing stresses, latch/lock/power-off behavior, elastic panel response, fatigue, or full CAD-detail swept contact. This is a servo-held rigid-body study mechanism, not a calibrated flight mechanism.

## Authoring and operation

Use `author_panel.py` through the production typed USD document API after the CAD-only scene authoring. `author_panel.py parameters` refreshes only CAD-derived physical/control parameters; `author_panel.py fixtures` creates saved panel acceptance scenes. Then `author_simulation.py fixtures` creates wheel fixtures. Never run two authoring loops against the same editor simultaneously. The Modelica source is `models/FlipPanelController.mo`; the bounded test observer is `scenarios/tests/flip_panel_acceptance.rhai`. The Twin declares no automatic Modelica library roots because this is a standalone sourceAsset program, not a library package.

Operator requests go to the controller's degree-valued `command_deg` input through SetPorts. External API writes require a stable nonzero `producer_id`; discover the controller API id from the live hierarchy. Output `angle` is radians. Never write panel transforms to command motion. The parked scene requests 82 degrees; acceptance-driving programs remain disabled there. Authored hinge angle input and drive target match that initial pose.

## Supporting engine correction

Windows connection preflight exposed separator drift in `lunco-assets-path`: native Path normalization returned backslashes while root URI normalization used forward slashes. Relative canonicalization and root canonicalization now use the existing `slashed` owner helper after normalization. No model-specific resolver or direct USD rewrite was introduced. Focused `relative_keeps_the_anchors_scheme` unit test passes on Windows; production build and typed connection authoring also pass.

Remaining generic engine issues: repeated live editor reloads previously faulted with duplicate projected body identities, so native acceptance uses fresh production processes. Some fault-fixture starts logged wheel seating corrections; startup determinism is not certified. Camera-selection UI telemetry errors remain separate from the verified mechanism.

The singleton `apiSchemas` interoperability defect is corrected in the canonical OpenUSD TextWriter: list-op statement values now retain brackets even for one token. The regression failed before the correction; all 37 text-writer roundtrip tests pass afterward. The local production build uses the sibling `../openusd` source checkout; this correction has not been published upstream. `repair_usd_exports.py` re-exported the main scene and all eight test fixtures through the production typed document API, preserving existing attribute values. Pixar Sdf accepts all nine persisted layers. No direct USDA text rewrite or CAD re-tessellation was used. Original scene backups are outside this Twin in `../flip_rover_v5-export-backup-before-writer-fix`.

## Post-export regression evidence (2026-10-01 local)

- Rebuilt production executable; corrected writer tests: 37/37 PASS. All nine simulation layers pass Pixar Sdf parsing after API serialization.
- `test-export-fix-panel_cycle.log`: native PASS, 4,440 ticks / 74 seconds. Missing-drive and missing-joint fixtures reject at zero ticks; blocked-panel fixture fails at 4,440 ticks as expected. Wheel repeat and obstacle fixtures pass at 1,140 ticks / 19 seconds; invalid-mass and stock-visual mutants fail as expected. All eight expected verdicts match.
- Clean graphical session: port 4186, PID 35104. Initial load and full RestartScene reach ready=true, world_hold=false, faulted=false, pending_count=0. Read-only structural verification passes before and after restart: 339 visible CAD mesh chunks, 96 panel-owned members, six hidden contact shapes, nine joints, correct wheel/panel mass and inertia. A full restart is not proof that every editor hot-reload path is repaired.
- Geometry audit still reports 195 components / 761,656 triangles and maximum coordinate error 5.913e-8 m. Simulation CAD SHA-256 remains `b17f77f404ea63f3df2182b574efd6c84ab0904a37632ef37fa9976ee627f969`. Original CAD/USDC and retained visual layers are unchanged.
- The export session on port 4184 timed out during scene readiness while several editor previews were opened; it was closed and is excluded from runtime acceptance. Export/parser results from that session are distinct from the fresh-process native tests above.
- A subsequent unchanged panel `physics:mass = 15` typed edit/save reproduced `usd-sim-duplicate-order-identity` for Wheel_FL in session 4186. Therefore the successful full restart does not establish editor physics hot-reload safety. That session was closed for production rebuild testing; the eight fresh-process physical verdicts remain valid.
- A candidate child-admission guard passed its focused test but did not prevent the same live physics fault in session 4188. It was removed rather than shipped as a fix. The candidate-build native fixtures (`test-reload-fix-*.log`) again matched all eight verdicts, but those fresh-process tests do not exercise hot reload. A broader candidate-build runtime-core suite reported 42/43 passes, with the preview-scale test failing; no complete runtime-core pass is claimed.
- Final production rebuild retains only the verified serializer correction (no candidate projection changes). Fresh session port 4190, PID 41752 is left open: ready=true, world_hold=false, faulted=false, pending_count=0. Live topology and panel structural preflight pass; `FLIP_export_fixed.png` records the inspection-camera presentation. Do not perform live physics editor saves in this session; close/reopen the simulator after physical authoring until the duplicate-identity defect is resolved.

## Final evidence (2026-10-01 local)

- `test-panel-cycle.log`: PASS, 4,440 ticks / 74 s; six endpoints, maximum error 0.000995 degrees; anchor error 0.856 mm; orientation disagreement 0.0231 degrees; commanded-motion rate 0.195052 rad/s / tilt 1.39772 degrees; hold rate 0.010297 rad/s; zero panel contacts; total mass 450 kg. Startup settling separately reached 0.57404 rad/s / 10.7201 degrees and was settled before the first command.
- Missing drive and missing joint: expected FAIL at 0 ticks, explicit structural fault predicates. Blocked panel: expected FAIL at 4,440 ticks; one native contact pair, maximum closure error 15.079 degrees. Thus the clear-path test cannot pass with a real obstruction.
- Wheel repeat: PASS, 1,140 ticks / 19 s; travel 13.40085 m, heading change 57.39063 degrees, peak shaft rate 2.73284 rad/s. 80 mm obstacle: PASS, travel 12.46586 m, heading change 57.38056 degrees, peak shaft rate 5.22064 rad/s; trailing-wheel clearance predicate passes. Deliberate mass/stock-visual mutants both FAIL as required.
- Fresh graphical production session: port 4182, PID 22924; ready=true, world_hold=false, faulted=false, pending_count=0. `test-live-physics.log` and `test-solar-panel-sim.log` pass their exhaustive topology and structural gates. There are nine joints and six hidden contact shapes; only 339 CAD mesh chunks render, 96 on the panel body.
- `FLIP_panel_closed.png` and `FLIP_panel_open.png`: real live commanded endpoints, measured 0 and 89.999 degrees; `FLIP_panel_ready.png`: final parked 82-degree presentation. All visually inspected. The source declares units, but runtime Modelica port metadata still reports no unit: automatic metadata-level unit checking is not established by these tests.
- CAD audit: all 23 sampled poses/clamps pass; saved simulation CAD SHA-256 `b17f77f404ea63f3df2182b574efd6c84ab0904a37632ef37fa9976ee627f969` remains unchanged during read-only tests. Geometry audit preserves all 195 components / 761,656 triangles, maximum coordinate export error 5.913e-8 m. Original CAD and USDC were not changed.
- Production parse validation accepts the main scene, Modelica program and test observer. Python scripts compile; the focused Windows canonical-path unit test passes; the production executable rebuild succeeds; Rust formatting and focused diff whitespace checks pass. None of these substitutes for the physical test verdicts above.

Reproduce the native panel gate from the LunCoSim repository:

```
target/debug/luncosim.exe test --api <unused-port> --scene <absolute-FLIP-folder>/FLIP_test_panel_cycle.usda --max-ticks 5000
```

Keep the CAD visual layers, `models/FlipPanelController.mo`, observer directory and `twin.toml` beside the scene. This package still depends on the installed LunCo rover library.
