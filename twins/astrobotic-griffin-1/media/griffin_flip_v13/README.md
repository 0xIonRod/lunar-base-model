# Griffin / FLIP V13 film scenes

Film-only scenes reference the canonical Griffin/FLIP Twin and shared simulator assets. No vehicle geometry is copied here. Ten active scenes: broll, landing, drop-low, drop-high, drive, solar, routes, sun, moon-zoom and moon-day.

The matching `headful_*_capture.rhai` scripts control native headful capture. Drive, solar, routes and moon-day receive an explicit `ctx.output_path`; other auto-recording scenes require a fresh authored output path. Loading a recording scene starts a take. Do not load one casually for inspection or overwrite an accepted destination.

`drive_policy_validated_profile.rhai`, `solar_policy_validated_profile.rhai` and `routes_policy_validated_profile.rhai` own the film's tested operations. The route pair uses independent physical copies, inactive P3 route stubs, a common Sun-facing final approach and an equal observation window. Forward/reverse approach selection avoids an unnecessary half-turn. Final capture passed all 24 native acceptance checks with the same 0.45 m endpoint tolerance. No pose teleport or fabricated energy values are used.

Capture uses native fixed simulation steps: two 60 Hz ticks per 30 fps image, or ten for the route comparison, whose speed is labelled in the film. The lunar-day ground and body-fixed orbital camera use the native celestial clock. Moon zoom uses native scroll input and continuous orbit-to-surface handoff. Local NOBILE03 height/albedo and a cached 8k globe image remain distinct assets.

These are educational mission-model examples, not flight-qualified Griffin/FLIP predictions. Native tether egress remains unqualified; the approved credited manufacturer Earth test is used in the edit. The marketing episode owns narration, editing, graphics and final capture receipts. Rejected experimental sources elsewhere in this local directory are not part of this committed production set.
