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
- `GRC003_WidthClearsFlipWheelEnvelope` checks the FLIP wheel stations, wheel
  radius, and authored clearance against the ramp width.
- The physical ramp bodies, hinge joints, and deck transition belong to the
  physical Griffin model and its separate requirements. The render component
  does not provide a collider, mass, inertia, or a second physical body.
- FLIP remains a referenced rover component; the ramp requirement reads FLIP's
  wheel datums through its SysML source.
- The physical `TopDeckCollisionProxy` currently uses the obsolete six-sided
  study footprint, while the required bus/deck profile is octagonal. The
  existing 1.21 m deck transition is a legacy value and not acceptance data;
  GRR-012 stays inconclusive until Editor readback provides a recomputed
  overlap and confirms the octagonal collider.

## Evidence

`scenarios/tests/griffin_ramp_requirements.rhai` observes the composed ramp
instances in the Griffin vehicle document. It supplies typed USD facts and FLIP
wheel measurements to generic source constraints; it does not author a second
ramp limit or reinterpret a boolean Rhai predicate as requirement evidence.
