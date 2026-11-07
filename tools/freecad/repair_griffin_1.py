"""Repair and connect the reference-upgraded Griffin-1 FreeCAD document.

This is a non-destructive repair pass over griffin_1_lander.FCStd. It moves
the upper tanks and corner pods clear of the bus/payload envelope, offsets the
solar blankets outside the bus, marks render-only layers as non-collision, and
adds explicit fixed/revolute joint records.
"""

import os

import FreeCAD as App

try:
    import FreeCADGui as Gui
except ImportError:
    Gui = None


V = App.Vector
PATH = r"C:\Users\salek\OneDrive\Desktop\NASA-lunar-base-model\griffin_1_lander.FCStd"


def move(obj, delta):
    if obj is None or not hasattr(obj, "Shape") or obj.Shape.isNull():
        return
    shape = obj.Shape.copy()
    shape.translate(delta)
    obj.Shape = shape


def mark(obj, enabled):
    if obj is None:
        return
    if not hasattr(obj, "CollisionEnabled"):
        obj.addProperty("App::PropertyBool", "CollisionEnabled", "Engineering")
    obj.CollisionEnabled = enabled


def joint(parent, name, label, kind, body_a, body_b, anchor, axis, dof):
    obj = doc.getObject(name) or doc.addObject("App::FeaturePython", name)
    obj.Label = label
    for prop, value in (("JointType", kind), ("BodyA", body_a), ("BodyB", body_b),
                        ("ConnectionStatus", "Connected study joint")):
        if not hasattr(obj, prop):
            obj.addProperty("App::PropertyString", prop, "Engineering")
        setattr(obj, prop, value)
    if not hasattr(obj, "Anchor"):
        obj.addProperty("App::PropertyVector", "Anchor", "Engineering")
    if not hasattr(obj, "Axis"):
        obj.addProperty("App::PropertyVector", "Axis", "Engineering")
    if not hasattr(obj, "DegreesOfFreedom"):
        obj.addProperty("App::PropertyInteger", "DegreesOfFreedom", "Engineering")
    obj.Anchor, obj.Axis, obj.DegreesOfFreedom = anchor, axis, dof
    if obj not in parent.Group:
        parent.addObject(obj)


doc = App.openDocument(PATH)
doc.recompute()

# Tank centres move from (+/-1850,+/-1150,2850) to a clear, slightly raised
# (+/-2100,+/-1450,3200) envelope around the central payload opening.
old_tanks = [(-1850, -1150), (1850, -1150), (-1850, 1150), (1850, 1150)]
new_tanks = [(-2100, -1450), (2100, -1450), (-2100, 1450), (2100, 1450)]
for idx, (old, new) in enumerate(zip(old_tanks, new_tanks), 1):
    delta = V(new[0] - old[0], new[1] - old[1], 350)
    for prefix in ("Tank_%02d" % idx, "TankBand_%02d" % idx, "TankCradle_%02d" % idx):
        move(doc.getObject(prefix), delta)
    mark(doc.getObject("TankBand_%02d" % idx), False)
    mark(doc.getObject("TankCradle_%02d" % idx), False)

# Corner pods and their sensor hardware are raised clear of the bus top face.
for obj in doc.Objects:
    if any(obj.Name.startswith(prefix) for prefix in ("CornerPod_", "SensorBoom_", "SensorHead_", "SensorDish_")):
        move(obj, V(0, 0, 280))

# Solar blankets are mounted outside the bus skin. Their cell/backing/frame
# layers are presentation geometry and must not enter the rigid collision set.
for obj in doc.Objects:
    if obj.Name.startswith("Solar"):
        mark(obj, False)
for key, delta in (("Front", V(0, -90, 0)), ("Rear", V(0, 90, 0)),
                   ("Port", V(-90, 0, 0)), ("Starboard", V(90, 0, 0))):
    for obj in doc.Objects:
        if key in obj.Name and obj.Name.startswith("Solar"):
            move(obj, delta)

# Lower thermal skirt, braces, and tank restraints are visual/mount layers.
mark(doc.getObject("LowerStructuralSkirt"), False)
for obj in doc.Objects:
    if obj.Name.startswith(("BraceA_", "BraceB_", "Oleo_", "FootpadRim_")):
        mark(obj, False)

# Add a real document-level connectivity ledger. These records are native
# FreeCAD objects and provide the handoff point for a future Assembly solver.
joints = doc.getObject("Joints")
if joints is None:
    joints = doc.addObject("App::Part", "Joints")
    joints.Label = "08 Connected joints"
    root = doc.getObject("Griffin1")
    if root is not None:
        root.addObject(joints)
for idx, (sx, sy) in enumerate([(-1, -1), (-1, 1), (1, -1), (1, 1)], 1):
    joint(joints, "LegMountJoint_%02d" % idx, "Fixed bus-to-leg joint %02d" % idx,
          "Fixed", "MainFacetedBus", "MainLeg_%02d" % idx,
          V(sx * 2850, sy * 1850, 720), V(0, 0, 1), 0)
joint(joints, "EgressRevoluteJoint_Port", "Port egress revolute joint", "Revolute",
      "MainFacetedBus", "EgressRamp_Port", V(-1300, 0, 3040), V(0, 1, 0), 1)
joint(joints, "EgressRevoluteJoint_Starboard", "Starboard egress revolute joint", "Revolute",
      "MainFacetedBus", "EgressRamp_Starboard", V(1300, 0, 3040), V(0, 1, 0), 1)

# Ensure the final saved document opens visibly in the GUI.
if Gui is not None and hasattr(Gui, "showMainWindow"):
    Gui.showMainWindow()
    for obj in doc.Objects:
        view = getattr(obj, "ViewObject", None)
        if view is not None:
            view.Visibility = True
    try:
        Gui.activeDocument().activeView().viewAxonometric()
        Gui.activeDocument().activeView().fitAll()
    except Exception:
        pass

doc.recompute()
doc.save()
print("Repaired Griffin-1 document saved to: %s" % PATH)
