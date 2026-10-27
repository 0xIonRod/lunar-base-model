# Griffin / FLIP completion plan

> Historical plan. See
> `twins/astrobotic-griffin-1/contracts/flip-cad-integration-2026-10-27.md`
> for the current integration, accepted subsystem checks and remaining mission
> boundary. The instructions below describe the earlier session.

Date: 2026-10-20
Status: execution plan; simulator updates and runtime acceptance have not been performed for this plan.

## Outcome

Run the updated LunCoSim core, establish a passing current mission, then replace
the existing vehicle visuals with CAD-derived Griffin and FLIP assets while
preserving functional subsystems. Griffin must carry FLIP through descent,
land and settle, release FLIP through the real attachment mechanism, and allow
FLIP to complete the same ordered surface route and stop. The final mission
must remain stable and meet an explicitly agreed performance budget.

## Starting evidence and sources

- Simulator checkout found at `F:\lunco-sim`; its current revision, upstream
  status, local changes, build and running process still need inspection.
- Mission checkout is `F:\lunar-base-model`, inspected at `c10b4e6` with a clean
  working tree before adding this plan. Latest remote revisions are unverified.
- Canonical mission: `twins/astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda`.
  `missions/mission-002/scene.usda` composes it. The Twin default is a visual
  review scene, so opening the default is insufficient to test the mission.
- Functional vehicles: `vehicles/griffin_1.usda` and `vehicles/flip.usda` inside
  that Twin. They are already separate reusable assets, even though their
  current visuals need replacement.
- CAD candidates: `freecad/griffin_8/griffin_8_lander.FCStd` and
  `freecad/flip_v3/FLIP_rover_v3_corrected.FCStd`. Their READMEs explicitly leave
  simulator integration open; fresh exports must be checked rather than assumed.
- The Twin README and gap report record incomplete touchdown/route acceptance,
  collision projection concerns and joint seating errors on older core builds.
  Retest these on the updated core; their historical status is not a fresh result.

## Configuration decision and retained systems (2026-10-20)

