# Exterior blankets and tether feasibility — 29 October 2026

The operator confirmed that manual detachment works and requested a proper
tethered deployment if practical, otherwise a visual pass. This revision uses
that visual-first fallback. It preserves the existing adapter-release, rover
possession and brake handoff, without claiming automatic restrained descent.

## Physics feasibility boundary

The checked LunCoSim source supports `PhysicsDistanceJoint`, mapping its two
anchors and distance bounds to a native Avian distance constraint. A fixed
distance constraint can restrain separation; it does not itself model fabric
tether payout or wheel wrapping, slack-to-taut contact, braking losses, load
sharing or release after surface transfer. No maintained reusable tether/winch
Modelica component was found in the checked `assets/models/LunCo` source set.
This is a bounded capability check, not a claim that the engine cannot implement
a tether model. No artificial trajectory, transform animation or new force is
used to stand in for the missing physics.

A later 1D Modelica bench can qualify a coordinate along the study ramp, gravity,
wheel/brake torque, unilateral tension, payout and energy balance. Its coupling
to the real 3D bodies needs a separate force/interface and surface-transfer test;
solving a 1D trajectory alone would not qualify the actual deployment. Unknown
tether stiffness, damping, strength, routing and payout parameters must remain
explicit assumptions until sourced. Tether work remains deferred here.

## Visual correction

[NASA/JPL PIA26708 hardware imagery](https://science.nasa.gov/photojournal/voyager-technologies-griffin-1-completes-environmental-testing-at-nasa-jpl/)
shows extensive predominantly silver/white exterior blanket coverage. The
earlier reconstruction left the bus side bays exposed. Eight new finite-thickness
blanket panels now fill those existing frame bays, with sixteen small tape tabs.
The seam/tape pattern remains illustrative, not an as-built blanket drawing.

The pure plans in `griffin_exterior_blankets.rhai` read the existing upper and
lower stock-box rings in `PerimeterFrame`. Each face's center, orientation,
width and vertical span derive from those source vertices. SysML owns only the
edge gap, thickness, inset, tape dimensions and selected finish values. This
preserves the actual irregular octagon rather than inventing another bus size.
The panels sit slightly behind the structural outer faces and between their
upper and lower rails. The compact ramp geometry and rover deck are untouched.

The existing `ExteriorPanels` foil network is reused with the same finer-fold
parameters selected for the skirt. The small tabs reuse `ServiceConnectors`'s
existing metallic finish as a visual approximation. No shader source, light,
exposure, thermal property, collider, joint, mass or inertia is changed.
All twenty-four added shapes have render purpose, disabled collision, and only
MaterialBindingAPI. They provide no structural or thermal authority.

## Verification

- All eight source-frame face gates pass geometry, transforms, bindings and
  render/physics ownership checks. Every face was applied, projected, read back
  and explicitly saved through the native document owner. An early readback
  sampled an unsettled projection; it was retried after matching generation.
- The actual composed review scene loads ready with zero runtime errors or
  warnings. Its live saved-source projection and original-camera render show
  the new silver coverage. See the [review frame](../handover/griffin-exterior-blankets-2026-10-29.png).
- Existing manual departure regression: PASS, exit 0, six checks, seed
  6840157149251759617, 60 Hz, default threads, verdict tick 1565 / 26.0833 s.
  Actual adapter removal remains tick 1385, with thirteen joints/graph edges,
  manual possession and brake release, followed by 0.6302798 m signed forward
  movement. This is not full ramp or tether descent acceptance.
- Repository structural validation and `git diff --check` pass.

Local authoring journals, frame-bay checks and complete test logs are retained
under `runs/griffin-exterior-blankets-2026-10-29/`.
