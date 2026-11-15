# NASA Lunar Base Model

This model is built for LunCoSim, the simulator that opens and runs it.
LunCoSim must be installed to use the model. The project folder that you open
in LunCoSim is called a Twin.

The current model contains the Astrobotic Griffin-1 lunar lander and FLIP
rover. It does not yet simulate a lunar base. This is a study model, not a
flight-qualified vehicle or mission.

## Install and open the Twin

### 1. Install LunCoSim

Use the engine revision identified by the Twin release's `QUALIFICATION.json`,
including its matching shared assets. An arbitrary latest application may have
a different component interface. Obtain a compatible
[LunCoSim release](https://github.com/LunCoSim/lunco-sim/releases), or
[build that exact source revision](https://github.com/LunCoSim/lunco-sim/blob/main/docs/apps/README.md#build-from-source).
For repository sources, the release contract is [tools/qualification.toml](tools/qualification.toml).

### 2. Get the Griffin-1 / FLIP model files

**Recommended: download the Twin ZIP.**

[Download the latest Griffin Twin ZIP](https://github.com/0xIonRod/lunar-base-model/releases/latest/download/astrobotic-griffin-1.zip)
([SHA-256 checksum](https://github.com/0xIonRod/lunar-base-model/releases/latest/download/astrobotic-griffin-1.zip.sha256)).
Extract the ZIP. The folder you will open is `astrobotic-griffin-1`.

**Alternatively: clone or download the source repository.**

Clone with Git:

```sh
git clone https://github.com/0xIonRod/lunar-base-model.git
```

Or [download the repository ZIP](https://github.com/0xIonRod/lunar-base-model/archive/refs/heads/main.zip)
and extract it. The folder you will open is
`lunar-base-model/twins/astrobotic-griffin-1`.

### 3. Open the model in LunCoSim

Start LunCoSim. On its welcome screen, click **Open Twin**. Browse to the
folder from step 2 that contains `twin.toml`, select that folder, and confirm.
If LunCoSim is already open, choose **File → Open Folder/Twin…** and select
the same folder. LunCoSim opens the Twin's default Griffin/FLIP scene.

On first opening the Twin, LunCoSim downloads missing assets such as terrain.
An internet connection is required.

The default scene is `scenes/griffin_1_surface_ops.usda`. For controls and
mission details, see the [Twin instructions](twins/astrobotic-griffin-1/instructions.md)
and [Twin overview](twins/astrobotic-griffin-1/README.md).

## Downloadable builds

A push to `main` stages the Twin, builds the pinned engine and shared asset
revision, prepares its declared terrain, and requires native preflight plus
the registered release gates before publishing a ZIP and SHA-256 checksum.
The archive records the Twin source commit and includes `QUALIFICATION.json`
with the tested engine revision, binary hashes and individual runtime reports.
Headless qualification does not establish visual acceptance.

The application and generated terrain cache are not included. The first open
prepares missing terrain from `Assets.toml` and requires internet access.
The download links point to the latest main revision that passed qualification.

For local checks, build `luncosim` and `lunco-assets` from the clean pinned
engine checkout, then run:

```sh
python3 tools/validate_repository.py
python3 tools/qualification.py --engine /path/to/lunco-sim --provision --api-port 4299
```

The first command checks manifest structure and package-local references only.
The second requires native Twin/SysML/scene preflight and bounded production
verdicts. It rejects a mismatched or dirty engine and leaves evidence under
`runs/qualification/`. It never builds, edits USD, or publishes a release.
