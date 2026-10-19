# Griffin engine plume contract

Seven main engines have independent `PressureFedEngine` and `PlumePhotometry`
members fed by the shared live tanks. Each visual inherits the library's
render-only cylinder volumes, materials and local light. Main nozzle design
supplies radius, area, Mach, gamma and wall angle. All twelve attitude jets use
the same shared Modelica field function through `RCSJet`, with their physical
throat/exit/bell geometry from typed SysML. Render wall thickness is not a
physical throat dimension.

Modelica owns gas state, conservative station profiles, a passive optical energy
estimate and transported phase. USD owns static mounts, references and typed
connections. WGSL integrates optically thin emission and convected structure.
Rust uses its existing generic mechanisms. Authoring lives in
`griffin_visual_builder` and the library's `engine_exhaust`; no per-frame script
animates the effect. Engine-out and either feed-starvation path extinguish the
affected jet through its delivered state.

See `contracts/parts.md`, the `GriffinPlumeStudy` SysML part and the engine's
`docs/architecture/propulsion-plume.md` for equations, the observation horizon,
uncalibrated optical assumptions and validity limits. A numeric conservation
gate does not establish flight accuracy or visual acceptance. Use the owning
production engine-out/depletion gates, shared conservation/invalid-gas/feed
checks, directed main/RCS captures, pause checks and clean GPU diagnostics.

2026-10-19 acceptance: shared conservation 48, invalid gas 5, RCS feed 16,
shared lander activity 6, Griffin engine-out 20, fuel depletion 11 and oxidizer
depletion 11 checks passed in the production runtime. Directed main/RCS
on/partial/off and paused-phase captures had clean GPU validation logs.
The Desktop copy was synchronized through the USD document Save-As operation
and matching text assets, preserving its downloaded `.cache` data. With the
optimization checkout's own updated library (92 Modelica documents), its six
coupled participants initialized and both sampled main engines delivered
85.034 N during spool-up, with readiness true and no world hold or runtime
fault. This is startup/burn evidence, not a completed surface mission gate.
