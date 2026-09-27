---
name: luncosim-twin-development
description: >
  Develop or verify simulation-ready Twins in this repository when work needs
  LunCoSim. Use to locate a compatible installed executable or source checkout,
  run the right Twin checks, and report runtime evidence accurately.
---

# LunCoSim Twin development

Use this repository-local guide alongside the owning Twin's instructions and
the [`interactive-component-authoring`](../interactive-component-authoring/SKILL.md)
skill. It is for finding and using LunCoSim and selecting sound runtime evidence;
it does not replace the Twin's component contracts or authoring workflow.

## Read the Twin contract first

Identify the Twin and scene named by the task under `twins/`. Read that Twin's
README, setup instructions, and the relevant contracts, requirements, and
implementation-gap notes before changing or validating it. For the Griffin-1 /
FLIP Twin, start with [`README.md`](../../twins/astrobotic-griffin-1/README.md),
[`instructions.md`](../../twins/astrobotic-griffin-1/instructions.md), and the
[`verification contract`](../../twins/astrobotic-griffin-1/contracts/verification.md).
Use the matching Twin-local documents if the task targets another Twin.

Keep each model fact in its owning source: SysML for requirements, configuration,
units, and design datums; USD for composed geometry and scene references; Rhai
for mission policy and Twin-specific observations; Modelica for continuous
subsystem equations. Put reusable simulation or authoring mechanisms in
LunCoSim's generic capabilities rather than adding Twin-specific engine logic.

## Find LunCoSim before reporting it missing

Do not assume the simulator is absent because it is not in the current folder or
on `PATH`. Search in this order, using read-only discovery first:

1. Check for a path or launch command supplied in the current task or session,
   then check command resolution (`command -v luncosim` on Unix-like shells or
   `Get-Command luncosim` in PowerShell).
2. Inspect the current project/workspace and relevant sibling development
   folders for an installed application or an executable named `luncosim` (or
   `luncosim.exe`). Use the host's application lookup (for example Spotlight
   metadata search on macOS or installed-app lookup on Windows) and a bounded
   filename search across accessible application and development roots. Do not
   assume a particular user's directory layout.
3. Look for a [LunCoSim source checkout](https://github.com/LunCoSim/lunco-sim)
   by its Cargo workspace and the `lunco-luncosim` package. Check whether it has
   a built `luncosim` executable. A binary in another checkout may be stale or
   may not contain the APIs this Twin needs, so identify its source revision
   when possible.
4. If no compatible local executable or checkout is found, check the official
   [LunCoSim releases](https://github.com/LunCoSim/lunco-sim/releases) for a
   package matching the host platform and architecture. Read that release's
   notes and compatibility information; distinguish stable releases from
   testing/nightly builds.

When a development checkout is the right match, build from that checkout's
root using its current instructions. The production simulator target is:

```sh
cargo build -p lunco-luncosim --bin luncosim
```

Prefer a build from the matching source checkout when validating current source
or diagnosing a runtime/API mismatch. Do not compensate for an old or unrelated
binary by changing Twin source. If LunCoSim cannot be found after these checks,
tell the user what kinds of locations and checkouts were searched, ask where
their install/source checkout is, or offer the official release download. Do not
report that LunCoSim is unavailable before completing discovery. Do not download
or install a release package until the user authorizes that step.

Do not hardcode a machine-specific executable or installation path in committed
Twin files or skills. Resolve the path for the current task and keep it local to
the command/session.

## Match the check to the claim

Before running commands, inspect the installed build's help and bundled
documentation/skills when available, then follow the owning Twin's current
instructions. Do not infer that a command or API exists based on a different
LunCoSim revision.

Use the narrowest check that answers the task. Report source parsing, structural
or requirement checks, headless simulation verdicts, and live visual inspection
as separate evidence. A successful parse or build does not prove runtime
behavior; a headless pass does not prove the scene looks correct. For a visual
claim, open the exact requested scene in the running app and inspect the relevant
view. Record the command, exit status, and actual verdict or observation.

If an error says a function or API is missing, first compare the executable's
revision/capabilities with the Twin's expected LunCoSim version and rebuild or
select a compatible release before treating it as a Twin defect. For detailed
Editor authoring, follow the component cycle in
[`interactive-component-authoring`](../interactive-component-authoring/SKILL.md).
