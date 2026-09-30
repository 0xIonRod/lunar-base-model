# Griffin high-gain antenna

Reference review resolved a missing visual feature: PUG August 2021 v5.02 p30
labels an actual Griffin high-gain dish at the bus edge. Reused the existing
lunco://components/comms/antenna.usda component, with source-owned study mast,
head scale and parked tilt in GriffinVisualConfiguration. Mount derives from
the existing top deck datum/stock midline. Removed both hidden legacy HighGainDish
opinions. No custom reflector mesh, new Rust, independent animation, additional
active rigid body or operational pointing claim. Library indicator/beam graphics
are hidden for this hardware review. Medium-/low-gain reconstruction remains.

The dry Rhai plan was applied through Editor API49746 in separate removal,
reference and 11 attribute operations, then saved. Adding a reference did not
refresh the live recipe automatically: a close/reopen of our own vehicle
resolved the shared antenna and link-beam layers. Document115588691032015,
projection generation0 ready,19 layers; rear screenshot:
/tmp/griffin-hga-rear-review.png. Readback: mount(0,1.79,-1.71), mast radius.025,
height.18, YawHead height.18, gimbal rotation(-70,0,0), head scale(.6,.6,.6),
reflector library rimRadius.58. Both gimbal bodies rigidBodyEnabled=false.
Re-planning the existing composed component succeeds with11 attribute operations.

GV002 now includes the antenna and corrects stale seven-engine wording to five.
The existing visual observer checks the shared mast/reflector/feed arm and two
source-sized mast dimensions. GVC001 and the typed evidence catalogue link the
PUG; griffin-size-evidence records estimates and rationale.

Production visual fixture PASS from terrain cwd:
/tmp/griffin-hga-terrain-visual-gate.log,113checks,8ticks,60Hz,one thread,
seed6840157149251759617. An initial invocation from model cwd was stopped at its
owned PID571336; its imagery asset errors are not accepted evidence. Catalogue
and diff checks pass. This proves visual composition, not dynamic landing,
Earth pointing, or FLIP egress. The full goal remains active.
