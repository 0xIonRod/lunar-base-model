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

`GRR-017` owns a replaceable two-hinge flight fold: each middle section targets
+90 degrees and each toe targets -90 degrees during descent. `GRR-018` keeps
the rail bottoms on the upper track face: the authored rail bottom and track
top are both Y=0.09 m in section-local coordinates. The focused composed-USD
check also measures all 12 rail bounds and 40 landing-leg geometry bounds in
the canonical stage frame. Its current stowed pose has a lowest rail point at
Y=5.19 m and a highest leg point at Y=2.44 m, leaving 2.75 m of vertical
clearance.

After touchdown and four-leg contact are confirmed, press **U** or choose
**UNWIND RAMP** in the guided HUD. The mission commands the four intermediate
hinges to the level deployment target, waits 3 s, then deploys the deck hinges
and waits 4 s for settling. **G** or **RELEASE ROVER** becomes available after
that settle interval. The `griffin_surface_ops::request_ramp_unfold()` Rhai
function provides the command path. `physical_ramp_hinge_report()` returns the
minimum and maximum for all six hinges in degrees and radians plus any live
angle-port records; `set_physical_ramp_hinge_angle(name, radians)` checks the
composed limits before commanding one hinge. The focused
`Verify_GriffinRampFlightStow` case
passed all 61 checks at source revision `13950898190506578966`. This is static
pose and source evidence. A 650 s wall-clock powered-descent diagnostic
stopped at 390 simulated seconds without the lander's touchdown output; it
showed intermittent leg-contact flags and continued vertical motion. Therefore,
the operator-triggered unfold, deck deployment, and release sequence have not
yet been observed in mission runtime, and the 60 s post-touchdown stability
verdict remains unavailable.
During the folded pose, the rails remained over 5 m above the body reference,
so they could not have made ground contact during the sampled descent. The
stow angles remain study assumptions until a supplier mechanism ICD is
available.

## Evidence

`scenarios/tests/griffin_ramp_requirements.rhai` observes the composed ramp
instances in the Griffin vehicle document. It supplies typed USD facts and FLIP
wheel measurements to generic source constraints; it does not author a second
ramp limit or reinterpret a boolean Rhai predicate as requirement evidence.
