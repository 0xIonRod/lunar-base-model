# Slender ramp guide checkpoint

Compared the live folded assembly with Astrobotic's selected 2021 rendering:
https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png.
The guide sides looked like square bars and oversized fittings. Their new
transverse width is 20 mm, with 40 mm vertical depth; posts are 40 mm deep,
diagonals 8 mm square, and lower chords 20 mm square. Local pins are 40 mm
diameter and 60 mm long, with 10 mm lug plates. These are explicitly labelled
low-confidence silhouette estimates in GriffinEgressRamp. The source provides
no stock specification or structural sizing. The twelve lattice bays,
vertical hinge datums, contact plate dimensions and deployment angles remain
the study values.

Guide centers derive from track faces: outer +/-1.30 m, center +/-0.70 m.
The shared section owns the lattice. Removed 56 assembly opinions for shared
guides and identical deck/toe fittings; the middle-section hinge-specific
fitting placements remain local. No new geometry tool or redundant observer
was added. All USD edits and saves used the Editor document command owner.

Fresh combined preview document 115594355930621, view 13, generation 0,
stage generation 31 reports guide scale (1.799084054, .04, .02), post scale
(.012, .225, .04), diagonal section (.008, .008), and pin radius .02 / height
.06 m. The focused image is `griffin-slender-rails-2026-10-01.png`.
The ramp requirements gate passed 1421 existing checks, 11 ticks, one thread,
zero jitter, 60 Hz, seed 6840157149251759617. This proves source-to-composed
static geometry; it does not establish powered deployment or rover egress.
The affected flight-stow gate also passed its existing 228 checks in 8 ticks
with the same deterministic clock settings.
