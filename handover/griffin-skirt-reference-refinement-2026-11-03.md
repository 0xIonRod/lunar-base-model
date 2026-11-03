# Griffin engine-skirt visual refinement — 2026-11-03

Refinement on `codex/griffin-engine-skirt-satin`, based on commit
`3c096e4db320bbf086f76332a3d5fadbb208c192`. Delivery target is the same
feature branch on Rod's fork, `0xIonRod/lunar-base-model`.

## Appearance and source owners

Widened the exhaust opening to 1.44 m apothem, leaving about 0.212 m of
apron at each flat. Added thin inner/outer folded rims, eight radial panel
seams and sixteen small retaining heads. The apron has a dark satin finish.
The original external envelope, seven engine stations, mass and propulsion
owners are retained. All added detail has render purpose and collision disabled.

Geometry is owned by `GriffinPropulsionRequirements::GriffinEngineSkirtComponent`;
finish/detail parameters by `GriffinPresentationStudy::EngineBayFinish` and
`EngineBayDetail`. Regenerate the existing base skirt, apply the idempotent
`griffin_bus_detail::skirt_finish_plan`, then `griffin_skirt_detail::plan`.
The new detail module also supplies a source-derived `check` entry point.

References: [Griffin hardware photograph](https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png)
and [NASA Griffin gallery](https://www.nasa.gov/gallery/astrobotics-griffin-1/).
They inform wrapped panels, segmentation and attachment vocabulary. They do
not expose a measured complete underside: aperture, hems and fasteners remain
visual reconstruction estimates. Visual fidelity is therefore Partial.

## Verification

- Pass: native document readback of 29 render shapes, including 26 new details.
- Pass: five meshes have finite coordinates, closed consistently oriented edges
  and positive signed volume.
- Pass: all seven bells measured in the common cluster frame; minimum aperture
  clearance 0.6100261664 m, exit recess 0.0200000107 m.
- Pass: native isolated and assembled underside appearance review.
- Pass: saved component reopened in a fresh application process, clean at
  generation zero, with all 26 detail children present and projection ready.
- Pass: new Rhai module source preflight and presentation SysML validation.
- Not evaluated: execution of the new Rhai regeneration/check functions; the
  existing scripting initializer did not complete in this build.
- Not evaluated: full Twin source validation and simulation. Whole-Twin
  `ValidateSysml` stalled the review process; it was restarted after saving.
  Standalone propulsion SysML validation reports unresolved cross-file imports.

Intentional fitted contacts are inner hem–apron/liner, outer hem–apron/shell,
seam–apron and retaining head–apron. No general assembly interference or thermal
qualification is asserted.

Application: LunCoSim 0.6.0-dev, engine `8942a7d5-dirty`, native Vulkan build.
Persistent asset: `twins/astrobotic-griffin-1/components/lander/griffin_engine_skirt_visual.usda`.
SHA256: `157590348C577A930966E401A15FF597FFE1609C3D61D2CE662CCD7209C24117`.
Edits and save used typed Editor operations; inspection rotations use only
the transient view layer.
The native save serialized the existing apron/liner documentation keys as
`doc` rather than `documentation`; their text is preserved.

Evidence in the engine checkout's ignored `logs/` directory:
`skirt-refinement-verification-nov03.json`,
`skirt-detail-verification-inputs-nov03.json`,
`skirt-bell-clearance-inputs-nov03.json`,
`skirt-detail-ready-nov03.png`, and `griffin-final-ready-nov03.png`.
