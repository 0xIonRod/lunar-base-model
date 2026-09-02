# Griffin-1 Twin setup instructions

This file is the operational setup guide for the Astrobotic Griffin-1 /
Moon Base II study Twin. It assumes a clean LunCoSim checkout and a native
Windows build, but the USD and Rhai package is portable to other hosts.

## Inputs required before a flight-fidelity build

The current package can be run as an integration MVP without these inputs, but
a flight-fidelity version requires:

1. Griffin as-built CAD/envelope and measured mass properties.
2. Griffin propulsion, RCS, propellant, leg, sensor, and GNC interfaces.
3. FLIP as-built geometry, mass properties, wheel/traction, power, thermal,
   payload, and communications data.
4. Registered Nobile Crater DEM and site frame.
5. Mission epoch, solar geometry, command timeline, and release sequence.
6. A source or owner confirmation for every parameter marked unknown.

Until these arrive, keep the parameter-status metadata and the assumption
table unchanged.

## Step 1: prepare the repository

Use a clean LunCoSim main checkout. The package was authored against:

    042f024679900c9916dc23ee52f0485ceae5392f

Do not copy files from the old dirty worktree into the clean checkout. Confirm
that the checkout contains Cargo.toml, assets/, crates/, and twins/.

## Step 2: place the Twin

The package root is:

    twins/astrobotic-griffin-1

Keep this structure:

    twin.toml
    scenes/griffin_1_surface_ops.usda
    vehicles/griffin_1.usda
    vehicles/flip.usda
    behaviors/griffin_1_flip_patrol.btxml
    environments/south_pole_surrogate.usda
    scenarios/griffin_1_surface_ops.rhai
    tools/griffin_controls.rhai
    research/griffin_1_assumptions.md
    README.md
    handover.md
    agent_to_agent_missing.md

The Twin-local references use twin://astrobotic-griffin-1/. Do not change them
to absolute Windows paths.

## Step 3: build the current LunCoSim binary

From the repository root:

    $env:PATH = 'C:\Program Files\Git\usr\bin;' + $env:PATH
    cargo build -p lunco-luncosim --bin luncosim

The PATH line supplies date.exe for the current celestial EOP build helper.
It changes only the current PowerShell process.

## Step 4: validate authored source

Run:

    .\target\debug\luncosim.exe --validate twins\astrobotic-griffin-1\vehicles\griffin_1.usda twins\astrobotic-griffin-1\vehicles\flip.usda twins\astrobotic-griffin-1\environments\south_pole_surrogate.usda twins\astrobotic-griffin-1\scenarios\griffin_1_surface_ops.rhai twins\astrobotic-griffin-1\tools\griffin_controls.rhai twins\astrobotic-griffin-1\behaviors\griffin_1_flip_patrol.btxml

Expected result: six OK lines. A parse pass only proves syntax and source
loading; it does not prove physics or mission completion.

## Step 5: run the interactive Twin

Run:

    .\target\debug\luncosim.exe --scene twins\astrobotic-griffin-1\scenes\griffin_1_surface_ops.usda

Check:

- the Griffin lander is present at the authored descent start;
- the South-Pole surrogate ground is present;
- the camera and landing target are present;
- the four-wheel FLIP study proxy is visible on the lander top deck during
  descent;
- the isogrid deck, clean top deck, matched vertical side solar arrays, two
  collision-safe ramps, and the ordered route markers are present;
- the runtime has no unresolved twin:// asset error.

The persistent control brief is part of the interactive acceptance check:

- click the Griffin lander to possess it and verify the lander control card;
- use `W/S` pitch, `A/D` roll, `Q/E` yaw, `Space` thrust, and `G` release;
- after rover release, click FLIP to possess it and verify the rover HUD;
- use `W/S` drive, `A/D` steer, `Space` brake, and `F` to toggle autopilot;
- use `Escape` or `Backspace` to return to free flight.

The Twin-local Rhai tool library exposes the same handoff explicitly for the
console: `griffin_controls::control_lander()`,
`griffin_controls::control_rover()`, and
`griffin_controls::release_control()`.

