# NASA Lunar Base Foundation Overview

**Audit date:** 2026-09-01
**Repository:** `NASA-lunar-base-model`
**Purpose:** Foundation inventory for the MoonDAO NASA Lunar Base technical
workflow. This document records what is present, where it is owned, how it is
run, and which claims remain study assumptions.

## Executive status

The repository has a usable planning and integration foundation, but it is not
a flight-validated lunar-base model. The durable project layer contains two
mission records, research registers, five operational scenario contracts, a
tracked Griffin-1 Twin package, and structural validation tooling. A local
LunCoSim checkout supplies the maintained runtime, generic USD vehicle assets,
Modelica models, terrain support, and authored scenario/test workflows.

The current engineering boundary is a **surface-operations study**:

- real mission identity and public facts are kept in the NASA repository;
- vehicle, terrain, and power values without authoritative as-built data are
  explicitly labelled as simulator assumptions;
- OpenUSD owns scene structure and connections;
- Modelica owns continuous subsystem equations;
- Rhai/behavior assets own mission policy and sequencing;
- LunCoSim Rust crates provide generic physics, composition, API, and runtime
  mechanisms.

The repository validator passed on this audit:

```text
OK: repository structure, mission twin, scenarios, and obsolete-reference checks passed
```

The validator was run with the configured bundled Python runtime. The plain
`python` command is not available on this Windows host.

## Repository and checkout boundary

| Layer | Current evidence | Interpretation |
|---|---|---|
| NASA model repository | `c17ab06320e48aa0f336406a2fca6904cdb408da` on `codex/astrobotic-griffin-1-twin` | Contains the durable mission/research/Twin package. |
| Local LunCoSim checkout | `luncosim-griffin-1/`, branch `codex/astrobotic-griffin-1-twin`, HEAD `e9c8a55872916066ed39832c654027aa3d141d06` | Separate nested Git worktree with existing user changes and runtime logs; it is not a clean release baseline and is not part of the parent repository commit. |
| Existing local CAD work | `freecad/`, `griffin_1_lander.FCStd`, and related backup files | User-owned untracked work. It is evidence of authoring activity, not a committed runtime dependency. |

The nested checkout and CAD files must remain outside commits for this audit
unless their owner explicitly stages them in a later task.

## Foundation inventory

| Area | NASA repository assets | LunCoSim foundation | Current status and limit |
|---|---|---|---|
| Mission identity and provenance | `missions/mission-001/mission.yaml`, `missions/mission-002/mission.yaml`, the two mission research records, and `research/` registers | Twin manifests and source-asset metadata under `assets/` and `twins/` | Mission identity is represented. Public mission facts must not be treated as vehicle qualification data. |
| Terrain and polar site | `missions/mission-001/scene.usda`; Mission 002 records a 1 km × 1 km `procedural_flat_site`; `twins/astrobotic-griffin-1/environments/south_pole_surrogate.usda` and `lunar_surface_base.usda` | `assets/scenes/base/lunar_surface.usda`, `assets/scenes/terrain_only.usda`, `assets/components/terrain/rocker_bogie_articulation_course.usda`, `assets/manifests/terrain.toml`, `crates/lunco-terrain-core/`, and `crates/lunco-terrain-bake/` | A deterministic flat collision surrogate and visual berms are available. There is no validated Nobile Crater DEM, hazard map, illumination timeline, or communications mask. |
| Sun and illumination | `scenarios/03_power_and_illumination.yaml` plus the Griffin Twin's explicit scene lighting | `assets/lighting/sun.usda`, `assets/models/LunCo/Pointing/SunTracker.mo`, and `assets/scenarios/tests/sun_tracker.rhai` | Sun/light and tracker mechanisms exist for study workflows. Site-specific power claims require a real frame, epoch, and illumination data. |
| Rovers | `research/flip_rover.md`, `research/vehicles.md`, `twins/astrobotic-griffin-1/vehicles/flip.usda`, and the M01 simulator rover in `missions/mission-001/scene.usda` | `assets/vessels/rovers/rocker_bogie.usda`, `six_wheel_rover.usda`, `six_wheel_independent.usda`, `ackermann_rover.usda`, `assets/components/mobility/`, and the rover behavior/test assets | Generic USD-driven mobility and explicit actuator topology are available. The active Griffin FLIP asset is a four-wheel all-wheel-steer study proxy, not an as-built FLIP model. |
| Griffin lander | `missions/mission-002/`, `twins/astrobotic-griffin-1/vehicles/griffin_1.usda`, the Twin scene, behavior, and scenario assets | `assets/vessels/landers/descent_lander.usda`, `assets/models/Lander.mo`, GNC models, and the maintained USD/Modelica runtime | A reusable generic descent lander is wrapped with Griffin identity and study geometry. Public Griffin mass properties, propulsion details, landing coordinates, and flight state vectors remain unknown. |
| Habitats and base structures | `twins/astrobotic-griffin-1/environments/lunar_surface_base.usda`, mission/scenario contracts, and base context in `NASA_LUNAR_BASE_OVERVIEW.md` | `assets/structures/habitat_fsh.usda`, `assets/structures/solar_tower.usda`, and the base scene assets | Base structure primitives exist for composition and visualization. There is not yet a complete, source-backed, interactive base layout with validated power, thermal, or logistics behavior. |
| Power and electrical components | `scenarios/03_power_and_illumination.yaml`, Griffin mission assumptions, and Twin metadata | `assets/components/power/battery.usda`, `power_bus.usda`, `solar_panel.usda`, `ideal_voltage_source.usda`, `assets/models/LunCo/Electrical/SolarPanel.mo`, and related Modelica tests | Generic battery/solar/power building blocks exist. Mission-specific capacity, generation, load, degradation, and lunar-night budgets are not flight data. |
| Communications | `scenarios/04_communications_blackout.yaml`, `research/assumptions.md`, and mission records | `assets/components/comms/transmitter_power.usda`, communications scenarios/tests, and the API/telemetry surfaces | Blackout and recovery can be represented as an operations study. A validated relay geometry, bandwidth, latency, and link mask are not yet present. |
| Payloads and ISRU context | `research/vehicles.md`, `research/missions.md`, `missions/mission-002/mission.yaml`, and `scenarios/05_cargo_inspection.yaml` | USD scopes and generic component/telemetry mechanisms | Payload identity and purposes are documented; detailed payload mass, power, thermal, and instrument behavior remains out of scope until sourced. |

