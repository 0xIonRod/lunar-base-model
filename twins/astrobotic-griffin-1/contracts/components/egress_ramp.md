# Egress ramp component contract

Component: `components/lander/egress_ramp.usda`

Status: Twin study component; public reference establishes the two-side ramp
concept and the tested egress angle, not a complete mechanical ICD.

Public reference:

- https://www.astrobotic.com/astrobotic-griffin-lander-and-nasas-viper-moon-rover-complete-complex-test-drives/

## Ownership

The component root owns its local geometry, mass/collision envelope, hinge
datum, mount socket, deployment-limit metadata, and provenance. The Griffin
assembly owns each instance's placement, side identity, host-facing revolute
joint, and cross-component wiring.

## Local frame and topology

- Y-up, right-handed, SI metres; component origin is the hinge axis.
- Root: `/EgressRamp`, type `Xform`, one independently reusable component.
- Required geometry: `Surface`, `EdgeRail`, `EdgeRailInner`, `HingeBlock`, and
  `MountSocket`.
- `Surface` and both rails are solid contact geometry with enabled collision.
- `MountSocket` is a visual/mount datum and does not create a second body.
- The component has one rigid body; the parent assembly supplies the
  host-facing revolute joint when the component is mounted.

## Parameters and limits

- positive authored `physics:mass` and diagonal inertia;
- `lunco:deployment_angle_limit_rad` is positive and bounded by the Twin
  study limit;
- each deployed instance publishes `lunco:deployment_angle_rad` in radians;
- the transform angle is in degrees because USD `rotateXYZ` is degrees; the
  Rhai command/lint boundary checks the conversion and does not duplicate it in
  Modelica or Rust.

The 33-degree egress value is a public test reference. The component's exact
length, width, mass, inertia, rail section, hinge dimensions, and placement are
study values and must remain labelled as such.

## Required evidence

The component test is read-only and must report exact missing/malformed paths.
It checks topology, types, visibility, positive mass/inertia, contact collider
flags, provenance, deployment limit, and boundary values at the limit and just
outside the limit. It does not repair the stage or prove assembly placement.
