# Griffin and FLIP size basis — updated 2026-10-05

These are provisional reconstruction requirements, not an as-built mechanical
ICD. A successful geometry check proves implementation of the assumptions; it
does not prove the assumptions describe flight hardware. Replace estimates when
better configuration-specific evidence becomes available. Numerical precision in
derived hinge coordinates is for interface closure, not measurement accuracy.

## Current packaging study, 2026-10-05

The [NASA June 15 hardware gallery](https://www.nasa.gov/gallery/astrobotics-griffin-1/)
and [PGH reference](https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png)
show tall side arrays, folded ramps above them, a supported upper deck, corner
attitude hardware and a wrapped lower engine bay. They do not provide flight
clearances, hinge coordinates, qualified load paths or calibrated dimensions.
SysML owns the estimates and builder relationships; the table below is current.

Four 80 mm cardinal columns meet the bus deck at Y1.79 and upper frame at
Y2.76. Two crossmembers span the frame at Y2.68–2.76, joining its central mast
to the interface plate. A narrow rear avionics shelf replaces the obsolete
central box that occupied the tank/mast volume. These are visible integration
members under the existing lander mass, not separately qualified structural
bodies. GBC-011 verifies actual mating faces; it does not calculate strength.

The seven main bells are contained by an open octagonal skirt. Its lower lip
is Y0.06; nozzle exits are Y0.08, a chosen 20 mm recess. The 0.80 m shell depth
is derived from that recess, the nozzle envelope and adapter plane. Radial
clearance is checked against the actual perimeter. The former square adapter
plate projected beyond the shell corners; its retained 2.84 m envelope now
follows the same octagonal profile, and its vertices are checked for containment. Shared bus foil gives the
photographed silver blanket finish. Heat protection and plume interaction
are unmodelled. A110 RCS members retain their original force/fuel identities
on four upper corner platforms; their station height is deck top + 0.20 m.
Flight count, arrangement and mounting dimensions remain explicit estimates.

Static stow clearance, bus support closure, nominal ramp interfaces and nozzle
containment have focused gates. Full unfolding sweep, physical egress and
landing acceptance must be assessed for this exact raised assembly; older
flight acceptance below cannot establish them.

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
| Payload surface above nominal terrain | 5.72 m; earlier study 2.52 m | 3.28 m | Integration estimate: local deck top 2.84 m clears the reconstructed current tall-panel top 2.714577 m by 0.125423 m, plus the 0.44 m nominal touchdown reference. This supersedes the older height study. No calibrated photo or flight drawing establishes this height. |
| Footprint across opposed pad edges | 7.24 m | 4.50 m | Diagonal foot stations at X/Z=+/-1.90 m plus 0.35 m pad radii on each side; selected to match the historical envelope approximately. Current footprint unconfirmed. |
| Payload adapter | 4.40 × 3.20 m | 3.20 × 3.20 m | Estimated octagonal footprint fitting inside the bus and covering the reconstructed FLIP wheels after clipping the corners. 80 mm stock is an explicit silhouette estimate; center Y2.80 gives the Y2.84 contact top above current tall panels. |
| FLIP body | 4.40 × 2.76 m lower frame | 2.116 × 1.476 m | Promote the estimated CAD plan dimensions with an explicit axis mapping. Allow approximately 20% dimensional uncertainty. The 0.12 m lower-frame height is a visualization/collision proxy; equipment box height 0.396 m comes from CAD. |
| FLIP wheel envelope | legacy inconsistent envelope | 2.28 m across track; 2.60 m along travel | Derived from 2.0 m track + 0.28 m tire width and 1.7 m wheelbase + two 0.45 m radii. Wheel ribs, deformation and suspension travel excluded. |
| Ramp length | 12.228605 m | 5.397252161 m | Retain the earlier derived study length; new nominal angle is asin(3.28 / 5.397252161) = 37.4246°. Both length and slope remain unconfirmed; terrain fitting uses live toe height. |
| Each of three sections | 4.076201667 m | 1.799084054 m | Total length / 3. Three-section folding topology remains a study assumption. |
| Ramp outside width | 3.50 m | 2.592 m | 2.00 m track + 0.58 m contact-track width + two 0.006 m rails. Derived from the current outer rail edges; 2.86 m belonged to the superseded 140 mm rails. Contact width is 0.28 m wheel + twice 0.15 m estimated clearance. |
| Deck transition | 1.96327 m | 0.90 m | Estimated bridge to the octagonal deck: outboard X=1.90, inboard X=1.00. Width follows the current 2.592 m rail corridor; GRR-012 checks composed deck overlap against the 0.05 m study requirement. |

The vehicle touchdown reference remains 0.44 m. Adapter center Y=2.80 plus
half-thickness 0.04 gives a vehicle-local top of 2.84 m, hence 3.28 m above
nominal ground. With 30 mm ramp plate thickness, source-derived hinge stations
are X=±1.909115750, Y=2.828087691. The earlier Y2.08 platform let the
folded toe and guides pass through the tall panels. Moving ramps outward alone
was rejected because it left the bridge and rover crossing the same wall.
Raised support columns and crossmembers now close the deck-to-bus structure.
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
assembled view is `terrain/target/assembly-editor/griffin-current-framed.png`;
the close finish view is `terrain/target/assembly-editor/griffin-silver-foil-refined.png`.
This is visual/component evidence, not a landing or egress verdict.

A separate generic Editor query defect was corrected in local core commit
2711489c1: explicit document queries now recognize a live standalone preview
as the canonical geometry owner. The production `usd_material_edit_projection`
windowed gate passes, including translate/scale readback and source replacement.
However, clearing a simulation scene can still leave a retained preview empty
and pending. The earlier frame-selection attempt targeted a nonexistent prim;
the correct `/GriffinFlipVisual/Griffin1` path frames the complete assembly.
This was an invocation error, not evidence of a frame-selection defect. Warm scene
reload, landing replay and camera lifecycle remain unresolved and are not
claimed by either component PASS above.

## Ramp reaction loads and fresh landing trials — 2026-10-03

The post-command-ordering trial lost the NZ foot at ticks 1520 and 1560,
inside the middle-section unfold (start 1491, settled 1563). Native engine
thrust was zero at both losses. The bounded contact-drop records retain the
four individual contacts, position, velocity, angular speed and handoff;
they diagnose the existing four-foot predicate without changing it.

`physicalRampUnfoldQuarterTurnDurationS = 6.0` now owns the command timing.
Each quarter-turn follows quintic interpolation with zero endpoint speed and
acceleration, on the admitted simulation tick lattice. A 90-degree motion has
15 degrees/s average and 28.125 degrees/s peak commanded speed. Six seconds
is a conservative simulation-study estimate chosen to reduce the measured
gear reaction to the former abrupt command, not a supplier actuator rating.
The qualitative fold reference is
https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png ; it supplies no
actuation timing. The existing angle/speed settlement checks remain mandatory
between quarters and before payload release. Avian owns all body motion.

Two fresh production trials at 60 Hz, one thread, zero jitter, source revision
13873018758900720979, each passed the unchanged 60-second landing-stability
predicate: **361/361 four-foot samples**, no contact-drop records, touchdown
tick 1394, final tick 5000. Maximum angular speed was 0.01072/0.02021 rad/s;
maximum horizontal drift was 0.21562/0.21559 m. Both completed measured ramp
deployment and adapter release before the horizon. The separate saved-source
ramp gate passed **1277** checks at that revision.

Evidence: `terrain/target/griffin-smooth-ramp-landing-replay/run-{1,2}.json`
and `.log`, plus `terrain/target/griffin-smooth-ramp-source-gate.log`.
Fresh-process repeatability still **FAILS**: final X differs by 0.000112161 m,
above the unchanged 0.000001 m replay limit. Stability PASS does not establish
deterministic reload, full route completion, reflight or flight qualification.

Local core commit `3a70f8692` samples script-admitted inputs after ScriptingSet
and before Modelica step dispatch. The production rocket-engine boundary
regression failed with an adjacent accepted step consuming the old throttle;
the corrected ordering passes all 15 checks. The separate lander-controls
fixture fails the same eight assertions with both the old and new binaries.
It remains an independent control/fixture defect; no tolerance was weakened.
The pending core stack is not merged as a deterministic-reload fix.

## Retained observer identity and report lifecycle — 2026-10-03

The isolated Twin host created by RunScenarioAsset had no global identity;
simulation queries rejected it with “no live scenario owns this simulation
access.” The core host now declares authoritative provenance and receives its
identity from the existing session admission owner. Production rebuild and
same-app readback confirm a nonzero retained identity and working declared
physics reads across replacement. This closes the observer authorization
defect, not physical determinism.

The landing-stability observer also mutated its report latch on a copied Rhai
map argument. It therefore rebuilt the full report every tick after its
horizon, slowing longer diagnostics substantially. The scenario caller now
owns that latch. The corrected live trial emitted exactly one stability
metrics record through its first 90-second trajectory.

Evidence: `terrain/target/griffin-twin-host-single-report-reload.log`.
Two same-app replacements still **FAIL** at relative tick 60, before ground
contact: reference/sample Y position 59.199830788144354/59.1998353552034 m,
angular speed 0.3271466051275888/0.3390591487815587 rad/s, with identical zero
engine thrust and identical reported vehicle mass. Articulated initialization
must be traced before the pending core stack is merged as a reload fix.

### Engine-skirt corners, 2026-10-04

The user's close-up showed square skirt rails extending past the bus chamfers.
The four square rails are replaced by one continuous mitered octagonal mesh;
its outline and the shallow shell use the existing typed body profile. The
3.44 m across-flats envelope, 80 mm stock and 60 mm shell taper remain study
packaging estimates. The shell taper no longer doubles as its plan-view corner
clip. Qualitative footprint references are the [PGH hardware image](https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png)
and [ESA Griffin depiction](https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander).
These images are not engineering drawings or proof of stock dimensions.

Authoring used the live document owner (`ApplyUsdOps`, source generation 28,
explicit `SaveDocument`), with requirements edited through `ApplySysmlOps`.
The existing propulsion fixture passes all 94 checks, including the updated
GES-006 profile/topology/footprint constraint and unchanged GES-004 bell fit.
Evidence: `terrain/target/griffin-octagonal-skirt-gate.log`.
The combined assembly was reviewed in a fresh owned Editor session on 49758:
`terrain/target/assembly-editor/griffin-octagonal-skirt-reviewed.png`. The lower
square corners are absent; nozzle and landing-leg placement is unchanged.
This is visual/component acceptance, not closure of the warm-reload failure.

### One-side solar belt and section pivot fittings, 2026-10-04

Selected the shallow belt-array configuration in Astrobotic's
[2021 g1 image](https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png),
linked from its [Griffin product page](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/).
Two full panels and a narrower chamfer panel wrap one Sun-facing quadrant;
the speculative opposite broad-face panel is removed. This is a selected
reconstruction configuration, not proof of hidden-side flight hardware.

The full frame is 1.866 m wide: the estimated 2.016 m mounting span minus
150 mm edge allowance. A 30 mm border leaves a 1.806 m active width.
The observed 14 by 5 cell count gives a square 129 mm pitch and 645 mm
active height, hence a 705 mm overall height. The chamfer frame is about
857 mm wide and carries six columns at the same metric pitch. The module
count and aspect ratio are image observations; absolute dimensions, border,
standoff and support stock are study estimates. SysML owns these values and
the derived dimensions; the USD component and installed instances were
updated through generation-checked live typed operations and explicit saves.

The intermediate ramp hinges lacked mating parent-side plates and used
child lugs stretched from the track underside to the top rail. Each now has
a compact 60 mm circular, 10 mm thick child tongue between two 6 mm parent
cheeks. All plate centres derive from the existing joint's localPos0/1;
cheek spacing derives from the tongue and cheek thickness. The existing
40 mm pins are retained. Circular shape, stock and fit are low-confidence
visual estimates, not a qualified bearing design. The source records both
Astrobotic's stowed rendering and the [ESA 2022 artist impression](https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander).
ESA's partly opened pose does not establish a deployment trajectory.
The three-section accordion configuration and commanded motion remain study
assumptions. No body mass, contact track, joint frame or drive was changed.

The existing solar gate passes 152 checks, the ramp geometry gate passes
1281, and the separate flight-stow gate passes. The four added ramp checks
aggregate fitting dimensions, render-only ownership and native-anchor fit
per intermediate joint; they do not multiply every plate into separate
requirements. Evidence: `terrain/target/griffin-solar-one-side-gate.log`,
`terrain/target/griffin-compact-pivot-gate.log`, and
`terrain/target/griffin-compact-pivot-stow-gate.log`.

During editing, the document inspection contained the new prims while its
canonical composed query reverted to an older stage. Reopening the preview
restored projection readiness but did not refresh that query owner. Thus the
save-before-gate portion of the normal authoring sequence could not be
completed in that session: authored inspection and explicit saves were
followed by fresh saved-source production gates and a new Editor session.
Fresh owned port 49759 reads the new fittings correctly and reports a ready
preview. Reviewed image: `terrain/target/assembly-editor/griffin-solar-ramp-saved-reviewed.png`.
This is visual/component acceptance. Held-Space reflight, warm reload
repeatability and full rover traversal remain open.


### Tall side array and current hardware references, 2026-10-04

The user selected a tall panel on one side, as in the [ESA 2022 artist
impression](https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander).
This supersedes the previous pass's assumption that every installed panel
should use the shallow belt module. The front and chamfer retain their
Astrobotic rendering proportions; the starboard panel now has an estimated
10-column by 14-row field. The same assumed 129 mm pitch gives a 1.350 m wide
by 1.866 m tall frame. Grid count is an approximate visual reconstruction;
matching pitch between different rendering revisions is an explicit study
assumption, not a flight-hardware dimension. Its lower edge stays at the
existing belt edge. Centre height derives from that relationship, and bracket,
link and hinge stations retain the existing bus sockets. Rhai reads the ordered
SysML column/row arrays; it does not own another dimension table.

The latest real hardware photos located in this search are Astrobotic's
June 15, 2026 unveiling photos. Reviewed both the
[1348 clean-room view](https://www.astrobotic.com/wp-content/uploads/2026/06/26.06.15_Griffin-1_PressConference_1348_Edit-scaled.jpg)
and the [1419 opposite view, credited to Astrobotic by NASA](https://www.nasa.gov/image-detail/26-06-15-griffin-1-pressconference-1419-edit-2/).
Source context: [Astrobotic's unveiling release](https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/)
and [NASA's hardware gallery](https://www.nasa.gov/gallery/astrobotics-griffin-1/).
These are photographs of the integrated lander in a ground-test pose, unlike
the older product/ESA renderings. They are stronger evidence for hardware
shape and placement, but supply no metric panel dimensions.

The photos show large solar-covered faces around one quadrant, stepped
lower and equipment openings, dark cells with rounded corners and warm-colored
inter-cell substrate, silver frames, and substantial landing-gear sleeves.
Folded ramp backs also have broad dark surfaces rather than only an open
ladder appearance. Current-model gaps remain: tall coverage of the other two
faces, shaped openings and cell/support appearance, ramp deck/back geometry,
and hardware-specific leg details. The current single tall rectangular panel
is the user-selected reconstruction; it is **not** asserted to reproduce the
June 2026 flight vehicle. Ground wheeled stands, protective covers and elevated
footpads must not become lunar landing geometry or nominal leg compression.

Live Editor editing used four bounded named groups (surface, columns, rows,
mounts), all submitted through the same typed planner/document owner. The
preview lease was renewed at the same document identity to restore projection
readiness at generation 355. The pre-save document-scoped SysML envelope gate
passed four observations (frame/cell/backplane heights and derived centre).
The saved-source production solar fixture passed its existing 152 checks,
including the full 14-row grid and mount overlap. Evidence:
`terrain/target/griffin-tall-solar-gate.log`;
local live envelope report `/tmp/griffin-tall-solar-live-envelope.json`.
The full one-shot solar observer exceeded the Editor's operation ceiling, so
no additional observer library or increased limit was added. The focused
Editor images show the taller silhouette partly occluded by stowed ramps;
full exposed-side visual clearance is still to be reviewed. Images:
`terrain/target/assembly-editor/griffin-tall-solar-focused.png` and
`terrain/target/assembly-editor/griffin-tall-solar-camera.png`.
This is component geometry acceptance, not landing, reload, power-performance
or rover-egress acceptance.


### June 2026 hardware appearance update, 2026-10-04

This pass supersedes the preceding single-tall-ESA-panel configuration. The
appearance reference is the actual integrated vehicle photographed on June 15:
[Astrobotic's unveiling release](https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/),
[Astrobotic 1348 image](https://www.astrobotic.com/wp-content/uploads/2026/06/26.06.15_Griffin-1_PressConference_1348_Edit-scaled.jpg),
and [NASA's 1419 photo credited to Astrobotic](https://www.nasa.gov/image-detail/26-06-15-griffin-1-pressconference-1419-edit-2/).
These photographs show three tall adjacent solar faces, stepped edges,
equipment/leg recesses, dark rounded rectangular cells, warm inter-cell gaps
and silver perimeter frames. Their ground stands, protective covers and
raised footpad pose are excluded from the lunar vehicle.

| Realization | Evidence and explicit assumption |
| --- | --- |
| Nominal broad field: 13 columns × 24 rows, horizontal/vertical pitch ratio 2:1 | Approximate count and cell aspect from the frontal photos; clipped/stepped rows have fewer cells. Supplier count and dimensions are unavailable. |
| Broad frame: 1.866 × 1.727077 m | Retain the existing estimated rail-fitted width, with 30 mm border. Active width 1.806 m / 13 yields 138.923 mm horizontal pitch; half that yields 69.462 mm vertical pitch. Twenty-four rows plus two borders determines height. This is packaging reconstruction, not photogrammetric scale. |
| Chamfer frame: 0.856920 m wide, five columns at the same metric pitch | Existing corner-post span minus the source edge allowance caps the face. Whole-column fitting leaves edge clearance. The actual flight bus facets and panel interface may differ; this narrow chamfer is a retained packaging approximation. |
| Panel centre Y: 1.851038 m; lower edge Y: 0.9875 m | Keep the original bus lower-edge datum: raise the old 1.34 m centre by half the difference between the new frame height and 0.705 m installation datum. Retain rail sockets and derive links in the panel frame. |
| Distinct front/chamfer/side silhouettes | SysML vertices are in cell-pitch coordinates. Front face has upper-left steps and a right equipment recess; the chamfer has a lower leg opening; the side has a lower corner opening. Shape and face assignment adapt the photographs to the retained octagonal bus. Unseen contours and exact dimensions remain estimates. |
| Clipped corners, 5 mm gaps, 7 mm corner clips | Approximate the photographed rounded cell tiles with a simple eight-corner profile. These are visual approximations, not cell manufacturing specifications. |
| Dark cells, copper-colored gaps, silver frames | Photographic appearance only. Source RGB/metallic/roughness values select standard USD materials; they do not assert substrate alloy, electrical efficiency or thermal properties. |

Each cell row is one mesh, avoiding a separate entity for each cell. Convex
native extrusion builds clipped tiles and rectangular substrate bands; source
contours drive the band partition and perimeter beams. Reusable component
and installed instances share one planner. The obsolete divider primitives,
notched-rectangle-only builder and duplicate mesh writes were removed.

The live component envelope gate passed two observations; each installed
panel height passed its own document-scoped gate. Warm vehicle preview
projection stalled after dependency edits (generation fence remained false
at 49759 despite lease renewal and reopening). Its authored document was
explicitly saved through the owner, then validated from disk in fresh runs.
Fresh 49760 reports `projection_ready=true`, generation 0, for the saved
vehicle. Focused component and whole-assembly screenshots were inspected.
Evidence: `terrain/target/assembly-editor/griffin-hardware-solar-component.png`
and `terrain/target/assembly-editor/griffin-hardware-fresh-editor.png`.

Production saved-source acceptance:

- Solar fixture: **PASS 152**, exit 0, tick 78 / 1.3 simulated seconds;
  `terrain/target/griffin-hardware-solar-gate.log`.
- Combined Griffin/FLIP visual fixture: **PASS 126**, exit 0, tick 8;
  `terrain/target/griffin-hardware-visual-gate.log`.

The solar observer measures cell centres, dimensions and contour omissions
one row per tick. It keeps only scalar residuals plus source/document/stage
identity and rejects mixed revisions; the final packet still reports once.
This avoids raising Rhai's operation or aggregate-array limits. These gates
verify the authored study geometry, not flight dimensions or landing physics.

Remaining work, in order:

1. Reconcile bus plan shape and facet widths with multiple real views. Current
   normalized corner coordinate 0.585786 is a clipped-square study octagon,
   not a regular octagon (whose coordinate would be 0.414214). Do not change
   it blindly: tank openings, physical hull, panel mount rails and leg
   interfaces must be evaluated together. The current narrow middle panel
   is the clearest visible sign of this unresolved packaging choice.
2. Reconstruct the folded ramp backs and confirm the mechanism from actual
   deployment footage/drawings. The photographs suggest broad dark backs;
   the current three-section accordion and quarter-turn path remain a study
   configuration. Preserve track collision and joint ownership while checking
   toe-to-ground continuity and rover clearance through the full sequence.
3. Refine leg sleeves, hinges, tilted footpads and exposed equipment/plumbing
   from hardware views. Keep motion on the bus-to-foot axis and never use the
   ground-test stand pose to set flight suspension compression.
4. Close warm reload/contact repeatability, held-Space reflight and complete
   FLIP traversal separately. The current appearance pass changes no masses,
   colliders, contact laws, fuel inventory or guidance behavior.
5. Replace panel supplier/count/contour and electrical/thermal placeholders
   with controlled data. Revisit blankets, tank supports and nozzle/interface
   details where those data change the study geometry.

## Sustained engine commands, 2026-10-04

The full pilot path exposed an inconsistent scalar contract: the main force
actuator accepted only 60,000 N, while the chamber produced about 88,600 N at
full demand. Above the actuator limit, port validation rejected the command
before force delivery. Spooling through the accepted range caused a brief hop;
repeated input edges could repeat those impulses. The actuator now accepts
90,316.8 N, derived from the explicit 32 kg/s feed envelope, 2940 m/s effective
exhaust velocity and 0.96 combustion efficiency in `GriffinEngineControlStudy`.
The upward rounding from 31.7685 kg/s bounds the existing pressure-dependent
feed equations. It changes the interface limit, not the chamber equations or
the claimed flight rating.

Current hardware topology follows the [Astrobotic product page](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
(seven main engines and four attitude clusters, checked 2026-10-04). Fuel and
pressure-fed architecture are historical [August 2021 PUG v5.02, p.26](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf).
The feed model, impulse and efficiency remain integration estimates; the
current flight engine rating is unavailable. Turbopump equations in this Twin
remain an approximation that requires replacement for pressure-fed fidelity.

GPP-010 now requires sustained end-of-burn climb, rather than just a peak
height. Production `griffin_engine_commands.rhai` passed five checks on the
surface scene with one five-second input hold, about 137.7 m lift and 58.9 m/s
upward speed at burn end, fuel consumption, and extinguished thrust after a
three-second release interval. This verifies command delivery and reflight;
it does not qualify flight performance, camera behavior or the full rover route.
The canonical vehicle was saved through the Editor at generation 1; composed
readback confirmed the source-derived force envelope. Core source at this run
was `ad5813405` plus the pending fixed-step physics admission and terrain
causal-admission changes. Log: `target/griffin-engine-force-contract-live.log`
in the owned terrain checkout, API port 49766.

## RCS nozzles and physical command reception, 2026-10-05

Each of twelve attitude-force identities now owns one referenced hollow bell,
with curved walls and an open throat. The shared library engine exhaust supplies
plume/core/light; retired Twin cone/flame/light proxies are removed. Bell shape
construction and inspection share `griffin_geometry`; there is no second engine
mesh algorithm. Editor projection and four bounded mesh checks agree at the
saved source generation. Focused view: `target/griffin-rcs-bell-current-framed.png`
in the owned terrain checkout, port 49772.

The historical [August 2021 PUG v5.02, p.26](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf)
gives twelve 25 lbf ACS engines. The current [Astrobotic product page](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
gives four attitude clusters. Combining twelve jets, four corner clusters and
111.2055403815125 N per jet is an explicit study choice, not a released 2026
engine specification. The 80 mm exit diameter, 120 mm bell height, 24 mm throat
diameter, 30 mm collar and 1 mm visual wall are packaging estimates from small
nozzle silhouettes in the [PGH image](https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png)
and [June 2026 hardware photographs](https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/).
The 60 mm standoff, 40 mm below-bus-top datum and 120 mm member spacing are
estimated clearances. They keep the nozzles on the chamfers and preserve paired
zero-translation moment geometry. They are not supplier mount dimensions.
Historical M20/MON3 identifies the hypergolic plume family; its RGB/photometry
are illustrative library estimates, not measured Griffin spectra.

The command path has two distinct units. The geometry-derived allocator emits
normalized valve openings. Those output relationships identify allocator
columns; each physical force input receives the RCSJet's computed thrust in
newtons. Fuel and oxidizer mass pass through public MainPropulsion outputs and
AttitudePropulsion inputs before entering each jet. Direct child-to-child
connections across compiled network boundaries were rejected and are removed.

The previous 6000 Nm controller bound exceeded the small modeled jet bank's
pure-axis capacity and could saturate it into unwanted translation. The current
bound is 277.19165 Nm: 90% of the weakest composed pure-axis pair capacity.
The 10% reserve is an explicit control study margin. The builder derives the
capacity from composed force directions, positions and ratings; it does not
maintain a copied torque table. The generic Lander yaw command now shares this
physical bound with its attitude-hold requests.

The shared Modelica allocator now performs bounded cyclic coordinate sweeps.
The previous simultaneous gradient iterations left about 18 N of unintended
sideways force for a feasible pitch request. The production command fixture
passes thirteen checks covering positive/negative pitch, yaw and roll, requested
moment magnitude, unwanted moments and net force. It observes the generated
allocator and live RCS outputs at 60 Hz, one physics thread and zero jitter:
2160 ticks / 36 simulated seconds. Pitch net force is below 1e-6 N. Evidence:
`target/griffin-rcs-coordinate-equations.log`. The source-owned relative numerical
tolerance is 1e-5; six-second settling includes the existing 0.35-second pilot
filter and network publication delay. This proves the control boundary in a
motion-disabled fixture, not free-flight pointing performance.

Fuel and oxidizer starvation each pass eleven checks through the accepted
allocator and production propulsion network: 180 ticks / 3 simulated seconds,
one physics thread, zero jitter. Both main engines and RCS produce useful
thrust/light before depletion, then reach zero thrust, activity and light while
main demand and a positive allocated RCS valve demand remain held. The two
fixtures share one observer and one propulsion composition; their tank loads
are complementary test stimuli, not proposed flight inventories. Evidence:
`target/griffin-fuel-coordinate-equations.log` and
`target/griffin-oxidizer-coordinate-equations.log`. All twelve jets receive both
live availability inputs through the common network boundaries.

The main-engine feed architecture, total fuel inventory, aggregate throat area
and current flight engine ratings remain engineering-data gaps. This RCS/control
checkpoint does not resolve them or qualify flight performance. Fresh landing,
warm reload, full FLIP route and the remaining hardware appearance refinements
must still pass independently.

## Reachable engine cutoff, 2026-10-05

The first current-engine descent missed touchdown and rebounded repeatedly.
At 22 seconds the attitude was upright but retained about 0.013 rad/s rotation.
The generic Lander stopped damping below 0.02 rad/s, while its touchdown and
engine-cutoff rate predicate required less than 0.005 rad/s. The controller
therefore could leave a spin that prevented its own handoff. These are simulator
values from `lunco://models/Lander.mo`, not measured Griffin thresholds.

The effective damping deadband now caps at half the settled-rate tolerance.
The half-tolerance margin is an explicit control study choice to leave damping
authority inside the acceptance envelope; no touchdown threshold was widened.
With this law, the production descent reached qualified touchdown at tick 1484
(about 24.7 seconds) and passed the unchanged GR-036 stability requirement:
361/361 samples retained four-foot contact over 60 seconds, minimum upright
projection 0.995907 and maximum horizontal drift 0.157619 m. Evidence:
`terrain/target/griffin-engine-contact-rate-margin.log`, exit 0, 5090 ticks.
This is one physical run, not deterministic fresh/warm reload acceptance.

The observer now reports at the existing source-owned 300-second landing
watchdog if touchdown is missing, rather than waiting forever for a
post-touchdown window. Its diagnostics include target error, requested torque
and physical attitude; the stability limits and predicates are unchanged.


## A110 supplier reference and command verification, 2026-10-05

This supersedes the estimated RCS dimensions in the 2026-10-04 section.
Agile confirms [A110 flight-unit delivery to Astrobotic in December 2023](https://agilespaceindustries.com/press/2023-year-in-review).
The [manufacturer's 2023 A110 datasheet](https://static1.squarespace.com/static/634ee7b32099c80fdfcc8cac/t/6418ea80e1144560207215ca/1679505951405/AgileSpace_A110SpecDoc.pdf)
is the reference configuration, not a current Griffin as-built ICD. Checked
2026-10-05. It identifies two direct-acting solenoid valves, refractory chamber
and nozzle, titanium inlet tubes and a stainless valve body. The drawing gives
a 2.4 inch exit diameter (60.96 mm) and 9 inch overall envelope. Griffin's
component uses that exit diameter, expansion ratio 70 and a derived 3.643 mm
throat radius. Bell height 84 mm and chamber length 85 mm are estimates from
157/430 and 160/430 of the drawing's 9 inch dimension. Valve/inlet cylinder
sizes, 45 degree separation, 0.5 mm visual wall and contour exponent 0.55 are
explicit visual estimates; mounting orientation remains a reconstruction.

The nominal operating point is 111.2 N, M20/MON3, O/F 0.90, 19.25 g/s fuel,
17.33 g/s oxidizer and 220 psia chamber pressure (1.5168466 MPa). The nominal
Isp used by the simulation is **derived** from thrust divided by total flow
and standard gravity: 309.9848083 s. The published Isp >=305.5 s is a minimum,
not a nominal value. These are A110 reference values, not measured Griffin
flight-unit performance. Commands represent averaged valve duty at 60 Hz;
the published sub-5 ms pulse capability and sub-10 ms transients require a
finer discrete valve model and are not reproduced by this duty approximation.

All twelve normalized commands are allocated from the composed mount wrench.
Their physics actuators read delivered Newton thrust, not raw valve duty.
Shared Modelica flow consumes both tank inventories; missing either reactant
extinguishes combustion and the library plume. The composed pure-axis capacity
with the unchanged 10% reserve is now 277.1778424 Nm. The production six-axis
command fixture passed **19 checks**, including actual nominal-flow and O/F
closure in each direction, at 2160 ticks / 36 s, one thread, zero jitter:
`terrain/target/griffin-a110-command-flow.log` (exit 0). Four bounded hollow-mesh
checks passed at component generation 80; focused Editor image:
`terrain/target/assembly-editor/griffin-a110-vendor-component-framed.png`.
The saved assembly's fresh preview is ready at generation 0 in owned port
49777; the component reference is loaded. The warm Editor lost projection
readiness after reference updates and reported terrain material-continuation
failure; this does not establish hot-reload acceptance.

Current [Astrobotic full propulsion hot-fire report](https://www.linkedin.com/posts/astrobotic_the-astrobotic-team-recently-completed-a-activity-7402458294524530689-09jf)
confirms two fuel tanks, two oxidizer tanks, three helium pressurant tanks,
pressure-fed hypergolic propulsion and pulsed main/ACS operation. It identifies
Frontier main engines but supplies no current seven-engine unit ratings, tank
loads, regulator settings or chamber geometry. Thus main-engine numerical
performance remains a study assumption; the old turbopump representation
requires replacement. The known architecture must no longer be called unknown.

Strict replay remains **FAIL**. Two pinned fresh trials both qualified touchdown
at tick 1478 with identical position and retained 361/361 four-foot samples,
but final X differed by 2.11176 mm against the unchanged 1 micrometre tolerance.
Logs: `terrain/target/griffin-engine-rate-margin-replay/run-{1,2}.log`.
The single-observer same-process restart failed at tick 60, before contact,
with a 5.74177 micrometre Y difference. Its baseline retained 91 samples over
90 s. Log: `terrain/target/griffin-engine-warm-49775.log`,
`GRIFFIN_RELOAD_FAIL`. These failures predate the A110 reference update and
remain unresolved. Do not merge the core stack as a determinism fix.

The saved production engine-command fixture passed all five checks at 1959
ticks / 32.65 s, one thread and zero jitter. It landed, acquired semantic pilot
ownership, held thrust once for five seconds, retained upward flight at the
end, consumed fuel, and extinguished thrust after release. Log:
`terrain/target/griffin-a110-held-thrust.log`, exit 0. This verifies sustained
command delivery with the current modeled feed; it does not accept strict
reload replay or current flight-engine performance.

## Earlier pressure-fed main-engine tuning, 2026-10-05 (superseded sizing)

This supersedes the pump approximation and outer-radius nozzle datum in the
older checkpoints above. [Astrobotic's current product page](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
confirms seven main engines and four attitude clusters; the
[full-system hot-fire report](https://www.linkedin.com/posts/astrobotic_the-astrobotic-team-recently-completed-a-activity-7402458294524530689-09jf)
confirms pressure-fed hypergolic operation and the two fuel/two oxidizer/three
helium tank architecture. Neither source supplies current flight pressures,
flow rates, chamber dimensions, valve response or propellant inventories.

`GriffinPressureFedStudy` owns the numerical assumptions and derivations:

| Datum | Value | Status and rationale |
| --- | --- | --- |
| Fuel reference flow | 8 kg/s aggregate | Inherited integration assumption; not a flight rating |
| Oxidizer/fuel ratio | 2.6 | Inherited mixture assumption; oxidizer reference becomes 20.8 kg/s to use the same mixture in both feeds and chamber |
| Supply pressure | 2.5–3 MPa | Inherited tank envelope; an ideal regulator approximation, without finite helium depletion |
| Reference chamber pressure | 1.5 MPa | Chosen below minimum supply to leave 1 MPa of passive valve/injector pressure loss |
| Effective c-star | 1550 × 0.96 m/s | Inherited characteristic velocity and combustion-efficiency assumptions |
| Aggregate throat bore area | 0.0285696 m² | Derived from 28.8 kg/s × effective c-star / reference chamber pressure |
| Each of seven throat bore radii | 0.03604359686410814 m | Derived as sqrt(aggregate area / (7 × pi)) |
| Bell exit bore radius | 0.334 m | Existing estimated 0.34 m outer radius minus estimated 6 mm visual wall |
| Full-opening flow capability | 33 kg/s aggregate | Upward rounding of the 32.7588079 kg/s coupled steady solution at 3 MPa supply |
| Actuator admission bound | 141120 N | Conservative 50 kg/s × 2940 m/s × 0.96; bounds passive feed flow even at zero chamber pressure, not predicted flight thrust |
| Valve opening/closing response | 0.08 s | Inherited lumped response; discrete flight-engine pulses are not resolved |
| Fuel/oxidizer initial load | 1000 kg each | Inherited integration inventory; current flight loading remains unknown |

The USD circuit now connects each tank through a `PressureFedValve` to a
`PressureFedCombustionChamber`. Passive flow follows opening × availability ×
sqrt(actual differential pressure / reference differential pressure). Both
injector outlets share the combustion-pressure node. Useful flow, mixture,
c-star and the common bore determine chamber pressure; liquid supply pressure
is no longer reported as chamber pressure. A missing reactant removes useful
combustion, chamber pressure, thrust and the library exhaust effect through the
same Modelica dataflow. Tank mass has a fixed authored initial condition.

The main bell was rebuilt through the typed Editor owner at saved component
generation 30. Measured inner neck radius is 0.0360435955 m; outer exit radius
is 0.3400000143 m, consistent with float mesh-point precision. Focused view:
`terrain/target/assembly-editor/griffin-pressure-fed-main-bell-focused.png`.
These are dimensional/visual observations, not flight-engine qualification.

A source-body numerical experiment, with opening held from 1 to 3 s, completed
five simulated seconds and reached about 1.706 MPa, 32.759 kg/s and 92.458 kN.
After closing, pressure and thrust decayed to zero. This proves the reduced
equations in isolation; it does not accept landing, replay or the full vehicle.

Full-scene trials exposed two generic Rumoca evaluation defects: Newton retry
discarded already-evaluated constants, causing an unrelated nozzle-area
division by zero; then the global absolute convergence check rejected a
2.9802322388e-8 W residual at approximately 152 MW, one representable double
step at that magnitude. The focused generic reproduction and trace are in
`terrain/target/griffin-solver-newton-before.log` and
`terrain/target/griffin-pressure-fed-refresh-trace-49781.log`. The owning Rumoca
fix retains the first finite sweep and allows at most sixteen representable
steps of roundoff per variable in addition to the requested absolute tolerance.
The bound is twice the eight-step residual observed in compound plume
photometry after the feed solution settled; it is a numerical integration
choice, not a change to the physical requirement. Failures now name the first
unmet variable and its residual instead of returning an unlocated error.
Authored landing/replay tolerances are unchanged. Production acceptance of
this new feed circuit is pending; old pump-circuit PASS results cannot accept it.

The first full production trial using raw normalized valve travel stayed
numerically healthy beyond 100 s but oscillated in descent and did not qualify
touchdown before it was stopped for command correction. At low chamber pressure,
flow per unit opening exceeds the controller's nominal capability. The valve now
converts requested flow fraction to target opening using current differential
pressure, then applies the same 0.08 s actuator dynamics and physical saturation.
The 33 kg/s capability is split into 9.1666667 kg/s fuel and 23.8333333 kg/s
oxidizer at the study O/F 2.6. This is a simulator control approximation, not a
published Astrobotic throttle/valve interface. Main command ports are explicitly
named `flow_fraction_command`; Modelica owns the conversion and delivered force.
The prior isolated opening trial proves the passive feed equations only and
predates this flow-command correction. New production acceptance is pending.

The upstream solver fix is committed and published on
`fix/algebraic-refresh-roundoff` at `135d8d393026bf06fde1e97e1899d1046117d351`.
All 116 focused owner tests pass. The core dependency is now pinned to that
immutable Git revision; the normal locked build passes. Neither the
solver fix nor this engine change establishes deterministic Griffin reload.

The pressure-compensated production trial reached qualified touchdown near
25 s, then sustained climb from one held pilot command. Six of eight command
checks passed; two new pressure checks failed. The observer incorrectly treated
all flow as reacting flow during valve saturation; it now includes the native
mixture-efficiency output. The 3 s shutdown observation also conflicted with
the existing 0.35 s pilot spool plus 0.08 s valve dynamics: reducing 1.706 MPa
below 100 Pa alone takes 0.35*ln(1.706e6/100)=3.41 s. The study requirement now
allows 4 s with cascade margin, retaining the 100 Pa threshold. This is an
explicit settling estimate, not a flight-engine shutdown rating. The sustained
burn developed increasing angular rate; upright powered-flight stability
remains unaccepted independently of command/pressure closure.

Current reduced-model acceptance, before the next performance estimate update:
normal locked Git build passes; production pilot command/pressure trial PASS 8
at tick 2037 / 33.95 s (`griffin-pressure-fed-engine-final-49788.log`). After
release it measures 28.695 Pa and 1.555 N. Fuel exhaustion PASS 11 at tick 180 /
3 s (`griffin-pressure-fed-fuel-final-49789.log`), including commanded-open ACS
extinction through shared tank availability. The affected existing propulsion
geometry/provenance observer PASS 94 on the same runtime and source revision
14210885191415472004. Oxidizer exhaustion also PASS 11 at tick 180 / 3 s
(`griffin-pressure-fed-oxidizer-final-49790.log`). These checks do not
accept powered-flight attitude, warm reload or full rover egress.


## Geometry-derived nozzle performance and rating estimate, 2026-10-05

This supersedes the inherited 33 kg/s / 93 kN sizing above. The current
[Astrobotic product](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
provides the seven-engine count. The historical
[Payload User Guide, p.26](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf)
provides a **five-engine** baseline with 700 lbf units. Applying that older
unit rating to today's seven units is an explicit estimate, not a current
flight specification. It is better constrained than the inherited generic
93 kN thrust value, but remains subject to replacement by supplier data.

The shared `LunCo.Propulsion.BellNozzle` now inverts the supersonic area–Mach
relation and obtains the exit/chamber pressure ratio from
[NASA Glenn's isentropic relations](https://www.grc.nasa.gov/WWW/BGH/isentrop.html).
The exit pressure is no longer an independent 8 kPa input. Its authored c-star
and thrust coefficient supply the chamber's effective exhaust velocity;
pressure and thrust use the same gas and throat assumptions. The model assumes
choked, attached ideal-gas expansion. It does not solve equilibrium chemistry,
flow separation, injector geometry, finite helium inventory or discrete engine
pulsing. Fuel energy is now applied to fuel mass flow rather than total
bipropellant flow.

| Current study datum | Value | Source or explicit estimation rationale |
| --- | --- | --- |
| Unit / aggregate design thrust | 3,113.755 N / 21,796.286 N | Historical 700 lbf rating extrapolated to seven current units; applicability is unconfirmed |
| Chamber / supply reference | 1.5 MPa / 2.5–3 MPa | Retained pressure study; leaves at least 1 MPa for valve/injector loss |
| Gas gamma / c-star / efficiency | 1.2 / 1550 m/s / .96 | Reduced gas assumptions; not measured Griffin performance |
| Exit bore radius / bell length / visual wall | .334 m / .52 m / .006 m | Retained visual estimates; no nozzle drawing was found |
| Throat bore radius / aggregate bore area | .018077777339853586 m / .007186840039031625 m² | Solve F=Cf(epsilon) Pc At against the estimated unit rating, using the retained exit bore |
| Vacuum thrust coefficient | 2.0218701400894896 | Native nozzle result for the above geometry and gamma |
| Nominal aggregate / fuel / oxidizer flow | 7.244798426 / 2.012444007 / 5.232354419 kg/s | Pc At divided by c-star and efficiency, then split at the inherited O/F 2.6 |
| Ideal / efficiency-adjusted exhaust velocity | 3133.898717 / 3008.542768 m/s | Native Cf × c-star, then the single chamber efficiency factor |
| Actuator admission envelope | 39,111.056 N | ceil(nominal flow × sqrt(3 MPa / 1 MPa)) = 13 kg/s, multiplied by the same efficiency-adjusted velocity; not nominal thrust |
| Initial reactant inventories | 1000 kg each | Still inherited, unsourced integration loads; not accepted flight loading |

Nozzle verification used the exact maintained model body in a temporary native
Modelica document, with explicit test inputs. Mach 2 at area ratio 1.6875 and
Mach 3 at 4.234567901234568 both match within 1e-10; pressure ratios are
.12780452546292945 and .02722368370385856. A zero-pressure chamber has finite
coefficient and zero design thrust. Griffin's native unit result is
3113.7551306823484 N. Evidence:
`terrain/target/griffin-nozzle-benchmark-final.json`. The temporary document was
closed, without persisting an alternate physics model.

The first production attempt at this sizing failed its Modelica step at 4.8 s
before touchdown: `terrain/target/griffin-nozzle-engine-49793.log`. Preserve that
failure. The upstream branch now includes start-guess constant-folding repair
(825 solve-lowering tests pass) and bounded Newton backtracking (117 algebraic
runtime tests pass). A generic square-root regression proves that a full step
can leave a valid root's domain; backtracking keeps the original convergence
tolerance. These focused passes do not accept production landing or replay.

The starvation observer now waits for **actual** reservoir depletion, then
allows one second for the public availability boundary and .08 s valve response
to settle while commands stay held. Its 10 s timeout bounds a failed command or
feed. This is an explicit test allowance: the 5 kg fuel fixture needs about
5/2.01244=2.48 s at nominal flow, plus startup and settlement. The old fixed
three-second deadline assumed the superseded larger flow. The observer still
requires the opposite feed to remain available and native combustion, RCS and
shared plume outputs to become exactly zero.


The chamber's chemical-power estimate counts fuel flow, rather than total
fuel plus oxidizer flow, against the authored fuel energy. Its reduced
reacting-temperature estimate uses the authored full temperature and mixture
loss instead of scaling temperature by throttle: at fixed chemistry, reducing
mass flow reduces total released power, rather than requiring a proportionally
colder combustion gas. The mixture curve, full temperature and efficiency
remain simulator estimates; no equilibrium chemistry or chamber thermal
transient is claimed. Missing either reactant still removes useful combustion
through the native mixture/availability equations.

Production follow-up: the domain-backtracking revision `9267b7bd` still failed
at target 4.4 s on owned port 49794. Its debug repetition on 49795 showed a
near-root late sweep followed by a restart from the cold first sweep. Upstream
`fb5eaa86` retains improving finite sweeps, with 118 focused tests passing,
but its production run on 49796 still failed before touchdown. The retained
49797 trace showed that unscaled update ranking mixed flow, pressure and
chemical power. Revision `2d5ca942` ranks finite sweeps by scaled change;
a regression with a large dependent output fails before and passes after,
and all 118 runtime tests pass. Absolute convergence and the bounded roundoff
floor are unchanged. The production rerun remains required; these focused
checks do not establish landing, pilot-flight stability or deterministic reload.


The 49798 production run with `2d5ca942` passed the earlier failing feed step
but later faulted on `PlumePhotometry.visual_intensity`: residual
6.693881e-10, beyond its unchanged convergence bound, with the Newton line
search exhausted. A bounded-output refresh was considered, but the focused
Solve-IR reproduction exposed the more general cause: runtime refresh was
solving a feedback cycle together with its one-way outputs. A dependent
exponential at gain 30 / scale 1e8 failed the whole Newton system although
it did not feed back into the two-equation cycle.

Upstream `da77eb4b` partitions that existing dependency graph into ordered
feedback blocks. It reuses the structural phase's Tarjan implementation from
one shared foundation owner; acyclic blocks follow their solved producers,
with stable independent ordering and multi-output batching retained. No
special Griffin/plume solver, relaxed tolerance or final-refresh fallback was
added. The dependent-output reproduction now passes all six selected scales;
119 runtime, 96 foundation and 232 structural tests pass. Full-scene
acceptance still requires a fresh run with this exact dependency pin.


Current production with exact pin `da77eb4b` passes the engine-command trial
(8 checks, 2049 ticks / 34.15 s, owned 49800), fuel exhaustion (11 checks,
241 ticks / 4.016667 s, owned 49802) and oxidizer exhaustion (11 checks,
151 ticks / 2.516667 s, owned 49803). Release pressure is 25.0432 Pa and
thrust .3639 N after four seconds. Five-second burn samples stay nearly
upright (Y >= .996, angular speed <= .053 rad/s); these short-run observations
do not qualify full flight control or deterministic reload. Full traces and
status snapshots are under `terrain/target/griffin-feedback-block-*`.

The visible chamber/neck now converges into the calculated throat instead
of depicting the whole .16 m neck as a throat-width pipe. Its bore radius is
**estimated** at four throat radii (chamber/throat area ratio 16), with the
retained package split equally between a convergent half and cylindrical
chamber half. This gives a recognizable chamber-to-throat topology while
preserving the adapter datum and open flow path. NASA describes that topology:
https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/nozzle-design/ .
The radius multiplier, package length, split and 6 mm visual wall are not
measured flight hardware dimensions. They do not claim chamber volume,
residence time, cooling or transient thermodynamics. The latest real photo
mostly hides the main engines beneath black insulation; it cannot establish
these internal dimensions. The existing inherited nozzle-library material
is retained, rather than inventing a flight alloy from the photograph.

Revised chamber/bell geometry PASS 94 on owned 49806, 2512 ticks / 41.866667 s,
The verdict packet pins its analyzed source revision; use that packet
rather than assuming it matches later source changes.
Editor generation 30 is saved and visually inspected; an assembled Griffin
preview resolves the revised reference. These checks do not accept reload or
landing stability. Invalid observer attachment 49805 is excluded.

The straight-up command trial additionally bounds tilt to 10 degrees
(upright Y >= cos(10deg)) and angular speed to .1 rad/s (~5.73deg/s) throughout
its five-second burn. These are **chosen integration limits**, intended to
reject a tipping liftoff even when altitude rises; they are not sourced Griffin
flight GNC tolerances. Existing lift/climb/extinction checks remain unchanged.
All ten checks pass on owned 49809 at tick 2049 / 34.15 s. Current landing
stability passes both fresh runs, but strict fresh and warm replay still fail;
see the current handover for exact failures and retained source-pinned evidence.

### Ramp breakover and route acceptance, 2026-10-05

The root guard now rises from a centre one half-strip height above the track
surface to the existing full-height downstream fold datum. Posts and web
braces follow that line. Its shape is a low-confidence interface estimate;
public Astrobotic/ESA images establish folding tracks, not the entrance ICD.
An owned production contact sample on API 49819 placed the old guard contact
at root-local `(0.00845, 0.17307, 0.70984)` m with 59.96 N s opposing impulse.
Corrected owned 49820 trials physically crossed the ramp; all four exit wheel
hits matched the retained DEM within 0.5 mm. Contact remains enabled.
The 2026 hardware release does not show integrated FLIP or deployed ramps:
https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/ .

All five demo route datums now use one horizontal port-ramp frame captured at
first egress. They are relative simulation gates, not geodetic flight goals.
Intermediate survey guidance leads one source wheelbase (1.70 m) into the
following segment, capped by its length; arrival radii remain unchanged.
The final base point remains a stop. The shared Modelica Ackermann arrival
slowdown band lies inside the arrival circle: tapering demand in the former
50 mm outside band balanced the local slope before arrival (owned 49820,
final target distance about 1.235 m versus the 1.20 m radius). The 50 mm
smoothing width and 35 percent crawl fraction are controller-study choices,
not supplier values. Owner: `LunCo.Mobility.RoverAutopilotGuidance`.
Full mission acceptance of the final controller revision is pending.
# Ramp finish and assembly interference — 2026-10-05

The real June 15 hardware photo shows broad dark folded ramp backs next to
silver framing: [NASA photo](https://www.nasa.gov/wp-content/uploads/2026/06/26-06-15-griffin-1-pressconference-1348-edit.jpg),
[gallery and date](https://www.nasa.gov/gallery/astrobotics-griffin-1/).
The existing physical walking Mesh now owns this finish on both faces; no
separate back, body, collider, mass or animated proxy is added. Coloring the
whole plate is explicitly a visual reconstruction estimate: the photograph
does not resolve the walking-face finish or structural laminate. Color,
metallic and roughness are source-owned display controls, not material data.

Typed Editor batches update the two reusable assets and six installed sections.
API 49838 vehicle generation 74 is projected and saved. All geometric and
physics attributes are unchanged; focused screenshots are
`terrain/target/griffin-ramp-dark-reusable-49838.png`,
`griffin-dark-reusable-toe-49838.png` and
`griffin-dark-starboard-toe-ready-49838.png`.
The saved-source ramp gate passes all 1281 existing checks. Its root-guide
length, turn and centre checks now follow the previously authored sloped
deck-breakover datum, rather than incorrectly requiring level guides.
Evidence: `terrain/target/griffin-ramp-finish-final-gate.log`.
The final warm preview required lease renewal and close/reopen before its
generation-74 readiness fence completed; earlier pending screenshots are not
visual acceptance.

The operator's new screenshot identifies a separate clearance defect. Typed
composed transforms put the folded toe origin at X=1.602948 m and the minimum
silver-guide vertex at X=1.469811 m; the side panel is at X=1.94 m. Thus the
current assembly intersects. The photographic finish pass does not close this
defect. Clearance must include the entire fold/deploy travel and a connected
deck transition, not just a moved visual plate. RCS mounts also need review
against the tall diagonal panel: their 60 mm skin standoff predates the
panel's 220 mm standoff. These measurements are model evidence, not released
Astrobotic installation dimensions.
