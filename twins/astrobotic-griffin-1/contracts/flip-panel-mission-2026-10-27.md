# CAD FLIP panel buttons and mounted mission test — 2026-10-27

The View HUD now offers **OPEN SOLAR PANEL** and **STOW SOLAR PANEL** for
each dynamic CAD FLIP. The controls are also present while the payload is
attached to Griffin. The mounted mission starts stowed; standalone CAD drive
retains its deployed initial configuration.

USD owns the 82° open and 0° stow targets. The HUD callback emits a Twin-scoped
request identifying its rover. That rover's scene-owned Rhai actor commands
`SolarMechanism/Controller.command_deg` through `SetPorts`; the existing
Modelica controller and native revolute joint perform the motion. No pose
overrides, additional continuous script controller, or physics tolerances
were introduced. The actor subscribes only to the panel request event and
retires its HUD on stop.

## Validation

Simulator `8bad5b08b08357412218087ae20be03e80c4db55`, with the pre-existing
local simulator integration fixes preserved; model base `e45cd8d`, plus the
uncommitted panel changes. The simulator was updated because the earlier
binary could not load the current mission's shared contact-speed model.

- Native HUD pointer clicks on **Stow**, then **Open**, changed the live
  controller command to 0° and 82°, respectively. Stow measured approximately
  0.0018° at the native hinge. Open reached approximately 82° transiently and
  settled at 79.60°. Button dispatch and physical actuation work; the existing
  2° steady tracking criterion is **not met** on this simulator version.
- In a fresh mounted mission window, **Open** changed the controller from
  0° to 82° and physically raised the panel while the payload adapter still
  existed. The final sampled hinge angle was approximately 78.81°. Later
  interactive detachment/control input makes that session unsuitable as an
  unattended mission acceptance result.
- The unattended full mission was run with CAD FLIP attached and the panel
  stowed. Preparation completed, and the complete 5,389.99976 kg dynamic
  assembly matched the guidance mass input (**GR-039 PASS**).
- The mission then **FAILED GR-004-phase-landing at tick 18,001 / 300.02 s**.
  Griffin tipped; its final upright-axis Y component was −0.12382 and only
  LegPX had contact. Touchdown, engine-cutoff contact and flight handoff were
  all false. Ramp deployment, adapter release and the rover route were not
  reached by this acceptance run. No landing gate was bypassed.

The landing instability and panel steady tracking error remain open; this
receipt does not claim complete mission acceptance. Earlier CAD component
passes remain historical results from their recorded simulator revisions.

Compact measured evidence: [JSON](evidence/flip-panel-mission-2026-10-27.json).
Full logs, native input traces, typed USD authoring journal and controller/
hinge samples are retained under `runs/flip-mission-panel-2026-10-27/` in the
model checkout. The `current-engine` directory contains the unattended
mission verdict; `panel-final` contains the standalone button traces;
`mounted-window` contains the attached-payload Open trace.

## Mounted alignment and shortcuts follow-up

After manual testing, the mounted payload was turned 90° toward the port
egress rails: lander yaw remains 172.483°, FLIP yaw is 82.483°. The payload
adapter's body-0 joint frame has the corresponding −90° yaw; changing both
the authored pose and attachment frame prevents the fixed joint from
restoring the old orientation. Standalone CAD FLIP is unchanged.

O opens the panel. S stows it while FLIP is unpossessed, including mounted
operations; S remains reverse while driving FLIP, when the Stow button is
still available. Both keys enter the existing scene-owned panel command path.

All ten composed mount checks passed, including deck seating, rail direction,
attachment-frame alignment and the four wheel drives. In a fresh visible
mission window, native O/S press/release input changed `command_deg` from
0 to 82 to 0, with matching deployment motion. The native rover-forward/
lander-rail direction dot product was 0.9999999999999903 while the adapter
remained present. Evidence is retained in
`runs/flip-mount-shortcuts-2026-10-27/`. The full unattended mission has not
been rerun after this orientation correction; the landing failure above
describes the earlier mounting orientation.
