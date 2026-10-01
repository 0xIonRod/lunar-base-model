# Rounded Griffin ramp pivot plates

Replace the rectangular visual lug blocks with native extruded rounded plate
profiles. Existing 60 mm plate width gives a 30 mm outer end radius, leaving
10 mm radial stock around the estimated 40 mm pin. Plate thickness remains
10 mm. Height and centre derive from each section axis, track bottom and upper
chord. Native profile extrusion is centred across thickness; the plate centre
therefore shares the guide/pin Z station exactly. Extents derive from actual
mesh vertices. One guide group owns one profile generation to keep Rhai plans
bounded. The existing native extrude_profile and material planners suffice;
no Rust or new geometry library was added.

GRR-008 and GriffinEgressRamp record the source links and low-confidence
rounded-outline/radial-stock interpretation:
https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander
https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png
Public artist renderings do not establish machining, bores, bearings or load
capacity. The visible pin obscures an unmodelled bore; these plate blanks are
visual reconstruction, not manufacturing-ready hardware.

All USD changes used Editor API49746. Shared deck profiles inherit into both
ramps; toe and middle profiles retain their native hinge-specific heights.
Existing silver-metal material is reused. Collision ownership, articulated
joints, section poses and mass properties were retained.

The observer now checks Mesh presence, vertex-derived local extent endpoints,
and pin-to-lug lateral alignment. Its former extent_component observation
only implements Cube size*scale and was unsuitable for a Mesh. The existing
array_component observer reads standard USD extent coordinates instead.

Terrain a7707995c was rebuilt successfully using the reusable optimization
build cache. The private copied binary reports a7707995. The current ramp gate
passes 1157 checks at source revision 9494185534342527621, 60 Hz, one thread,
zero jitter. Source provenance passes 207 targets/records, 47 sources, 3 roles.

Isolated section preview document115603934347739, view1, generation0 was
visually reviewed. Screenshot griffin-rounded-ramp-pivots-2026-10-01.png shows
the rounded plate tops and pin connection in the shared section. Combined
preview framing remains unreliable: canonical USD reports metre-scale poses,
while FrameUsdPreviewSelection targets hundreds of metres away. Pausing and
reopening did not resolve this. Gravity was suspected but is not established;
do not claim this component review accepts the combined live scene.

The owned review processes exited137 during this turn; cause is unestablished.
The final screenshot preceded the last exit. Old review API49746 is now
unavailable. Native model/gate evidence remains available. The failed first
terrain link was disk exhaustion; cargo clean removed only this turn's
initial fresh terrain/target artifacts, then the cached build succeeded.
Full landing, deployment and FLIP egress remain open.
