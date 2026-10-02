# Griffin ramp model contract

Visual component: `components/lander/griffin_ramp_visual.usda`
Requirements and visual dimensions: `requirements/griffin_ramp_requirements.sysml`

The standalone visual ramp asset remains available for component previews. The
integrated vehicle uses the six articulated physical hinge joints and their
render geometry; its mount sockets do not instantiate a second static ramp.
Section identities, dimensions, support members, appearance, wheel clearance,
hinge limits, and drive values are owned by the SysML source and checked by the
shared SysML/USD requirements evaluator.

## Ownership

- `GriffinRampRequirements::GriffinEgressRamp` owns the standalone visual
  dimensions, physical child and hinge identities, and port/starboard
  deployment datums.
- `GRC005_DeploymentCommandWithinLimit` owns the symmetric command acceptance
  boundary in radians.
- `GRC003_WidthClearsFlipWheelEnvelope` checks the FLIP lateral wheel stations,
  half wheel width, and authored clearance against the outside rail envelope.
- `GRC016_ContactTrackClearsTire` checks each separate contact-track width
  against the source wheel width and two side clearances.
- The physical ramp bodies, six hinge joints, and deck transition belong to
  the physical Griffin model. The two root deck hinges and four section hinges
  each expose the same source-owned angular drive values; the root joints had
  limits but no drive before this repair. The render component does not provide
  a collider, mass, inertia, or another physical body.
- FLIP remains a referenced rover component; the ramp requirement reads FLIP's
  wheel datums through its SysML source.
- The physical top deck uses eight hidden convex perimeter-beam colliders and
  a separate payload-deck collider. GRR-012 reads exact composed collider
  vertices for the adapter, transition, and ramp track together from one USD
  snapshot for each side. It measures minimum cross-section overlap across the
  adapter's complete lateral span, transition length, top-face step, and hinge
  seam. The clipped octagonal adapter makes AABB intersection too coarse to
  prove overlap. SysML owns the transition length and minimum actual overlap.
  The result is static interface evidence; rover traversal still needs
  runtime wheel-contact evidence.
- GRR-006 checks the composed physical track's convex collision bounds and toe
  mesh vertices against SysML geometry. A shared mechanical relation derives
  the toe bevel from track thickness and deployment angle; it is not another
  Twin-owned length literal.
- GRR-010 checks both toe edges against the authored terrain height. Source
  geometry places the physical track centre at Y=5.19 m, aligns its top to the
  adapter at Y=5.28 m, and uses a 12.228605 m top face at 27.833532 degrees
  from the 0.44 m vehicle-reference touchdown datum. These are replaceable
  study values. The focused GRR-010 check passed at source revision
  `13950898190506578966`; both toe edges compute at terrain Y=0 within numeric
  precision. Runtime deployment and rover traversal remain unverified.
- GRR-011 owns the existing ramp-body mass and diagonal inertia in SysML and
  checks the composed body matches those values. They remain labeled Twin
  study proxies; center of mass and supplier mass properties are still open
  under GR-021.
- The ramp contact geometry uses two FLIP-aligned tracks, not a solid plate
  across the open centre. The same source wheel stations and track width drive
  render geometry and physical colliders.

## Physical flight stow and rail clearance

`GRR-017` owns the image-based flight-stow pose: both roots use a +45 degree
Z rotation, and the starboard root also uses a 180 degree Y mount. Under the
simulator's fixed-axis `rotateXYZ` convention, their
lander-frame headings are +45 and +135 degrees. The 180 degree Y mount makes both
folded bundles mirror across the lander's X=0 centerline, with 6.4 m between
their root stations. Both intermediate hinges turn 180 degrees to fold
each three-section ramp into its transport bundle. Their full +/-180 degree
travel remains available for commanded deployment and inspection. These angles
are replaceable study estimates from the user-provided Griffin reference, not
released supplier geometry. The root hinges retain source-owned asymmetric
travel: port runs from -50 to +60 degrees and starboard from -60 to +50
degrees; the terrain targets remain -27.83 degrees port and +27.83 degrees
starboard.
`GRR-018` keeps the rail bottoms on the upper track face: the authored rail
bottom and track top are both Y=0.09 m in section-local coordinates. The
focused composed-USD check measures all 12 rail bounds and 40 landing-leg
geometry bounds in the canonical stage frame.

NASA describes Griffin's ramps as folding ramps and Astrobotic documents the
optional egress-ramp interface, but public material does not publish the
flight-stowed mechanism geometry or supplier ICD. The reference image controls
this study pose; the mirrored +45/-45 degree local Z rotations, starboard
180 degree Y mount, and asymmetric travel remain explicit replaceable
assumptions, not a claim of released flight-hardware geometry.

Press **U** or choose **OPEN RAMPS** to unfold, and **F** or **DETACH ROVER**
to release FLIP. Both manual actions remain available during flight and landing.
The autonomous mission waits for touchdown. Intermediate hinges move through
measured halfway poses before leveling; the root hinges then lower. Automatic
release requires the source-owned sampled hinge settlement dwell. A flight
opening is a mechanism pose, not terrain-contact or egress acceptance.

The 2026-10-02 wheel-path correction shortens each central hinge shaft from
2.592 m to 1.408 m, the derived gap inside the two inner rails. Four rail-local
coaxial pins retain the visible bearings. This avoids a transverse shaft above
the tire corridors while preserving the folding axes. The split-shaft layout
is a low-confidence reconstruction from the paired open trusses in the
[Astrobotic reference](https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png)
and the operator's obstruction report; public supplier hinge drawings are
unavailable. GRR-015 owns this clearance requirement. The USD section assets
and integrated vehicle use the same derived shaft length.

Before this change, the owned live scene measured all three deployed port
section normals upward (Y > 0.890) and aligned, and recorded FLIP ramp exit.
That excludes an inverted section in that run, but does not establish general
clearance or traversal acceptance for the revised geometry.

## Evidence

`scenarios/tests/griffin_ramp_requirements.rhai` observes the composed ramp
instances in the Griffin vehicle document. It supplies typed USD facts and FLIP
wheel measurements to generic source constraints; it does not author a second
ramp limit or reinterpret a boolean Rhai predicate as requirement evidence.
