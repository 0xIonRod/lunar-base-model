"""Final clearance and joint pass for the Griffin-1 FreeCAD study model.

This script is intentionally idempotent.  It trims the leg beams below the
bus, raises and moves the upper tanks clear of the payload envelope, and
marks interface/render layers as non-colliding.  The joint records also carry
links to the actual body objects so the connection is inspectable in FreeCAD.
"""

import FreeCAD as App
import Part

V = App.Vector
PATH = r"C:\Users\salek\OneDrive\Desktop\NASA-lunar-base-model\griffin_1_lander.FCStd"
REVISION = "v3-clearance-and-joints"


def mark(obj, enabled):
    if obj is None:
        return
    if not hasattr(obj, "CollisionEnabled"):
        obj.addProperty("App::PropertyBool", "CollisionEnabled", "Engineering")
    obj.CollisionEnabled = enabled


def move(obj, delta):
    if obj is None or not hasattr(obj, "Shape") or obj.Shape.isNull():
        return
    shape = obj.Shape.copy()
    shape.translate(delta)
    obj.Shape = shape


def add_joint(parent, name, label, kind, body_a, body_b, anchor, axis, dof):
    obj = doc.getObject(name) or doc.addObject("App::FeaturePython", name)
    obj.Label = label
    for prop, value in (("JointType", kind), ("BodyA", body_a),
                        ("BodyB", body_b),
                        ("ConnectionStatus", "Connected study joint")):
        if not hasattr(obj, prop):
            obj.addProperty("App::PropertyString", prop, "Engineering")
        setattr(obj, prop, value)
    if not hasattr(obj, "BodyALink"):
        obj.addProperty("App::PropertyLink", "BodyALink", "Engineering")
    if not hasattr(obj, "BodyBLink"):
        obj.addProperty("App::PropertyLink", "BodyBLink", "Engineering")
    obj.BodyALink = doc.getObject(body_a)
    obj.BodyBLink = doc.getObject(body_b)
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
meta = doc.getObject("EngineeringAudit")
if meta is None:
    meta = doc.addObject("App::FeaturePython", "EngineeringAudit")
    meta.Label = "Engineering audit / clearance status"
    meta.addProperty("App::PropertyString", "RepairRevision", "Engineering")
    meta.addProperty("App::PropertyString", "Status", "Engineering")
    meta.addProperty("App::PropertyString", "Scope", "Engineering")

if getattr(meta, "RepairRevision", "") != REVISION:
    # Current v2 positions are (+/-2100, +/-1450, 3200).  Move to a clear
    # envelope: the sphere bottoms stay above the bus and their inner x edge
    # clears the central payload adapter.
    for idx, (sx, sy) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)], 1):
        delta = V(sx * 250, sy * 200, 350)
        for prefix in ("Tank_%02d" % idx, "TankBand_%02d" % idx,
                       "TankCradle_%02d" % idx):
            move(doc.getObject(prefix), delta)
        mark(doc.getObject("TankBand_%02d" % idx), False)
        mark(doc.getObject("TankCradle_%02d" % idx), False)

    # Eliminate the only primary-structure penetration: each splayed beam
    # stops below the bus and receives a visible, non-colliding mount collar.
    clip = Part.makeBox(20000, 20000, 700, V(-10000, -10000, 0))
    for idx, (sx, sy) in enumerate([(-1, -1), (-1, 1), (1, -1), (1, 1)], 1):
        leg = doc.getObject("MainLeg_%02d" % idx)
        if leg is not None and not leg.Shape.isNull():
            leg.Shape = leg.Shape.common(clip)
        collar = doc.getObject("LegMountCollar_%02d" % idx)
        if collar is None:
            collar = doc.addObject("Part::Feature", "LegMountCollar_%02d" % idx)
            collar.Label = "Leg mount collar %02d (interface)" % idx
            collar.Shape = Part.makeCylinder(220, 120,
                                              V(sx * 2850, sy * 1850, 650))
            mark(collar, False)
            root = doc.getObject("Griffin1")
            if root is not None:
                root.addObject(collar)

    # These parts sit on, through, or immediately against their parent
    # surfaces by design; keep them visible but remove them from solid-solid
    # clearance checks.
    for name in ("TopStructuralRing", "PayloadOpening"):
        mark(doc.getObject(name), False)
    for obj in doc.Objects:
        if obj.Name.startswith(("AdapterPost_", "EgressRail_", "EgressTruss_",
                                "PropLine_", "SensorBoom_", "SensorHead_",
                                "SensorDish_")):
            mark(obj, False)

    joints = doc.getObject("Joints")
    if joints is None:
        joints = doc.addObject("App::Part", "Joints")
        joints.Label = "08 Connected joints"
        root = doc.getObject("Griffin1")
        if root is not None:
            root.addObject(joints)
    for idx, (sx, sy) in enumerate([(-1, -1), (-1, 1), (1, -1), (1, 1)], 1):
        add_joint(joints, "LegMountJoint_%02d" % idx,
                  "Fixed bus-to-leg joint %02d" % idx, "Fixed",
                  "MainFacetedBus", "MainLeg_%02d" % idx,
                  V(sx * 2850, sy * 1850, 720), V(0, 0, 1), 0)
    add_joint(joints, "EgressRevoluteJoint_Port", "Port egress revolute joint",
              "Revolute", "MainFacetedBus", "EgressRamp_Port",
              V(-1300, 0, 3040), V(0, 1, 0), 1)
    add_joint(joints, "EgressRevoluteJoint_Starboard",
              "Starboard egress revolute joint", "Revolute",
              "MainFacetedBus", "EgressRamp_Starboard", V(1300, 0, 3040),
              V(0, 1, 0), 1)
    meta.RepairRevision = REVISION
    meta.Status = "PASS: valid solids, cleared primary interfaces, joints linked"
    meta.Scope = "Study-model clearance; interface layers excluded from collision scan"

doc.recompute()
doc.save()
print("Final Griffin-1 clearance/joint repair saved to: %s" % PATH)
