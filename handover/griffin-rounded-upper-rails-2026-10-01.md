# Rounded upper rail strips

Continued the rail reconstruction after checkpoints 6bb0355 and 664db08.
Upper strips now use rounded plate ends within the existing 1.799084054 m
length, 40 mm height and 6 mm transverse thickness. End radius derives from
half the strip height (20 mm). Native profile extrusion is reused from the
pivot-plate helper, with a quarter-turn into the ramp longitudinal frame.
No new geometry framework was added.

The source/rationale lives in GriffinEgressRamp and GRR-008. References:
- https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander
- https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png

The renderings suggest compact rounded tips but do not resolve an exact
manufacturing outline. The semicircular profile is an explicit low-confidence
visual estimate, not supplier geometry or a qualified structural design.

Persistent USD changes used owned Editor API49746. First guide plan: 165
operations, then fresh document115606782820979/generation0 confirmed Mesh,
vertex-derived extent +/- (.020,.899542,.003), placement (.899542,.18,1.293)
and -90 degree local Z rotation. Subsequent small applies scoped only the
upper strip. The shared component owns all four strips; toe and vehicle
instances inherit it. Temporary instance copies were removed through typed
Editor operations before acceptance. No additional body or visual proxy was
introduced. The same mesh is rendered and cooked as a convex-hull guard
collider. Corner contact geometry changes with the rounded profile; rail
centres, envelopes, hinge axes and dynamics settings retain their source values.

Updated existing observers to read mesh extents and orientation instead of
Cube scale. Final geometry gate PASS (1277 checks, tick11, .18s), flight-stow
gate PASS (228 checks, tick6, .10s). Both use terrain a7707995, 60Hz, one thread,
zero jitter. Source revision11624680991050655375. Logs:
/tmp/griffin-rounded-upper-gate.log
/tmp/griffin-rounded-upper-stow-final.log
Typed provenance PASS: 207 targets/records, 47 source elements, 3 roles.
Rhai compilation and git diff --check passed.

Final fresh vehicle preview115607656925833/view3/generation0, projection
ready. Port middle guide readback confirms inherited Mesh, source extent and
placement, collisionEnabled=true and convexHull approximation. Focused folded
assembly screenshot: griffin-rounded-upper-rails-2026-10-01.png. This owned
Editor remains running as exec57072, API49746, private terrain binary
/tmp/griffin-terrain-a770-luncosim, isolated config, High quality. Previous
owned Editor59176 ended137; cause is unestablished. The fresh vehicle-only
preview now frames correctly; this does not establish that every scene
preview framing issue is fixed.

Full mission replay prior to this strip change failed at middle unfolding;
see griffin-structured-replay-running-2026-10-01.md. Component geometry and
stow passes are not accepted powered deployment, release or rover egress.