## Current implementation workflow

The NASA repository is the mission-data and provenance layer. The tracked
Griffin package is under `twins/astrobotic-griffin-1/` and currently contains:

```text
twin.toml
scenes/griffin_1_surface_ops.usda
vehicles/griffin_1.usda
vehicles/flip.usda
vehicles/flip.legacy-six-wheel.usda
environments/south_pole_surrogate.usda
environments/lunar_surface_base.usda
behaviors/griffin_1_flip_patrol.btxml
scenarios/griffin_1_surface_ops.rhai
research/griffin_1_assumptions.md
```

The maintained LunCoSim workflow is:

1. Build the production `luncosim` binary from the LunCoSim checkout:

   ```powershell
   cargo build -p lunco-luncosim --bin luncosim
   ```

2. Use one explicit API port for an interactive session, normally `4101`:

   ```powershell
   target\debug\luncosim.exe --api 4101
   ```

3. Validate authored files before runtime claims. The Griffin setup guide
   uses `luncosim.exe --validate` against its USD and Rhai inputs.

4. Run the production scene-test path for numeric verdicts, for example:

   ```powershell
   target\debug\luncosim.exe test --scene twins\astrobotic-griffin-1\scenes\griffin_1_surface_ops.usda --max-ticks 14400 --tick-hz 60 --verdict-channel GRIFFIN_SURFACE_OPS
   ```

5. Inspect readiness, entities, ports, co-simulation status, and screenshots
   through the API. Logs are diagnostic only and are not authoritative
   telemetry.

The old `sandbox` executable name is retired. The current architecture keeps
continuous equations in Modelica, structure and typed wiring in USD, and
event-driven mission policy in Rhai/behavior assets. Rhai must not become a
per-tick PID, force mixer, or wheel-physics implementation.

The NASA-side equivalents are documented in:

- `tools/instructions for luncosim/README.md`
- `tools/instructions for luncosim/astrobotic-griffin-1-setup.md`
- `tools/validate_repository.py`
- `twins/astrobotic-griffin-1/README.md`
- `twins/astrobotic-griffin-1/instructions.md`
- `twins/astrobotic-griffin-1/handover.md`

## Existing evidence and known gaps

The current Griffin handover records a staged baseline for the generic
attached lander/rover study and a later re-qualification boundary after ramp
and release changes. It explicitly says that the final post-change route test
still needs a new PASS. That evidence must not be represented as a completed
flight or mission validation result.

The repository also has a known validator boundary: `tools/validate_repository.py`
requires Mission 001 and exactly five root-level scenario files. It passes for
the current tree, but it does not yet enumerate every mission package or
validate scenario references per mission. Generalizing that validator belongs
to a focused follow-up task rather than silently weakening the existing checks.

The main foundation gaps are:

1. Replace the procedural surface surrogate with a registered, source-backed
   terrain/illumination package before making geographic or power claims.
2. Keep Griffin and FLIP parameters marked as public, estimated, assumed, or
   unknown until an authoritative interface-control or supplier source exists.
3. Compose the base assets into a reusable layered scene with explicit
   terrain, habitats, rovers, power, communications, landing-pad, and ISRU
   layers.
4. Re-qualify the active Griffin landing, ramp, physical-release, and rover
   route chain on a clean pinned LunCoSim checkout, separately recording
   deterministic and diagnostic runs.
5. Update stale handover text that still describes the Griffin package as
   absent; the package now exists in the tracked NASA repository.

## Kickoff post draft

The repository-side foundation audit is complete. The NASA Lunar Base model
now has separate Mission 001 and Griffin-1/Mission 002 records, a tracked
Griffin surface-study Twin, reusable research and scenario contracts, and a
documented path from USD scene composition through LunCoSim, Modelica, and
Rhai/API inspection. The current terrain and vehicle values are transparent
study assumptions, not flight validation. The next technical step is to
compose the reusable layered base scene and then re-qualify the Griffin/FLIP
surface route on a clean pinned LunCoSim checkout.

Project links:

- Repository: `NASA-lunar-base-model`
- Foundation overview: `FOUNDATION_OVERVIEW.md`
- Griffin Twin: `twins/astrobotic-griffin-1/`
- Runbook: `tools/instructions for luncosim/astrobotic-griffin-1-setup.md`
