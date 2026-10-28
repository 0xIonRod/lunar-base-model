# Griffin photographic presentation — 27 October 2026

This pass improves the reusable Griffin presentation for model inspection and
operations studies. It retains the June 2026 integration reconstruction, the
current CAD FLIP payload, the existing physical contact model and the explicit
uncertainty on flight dimensions. It does not establish flight fidelity or
complete mission acceptance.

## Reference and appearance

The inspected primary image is NASA's [Griffin-1 in the clean room](https://www.nasa.gov/image-detail/26-06-15-griffin-1-pressconference-1348-edit/),
photographed on 15 June 2026. It shows silver-gray lower insulation and metallic
landing gear, dished footpads, service wiring and the stepped photovoltaic bank.
The photo is qualitative evidence; lighting and reflections do not identify
measured optical coefficients, alloy properties, wiring ICDs or calibrated scale.

The user's instruction to make the model as realistic as possible supersedes
the earlier gold presentation preference. Source-owned bus/tank insulation
palettes now use silver-gray rather than gold. The existing object-space foil
shader supplies folds and reflections without bitmap textures or extra foil
tessellation. Retention hardware, aluminum supports, valves, piston surfaces,
joint hardware and pads use separate standard USD material finishes.

## Changes and ownership

- `components/lander/griffin_tank_visual.usda` owns its insulation and fitting
  materials. The vehicle's four stronger shell bindings were removed so the
  referenced component supplies the finish.
- `components/lander/griffin_landing_leg_visual.usda` adds one closed, smooth
  domed pad cover and separate metal finishes. Its radius and seating datum
  derive from the existing leg requirements. The estimated dome profile is
  owned by `GriffinPresentationStudy::HardwareFinish`. It stays above the
  original pad-bottom contact plane and inside the existing radial envelope.
  Stationary bus-mount copies hide the cover, leaving one on each moving leg.
- `components/lander/griffin_bus_visual.usda` adds 16 routed bundle segments,
  eight clamps, six connectors and six pigtails. Routes follow existing rail
  and avionics stations. They are estimated service detail, not a functioning
  electrical or pressure network. The open bays and tank clearances remain.
- The engine-bay material retains its shared blanket reference and receives
  explicit source-owned instance parameters. The exposed payload adapter uses
  the aluminum finish rather than its former brown display color.
- `requirements/griffin_visual_configuration.sysml` remains the canonical
  insulation palette. `requirements/griffin_presentation_study.sysml` owns the
  new fitting finishes and display-detail proportions. The landing-leg inventory
  explicitly includes `FootPadCover`.
- The pure `griffin_tank_finish`, `griffin_leg_finish` and `griffin_bus_detail`
  Rhai tools produce generation-checked typed Editor operations and readback
  checks. USD was saved through the Editor; no USDA text was hand-edited.

All new service geometry and pad covers are render-only and non-colliding.
They introduce no bodies, joints, force owners, physical mass or thermal
coefficients. Existing cylinders and derived contact geometry remain authoritative.
These finishes describe renderer appearance, not flight absorptivity/emissivity.

## Verification and limits

Fresh existing regressions pass: tank **536/536**, landing legs **189/189**,
bus **254/254**, and lander **122/122**: **1,101 checks** in total.
An initial runner used the plural leg channel; its corrected
run exits successfully on `GRIFFIN_LANDING_LEG_REQUIREMENTS`. The bus appearance
source and geometry were reconciled before its final passing run. The initial
receipts remain alongside the final results.

Focused Editor readback gates pass: ten tank dimension/binding checks, six leg
dimension/render-role checks and sixteen service-bundle geometry/render-role
checks. The component document lint checks report no errors or warnings.
Assembly Editor lint also reports runtime-port availability errors in the
non-running physics preview; component lint and these static checks do not
qualify flight runtime wiring.

Full operations acceptance remains open. The latest recorded unattended CAD
mission failed landing before release and traversal; the later mounted-rover
orientation correction has not received a complete successful mission replay.
This presentation pass does not change guidance, thrust, propellant, mass,
inertia, terrain, landing gates or physics tolerances to hide that failure.

The simulator used here is `8bad5b08b08357412218087ae20be03e80c4db55`, with the
existing local integration fixes. Detailed typed-command journals, screenshots,
native gate results and fresh-process regression logs are retained under
`runs/griffin-realism-2026-10-27/`. Source hashes and compact results are recorded
in the [companion evidence receipt](evidence/griffin-visual-realism-2026-10-27.json).
The [assembled Editor view](../handover/griffin-realism-2026-10-27.png) records
the saved presentation. A [model-only native capture](../handover/griffin-realism-model-2026-10-27.png)
shows the same preview without surrounding application panels. The Editor
session remains open for inspection.
