# Griffin native-axis ramp fittings

Follow-up to 88cfe70: four coaxial guide fittings now share each section's
native shaft elevation: root 0 m, middle .2 m, toe -.015 m. The old pair at
upper-chord centre (.18 m) incorrectly passed the observer. GRR008 and its
observer now require the native axis and a lug spanning between that axis
and its guard. Shaft and joint datums themselves are unchanged.

A shared `griffin_spec::ramp_guide_stations()` pairs source pin identities with
all four guide stations for both builder and observer. Lug heights derive from
pin radius, plate bottom and guard top. The 60 mm travel width and 16 mm plate
thickness are explicitly unqualified visual assembly estimates with rationale
and the selected Astrobotic image link in the ramp requirements. All fittings
follow existing section bodies; no additional joints or independent animation.

Typed Editor operations saved the reusable section, specialized toe and
middle-section overrides. Deck/toe instances inherit source fittings; retired
local pin opinions were removed. Owned API 49746, composed vehicle document
115583440039739 generation 0, projection ready with all 17 recipe layers.
Readback /tmp/griffin-coaxial-fittings-readback.txt confirmed all 24 fittings
share their six section-shaft axes within 2 mm and use cylinder axis Z.
Focused and assembly rendering: /tmp/griffin-coaxial-rail-section.png and
/tmp/griffin-coaxial-fittings-front.png.

Deployed ramp fixture passed at source revision 17365296355085597972:
/tmp/griffin-coaxial-fittings-ramp-gate.log. Lattice flight-stow fixture passed
before this render-only fitting correction. Source catalogue and diff checks
passed. Full mission landing and FLIP traversal remain separate acceptance.
