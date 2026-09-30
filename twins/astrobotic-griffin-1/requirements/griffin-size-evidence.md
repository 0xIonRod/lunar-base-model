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
| Body belt and frame-member height | 2.00 m; first pass 1.40 m | 0.72 m | User-selected ESA face ratio ≈3:1; broad octagon face = 0.585786 × 3.60 = 2.109 m; 2.109 / 3 = 0.703 m, rounded to 0.72 m. Approximate range 0.60–0.84 m; low-confidence presentation estimate. The earlier 1.40 m entry was stale and did not match the authored geometry. |
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

The eight neutral exterior facets reproduce the shallow body belt in the
user-selected ESA concept image. Their 25 mm thickness, 40 mm frame-edge margin,
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

## User-selected proportion correction

[ESA Griffin lander, 23 September 2022](https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander)
is explicitly an artist's impression. The user marked one broad side face,
roughly three times wider than high. This is not the whole lander aspect ratio,
and it excludes the tanks and rover above the belt. The selected 3.60 m plan
span remains an uncertain scale assumption; changing it should scale the belt
height with the face ratio. Four wide octagon faces have a 2.109 m span before
panel margins. Their source ratio is 2.93 with the selected 0.72 m height.
The image ratio is estimated as 3.0 ±0.35; this tolerance reflects visual
interpretation, not a manufacturing allowable. The gate measures the actual
four wide facet meshes, including margins; corner faces are excluded.

