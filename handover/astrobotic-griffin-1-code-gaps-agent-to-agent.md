# Agent-to-Agent Code Gap Report — Griffin-1 LunCoSim Integration

**Prepared:** 2026-08-29  
**Sender:** research/integration agent  
**Receiver:** next implementation and verification agent  
**Scope:** NASA-lunar-base-model plus current LunCoSim `main` architecture  
**Priority vocabulary:** P0 blocks a meaningful Twin; P1 blocks an integrated mission study; P2 limits fidelity or maintainability

## 1. Read this first

The NASA repository is not yet a runnable Griffin Twin. It contains research and one Blue Moon planning twin. The current LunCoSim codebase already contains most generic mechanisms required to compose a lander, rover, Modelica domains, and Rhai policy. The work should therefore begin with authored mission assets and tests, not with a new Griffin-specific Rust subsystem.

Current LunCoSim references used for this assessment:

- [repository README](https://github.com/LunCoSim/lunco-sim)
- [agent guide](https://github.com/LunCoSim/lunco-sim/blob/main/AGENTS.md)
- [spacecraft modeling architecture](https://github.com/LunCoSim/lunco-sim/blob/main/docs/architecture/33-spacecraft-modeling.md)
- [scenario and multi-domain architecture](https://github.com/LunCoSim/lunco-sim/blob/main/docs/architecture/34-scenario-and-multidomain.md)
- [compose-multidomain-twin guidance](https://github.com/LunCoSim/lunco-sim/blob/main/skills/compose-multidomain-twin/SKILL.md)
- [author-scenario guidance](https://github.com/LunCoSim/lunco-sim/blob/main/skills/author-scenario/SKILL.md)
- [inspect-simulation guidance](https://github.com/LunCoSim/lunco-sim/blob/main/skills/inspect-simulation/SKILL.md)

## 2. Baseline: what the current LunCoSim already provides

Treat these as available infrastructure unless a focused test against the exact checkout disproves them:

| Capability | Current baseline | Griffin implication |
|---|---|---|
| Production runtime | `luncosim` binary; old `sandbox` name retired | Build and run the current production entry point |
| Twin packaging | `twin.toml` with `[usd] default_scene` | Add a real Twin manifest |
| Scene composition | OpenUSD authored layers/references/payloads/variants | Compose lander, rovers, terrain, and domains in USD |
| Rigid-body physics | Avian-backed body, contact, force, and joint plumbing | Use generic body/contact infrastructure |
| Terrain | USD/terrain runtime path | Start with a local surrogate, later add DEM |
| Rover topology | USD-driven wheels and vehicle parameters | Author FLIP in USD; do not add a Rust FLIP struct |
| Joints | USD `Physics*Joint` to Avian Revolute/Prismatic/Fixed | Author deployment and landing-leg mechanisms |
| Compound bodies | Parent rigid body plus child collision API | Avoid accidental nested independent bodies |
| Cosim | `LunCoProgramAPI`, `info:sourceAsset`, native USD connections | Add one program prim per continuous domain |
| Forces | Body-frame force and torque ports are documented as shipped | Drive Griffin thrust and attitude torque through ports |
| Attitude | quaternion, yaw/pitch/roll, and angular-rate outputs | Close an attitude controller without re-derived pose math |
| Mass properties | load-time and live mass/inertia/COM ports | Model propellant burn and payload changes through one path |
| Actuator topology | Arbitrary wheel ports and explicit per-wheel bindings | Support non-parity wheel layouts if FLIP requires them |
| Prismatic actuation | displacement port and USD drive API | Deploy ramps, legs, latches, or arms through authored joints |
| Events | trigger zones, Modelica condition events, event source identity | Drive mission phase transitions from evidence |
| Rhai orchestration | first-class scenarios, sequencers, host verbs | Implement mission policy without engine changes |
| API | `/api/commands`, entity listing, port reads, cosim status, screenshots | Make every verdict inspectable |
| Headless path | `luncosim-server` guidance exists | Add numeric CI-style tests without relying on the GUI |
| Engine visual | throttle-driven plume shader path | Wire plume to a real throttle signal, not a Rhai animation |

## 3. P0 gaps — block the first executable Griffin Twin

### G-001 — No Griffin mission package in this repository

**Observed:** only `missions/mission-001/` exists as an executable mission package. Griffin appears as an M02 data-model example and in research catalogs.

**Needed:** add `missions/mission-002/` with `README.md`, `mission.yaml`, `mission-research.md`, and a scene or Twin reference.

**Acceptance:** mission ID, source mission ID, USD metadata, scenario IDs, and research sources agree; Mission 001 remains unchanged.

### G-002 — No `twin.toml`

**Observed:** the NASA repository has no Twin manifest. Current LunCoSim defines a Twin as a folder plus `twin.toml` with a default USD scene.

**Needed:** add the manifest in the actual LunCoSim Twin directory and make all referenced files relative to it.

**Acceptance:** opening the Twin loads the intended default scene without manual file selection.

### G-003 — Current `scene.usda` is not a LunCoSim multi-domain vehicle

**Observed:** Mission 001’s scene is simple USD geometry and a `PhysicsScene`; it does not author Griffin body schemas, program prims, Modelica source assets, or native cosim wires.

**Needed:** author the Griffin scene as a composed USD stage with Environment, Griffin, FLIP, CubeRover, payload scopes, and Scenario.

**Acceptance:** composed stage contains the intended topology and the production runtime discovers the required entities.

### G-004 — No authored Griffin/FLIP/CubeRover vehicle assets

**Observed:** no mission-specific USD files exist. The existing rover in Mission 001 is explicitly a simulator-only test asset and is not an Endurance payload.

**Needed:** create separate USD assets; reuse current generic rover mechanisms and examples as structural references.

**Acceptance:** each asset has authored geometry, rigid-body/collision topology, mass/inertia/COM policy, and stable IDs.

### G-005 — No terrain or polar illumination asset

**Observed:** `research/locations.md` intentionally leaves coordinates and DEM data unresolved. Mission 001 uses a flat square.

**Needed:** first create a documented cratered-polar surrogate; later import a real DEM, hazard map, illumination timeline, shadow map, and communications mask.

**Acceptance:** surrogate is clearly labeled; no screenshot is described as a geographic Nobile Crater reconstruction.

## 4. P1 gaps — block an integrated mission study

### G-006 — No Modelica propulsion model with Griffin evidence

**Observed:** current LunCoSim documents an existing generic `assets/models/RocketEngine.mo` and an annotated rocket-stage example. The NASA repository has no `.mo` files.

**Needed:** adapt the generic model only for plumbing first, then add explicit Griffin propulsion assumptions: propellant state, throttle, thrust, burn, engine enable, and failure/safe-mode behavior.

**Risk:** Griffin’s detailed engine count, propellant load, thrust curve, and control law are not all public. Do not label a generic rocket model as BE-7/Griffin validation.

**Acceptance:** model compiles, exposes declared ports, and thrust reaches the body through a native USD connection and the PortRegistry.

### G-007 — No GNC/attitude control domain

**Observed:** current LunCoSim supports body-frame force/torque and attitude/body-rate outputs, but no Griffin-specific GNC model exists in this repository.

**Needed:** author a Modelica GNC domain with explicit sensor inputs, landing/descent setpoints, throttle/torque outputs, and safe-mode gates.

**Acceptance:** a controlled descent test shows correct sign, stable attitude, and no duplicate gravity; controller outputs are observable in `cosim_status`/ports.

### G-008 — No electrical/power/thermal domains

**Observed:** no Griffin/FLIP battery, solar, load, thermal mass, radiator, or lunar-night model exists in the NASA repository.

**Needed:** add separate Electrical and Thermal program scopes with typed causal boundary signals. Keep acausal pins/heat ports inside their own domain model.

**Acceptance:** state of charge, generation/load, component temperature, and safe-mode thresholds are numeric and testable.

### G-009 — No communications model

**Observed:** mission research says communications remain unresolved; no communications domain or link mask exists.

**Needed:** create an explicit assumption model for direct-to-Earth visibility, relay dependency if used, bandwidth/latency, queueing, and blackout/recovery.

**Acceptance:** a scenario can disable the link, run a bounded autonomous action, restore the link, and verify queued telemetry.

### G-010 — No FLIP mobility parameter set

**Observed:** FLIP is identified in research, but dimensions, mass, wheel data, motor/gearbox, suspension, battery, and traverse limits are missing.

**Needed:** author a transparent surrogate parameter set and put every surrogate number in a parameter register with confidence. Use current LunCoSim USD-driven wheel schemas and explicit per-wheel bindings.

**Acceptance:** all required wheel attributes resolve; wheel drive is not inferred from parity; rover does not apply implausible lunar forces.

### G-011 — No deployment mechanism

**Observed:** no Griffin ramp, latch, leg, rover release, or CubeRover deployment topology exists.

**Needed:** author the mechanism with USD joints and drives. Current LunCoSim exposes prismatic `displacement` and revolute `angle` runtime surfaces and standard USD drive fields.

**Acceptance:** deployment state is established from joint/contact evidence and remains within authored limits.

### G-012 — No first-class Rhai mission orchestration

**Observed:** current project scenarios are YAML operational contracts for Mission 001, not LunCoSim Rhai assets.

**Needed:** author a `Scenario` prim with a referenced Rhai script and phase sequence: descent, touchdown, stabilization, commissioning, deployment, handover, survey, power/thermal, blackout, recovery.

**Acceptance:** production logic is event-driven; persistent state lives on `this`; control math is absent from Rhai.

### G-013 — No API evidence pack

**Observed:** no Griffin run record, entity snapshot, port snapshot, cosim result, screenshot, or scenario verdict is stored.

**Needed:** create a reproducible inspection/test procedure using API port 4101 and archive outputs with the source revision.

**Acceptance:** a new agent can reproduce the run and distinguish compile-pending, unknown-port, physics, and scenario-policy failures.

## 5. P2 gaps — improve fidelity and maintainability

### G-014 — No launch/ascent/cislunar transfer model

**Observed:** current LunCoSim README lists NASA GMAT integration as planned rather than a current runtime claim. Public Griffin trajectory/state data is not present here.

**Needed:** keep launch and transfer as a separate study boundary or integrate a verified orbital tool later.

**Acceptance:** the surface Twin does not imply that the launch phase was simulated.

### G-015 — No flight-quality regolith terramechanics

**Observed:** current LunCoSim provides generic wheel and rigid-body mechanisms; PINN-based terramechanics is documented as planned.

**Needed:** use current wheel/contact behavior for an engineering smoke test and identify the assumptions. Add high-fidelity regolith validation only with a supported model and data.

### G-016 — Validator is Mission-001-specific

**Observed:** `tools/validate_repository.py` hardcodes `mission-001` and expects exactly five root-level scenario YAML files.

**Needed:** generalize validation to enumerate mission packages and validate scenario references per mission.

**Acceptance:** adding Griffin does not require weakening existing checks or moving files solely to satisfy a count.

### G-017 — No negative fixtures

**Observed:** NASA repository has no LunCoSim scene/scenario negative fixtures.

**Needed:** add incomplete-wheel, missing-model, unknown-port, nested-body-without-joint, and incompatible-wire fixtures in the LunCoSim test layout.

**Acceptance:** each fixture fails for the intended reason and the test output is recorded.

### G-018 — No provenance bridge from mission YAML to USD/Modelica

**Observed:** research records and scene metadata are separate and currently not machine-checked against each other.

**Needed:** add stable IDs and source references to USD custom data and generated evidence; do not duplicate free-text mission identity.

**Acceptance:** mission, lander, rover, payload, and location IDs can be traced across YAML, USD, Modelica programs, Rhai actors, and telemetry.

## 6. Code changes versus authored-data changes

### Do not change Rust first

The current LunCoSim architecture explicitly says the reusable Rust substrate should provide generic physics, port, joint, wheel, and solver behavior. The following should initially be authored data:

- Griffin body and collision geometry;
- FLIP wheel/suspension topology;
- deployment joints;
- mass/inertia/COM values;
- Modelica source bindings;
- native USD cross-domain connections;
- payload scopes;
- Scenario and Rhai orchestration;
- test scenes and mission parameters.

### Rust changes are justified only if a focused test proves an infrastructure gap

A Rust change may be appropriate if the checked-out LunCoSim revision cannot do one of these generically:

- parse a required standard USD schema;
- project a valid authored port or joint;
- apply a supported body-frame force/torque;
- expose a required rigid-body or joint state port;
- resolve a valid per-wheel connection;
- execute a documented API command or scenario hook;
- produce a useful negative verdict.

If a Rust change is needed, update the owning crate, source schema/generator if relevant, tests, crate index, and architecture documentation together. Do not add a Griffin-specific fallback, alias, hard-coded vehicle name, or duplicate port vocabulary.

## 7. Known integration traps

1. **Old executable name:** use `luncosim`; do not use `sandbox`.
2. **Wrong input path:** write through the PortRegistry. Direct Modelica input writes can be clobbered on the next sync.
3. **Duplicate gravity:** environment owns gravity; do not apply it again in `.mo`.
4. **Wrong layer:** geometry and topology belong in USD; equations belong in Modelica; phase policy belongs in Rhai; generic mechanisms belong in Rust.
5. **Nested bodies:** a child moving part needs a rigid body and joint; internal geometry should stay a compound collider when it is not independently movable.
6. **Wheel assumptions:** current wheel readers require authored attributes and explicit connections; do not rely on old parity or hidden defaults.
7. **Acausal cross-domain wiring:** electrical and thermal connectors do not cross generated domain units; use causal boundary signals.
8. **Premature port failure:** a port can be absent while Modelica is still compiling. Check readiness before classifying it as an authoring failure.
9. **Rhai state:** helper functions cannot see top-level `let`; persistent state belongs on `this` in engine-called hooks.
10. **Rhai control loop:** do not implement PID, force mixing, or wheel physics in production `on_tick`.
11. **API identity:** `api_id` from `ListEntities` is not a Rhai global ID.
12. **Log scraping:** use port snapshots, `cosim_status`, and screenshots; do not infer authoritative state from logs.
13. **Headless path:** use the current server guidance for numeric tests; do not assume the UI binary with `--no-ui` is equivalent.
14. **Source uncertainty:** an old VIPER-era Griffin source is not automatically a current FLIP-era Griffin parameter source.

## 8. Recommended next-agent work queue

### First pass

1. Create `missions/mission-002/` and reconcile M02 YAML fields.
2. Add Griffin research/provenance record with the current mission status and explicit gaps.
3. Create a Twin manifest and minimal static USD scene.
4. Add simple Griffin, FLIP, CubeRover, payload, and environment scopes.
5. Load the static Twin and capture the first entity/screenshot evidence.

### Second pass

1. Add authored rigid-body/collider/mass properties.
2. Add FLIP wheel topology and a minimal deployment joint.
3. Add one minimal Modelica propulsion/GNC chain.
4. Verify body-frame thrust and gravity once, numerically.

### Third pass

1. Add power and thermal models.
2. Add communications blackout policy.
3. Add Rhai Scenario and phase verdicts.
4. Add negative fixtures and generalize the repository validator.

### Later

1. Replace terrain surrogate with a defensible DEM and illumination model.
2. Calibrate FLIP and Griffin parameters from authoritative sources.
3. Add transfer/orbital integration only with a verified tool and data contract.
4. Add higher-fidelity regolith/thermal/lunar-night behavior when supported by LunCoSim and evidence.

## 9. Handoff checklist

Before passing this work to another agent, report:

- NASA repository commit and LunCoSim commit/branch;
- exact Twin path and default scene;
- exact build command and exit code;
- exact runtime command and API port;
- `/api/ready` result;
- entity IDs and key port names;
- Modelica compile status and generated domain names;
- scenario names and verdicts;
- screenshots/telemetry artifact paths;
- assumptions used and their confidence;
- unresolved gaps from this document;
- any Rust changes and why authored USD/Modelica/Rhai could not solve the issue.

## 10. Final status

**Current status:** research-complete enough to begin a surface-study Twin; not ready for a mission-faithful or flight-dynamics claim.  
**Most important next action:** author and load the minimal Twin, then prove the USD → Modelica → PortRegistry → rigid-body chain with one controlled descent/touchdown test before adding terrain detail or a long operational scenario.
