# Griffin-1 model requirements and acceptance

Reviewed: 2026-10-19. Scope: the Griffin-1 / FLIP Twin under
[`twins/astrobotic-griffin-1`](../twins/astrobotic-griffin-1/README.md).

The normative requirement identities, values, sources and verification cases
live in the Twin's SysML packages. This page is their human-readable index;
it does not maintain a second geometry or parameter catalogue. A structural
PASS establishes only the checks actually executed. Unavailable observations
remain inconclusive, and planned checks remain open.

## Source and configuration baseline

- Astrobotic's [current Griffin product page](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
  publishes seven main engines, four landing legs, a 625 kg payload capacity,
  an isogrid payload deck, and optional rover ramps. These are product facts,
  not a complete Griffin-1 mechanical or propulsion ICD.
- Astrobotic's [June 15, 2026 integration photographs](https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/)
  inform exterior appearance. Current array appearance supersedes older
  concept images. Three arrays are represented on the forward face and both
  forward chamfers to preserve the study rover's opposite X-side exits;
  this station assignment, contour reconstruction and metric scale remain
  study estimates. Clean-room stands and temporary covers are excluded.
- The [August 2021 Payload User Guide](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf)
  supplies historical tank and antenna context. Its older five-engine
  configuration does not override the current product count.
- FLIP uses one four-wheel skid-steer assembly in both review and dynamics.
  Its dimensions and mass properties remain a reference-informed study.
  The current fixed array represents the public collapsible-array concept;
  deployed flight hardware and electrical qualification are unresolved.
- The LROC NOBILE03 terrain is real source data. Crop, normalization, checksum
  and study anchor belong to `Assets.toml` and the terrain processing record.
  The study anchor and epoch are not a published touchdown coordinate or date.

The [typed source catalogue](../twins/astrobotic-griffin-1/requirements/griffin_requirement_sources.sysml)
links requirement usages to public evidence, project decisions or study
assumptions. [Size evidence](../twins/astrobotic-griffin-1/requirements/griffin-size-evidence.md)
and the [assumptions record](../twins/astrobotic-griffin-1/research/griffin_1_assumptions.md)
state confidence and unresolved flight data.

## Owning requirements

All paths below are relative to the Twin's `requirements/` directory.

| Domain | Normative source | Required result |
|---|---|---|
| Integration and mission | `griffin_requirements.sysml`, `griffin_functional_requirements.sysml` | Reusable lander, payload capacity boundary, descent attachment, observed release, physical egress and surface-route handoff. |
| Lander configuration | `griffin_lander_requirements.sysml`, `griffin_visual_configuration.sysml`, `griffin_vehicle_assembly.sysml` | One named assembly; four corner legs, four tank study assemblies, seven engine bells and three array assemblies at typed stations. Instance names are identities, not directions. |
| Bus and deck | `griffin_bus_requirements.sysml`, `griffin_mechanical_requirements.sysml` | Faceted octagonal frame and blanket exterior; separate payload deck and perimeter support; explicit hidden load-bearing colliders. |
| Landing gear | `griffin_landing_legs_requirements.sysml` | Four seated leg mechanisms with enabled pads, correct joints, finite study parameters and observable native contacts. |
| Propulsion and tanks | `griffin_propulsion_requirements.sysml`, `griffin_tank_requirements.sysml` | Per-engine thrust/propellant ownership, seven non-colliding bells, four render-only tank assemblies and explicit source/assumption boundaries. |
| Solar | `griffin_solar_requirements.sysml` | Three tall frame/cell assemblies, supported mounts, source-owned outlines and clear rover corridors. Flight dimensions and electrical performance remain unresolved. |
| Optional ramps | `griffin_ramp_requirements.sysml` | Two articulated three-section assemblies, paired wheel tracks, connected hinges, transport latches, terrain seating and clearance. Command bounds and joint poses come from SysML. |
| FLIP | `flip_requirements.sysml` and component packages | Four shared wheel stations, chassis, mast, suspension and power/thermal interfaces in one review/dynamics assembly. |
| Presentation | `griffin_visual_requirements.sysml` | Repeatable metre/Y-up camera, recognizable shape, distinct blanket/metal/cell finishes, render-only detail, and a same-revision verdict, composed query and captured frame. |
| Simulation accuracy | `griffin_simulation_accuracy_requirements.sysml` | Landing target/terrain agreement, full joint-island guidance mass, fixed-clock repeatability, and sampled post-touchdown stability. |
| Assurance | `griffin_assurance_requirements.sysml` | Typed provenance, one owner per parameter, explicit study status, fail-closed checks and reviewable evidence. |

Visible materials use shared foil and UsdPreviewSurface implementations.
Shader color, roughness, metallic and wrinkle controls are appearance estimates;
they do not establish thermal emittance, absorptance, alloy, layup or blanket
construction. Visual detail must retain physical collision and mass ownership.

## Verification and delivery

`twin.toml` is the single registry for component and SysML verification cases.
Run the installed production binary from the selected simulator checkout with
its matching shared assets. Set `LUNCOSIM_BIN` to that executable; do not infer
compatibility from another branch's old evidence.

```sh
bash twins/astrobotic-griffin-1/tools/verify_requirement_sources.sh
"$LUNCOSIM_BIN" test-component \
  --twin "$PWD/twins/astrobotic-griffin-1" --component griffin.bus \
  --max-ticks 120 --tick-hz 60 --threads 1 --jitter 0
```

Repeat the registered component gates for the affected owners. Run dynamic
landing, engine, ramp, release and rover cases against their actual runtime
fixtures; source parsing or visual checks cannot replace those verdicts.
Capture the source revision, simulator build/asset owner, execution settings,
verdict counts and evidence paths. Full SysML reference resolution requires the
mounted Twin source set; parsing an isolated file is insufficient.

Inspect the actual rendered static review and live mission. Measure settled
frame-time and physics costs at a recorded viewport, camera, quality and
workload using standard PBR materials; an unlit fast profile does not qualify
the requested realistic presentation. Report concurrent workloads and missing
performance evidence. The current model has no sourced flight-performance
qualification or measured hardware material calibration.

[`contracts/verification.md`](../twins/astrobotic-griffin-1/contracts/verification.md)
records the executable boundary; the
[implementation gaps](../twins/astrobotic-griffin-1/contracts/implementation_gaps.md)
retain open acceptance work. Do not turn a planned or inconclusive requirement
into PASS by deleting it or loosening its bounds.
