> Current FLIP CAD: [flip_v3](flip_v3/README.md), with corrected side hinge. The instructions below describe the historical v1 generator and do not reproduce v3.

# FLIP rover FreeCAD model

`FLIP_Rover.py` builds and saves `FLIP_Rover.FCStd` in this folder.

## Run it

1. Open FreeCAD and enable **View -> Panels -> Python console**.
2. Run:

```python
p = r"C:/Users/salek/OneDrive/Desktop/NASA-lunar-base-model/freecad/FLIP_Rover.py"
scope = globals()
scope["__file__"] = p
exec(compile(open(p).read(), p, "exec"), scope)
```

The saved document opens in the **CLOSED / STOWED** configuration: the large
framed solar panel lies over the payload deck. It is a separate
`SolarArrayPanelBody` driven by the explicit `SolarArrayJoint` revolute hinge
about the X/lateral axis.

To move it after running the macro:

```python
deploy_solar_panel()  # upright reference pose, 82 deg
stow_solar_panel()    # closed deck pose, 0 deg
```

You can also select `SolarArrayJoint` in the tree and edit its `Angle` in the
Data panel between `0 deg` and `90 deg`. The joint records the parent body,
child body, hinge position, axis, limits, stowed/deployed angles, and motion
acceptance contract.

This is a reference-inspired packaging and articulation study proxy, not
flight-qualified or as-built vehicle CAD. The supplied image is visual-only;
its proportions are not treated as dimensional evidence.
