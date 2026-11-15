# Griffin-1 Twin setup and verification

The active study composes `vehicles/griffin_1.usda`, the CAD-based
`vehicles/flip_v5.usda`, the NOBILE03 terrain, and the landing and restrained
FLIP deployment controllers. The exit tracks are fixed. DEPLOY FLIP starts
balanced tether preload, adapter release, controlled descent and ground
transfer; DISCONNECT TETHERS releases unloaded lines before manual drive.
The numerical vehicle, rigging and actuator assumptions are not flight ratings.

## Match the runtime and assets

For a downloaded Twin, use the engine revision recorded in `QUALIFICATION.json`
and its complete matching shared assets. For repository sources, use the exact
revision in the repository's [`tools/qualification.toml`](../../tools/qualification.toml).
The runtime executable and `lunco://` component/Modelica library must come from
that same checkout. The qualification receipt covers headless execution, while
visual inspection remains a separate check.

An installed compatible application can open the extracted Twin directly.
For a source build, run in the matching engine checkout:

```sh
cargo build --locked -p lunco-luncosim --bin luncosim -j 4
cargo build --locked -p lunco-assets --bin lunco-assets -j 4
```

Use that checkout's `target/debug/luncosim` (`luncosim.exe` on Windows) as
`LUNCOSIM_BIN` for the commands below. The Twin folder is
`twins/astrobotic-griffin-1` in this model repository; supply its absolute path
when launching from the engine checkout. Keep the Twin's portable `twin://`
references intact.

## Prepare terrain

Release ZIPs contain `Assets.toml` and source provenance; they exclude generated
`.cache/` data. The application requests the dataset on first open and network
access is required until preparation finishes. The source-build asset-manager
commands and expected artifacts are in [terrain preparation](docs/terrain-assets.md).

The native recipe prepares a 2048 m square, 513 × 513-node NOBILE03 crop at the
source-declared regional study anchor. This is reproducible terrain registration,
not a confirmed mission touchdown coordinate. Downloads, processed terrain and
runtime state stay ignored.

## Open and operate

Open the folder containing `twin.toml` through **Open Twin**. It selects
`scenes/griffin_1_surface_ops.usda`. For an agent-owned source-build session,
select an explicit free API port and launch from the engine checkout:

```sh
"$LUNCOSIM_BIN" --scene /path/to/astrobotic-griffin-1/scenes/griffin_1_surface_ops.usda --api 4201
```

Wait for scene data, Modelica and physics readiness before operating. Confirm
that the lander, attached CAD FLIP rover, terrain and tracking camera are
present. Powered descent ends with qualified four-pad landing. Then:

1. Select **DEPLOY FLIP** and observe preload and restrained descent.
2. Wait for stable ground transfer and the unloaded-line indication.
3. Select **DISCONNECT TETHERS** and confirm that manual FLIP drive is enabled.
4. Use the HUD's configured drive, turn, brake and possession controls.

The interactive scene intentionally waits for these operator actions. Its
landing alone is not a complete mission-verification verdict. The
[system views](views/README.md) expose authored physical wiring and subsystem
boundaries. A runtime scripting interaction is distinct from an acausal link.

## Run acceptance

The mapped acceptance fixture composes the production scene and enables the
shared deployment controller's explicit verification mode. Run from the engine
checkout with a free test API port:

```sh
"$LUNCOSIM_BIN" test --scene /path/to/astrobotic-griffin-1/tests/griffin_tether_descent.usda --verification Griffin1Requirements::Verify_GriffinSurfaceOperations --max-ticks 14000 --tick-hz 60 --threads 1 --jitter 0 --api 4202
```

Require `GRIFFIN_TETHER_DESCENT` PASS and the native
`LUNCO_SCENE_TEST_REPORT` for that verification identity. Exit 0 means the
observer passed; exit 1 is a failed verdict; exit 2 means no verdict and fails
acceptance. Inspect the reported stage, native contacts, line loads, brake and
joint ownership when a run stops. A timeout cannot substitute for a verdict.
See the [test catalogue](tests/README.md) for focused cases.

For release qualification, build the binaries from the clean pinned checkout,
then run from this model repository:

```sh
python3 tools/validate_repository.py
python3 tools/qualification.py --engine /path/to/lunco-sim --provision --api-port 4299
```

The structural command checks native TOML structure and package-local manifest
references only. Qualification prepares declared datasets through the native
asset manager, validates the mounted Twin, its entire indexed SysML source set
and mapped scenes, and requires every release-case runtime verdict. It records
source and executable identities and rejects source changes during the run.
The workflow applies those gates to the staged archive contents before marking
a release latest. Generated terrain and session state are excluded from the ZIP.

## Update the engineering model

Keep requirements, configuration datums and provenance in the owning SysML
packages; executable topology and parameters in USD; continuous equations in
Modelica; and mission policy and observations in Rhai. Author USD changes through
the simulator's document tools, save explicitly, and inspect the saved result.

Replace assumptions with measured or supplier data at their owning source,
update affected component plans and tests, and record changed acceptance bounds
separately from physics changes. Flight-fidelity work still needs as-built CAD,
mass properties, propulsion and electrical interfaces, rigging and actuator
characteristics, the registered site and mission timeline. Keep unknown values
visible in the assumption register until evidence resolves them.
