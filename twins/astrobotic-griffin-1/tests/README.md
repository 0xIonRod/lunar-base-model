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
```

The authoring port must belong to your own windowed session with this Twin
open; the test port must be free. Run the drivers serially. Ignored fault
layers use `_bus_failure_` and `_power_failure_` prefixes; local evidence is
stored under `.cache/`. The bus driver removes its disposable layers.
