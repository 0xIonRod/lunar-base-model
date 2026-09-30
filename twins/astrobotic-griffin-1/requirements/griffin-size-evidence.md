# Griffin and FLIP size basis — 2026-09-30

These are provisional reconstruction requirements, not an as-built mechanical
ICD. A successful geometry check proves implementation of the assumptions; it
does not prove the assumptions describe flight hardware. Replace estimates when
better configuration-specific evidence becomes available. Numerical precision in
derived hinge coordinates is for interface closure, not measurement accuracy.

## Evidence and configuration boundaries

* [NASA MSS 2024 NDL presentation](https://ntrs.nasa.gov/citations/20240004236),
  slide 8 (PDF page 8), labels a Griffin/VIPER illustration **4.5 m across and
  2.0 m high**. Those arrows describe an older vehicle envelope, not a measured
  Griffin-1 bus. This is a scale anchor with a configuration mismatch.
* [Astrobotic June 2026 Griffin-1 hardware](https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/)
  shows the current structure, seven-engine configuration and side panels.
  The handling stand beneath it is ground equipment. The photograph has
  perspective and no calibrated scale; it supports proportions, not dimensions.
* [Astrolab LPSC 2026 abstract 1874](https://www.hou.usra.edu/meetings/lpsc2026/pdf/1874.pdf)
  identifies four wheels, skid steering and a 480 kg launch constraint inherited
  from the VIPER allocation. It publishes **no numerical body or wheel sizes**.
* `flip_cad_requirements.sysml` records the local reference-informed CAD study:
  body 1476 × 2116 × 396 mm, 2000 mm track, 1700 mm wheelbase, 450 mm tire-band
  radius and 280 mm tire width. **All are estimates**, not supplier data.
  They provide a more coherent starting point than the legacy 4.40 m chassis.

## Selected assumptions and rationale

| Quantity | Previous active model | New study value | Basis and uncertainty |
|---|---:|---:|---|
| Griffin body plan span | 5.40 m | 3.60 m | Estimate: 80% of the historical 4.5 m overall envelope reserves 0.45 m per side for leg/foot extension. Plausible range 3.2–4.0 m; low confidence. |
| Body frame height | 2.00 m | 1.40 m | Packaging estimate to keep the bus substantial without treating the handling stand as spacecraft. Range 1.1–1.7 m; low confidence. |
| Payload surface above terrain | 5.72 m | 2.52 m | Estimate: older 2.0 m overall-height anchor plus approximately 0.5 m allowance for the current higher deck/structure. Range 2.0–3.0 m. Not a photograph measurement. |
| Footprint across opposed pad edges | 7.24 m | 4.50 m | Two 1.90 m radial leg stations plus two 0.35 m pad radii; selected to match the historical envelope approximately. Current footprint unconfirmed. |
| Payload adapter | 4.40 × 3.20 m | 3.20 × 3.20 m | Estimated octagonal footprint fitting inside the bus and covering the reconstructed FLIP wheels after clipping the corners. Thickness retained at 0.16 m as a structural proxy. |
| FLIP body | 4.40 × 2.76 m lower frame | 2.116 × 1.476 m | Promote the estimated CAD plan dimensions with an explicit axis mapping. Allow approximately 20% dimensional uncertainty. The 0.12 m lower-frame height is a visualization/collision proxy; equipment box height 0.396 m comes from CAD. |
| FLIP wheel envelope | legacy inconsistent envelope | 2.28 m across track; 2.60 m along travel | Derived from 2.0 m track + 0.28 m tire width and 1.7 m wheelbase + two 0.45 m radii. Wheel ribs, deformation and suspension travel excluded. |
| Ramp length | 12.228605 m | 5.397252161 m | Derived: 2.52 / sin(0.4857867749). Retain the previous **estimated** 27.8335° deployment angle to isolate the height correction; not a published ramp slope. At 2.0–3.0 m deck heights this gives 4.28–6.43 m. |
| Each of three sections | 4.076201667 m | 1.799084054 m | Total length / 3. Three-section folding topology remains a study assumption. |
| Ramp outside width | 3.50 m | 2.86 m | 2.00 m track + 0.58 m contact-track width + two 0.14 m rails. Contact width is 0.28 m wheel + twice 0.15 m estimated clearance. |
| Deck transition | 1.96327 m | 0.90 m | Estimated bridge to the octagonal deck: outboard X=1.90, inboard X=1.00. At outer rail Z=1.43 the deck edge is X≈1.107, leaving >0.05 m overlap. |

The vehicle touchdown reference remains 0.44 m. Adapter center Y=2.00 plus
half-thickness 0.08 gives a vehicle-local top of 2.08 m, hence 2.52 m above
ground. A ramp half-thickness of 0.09 m yields hinge X=1.90+0.09 sin(angle),
Y=2.08−0.09 cos(angle); the builder's toe miter closes both contact edges.
Section and transition inertia are recomputed as rectangular-envelope proxies
using the existing estimated masses (95 kg ramp, 15 kg transition). Retaining
those masses avoids inventing a supplier mass revision; they remain uncertain.

The body mount, shortened legs, tank stations, tank scale, frame rings, support
openings, solar mounts and bucket heights are **dependent packaging estimates**.
Their purpose is to keep neighboring parts aligned after removing the inflated
deck height. They are not separately measured dimensions. Tank scale 0.60
replaces 0.90; four tanks remain, with 0.58 m support openings allowing the
approximately 0.516 m maximum scaled band radius plus >0.06 m clearance.
Leg tube length 1.40 m and piston length 1.15 m connect the revised 1.20 m leg
mount to the −1.15 m local pad center. Tube section, shock tuning and dynamics
remain study proxies. Spring seating is calculated from these datums by the
existing builder, not hand-positioned independently.

## Coordinate and acceptance limits

The CAD uses X lateral, Y longitudinal, Z up. The egress reconstruction uses
USD X longitudinal, Y up, Z lateral: CAD (X,Y,Z) → USD (Y,Z,X). Wheel cylinders
must use Z axle axes and the FL/RL/FR/RR identities must follow that mapping.
The legacy frame description and wheel axle inheritance were inconsistent with
the existing ramp's X travel direction. Check saved composed geometry, not just
source tables, when accepting this correction.

Geometry promotion does not establish the real spring deployment mechanism,
supplier load paths, actuator dynamics, calibrated masses/inertias, landing
control, or successful rover egress. The legacy Ackermann simulation policy
also remains a separate mismatch with the public skid-steer configuration;
correcting its controller requires its own behavior validation.

The eight muted-gold exterior facets approximate wrapped side panels visible in
the June 2026 hardware photo. Their 25 mm thickness, 80 mm frame-edge margin,
flat faces and display color are presentation estimates. They add no collision
or material/structural claim. The body collision proxy uses five boxes inscribed
in the octagon; it omits the diagonal triangular wedges and follows the same
body dimensions and mount rather than retaining the old oversized collider.

First-pass checks: the fresh production test passes all 164 ramp stow checks,
all six ramp touchdown-geometry checks, and all 161 landing-leg checks. The bus
fixture returned NO-VERDICT, and standalone FLIP fixtures encountered an
environment-direction-unavailable fault. These results do not establish full
mission acceptance. The stow gate now measures composed track centers directly:
the previous Euler reconstruction disagreed with USD geometry and hid the
starboard downward pose. Its saved USD rotation is corrected to (0,180,-45).
