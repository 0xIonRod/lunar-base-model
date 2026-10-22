# Griffin verification fixtures and drivers

The `.usda` files are production scene-test fixtures. `twin.toml` maps positive
verification cases to these scenes and their observers in `scenarios/tests/`.
SysML owns acceptance criteria; Rhai observes the composed/runtime system and
emits typed verdicts; Modelica owns continuous physics.

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
