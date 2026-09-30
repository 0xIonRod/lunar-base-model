# Griffin rail web review

Committed the preceding reporter checkpoint as c11923b before this rail pass.
The previously approved visual checkpoints are 83a0a9d and d5b8713.

The rail reconstruction replaces square-section fence-like stock with a
common 6 mm transverse web, 40 mm upper strips, 20 mm lower strips, and 12 mm
in-plane diagonal members. Two end posts and twelve alternating diagonals
per guide leave open triangular bays. The lower strip bottom derives from the
contact-track top; its centre is now Y=.025 m rather than .055 m. Rail centres
and fitting stations derive from the track edges: outer +/-1.293 m and inner
+/-.707 m. Shaft span is 2.592 m. Track contact width, hinge elevations and
fold angles retain their existing study values.

References:
- https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png
- https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander

These are artist renderings, not released mechanical drawings. The zigzag web
interpretation, bay count and member gauges are low-confidence visual study
assumptions. Their source and rationale are recorded in GriffinEgressRamp and
GRR-009/019. This pass does not establish structural strength. Shared standard
silver-metal appearance uses existing GriffinVisualConfiguration values;
these are artistic renderer inputs, not measured optical properties.

All persistent USD edits used the owned Editor API 49746. Shared section
geometry owns all webs; removed the toe guide overrides, and retained only
hinge-specific fitting placement in the assembly. Existing generic material
and placement planners were reused. The guide identity-to-side mapping now
lives once in griffin_spec::ramp_guide_stations for builder and observer.
No new geometry framework or core code was introduced.

Fresh combined preview 115600167141700, view 18, document generation 0,
stage generation 66, projection ready. Composed middle-section readback:
8 end posts and 48 diagonal braces across four guides; lower strip scale
(1.799084054,.020,.006), centre (.899542027,.025,1.293); first diagonal scale
(.215643472,.012,.006). The shared RampStructure material binding resolves in
that instance namespace. Screenshot: griffin-open-rail-web-2026-10-01.png.

Focused rail geometry gate: PASS, 1085 checks. Affected flight-stow gate:
PASS, 228 checks. Both use 60 Hz, one thread and zero jitter. Typed provenance:
207 targets/records, 47 source elements, 3 roles. Geometry checks now sample
web thickness and lower-strip seating while following the reduced post count;
the check count is lower than the prior 1421-check gate. Static conformance
and this visual review do not prove powered unfolding or FLIP egress.

The old owned mission replay was intentionally stopped (exit 130) after its
repeated reporter exception; it was not a terminal mission FAIL verdict.
The reporter smoke fix is recorded separately. Do not resume a full mission
campaign merely to review these visual rails.
