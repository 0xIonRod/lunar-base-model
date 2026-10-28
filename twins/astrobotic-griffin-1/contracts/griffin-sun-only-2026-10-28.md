# Sun-only correction and release failure — 28 October 2026

**Later architecture correction:** the [compact FLIP egress reconstruction](griffin-compact-egress-2026-10-28.md)
supersedes the folding-ramp/free-release configuration tested below. The overload
receipt belongs to commit `35d21c7`; the new layout holds the payload attached
until tether dynamics are qualified. That hold is not a gearbox repair.

The user rejected the presentation fill and additional hardware shaders.
`griffin_1_surface_ops.usda` now exactly matches its pre-fill source. The hidden
DomeLight was also removed from the separate shader-review scene. The HDR,
generator, experimental role materials and their authoring tool were removed.
Ramp pins/bearings reuse their existing materials; solar hinges and mount stock
reuse PanelFrame. The earlier geometry improvements remain. No brighter Sun,
emission, exposure compensation or replacement lighting was introduced.

Native document operations and explicit saves own all USD changes. The
restoration plan is `tools/griffin_standard_lighting.rhai`. The saved mission
was inspected in a fresh window, with zero runtime diagnostics at the visual
checkpoint; see `handover/griffin-sun-only-2026-10-28.png`. This visual checkpoint
does not qualify later drivetrain operation.

## Detach error remains open

The current v5 mission reproduces a terminal Modelica failure immediately after
payload release, before route torque is commanded:

> GearRatio output torque exceeds its rating; model overload or slip explicitly

The production mission failed at tick 3593 / 59.88 s with seed
`6840157149251759617`. A replay using the current-vehicle release fixture and
the same seed failed at tick 3594 / 59.90 s. Release occurred at approximately
59.75 s. Accepted motor demand was zero; left-wheel back-driving and gearbox
losses rose sharply. A bounded diagnostic trace captured left-wheel angular
velocity rising from approximately 0.05 to 8.2 and then -23.4 rad/s within
three ticks. This is a reproduced release transient, not a confirmed diagnosis
of its underlying force/coupling cause. Torque protection remains enabled.

`tests/griffin_flip_v5_payload_release.usda` was created through SaveAs from the
current mission and adds only the existing release observer. The production
payload-release verification registry now uses it. The older fixture references
the previous FLIP proxy and is unsuitable for accepting current v5 operation.
The default-seed v5 case passes all 10 release checks (8.254 m travel, four
supporting wheel contacts, 27 joints and 27 graph edges, no pending detach).
The failing-seed replay shows that this single pass is insufficient acceptance.

An attempted standard native-contact material binding was rejected and fully
reverted because that realization does not expose the tire-heat port consumed
by the existing thermal assembly. No contact-model, motor, gearbox, brake,
mass, inertia, geometry or joint changes remain from that experiment. No
fake heat values or higher gearbox rating were substituted. Temporary trace
instrumentation was removed from the existing observer.

Reproduce with a compatible local simulator and the Twin's terrain cache:

```sh
luncosim test --scene twins/astrobotic-griffin-1/tests/griffin_flip_v5_payload_release.usda --verdict-channel GRIFFIN_PAYLOAD_RELEASE --seed 6840157149251759617 --max-ticks 18000 --threads 0
```

Repository structural validation, changed Rhai/SysML syntax validation, and
`git diff --check` pass. Local API receipts, full failure values and trial logs
are under `runs/griffin-sun-only-2026-10-28/`.
