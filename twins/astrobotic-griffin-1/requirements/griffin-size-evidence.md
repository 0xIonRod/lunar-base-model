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
