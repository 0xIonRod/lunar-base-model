# Griffin engine skirt

The skirt is a public-reference reconstruction around the seven-engine cluster.
The [June 2026 hardware photograph](https://www.nasa.gov/image-detail/26-06-15-griffin-1-pressconference-1348-edit/)
provides configuration context, not calibrated skirt dimensions. The large black
support visible in that photograph is ground equipment. It is not part of the
flight skirt in this model.

`GriffinEngineSkirtComponent` in `griffin_propulsion_requirements.sysml` owns
the rail, tapered shell, adapter, apron and exhaust-opening dimensions. The
3.44 m rail span, 60 mm lower inset, 1.02 m aperture apothem and 20 mm nozzle
exit recess remain packaging assumptions. Engine sizing assumptions and their
limits are recorded in [the model review](griffin-model-audit-2026-10-21.md).

The outer shell and inner liner have finite radial stock and real upper and
lower lips. Their 8 mm visual allowance derives from the existing apron
allowance. It is not a measured flight blanket gauge, structural thickness,
thermal conductivity or heat-protection qualification. The liner stock lies
outside the exhaust aperture; the apron meets the shell's inner wall. The
engine stations and outside skirt envelope are preserved.

The apron uses the outer shell's shared MLI material. Its gold color is the
requested presentation finish; the hardware reference is predominantly silver.
The recessed liner uses the shared silver metal material. All three surfaces
are single sided, with consistently outward-facing closed material volumes
around an open central exhaust path. Their display meshes do not add mass or
collision ownership.

GES-002 requires measured finite wall geometry. The production propulsion
observer reads the composed mesh vertices, face indices and render-side
setting. It measures edge incidence, opposing edge direction, positive signed
volume, minimum and maximum shell/liner stock at both lips and apron thickness.
Both measured stock bounds must match the declared allowance within the
source-owned geometry tolerance. GES-004 separately
checks bell clearance and the exhaust path; GES-006 checks the rail and shell
against their source-owned profile. These observations share the same source
revision and USD document/stage generation, across bounded script callbacks.

The repair evidence is retained in the tutorials worktree under
`.cache/codex-evidence/griffin-skirt-thickness-20261021/`. The isolated Editor
gate passed before saving, and the assembled underside was visually inspected.
The initial integrated observer exceeded its per-callback operation budget;
wall and exhaust measurements now use separate callbacks with the same
snapshot fence. No operation limit was raised.

On 22 October, the preserved production executable
`luncosim-343baf607-grid-final` (SHA-256
`0f5daf8adde208a68312ef998a26c4db85f8986c6dcc8ed4a30abb73a22b84dd`)
ran from the requested USD checkout against its shared assets. The former
minimum-only predicate accepted a deliberately fourfold-thick lower liner
lip while the upper lip remained unchanged: all 104 checks passed at source
revision `13786752950730195760`. This exposed a verification gap, not a need
to change the intended 8 mm allowance or the geometry tolerance.

The revised predicate checks both thickness extrema. The unchanged positive
vehicle passes all 104 checks at source revision `17995770647406241040`,
with that same revision at run start and completion. Both the collapsed-lip
and fourfold-thick lower-lip fixtures fail exactly `GES-002-finite-walls`;
the other 103 checks pass, with zero evaluation errors or inconclusive checks.
The portable driver is `tests/check_skirt_failure_rejection.py`; it forks,
edits, saves and reads back each disposable fixture through the document API,
then removes it. Each trial uses a new scratch identity so restored documents
cannot claim its path. A session closure and a stale restored-preview collision
interrupted two authoring trials; neither is counted as rejection evidence.

Current receipts, before/after logs and source hashes are under the USD
checkout's `.cache/codex-evidence/griffin-resume-20261022/`. This qualifies the
skirt geometry observation on the named executable, not a rebuild of the
current USD source or the full Twin's appearance, flight fidelity or speed.
