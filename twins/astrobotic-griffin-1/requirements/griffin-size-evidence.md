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
| Footprint across opposed pad edges | 7.24 m | 4.50 m | Diagonal foot stations at X/Z=+/-1.90 m plus 0.35 m pad radii on each side; selected to match the historical envelope approximately. Current footprint unconfirmed. |
| Payload adapter | 4.40 × 3.20 m | 3.20 × 3.20 m | Estimated octagonal footprint fitting inside the bus and covering the reconstructed FLIP wheels after clipping the corners. 80 mm stock is an explicit silhouette estimate; center Y2.04 preserves the Y2.08 contact top. |
| FLIP body | 4.40 × 2.76 m lower frame | 2.116 × 1.476 m | Promote the estimated CAD plan dimensions with an explicit axis mapping. Allow approximately 20% dimensional uncertainty. The 0.12 m lower-frame height is a visualization/collision proxy; equipment box height 0.396 m comes from CAD. |
| FLIP wheel envelope | legacy inconsistent envelope | 2.28 m across track; 2.60 m along travel | Derived from 2.0 m track + 0.28 m tire width and 1.7 m wheelbase + two 0.45 m radii. Wheel ribs, deformation and suspension travel excluded. |
| Ramp length | 12.228605 m | 5.397252161 m | Derived: 2.52 / sin(0.4857867749). Retain the previous **estimated** 27.8335° deployment angle to isolate the height correction; not a published ramp slope. At 2.0–3.0 m deck heights this gives 4.28–6.43 m. |
| Each of three sections | 4.076201667 m | 1.799084054 m | Total length / 3. Three-section folding topology remains a study assumption. |
| Ramp outside width | 3.50 m | 2.592 m | 2.00 m track + 0.58 m contact-track width + two 0.006 m rails. Derived from the current outer rail edges; 2.86 m belonged to the superseded 140 mm rails. Contact width is 0.28 m wheel + twice 0.15 m estimated clearance. |
| Deck transition | 1.96327 m | 0.90 m | Estimated bridge to the octagonal deck: outboard X=1.90, inboard X=1.00. Width follows the current 2.592 m rail corridor; GRR-012 checks composed deck overlap against the 0.05 m study requirement. |

The vehicle touchdown reference remains 0.44 m. Adapter center Y=2.04 plus
half-thickness 0.04 gives a vehicle-local top of 2.08 m, hence 2.52 m above
ground. A ramp half-thickness of 0.015 m yields hinge X=1.90+0.015 sin(angle),
Y=2.08−0.015 cos(angle); the builder's toe miter closes both contact edges.
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

Current rail chord top is 0.20 m above the walking plane, about 0.11 of
its 1.799 m section length. Upper strips are 40 mm high, lower strips 20 mm,
end posts and diagonals 12 mm in-plane, all with a 6 mm transverse web.
Twelve alternating diagonal bays per guide, rounded strip tips and rounded
pivot lugs reconstruct the concept silhouette. These are low-confidence image
estimates, not structural sizing. The 30 mm contact thickness, wheel clearance,
length, deployment angle and 95 kg ramp mass proxy remain study assumptions.
Current rail width and rectangular-envelope inertia derive together from the
outer rail edges. The two 15 kg transition proxies use that same width.
Reference rechecked 2026-10-01: https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png .

The shared `usd_geometry_inspection` library owns the read-only fixed-tick USD
query contract and composed scene-owner lookup. Bus and visual gates do not
rely on Editor tab focus; the ramp stow gate uses the same dependencies.


Historical focused evidence (before the subsequent rail refinements): the bus gate passed 339 checks, the solar gate passed
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

The numerical reconstruction in this historical section is superseded by the
2026-10-01 suspension review below. Its earlier endpoint check establishes only
that earlier geometry, not acceptance of the revised mechanism.

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

[Astrobotic Payload User Guide, August 2021 v5.02, page 26 (hosted January 2022)](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf)
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
The neck is also a hollow revolved shell, using the same estimated 6 mm
visual wall. Its lower rim is seated at the bell throat plane (.26 m local Y);
its 160 mm height derives a .34 m centre and .42 m upper rim. The adapter plate
lower face follows that upper rim. This replaces the old capped cylinder that
intruded into and visually closed the flow bore. The requirement observer
measures both meshes and rejects a face closing either bore.

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

The 35-degree bell shading crease is a rendering estimate: adjacent curved-wall normals are averaged, while the thin open rim retains its sharp edge. It changes shading only, not the source-derived envelope or mesh topology.

### Ramp rail stock review, 2026-09-30

The user identified overly thick rails. The [ESA artist impression](https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander) and [Astrobotic product rendering](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/) show slender truss members, with compact fittings rather than large transverse pipes. Perspective and unknown stock sizes prevent a calibrated measurement. The revised estimates are 40 mm upper chords, 35 mm lower chord depth, 25 mm posts, 18 mm diagonal thickness, 50 mm hinge/pin diameter and 60 by 45 mm underside beams. Upper chord depth is 2.2% of the 1.799 m section length; previous 80 mm depth was 4.4%. The 240 mm hinge barrels were particularly oversized. Walking contact thickness, ramp span, deployment poses and physical hinge datums remain the existing contract. These changes improve the rendered structural silhouette; they do not establish structural strength.

The interface width check now compares transition coverage with the ramp travel corridor, rather than the wider 3.20 m payload adapter. It retains the existing 2 mm composed-geometry tolerance. Wheel-track width is derived from the rover tire width plus twice the source clearance, avoiding a rounded duplicate decimal at the exact clearance limit. The separate bus collider/profile compatibility check remains required.


### Bus support datum and collider review, 2026-09-30

The upper bucket had an additional 2.076445 m local translation despite its mesh already carrying the bus-frame vertical datums. This detached it from the payload support. The instance translation is now zero; the builder resets bucket transforms and the bus gate checks identity placement. The convention is derived from the authored profile coordinates, not from photo metrology.

Avian's convex cook reduces the payload adapter's 64 source points to 40 hull vertices. Requiring 64 cooked vertices incorrectly rejected equivalent geometry. The gate retains exact authored topology and point checks, then verifies finite hull vertices and support distances in 26 axis/diagonal directions within the existing 1 mm tolerance. This is an envelope check, not a proof of identical contact at every internal gap. The deployed ramp gate passes 845 checks after this correction.


### Tank packing and central adapters, 2026-09-30

The four installed vessels remain 1.008 m diameter (0.84 m reusable sphere radius times 0.60 instance scale). The old 1.51 m minimum belonged to the abandoned 0.90-scale study: four such vessels would overlap at the retained cardinal stations. The replacement 1.00 m lower bound is an explicit packing estimate, not a vendor tank dimension. Maximum retention-band diameter is 1.032 m; nearest station spacing is sqrt(2) times 0.85 = 1.202 m, leaving approximately 0.170 m between band envelopes.

