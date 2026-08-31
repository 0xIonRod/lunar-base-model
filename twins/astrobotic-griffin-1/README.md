# Astrobotic Griffin-1 / Moon Base II Twin

This Twin is a LunCoSim study model for the planned Astrobotic Griffin-1
mission, now presented by NASA as Moon Base II. It composes a generic LunCoSim
powered-descent lander, a four-wheel FLIP mobility study proxy, a deterministic
South-Pole surface surrogate, live Modelica co-simulation, USD-authored
connections, and a Rhai mission sequence.

It is an integration and operations study, not a flight-validated Griffin
vehicle model. Public Griffin and FLIP engineering data must replace the
surrogate values before any performance, landing, structural, or mobility
claim is made.

## Current public mission baseline

The latest primary-source baseline used for this package is:

- NASA describes Griffin-1 / Moon Base II as a 2026 mission to the lunar
  South-Pole region, carrying more than 1,100 lb of cargo including
  Astrolab's FLIP rover to Nobile Crater.
- NASA's August 2026 update says Griffin-1 is undergoing environmental testing
  at NASA's Jet Propulsion Laboratory, has completed mass-properties testing,
  and is planned for a late-2026 launch.
- Astrobotic's June 2026 update says the integrated lander is moving through
  environmental testing, with FLIP to be integrated at the Florida launch
  processing site.
- Astrolab's public announcement describes FLIP as a FLEX Lunar Innovation
  Platform, with a public mass of nearly half a metric ton and a 30 kg payload
  capacity. These public values are not silently copied into the generic
  vehicle asset; the Twin records where the real values still need to enter.

Sources:

