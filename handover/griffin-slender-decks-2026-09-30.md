# Griffin slimmer upper structure

Follows dd92e68 (corner legs). The payload support perimeter uses estimated 80 mm square stock instead of 160 mm; its center moves from vehicle Y2.00 to 2.04 to preserve its Y2.08 wheel contact top. The upper bus perimeter deck ring also changes from 160 to 80 mm, with bus-local center .37 -> .41 preserving its .45 top. Plan spans, body belt, solar mounts, rover pose and ramp hinges remain unchanged. Visible meshes and source-driven hidden contact geometry were saved through the typed Editor journal together.

Rationale/source: the user-selected Astrobotic rendering, https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ , shows an open upper structure and exposed tank domes. 80 mm is an explicit silhouette estimate, not a measured beam section or load-qualified structural dimension. COPV upper-cap clearance below the payload rails increases from 14 to 94 mm without enlarging or lifting the tanks. Dimensions and estimate rationale are recorded in GriffinVisualConfiguration and griffin-size-evidence.md.

Verification is reported by behavior family, not by total assertion count:
- Tank packing/clearance: pass, /tmp/griffin-slender-frame-tank-gate.log.
- FLIP support interface: pass, /tmp/griffin-slender-frame-interface-gate.log.
- Bus geometry: pass after both ring changes, /tmp/griffin-slender-decks-bus-gate.log.
- Ramp touchdown: pass, /tmp/griffin-slender-decks-ramp-gate.log.
- Deployed ramp and cooked deck-contact geometry: pass after both ring changes, /tmp/griffin-slender-decks-ramp-interface-gate.log.
- Source catalog and git diff --check: pass.

Fresh owned Editor API49746 reopened saved assets; screenshot: griffin-slender-decks-review-2026-09-30.png. Visually the upper bands are thinner and the tank domes more exposed. The model remains a reconstruction with coarse materials, broad tread strips and simplified fittings. The tests establish implementation/physics consistency, not visual realism or structural sizing. Next work should improve these visible features against the selected rendering, rather than add assertion counts as a quality target.
