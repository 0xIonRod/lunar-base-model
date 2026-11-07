# NASA Lunar Base Model

The current runnable model is the Astrobotic Griffin-1 lander and FLIP rover
Twin; it does not yet simulate a lunar base. This is a study model, not a
flight-qualified vehicle or mission.

## Install and open the Twin

### 1. Install LunCoSim

Download and install [LunCoSim for your operating system](https://github.com/LunCoSim/lunco-sim/releases),
or [build LunCoSim from source](https://github.com/LunCoSim/lunco-sim/blob/main/docs/apps/README.md#build-from-source).
Keep LunCoSim installed; the Twin uses its runtime and shared assets.

### 2. Get the Griffin-1 / FLIP Twin

**Recommended: download the Twin ZIP.**

[Download the latest Griffin Twin ZIP](https://github.com/0xIonRod/lunar-base-model/releases/latest/download/astrobotic-griffin-1.zip)
([SHA-256 checksum](https://github.com/0xIonRod/lunar-base-model/releases/latest/download/astrobotic-griffin-1.zip.sha256)).
Extract the ZIP, then open the extracted `astrobotic-griffin-1` folder in
LunCoSim as a Twin.

**Alternatively: clone or download the source repository.**

Clone with Git:

```sh
git clone https://github.com/0xIonRod/lunar-base-model.git
```

Or [download the repository ZIP](https://github.com/0xIonRod/lunar-base-model/archive/refs/heads/main.zip).
In LunCoSim, open `twins/astrobotic-griffin-1` from the extracted or cloned
repository as a Twin.

On first opening the Twin, LunCoSim downloads missing assets such as terrain.
An internet connection is required.

The default scene is `scenes/griffin_1_surface_ops.usda`. For controls and
mission details, see the [Twin instructions](twins/astrobotic-griffin-1/instructions.md)
and [Twin overview](twins/astrobotic-griffin-1/README.md).

## Downloadable builds

A push to `main` packages the Twin files and publishes a ZIP and SHA-256
checksum to GitHub Releases. After the first successful main build, the
download links above point to the newest successful main build. Each archive
records its source commit. The LunCoSim application is not included.
