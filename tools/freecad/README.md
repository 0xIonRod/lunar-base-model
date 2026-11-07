# Griffin-1 FreeCAD model

`build_griffin_1.py` is a FreeCAD Python macro that builds an editable
`griffin_1_lander.FCStd` at the repository root.

## Run it

1. Install FreeCAD 0.21 or newer.
2. Open FreeCAD and open **View → Panels → Python console**.
3. In the Python console, run the macro from **Macro → Macros… → Execute**,
   or paste the contents of `build_griffin_1.py` into the console with an
   `exec(compile(...))` wrapper.
4. The model is saved as `griffin_1_lander.FCStd` in the project root.

The document is organized into seven named groups: structure, propulsion,
landing gear, isogrid payload deck, solar arrays, egress ramps, and
documentation.  All dimensions are millimetres and the presentation model is
Z-up.

The geometry follows the project’s explicit Griffin-1 prototype assumptions:
four landing legs, isogrid deck, side-mounted solar arrays, top payload
adapter, and two physical egress ramps.  It must not be treated as an
as-built or flight-validated Griffin-1 vehicle model.

## Export to the Twin

The proper boundary is:

    FCStd NURBS/BRep -> FreeCAD tessellation -> OBJ staging -> GLB visual payload -> USD payload

Run the project-level exporter from the repository root:

    & 'C:\Program Files\FreeCAD 1.1\bin\FreeCADCmd.exe' -c "exec(compile(open(r'tools/freecad/export_twin_assets_v2.py', encoding='utf-8').read(), r'tools/freecad/export_twin_assets_v2.py', 'exec'), {'__file__': r'tools/freecad/export_twin_assets_v2.py', '__name__': '__main__'})"

FreeCAD source geometry stays editable and NURBS-based. The generated GLB is
visual-only; keep collision, mass, joints, actuators, and Modelica equations in
USD/Modelica. Griffin Z-up is rotated into the Twin Y-up convention; FLIP is
already Y-up. The exporter always selects the newest project-owned FCStd file
and records that choice in the Twin source manifest.