Use five main engines as the provisional GM1 modeling target. Astrobotic's
[GM1 procurement announcement](https://www.astrobotic.com/astrobotic-selects-lander-engines-more-for-griffin-viper-mission/)
specifies five 700-lbf engines, and its August 2021 user guide (printed page 26)
also specifies five. The
[general Griffin product page](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
instead says seven. This is a conflict between manufacturer sources, not proof
that the five-engine CAD is obsolete. The mission-specific procurement and
technical documentation are the stronger basis for this study; final current
flight configuration remains unconfirmed by the evidence checked here.
The [October 2025 mission update](https://www.astrobotic.com/griffin-1-mission-update/)
describes propulsion integration but does not resolve the engine count.

Keep the seven-engine runtime asset unchanged during baseline testing. Then
migrate count, engine identities, geometry, actuator locations, allocation,
thrust/mass-flow parameters and related requirements together as a separate
verified configuration change. Do not redistribute seven-engine total thrust
over five engines without a documented physical basis. Requalify landing after
that change before calling the CAD integration accepted.

User direction: retain and connect the existing FLIP simulator systems to the
CAD-backed rover. Preserve its drive/steering, suspension/contact, motor,
gearbox/shaft, battery, solar, thermal, sensors, controls and route connections.
Retain the explicit Griffin payload adapter/release interface. No ML retraining
is part of this migration. Connection and runtime verification remain execution
work after the passing baseline; this plan does not claim they are complete.

## 1. Update and prove the simulator independently

- Read simulator `AGENTS.md` and build/run instructions. Inspect Git status,
  remotes, branches and any running simulator before changing the checkout.
- Fetch current upstream refs, identify the intended supported main revision,
  preserve local work, and update without discarding it. Record the exact SHA,
  build profile, dependencies, launch arguments and executable used.
- Build and run the production simulator. Use its current CLI/API help rather
  than assuming historical commands still apply after the core changes.
- Run focused core checks and a known simple scene: load, physics/contact,
  scripts, controls, telemetry, reset and clean shutdown. Reuse an active headful
  instance for Editor inspection and avoid competing simulator instances.
- Capture startup/runtime diagnostics. Resolve crashes, asset/API/schema
  compatibility errors and physics failures before introducing the Griffin Twin.

Exit: a repeatable simulator smoke test passes on a pinned revision; remaining
diagnostics have an explanation and no unresolved effect on required behavior.

## 2. Update and establish the existing Griffin / FLIP mission

- Fetch and inspect mission updates, preserving local work. Record the mission
  SHA and resolve its required Twin registration, shared libraries and generated
  NOBILE03 terrain against the pinned simulator.
- Run repository validation and the relevant existing vehicle/Twin checks.
  Open the explicit surface-operations scene and verify composed references,
  coordinate frames, collision ownership, mass properties and joint frames.
- Diagnose in increasing scope: lander/contact, isolated rover motion, adapter
  attachment/release, then the integrated mission. Fix core regressions generically;
  keep mission configuration and sequencing in the Twin.
- Prove powered descent with FLIP attached, stable touchdown, commanded release,
  physical separation/egress, ordered waypoint arrivals and a final stopped rover.
  Verify both manual control and the existing route behavior.
- Reuse authored numeric requirements. Before acceptance runs, make any missing
  position, tilt, velocity, hold-time, route and timeout limits explicit. Do not
  relax limits merely to obtain a PASS. Preserve the current route coordinates,
  order and arrival criteria as the migration comparison contract.
- Run at least three fresh-start full missions with the same initial conditions.
  Save verdicts, trajectories, phase times, contact/pose evidence, diagnostics,
  screenshots and phase-specific performance samples.

Exit: the current assets complete the actual landing-release-drive sequence
repeatedly. If they fail, this phase remains open; CAD replacement does not start.
Save this passing simulator/mission revision pair as the rollback baseline.

## 3. Prepare CAD exports and subsystem mapping

- Audit CAD inputs and produce reproducible per-component exports with units,
  axis conversion, origin, hierarchy, material and source-hash metadata.
- Export fixed structures together where useful; preserve separate moving
  wheels, hinges and ramps with named pivot/mount frames. Confirm dimensions,
  orientation, wheel centres, deck seating, ground clearance and ramp reach.
- Use CAD-derived render meshes with simplified explicit collision proxies;
  do not make every CAD detail a collider or rigid body. Retain verified mass
  and inertia assumptions until replacements have an actual physical basis.
- Make an explicit mapping table: existing USD subsystem/path -> exported CAD
  part/frame -> retained connection/behavior -> verification case. Include
  propulsion/GNC, sensors, landing contacts, payload adapter, ramp mechanisms,
  wheel stations, steering/drive, battery, solar and thermal systems.
- Griffin 8 has five engines; the existing runtime asset has seven. Follow the
  configuration decision above: preserve the runtime baseline, then make a
  coordinated five-engine configuration migration and rerun landing acceptance.
  Preserve Griffin subsystem implementations while deliberately updating their
  engine instances, bindings and allocation for the selected configuration.
- FLIP v3 provides kinematic wheel/panel controls, not dynamics or qualified
  mass properties. Map its geometry to the existing FLIP mobility and power
  systems. Griffin subsystems belong to Griffin; existing FLIP subsystems belong
  to the exported FLIP model.
- Set triangle/material/asset-size budgets and numeric runtime acceptance
  limits from the passing baseline on the same hardware and build profile.
  Track physics step time separately from rendering/frame time and load time.

Exit: reviewed mapping and exports; configuration differences are resolved or
explicitly scoped, and both physical and visual frames agree.

## 4. Integrate each CAD vehicle separately

- Keep canonical vehicle wrappers as the owners of behavior, connections and
  physics. Reference CAD visuals beneath them with stable subsystem identities.
  Use the current typed Editor authoring workflow for live changes, read back
  the composed result, and save after verification.
- Replace Griffin visuals first and rerun lander/contact/descent acceptance.
  Then replace FLIP visuals and rerun isolated settle/drive/steer/brake and
  power/control checks. Preserve the other vehicle baseline at each step.
- Use simulation-driven wheel, ramp and panel transforms; avoid applying both
  CAD animation and physics motion to the same part.
- Verify collision envelopes still match the new geometry sufficiently for
  contact, seating and egress. Adapt proxies/frames deliberately where needed
  and rerun the affected tests after each physical change.
- Disable the replaced primitive visuals to avoid duplicate geometry. Keep the
  old assets available for comparison until integrated acceptance is complete.

Exit: each CAD-backed vehicle passes its focused behavior checks and visual
inspection without disconnected geometry, duplicate bodies or physics regressions.

## 5. Prove the final attached-to-driving mission

- Mount CAD-backed FLIP on CAD-backed Griffin using the explicit adapter and
  verified mating frames. Confirm no initial overlap and correct joint seating.
- Run descent and landing with the rover physically restrained. Confirm it does
  not consume route triggers or receive drive authority while attached.
- After the accepted touchdown/settle state, command release. Confirm the native
  joint and graph edge are removed, body/collider counts stay consistent, the
  rover wakes, and it remains stable during separation and physical egress.
- Reuse the accepted baseline egress method and ordered route. Prove waypoint
  arrivals and final braking through runtime observations, not elapsed time or
  a scripted teleport. Inspect underbody, wheels, ramps and terrain contacts.
- Repeat at least three fresh-start integrated runs. Compare route error,
  landing stability, mission duration, diagnostics and performance to the
  baseline using the fixed acceptance limits. Investigate differences.
- If slow, profile phase boundaries and optimize meshes, materials and collision
  complexity before changing solver fidelity. Recheck behavior after optimization.

Exit: repeated mission PASS, reviewed visuals, correct attachment lifecycle,
and measured performance within the declared budget.

## 6. Deliver and retire superseded visuals

- Promote the verified CAD references in the canonical Twin; keep the mission
  package composing that Twin without another copy of vehicles or terrain.
- Retire obsolete visuals/build paths only after reference closure is checked.
- Deliver exact simulator/mission revisions, CAD hashes/export recipe, mapping
  table, run instructions, acceptance results and a short landing-to-route video
  or equivalent screenshots/telemetry. Update the gap report with fresh evidence.
- Separate remaining study assumptions from confirmed implementation behavior.

First execution task: inspect/update/build `F:\lunco-sim` and pass the simulator
smoke test. Then update and run the unchanged mission before any CAD migration.
