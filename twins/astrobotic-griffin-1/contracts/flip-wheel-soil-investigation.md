# FLIP wheel–soil model investigation

25 November 2026. Baseline simulator commit `9cdbfc594`, Twin commit
`3f1850a`. The [motion contract](flip-motion-runtime.md) records the completed
steering correction and its production acceptance. This investigation extends
the force comparison beyond the two rolling angles used in calibration.

## Repeatable force-law failures

The native steering test passed its eight acceptance constraints. Its inputs
and limits establish an operator handling envelope on one terrain. In
particular, it checks the mounted WES calibration knots, wheel loading and
the presence and sign of applied forces. The test does not independently
measure the magnitude of lateral force in a pivot.

For this study the exact committed Rust `PatchResponse` and shear limiter
were extracted into a small executable and evaluated at the prescribed
kinematics of different WES Table 2 tow runs. For carriage speed (V_c), yaw
angle `a`, and reported tread speed `Vw`, the inputs are
`vx = Vc*cos(a)`, `vy = Vc*sin(a)`, and `tread = Vw`. The geometry and
soil parameters are the current FLIP surrogate (radius 0.465 m, width
0.280 m, nominal friction 0.60, effective pressure gradient 980 kPa/m,
cohesion 760 Pa, friction angle 38.5°, shear scale 25 mm). The coupled
column uses the passive longitudinal denominator of 4 m/s and stiffness
8,000 N per unit slip, matching the inherited regolith tire. This is a
constitutive-law evaluation, with the recorded hub motion and wheel speed
prescribed independently. It is distinct from a native dynamic tow rig,
and the Apollo measurements use a different wheel and terrestrial gravity.

| WES test | Yaw | Load (N) | Measured side force (N) | Predicted with zero longitudinal demand (N) | Predicted at reported tread speed (N) |
| --- | ---: | ---: | ---: | ---: | ---: |
| 25 | 5° | 277 | 71.4 | 67.6 | 67.6 |
| 27 | 10° | 276 | 113.0 | 102.7 | 102.7 |
| 28 | 15° | 276 | 134.8 | 109.2 | 106.9 |
| 30 | 40° | 274 | 144.8 | 155.8 | 61.5 |
| 45 | 40° | 188 | 101.1 | 109.2 | 31.9 |
| 46 | 65° | 188 | 152.2 | 114.4 | 34.4 |
| 47 | 85° | 186 | 235.5 | 113.7 | 111.9 |
| 48 | 90° | 185 | 204.9 | 113.1 | 113.1 |

