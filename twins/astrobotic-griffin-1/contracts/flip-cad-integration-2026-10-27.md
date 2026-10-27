# CAD FLIP integration checkpoint — 2026-10-27

This change integrates the retained FLIP v5 CAD assembly with the latest
`origin/main` model at `2b3c0a9`. It preserves the upstream four-track/twelve-
hinge ramp mechanism, contact-validity policy and terrain-fitted route markers.

The production surface-operations and visual scenes reference `vehicles/flip_v5.usda`.
Four native wheel hinges, suspension sliders and the solar-panel hinge retain
their CAD geometry and mechanical topology. The finite battery, moving-panel
photovoltaic/environment probe, shared drivetrain/tire thermal network, operator
route and vessel HUD use the existing simulator component mechanisms.
The 0.70 m wheel-support offset and adapter anchor align the CAD payload with
the unchanged Griffin deck datum.

The component README records the source commit and provenance. Electrical and
thermal parameters remain explicit study assumptions; this is not flight
hardware calibration. Older proxy fixtures retain their original geometry.

## Reproducible checks

Run these with a compatible production `luncosim` binary from this Twin:

```sh
luncosim test --scene tests/flip_route_follow.usda --verdict-channel FLIP_ROUTE_FOLLOW --max-ticks 11000 --api 4201
luncosim test --scene tests/flip_motion.usda --verdict-channel FLIP_MOTION_COMPLETE --max-ticks 1800 --api 4201
luncosim test --scene tests/flip_cad_capabilities.usda --verdict-channel FLIP_CAD_CAPABILITIES --max-ticks 2000 --api 4201
```

The merged route/HUD/manual-takeover/thermal gate passes at tick 1582 (26.37 s).
The earlier CAD motion gate passes at tick 845; the panel/finite-EPS gate passes
at tick 1561. The mounted CAD assembly passes all eight deck/adapter/drive checks
against the updated Griffin. Windowed reloads and native controls are recorded
in [the CAD runtime receipt](flip-cad-runtime-2026-10-26.md).

Rebuild the ignored terrain maps using `tools/terrain/README.md`. The offline
bundle verifier passes for all three pinned sources, finite 513-by-513 terrain,
4 m node spacing over 2048 m, and the 2048-by-2048 albedo map. Generated maps,
downloads, local config and raw simulator runs are excluded from the commit.

## Simulator compatibility and remaining boundary

Validation used simulator revision `a23ab8ec8` with local integration fixes.
The wheel projector waits for structural stage work before binding referenced
CAD render roots; the visual projector drains asynchronous mesh work correctly
and preserves hidden proxy frames. The terrain asset processor must use node
intervals `(win - 1) * scale` and processing pipeline version 8 or later.
The matching local processor regression and model bundle verifier pass.
These simulator changes belong to the separate `lunco-sim` repository and are
not included in this model commit. Use a simulator carrying those fixes.

Full landing, release and ramp traversal were not rerun after this upstream
merge. The previously observed mission Rhai string-limit failure is a separate
acceptance boundary; focused rover passes do not establish full mission success.

The merge retained all 23 formerly untracked CAD/test/evidence files. Its sole
text conflict was resolved by retaining the current reconstruction review and
preserving the earlier engine-count source note as historical context.