Tank centers are 1.39 m; the 1.894 m sphere top exposes approximately 0.23 m above the 1.66 m skin top. The upper cap reaches 1.906 m, leaving 14 mm below the payload frame's 1.920 m underside. The 10 mm minimum clearance is an explicit visualization estimate. The ESA concept image supports exposed domes, but cannot override this reconstructed FLIP packaging constraint: https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander. The installed station and bus origin need not be identical. The cradle seats from the lower-skirt bottom plus its 20 mm estimated clearance; seating from the top would put the pad above the lower neck and yield a negative support span. The derived local post length is 40 mm, scaled once by 0.60 at installation. Braces use an estimated 12-degree mirrored tilt and 0.15 m local length. Their centers account for the actual rotation, seating their lower endpoints on the pad. A shared geometry helper supplies this relationship to authoring and observation; vessel-contact radial residual is approximately 3 mm within the 15 mm study tolerance. The tank gate also checks the upper vessel/cap-to-payload gap, since isolated tank checks cannot detect rail intersections.

The previous central flared shells swept through the COPV and peripheral nozzle columns. The new upper shell has 0.54 m maximum diameter; its 0.27 m outer radius leaves 0.064 m radial clearance to the maximum tank-band envelope at the 0.85 m station. The lower shell has 1.28 m maximum diameter, leaving 0.07 m to the peripheral full bell envelopes (1.05 m station minus 0.34 m bell radius minus 0.64 m shell radius). A 25 mm shell wall is an explicit structural visualization estimate. The PUG central adapter architecture motivates a central support, but publishes no dimensions for these FLIP reconstruction shells: https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf, August 2021 v5.02, pp.25-26. These shells are not the boundary of the engine cluster. That boundary now derives from the 3.20 m engine-skirt span. This correction preserves engine stations, bell dimensions, propulsion parameters, and thrust ownership.

## Corner leg reconstruction — 2026-09-30

