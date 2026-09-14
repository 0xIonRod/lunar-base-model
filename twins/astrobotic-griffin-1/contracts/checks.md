# Griffin executable check catalog

The check IDs below are the acceptance contract. `Active` means the current
Rhai fixture can evaluate it against the composed stage. The normative intent
and study thresholds are declared in
`requirements/griffin_requirements.sysml`; Rhai remains the executable test and
verdict backend. `twin.toml`'s `[verification]` section binds each qualified
SysML verification to its scene, Rhai observer, and verdict channel; it is
validated before a run and contains no copied thresholds. `Planned` means the obligation is recorded now, but needs a
generic query or runtime seam that this Twin does not yet expose. Planned
checks must not be represented as passing.

| ID | Check | State |
|---|---|---|
| GR-001 | Root identity, Xform type, boxy airframe, payload deck, metadata, and canonical topology | Active |
| GR-002 | Payload adapter and enabled adapter-plate collider | Active |
| GR-003 | Optional two ramp bodies, contact surfaces/rails, mechanism metadata, and command bound | Active (ramp branch) |
| GR-004 | Public/global reference provenance is recorded for every imported or surrogate part | Planned |
| GR-005 | Explicit parameter status, source provenance, and public-fact boundary (SysML + USD metadata) | Active |
| GR-006 | Main propulsion interface and exactly two named solar-array owners | Active |
| GR-007 | Units, Y-up frame, root datum, and local-vs-world transform convention | Active |
| GR-008 | No duplicate visible canonical/proxy geometry or dangling authored paths | Planned / partial via GR-020 |
| GR-009 | SysML payload capacity is the public 625 kg Griffin product value; Rhai boundary accepts edge and rejects over-limit | Active |
| GR-010 | Exactly four visible functional legs, named struts, positive mass, and pad colliders | Active |
| GR-011 | SysML ramp command proxy is ±0.58 rad; Rhai checks two revolute joints, body relationships, Z axis, and ordered limits | Active (ramp branch) |
| GR-012 | Collision ownership: solid contact parts collide; visual-only parts do not | Active / partial |
| GR-013 | Adapter/release ownership is explicit and separated from the scene timeline | Active in mission contract |
| GR-014 | Authored pose admission/settle prevents start-under-ground bodies | Planned runtime gate |
| GR-015 | Nozzle wrapper is visible, typed as a part frame, and owns real bell geometry | Active |
| GR-016 | Solar-array count, signed sides, mirror placement, and `Cells` geometry | Active |
| GR-017 | Ramp count, opposite-side placement, mirrored rotation, and metadata/transform agreement | Active |
| GR-018 | Boxy airframe and rectangular isogrid-deck shape, dimensions, height datum, and collider | Active |
| GR-019 | Leg cardinal placement, mirror symmetry, radial datum, and pad contact placement | Active |
| GR-020 | Historical comparison/proxy geometry is deleted, not merely hidden | Active |
| GR-021 | Positive finite mass, centre of mass, and inertia for every dynamic body | Planned |
| GR-022 | Support polygon contains the projected centre of mass at touchdown | Planned |
| GR-023 | Pad contact plane and ramp contact plane are continuous and non-penetrating | Planned |
| GR-024 | Hinge frames, axes, limits, and body ownership agree with the authored pose | Planned / partial via GR-011/017 |
| GR-025 | Solar panel clearances, no body overlap, and no panel self-intersection | Planned |
| GR-026 | Payload adapter release leaves no stale joint or route-sensor ownership and records direct/ramp branch | Active in mission contract |
| GR-027 | Propulsion nozzle/flame alignment and visual plume does not become a collider | Planned |
| GR-028 | Required electrical/thermal/propulsion interface names resolve without silent defaults | Planned |
| GR-029 | Every part has a source/provenance and a known/TBD parameter status | Active via manifest |
| GR-030 | Fresh headful screenshot and query evidence for each changed geometry group | Process gate |
| GR-031 | Production Twin test emits a verdict with deterministic threads/jitter | Active; landing-stability trial also records fixed-horizon telemetry and repeatability deltas |
| GR-032 | Exactly seven visible non-colliding main-engine bell geometries | Active |
| GR-033 | Exactly four visible Y-axis propellant-tank geometries with mirrored layout | Active |

The active checks are deliberately conservative. They are allowed to fail on
the current model until the Editor repairs the authoritative geometry. The
planned checks remain visible so future work cannot mistake a green partial
lint for a complete vehicle qualification.

## Visual review checks

The visual contract is intentionally separate from flight/dynamics topology.
Its source is the same SysML package, but the executable check table is
`scenarios/tests/griffin_flip_visual.rhai` and the geometry is composed from
Twin-local component assets. Every check is a read-only observation; dimensions
use `QueryUsdPrim` composed `geometry_bounds` rather than reimplementing USD
shape math in the Twin.

| ID | Component scope | Evidence |
|---|---|---|
| GV-001 | Authored camera | camera prim exists in the SI/Y-up review frame |
| GV-002 | Griffin bus, legs, tanks, ramps, engine bells | each instance and named subpart resolves as a visible composed child |
| GV-003 | Griffin mirrored solar arrays | component decomposition and the Griffin solar-array visual datum are present |
| FGV-001 | FLIP chassis, mast, collapsible solar array, four directional wheels | rover-owned decomposition and the SysML four-wheel visual datum are present |
| GV-004 | Scale | composed bounds agree with deck, wheel, landing-pad, and ground metre datums |
| GV-005 | Render ownership | review ground is render-only and does not add a physics collider |
| GV-006 | Lunar context | ground and one authored light are present |
| GV-007 | Evidence | Rhai emits a verdict that can be paired with a same-generation frame/query capture |
