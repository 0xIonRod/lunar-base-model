# Mounted FLIP control diagnosis — 28 October 2026

FLIP remained connected to Griffin by the active `PhysicsFixedJoint`
`/Griffin1SurfaceOps/FLIPPayloadAdapterJoint`. Native W input reached its
throttle input at 1.0; the attachment prevents independent rover translation.
F has different meanings: detach while controlling Griffin, route run/stop
while controlling FLIP. The former button label did not explain that context.

The mission brief now explains the attachment, ramp settlement and detach
sequence. Mounted rover input refreshes that explanation. The control helper
also reports attachment instead of announcing unrestricted manual driving.
The detach button keeps its possession-independent callback and drops the
ambiguous F suffix. Physics and release policy are unchanged.

Native window-input checks in `scenes/flip_cad_drive.usda` passed 25 assertions:
forward travel 3.7148 m, reverse travel 2.8198 m, all four wheel rates and render
bindings valid, upright within 25 degrees, and braking from 1.6307 to
0.00861 m/s. In the production mission, the mounted HUD was visually inspected
after native W input. Its detach callback queued the normal release event;
the adapter disappeared and readiness remained true. That release test ran
before touchdown in an isolated diagnostic session, which was restarted and
closed afterward.

Both changed Rhai sources pass native syntax validation; `git diff --check`
passes. The [evidence receipt](evidence/flip-mounted-controls-2026-10-28.json)
contains source hashes and native assertion output. Local screenshots and
diagnostic drivers are under `runs/flip-drive-debug-2026-10-28/`.

These checks qualify the control feedback, standalone drivetrain and release
callback. Full landing and loaded ramp traversal remain unqualified.
