# Griffin / FLIP V12 native production assets

These are authored scenes, scenario programs and native runtime UI used for the V12 film. Video editing, narration and the delivery manifest live in lunco-marketing under `campaigns/lunar-missions/griffin_flip_v12/`. Captures, downloaded datasets and executable binaries are local outputs, not Git assets.

V12 reuses the retained V8 environment, idle scenario and single runtime UI manifest. The V8 files here are authored inputs, not the deleted V8 recordings. Downloadable terrain and lunar imagery are declared in the Twin's `Assets.toml`; local NOBILE03 relief is not a globally bound lunar elevation map.

Accepted recordings use `drive_05`, `routes_04`, `solar_01` / `solar_02`, `sun_03`, `moon_day_02` and `moon_zoom_05`. Earlier takes and probes are retained for diagnosis and are not accepted evidence by themselves. The film's source manifest identifies the selected footage and measurements.

The `egress-*` scenes and `egress_trial_*` programs are experiments. `GriffinTetherModels.EgressPair` passed isolated conservation checks but the coupled rover descent failed safe-attitude acceptance. Do not present it as a validated deployment or flight tether design. The review film uses the separately approved, credited Astrolab ground test instead.

Validation at checkpoint: Twin TOML and native UI dependencies pass. Modelica, SysML and base-scenario parser checks pass. The bare-file USD preflight cannot resolve the mounted `twin://` composition in this CLI invocation, and production Rhai lint flags per-frame `on_tick` film controllers. Full preflight is therefore not claimed as passed. Previously recorded live evidence applies only to the selected film sources; it does not qualify the rejected tether experiment.
