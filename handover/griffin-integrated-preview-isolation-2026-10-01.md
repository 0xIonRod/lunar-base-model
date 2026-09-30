# Griffin integrated preview isolation investigation

Models branch main: requirements GV001 now explicitly distinguishes canonical
Editor component previews from georeferenced mission cameras. No compensating
USD transforms were authored. New source/rationale evidence is in
requirements/griffin-size-evidence.md.

Owned process API49746 remains open. Integrated scene document115589474414007,
view31, projection generation0 ready,50 recipe layers. Its canonical Griffin
position is0,0,0 but framing produced a camera target near lunar-radius
coordinates (-51650.75,-1725515.25,195171.97). Screenshot
/tmp/griffin-flip-framed-review.png shows major distortion. Local vehicle preview
is normal. Do not judge model geometry from this integrated preview until the
frame issue is resolved. Leave global mission precision/anchors intact.

Terrain branch terrain-streaming, HEAD6186c437b, initially clean. Read-only
owner trace found project_celestial_comms_prims lacks the existing preview
ancestry guard, whereas other simulation adapters use
lunco_usd_bevy_scene::is_preview_only. The preview root already carries
UsdPreviewOnly. Celestial site placement establishes a Grid/ActivePhysicsFrame;
preview camera construction uses an ordinary Transform. Root cause remains a
hypothesis until the focused test and rebuilt rendering confirm it.

A generic regression test was added first, uncommitted, only in terrain
crates/lunco-usd-sim-celestial/src/lib.rs:
preview_prims_do_not_enter_celestial_projection. It distinguishes a preview
root+child from a live loading root. No implementation patch yet. Test exec
session54319, cargo PID593766, log/tmp/griffin-preview-isolation-red.log.
It is confirmed waiting for the shared optimization target lock; another live
cargo build PID592659 owns that work. Do not stop other builds or restart our
pending test merely for an observation timeout. Poll that exact handle.
After the test fails as expected, reuse is_preview_only at the projector owner,
run focused tests, build from terrain, and inspect the exact combined scene.

Trello workflow was read and its missing official connector reported before
core work. No available Trello tools were discovered; no external messages
were sent. No core commit or rendering fix is claimed. The active Griffin goal
remains incomplete.

## Resolved checkpoint

Core fix committed in terrain/terrain-streaming as a7707995c. The original
cargo test completed (exit101, expected queue assertion), then all10 crate tests
passed with the existing ancestry guard. Full app build from terrain passed;
owned old PID162365 was stopped only after USD InspectUsdDocument reported
all8documents saved. ListOpenDocuments had stale dirty flags; concrete USD
owner reports were authoritative. Fresh owned PID627628, exec session47868,
API49746, high quality, isolated config remains running.

Fresh combined document115591551527336, view8, generation0 ready,50recipe layers.
Same rear preset target(0,1.65,0), distance27.6 now renders the proper assembly,
including FLIP and dish. Framing target approximately(0,.26218,0) confirms the
local presentation frame. Source scene/vehicle transforms were not modified.
Screenshot committed under twins/astrobotic-griffin-1/handover/
griffin-flip-preview-fixed-2026-10-01.png.

Core diagnosis refined: preview roots carry UsdPreviewOnly but not UsdSceneRoot,
so the authored root anchor followed generic geodetic placement, rather than a
proven SiteAnchor/ActivePhysicsFrame mutation. Guard stops celestial/link domain
projection for the whole preview hierarchy. Production visual fixture PASS:
/tmp/griffin-preview-isolation-visual-gate.log,113checks,8ticks,60Hz,one thread,
seed6840157149251759617. No full mission acceptance follows. Continue model
fidelity against references now that the integrated preview can be trusted.
