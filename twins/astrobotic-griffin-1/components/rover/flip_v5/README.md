# FLIP v5 CAD assets in the Griffin Twin

The active CAD vehicle is `../../../vehicles/flip_v5.usda`, used by the visual,
surface-operations and focused CAD driving scenes. This directory is a
component bundle, not a separately registered Twin.

Source: `0xIonRod/lunar-base-model`, branch `codex/flip-visual-requirements`,
commit `c51853f147015346f59bb87cab1d3b86a7eaa63e`, `freecad/flip_rover_v5`.
The five visual layers and panel Modelica source were copied without changing
their geometry or equations. All five visual-layer hashes match the source.
`DELIVERY_REPORT.md` is the original supplier handoff, not a fresh acceptance result.

The vehicle was extracted from the source `/World/FLIP` with LunCoSim's typed
`MovePrim` operation, which also remapped joint and connection targets. Its
standalone scene environment, ground, camera and inactive acceptance controller
are excluded. CAD references and the panel-controller URI resolve inside this
Griffin Twin; the payload root translation is zero. No dependency on `runs/`
or an external registered `flip_rover_v5` Twin remains.

The source's physical wheel drivetrain, suspension sliders, motor/gearbox/shaft
network and panel hinge/controller are retained. The vehicle now selects finite
battery power and composes the older FLIP's thermal subassembly with explicit
motor, gearbox, bearing, brake, tire and contact boundaries. A photovoltaic
component is mounted on the moving panel body, with its own environment probe
and a connection to the battery bus. Generic panel proxy geometry is disabled.
Electrical components do not add another mechanical mass over the CAD budget.
Battery and solar ratings remain study assumptions, not supplier calibration.
The CAD differential-steering route, forward/reverse/braking, panel stow/deploy
and finite EPS gates have passed; see `../../../contracts/flip-cad-runtime-2026-10-26.md`.

Mount: rover root is 0.70 m above Griffin's 2.119999885559082 m deck datum,
with the updated mission's 172.483-degree lander/rover heading. The existing payload fixed joint remains
the release interface; its rover anchor is `(0, -0.7, 0)`.

Run the read-only authored assembly gate through `RunRhai`: evaluate
`scenarios/tests/griffin_flip_v5_mount.rhai` and call
`verify(doc_id, "/Griffin1SurfaceOps")` on the exact open mission document.
Its eight checks cover seating, adapter endpoints/vertical alignment, panel
hinge and four wheel/drive stations. It does not prove dynamics, landing,
release, power performance, egress or waypoint arrivals.
