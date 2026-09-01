# Astrobotic Griffin-1 / Moon Base II — LunCoSim Handover

**Document type:** agent-to-agent implementation handover  
**Repository:** `NASA-lunar-base-model`  
**Mission:** Astrobotic Griffin Mission One (Griffin-1), NASA Moon Base II  
**Prepared:** 2026-08-29  
**Research state:** current public mission information checked against NASA and Astrobotic updates available on 2026-08-29  
**Implementation status:** planning and integration handover; no Griffin executable Twin has been authored in this repository yet

## 1. Executive handover

The next Astrobotic lunar mission is Griffin-1. NASA currently describes the lander as being in environmental testing at the Jet Propulsion Laboratory after mass-properties testing, with a late-2026 launch plan. Astrobotic/Voyager’s latest mission release gives the more specific target of **no earlier than November 2026**. The mission is intended to deliver more than 1,100 lb of cargo to the lunar South Pole, including Astrolab’s FLIP rover. Sources:

- NASA, [Moon Base phases](https://www.nasa.gov/moonbase-phases/)
- NASA, [August 2026 commercial lander update](https://www.nasa.gov/missions/moon-base/nasa-provides-updates-on-moon-base-cargo-landers-tech-demonstrations/)
- NASA, [Moon Base II: Griffin-1](https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/)
- Astrobotic/Voyager, [Griffin-1 and acquisition update](https://www.astrobotic.com/voyager-awarded-298m-nasa-contract-under-completed-astrobotic-acquisition/)

This repository currently contains the first mission twin only: Blue Origin Blue Moon MK1 Endurance under `missions/mission-001/`. It has research records for Griffin-1 in `research/data-model.md`, `research/vehicles.md`, and `research/locations.md`, but it does not yet contain a Griffin-1 mission package, a LunCoSim `twin.toml`, mission-specific USD assets, Modelica source assets, or Rhai scenario assets.

The recommended implementation is a **surface-mission Twin first**:

```text
Griffin lander + landing pad + South-Pole surrogate terrain
    ├── USD authored rigid bodies, colliders, joints, payload topology
    ├── Modelica propulsion / power / thermal / GNC domains
    ├── Rhai mission phases and event policy
    └── LunCoSim API telemetry, screenshots, and verdict tests
```

Launch ascent, cislunar transfer, and a flight-quality landing ellipse should remain separate work packages until trajectory, state-vector, and vehicle data are available. The public data is sufficient for an explicitly labeled surface smoke test and mission-operations study, not for a flight-certified Griffin model.

## 2. Scope and evidence boundary

### Confirmed mission facts

| Item | Current value | Evidence |
|---|---|---|
| Mission | Griffin Mission One / Griffin-1 | NASA and Astrobotic |
| NASA designation | Moon Base II | Astrobotic June 2026 release |
| Operator identity | Voyager Lunar Systems, formerly Astrobotic Technology | Voyager/Astrobotic July 2026 release |
| Program | NASA Moon Base / Commercial Lunar Payload Services (CLPS) | NASA |
| Status | In development; environmental testing at JPL | NASA August 2026 update |
| Launch target | Late 2026; provider release says no earlier than November 2026 | NASA and Astrobotic/Voyager |
| Landing region | Nobile Crater / lunar South Pole region; NASA also uses the Mons Mouton area in current CLPS material | NASA and Astrobotic |
| Main rover | Astrolab FLIP (FLEX Lunar Innovation Platform) | NASA and Astrobotic |
| NASA payload group | LDES, Lunar LiDAR Demonstration, two Laser Retroreflector Arrays, and METAL | NASA Moon Base architecture page |
| Other named payloads | Astrobotic CubeRover/BEACON, ESA LandCam-X, Moon Pi, MoonBox, and a Nippon Travel Agency time capsule | Astrobotic manifest |
| Mission operations | Astrobotic/Voyager Mission Control Center in Pittsburgh after launch-vehicle separation | Astrobotic June 2026 release |

The current mission manifest and landing location are authoritative for this project’s mission description. The target date remains a planning target, not a guaranteed flight date.

### Values that must stay unknown or assumption-labeled

Do not invent these values in `mission.yaml`, USD, Modelica, or scenario code:

- exact launch date, launch site, and ascent profile;
- public flight state vectors, transfer trajectory, and lunar-orbit insertion sequence;
- landing coordinates, landing ellipse, and final local DEM;
- Griffin dry mass, propellant load, center of mass, inertia tensor, engine count, and detailed thrust curve;
- FLIP dimensions, mass properties, wheel geometry, motor ratings, battery capacity, and traverse plan;
- exact surface power, thermal, lunar-night, and communications budgets;
- full deployment mechanism geometry and payload mounting interfaces;
- validated regolith traction and terramechanics parameters.

Use `TBD`, `null`, or an explicit `simulator_assumption` field. Every assumed number needs units, rationale, and confidence.

## 3. Current state of this repository

### Existing assets

- [`README.md`](../README.md) defines the project rules: separate facts from assumptions, keep provenance, prefer LunCoSim-native features, and validate after parameter changes.
- [`missions/mission-001/mission.yaml`](../missions/mission-001/mission.yaml) is the current machine-readable mission contract.
- [`missions/mission-001/scene.usda`](../missions/mission-001/scene.usda) is a deliberately simple USD scene with a flat 1 km square, lunar gravity, a placeholder lander, and a simulator-only rover.
- [`scenarios/`](../scenarios/) contains five YAML operational contracts for Mission 001.
- [`research/data-model.md`](../research/data-model.md) already contains a Griffin-1/M02 data-model example.
- [`research/vehicles.md`](../research/vehicles.md) already registers Griffin-1, FLIP, and related vehicles.
- [`research/locations.md`](../research/locations.md) already registers the Nobile Region as `LOC01`.
- [`tools/validate_repository.py`](../tools/validate_repository.py) performs lightweight structural checks, but it currently requires `mission-001` and exactly five root-level scenario files.

### What is not present

The workspace is not yet a LunCoSim Twin. It lacks:

1. `missions/mission-002/twin.toml`.
2. A default scene composed according to the current LunCoSim Twin convention.
3. Referenced Griffin, FLIP, and CubeRover USD vehicle files.
4. `PhysicsRigidBodyAPI`, collision, mass/inertia/COM, wheel, joint, and actuator authoring for the real vehicle topology.
5. Mission-specific `.mo` domains for propulsion, power, thermal, communications, and guidance/control.
6. Native USD connections between body ports, domain program ports, and environment outputs.
7. A first-class USD `Scenario` prim and production Rhai orchestration.
8. Mission-specific test scenes, negative fixtures, and numeric verdicts.
9. A Nobile-region terrain/illumination asset or a documented terrain surrogate.
10. A run record showing `luncosim` loaded the Twin and the cosimulation chain produced valid telemetry.

## 4. Latest LunCoSim baseline to target

The implementation target is the current `main` branch of [LunCoSim/lunco-sim](https://github.com/LunCoSim/lunco-sim), not the historical Godot project or the retired `sandbox` executable.

### Runtime and build

The current repository README identifies the production mission simulator as `luncosim`:

```powershell
git clone https://github.com/LunCoSim/lunco-sim.git
cd lunco-sim
cargo build -p lunco-luncosim --bin luncosim
target/debug/luncosim --api 4101
```

The current LunCoSim agent guide states that the old `sandbox` executable name is retired. The same guide requires an explicit API port, one production process while iterating, and API-driven reload/inspection rather than overlapping GUI sessions. See [LunCoSim README](https://github.com/LunCoSim/lunco-sim) and [LunCoSim AGENTS.md](https://github.com/LunCoSim/lunco-sim/blob/main/AGENTS.md).

For headless validation, target the current `luncosim-server` path described by the spacecraft architecture and Modelica run guidance. Do not assume that `luncosim --no-ui` is equivalent to a GPU-free server; the current architecture notes that render-gated resources can still be compiled into that path. See [run-modelica guidance](https://github.com/LunCoSim/lunco-sim/blob/main/skills/run-modelica/SKILL.md).

### Architecture rules that govern this Twin

The current LunCoSim architecture separates the mission into three layers:

| Layer | Owns | Author in |
|---|---|---|
| Structure and wiring | bodies, colliders, mass/inertia, joints, vehicle topology, program bindings, USD connections | USD |
| Continuous subsystem dynamics | propulsion, propellant, battery, thermal, controllers, other evolving equations | Modelica / cosim |
| Solver and generic physical behavior | rigid-body dynamics, joints, contacts, wheel/suspension/friction behavior, port plumbing | Rust library |

This means a Griffin or FLIP implementation should be a USD-authored vehicle, not a new Griffin-specific Rust struct. Current LunCoSim already supports data-driven rover structure, USD-authored joints, compound rigid bodies, native USD cosim connections, body-frame force/torque ports, attitude/body-rate outputs, live mass/inertia/COM ports, arbitrary wheel actuator topology, prismatic drives, event triggers, and a throttle-driven plume visual. See [spacecraft modeling architecture](https://github.com/LunCoSim/lunco-sim/blob/main/docs/architecture/33-spacecraft-modeling.md).

### Program and domain rules

Use one `LunCoProgramAPI` program prim per physical domain under the vehicle. A Griffin vehicle should start with:

```text
Griffin
├── Propulsion
├── GNC
├── Electrical
├── Thermal
└── Communications
```

Each program names its own `.mo` source through `info:sourceAsset`. Cross-domain signals use typed causal USD `inputs:`/`outputs:` connections. Acausal Modelica connectors stay inside one domain; do not wire an electrical `Pin` directly to a thermal `HeatPort` across generated domain units. See [scenarios and multi-domain vehicles](https://github.com/LunCoSim/lunco-sim/blob/main/docs/architecture/34-scenario-and-multidomain.md).

The PortRegistry is the one input-write path. Wires, API commands, Python, and Rhai must converge on the port surface. Do not write directly to `ModelicaModel.inputs` or bypass a cosim port; the runtime synchronization can overwrite that value on the next step.

Gravity comes from the environment. Do not add lunar gravity as a second force in a Modelica model. Connect a model’s gravity input to the environment’s `gravity_accel` output only when the model contract declares such an input.

### Scenario rules

The mission sequence belongs in a first-class USD `Scenario` prim whose `LunCoProgramAPI` references a Rhai source asset. Production Rhai is event-driven policy, not a per-tick control loop. Continuous control math belongs in Modelica or the engine kernels; Rhai decides phases and calls high-level verbs such as `nav_to`, `drive`, `brake`, `cmd`, and `query`.

Persistent Rhai state must live on `this` inside engine-called hooks. Helper functions are pure and cannot see top-level `let` state. Use the built-in vector/angle math instead of reimplementing it. See [author-scenario guidance](https://github.com/LunCoSim/lunco-sim/blob/main/skills/author-scenario/SKILL.md).

## 5. Proposed Griffin-1 Twin layout

The following is the target layout inside the LunCoSim checkout or a referenceable Twin directory. The NASA research repository can retain the mission contract and provenance beside it.

```text
astrobotic_griffin_1/
├── twin.toml
├── scene.usda
├── assets/
│   ├── environments/
│   │   └── nobile_region_surrogate.usda
│   ├── landers/
│   │   └── griffin_1.usda
│   └── rovers/
│       ├── flip.usda
│       └── cuberover_2u.usda
├── models/
│   ├── griffin_propulsion.mo
│   ├── griffin_gnc.mo
│   ├── griffin_electrical.mo
│   ├── griffin_thermal.mo
│   └── griffin_communications.mo
├── scenarios/
│   └── griffin_1_surface_ops.rhai
├── tests/
│   ├── scene_griffin_minimal.usda
│   ├── scene_griffin_missing_wheel_attribute.usda
│   └── scenario_griffin_surface_ops.rhai
└── README.md
```

The minimal Twin manifest follows the current LunCoSim convention:

```toml
name = "astrobotic-griffin-1"
version = "0.1.0"
description = "Griffin-1 / Moon Base II surface mission study"

[usd]
default_scene = "scene.usda"
```

Everything needed to open the study should be beneath the Twin folder: USD composition, referenced vehicle assets, `.mo` models, and `.rhai` scenarios.

## 6. Target scene composition

The default `scene.usda` should contain:

```text
Mission002
├── Environment
│   ├── Terrain
│   ├── Illumination
│   └── CommunicationsEnvironment
├── Griffin
│   ├── Propulsion
│   ├── GNC
│   ├── Electrical
│   ├── Thermal
│   └── Communications
├── FLIP
│   ├── Electrical
│   ├── Thermal
│   └── Mobility
├── CubeRover
├── Payloads
└── Scenario
```

Required first-pass authoring:

- `metersPerUnit = 1` and the project’s chosen up-axis must be explicit.
- Lunar gravity must be authored/provided once through the environment.
- Griffin, FLIP, and CubeRover roots must have authored rigid-body and collision topology.
- Mass, diagonal inertia, center of mass, and principal axes should be authored where known; unknown values must be clearly marked as simulator assumptions.
- Child geometry should use compound collision under the parent rigid body rather than becoming accidental independent bodies.
- A movable landing leg, ramp, latch, wheel, or deployment part needs both a rigid body and the appropriate USD joint. Internal geometry should not become an unconnected body.
- FLIP wheel count, wheel locations, radii, masses, drive ports, suspension, motor/gearbox, tire stiffness, friction, and damping must come from USD attributes. Current LunCoSim rejects incomplete wheel authoring instead of silently adding Rust defaults.
- A six-wheel or custom-wheel topology must use explicit per-wheel USD drive connections. Do not rely on old left/right parity or wheel-index conventions.
- Payloads can start as metadata-bearing USD scopes, but any payload that affects mass, power, thermal load, navigation, or communications must eventually have a typed model or port contract.

Example cross-domain shape:

```usda
def Xform "Griffin" (prepend apiSchemas = ["PhysicsRigidBodyAPI"])
{
    float inputs:force_local_y.connect = </Mission002/Griffin/GNC.outputs:thrust>
    float inputs:torque_local_x.connect = </Mission002/Griffin/GNC.outputs:torque_x>

    def Scope "Propulsion" (prepend apiSchemas = ["LunCoProgramAPI"])
    {
        uniform asset info:sourceAsset = @models/griffin_propulsion.mo@
    }

    def Scope "GNC" (prepend apiSchemas = ["LunCoProgramAPI"])
    {
        uniform asset info:sourceAsset = @models/griffin_gnc.mo@
        float inputs:altitude.connect = </Mission002/Griffin.outputs:position_y>
        float inputs:descent_rate.connect = </Mission002/Griffin.outputs:velocity_y>
        float inputs:g.connect = </Mission002/Environment.outputs:gravity_accel>
        float inputs:soc.connect = </Mission002/Griffin/Electrical.outputs:soc_out>
    }
}
```

This is an integration shape, not a claim that the shown names or units already exist in the repository. The final port names must come from the compiled Modelica contracts and the composed USD stage.

## 7. Mission phase model

The first production scenario should implement these phases with event/predicate transitions:

1. **Descent setup** — initialize the lander and environment; verify all required domains are ready.
2. **Powered descent** — use GNC and propulsion outputs to drive body-frame thrust; use environment gravity; record altitude, descent rate, attitude, and engine state.
3. **Touchdown** — use actual collider contact/touchdown evidence and landing-leg joint state; do not make a second independently calculated touchdown sensor.
4. **Post-landing stabilization** — wait for body velocity, angular rate, leg displacement, and contact force to settle within defined limits.
5. **Payload commissioning** — bring up power, thermal, navigation, communications, and payload health state.
6. **FLIP deployment** — command the deployment/latch mechanism and wait for the deployed state or joint predicate.
7. **CubeRover/BEACON activation** — release or activate the CubeRover, establish the software/communications state, and confirm mobility telemetry.
8. **Surface mobility** — route FLIP to a named waypoint or survey zone; exercise wheel drive, steering, traction, obstacle sensing, and energy use.
9. **Navigation and payload operations** — exercise LandCam-X/LiDAR-style local mapping, retroreflector placement/reference, and payload metadata.
10. **Illumination/power/thermal stress** — use low-Sun-angle and shadow transitions; test reserves and safe mode rather than claiming a validated lunar-night survival result.
11. **Communications loss and recovery** — disable the configured link, execute a bounded autonomous route, restore the link, and verify queued telemetry.
12. **Mission end state** — park or safe the vehicles and preserve a telemetry/evidence summary.

Each phase should have a clear entry predicate, action, timeout, success verdict, failure event, and telemetry list. Do not use arbitrary Rhai sleeps to wait for generated domain islands; wait on the readiness contract and then on real port predicates.

## 8. Verification and evidence contract

The handover agent should not claim that a scene works from a successful file parse alone. A minimum Griffin verification run must show:

### Load and readiness

- production `luncosim` or `luncosim-server` built from the intended LunCoSim checkout;
- one process on an explicit API port, normally `4101`;
- `/api/ready` reports `ready: true`, `world_hold: false`, and `pending_count: 0` before interpreting missing ports as failures;
- the Twin’s default USD scene is loaded and the `Mission002` stage is present.

### Entity and port checks

Use the current inspect-simulation sequence:

```text
ListEntities
→ identify api_id for Griffin, FLIP, CubeRover, and domain program prims
→ ReadPorts with a narrow name/port filter
→ SnapshotVariables or cosim_status for Modelica domains
→ CaptureScreenshot for visual confirmation
```

`api_id` is not the same thing as a Rhai `GlobalEntityId`; obtain it from `ListEntities`. Use `ReadPorts`/`ReadPort` rather than scraping logs. See [inspect-simulation guidance](https://github.com/LunCoSim/lunco-sim/blob/main/skills/inspect-simulation/SKILL.md).

### Numeric checks

At minimum, test:

- gravity magnitude and direction;
- static-body stability on the pad;
- landing/contact detection;
- body-frame thrust direction and torque sign;
- mass/inertia/COM read-back;
- fuel/propellant state changing only through the intended model path;
- battery state of charge and power reserve;
- FLIP wheel topology and drive response;
- no wheel motor force that is obviously inconsistent with lunar weight;
- deployment joint limits and final state;
- communications blackout and telemetry recovery;
- scenario phase order and terminal verdict.

### Negative tests

Current LunCoSim guidance requires a negative fixture and a real verdict for a green gate. Add at least:

- a wheel missing a required authored attribute;
- an unconnected required actuator port;
- an unknown post-compile port;
- an invalid or missing `info:sourceAsset`;
- a nested rigid body without a joint;
- an incompatible cross-domain connection;
- a scenario that times out before the landing or deployment predicate.

## 9. Recommended implementation order

### Gate A — repository-level contract

1. Add `mission-002` without modifying Mission 001.
2. Reconcile the existing M02 data-model example with the executable YAML schema.
3. Add `mission-research.md` with current sources, facts, unknowns, and assumptions.
4. Extend validation to discover all mission packages and per-mission scenario folders.

### Gate B — visible static Twin

1. Author `twin.toml` and a minimal default USD scene.
2. Use flat 1 km terrain as a temporary Nobile-region surrogate.
3. Add simple Griffin, FLIP, and CubeRover geometry with IDs and payload metadata.
4. Load it in `luncosim` and verify the stage and entities.

### Gate C — rigid-body and mobility Twin

1. Add body/collider/mass/inertia/COM authoring.
2. Add landing pad contact and landing-leg joints.
3. Author FLIP’s wheel topology and drive connections from USD.
4. Add deployment joints and limits.
5. Run focused physics tests and inspect ports.

### Gate D — multi-domain Twin

1. Reuse the current `RocketEngine.mo` only as a structural starting point; do not treat it as Griffin-specific validation.
2. Add mission-specific propulsion and GNC contracts.
3. Add electrical and thermal domains with typed boundary ports.
4. Add communications and navigation contracts.
5. Confirm all cross-domain wires after compile; unknown ports after readiness are authoring failures.

### Gate E — operations and evidence

1. Add the first-class Scenario prim and Rhai source.
2. Implement event-driven phase orchestration.
3. Add API-driven verdict tests and negative fixtures.
4. Add a DEM/illumination pass only after the flat surrogate is stable.
5. Record exact build, source revision, runtime command, API port, test names, verdicts, and remaining assumptions.

## 10. Decision log for the next agent

- Keep `mission-001` as Blue Moon MK1 Endurance. It is a separate planning twin.
- Use `mission-002` for Griffin-1 and `source_mission_id: M02`.
- Keep exact landing coordinates and most physical parameters as `TBD` until sourced.
- Start with a surface study. Do not fabricate launch or transfer dynamics.
- Prefer a USD-authored FLIP asset and current LunCoSim generic mobility kernels over Griffin/FLIP-specific Rust code.
- Use one `LunCoProgramAPI` prim per continuous domain.
- Use the PortRegistry for all runtime input writes.
- Keep gravity in the environment, not duplicated in Modelica.
- Use Rhai for policy and sequencing, not PID/thrust/wheel control math.
- Treat compiled readiness and telemetry as separate gates.
- Do not call a visible placeholder a flight-ready or mission-faithful model.

## 11. References

### Mission sources

- [NASA Moon Base development phases](https://www.nasa.gov/moonbase-phases/)
- [NASA August 2026 cargo-lander update](https://www.nasa.gov/missions/moon-base/nasa-provides-updates-on-moon-base-cargo-landers-tech-demonstrations/)
- [NASA Moon Base II: Griffin-1](https://www.nasa.gov/event/clps-flight-astrobotics-griffin-mission-one/)
- [NASA CLPS landing sites](https://www.nasa.gov/commercial-lunar-payload-services/clps-landing-sites/)
- [Astrobotic Griffin-1 manifest](https://www.astrobotic.com/lunar-delivery/manifest/)
- [Astrobotic Griffin-1 environmental-test announcement](https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/)
- [Voyager/Astrobotic acquisition and Griffin update](https://www.astrobotic.com/voyager-awarded-298m-nasa-contract-under-completed-astrobotic-acquisition/)
- [Astrobotic Peregrine post-mission report](https://www.astrobotic.com/wp-content/uploads/2024/08/PM1_Post-Mission-Report_2.4_Web.pdf)

### LunCoSim sources

- [LunCoSim repository](https://github.com/LunCoSim/lunco-sim)
- [LunCoSim AGENTS.md](https://github.com/LunCoSim/lunco-sim/blob/main/AGENTS.md)
- [Spacecraft modeling architecture](https://github.com/LunCoSim/lunco-sim/blob/main/docs/architecture/33-spacecraft-modeling.md)
- [Scenarios and multi-domain vehicles](https://github.com/LunCoSim/lunco-sim/blob/main/docs/architecture/34-scenario-and-multidomain.md)
- [Compose multi-domain Twin guidance](https://github.com/LunCoSim/lunco-sim/blob/main/skills/compose-multidomain-twin/SKILL.md)
- [Author-scenario guidance](https://github.com/LunCoSim/lunco-sim/blob/main/skills/author-scenario/SKILL.md)
- [Run-Modelica/API guidance](https://github.com/LunCoSim/lunco-sim/blob/main/skills/run-modelica/SKILL.md)
- [Inspect-simulation/API guidance](https://github.com/LunCoSim/lunco-sim/blob/main/skills/inspect-simulation/SKILL.md)
