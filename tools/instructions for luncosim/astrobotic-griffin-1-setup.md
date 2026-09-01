# LunCoSim Setup Instructions — Astrobotic Griffin-1 / Moon Base II

**Audience:** an engineer or agent implementing the Griffin-1 mission Twin  
**Last verified against public LunCoSim main-branch guidance:** 2026-08-29  
**Mission data source:** NASA and Astrobotic/Voyager public updates  
**Implementation level:** surface mission study first; flight dynamics only when supported by evidence

## 0. What you are building

Build a LunCoSim Twin for Griffin-1, the Astrobotic/Voyager infrastructure-class lunar lander planned for NASA’s Moon Base program. The first useful deliverable is a reproducible South-Pole surface operations study containing:

- a Griffin lander;
- Astrolab’s FLIP rover;
- Astrobotic’s CubeRover/BEACON demonstration;
- a temporary Nobile-region terrain surrogate;
- authored rigid-body and mobility topology;
- Modelica domains for the continuous systems that are actually modeled;
- Rhai mission phase policy;
- API-observable telemetry and test verdicts.

NASA currently reports Griffin-1 in environmental testing at JPL and targeting late 2026. Astrobotic/Voyager’s July 2026 update says no earlier than November 2026. See [NASA](https://www.nasa.gov/missions/moon-base/nasa-provides-updates-on-moon-base-cargo-landers-tech-demonstrations/) and [Astrobotic/Voyager](https://www.astrobotic.com/voyager-awarded-298m-nasa-contract-under-completed-astrobotic-acquisition/).

This guide does not authorize inventing the landing ellipse, DEM, mass properties, trajectory, or detailed rover specifications.

## 1. Read the two source repositories

Use the NASA mission repository as the mission-data source and the latest LunCoSim `main` branch as the runtime/authoring source:

```powershell
cd C:\Users\salek\OneDrive\Desktop
git clone https://github.com/LunCoSim/lunco-sim.git
cd .\lunco-sim
git pull --ff-only
```

The current LunCoSim README instructs users to build `lunco-luncosim` and run the production `luncosim` binary. The former `sandbox` executable name is retired. Read:

- [LunCoSim README](https://github.com/LunCoSim/lunco-sim)
- [LunCoSim AGENTS.md](https://github.com/LunCoSim/lunco-sim/blob/main/AGENTS.md)
- [Compose multi-domain Twin guidance](https://github.com/LunCoSim/lunco-sim/blob/main/skills/compose-multidomain-twin/SKILL.md)
- [Spacecraft modeling architecture](https://github.com/LunCoSim/lunco-sim/blob/main/docs/architecture/33-spacecraft-modeling.md)
- [Scenario and multi-domain architecture](https://github.com/LunCoSim/lunco-sim/blob/main/docs/architecture/34-scenario-and-multidomain.md)

Do not start implementation from a historical Godot-only workflow or an old `sandbox` command.

## 2. Build the current production simulator

From the LunCoSim repository:

```powershell
cargo build -p lunco-luncosim --bin luncosim
```

For an interactive inspection session, use one explicit API port:

```powershell
target\debug\luncosim.exe --api 4101
```

For headless numeric validation, use the current headless server path described in the repository’s Modelica guidance rather than assuming `luncosim --no-ui` is GPU-free:

```text
cargo run -p lunco-luncosim-server -- --api 4101
```

Use the exact binary name present in the checked-out current workspace if the package layout has changed. Do not overlap two sessions on port 4101. Networking is opt-in; do not enable it for a local mission test unless the scenario explicitly needs multiplayer.

## 3. Create a Twin folder

Create a new Twin directory. Do not replace Mission 001 in the NASA repository.

```text
astrobotic_griffin_1/
├── twin.toml
├── scene.usda
├── assets/
├── models/
├── scenarios/
└── tests/
```

Create `twin.toml`:

```toml
name = "astrobotic-griffin-1"
version = "0.1.0"
description = "Griffin-1 / Moon Base II surface mission study"

[usd]
default_scene = "scene.usda"
```

The Twin owns its scene, referenced vehicle assets, Modelica files, and Rhai scripts. The NASA repository should keep provenance and planning contracts separately under `missions/mission-002/`.

## 4. Create the mission contract

Add `missions/mission-002/mission.yaml` by following the existing project schema in [`missions/mission-001/mission.yaml`](../../missions/mission-001/mission.yaml), not by silently replacing Mission 001.

Recommended identity and status:

```yaml
schema_version: 1
mission_id: mission-002
source_mission_id: M02
name: Griffin Mission One
status: planned
mission_class: infrastructure_class_lunar_lander
operator: Voyager Lunar Systems / Astrobotic
target_year: 2026
target_window: no earlier than November 2026
landing_site:
  name: Nobile Crater
  region: lunar South Pole
  coordinates: TBD
```

Keep these as explicit unknowns until sourced:

```yaml
launch_site: TBD
launch_vehicle: TBD
transit_profile: TBD
orbit_before_descent: TBD
landing_ellipse: TBD
lander_dry_mass_kg: null
lander_inertia: null
flip_mass_kg: null
flip_battery_capacity_kwh: null
communications: TBD
```

If a provider or current mission source later confirms a value, record the source URL and date beside the value. Do not turn an old VIPER-era value into a Griffin-1 current value.

## 5. Author a minimal static USD scene

Start with a flat 1 km × 1 km local test tile. It is a surrogate for a cratered polar region, not a geographic reconstruction of Nobile Crater.

Required scene hierarchy:

```text
Mission002
├── Environment
│   ├── Terrain
│   └── Illumination
├── LandingPad
├── Griffin
├── FLIP
├── CubeRover
├── Payloads
└── Scenario
```

Author these scene facts explicitly:

```usda
#usda 1.0
(
    defaultPrim = "Mission002"
    upAxis = "Y"
    metersPerUnit = 1
)

def Xform "Mission002"
{
    def PhysicsScene "PhysicsScene"
    {
        vector3f physics:gravityDirection = (0, -1, 0)
        float physics:gravityMagnitude = 1.62
    }
}
```

The exact current LunCoSim environment projection should remain the authority for runtime gravity. Do not add a second lunar gravity force in Modelica.

## 6. Author Griffin as a USD vehicle

Create a real authored Griffin asset rather than adding a Griffin-specific Rust type. The current LunCoSim architecture says vehicle structure and wiring belong in USD, while Rust supplies generic solver behavior.

Minimum Griffin authoring:

- root `Xform` with `PhysicsRigidBodyAPI`;
- body and landing-pad collision geometry;
- `physics:mass`, `physics:diagonalInertia`, and `physics:centerOfMass` where known;
- four or more landing-leg assemblies only when the geometry and joint assumptions are documented;
- landing-leg joints and limits;
- authored body-frame force and torque consumer ports;
- payload mounting scopes and IDs;
- program scopes for continuous domains.

The current LunCoSim baseline already exposes body-frame `force_local_*`, `torque_*`, attitude, angular rate, mass, inertia, and center-of-mass port support. Use those existing ports; do not add parallel Rust mechanisms. See [spacecraft modeling architecture](https://github.com/LunCoSim/lunco-sim/blob/main/docs/architecture/33-spacecraft-modeling.md).

## 7. Author FLIP and CubeRover from USD

FLIP is the principal rover. CubeRover is the smaller Astrobotic/BEACON demonstration. Both must be authored as USD vehicle assets.

For FLIP, author or mark `TBD` for:

- wheel count and placement;
- wheel radius, width, mass, and moment of inertia;
- chassis mass/inertia/COM;
- motor and gearbox torque/speed/efficiency;
- suspension joints, travel, stiffness, and damping;
- tire longitudinal stiffness, friction, and rolling drag;
- per-wheel drive/steer/brake ports;
- solar-panel placement and battery boundary ports;
- thermal mounting and radiator assumptions.

Current LunCoSim supports explicit per-wheel drive connections and arbitrary actuator port topology. A six-wheel rover is authored in USD; it is not hard-coded in Rust. Every wheel must have the required attributes and explicit drive binding. See the wheel and actuator sections of [spacecraft modeling architecture](https://github.com/LunCoSim/lunco-sim/blob/main/docs/architecture/33-spacecraft-modeling.md).

For a first smoke test, use a transparent engineering assumption set and label it in USD custom data and the mission research file. Do not describe that asset as the flight FLIP vehicle.

## 8. Add payload scopes

Add payload metadata under `Payloads` and under the relevant vehicle. The current public Griffin manifest includes FLIP, BEACON/CubeRover, LandCam-X, LRA, Moon Pi, MoonBox, and a time capsule. NASA’s current architecture identifies five NASA investigations: LDES, Lunar LiDAR, two LRAs, and METAL.

Start payload scopes with IDs and purposes:

```usda
def Scope "LDES"
{
    custom string payload:id = "payload-ldes"
    custom string payload:purpose = "Measure lunar dust accumulation"
}

def Scope "LunarLiDAR"
{
    custom string payload:id = "payload-lidar"
    custom string payload:purpose = "Demonstrate local 3D mapping and navigation"
}
```

Metadata is not the same as an operational payload model. Add electrical, thermal, mass, sensor, or navigation ports only when the behavior is actually implemented and testable.

## 9. Add one program prim per continuous domain

Create separate `LunCoProgramAPI` scopes under Griffin and FLIP for the domains you implement:

```text
Griffin/Propulsion
Griffin/GNC
Griffin/Electrical
Griffin/Thermal
Griffin/Communications
FLIP/Electrical
FLIP/Thermal
FLIP/Mobility
```

Each program should:

1. name its own `.mo` source via `info:sourceAsset`;
2. expose typed ports;
3. connect consumer inputs using native USD `inputs:x.connect` connections;
4. avoid duplicate solver instances on a single physical entity;
5. keep acausal electrical/thermal connectors inside their own domain;
6. expose only causal scalar boundary signals between domains.

Candidate initial models:

| Domain | First model | Required outputs/inputs |
|---|---|---|
| Propulsion | generic rocket-engine adaptation, later Griffin-specific | throttle, thrust, propellant mass, engine state |
| GNC | descent/attitude controller | altitude, descent rate, attitude, rates, thrust/torque commands |
| Electrical | battery and solar generation | generation, load, current, voltage, state of charge |
| Thermal | lumped masses and radiator boundary | component temperatures, heat flow, safe-mode threshold |
| Communications | link availability and queue policy | link state, latency/bandwidth assumption, queued telemetry |
| Mobility | existing USD wheel/drive substrate | wheel commands, speed, contact, energy load |

Control math belongs in Modelica or the maintained engine kernels. Rhai must not become a per-tick PID or force mixer.

## 10. Wire the domains correctly

Use the current SSP-style pattern:

```usda
def Xform "Griffin" (prepend apiSchemas = ["PhysicsRigidBodyAPI"])
{
    float inputs:force_local_y.connect = </Mission002/Griffin/GNC.outputs:thrust>

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

Before trusting a connection:

- compile or wait for the generated domain contract;
- inspect the resolved port names;
- reject an unknown port after the domain is ready;
- do not add dummy USD attributes to hide a missing declaration;
- do not write directly to `ModelicaModel.inputs`;
- use `SetPorts`, `set_input`, or Rhai `set(id, "port", value)` through the PortRegistry.

## 11. Author the Scenario prim and Rhai policy

Add one first-class Scenario scope:

```usda
def Scope "Scenario" (kind = "component")
{
    custom string lunco:scenario = "griffin-1-surface-ops"

    def Scope "Mission" (prepend apiSchemas = ["LunCoProgramAPI"])
    {
        uniform asset info:sourceAsset = @scenarios/griffin_1_surface_ops.rhai@
    }
}
```

Use event-driven phases:

```text
descent → touchdown → stabilize → commission → deploy_flip
→ activate_cuberover → survey → power_thermal_test
→ communications_blackout → recovery → safe_park
```

In Rhai:

- put persistent state on `this` inside `on_start`, `on_event`, or test-only `on_tick`;
- use `query`, `get`, `set`, `cmd`, `nav_to`, `drive`, and `brake` through the host surface;
- use built-in vector and angle helpers;
- wait on altitude, contact, joint displacement, state of charge, distance, temperature, or named events;
- do not sleep-loop or poll continuously in a production scenario;
- do not put thrust, PID, wheel mixing, or torque math in Rhai;
- remember that events are delivered on the next tick and scripts are host-authoritative.

Read [author-scenario guidance](https://github.com/LunCoSim/lunco-sim/blob/main/skills/author-scenario/SKILL.md) before writing the production script.

## 12. Add the mission test matrix

Create focused scene and scenario tests:

| Test | Purpose | Pass evidence |
|---|---|---|
| `griffin_static_load` | scene composition and static stability | entities loaded; body rests on pad |
| `griffin_touchdown` | contact and post-touchdown state | contact/leg ports and velocity settle |
| `griffin_thrust_direction` | body-frame force convention | measured acceleration matches expected sign |
| `griffin_mass_props` | authored/runtime mass state | mass, inertia, COM read back through ports |
| `flip_wheel_topology` | USD-driven rover creation | all authored wheels and drive ports resolve |
| `flip_deployment` | prismatic/revolute deployment | joint state reaches target without limit violation |
| `surface_survey` | navigation and observation policy | waypoint, distance, and telemetry verdict |
| `power_thermal_reserve` | low-light operation | reserve and temperature thresholds hold |
| `communications_recovery` | blackout behavior | queued telemetry arrives after link restoration |
| `negative_missing_wheel_attribute` | fail-closed authoring | load/test rejects incomplete wheel |
| `negative_unknown_port` | fail-closed cosim wiring | test reports terminal unknown-port error |
| `negative_nested_body_no_joint` | body topology lint | test rejects accidental nested body |

Use numeric API results for assertions. Use screenshots only to confirm physical appearance such as tipping, separation, or plume direction.

## 13. Run and inspect

The current API envelope is:

```text
POST http://127.0.0.1:4101/api/commands
Content-Type: application/json
```

Read-only inspection sequence:

```powershell
curl.exe -s -X POST http://127.0.0.1:4101/api/commands `
  -H "Content-Type: application/json" `
  -d '{"type":"ListEntities"}'
```

Then identify `api_id` values and issue narrow port reads. Conceptually:

```powershell
curl.exe -s -X POST http://127.0.0.1:4101/api/commands `
  -H "Content-Type: application/json" `
  -d '{"type":"ExecuteCommand","command":"ReadPorts","params":{"name_filter":"Griffin","ports":["position_y","velocity_y","mass"]}}'
```

Use `cosim_status` or `SnapshotVariables` to inspect Modelica state and `CaptureScreenshot` to visually verify the scene. Do not tail logs to infer a live port value. See [inspect-simulation guidance](https://github.com/LunCoSim/lunco-sim/blob/main/skills/inspect-simulation/SKILL.md).

Run a scenario only after the Twin is ready and the scenario contract has compiled. A missing port before Modelica readiness is an assembly-progress condition; a missing port after readiness is an authoring failure.

## 14. Validation gates

From the NASA repository root, run the project’s structural validator:

```powershell
python .\tools\validate_repository.py
```

That validator currently knows only about Mission 001 and five root-level scenarios. Before claiming a complete Griffin integration, extend it to:

- discover `missions/*/mission.yaml` and matching `scene.usda` files;
- validate per-mission scenario directories;
- check that every referenced artifact exists;
- check mission IDs agree between YAML, USD metadata, and scenario files;
- preserve the obsolete-reference check;
- validate source URLs and `last_verified` dates where possible.

In the LunCoSim checkout, run the focused USD/Modelica/scenario tests first, then the production luncosim or headless server path. Record exact commands, exit codes, API readiness, scenario verdicts, and the LunCoSim revision.

## 15. Completion definition

The Griffin-1 Twin is ready for handoff when:

- it opens from `twin.toml` with no missing references;
- Griffin, FLIP, CubeRover, payload scopes, and Environment are discoverable entities;
- body/collider/joint topology is authored and validated;
- all required wheel attributes and drive connections resolve;
- each implemented domain compiles and publishes its declared ports;
- cross-domain wires are visible and stable through the PortRegistry;
- the scenario advances through touchdown, deployment, mobility, power/thermal, and communications phases;
- at least one negative fixture fails for the intended reason;
- numeric telemetry and screenshots are archived;
- unknown mission facts remain explicitly marked instead of being presented as flight data.

## 16. Stop conditions

Stop and document a blocker if:

- the needed LunCoSim schema or API is absent from the checked-out revision;
- an exact vehicle parameter is required for a claim but no authoritative source exists;
- the generated Modelica contract does not publish the expected port after readiness;
- a USD asset requires a Rust-specific vehicle implementation instead of existing generic infrastructure;
- terrain or communications behavior is being presented as validated without data;
- the only evidence is a screenshot or a process that started without an API readiness check.
