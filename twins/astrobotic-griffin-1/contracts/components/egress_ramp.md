# Griffin ramp model contract

The integrated ramp mechanism has a confirmed folded-stack interference.
[The current inspection and candidate design](../griffin-ramp-interference-2026-10-22.md)
record its exact scope. Existing source-conformance checks do not qualify
collision-free stow, deployment or rover egress.

A [separate longer-root component](../griffin-ramp-root-section-2026-10-23.md)
is saved and tested at 2.149084054 m. It is an unmounted reconstruction
prototype. The equal-length installed mechanism described below is unchanged.

## Ownership and current datums

`requirements/griffin_ramp_requirements.sysml` owns reconstruction dimensions,
material choices, hinge frames, travel, masses and verification objectives.
`tools/griffin_spec.rhai` reads those typed facts; `griffin_visual_builder.rhai`
materializes geometry through the native document journal. The vehicle owns
references, installation poses, standard bodies, joints, latches and wiring.

Each side has three articulated sections, each 1.799084054 m long, totaling
5.397252162 m. Two collision-enabled tracks follow the FLIP wheel stations;
the center remains open. Walking stock is 0.03 m thick. Four open truss guides
follow each section. Their upper chord center is 0.18 m above the track datum,
with 0.04 m stock; root guides rise from the track entrance toward that datum.
The guides, tread bars and underside beams are structural appearance proxies,
not qualified load-bearing hardware.

Both roots lean thirty degrees inward from vertical. The port body has
Z=+120 degrees; starboard has Y=180, Z=-120 degrees. Root travel is -50..+125
and -125..+50 degrees respectively. Both intermediate physical folds are
180 degrees. Their current child frames are offset -90 degrees, so their
native stow, halfway and level targets are +90, 0 and -90 degrees. The middle
axis is Y=+0.20 m and the toe axis Y=-0.015 m in their respective body frames.
The saved source pose intersects the transition plates; the common unfolding
sense also needs mechanism review.

Each fixed transition is a separate 15 kg rigid body, constrained to the bus.
Its 1.35 m contact plate has a top at local Y=2.12 m and outboard edge at
|X|=2.35 m. GRR-012 measures exact convex footprints across the full lateral
span of the clipped payload adapter; an aggregate AABB cannot establish that
interface. The nominal landed bus reference is Y=0.44 m. Nominal deployment
angles come from the shared total span and landing/walking datums; runtime
terrain fitting uses the measured hinge frames and retained DEM. These are
study assumptions until supplier geometry is available.

Each section has source-owned mass and diagonal inertia. Visual stock does
not create extra physical bodies or mass. The deck uses separate convex
perimeter beams and a payload adapter, preserving the tank openings. Only the
matching root/transition seam is explicitly contact-filtered; middle and toe
contacts with fixed plates remain active.

## Commands and verification

The mission owns sequencing and measured settlement; Modelica owns continuous
motion profiles. Six fixed flight latches carry the stowed sections while
parallel hinge motors supply no effort. Release restores each selected pair's
admitted native motor law. Middle latches release first, then toe latches,
then roots after section settlement. Missing or changed laws fail visibly.
The observed interference means this authored sequence is not accepted.

Manual **U / OPEN RAMPS** and **F / DETACH ROVER** remain separate operator
commands. Automatic egress requires landed state, terrain-fitted targets and
the source-owned hinge settlement dwell. Opening during flight is a mechanism
pose, not terrain contact or traversable egress.

The production Rhai observers are `griffin_ramp_requirements.rhai`,
`griffin_ramp_flight_stow.rhai` and `griffin_ramp_touchdown_geometry.rhai` under
`scenarios/tests/`. They read typed USD facts and bind SysML constraints.
Their source-conformance, panel and leg checks have bounded coverage. Full
folded-bundle clearance, deployment-path clearance, runtime landing and loaded
rover traversal require their own passing evidence after a mechanism repair.

The standalone `components/lander/griffin_ramp_visual.usda` remains a compact
presentation asset. Integrated geometry comes from the reusable section and
toe components referenced by `vehicles/griffin_1.usda`. A miniature preview
cannot establish the physical mechanism envelope.

[Astrobotic](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
confirms the adapter/ramp concept. Public imagery guides the inward silhouette
and open trusses, but supplies no flight hinge positions, section dimensions,
mass properties or released deployment ICD. All numerical reconstruction
choices must retain that provenance boundary.