[Astrobotic Griffin product rendering](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
provides a second shallow-belt reference and labels an older overall envelope
4.5 m across, 2.0 m high. The user counts **14 cell columns and 5 rows** in the
front panel. Nearly equal cell pitches imply an active-field aspect ratio
around 2.8, before borders and perspective. This count is observed in a concept
rendering, not verified current flight hardware. The model uses a 14×5 grid,
1.596×0.58 m active field (pitch ratio 0.983), and 1.716×0.66 m nominal frame.
Each installed panel width still follows its own face-rail spacing. The 6 mm
dividers are visual gap estimates; the lower mounting cutout remains a study
assumption, so not every nominal cell has a full rectangular active area.

Body top remains vehicle Y=1.70; shortening the belt raises its center to
Y=1.34. Deck, adapter and ramp mount datums remain fixed. Frame rings, corner
posts, collars and buckets follow the new local height. Tanks move to Y=1.40
as a packaging estimate so their upper domes emerge above the belt while
remaining below the adapter; tank size is unchanged. This reconstructs the
concept's separation of shallow structure and exposed tank domes, without
claiming that the June 2026 hardware has the same exterior coverage.

Ramp truss chord top is revised from 0.81 to 0.36 m above the walking plane:
0.20 of a 1.799 m section length, rather than 0.45. This is a silhouette estimate
from the two concept images, not a strength calculation. Rail/chord stock is
0.08 m, posts 0.06 m, diagonal braces 0.04 m, underside beams 0.12×0.10 m.
Physical walking thickness, conservative width envelope, hinge location,
length, deployment angle and existing mass proxies are unchanged. The fold
axis offsets are re-derived from the slimmer chords by the builder.

The shared `usd_geometry_inspection` library owns the read-only fixed-tick USD
query contract and composed scene-owner lookup. Bus and visual gates do not
rely on Editor tab focus; the ramp stow gate uses the same dependencies.


Latest focused evidence: the bus gate passed 339 checks, the solar gate passed
148, ramp stow passed 164 and touchdown geometry passed 6. These are geometry
checks, not flight or deployment dynamics acceptance. Bus and solar fixtures
now explicitly declare metres; otherwise USD defaults to centimetres and
world-space overlap evidence has the wrong scale. Solar mounting orientation
uses a quaternion for face tilt followed by plan bearing; the previous Euler
composition tilted the diagonal panels and disconnected the side mounts.
The isolated and component-migration builders now share that orientation
recipe, as do the solar and broader lander checks.
The owned windowed review reports a degraded-rendering shader binding fault;
full rendered visual acceptance remains unresolved.


Follow-up evidence: the broader lander gate passes 122 checks after its fixture
also declares metres and shares the quaternion checks. The solar gate again
passes 148 checks after deduplication. All three isolated solar placement
recipes produce dry plans successfully. The saved vehicle preview has matching
document and projected generations 1050; the
[review screenshot](../handover/griffin-proportions-review-2026-09-30.png)
shows upright panels following their bus faces. It still reports rendering
Degraded and is a geometry review, not final material/render acceptance.
The [minimal relationship assembly proposal](../contracts/declarative-assembly.md)
uses existing named-frame tools; no new CAD solver or loader is implemented.

## Current renderer evidence

The degraded-rendering flag in the earlier preview was a binary/assets version
mismatch: the layered shader declared group-3 bindings 12–15, while the older
running binary had no corresponding layout bindings. Current `terrain` source
already includes those slots in `ShaderMaterial`; no Rust changes were needed.
A fresh build from `b6c31b8da95b5202814f144f2adf1038a52ef917` completed and
an owned windowed session on port 49735 rendered the Griffin/FLIP review scene.
Its log has no wgpu validation error and the
[new screenshot](../handover/griffin-render-review-2026-09-30.png)
has no degraded-rendering banner. This establishes recovered rendering, not
finished materials or acceptance of the landing dynamics. The old screenshot
is retained as the explicit earlier diagnostic state.

The fresh visual gate passes 95 checks on the current renderer build. It now
checks source-counted visible tread members and rails separately from the
invisible Mesh collision tracks. Requiring those proxy tracks to be visible
contradicted the authored render/contact separation. Review placement values
are read from the gate's selected source snapshot; the final rerun has no
scenario startup exception. This is presentation topology evidence only.

## Reusable model cleanup and remaining packaging correction

The visible solid cylinder `PayloadAdapter/AdapterRing` was an obsolete
comparison primitive above the maintained `Bus/RoverPayloadDeck`. The typed
Editor cleanup removes that render-only cylinder and retains `AdapterPlate`'s
physical interface. Four `MliTank` shells now bind to the already authored
`MliFoil_Mat` shader. Its optical parameters are appearance estimates, not
measured Griffin blanket properties; GR-033 records that boundary and the
concept-image sources. The updated visual gate passes 100 checks, including
four material relationships and absence of the old disc.

[Astrobotic Payload User's Guide, August 2021 version 5.02, page 25](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf)
shows the aluminum bus, large deck openings, radiators and a central upper cone.
The text explicitly identifies that upper-cone configuration as designed for
VIPER and says the payload mounting interface is mission-specific. It does
not establish a FLIP adapter ICD. That evidence supports an open structural
layout around the tanks; the current broad solid rover platform is still a
study assumption that hides much of the domes. Revise that packaging rather
than claiming the current silhouette is accepted. The scoped public-model
search found reference imagery and user-guide drawings, not a downloadable
Griffin engineering model on the inspected official pages.

[Settled model cleanup preview](../handover/griffin-model-cleanup-2026-09-30.png)
uses matching document/projected generation 17. It confirms disc removal, but
is not final finish acceptance: insulation visibility, structural detail and
materials still need visual work. The fresh powered-descent diagnostic was
stopped when the user reprioritized the 3D model; it established preflight and
powered-descent startup, not an accepted landing.

### FLIP wheel ownership correction, 2026-09-30

Four wheel stations remain. Each physical wheel cylinder is now the sole tire geometry source; the redundant three-cylinder visual component is removed. LunCoSim's `spawn_wheel_visual` already transfers the source mesh to a render child driven by suspension and spin. The shared selected tire material supplies tread, rim and hub appearance. Source: simulator `skills/build-vehicle/SKILL.md`, `crates/lunco-usd-sim/src/lib.rs`, `assets/components/mobility/wheel.usda` and `assets/components/mobility/tires/regolith.usda`, inspected 2026-09-30. Existing 0.45 m radius and 0.28 m width remain explicit reconstruction estimates, not newly sourced flight dimensions. Animation must preserve the authored Z axle; a fixed X-axle visual rotation is invalid. Static ownership checks do not establish dynamic acceptance.

## Landing-gear reconstruction, 2026-09-30

The user-supplied [Pittsburgh Technology Council Griffin hardware photograph](https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png)
was reviewed on 2026-09-30. It supports a slender primary shock member from the
outer body frame to the foot and two diagonal braces spreading to separated
underside/frame attachments. It does not support three thick, almost parallel
members. The photograph has no calibrated scale or identified hardware revision;
attachment coordinates, tube diameters and pad thickness must remain explicit
packaging estimates, with endpoints derived from the body/skirt datums.

The large central tapered item beneath the vehicle must not be used as an
individual engine-bell reference. The Astrobotic PUG page 25 distinguishes a
launch-vehicle adapter from payload interfaces. Exact correspondence of this
photographed item to flight engine/skirt hardware is unconfirmed. The engine/skirt proxies still need a separate geometry pass. The leg reconstruction below is a study model, not structural qualification.


Each local leg frame uses +X outward, +Y upward and Z tangential. The primary
member runs from `(-0.10, 0.12, 0)` on the outer body mount to the foot hub
`(0, -1.13, 0)`. Two braces run from `(-0.40, -0.10, ±0.68)` on separated
skirt/frame mounts to that same hub. With the existing root at radial 1.90 m
and Y=1.20 m, these mounts meet the body frame near radial 1.80 m/Y=1.32 m
and the skirt rail at radial 1.50 m/Y=1.10 m. These coordinates are estimated
from the current assembly's attachment surfaces, informed by the photograph's
three-member topology; they are not measured flight datums. Length, midpoint
and Euler rotation are derived from those endpoints rather than independently
estimated angles.

Primary diameter 0.12 m and brace diameter 0.07 m are visual packaging estimates
chosen to show the photograph's slender members. Pad diameter remains 0.70 m;
its thickness is reduced to 0.04 m and its centre moves to Y=-1.19 m, preserving
the previous underside at Y=-1.21 m. The 0.42 × 0.04 × 0.36 m foot plate
meets the hub at Y=-1.13 m. Clevises are reduced to 0.16 × 0.16 × 0.12 m.
These section and fitting dimensions remain uncalibrated estimates; material,
wall thickness, shock travel and load capacity are unavailable.

The observer measures transformed cylinder endpoints against source-owned
anchors with a 2 mm reconstruction tolerance. Owner-document readback at
generation 157 measured maximum closure error 2.24e-16 m. The Editor preview
and the canonical scene-query projection have distinct owners: the latter
returned an older generation during live editing, so its stale values were
not accepted as current geometry evidence. A fresh fixture is required for
composed-stage acceptance. The existing prismatic leg body moves the complete
visual leg together; independently articulated upper mounts are not qualified.


Fresh production leg verification passed 153/153 checks over ten requirements,
including all twelve actual member endpoint closures and the four source-linked
contact pads (`--max-ticks 120 --readiness-timeout 30`, verdict after six ticks).
The observer selects its component requirements and inputs through the existing
SysML selection API; loading the complete Twin catalog exhausted Rhai's operation
budget before reporting. Limits were not increased. The saved component and
vehicle were reviewed in a rebuilt Editor at matching document/projected
generation 0: [isolated leg](../handover/griffin-three-member-leg-crisp-2026-09-30.png)
and [assembly](../handover/griffin-leg-assembly-crisp-2026-09-30.png). Editor bloom
is disabled by authored render policy. Full visual-scene checks also passed
112/112. These are geometry/ownership checks; landing dynamics and upper-mount
articulation remain outside this acceptance.

## Engine and exhaust reconstruction, 2026-09-30

[Astrobotic Payload User Guide, January 2022, page 26](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf)
specifies five 700 lbf pulsed main engines, twelve 25 lbf attitude engines,
pressure-fed M20 fuel and MON3 oxidizer, and two tanks for each reactant. The
previous seven-engine interpretation was wrong. Requirements and USD now use
five main engines. Centre plus four cardinal stations at radius 1.05 m are an
explicit symmetric packaging estimate; the guide is not a mounting drawing.
The existing feed/pump/chamber parameters still represent a generic study
network, with aggregate thrust capability above the published five-engine
rating. They do not validate Griffin's flight propulsion performance.

The nozzle is an open hollow revolved bell with 0.12 m throat radius, 0.34 m
exit radius and 0.52 m height. These dimensions are reconstruction estimates.
The profile follows the library BellNozzle power law with exponent 0.55;
16 axial intervals sampled quadratically concentrate resolution near the throat,
and 48 angular segments reduce visible facets. A 6 mm visual wall is estimated
for a legible rim; it is not a qualified wall thickness. The outer radius is the
current presentation/design datum. [NASA nozzle design](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/nozzle-design/)
supports the throat and expanding exit topology, not these dimensions or an
optimized manufacturer contour.

The engine component inherits exhaust from LunCoSim's standard engine library.
The Twin supplies only nozzle-exit placement and physics connections. Modelica
derives metric plume dimensions from nozzle radius, nominal thrust and exhaust
velocity, and publishes delivered activity, colour and light. Hypergolic fuel
family comes from M20/MON3 in the guide. Reference O/F 2.0, RGB palette anchors,
1000 Pa visibility threshold, radial expansion 1.6 and core radius fraction 0.65
are explicit visualization estimates, chosen for a readable pressure-based
jet with a warmer fuel-rich palette. They are not calibrated spectra or CFD.

The fuel-exhaustion fixture starts the unchanged Griffin network with 5 kg fuel
and 100 kg oxidizer, sufficient to observe a burn followed by fuel starvation
within three simulated seconds. The command remains on and oxidizer continues
flowing. Tank availability reduces fuel feed; mixture efficiency makes useful
combustion, heat and thrust zero; zero delivered jet momentum makes plume
activity, visible length and luminous power zero. No scenario calculates flame
state or changes visibility. The regression observes both a positive burn and
the exact dark endpoint. Omitted Modelica library defaults must survive the
first physics step; the core lifecycle bridge now reads initialized solver
values rather than replacing those inputs with zero.

Current geometry/dataflow verification covers 115 checks. The twelve attitude
engine visuals still use the older Twin-owned hidden presentation and require
a subsequent shared-library migration; they are not included in the main-engine
exhaust cutover or this depletion acceptance.

Fresh rebuilt production evidence: fuel-exhaustion regression 7/7 checks at
180 ticks (3 s), shared plume defaults 11/11 at 120 ticks (2 s), and Griffin
propulsion geometry/dataflow 115/115 at 12 ticks. The existing lander feed/valve
spool regression also passed. These do not accept landing or propulsion ratings.
The Editor's saved nozzle document and projected generation both read 0 in a
fresh session; the [current bell review](../handover/griffin-five-engine-bell-2026-09-30.png)
shows the curved shell with remaining flat-shaded facets. Smooth normals and
finer material work remain visual improvements, not completed acceptance.
