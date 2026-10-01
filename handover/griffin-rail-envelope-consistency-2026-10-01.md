# Current rail envelope and mass-property consistency

Inspection found that the slender 6 mm rails were positioned correctly, but
the source outside width and dynamics proxies still used 2.86 m from 140 mm
rails. The outside rail edges are +/-1.296 m, giving 2.592 m. This is a
derived study datum, not a supplier measurement. Compact pins extend beyond
that rail-only envelope; the field does not certify total hardware clearance.
Reference silhouette rechecked:
https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png .

GriffinEgressRamp now derives rampSurfaceWidthM from the outer rail station
and thickness. Section and transition rectangular-envelope inertias derive
from current dimensions and the retained unqualified masses. Native source
readback gave section inertia (17.73165500019,26.27058072719,8.54367572700)
kg m2 and transition inertia (8.399205,9.41058,1.013625) kg m2. This is a
consistent dynamics proxy, not a mass distribution or strength certification.

Owned headless Editor API49746 saved the SysML document through
ApplySysmlOps/SaveSysmlDocument. OpenFile/ApplyUsdOps/SaveDocument changed
the vehicle's six section inertias, two operational-width fields, two
transition inertias and two transition contact widths. Document
115615321640030 generation12 read back dirty=false and no diagnostics.
The USD float3 inertia boundary accounts for the saved f32 rounding.
Visible rail meshes, wheel-track clearance and deployment angles did not
change. The size-evidence note now describes current stock and hinge
half-thickness rather than stale earlier reconstruction values.

Focused production gate: private terrain a7707995, scene
tests/griffin_ramp_requirements.usda, max1000ticks, 60Hz, threads1, jitter0.
Terminal PASS exit0, 1277 checks, 11 ticks/17 updates. Log:
/tmp/griffin-rail-width-geometry.log. Typed provenance PASS: 207 targets,
207 records,47 source elements,3 roles. Repository and whitespace checks PASS.
The existing composed rail station/mesh-extent checks and source-backed
width/inertia checks cover this reconciliation; no additional check family
or geometry mechanism was added.

The core command fix is separately committed as terrain 5079c4b58. Its
focused compile check passed; its test build exhausted /home disk space.
The geometry gate above uses the prior core and does not prove the new motor
behavior. Rebuild/replay remains necessary before accepting stable deployed
ramps, toe contact, payload release or FLIP egress.
