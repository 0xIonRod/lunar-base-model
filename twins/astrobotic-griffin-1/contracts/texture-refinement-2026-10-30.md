# Griffin / FLIP texture refinement — 30 October 2026

Griffin's bus frame, tank supports and deck now share the existing fine brushed
hardware shader instead of flat preview materials. Frame/deck finish controls
come from the existing aluminum presentation preset; the inner retention frame
uses the existing retention preset. The fallback diffuse channels agree with
the shader base colors. These are optical reconstruction choices, not alloy
grades or measured reflectance.

The new Twin-owned `thermal_blanket.wesl` adds fine handling crinkles to the
existing component-owned coarse folds. It replaces the shared foil shader on
the bus exterior, main tank covers and engine skirt. The two upper bottles
inherit the new network through their existing tank-material reference; their
distinct coarse-fold overrides are retained. Source palette, coarse frequency,
fold slope, sheen and axial scale remain unchanged. Fine frequency 240/m and
dimensionless slope 0.045 are explicit renderer assumptions in
`GriffinPresentationStudy::BlanketFinish`.

Each noise octave filters against the pixel derivatives. Lost normal detail
contributes to roughness instead of retaining unresolved sharp highlights.
This remains a visual approximation of a covered surface. The public reference
photographs do not identify the insulation layer stack or thermal properties.
The [material register](../research/materials.md) records those distinctions.

FLIP and Griffin's existing hardware shader now blends the brushing direction
toward local X on horizontal surfaces. The former fixed-Y stretch had no
directional effect on horizontal deck faces. The blend is smooth and remains
object-fixed; it does not introduce UV seams or require supplier CAD UVs.
Unresolved grain contributes normal variance to roughness. This is directional
normal detail under the existing BRDF, not a measured anisotropic BRDF.

FLIP's photovoltaic shader now integrates the periodic electrode mask across
the derivative-estimated pixel footprint. Thin electrodes preserve their area
coverage as they become subpixel. Cell color, pitch, width, material selection
and electrical model are unchanged. The pattern is illustrative, not released
cell metallization geometry.

## Authoring and verification

All persistent USD edits used typed native document-owner batches and explicit
SaveDocument. The editable shader and Rhai sources remain Twin-local. No scene,
light, exposure, geometry, collider, mass, joint or physics-material change is
part of this pass. In particular, no fill light or emission was added.

| Component | Document / final generation | Projection fence | Readback |
| --- | --- | --- | --- |
| Bus and deck | 120964487285469 / 55 | Ready, projected generation 55 | 12 grouped hardware checks; 3 blanket source checks |
| Main tank cover | 120964947093797 / 4 | Ready, projected generation 4 | 3 blanket source checks |
| Engine skirt | 120965093365695 / 4 | Ready, projected generation 4 | 3 blanket source checks |
| FLIP | 120965230139086 / 0 | Ready, source geometry unchanged | All 339 CAD surface bindings pass |

Focused Editor previews were inspected for the bus, tank, skirt and FLIP cell
faces. `FocusPanel {id: "usd::viewport"}` exposes the missing viewport panel;
this resolves the blank-preview presentation issue recorded in the previous
pass. Native WESL validation passes for all three changed/new shaders; Rhai,
presentation SysML, repository validation and `git diff --check` pass.

The authoring session later hit `usd-sim-duplicate-order-identity` while
reloading dependent layers. Its final running-scene frame was discarded. A
fresh owned review process loaded only the saved review scene, without edits:
ready true, no fault, no world hold, no pending participants, RuntimeDiagnostics
zero errors and zero warnings. Fresh composed queries confirm the new shader
and micro controls on the bus, inherited upper bottles and mounted skirt.
The Twin-wide SysML snapshot resolves both new controls at source revision
12899535108293189179 with no source errors. Startup loader/library warnings
remain in the local logs; they are not claimed absent.

The close and assembly stills were reviewed under the saved scene's existing
Sun, zero ReviewFill and zero exposure compensation:

- [Material detail](../handover/griffin-texture-detail-2026-10-30.png)
- [Assembly](../handover/griffin-texture-assembly-2026-10-30.png)

This qualifies source bindings and rendered stills. Final moving-camera social
export, temporal shimmer acceptance and flight optical calibration remain
separate checks. No tether-descent qualification is implied.

See [machine-readable receipt](evidence/texture-refinement-2026-10-30.json).
Local journals and screenshots are in `runs/griffin-textures-2026-10-30/`;
the native command journal continues in the existing API helper's run folder.
