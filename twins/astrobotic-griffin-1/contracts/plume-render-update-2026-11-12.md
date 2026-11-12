# Plume rendering interface - 2026-11-12

Each of Griffin's seven main engines and twelve RCS nozzles now uses one shared
`Flame` volume. The broad and hot-core optical components share the physical
field, clipping and ray integration. Geometry, actuators, plumbing, wall thermal
state and flight controls retain their previous owners.

Deploy this Twin with the coordinated LunCoSim asset revision: the single-volume
`rocket_engine_visual.usda`, `engine_exhaust.rhai`, `plume.wesl`, `plume_field.wesl`,
`blackbody_radiance.wesl` and matching propulsion Modelica outputs. The former
`FlameCore` and `core_envelope_radius_m` interface has been retired. A Rust
rebuild by itself cannot update an independently installed asset library.

Presentation constants belong to `Shader.inputs:*`. `core_fraction` partitions
one radiative estimate, `core_width` sets its downstream optical core, and the
inner/outer colour pairs preserve their separate tints. `steps=128` caps the
whole ray. All nineteen Shader seeds are authored per emitter and verified
against the runtime material ports; GPU instance allocation is not an identity.
The shared field retains filled nozzle exits, bounded area-preserving axial
motion, passive attenuating detail and the Modelica simulation clock.

The physical station model and optical efficiencies remain reduced study
assumptions, not calibrated Griffin plume measurements. The nozzle's blackbody
approximation changes only how the computed wall temperature reaches the GPU;
shutdown and cooling remain Modelica-owned. Geometry and camera/timeline data
in the tracked film compositions are unchanged.

Native validation includes the 104-check propulsion requirement gate, engine-out
and both reactant-exhaustion gates, nineteen
seed readbacks, powered close/underside/cluster views, opaque depth clipping,
GPU mathematical controls and sample-budget convergence. Shared implementation,
commands, hardware, limitations and full evidence are documented in LunCoSim's
`docs/reviews/plume-render-update-2026-11-12.md`; runtime artifacts are under
`.cache/perf/plume-update/` in the simulator checkout.

Use the matching shared asset root when launching. An already-running simulator
continues to use its own selected library; this source update does not replace
or restart unrelated running app sessions.