- NASA, [Moon Base II: Astrobotic Griffin-1](https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/)
- NASA, [NASA Provides Updates on Moon Base Cargo Landers and Tech Demonstrations](https://www.nasa.gov/missions/moon-base/nasa-provides-updates-on-moon-base-cargo-landers-tech-demonstrations/)
- Astrobotic, [Griffin-1 Lunar Lander Unveiled Ahead of Environmental Testing](https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/)
- Astrolab/Astrobotic, [FLIP rover joins Griffin-1](https://www.astrobotic.com/astrolabs-flip-rover-joins-astrobotics-griffin-1-to-the-moon/)

## Package layout

| Path | Purpose |
|---|---|
| twin.toml | Twin identity and default scene |
| scenes/griffin_1_surface_ops.usda | Mission composition and USD topology |
| vehicles/griffin_1.usda | Reusable Griffin lander wrapper around the LunCoSim descent lander |
| vehicles/flip.usda | Reusable FLIP study asset with four-wheel all-wheel-steer mobility, EPS, and thermal networks |
| behaviors/griffin_1_flip_patrol.btxml | Griffin-local route tree targeting the deck approach, ramp exit, waypoints, and base site |
| environments/south_pole_surrogate.usda | Labelled flat/cratered study surface |
| scenarios/griffin_1_surface_ops.rhai | Mission sequencing and route policy |
| research/griffin_1_assumptions.md | Public facts, surrogate values, and confidence boundaries |
| handover.md | Detailed implementation and verification handover |
| agent_to_agent_missing.md | Concrete follow-up work for the next coding agent |
| instructions.md | Step-by-step setup and completion procedure |

## Build and run

Run from the LunCoSim repository root, which is the directory containing
Cargo.toml and assets/.

### Build

On native Windows, the current EOP-data build helper expects the Unix date
utility. If Git for Windows is installed, build with its utility directory
temporarily prepended to PATH:

    $env:PATH = 'C:\Program Files\Git\usr\bin;' + $env:PATH
    cargo build -p lunco-luncosim --bin luncosim

The PATH change is process-local and does not change the repository.

### Parse/lint the Twin files

    .\target\debug\luncosim.exe --validate twins\astrobotic-griffin-1\vehicles\griffin_1.usda twins\astrobotic-griffin-1\vehicles\flip.usda twins\astrobotic-griffin-1\environments\south_pole_surrogate.usda twins\astrobotic-griffin-1\scenarios\griffin_1_surface_ops.rhai behaviors\griffin_1_flip_patrol.btxml

All five files must report OK.

### Run the scene

    .\target\debug\luncosim.exe --scene twins\astrobotic-griffin-1\scenes\griffin_1_surface_ops.usda

The old sandbox binary is not the target for this Twin. Use the production
luncosim binary and the default scene from twin.toml.

### Run the bounded headless check

    .\target\debug\luncosim.exe test --scene twins\astrobotic-griffin-1\scenes\griffin_1_surface_ops.usda --max-ticks 14400 --tick-hz 60 --verdict-channel GRIFFIN_SURFACE_OPS

Exit code 0 means the Rhai scenario emitted PASS. Exit code 1 means a
terminal runtime or scenario failure. Exit code 2 means the bound expired
without a verdict. The current corrected package passes the same composed
scene at 3,983 ticks / 66.38 simulated seconds on the installed
`luncosim 0.6.0-nightly.64.1 (042f0246)` binary. The 14,400-tick bound remains
the reproducible command because it leaves margin for Modelica startup and
route completion.

## What the MVP demonstrates

The current stable boundary demonstrates:

1. A Twin-local package resolves through twin:// references.
2. Griffin and FLIP are reusable USD wrappers, not Rust-only entities.
3. The lander owns its Modelica propulsion, attitude, sensor, and touchdown
   contracts.
4. The mission scene owns guidance wiring, landing target, camera, anchors,
   waypoint markers, and mission metadata.
5. The Griffin wrapper carries the MoonDAO prototype configuration: 625 kg
   payload class, four landing legs, isogrid deck, side-mounted solar arrays,
   top-deck adapter, and two side ramps. These are explicit study requirements,
   not public as-built Griffin values.
6. FLIP uses a four-wheel all-wheel-steer study topology, with explicit wheel,
   motor/gearbox, finite-EPS, and motor-thermal Modelica contracts. The
   wheel count and numeric values are proxy assumptions until FLIP ICD data is
   available.
7. The surface environment uses the current runtime's flat-site terrain role.
8. The Rhai task tree expresses descent event waits, physical ramp deployment,
   adapter-joint release, and a ramp-approach → ramp-exit → surface-transit →
   base-site route. The close-spaced transit and base-arc markers are authored
   to keep the current four-wheel proxy on a feasible turn path.

The active scene now keeps FLIP on a scene-level fixed top-deck adapter joint
during descent, deploys two finite-mass collision ramps after touchdown, then
removes the live adapter joint before the rover route begins. Fixed-joint cargo
is prevented from consuming route sensors before that release. The current
prototype ramps use a 12 m clear collision envelope to accommodate the study
proxy's steering transient. The public
Astrolab material describes direct top-deck egress; the ramps are the MoonDAO
prototype requirement. The historical six-wheel wrapper is retained as
`vehicles/flip.legacy-six-wheel.usda` for comparison, not as the active asset.

## Next required data

Replace the surrogates in this order:

1. Mission configuration: final launch window, landing site frame, landing
   coordinates, epoch, and mission timeline.
2. Griffin vehicle: dimensions, mass properties, propulsion thrust curve,
   propellant loads, attitude-actuator limits, leg geometry, and landing
   qualification thresholds.
3. FLIP: as-built dimensions, wheel/suspension geometry, mass properties,
   tire/traction model, actuator limits, battery, solar, thermal, payload
   interfaces, and command/telemetry dictionary.
4. Surface: registered DEM, slopes, illumination, hazards, regolith
   parameters, and a frame-transform validation report.
5. Operations: release mechanism, landed-state authority handoff, route,
   communications delays, power/thermal constraints, and payload activities.

Every replacement must update research/griffin_1_assumptions.md and add a
verification result that distinguishes sourced data from inferred values.