The user-selected Astrobotic rendering (https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
places the legs beneath the body corners. Earlier cardinal side mounts were an
incorrect reconstruction. Four diagonal foot stations now preserve the estimated
4.50 m X/Z footprint; local +X follows each chamfer normal. Primary upper anchors
meet chamfer midpoints, below the belt. Exact positions are estimated from the
existing 3.60 m octagon, not calibrated from pixels. Tube lengths/rotations and
mount brackets derive from endpoints; the three-member load path is retained.
The footprint diagonal is larger than the X/Z span; the old description of
1.90 m radial stations no longer applies. No panel cutouts are used.

## Payload support stock — 2026-09-30

The earlier 160 mm square perimeter beams obscured the COPV domes and dominated
the silhouette. Revise stock to an estimated 80 mm, following the lighter open
structure in the user-selected Astrobotic rendering. This is not supplier
structural sizing. Keep the 3.20 m plan span and Y2.08 support top: center Y2.04
plus half-stock .04. Visual mesh and cooked contact proxy use that same source.
Wheel-track widths remain dictated by the existing FLIP packaging estimate.

The upper perimeter deck ring also uses estimated 80 mm stock; its bus-local
center rises from .37 to .41 m, preserving its .45 m upper surface. Source-driven
contact beams change together. This leaves the body envelope and solar mounts
unchanged. COPV upper-cap clearance below the payload rails increases from
14 mm to 94 mm; this is a derived consequence, not a new tank size measurement.

## Ramp walking plates — 2026-09-30

Replace the legacy 180 mm walking slab with an estimated 30 mm plate and
50 mm high traction blocks with estimated 10 mm strips (60 mm travel width).
The ESA and Astrobotic renderings linked above show thin walking structures,
but publish no plate gauge. These dimensions are visual reconstruction
estimates, not strength calculations. Physical contact meshes use the same
thickness. Hinge offsets, toe bevel, under-beam seating, transition center
and box-proxy inertias change together; the deck top, slope and terrain toe
height stay fixed. Ramp/transition masses remain explicitly unqualified proxies.

## Rectangular solar arrays and support stock — 2026-09-30

The selected [Astrobotic product rendering](https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png)
shows rectangular 14 x 5 arrays with small attachment fittings. This pass
replaces the notch inferred from a different hardware revision with a full
cell field. Panel height/width and installed bus datums are retained.
Frame stock 30 mm, backplane 12 mm, visual cell surface 2 mm, divider relief
1 mm, bracket envelope 100 x 80 x 120 mm and hinge diameter 50 mm are explicit
appearance estimates. They do not describe qualified laminate or mechanisms.
The support link spans the unchanged 220 mm standoff; 10 mm overlap checks
visible seating only. Dark cell color and finish values are artistic estimates.

Eight later-created dividers had scale-before-translation USD transforms,
which compressed their metric spacing while raw position attributes appeared
correct. The component cube planner now authors translate/rotate/scale order;
a targeted solar regression checks the affected final divider. The complete
grid and slim fittings were reviewed in a freshly composed vehicle preview.

## Ramp plates, compact trusses and hinge shafts — 2026-09-30

The walking plate now uses the same visible Mesh as physical contact. Sparse
traction bars are details on the plate, not a replacement for it. This fixes
the floating bars seen when the contact mesh was hidden; no duplicate visual
track was created. The silver-gray display color is an appearance estimate.

Upper chord center is estimated at 180 mm above the track datum, replacing
the 340 mm elevation inherited from the thick slab. With 40 mm upper stock
and the 55 mm lower-chord center, the triangulated web depth is 125 mm. This
is a silhouette estimate informed by the selected
[Astrobotic rendering](https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png),
not a supplier truss drawing. Fold-axis clearance now derives from the
200 mm chord top. The contact span, root stow angle, mass proxy and deployed
plane are retained.

The obsolete −180 mm shaft elevation left detached crossbars. Root shaft
Y is zero at the deck pivot, middle shaft Y derives from upper chord top,
and toe shaft Y derives from the plate bottom. These match the section
revolute frame datums and are shared by native joint placement and shaft
appearance. Deployed ramp and folded-rail gates passed for these changes;
rendered review shows continuous tracks and closer-packed folded trusses.

### Tank support surface ownership, 2026-10-01

The three tank-support perimeters and twelve annular collars now bind two
reusable standard USD materials inside the bus component. Their existing
source-owned tankSupportDisplayColor and tankCollarDisplayColor supply the
palette; silverMetallic and silverRoughness supply the shared inspection finish.
These are artistic appearance estimates chosen to distinguish structure from
gold tank blankets, informed by the supplied ESA rendering:
https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander.
They are not measured optical constants, an alloy selection or evidence of
hardware qualification. The 120 mm ring section and annular radii were retained:
reducing the collar outer radius alone would break its reconstructed connection
to the perimeter. Tank clearances and existing datums remain the geometry basis.

### Griffin high-gain antenna, 2026-10-01

Astrobotic Payload User Guide August 2021 v5.02, page 30, explicitly labels
Griffin's high-gain dish and medium-gain antenna and describes multiple low-gain
antennas with an actuated medium/high-gain antenna after touchdown:
https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf.
The 2022 ESA image is an integrated artist's impression; its elevated payload
mast does not establish a Griffin bus mast dimension. The model now reuses the
parked shared CommsAntenna for the bus-edge dish rather than a hidden placeholder.

Its 0.60 head scale gives 0.696 m diameter from the library reflector's 0.58 m
radius. This is a low-confidence image-proportion estimate (about one fifth of
the selected 3.60 m bus), not a published antenna diameter. A 180 mm pedestal
with 25 mm radius gives a slender, compact deck mounting; both dimensions are
packaging estimates. The parked -70 degree X tilt points outward toward -Z;
it is a review pose, not an Earth direction. The mount derives from bodyMount,
deckCenter and deckDimensions: Y is the deck top, Z is the negative edge stock
midline. Current resulting station is (0,1.79,-1.71) m. Head scale and mount are
kept separate so the reflector estimate cannot rescale the bus or pedestal.
Yaw/elevation bodies and tracking stay in the library's disabled parked state;
operational pointing, actuator sizing and antenna mass qualification are open.
The medium- and low-gain hardware remains to be reconstructed from evidence.

### Integrated Editor preview isolation, 2026-10-01

The saved Griffin-FLIP composition is georeferenced; its authored vehicle
station still reads (0,0,0) in canonical stage coordinates. In the owned
Editor preview, FrameUsdPreviewSelection instead targeted approximately
(-51650.75,-1725515.25,195171.97) m, and the resulting image showed rotated,
severely distorted fine geometry. The same saved Griffin asset renders normally
in its local component preview. Evidence images:
/tmp/griffin-flip-composed-review.png (fixed local preset missed the scene),
/tmp/griffin-flip-framed-review.png (framed integrated scene).

This is evidence of a preview projection/frame problem, not evidence that the
saved leg/ramp shapes need compensating transforms. Current owner investigation
found project_celestial_comms_prims in terrain/crates/lunco-usd-sim-celestial/src/lib.rs
has no UsdPreviewOnly ancestry guard. Other simulation adapters reuse
is_preview_only from lunco-usd-bevy-scene. Celestial placement can establish a
site grid and ActivePhysicsFrame, while the preview camera is an ordinary local
Transform. Preview scene isolation is now explicit in GV001. The missing guard
is a leading cause pending a regression test and rebuilt headful confirmation;
no flight/site coordinates were altered to hide the symptom.

The same PUG used for the dish provides further communications evidence:
https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf,
August2021 v5.02 pp20/30. Page20 depicts Peregrine medium gain as a flat panel
and low gain as a small flush patch; page30 labels Griffin's medium gain at its
bus edge and says the communications system can share Peregrine specifications.
Those references motivate examining panel/patch geometry, not adding more
parabolic dishes. Griffin-specific antenna dimensions, count and mounting
interfaces remain unestablished; they must not be copied from Peregrine as
verified Griffin hardware.

#### Preview isolation resolved

Terrain commit a7707995c reuses the existing is_preview_only ancestry guard in
the celestial projector. The focused regression first reproduced preview work
admission, then passed after the guard; all ten adapter tests pass. A rebuilt
owned Editor now renders the unchanged combined scene correctly from the local
rear preset. Selection framing returns approximately (0,.26218,0) m, rather than
lunar-radius coordinates. The preview root is not a live UsdSceneRoot; its
previous authored anchor entered the generic geodetic placement path. This
clarifies the earlier SiteAnchor/ActivePhysicsFrame hypothesis: no active-frame
mutation was proven in this preview. The correction prevents all celestial and
link domain admission under the preview marker. Mission georeferencing remains
owned by the live scene. The production visual fixture passes with the rebuilt
binary, while landing and egress remain separate open evidence.
Saved visual evidence: ../handover/griffin-flip-preview-fixed-2026-10-01.png.

#### Landed ramp targets and terrain contact (2026-10-01)

The ±0.4857867749 rad root angles remain the nominal flat-plane CAD datums.
They shall not be unconditional motor commands on the NOBILE03 DEM. The
owned replay of core `24dd835fa` and Twin `fec3026` landed with body Y
0.365507 m and upright-axis Y 0.996980044 (about 4.45° tilt), rather than the
static Y 0.44 m assumption. The middle/toe unfolding stages passed, but final
toe rates exceeded the unchanged 0.02 rad/s gate at tick 19196.

Source geometry transformed by the recorded native toe poses gives tip X
about +6.89…+6.97 m and −6.57…−6.65 m. These tips are outside the existing
12 m square pad. Retained DEM samples at those corners range from −0.235929
to +0.355317 m; opposite outer corners coincide with the recorded toe heights
to about 1 mm. This supports terrain contact as the reason nominal angle
commands load the deployed bundle; it does not prove a complete contact-force
or solver diagnosis.

Runtime planning therefore uses each measured root hinge frame, the existing
track length/width/thickness and nominal toe miter, and the retained DEM under
all eight toe corners. The pad top participates where its source footprint
applies and is higher. Targets stay inside the existing travel and reserve
half the existing 20 mm contact tolerance as a 10 mm predicted minimum gap.
This allowance is an explicit study estimate for section alignment and
elastic deflection; it is not a supplier clearance or locking specification.
Missing terrain or an unbracketed target prevents release. Existing angle,
rate and dwell limits are retained. The planner uses commanded joints, never
forced body poses or a separate visual animation.

Evidence and exact replay status: [landed ramp checkpoint](../../../handover/griffin-landed-ramp-contact-2026-10-01.md).

#### FLIP frame inconsistency exposed by egress (2026-10-01)

The dependency-corrected replay of Twin `985b084` and core `24dd835fa` again
passed ramp deployment and release, then failed `GR-004-route-stall` at tick
12762. The X-forward CAD reconstruction and its Z wheel axles must define the
same travel direction for physical tire forces, wheel spin, steering and
Modelica guidance. Current native wheel/guidance code instead assumes −Z
forward. Guidance reported a 2.222700 rad heading error and zero throttle for
the fixed (2,0,0) m target. Source: the owned native route-failure packet and
trace recorded in the [landed ramp checkpoint](../../../handover/griffin-landed-ramp-contact-2026-10-01.md).
This is an implementation inconsistency, not a new supplier datum or a reason
to increase motor torque. The existing X-forward reconstruction remains a
study frame; a corrected realization must explicitly transform that frame or
consume it consistently in both navigation and wheel contact. The first two
scene-fixed egress markers must also be checked against the landed ramp
centerline. Full rover egress and rendered mission acceptance remain open.

#### Operator scene and egress-frame correction (2026-10-01)

The default Twin scene is the live surface-operations mission. Griffin uses
`vehicle-control-left` with possessed visibility, matching the core lander HUD
contract. Space commands main thrust; W/S, A/D and Q/E command pitch, roll and
yaw. U requests the existing gated ramp sequence; F requests the existing gated
payload release via the source-scoped action intent. These are study UI choices,
not spacecraft hardware requirements. Release still requires landed support and
measured ramp settlement.

The visual-review scene is explicitly static on a flat render-only datum. Its
0.44 m body height and 0.47 m leg-mount height come from the existing spring-rest
geometry: 0.9 m mount minus 0.43 m spring target, minus 0.89 m foot offset and
0.02 m pad half-height. All referenced leg/ramp bodies are disabled there to
prevent gravity from moving children under a frozen parent. The live mission
retains its terrain and physical suspension.

The correction keeps the +X study travel frame: Cylinder Z axle crossed with
steering Y gives +X, and guidance receives a −π/2 yaw offset from SysML. Front
axle names now occupy positive X. The first two route gates use their existing
source distances from the port root mount, projected along the actual landed
ramp direction; later survey gates retain their scene frame. This relation is
estimated mission policy justified by the observed landed tilt and route stall,
not a supplier navigation ICD. Runtime acceptance remains pending a fresh replay.

Replay-2 (core abdcbf909) reached the apron at x=13.17 m, then failed the
unchanged stall gate at tick 28045. The front-left ray origin was Y=-0.126 m
inside the Y=0 apron, with no hits; other wheels carried valid contact. The
old 0.30 m extension estimate had been used as total ray length despite a
0.45 m wheel radius. The corrected relation is radius plus the same estimated
0.30 m extension (0.75 m); the native spring law and tire torque are unchanged.
Source: `/tmp/griffin-egress-frame-evidence.json`, native PhysicsWheelContact
snapshot, and core `strut_offset(rest_length, wheel_radius)` contract.

Replay-3 with this relation passed the physical ramp exit and confirmed four
supported wheels on departure. It later failed a survey-waypoint stall at
simulation tick 20293; full mission acceptance remains open. The fresh operator
check accepted U after touchdown and routed F to the existing ramp-settlement
gate without an event error. Sources: owned logs linked in the handover.

#### Camera focus and route-limit units (2026-10-01)

The Griffin control camera orbits the payload adapter top: local height is
adapter center Y (2.04 m) plus half its source thickness (0.08 m), hence
2.08 m above the vehicle root. This is a presentation choice requested for
inspection of the rover attachment, derived from the same estimated packaging
geometry; it is not supplier camera data. The core control profile authors
`lunco:cameraFollowHeight`, using the existing spring-arm vertical focus offset.
Camera collision probes and arm distance are measured from that focus.

The route command table is now named `surfaceRouteThrottleLimit`, because
`RoverAutopilotGuidance.mo` treats its speed input as normalized throttle,
scaling it further by heading alignment and distance-to-target. The former
m/s identifier and claim of measured vehicle speeds were incorrect. Limits
0.14–0.35 remain uncalibrated study estimates; observed motion additionally
depends on motor torque, gearing, slope, contact and steering. No supplier speed
claim or closed-loop speed regulation follows from that table.

### Thin foot-pad collision policy (2026-10-01)

The reported operator scene showed a leg below the surface. In the owned
pre-change runtime, LegNZ's composed physical pad center reached Y=-0.3949 m
inside the landing-pad footprint. The proxy was enabled and matched the
visible 0.35 m radius, 0.04 m tall cylinder; shifting the visible leg would
therefore conceal a physical contact failure.

Ordinary USD rigid-body projection lacked authored CCD support, whereas
LunCoSim's native wheel projection already installs Avian swept CCD. Griffin's
leg physics component now authors `physxRigidBody:enableCCD = true`, inherited
by all four bodies. The generic bridge projects that flag to Avian 0.7
nonlinear SweptCcd. This is an explicit numerical anti-tunneling choice for the
40 mm pads and 100 mm scene slab, not a published Astrobotic hardware value.
Canonical flag reference:
https://docs.omniverse.nvidia.com/kit/docs/omni_physics/107.2/dev_guide/schemas/physxschema.html
The existing leg geometry plan and observation read/check the typed SysML
policy; no extra visible pad, height correction or terrain offset was added.

Focused projection tests passed (7). In a new headful run after manual control
was acquired with zero throttle, foot centers were PX=0.3444, NX=0.04114,
PZ=0.34186, NZ=0.04121 m. NX/NZ had native slab contact; PX/PZ rested on higher
retained DEM relief. The slab contact sample reported about 4 mm solver
penetration, rather than the previous roughly 0.4 m burial. The close rendered
view confirmed the near feet on the surface. This is bounded landing/contact
evidence; it does not qualify arbitrary crash speeds, unpublished shock
kinematics, or the complete surface mission.

#### Manual mechanism authority and landed indication (2026-10-01)

Source: explicit operator request on 2026-10-01 that ramp opening and rover
detachment remain available in every flight/landing phase. This is simulator
operator policy, not an Astrobotic flight interlock specification. U and the
OPEN RAMPS HUD action run the existing middle/toe/root physical sequence in
parallel with landing. F on the lander and DETACH ROVER request native adapter
joint retirement immediately; repeated requests are idempotent. The HUD keeps
both actions enabled while the rover is selected; rover F retains autopilot
control. Finite angles, physical travel limits and measured mechanism settlement
remain enforced. The unattended mission retains its GNC handoff, physical
landing, post-touchdown dwell, settlement and solver-retirement acceptance gates.

The original standing vehicle already had touchdown=1, landing_contact=1 and
all_legs_contact=1, but landing_handoff=0. The old operator policy conflated
physical landing with the automatic guidance latch. Landed indication now reads
Modelica landing_contact directly and observes its current value as well as the
touchdown event, including after a script reload. Source:
LunCoSim assets/models/Lander.mo, landing_contact/settled_touchdown_target
equations. Those equations already qualify four-pad contact, upright attitude,
ground/descent speed, angular rate and suspension rate. No physical detection
threshold was weakened. Interactive status uses the existing task scheduler
at 0.1 simulated seconds; this is a replaceable display sampling choice, not
a control equation or supplier datum.

Airborne opening uses the existing SysML nominal deployment angles
(-0.4857867749 / +0.4857867749 rad) as a mechanism pose. Rationale: terrain may
be beyond ramp travel during flight, so terrain-contact fitting would falsely
reject an available manual command. Once physically landed, the planner uses
the measured root frames and retained DEM. An airborne pose never establishes
traversable egress or terrain contact.

Bounded owned run on port 49747: both manual requests were accepted with
landing_contact=0 and landing_handoff=0; the solver retired the adapter edge
and both middle sections, toes and roots received their physical targets. A
repeat detach request was accepted with the joint already absent. This airborne
run did not meet the existing root-settlement deadline, so complete mechanical
settlement/egress is not claimed. Sources: /tmp/griffin-manual-actions.json,
/tmp/griffin-manual-effects.json and /tmp/griffin-manual-policy-acceptance.log.
A separate grounded run reported landing_contact=1 and all_legs_contact=1; the
HUD displayed TOUCHDOWN CONFIRMED with both action buttons enabled. Sources:
/tmp/griffin-manual-landed-status.json, /tmp/griffin-manual-landed-acceptance.log
and terrain/griffin-manual-landed-controls.png. That second run had completed
an automatic handoff; the original no-handoff snapshot and the new single-port
status reader establish why handoff is no longer an operator prerequisite.
The Rhai sources compiled and the provenance gate passed (207 requirements,
207 evidence records). Full mission acceptance remains open.

## Suspension and panel reference review, 2026-10-01

| Reference | What it supports | What remains estimated |
|---|---|---|
| [Pittsburgh Technology Council hardware photograph](https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png) | One primary member and two separated diagonal braces converge at each foot; upper attachments belong to the bus/frame. | Hardware revision, calibrated dimensions, internal shock construction, hinge axes, travel and spring properties. Perspective cannot establish these values. |
| [Astrobotic Griffin lander description](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/) | Four shock-absorbing legs; manufacturer context for the lander. | A released linkage diagram, landing-gear stiffness or exact attachment coordinates. |
| [Astrobotic product image](https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png) | The user counted 14 cell columns and 5 rows on the broad panel; supports a shallow rectangular panel and slender folded ramps. | Cell pitch in metres and the layout on narrower faces. This older concept rendering is not current flight-panel metrology. |
| [ESA Griffin artist impression, 23 September 2022](https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander) | The user-marked broad bus face is approximately 3:1 in width/height; appearance reference for ramps and exposed tank domes. | Absolute dimensions, hidden mechanisms and structural stock sizes. Perspective and artistic rendering limit precision. |

The previous vertical prismatic joint translated the whole leg, including its
upper brackets. That violates the reconstructed fixed attachment load path.
The revised **proposed** mechanism uses a rigid V-brace/foot assembly pivoting
about its two skirt mounts, plus a primary shock with upper and lower pins and
an axial barrel/piston slider. This is a mechanically motivated idealization
of the visible three-member topology, not a linkage disclosed by Astrobotic.
The image alone does not prove the joint arrangement.

The typed leg requirements now describe a zero-seated nominal shock, 150 mm
compression allowance, 20 mm rebound, 40 kN/m axial stiffness and 8 kNs/m
damping. At an estimated 2.2 kN per leg, the stiffness gives approximately
55 mm static compression **before linkage leverage**. These are replaceable
simulation study values, not measured supplier properties. The existing
180 kg per-leg mass proxy is split into 160 kg brace/foot and two 10 kg shock
bodies to preserve the previous mass budget; no flight mass measurement
supports that allocation. The 45-degree pin limits and barrel/piston length
fractions likewise remain packaging estimates.

The nominal foot hub moves to local Y=-1.26 m and pad centre to -1.32 m while
the upper anchors remain fixed. With vehicle Y=0.44 m, leg station Y=0.90 m
and 40 mm pad thickness, the nominal pad underside is
0.44 + 0.90 - 1.32 - 0.02 = 0 m. This preserves the reconstruction's ground
datum without translating the bus-side brackets. It does not predict loaded
settlement; that needs articulated physics verification.

For panels, a narrow face must not gain a different cell aspect ratio merely
by stretching the same 14-column module. Consistent cell pitch and a reduced
column count on narrow faces are the proposed reconstruction rule. The exact
flight cell count on those faces is unavailable. The hardware photo and older
concept rendering show different panel configurations; their layouts must not
be combined as if they documented the same revision.

Status: mechanism assembly, panel refinement and revised geometry/physics
checks remain in progress. The earlier leg test counts and manual ramp-command
acceptance above do not establish acceptance of these proposed changes or a
fully settled ramp/egress sequence.

The revised leg assembly is now saved through the typed USD document API.
The standalone production leg fixture passed at tick 6 with the revised
topology, nominal joint-frame closure, fixed bus mounts and zero-seated axial
spring checks (`/tmp/griffin-gear-fixture-2.log`). Maximum measured nominal
joint separation was approximately 6e-8 m and rotation residual 1.71e-6 degrees.
The visual-review scene explicitly disables both added shock bodies and uses
the same nominal leg station as the vehicle. These are assembly checks;
loaded suspension, impact absorption and powered landing remain unverified.

The subsequent owned powered-descent run emitted physical touchdown at
38.1167 simulated seconds and automatic flight handoff at 38.2167 seconds
with the revised gear (`griffin-gear-mission.log`). The status task also
reported touchdown confirmed. This demonstrates a working handoff in that
run; it does not establish a sustained settling horizon or completed egress.

The panel refinement is now saved in the vehicle. Installed broad-face width
is capped at the source-owned 1.716 m maximum, correcting the previous
1.866 m inflation. The bevel retains its rail-derived approximately 0.857 m
frame width. Source cell pitch is 1.596/14 = 0.114 m by 0.58/5 = 0.116 m.
After reserving the nominal 0.120 m total border allowance, six columns fit
the bevel; its active width is 0.684 m. Broad faces retain 14 columns and
1.596 m active width. These pitches and border dimensions are explicit
reconstruction estimates based on the user-counted grid in the linked 2021
Astrobotic rendering, not calibrated hardware measurements.

Compact brackets remain seated on the bus rail datums. Their lateral size is
compensated for the panel instance scale, and each inclined support link is
derived from its rail attachment and panel edge rather than moving the bus
rails to fit the smaller frame. The production solar fixture passed with
metric grid spacing, panel envelopes and mount-path overlap checks
(`griffin-solar-fixture-4.log`). The rendered review confirms the narrow panel
uses six columns with approximately square cells rather than fourteen
compressed columns. Flight electrical area, power and deployment mechanism
acceptance remain outside this appearance reconstruction.

## Loaded suspension estimate correction — 2026-10-01

The appearance reconstruction's pivot coordinates need a load-aware shock
estimate. This is an analytical correction to a study proxy, not a measurement
of Griffin hardware. With upper shock pin A, midpoint skirt pivot B and foot
hub C from `GriffinLandingLegAssembly`, the nominal lengths are |A-C|=1.426417 m,
|B-C|=1.751114 m and |A-B|=0.445818 m. The triangle becomes straight when the
shock shortens by 0.121120 m. The former 0.150 m allowed compression was
geometrically impossible; a loaded owned readback reached 0.1176–0.1192 m,
near that singularity, after the body had dropped below its nominal datum.

Differentiating the fixed-brace and shock-length constraints at C gives
|dC_y/dL|=3.27427. The measured attached assembly mass, 5510 kg, under the
1.62 m/s² lunar study gravity gives 2231.55 N per leg and roughly 7306.7 N
axial shock load. A rounded 400 kN/m stiffness predicts 18.3 mm initial static
stroke and about 60 mm vertical deflection under the linear approximation.
The corresponding quarter-assembly generalized axial mass gives critical
damping approximately 153.7 kNs/m, rounded to 150 kNs/m. Compression is capped
at 50 mm, before the singularity; the 12 kN force cap is retained, with impact
saturation still to be verified. Exact pivots, damping curves, mass properties
and impact capacity remain estimates. The visible arrangement reference is
[the PGH hardware image](https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png).
The builder now rejects compression travel that reaches the linkage's triangle
closure limit. These values supersede the earlier estimate that ignored leverage.


## Landing and reload audit — 2026-10-03

Fresh-process landing replay passed for the unchanged 60 m surface-contract
fixture after telemetry was stamped before delivery and shared actuator/tire
forces were ordered. Both runs recorded touchdown at tick 1406 and identical
final pose at tick 5010; all 361 post-touchdown samples had four-foot contact.
Evidence is in the terrain checkout's `target/griffin-contact-order-replay/`.
This is same-host evidence for that fixture, not flight validation.

The same-app observer `scenarios/tests/griffin_scene_restart.rhai` compares two
retained `RestartScene` trajectories. It starts each measurement only after the
replacement generation is admitted. Its 90 s window reserves 30 s for the
60 m descent at the existing estimated 2.5 m/s speed limit, plus the source-owned
60 s stability window; this is a diagnostic budget, not flight descent timing.
The retained dependency lifecycle now rebinds scene identities without
reinitializing the observer. The current live replay still fails at relative
tick 1380 near contact, despite matching earlier samples. Contact-phase
same-app determinism remains unresolved; do not report this as a passing gate.

The user requests axial leg motion along the primary connection line. The
existing pinned V-brace reconstruction permits the foot to swing during shock
compression. The hardware photograph remains the appearance reference:
https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png .
It does not establish a flight linkage or force/stroke curve. A revised axial
mechanics proxy must explicitly state its brace compliance approximation and
measure perpendicular displacement, stroke limits and attachment closure.

Fuel review: the existing vehicle starts with 1000 kg fuel and 1000 kg oxidizer,
with a 2000 kg dry-body proxy. These are unqualified simulator values, not a
published terminal-descent load. Astrobotic's August 2021 guide, page 26,
specifies M20/MON3 and two tanks of each reactant, but provides no remaining
propellant mass for this 60 m scene:
https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf .
The historical guide describes five main engines; the current product page
states seven, so geometry/configuration sources must retain their dates:
https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ .
Do not infer current flight fuel mass or engine count from an older rendering.
A revised terminal-descent load must account for modeled consumption, mixture
ratio, reserve, actual tank volume and the attached assembly's mass.

Next acceptance priorities are first-contact leg stroke and sideways motion,
continuous force-driven descent without pose writes, restart replay, manual
liftoff after touchdown, fuel/oxidizer starvation, deployed ramp wheel clearance,
and real terrain wheel/pad contact. Scene cleanup must remove artificial pads
and revise pad-dependent preflight/egress contracts together; hiding their
meshes alone would retain an invisible alternate contact surface.


## Surface route simplification — 2026-10-03

The route now contains five operator-facing milestones: ramp approach, ramp
exit, two survey targets and the base site. Ten intermediate markers and the
unused base-site collision slab were removed with typed USD document operations.
The exit moves from X=15.60 m, inherited from the old 12.23 m ramp, to X=8.50 m.
For the current estimated 5.397 m ramp rooted near X=1.90 m at 27.83 degrees,
the nominal tip is near X=6.67 m; X=8.50 allows approximately 1.30 m rover
half-length plus the 0.30 m arrival radius. The later shallow-turn positions
and normalized throttle limits are mission-study choices requested by the user,
not a surveyed lunar route. SysML owns the five arrays and the USD builder reads
them. This pass verifies source and authored geometry consistency; rover traversal
of the revised route remains unverified. Landing and egress slabs still remain
until their pad-dependent physics and verification contracts are replaced.


## Axial landing gear revision — 2026-10-03

The vehicle now has four bus-to-foot prismatic joints. Each joint follows the
primary member's bus-to-hub connection line and locks the other translations
and rotations. Barrel geometry is attached to the bus mount, piston geometry
to the moving leg; neither adds an independent rigid body. The inferred skirt
hinges, shock pins and eight light shock bodies were removed. This supersedes
the earlier hinged V-brace mechanism and its leverage-based spring tuning.
The three-member appearance still follows the
[PGH hardware photograph](https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png).
That image does not establish the flight linkage. Secondary braces retain their
nominal endpoint geometry and move with the foot: their upper attachment
compliance is an explicit appearance approximation. Their loaded upper ends
are not claimed to be rigidly connected to the skirt.

The existing 180 kg per-leg proxy is conserved and lumped into each moving
leg, including the former barrel/piston allocations. Its mass distribution is
uncalibrated. The source-owned primary length 1.4264168 m and vertical span
1.26 m give cosine 0.883332. The previous reconstructed 5510 kg assembly under
1.62 m/s² gives 2526.3 N nominal axial quarter-load. An estimated 85 kN/m
spring gives 29.7 mm static compression. Critical damping for generalized
quarter-mass 1074.83 kg is 19.117 kNs/m, rounded to 19 kNs/m. These calculations
motivate the revised study values; they are not supplier shock curves. The
50 mm compression, 20 mm rebound and 12 kN force cap remain study assumptions.
Recalculate them when the propellant/mass budget changes.

Typed USD operations saved the vehicle and composed readback confirmed the
single slider and removal of the old mechanism. The component gate passes;
duplicate existence/body-relationship checks were removed. Live settled-leg
observations in an owned headful session measured compression 17–37 mm,
transverse error up to about 12 micrometres and relative rotation error below
0.0007 degrees across two sampled observations. Evidence:
`terrain/target/griffin-direct-slider-axis-live.jsonl`. These settled samples
are not a maximum transient stroke measurement.

Two fresh-process trials completed the full 60 s observation window with finite
telemetry, maximum angular speed below 0.012 rad/s, maximum horizontal speed
below 0.030 m/s and drift below 0.221 m. They do **not** pass acceptance:
359 of 361 observations had four-foot contact, and touchdown ticks differed
(1388 versus 1394), producing different final poses. The strict limits remain
unchanged. Raw evidence is in
`terrain/target/griffin-direct-slider-armed-replay/`. Both trajectories started
powered descent and continued into rover egress; full egress is not accepted.

A topology edit on the mounted scene also reproduced a simulator panic in
`sync_twin_overlays` / Avian island cleanup: “Neither body ... is in an island”.
The proposal was recovered through the document owner and saved with the scene
unmounted. Live partial-refresh safety remains unresolved; this is not a
replacement for fixing the core lifecycle. Evidence:
`terrain/target/griffin-retained-reload-live.log`.

Additional useful acceptance work is first-contact axial error/stroke across
all four legs, continuously qualified touchdown before the one-time notice,
startup/restart authority timing, a physically consistent fuel/oxidizer load,
manual liftoff, and deployed ramp traversal. The remaining visual priorities
are reference-matched folded-ramp proportions, visible tank/deck structure,
solar-cell shape and hardware finish contrast; artist-impression and current
hardware configurations must stay explicitly separated.

## Inspection lighting revision — 2026-10-03

The review composition retains its directional Sun and reduces the neutral
DomeLight inspection fill from 18000 at exposure 2 to 300 at exposure 0.
LunCoSim's `crates/lunco-usd-bevy-light/src/light.rs` maps this untextured dome
to ambient brightness as intensity times 2^exposure. These are renderer units,
not calibrated lunar lux or an Earthshine estimate. The mission light is unchanged.

Owned rendered A/B evidence: `terrain/target/assembly-editor/griffin-axial-full-review.png`
and `griffin-review-fill-300.png`. The lower fill reveals rail shadows, metallic
leg highlights and solar-cell contrast that the previous 72000 ambient brightness
washed out. The shadowed side becomes dark; this is a static shape inspection,
not acceptance of mission exposure, terrain appearance or flight physics.
The visual requirement's stale five-engine description was corrected to seven,
matching the existing current-product requirement and vehicle.

## Exterior finish and review cleanup — 2026-10-03

The bus ExteriorPanels UsdPreviewSurface now uses the source-owned metallic
0.55 and roughness 0.45, replacing 0 and 0.65. This is an appearance estimate
informed by the broad soft reflections on the pale exterior in the
[PGH hardware photograph](https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png),
not measured optical properties. The existing material is reused; no texture,
extra geometry, collider or mass was added. `griffin_bus_finish_plan` reads the
SysML values and uses the existing material-network planner after the cladding
is composed. Saved owner and dependent-stage reads confirm these values.

Twenty obsolete review-only shock-body and pin/brace-hinge overrides were
removed after the axial mechanism revision. A fresh-process static geometry
check passes all 126 checks, source revision 13849370287358511557, in
`terrain/target/griffin-current-visual-fresh.log`. This is structural evidence,
not rendered acceptance. The older process still returned the previous shock
paths after clearing/loading and stayed in physical-admission hold, while the
fresh process resolved the new piston Tube. That difference remains a core
dependency/reload defect to investigate; do not hide it by weakening checks.

## Blanket perimeter detail — 2026-10-03

Eight render-only tape meshes follow the existing panel face perimeters.
The [PGH hardware photo](https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png)
shows thin gold edge tape. Width 10 mm, a 1 mm surface offset to avoid coincident
render faces, and linear color (0.55, 0.36, 0.05) are explicit appearance estimates.
Each mesh has four quads forming a ring with an open center, derived directly
from its composed ExteriorFacet outer vertices; no independent bus pose, rigid
body or collision geometry is added. GBC-009 owns the detail and its uncertainty.

A directly launched scene initially had an inactive window camera. Opening the
Twin enabled the window camera; this explains the blank cold screenshot and is
separate from the warm-process stale dependency/admission defect. The current
full assembly, before edge tape, was inspected in
`terrain/target/assembly-editor/griffin-current-finish-twin.png`.

All eight composed tape meshes were observed spawned, single-sided, render-only
and non-colliding with eight points/four quads each. Evidence:
`terrain/target/assembly-editor/griffin-blanket-composed.json` and the inspected
`griffin-blanket-framed-current.png`. The component source refresh changed the
camera orientation before it was framed again through SetCameraLookAt; preserving
the camera across such refreshes remains unresolved. The geometry observation
and subsequent frame are not a camera-refresh PASS.

## Exposed-frame finish — 2026-10-03

The product description identifies an aluminum frame:
https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ . Silver
members are visible in the supplied hardware photograph:
https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png .
The earlier almost-black perimeter and payload frame were unsourced appearance
choices that obscured the open structure. Twelve exposed members now share
one `FrameMetal` standard USD material, using the existing SysML silver color,
metallic and roughness controls. Four redundant per-role palette fields were
removed, and their builders and observations consume `silverDisplayColor`.
These renderer settings remain estimates, not measured optical or structural
material properties. Geometry, joint axes, collision and mass were unchanged.

Authoring used bus document 115957121335495, root target, generation 126 ->
170, one 44-operation typed Editor batch. Preview 115957121335495/view 7
reported projected generation 170 and ready. Focused inspection:
`terrain/target/assembly-editor/griffin-silver-frame-editor-focused.png`;
full view: `terrain/target/assembly-editor/griffin-silver-frame-full.png`.
The saved-source production bus gate passed 353 existing checks at tick 28,
60 Hz, one thread, jitter zero, source revision 12429294179393803632:
`terrain/target/griffin-silver-frame-bus-gate.log`.

A live component source refresh also left the same-process review's
co-simulation barrier held: eight active participants, seven shared-clock
participants, worst lag about 0.10 s, transport playing but simulation paused.
That blocked the attached streamed check; the fresh component gate above does
not establish warm-refresh or mission acceptance. A console-only bus check
also exceeded its operation budget; neither failure was converted to a PASS.

The additional configuration-types fixture remains ERROR
(`terrain/target/griffin-silver-frame-types-gate.log`). Its obsolete absolute
mechanical-relations import and missing verification constant were corrected,
but its native-source observations still fail. Separately, direct source
inspection found five engine stations, five engine instance names and a
five-engine lander count, while that fixture expects seven. The saved vehicle
also contains only Engine01..Engine05. Thus the earlier seven-engine review
description is a requirement, not evidence of a realized seven-engine model.
Astrobotic's current product page specifies seven engines; reconciling the
model, propulsion source, placement and checks remains open. Do not replace
the seven-engine expectation with five to obtain a green report.


## Seven-engine underside and tank clearance — 2026-10-03

The current product page specifies **seven** main engines:
https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ (accessed
2026-10-03). The August 2021 PUG v5.02 p.26 describes five; it is historical
configuration evidence, not the current count. The supplied hardware reference
https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png helps with
structure and finish but does not establish the current nozzle station drawing.

The realized study layout is explicitly estimated: one center nozzle and six
on a regular 1.19 m ring, all facing down. With the retained 0.34 m exit radius,
neighboring exits have 0.51 m clearance. The 3.44 m skirt frame leaves at least
0.11 m to its inner rail edges. Bell and collar centers are at lander-local
Y=0.34 m, putting the highest collar point at Y=0.76 m. The lowest composed
tank hardware point is Y=0.784 m, giving **24 mm vertical separation**. At the
0.44 m touchdown-root datum, the lowest exit is 0.52 m above ground. These
clearances are reconstruction allowances, not qualified thermal/flight margins.

Skirt rails now share the adapter's component-local Y=0.48 m plane. Their
assembly tops are at Y=0.86 m, the lower service-skirt bottom; the shallow
open shroud surrounds the mounting interface rather than the bell exits.
Tank seats and adapter contacts remain structural attachment proxies. No
current supplier engine/tank attachment ICD is available. GPP-009 verifies a
conservative gap from the complete named vessel, cradle/pad, lower fittings
and brackets, using composed geometry bounds in one canonical snapshot. This
is necessary because an engine-spacing check alone missed collar penetration.

Engine06 and Engine07 reference the same reusable hollow bell/shared LunCoSim
exhaust component as the existing nozzles. All seven use aggregate Modelica
photometry; its count is seven. Total thrust, actuator ownership, physics mass,
nozzle dimensions and propellant state were unchanged. Current unit thrust,
current propellant loading/densities and mass allocation remain uncalibrated
study inputs; seven nozzles does not establish current flight performance.

Typed authoring changed the engine references/placements, then their plume
connections after composition, then the isolated skirt. Final authoring owners
were vehicle 115970293813770 (generation 0 -> 8, saved) and skirt
115970293813765 (generation 0 -> 34, saved). Earlier seven-engine reference and
190-operation photometry batches are retained in the vehicle journal/source.
Warm authoring sessions read stale source/geometry while reporting current
projection generations. A fresh owned process was required for exact saved
source readback; this is a recorded reload failure, not an accepted workaround.

Saved-source production checks, 60 Hz, one thread, zero jitter, source revision
16119617851389158153:

- Propulsion **PASS 123**, tick 14: `terrain/target/griffin-seven-clearance-saved-gate.log`.
- Configuration types **PASS 22**, tick 6: `terrain/target/griffin-seven-types-corner-gate.log`.
- Typed source registry **PASS 208 targets / 208 evidence / 47 sources / 3 roles**.

The configuration fixture lacked the shared read-only query dependency
contract, which prevented its source analysis; it now reuses
`usd_geometry_inspection::dependencies`. Native enum observations are reported
as literal/type evidence, preserving native evaluation without an unsupported
telemetry payload. Its outdated bus-center tank-plane and cardinal-leg pairing
assumptions were replaced by tank coplanarity and the authored corner-leg
mirror pairs. Numeric tolerances were not widened. Component checks do not
establish touchdown, warm reload, takeoff or rover egress acceptance.

Fresh saved-source Editor evidence used owned port 49753, vehicle document /
preview 115970812930734, view 7, projected generation 0 ready. Readback
`/tmp/griffin-seven-saved-readback.json` observes collar maximum Y=0.7599999869 m
and cradle minimum Y=0.7840000000 m in the same canonical frame, plus Engine07
and the elevated frame rail. Focused underside screenshot:
`terrain/target/assembly-editor/griffin-seven-saved-underside-framed.png`.
Seven hollow exits and the four corner-leg tripods are visible. Underside
inspection lighting remains too dark, and the frame-selection command rejected
the bus path; the view was manually framed using ordinary Editor orbit/zoom
input. Neither that framing failure nor warm camera/reload behavior is a PASS.


## Silver bus blankets and unobstructed ramp shafts — 2026-10-03

The pale crumpled exterior blankets and narrow gold seams in
https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png are the
appearance reference. The existing LunCoSim `mli_foil` shader is reused on one
shared bus material, with controls owned by GriffinVisualConfiguration. Valley
RGB (0.58, 0.59, 0.57), crinkle density 26/m, facet contrast 0.65, sheen 0.10
and axial scale 1.0 are explicit artistic estimates from an uncalibrated photo.
They retain a pale silver belt with centimetre-scale shading; lower sheen avoids
nearly black grazing faces under Editor inspection lighting. They do not
establish measured optical or thermal properties, actual blanket construction
or mesh wrinkles. The original flat-material controls were removed.

A reversed end quad in the shared prism topology affected eight bus facets,
four standalone ramp track meshes and twelve integrated ramp track meshes.
The existing closure observation now requires two opposite directed uses of
each edge; incidence two alone had accepted the reversed face. The corrected
indices change surface winding without changing vertices, bounds or the convex
collision point cloud. No new requirement was added for each individual face.

The two root ramp hinge shafts still spanned 2.592 m despite the existing
source-owned split-shaft layout. They now match its 1.408 m span, derived from
`2 * (rampCenterRailOffsetZM - rampRailWidthM / 2)`, leaving tire corridors
clear. The reference is https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png
and the operator's observed hinge obstruction. This remains an approximate
reconstruction of paired open trusses, not a released hinge drawing. The other
four section shafts already matched this value.

Typed owners saved the bus document 115973312757691 through generation 60,
vehicle 115973305098730 through generation 17, and standalone section documents
115976141711457/115976141711458 through generation 2. Saved-source production
gates at 60 Hz, one thread, zero jitter, source revision
5926034440915050438:

- Bus **PASS 355**, tick 28: `terrain/target/griffin-silver-blanket-bus-gate.log`.
- Ramp **PASS 1277**: `terrain/target/griffin-ramp-winding-hinge-gate.log`.

Fresh owned Editor port 49756 loaded the combined review source, document /
preview 115976867617853, view 7, projected generation 0 ready. Its composed
bus shader read back the shared foil asset and final controls. The focused
assembled view is `terrain/target/assembly-editor/griffin-silver-foil-assembled.png`;
the close finish view is `terrain/target/assembly-editor/griffin-silver-foil-refined.png`.
This is visual/component evidence, not a landing or egress verdict.

A separate generic Editor query defect was corrected in local core commit
2711489c1: explicit document queries now recognize a live standalone preview
as the canonical geometry owner. The production `usd_material_edit_projection`
windowed gate passes, including translate/scale readback and source replacement.
However, clearing a simulation scene can still leave a retained preview empty
and pending; the accepted frame-selection command also did not reframe this
review view. Ordinary Editor zoom provided the inspected image. Warm scene
reload, landing replay and camera lifecycle remain unresolved and are not
claimed by either component PASS above.