The current prototype keeps FLIP on a scene-level fixed top-deck adapter joint
through descent, deploys the two physical side ramps after touchdown, then
releases the live joint before rover egress. The earlier six-wheel jointed
attempt remains historical failure evidence; the active asset is the
four-wheel FLIP proxy.

## Step 6: run the deterministic headless check

Run:

    .\target\debug\luncosim.exe test --scene twins\astrobotic-griffin-1\scenes\griffin_1_surface_ops.usda --max-ticks 14400 --tick-hz 60 --verdict-channel GRIFFIN_SURFACE_OPS

Interpret the result:

- exit 0: the complete scenario reported PASS;
- exit 1: the scenario or physics reported FAIL;
- exit 2: the bound expired or the app exited before a verdict.

The original staged baseline reports PASS at 3,983 ticks / 66.38 simulated
seconds on `luncosim 0.6.0-nightly.64.1 (042f0246)`, before the current
attached-ramp release changes. The active prototype is a separate
re-qualification target: the production run reaches touchdown, both ramp
commands, adapter release, and FLIP autopilot engagement, then expires
NO-VERDICT without post-release waypoint progress. The route tree is
Griffin-local; do not substitute the generic LanderTest patrol asset because
its waypoint paths belong to another scene.

The active runtime build includes a fixed-joint cargo gate: FLIP cannot consume
the ramp-approach sensor while it is still attached to the lander. The current
prototype also treats the released adapter plate/restraints as non-colliding;
only the deck, ramps, and surface are the post-release contact path. A generic
fixed-joint regression passes, but the FLIP-specific body remains at its
release pose after detach, so the missing phase is vehicle-body promotion/wake
and route motion—not a missing Rhai event or a reason to add timer-only PASS.

## Step 7: investigate before changing the verdict

If the command reports NO-VERDICT:

1. Check the terminal log for a physics-body-escaped fault.
2. Confirm the lander event source paths.
3. Confirm the Rhai task is attached to /Griffin1SurfaceOps/Scenario/Mission.
4. After release, confirm the surface-waypoint and base-site events are
   emitted by FLIP; do not treat attached ramp sensors as acceptance events.
5. Confirm the rover command reaches its supported drive ports and that its
   body leaves the adapter release pose.
6. Add diagnostics to the acceptance observer, including live body state,
   velocity, contacts, wheel state, and joint ownership.
7. Keep the deterministic bound and report the missing phase.

Do not add a timer-only PASS.

## Step 8: extend the flight-attached path with measured data

Keep the active attached prototype bounded and do not treat it as flight
validation. Replace its proxy geometry and mass properties only when the
measured Griffin/FLIP ICD is available.

The implementation must define:

- joint or payload constraint topology;
- combined mass, COM, and inertia;
- which body owns guidance mass;
- release-state transition;
- body-escape telemetry;
- bounded landing test;
- reproducible PASS/FAIL verdict.

Start with the smallest lander-plus-FLIP attached fixture. Add the route only
after the landing fixture is stable.

## Step 9: replace assumptions with evidence

When a mission owner or public source supplies data:

1. Add the source and date to research/griffin_1_assumptions.md.
2. Mark each value as measured, supplier-provided, public estimate, assumed,
   or unknown.
3. Update the relevant USD or Modelica input.
4. Add a focused runtime or numerical check.
5. Update README.md, handover.md, and agent_to_agent_missing.md.
6. Record any changed verdict bounds separately from physics changes.

## Step 10: final product definition

The finished product is complete only when it contains:

- a source-backed Griffin/FLIP parameter manifest;
- a reusable Griffin lander and FLIP vehicle;
- a registered South-Pole environment;
- a physical attachment and release model;
- a working landing event chain;
- power, thermal, communications, and mobility constraints;
- ordered surface tasks and route markers;
- deterministic, jittered, and threaded acceptance results;
- provenance and limitations documented;
- a reproducible GRIFFIN_SURFACE_OPS PASS.

The current package is the integration-MVP foundation for that product, not the
final flight-fidelity Twin.