Source: [Green, NASA-CR-143290, Table 2](https://ntrs.nasa.gov/api/citations/19750021903/downloads/19750021903.pdf#page=41).
The report gives approximately 2.99 cm rut depth for test 47; the current
model estimates 4.98 mm static-equivalent sinkage. Rut depth and instantaneous
wheel sinkage are different observables, but this large discrepancy motivates
measurement of both.

### Why these failures occur

1. **High lateral slip.** At test 47 the tread limit is 111.6 N and the
   estimated passive side contribution is only about 2.2 N. Even assigning
   the entire tread force budget to the side force cannot reach the measured
   235.5 N. The pressure-gradient proxy, shallow footprint and omission of
   dynamic soil displacement restrict the resistance.
2. **Combined longitudinal and lateral slip.** The current code projects
   the longitudinal stiffness demand and the empirical lateral demand onto
   a circular Coulomb bound. At test 30, applying the observed tread speed
   reduces predicted lateral force from 155.8 N to 61.5 N, while the
   predicted longitudinal force is −152.9 N. The WES corrected wheel-plane
   pull was −39.2 N. A single combined-slip law must account for both
   components, the pressure resultant and soil displacement. Scalar
   independent calibration followed by circle projection is insufficient.
3. **Torque-mode discontinuity.** In the native axle path, the longitudinal
   slip denominator switches when drive torque becomes nonzero or braking
   becomes active. With an identical 182.25 N normal load, 0.20 m/s
   longitudinal hub speed, 0.21 m/s tread speed and +0.10 m/s lateral speed,
   the two branches give `Fx = +20.0 N, Fy = −67.6 N` (passive) and
   `Fx = +107.7 N, Fy = −19.7 N` (active). No physical change in contact
   state occurred. This creates an artificial force change around
   throttle/brake transitions and interacts with saturation.
4. **Soil state and motion resistance.** The sinkage estimate depends on
   wheel load alone. Soil shearing is computed from instantaneous lateral
   speed and a regularized residence time, so the wheel cannot dig in,
   recover, or retain soil deformation history. At perfect rolling with
   zero slip, longitudinal contact demand is zero. Soil compaction
   resistance and its associated axle torque are absent. The simulated
   static normal reaction is still supplied by a rigid DEM contact.
5. **Slip-angle interpretation.** A real 85° tow becomes approximately 51°
   in the existing angle expression because the longitudinal denominator
   is floored at 1.07 m/s. A validated-speed bound should describe evidence
   validity. The physical kinematics and the numerical treatment near zero
   total slip velocity need independent definitions.
6. **Control allocation.** `FlipManualSteering` is a proportional yaw-rate
   regulator with a low-speed deadband. Any steady resistance requires
   nonzero yaw error. Its demand enters `RoverDrivetrain`, whose separate
   clipping of throttle plus/minus steering reduces differential authority
   at full throttle. Program and autonomous maneuver authority also follow
   different paths. These are controller properties, independent of the
   contact model. The passed driving tests establish that the current
   combination works on the test terrain.

The first three discrepancies were reproduced numerically. Items 4–6
follow from the committed equations and runtime ownership. They do not
establish a particular real-FLIP trajectory error.

## Proposed physical and control model

Use a reusable per-wheel Modelica terramechanics model with FLIP-specific
geometry, wheel parameters and soil calibration. DLR's Contact Dynamics
library describes an analogous separation of wheel geometry, contact
detection, and replaceable reaction models. It includes methods based on
Bekker and Janosi–Hanamoto as well as TerRA, a lower-cost dynamic model
which tracks slip-dependent sinkage. This supports a reduced-order Modelica
reference model for system simulation, calibrated against a more detailed
wheel test or soil model.
[Buse, Pignède and Barthelmes, Modelica Conference 2023, sections 3 and 4.3](https://elib.dlr.de/200107/1/Buse-A_Modelica_Library_to_Add_Contact_Dynamics_and_Terramechanics_to_Multi-Body_Mechanics-162_a.pdf)

The proposed model should have these physical parts.

- Pressure–sinkage law, for example Bekker pressure
  `p = (kc/b + kphi)*z^n`, using measured pressure–sinkage coefficients.
  Use the distributed footprint and total normal load to solve effective
  contact depth. A future deformable ground implementation may instead own
  normal force from the current penetration.
- One vector soil shear law based on longitudinal and lateral relative
  motion and mobilized shear displacement, with a Mohr–Coulomb strength
  envelope and identified shear displacement scale. Derive the reactions
  together, including at high yaw, wheel spin, braking and reverse.
- Soil compaction and passive side-face resistance with separately
  identifiable work, genuine rolling resistance, and a consistent axle
  reaction torque. Resolve the stress resultant over the footprint to
  obtain force and moment.
- Dynamic slip-sinkage and shear history with contact renewal, and a
  low-speed static/shear treatment. Parameter identification must
  determine the required complexity from measured force and torque
  transients. Treat unloaded wheels and recontact explicitly.

[Ishigami et al. (2007), wheel-soil forces and rover steering validation](https://doi.org/10.1002/rob.20187)
provides a reference for lateral force in an articulated rover.
[Niksirat, Daca and Skonieczny (2020)](https://doi.org/10.1177/0278364920913945)
show measured differences in traction and sinkage at fixed wheel load with
different soil gravity. Gravity scaling needs independent qualification.
The WES tow data cannot identify driven-wheel traction, FLIP's flexible
wheel compliance, or transient soil state by itself.

For the controller, use a separate Modelica speed/yaw-rate regulator.
Request signed longitudinal speed and yaw rate. For track width `T`, the
nominal side speed difference for right-positive yaw is `T*yaw_rate`.
Account for skid rather than enforcing that relation kinematically.
Control each side's delivered torque with speed/yaw feedback, feedforward
resistance where identified, bounded integrators and anti-windup. Allocate
the common and differential commands together under each motor's torque,
speed, current and traction limits. Manual and route commands can share
this allocator while retaining their own command authority. The skid-steer
physics determines actual trajectory and slip.

## Runtime ownership and integration

| Owner | Responsibility |
| --- | --- |
| USD | Wheel radius/width, axle and material identity, authored Modelica binding, soil parameters and validation provenance. |
| Modelica/Rumoca | Constitutive equations, soil shear/sinkage state, wheel-side force and torque response, drive and control dynamics. |
| Native mobility + Avian | Contact detection, support identity, contact frames, authoritative chassis/wheel state, normal-load ownership, implicit spin solve, application of forces and moments to the correct bodies. |
| SysML and Rhai | Declared force and control requirements, prescribed wheel experiments, production maneuvers and measured verdicts. |

The contact constitutive interface needs wheel hub longitudinal and lateral
velocity relative to the support, wheel angular velocity, normal reaction
(or penetration in a deformable-soil implementation), wheel geometry, soil
parameters and time step. Its outputs are tangential forces, corresponding
contact moment/axle torque, estimated sinkage and dissipated power. The
wheel integrator must evaluate the force response at trial axle speeds,
then commit soil state exactly once for the accepted interval. Repeated
trial evaluations must leave the state unchanged.

The native axle solver currently evaluates the same Rust response inside
its implicit balance and for force application. A regular Modelica
co-simulation port carries interval samples. Connecting a fresh Modelica
force output directly to the generic force actuator would bypass the
shared axle force balance and could double-count native friction. A
reusable solver-side constitutive evaluation boundary is needed for
Modelica's real-time use, including torque residual bounds, deterministic
state commit, contact identity and support reaction. The force bounds must
reflect the selected constitutive law instead of assuming every reaction
is subject to the old tire's Coulomb circle.

Start with native normal support and compare a load-prescribed Modelica
wheel reference against the native response. A later contact realization
that computes load from deformation must replace the native normal
constraint for soil contact so that each normal reaction has one owner.
The rigid ramp and rock path should retain native rigid contact.

## Verification sequence before replacement

1. Establish an executable single-wheel tow/drive reference, with prescribed
   geometry, load, carriage velocity and wheel speed. Compare both force
   components with WES tests 21–48, retaining distinct training and
   held-out load, angle and speed groups. Use independent driven-wheel
   data for traction, braking and axle torque. Specify error limits before
   fitting. Treat FLIP-specific accuracy as open under FMR-005.
2. Exercise zero load, recontact, both slip signs, pure lateral slip,
   zero-slip rolling, wheel spin, combined slip and drive release at
   identical kinematics. Require continuity except where a declared
   physical mode transition admits an impulse. Check force and moment
   invariance under equivalent contact subdivisions, correct support
   reactions, dissipated work and energy balance including stored soil
   state.
3. Close the numerical loop with the shaft and wheel inertia. Compare
   Modelica reference and native coupled solutions at 30, 60 and 120 Hz
   with controlled solver settings and verify convergence, stable
   dissipative response and correct torque/heat accounting.
4. Rerun FMR-002 through FMR-004 plus parking, braking and route tracking,
   on level terrain and representative grades and soil conditions.
   Retain full time histories of slip, wheel load, reactions, drive
   current/torque, vehicle yaw, lateral speed, sinkage and steering demand.
   Require repeatability and compare against the reference with declared
   tolerances.

## Implemented revision

The simulator tutorials worktree now contains the prepared, event-free
algebraic `LunCo.Mobility.RegolithWheelContact` model. The native axle
solver uses its constitutive response during trial speeds and for the
accepted force and rolling moment. The Modelica source is authoritative
for the reaction equation. Contact geometry and normal load remain
native. FLIP uses an expanded side-force curve based on Table 2.

The native mobility tests evaluated the authored Modelica source at
the same prescribed kinematics used for the original investigation.

| WES yaw | Measured side force (N) | Previous prediction (N) | Modelica prediction (N) |
| --- | ---: | ---: | ---: |
| 40° | 144.8 | 61.5 | 135.76 |
| 65° | 152.2 | 34.4 | 134.39 |
| 85° | 235.5 | 111.9 | 235.25 |
| 90° | 204.9 | 113.1 | 204.80 |

These large-angle side-force observations informed the new curve.
They measure reproduction of calibration conditions. The six small-angle
holdout predictions still pass the load-transfer test. Under the
identical-kinematics throttle-mode case above, both paths now predict
+23.31 N longitudinal and −108.54 N lateral force. The Modelica law
also supplies a pressure-work rolling moment, tested in the implicit
axle balance and equivalent-contact moment sum.

Independent longitudinal and transient soil data remain necessary. For
example, at WES test 30 the new law predicts −92.72 N longitudinal force
against −39.2 N corrected pull, and test 46 predicts −60.67 N against
−18.5 N. The side-force improvements do not qualify the entire contact
law. The effective pressure-depth relation, shear length and contact
renewal regularization are engineering assumptions. Native terrain
remains rigid and the model has no permanent rut or dynamic sinkage
history. These are the next physical validation boundaries under
FMR-005.

The manual controller now contains bounded yaw integral feedback,
differential-priority allocation, and a zero-throttle pivot longitudinal
speed regulator. The final runtime steering results and their study
limits are recorded in the [motion contract](flip-motion-runtime.md).
