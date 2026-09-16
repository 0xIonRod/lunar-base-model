# Griffin-1 lander and FLIP rover study specification

This is the acceptance contract for the Twin model. It separates public
mission facts from geometry values that are simulator study assumptions. A
public reference is not treated as an as-built CAD drawing.

## Reference basis

- Griffin is modelled as a medium-class lunar lander for a south-polar mission.
  Astrobotic's current Griffin page describes an aluminum frame, an isogrid
  payload deck, four landing legs, optional payload/rover ramps, and solar
  power intended to point toward the Sun. See the primary references:
  `https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/` and
  `https://www.astrobotic.com/media-kit/images/`.
- The public Griffin payload class used here is 625 kg. Astrobotic's current
  product material describes seven main engines and four attitude-control
  thruster clusters; the twelve actuator identities in this Twin are a control
  topology, not a claim about final Griffin flight hardware.
- FLIP is the Astrolab FLEX Lunar Innovation Platform announced for Griffin-1.
  Public material is not sufficient to claim exact FLIP CAD dimensions, so the
  Twin labels its four-wheel all-wheel-steer geometry as a study proxy.
- The landing site is a Nobile regional anchor backed by LROC NOBILE03. The
  exact Griffin touchdown coordinate remains unresolved; local terrain is
  therefore an ENU study frame, not a claim about the flight trajectory.

## Authored geometry contract

The following are simulator acceptance bounds, not public as-built dimensions.

### Lander

- The visible primary body is a boxy, rectilinear airframe: 5.4 m maximum
  width, 3.2 m body height, and 5.4 m maximum depth. A cylindrical source
  placeholder must not remain visible in the Griffin wrapper.
- The top is a clean, solid payload deck with one adapter interface for FLIP.
  No lander high-gain antenna, loose mast, or decorative part may occupy the
  adapter clearance volume.
- Four direct landing-leg struts terminate at four direct solid pads. Struts
  and pads have collision enabled and are outside the rover's centre lane;
  obsolete reference-leg visuals are hidden so they cannot create a second,
  disconnected gear set. Each pad must meet the lower end of its strut in the
  nominal pose; a visually nearby but geometrically separate pad fails this
  contract. The accepted study pose uses a radial rake: strut centers at
  `(+-2.475, -3.125, +-2.475)`, half-span `1.725 m`, and pad centers at
  `(+-2.65, -4.85, +-2.65)`.
- Two side-mounted solar arrays are sized as the lander's primary polar power
  surfaces. Each array is a continuous solid panel with a backing/frame and a
  rigid mount to the side wall. It must not be a floating visual-only plane.
- Two solid egress ramps have collision surfaces and two visible edge rails on
  the outside/accessible side of each ramp. Each root has a solid hinge-support
  block tied into the deck. The accepted stable pose is an authored
  deployed/integrated ramp from the payload deck to the terrain. A
  future articulated fold must preserve this same swept-volume contract; the
  unstable independent rigid-body hinge variant is not part of the accepted
  runtime.
- The ramp swept volume, solar panels, legs, pads, and adapter are disjoint at
  the nominal deployed pose. FLIP cannot be mounted through a ramp or panel.

### FLIP rover

- FLIP is a separate reusable assembly with a rigid chassis, a payload deck,
  a clearly identified forward sensor mast, four wheel assemblies, and four
  suspension carriers.
- Each wheel is a solid cylinder with authored radius 0.45 m and width 0.28 m
  in this study. Each has a wheel attachment index, drive connection, steer
  connection, collision geometry, and suspension clearance.
- The drivetrain exposes two explicit stopped-vehicle steering modes:
  Ackermann and crab. Crab steers all four wheels to the same heading and is
  allowed only while stopped or below the configured crawl threshold. Changing
  modes must not add a second input path or leave stale per-wheel steering.
- The rover body, wheels, legs/ramp, and terrain collider are solid. A wheel
  ray, wheel axle, or rover chassis must not pass through a lander leg or ramp.
- FLIP keeps its electrical solar component for power-network semantics, while
  its visible rear-deck backsheet and cells are authored as explicit solid
  geometry so the visual and collision contracts are inspectable.

The current runtime realization deliberately selects the rover's `raycast`
drivetrain variant and disables the optional `Thermal` network. This preserves
the solid four-wheel geometry and the single steering interface while the
runtime gaps below are resolved; the authored physical-joint and thermal
variants remain useful engineering targets, but are not accepted as a working
mission configuration until they pass the same runtime tests.

## Runtime and presentation contract

- View shows a single mounted Twin; Editor shows the exact reusable assembly
  document. Editing `vehicles/griffin_1.usda` must leave the Griffin-only USD
  preview visible rather than previewing the complete surface-operations scene.
- The USD document has both an editable text tab and a paired 3D preview for
  the same document/edit target. Opening a USD file must not route it through
  Modelica source parsing or cause a scene reload.
- Possession identifies either Lander or FLIP unambiguously. Lander controls
  use thrust/pitch/roll/yaw/release; FLIP controls use drive/steer/brake and
  report the active steering mode.
- The polar scene uses the same authored lunar light for lander, rover, and
  terrain. Terrain processing records the source coordinate, projection,
  vertical datum, and generated output while downloaded/generated bytes stay
  ignored by Git.

## Evidence required for acceptance

1. Run the Twin-owned Rhai requirement gate from `twin.toml` and keep its
   structured verdict/evidence with the authored changes. Static source checks
   are not an acceptance substitute for a composed-stage Rhai observation.
2. In the headful Editor, capture a Griffin-only preview showing the clean top,
   side panels, four-leg envelope, and rail-equipped ramps.
3. In View, inspect both vessel records, possess the lander, release it, then
   possess FLIP and demonstrate Ackermann -> stopped crab -> drive -> brake.
4. Inspect the saved USD document and confirm `dirty=false`, the expected
   references/relationships, collision fields, and no duplicate scene reload.

## Known boundaries

Exact Astrobotic manufacturing drawings, final Griffin touchdown coordinates,
and final FLIP wheel/suspension data are not public in this checkout. Those
facts must be replaced when authoritative CAD or mission data becomes
available; the validator should then be tightened rather than silently
changing the assumptions.

Current Rust/runtime gaps that prevent claiming the full acceptance sequence:

- the live USD projector currently promotes `PhysicsCollisionAPI` geometry
  below a rigid body as independent physics bodies instead of aggregating the
  authored compound. The source intentionally keeps collision schemas on the
  deck, panels, ramps, rails, struts, pads, and hinges; until the projector
  owns compound-child admission, a live Griffin preview can visibly separate
  those parts even though the USD source is connected;
- the physical FLIP wheel-joint variant can escape the bounded physics world;
- the current ramp fold/joint path needs a stable compound-body articulation;
- the optional FLIP thermal graph currently needs algebraic-solver support that
  the active RK45 backend does not provide;
- the generic `SetPorts` API is a one-tick command, while a safe stop on a
  slope needs a held intent; the Twin helper now uses the existing persistent
  `SimulateIntent` path for this case;
- a native replicated vehicle-mode intent is missing, so crab/Ackermann mode is
  currently a typed Twin-local command rather than a first-class input action;
- replacement landing-contact proxies cannot yet bind to the source lander's
  name-bound leg channels without reintroducing the unstable source bodies;
- USD composition needs a shared presentation-only marker and stronger
  domain-qualified document handles so Editor previews cannot be confused with
  live scene entities;
- the Editor needs schema-aware transform/color setters that preserve USD
  xform order and array value types.
