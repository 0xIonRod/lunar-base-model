# Griffin main-engine plume handover

## Implemented

The seven Griffin main-engine visuals now have fixed-capacity outer-flame and
hot-core cones plus a local sphere light. Their throttle, visible length, light
intensity, and source radius come from the standard `LunCo.Propulsion.PlumePhotometry`
Modelica model. The model consumes the MainChamber activity, thrust, maximum
thrust, propellant flow, exhaust velocities, and chamber pressure. Nozzle exit
radius and area come from `LunCo.Propulsion.BellNozzle`.

The Griffin cluster publishes aggregate chamber quantities. `engine_count = 7`
normalizes thrust and flow to one of seven equal nozzles before calculating
per-nozzle plume pressure and light. The visual cones and light start at zero;
Rhai does not animate or calculate plume state. Vehicle-specific flame materials
are bound by the composed Griffin vehicle, keeping absolute vehicle paths out of
the reusable bell component.

The component's bell exit plane is at local `Y = +0.26 m`. The cone envelope is
positioned so its wide nozzle end meets that plane and its narrow end extends
down the exhaust axis. Its fixed capacity is 4 m; the Modelica output controls
the shader's visible length fraction.

SysML requirement GPP-008 covers plume count, live photometry inputs, every
nozzle's simulation connections and material bindings, and render-only plume
geometry. The Griffin propulsion verifier observes the composed Twin under
`/World/Griffin1` and records that constraint. The visual bell/throat contract
remains GPP-002, so the plume behavior has a separate requirement owner.

Reusable authoring guidance was updated in `terrain/`:

- `docs/architecture/50-usd-driven-visuals.md`
- `skills/visualize-physics-with-shaders/SKILL.md`

## Modeling assumptions and open checks

- The shared propulsion model represents equal nozzle sharing. Per-engine
  shutdown or engine-out operation is not modeled.
- Design exit pressure and design chamber pressure remain zero because there is
  no established Griffin value in the Twin. Ambient pressure is zero for the
  lunar vacuum study. The 1,000 Pa visibility threshold, four-metre shader
  envelope, flame shape, and light color are presentation assumptions.
- The exit-plane datum, plume direction, material bindings after reference
  composition, live signal propagation, zero-thrust darkness, and perceived
  brightness still need a visual/runtime check in Editor. No scene, scenario,
  or Twin simulation was run for this handover.
- The zero-thrust requirement is expressed in SysML, and the Modelica and shader
  equations gate outputs at zero thrust/throttle. The new GPP-008 observer checks
  composed structure and wiring; it does not sample a running burn.

## Commits

- Twin implementation and contract: `eeb51bc` (`Drive Griffin engine plumes
  from simulation`) on the local `main` branch of `lunar-base-model`.
- Generic Modelica behavior and authoring guidance: `779f96e20` (`Model clustered
  engine plume photometry`) on the `terrain-streaming` branch of LunCoSim's
  `terrain/` worktree.
- At the original handover time, neither implementation commit had been pushed.
  As of 2026-09-29, both are ancestors of their repositories' `origin/main`
  tips: Twin `c10b4e6` and LunCoSim `d855f4307`. This follow-up verification
  handover is separate from both implementation commits.

## Next agent

Open the Griffin surface-operations Twin in Editor and inspect the composed
`/World/Griffin1` engine cluster. Verify the seven light and material bindings,
the bell-to-plume join and exhaust direction, zero output while idle, and
simulation-driven plume and ground illumination while the main engine is
commanded. Adjust only against visible evidence and source-backed design values.
The `terrain/` worktree also had separately staged SolarPanel typed-parameter
changes; those are unrelated to the plume work and were excluded from it.
