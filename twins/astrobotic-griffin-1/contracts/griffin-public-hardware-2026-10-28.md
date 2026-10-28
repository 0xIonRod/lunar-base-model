# Public-reference Griffin exterior upgrade

The [research record](../../../research/griffin_public_hardware_2026-10-28.md)
separates current imagery, historical documentation and presentation assumptions.
The 2021 guide provides subsystem context; June–August 2026 NASA imagery informs
the visible hardware treatment. No historical VIPER configuration or laboratory
test fixtures were added to the operational vehicle.

## Changes

- The forward, port and starboard solar components receive 16, 12 and 12 raised
  edge lips respectively. Each lip derives from one existing stock segment in
  the frame mesh, preserving its notches and solar-cell geometry.
- The reusable leg receives three upper-strut sleeves with two cuffs each:
  nine visual cylinders. Sleeve positions follow the original cylinder axes.
  Their common foil material references the existing bus insulation material.
- The installed vehicle uses a separate stationary shock barrel and moving
  piston. Four actual barrel tubes receive twelve additional wrap/cuff shapes;
  the moving piston remains exposed and its existing travel is unchanged.
  The original hidden component piston was not made visible.
- Four exterior service looms follow the feet of existing bus rail stations.
  Sixteen jacket segments and eight end fittings make 24 visual shapes. Routes
  and sag are estimates, not released cable routing or functioning connections.

The authoring gate checks 85 authored shapes: 40 lips, 9 reusable leg shapes,
12 installed barrel shapes and 24 service-loop shapes. Repeated reference
instances are not counted as separate authored shapes. Every new shape has
render purpose and MaterialBindingAPI, no rigid-body/collision API, and disabled
collision. Existing source mesh points, physical dimensions, mass, joints and
contact proxies were not rewritten. All six affected USD files are additive
relative to the saved baseline taken at the start of this pass.

`GriffinPresentationStudy::PublicHardwareDetail` owns the estimated dimensions.
`tools/griffin_public_hardware.rhai` uses the existing shape planners and the
exact component mounts. The referenced sleeve material is prepared and projected
before its connection and shapes are authored; a first combined preparation was
rejected atomically because its referenced shader was not yet available.

## Visual review

- [Assembly](../handover/griffin-public-hardware-assembly-2026-10-28.png)
- [Leg detail](../handover/griffin-public-hardware-leg-2026-10-28.png)
- [Rear and underside review](../handover/griffin-public-hardware-rear-2026-10-28.png)
- [Wide before](../handover/griffin-public-hardware-wide-before-2026-10-28.png)
- [Wide after](../handover/griffin-public-hardware-wide-after-2026-10-28.png)

The wide comparison uses the existing Editor inspection assembly with the same
low-angle camera, studio lighting, crop and poses. Only this pass's twenty new
detail groups are hidden for before and restored for after. Earlier material and
seam/chassis work remains in both. Visibility is restored to `inherited` in the
saved review assembly. These are still-image reviews, not a qualified final video.

## Verification

Fresh production runs passed solar requirements (170), landing legs (189), and
bus requirements (254): **613 checks**. Landing legs were rerun after the installed
barrel wraps were saved. Typed readback also passed for all 85 new shapes,
including their source mounts, dimensions, material relationships and absence of
physics ownership. The existing focused leg and bus service-detail checks passed.
Repository validation, Rhai/SysML syntax checks and diff whitespace checks passed.
The final authoring-session runtime diagnostic was clear.

This is a visual reconstruction, not as-built qualification, a new thermal model,
or a full mission/hot-reload/video acceptance result. The source URLs, hashes,
camera state and check results are retained in the
[receipt](evidence/griffin-public-hardware-2026-10-28.json).
