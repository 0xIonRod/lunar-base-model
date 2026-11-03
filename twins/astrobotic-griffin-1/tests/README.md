# Griffin verification fixtures and drivers

The `.usda` files are production scene-test fixtures. `twin.toml` maps positive
verification cases to these scenes and their observers in `scenarios/tests/`.
SysML owns acceptance criteria; Rhai observes the composed/runtime system and
emits typed verdicts; Modelica owns continuous physics.

`flip_motion.usda` checks forward/reverse motion, four-wheel render roll,
physical stops and stationary dwell against `FlipMotionRequirements::MotionStudy`.
It references the route scene and replaces its observer. Run the production gate:

```sh
"$LUNCOSIM_BIN" test --scene tests/flip_motion.usda --verification FlipMotionRequirements::Verify_FLIPMotion --max-ticks 2400 --api 4201
```

See [CAD FLIP acceptance](../contracts/flip-cad-runtime-2026-10-26.md) for the
active CAD rover. The [2026-10-23 receipt](../contracts/flip-runtime-2026-10-23.md)
records the earlier proxy rover only.

[Motion acceptance](../contracts/flip-motion-runtime.md) defines the current
test boundary. Qualify its negative case with an owned authoring session and
one free test port:

```sh
python3 tests/check_flip_motion.py --engine /path/to/lunco-sim --author-port 4291 --test-port 4294
```

This runs the positive case and a disposable document-authored fork that omits
the braking command. The fork must fail on `FLIP_MOTION_COMPLETE` with measured
stop diagnostics; a timeout, runtime fault or script error cannot qualify it.
The driver removes the fork and preserves the positive source. Use `--case`
to select one unchanged trial when reusing existing evidence.

The [Moon presentation](../docs/moon-presentation.md) gate uses a windowed
production session and the engine's existing API-test dependencies (including
Pillow for rendered-image inspection):

```sh
python3 tests/check_moon_presentation.py --engine /path/to/lunco-sim --port 4294
```

It requires ten authored runtime checks, rejects a temporarily clipped target,
restores the camera, and requires visible globe pixels plus a clean render log.
Only the disposable document view layer changes; the saved scene is preserved.
Evidence defaults under the engine workspace for screenshot access. The explicit
`--render-quality` option selects the tested preset and is recorded in evidence;
the driver never changes preset after a graphics failure.

The Python files here are external test drivers. They use an already-built
`LUNCOSIM_BIN`, create disposable fault fixtures through an owned simulator's
document API, and launch separate test processes. They do not run as Twin
behavior. Run them from the Twin root:

```sh
python3 tests/check_bus_failure_rejection.py --engine /path/to/lunco-sim --author-port 4291 --test-port 4294
python3 tests/check_power_failure_rejection.py --engine /path/to/lunco-sim --author-port 4291 --test-port 4294
python3 tests/check_skirt_failure_rejection.py --engine /path/to/lunco-sim --author-port 4291 --test-port 4294
```

The authoring port must belong to your own windowed session with this Twin
open; the test port must be free. Run the drivers serially. Ignored fault
layers use `_bus_failure_` and `_power_failure_` prefixes; local evidence is
stored under `.cache/`. The bus driver removes its disposable layers.
The skirt driver also removes its `_skirt_failure_qualification_` layers. It
requires the typed GES-002 finite-wall failure for a collapsed lower liner lip
and for an excessively thick lower lip with the upper lip unchanged. A timeout,
runtime fault, or unrelated failed check does not satisfy either case.

The landing-leg gate also executes the shared GLL-008 pad geometry, contact
ownership and station constraints, and GLL-009 body-mount constraint. SysML
`bodyChildNames` owns the exact integrated body inventory. To qualify rejection,
fork `griffin_landing_legs_requirements.usda` through the document API, add an
Xform below `/World/Griffin1/LegPX`, save the disposable layer under `tests/`,
and run the same `GRIFFIN_LANDING_LEG_REQUIREMENTS` verdict channel. Require
exactly `GLL-008-contact-ownership` to fail, all 188 other checks to pass and
zero errors; a readiness timeout is not rejection evidence. Remove the
trial after retaining its receipts. The 22 October qualification and source
hashes are recorded in `contracts/griffin-model-audit-2026-10-22.md`.
## CAD FLIP v5 acceptance

The operator route and motion fixtures now reference `vehicles/flip_v5.usda`.
Use `scenes/flip_cad_drive.usda` for interactive driving: it disables the test
observer and starts the avatar near the rover in the terrain frame.

`tests/flip_cad_capabilities.usda` runs
`scenarios/tests/flip_cad_capabilities.rhai`, verdict `FLIP_CAD_CAPABILITIES`.
It commands the native panel hinge through stow and deployment, observes solar
generation from the moving panel's environment probe, and requires finite
battery discharge under driving load. The 26-second gate has seven assertions.

See `contracts/flip-cad-runtime-2026-10-26.md` for the CAD acceptance evidence.
Older proxy requirements fixtures retain their original geometry assumptions.
