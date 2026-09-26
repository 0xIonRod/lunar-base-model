# FLIP v3 CAD package
Open **FLIP_rover_v3_corrected.FCStd**, saved closed. Edit MOTION.SolarAngle:
0 degrees closed, 82 degrees example deployment, 90 degrees maximum effective angle.
A native min/max expression clamps geometry even if scripted SolarAngle input
retains a value outside this range.
LeftWheelRoll and RightWheelRoll rotate the two wheels on each side;
these are kinematic controls, not a vehicle dynamics solution.

The solar panel hinges along the side around the global Y axis. The body,
wheels and equipment are preserved. See ../../requirements/flip-rover.md
for dimensions, mass provenance, behavior and verification traceability.

## Rebuild and verify
Use FreeCAD 1.1.1. Paths are relative to these scripts.
1. Run build_side_hinge.py with FreeCADCmd. It reads the included v2 baseline
   and writes FLIP_rover_v3_side_hinge.FCStd (headless intermediate).
2. Run present.FCMacro in FreeCAD. It saves to a temporary directory, copies
   FLIP_rover_v3_corrected.FCStd here, reopens, and renders a 0/82/0 cycle.
   This overwrites generated v3 outputs; use a disposable copy for rebuilds.
3. Run audit.py with FreeCADCmd to audit the final corrected file.

If executing through a console, set __file__ to the selected script's absolute
path before exec(compile(...)). Do not run the historical freecad/FLIP_Rover.py
to reproduce v3.

## Evidence boundary
224 physical components; 225 individual attachment checks; 11 panel poses
and 6 wheel poses. Study tolerances: 0.01 mm attachment gap and 1 mm^3
penetration. A sampled PASS does not prove continuous clearance or structural
strength. The source v3_geometry_comparison.json records the pre-clamp GUI save.
The published clamp changes only out-of-range motion; published_geometry_comparison.json
compares final geometry across all audited panel/wheel poses. All 84 non-Power components are preserved.
The included v2 file is a reproducible baseline, not the current deliverable.

All detailed dimensions and the 82-degree pose are study estimates. No
material-density mass, inertia, motor performance or thermal qualification
is established by this CAD. No USD/Modelica assets are updated by this package.


The preserved audited_source.FCStd matches the hash in v3_audit_latest.json.
Run compare_published.py with FreeCADCmd to repeat the 17-pose equivalence check.
Run requirements_check.py with FreeCADCmd from this repository layout to measure
the delivered CAD against the SysML numeric contract and test effective angle limits.
Initial failed requirements checks are retained for traceability.

Repository structure validation passes. The broader historical Griffin validator
has pre-existing failures against unchanged runtime assets; see repository_validation.json.
Formal SysML parser validation and runtime promotion remain open.
