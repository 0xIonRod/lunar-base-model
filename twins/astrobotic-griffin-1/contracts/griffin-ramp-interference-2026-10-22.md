# Griffin folded-ramp interference

The saved inward-stowed mechanism is not clear of the fixed deck transitions.
This is an authored geometry defect. The current 4.50 m bus reconstruction and
compact FLIP dimensions do not make the equal-length fold stack viable.
Increasing the inward root angle alone cannot establish a valid mechanism.

The current source is model commit `4dc4d17`. Both ramp roots are stowed at
120 degrees in their mirrored mount frames. Each of the three sections is
1.799084054 m long. The middle fold is at section-local Y=0.20 m, while the
toe fold is at Y=-0.015 m. Each fixed transition is 1.35 m long, spans
X=1.00..2.35 m on the port side, and has its top at lander-local Y=2.12 m.
These dimensions and angles are reconstruction assumptions, not supplier data.

## Confirmed source interference

The normal USD production binary with the canonical collision-query frame
repair was used to open the exact vehicle source in the headful Editor.
Document, projected and stage generation were zero; the document stayed clean.
Cooked collider vertices, geometry bounds, topology transforms and joint frames
were captured from that document. The shared native f64 oriented-box SAT
kernel compared the straight middle tracks with both transition plates.

All four middle tracks intersect their corresponding transition. Their signed
SAT axis margin is approximately **-0.22070535 m**. The eight cooked vertices
fit each reconstructed rectangular box with maximum residual below 3e-8 m;
the transition boxes fit exactly. The opposite-side plates are separated by
approximately 2.485744 m. This is an exact box-intersection finding at the
saved source pose within that numerical residual. The signed SAT margin is
not a runtime contact penetration or a Euclidean distance measurement.

The root tracks meet their matching transitions at the constrained hinge seam;
that explicitly filtered adjacent pair is outside this finding. The mitered
toe tracks are not rectangular boxes and are excluded from the exact-box
conclusion. No contact exclusion, solver setting or authored geometry changed
during this inspection.

[The receipt](evidence/griffin-ramp-interference-2026-10-22.json) contains
source hashes, the six relevant collider snapshots, native transforms,
generation provenance and all eight middle-track/transition comparisons.
Optimization's separate loaded mission recorded actual middle-track contacts
against these transitions. Its runtime penetration is a different measurement
from this static SAT result.

## Candidate mechanism for detailed design

A bounded native-transform study retains the 120-degree root stow and the
5.397252162 m total span, using section lengths **2.149084054, 1.449084054 and
1.799084054 m**. Its toe axis is **0.12 m below the track datum**. The middle
unfolds physically from +180 to 0 degrees; the toe unfolds from -180 to 0
degrees, away from the root. Their coincident half-turn stow poses therefore
need different joint-frame/command mappings. Reusing the current common
-90-degree frame offset and common targets would choose the wrong toe sweep.

The port-side study uses conservative section boxes with 30 mm longitudinal
fitting overhang, lateral half-width 1.432 m, upper bound 0.23 m, root lower
bound -0.06 m and middle/toe lower bounds -0.15 m. There are 181 samples per
phase: middle unfolding while the toe is held, toe unfolding while the middle
is level, then root lowering with both sections level. Minimum sampled SAT
axis margins are 0.228048 m for middle/transition, 0.124232 m for
toe/transition and 0.028282 m for root/toe.

This establishes a candidate worth detailing. It does **not** qualify an
authored repair, continuous clearance between samples, adjacent hinge stock,
rover clearance, starboard assembly, terrain contact, structural loads,
runtime deployment or frame rate. The study's boxes and dimensions are
engineering choices, not measurements of flight hardware. They have not been
written into USD or the normative SysML parameter set.

Implementation must give each length its owned component geometry, connected
hinge fittings, matching anchors and geometry-derived inertia. The lower toe
axis needs a real bracket load path. Then verify the complete folded bundle,
all deployment phases, PV/leg/rover clearances and native landing/egress gates.
Keep mass, torque authority and contact policy under their existing owners;
do not use them to conceal geometric interference.

## Reference boundary

[Astrobotic's Griffin description](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
identifies a dedicated payload adapter and optional rover ramps. Its
[June 2026 hardware release](https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/)
provides the selected exterior configuration; FLIP was to be integrated later.
Neither supplies the folding-mechanism ICD or numerical section lengths.
The operator's mockup photograph guides the inward silhouette only. The
candidate dimensions must remain explicit reconstruction assumptions.
