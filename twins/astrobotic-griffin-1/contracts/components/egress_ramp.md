# Griffin ramp model contract

Visual component: `components/lander/griffin_ramp_visual.usda`
Requirements and visual dimensions: `requirements/griffin_ramp_requirements.sysml`

The two Griffin ramps reference the same replaceable visual component from the
vehicle assembly. The visual asset contains render geometry only. Its identity,
child names, dimensions, support members, appearance, wheel clearance, and
deployment limit are owned by the SysML source and checked by the shared
SysML/USD requirements evaluator.

## Ownership

- `GriffinRampRequirements::GriffinEgressRamp` owns the shared visual dimensions,
  child identities, and port/starboard deployment datums.
- `GRC005_DeploymentCommandWithinLimit` owns the symmetric command acceptance
  boundary in radians.
- `GRC003_WidthClearsFlipWheelEnvelope` checks the FLIP lateral wheel stations,
  half wheel width, and authored clearance against the outside rail envelope.
- `GRC016_ContactTrackClearsTire` checks each separate contact-track width
  against the source wheel width and two side clearances.
- The physical ramp bodies, hinge joints, and deck transition belong to the
  physical Griffin model and its separate requirements. The render component
  does not provide a collider, mass, inertia, or a second physical body.
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
  adapter at Y=5.28 m, and uses a 12.228605 m top face at 49 degrees from the
  3.98 m touchdown COM datum. These are replaceable study values; the typed
  Editor update and deployed runtime traversal have not been read back yet.
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

After the touchdown event, `griffin_1_surface_ops.rhai` waits 1.5 s, commands
the four intermediate hinges to the level deployment target, waits 3 s, and
then deploys the deck hinges. The focused `Verify_GriffinRampFlightStow` case
passed all 61 checks at source revision `1134567362502136608`. This is static
pose and source evidence. A separate 33.3 s powered-descent run did not reach
touchdown, so the unfold and deck-deployment commands have not yet been
observed in mission runtime. The stow angles remain study assumptions until a
supplier mechanism ICD is available.

## Evidence

`scenarios/tests/griffin_ramp_requirements.rhai` observes the composed ramp
instances in the Griffin vehicle document. It supplies typed USD facts and FLIP
wheel measurements to generic source constraints; it does not author a second
ramp limit or reinterpret a boolean Rhai predicate as requirement evidence.
