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
  a separate payload-deck collider. GRR-012 still stays inconclusive until the
  composed transition/contact geometry is available to the typed observer.
  The transition length is a SysML study datum derived from adapter half-width,
  hinge station, and contact overlap; it is not itself acceptance evidence.
- The ramp contact geometry uses two FLIP-aligned tracks, not a solid plate
  across the open centre. The same source wheel stations and track width drive
  render geometry and physical colliders.

## Evidence

`scenarios/tests/griffin_ramp_requirements.rhai` observes the composed ramp
instances in the Griffin vehicle document. It supplies typed USD facts and FLIP
wheel measurements to generic source constraints; it does not author a second
ramp limit or reinterpret a boolean Rhai predicate as requirement evidence.
