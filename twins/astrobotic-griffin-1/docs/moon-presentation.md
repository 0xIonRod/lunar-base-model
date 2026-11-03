# Moon globe presentation

The Twin opens its Griffin/FLIP surface-operations scene. The separate
`media/griffin_flip_v13/scenes/moon-day.usda` is a globe presentation with
an inactive rover and hidden local terrain mesh.

The site root retains its geodetic observer frame for physical sunlight and
Earthshine. Its real DEM-backed environment stays active so the terrain handoff
has its authoritative surface and datum. Only the local terrain mesh is hidden;
the globe supplies the orbital image. The scene's camera track selects
`MoonView`, whose explicit clipping range includes the globe from its
presentation altitude. The authored DistantLight remains the scene Sun.

`media/griffin_flip_v13/scenarios/headful_capture.rhai` reads the camera at
`/Griffin1SurfaceOps/MoonView`. Camera selection by the unique
`MoonView` name uses the same authored camera. Validate the selected identity,
range and runtime diagnostics, then inspect a newly captured rendered image.
