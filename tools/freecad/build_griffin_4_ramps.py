"""Build the next lander-only Griffin ramp iteration.

This iteration models the packed ramp hardware visible in the reference
photograph: each fore/aft rampway has three independent rail sections on
each side, a segmented centre/main rail tying the two sides together,
visible hinge pins at every fold, and simple actuator links.
"""

import math

import FreeCAD as App
import FreeCADGui as Gui
import Part


V = App.Vector
SOURCE = r"C:\Users\salek\OneDrive\Desktop\NASA-lunar-base-model\griffin_3_lander.FCStd"
OUTPUT = r"C:\Users\salek\OneDrive\Desktop\NASA-lunar-base-model\griffin_4_lander.FCStd"

DECK_X = 4500.0
DECK_Y = 4500.0
DECK_Z = 2150.0
RAMP_LENGTH = 5050.0
SEGMENT_LENGTHS = (1680.0, 1680.0, 1690.0)
RAMP_WIDTH = 1700.0
RAIL_C2C = 1500.0
RAIL_H = 300.0
RAIL_R = 34.0
JOINT_R = 92.0
PANEL_THICK = 70.0
NOMINAL_ANGLE = 24.0
MAX_TOTAL_ANGLE = 30.0

COLORS = {
    "structure": (0.25, 0.29, 0.33),
    "white": (0.86, 0.86, 0.82),
    "orange": (0.93, 0.43, 0.06),
    "tank": (0.73, 0.49, 0.18),
}


def unit(vector):
    length = vector.Length
    return vector if length == 0 else vector.multiply(1.0 / length)


def shifted(point, x):
    return V(x, point.y, point.z)


def set_color(obj, color):
    view = getattr(obj, "ViewObject", None)
    if view is None:
        return
    view.ShapeColor = COLORS[color]
    view.LineColor = (0.10, 0.11, 0.12)
    view.DisplayMode = "Flat Lines"


def add_string(obj, name, group, value):
    obj.addProperty("App::PropertyString", name, group)
    setattr(obj, name, value)


def add_feature(parent, name, label, shape, color, description):
    obj = doc.addObject("Part::Feature", name)
    obj.Label = label
    obj.Shape = shape
    parent.addObject(obj)
    set_color(obj, color)
    add_string(obj, "ComponentType", "Griffin 4", "Study geometry")
    add_string(obj, "Description", "Griffin 4", description)
    return obj


def beam(p1, p2, radius):
    delta = p2.sub(p1)
    if delta.Length < 0.1:
        return Part.makeSphere(radius, p1)
    return Part.makeCylinder(radius, delta.Length, p1, delta)


def deployed_direction(side, angle):
    radians = math.radians(angle)
    return unit(V(0.0, side * math.cos(radians), -math.sin(radians)))


def stowed_directions(side):
    # The first panel folds inboard and upward; the next two fold back over it
    # so the three truss panels nest on the top deck like the reference photo.
    return (
        unit(V(0.0, -side * 0.55, 0.84)),
        unit(V(0.0, side * 0.97, 0.24)),
        unit(V(0.0, -side * 0.97, 0.24)),
    )


def segment_frames(side, angle, stowed):
    hinge = V(0.0, side * DECK_Y / 2.0, DECK_Z)
    directions = stowed_directions(side) if stowed else (deployed_direction(side, angle),) * 3
    frames = []
    start = hinge
    for length, direction in zip(SEGMENT_LENGTHS, directions):
        end = start.add(direction.multiply(length))
        normal = unit(V(0.0, -direction.z, direction.y))
        frames.append((start, end, direction, normal))
        start = end
    return frames


def truss_segment(p0, p1, normal):
    top0 = p0.add(normal.multiply(RAIL_H))
    top1 = p1.add(normal.multiply(RAIL_H))
    parts = [beam(p0, p1, RAIL_R), beam(top0, top1, RAIL_R)]
    for fraction in (0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0):
        low = p0.add(p1.sub(p0).multiply(fraction))
        parts.append(beam(low, low.add(normal.multiply(RAIL_H)), RAIL_R * 0.78))
    for index in range(3):
        a = p0.add(p1.sub(p0).multiply(index / 3.0))
        b = p0.add(p1.sub(p0).multiply((index + 1) / 3.0))
        if index % 2:
            parts.append(beam(a.add(normal.multiply(RAIL_H)), b, RAIL_R * 0.68))
        else:
            parts.append(beam(a, b.add(normal.multiply(RAIL_H)), RAIL_R * 0.68))
    return Part.makeCompound(parts)


def panel_shape(p0, p1):
    direction = p1.sub(p0)
    length = direction.Length
    angle = math.degrees(math.atan2(direction.z, direction.y))
    shape = Part.makeBox(RAMP_WIDTH, length, PANEL_THICK,
                         V(-RAMP_WIDTH / 2.0, p0.y, p0.z - PANEL_THICK / 2.0))
    shape.rotate(V(0.0, p0.y, p0.z), V(1.0, 0.0, 0.0), angle)
    return shape


def cross_tie(point, normal):
    centre = point.add(normal.multiply(RAIL_H * 0.5))
    return beam(V(-RAIL_C2C / 2.0, centre.y, centre.z),
                V(RAIL_C2C / 2.0, centre.y, centre.z), 28.0)


def folding_joint(point, x):
    # Pin axis is transverse to the rampway and includes two visible collars.
    pin = Part.makeCylinder(JOINT_R, 170.0,
                            V(x - 85.0, point.y, point.z), V(1.0, 0.0, 0.0))
    collar_a = Part.makeCylinder(JOINT_R + 28.0, 28.0,
                                 V(x - 112.0, point.y, point.z), V(1.0, 0.0, 0.0))
    collar_b = Part.makeCylinder(JOINT_R + 28.0, 28.0,
                                 V(x + 84.0, point.y, point.z), V(1.0, 0.0, 0.0))
    cheek = Part.makeBox(190.0, 150.0, 120.0,
                         V(x - 95.0, point.y - 75.0, point.z - 60.0))
    return Part.makeCompound((pin, collar_a, collar_b, cheek))


def deck_hinge(point, x):
    pin = Part.makeCylinder(JOINT_R + 10.0, 220.0,
                            V(x - 110.0, point.y, point.z), V(1.0, 0.0, 0.0))
    bracket = Part.makeBox(230.0, 220.0, 180.0,
                           V(x - 115.0, point.y - 110.0, point.z - 90.0))
    return Part.makeCompound((pin, bracket))


def actuator_shape(side, point, direction):
    base = V(point.x, point.y - side * 330.0, DECK_Z - 420.0)
    attachment = point.add(direction.multiply(SEGMENT_LENGTHS[0] * 0.56))
    return Part.makeCompound((beam(base, attachment, 38.0),
                              Part.makeSphere(58.0, base),
                              Part.makeSphere(58.0, attachment)))


class RampController:
    def __init__(self, obj, parts):
        self.parts = parts
        obj.Proxy = self

    def execute(self, obj):
        stowed = obj.State == "Stowed"
        angle = min(max(float(obj.OpenAngle), 0.0), float(obj.MaxRampAngle))
        obj.EffectiveAngle = 0.0 if stowed else angle + abs(float(obj.DeckPitch)) + abs(float(obj.TerrainSlope))
        obj.Compliance = "STOWED" if stowed else ("PASS" if obj.EffectiveAngle <= float(obj.MaxTotalAngle) else "CHECK")
        frame_map = {}
        for side_name, side in (("Aft", 1), ("Fore", -1)):
            frame_map[side_name] = segment_frames(side, angle, stowed)
        for part in self.parts:
            frames = frame_map[part["set_name"]]
            kind = part["kind"]
            if kind in ("panel", "rail"):
                p0, p1, _direction, normal = frames[part["index"]]
                if kind == "panel":
                    part["obj"].Shape = panel_shape(p0, p1)
                else:
                    part["obj"].Shape = truss_segment(shifted(p0, part["x"]),
                                                       shifted(p1, part["x"]), normal)
            elif kind == "tie":
                index = part["index"]
                if index == 0:
                    point, _end, _direction, normal = frames[0]
                elif index == 3:
                    _start, point, _direction, normal = frames[-1]
                else:
                    point, _end, _direction, normal = frames[index]
                part["obj"].Shape = cross_tie(point, normal)
            elif kind == "joint":
                point = frames[part["index"] - 1][1]
                part["obj"].Shape = folding_joint(point, part["x"])
            elif kind == "hinge":
                point = frames[0][0]
                part["obj"].Shape = deck_hinge(point, part["x"])
            elif kind == "actuator":
                point, _end, direction, _normal = frames[0]
                part["obj"].Shape = actuator_shape(part["side"], shifted(point, part["x"]), direction)

    def onChanged(self, obj, prop):
        if prop in ("State", "OpenAngle", "MaxRampAngle", "MaxTotalAngle", "DeckPitch", "TerrainSlope"):
            obj.touch()

    def __getstate__(self):
        return {"version": 4}

    def __setstate__(self, state):
        return None


doc = App.openDocument(SOURCE)
egress = doc.getObject("Egress")
if egress is None:
    egress = doc.addObject("App::DocumentObjectGroup", "Egress")
    egress.Label = "06 Folding ramp hardware"
documentation = doc.getObject("Documentation")
if documentation is None:
    documentation = doc.addObject("App::DocumentObjectGroup", "Documentation")

# Remove the previous ramp solids/controller but preserve the rest of the lander.
for obj in list(doc.Objects):
    if (obj.Name in ("RampDeployment", "RampCorrectionNote") or
            obj.Name.startswith("AftRamp") or obj.Name.startswith("ForeRamp")):
        doc.removeObject(obj.Name)

ramp_parts = []
for set_name, side in (("Aft", 1), ("Fore", -1)):
    initial_frames = segment_frames(side, NOMINAL_ANGLE, True)
    for index, (_p0, _p1, _direction, _normal) in enumerate(initial_frames):
        panel = add_feature(
            egress, "%sRampPanel_%02d" % (set_name, index + 1),
            "%s ramp deck panel %d of 3" % (set_name, index + 1),
            panel_shape(_p0, _p1), "structure",
            "Independent folding ramp deck panel; packed pose is nested on the top deck.")
        ramp_parts.append({"obj": panel, "kind": "panel", "set_name": set_name, "index": index})
        for rail_name, x, color in (("Left", -RAIL_C2C / 2.0, "white"),
                                    ("Main", 0.0, "orange"),
                                    ("Right", RAIL_C2C / 2.0, "white")):
            rail = add_feature(
                egress, "%sRamp%sRail_%02d" % (set_name, rail_name, index + 1),
                "%s %s rail section %d of 3" % (set_name, rail_name.lower(), index + 1),
                truss_segment(shifted(_p0, x), shifted(_p1, x), _normal), color,
                "Separate articulated truss rail section with upper/lower members and diagonal braces.")
            ramp_parts.append({"obj": rail, "kind": "rail", "set_name": set_name,
                               "index": index, "x": x})

    frames = initial_frames
    for tie_index in range(4):
        tie = add_feature(
            egress, "%sRampMainRailConnector_%02d" % (set_name, tie_index + 1),
            "%s main rail connector %d of 4" % (set_name, tie_index + 1),
            cross_tie(frames[0][0] if tie_index == 0 else (frames[-1][1] if tie_index == 3 else frames[tie_index][0]),
                      frames[0][3] if tie_index == 0 else (frames[-1][3] if tie_index == 3 else frames[tie_index][3])),
            "orange", "Main transverse rail connector tying the left, centre, and right rail strings together.")
        ramp_parts.append({"obj": tie, "kind": "tie", "set_name": set_name, "index": tie_index})

    for joint_index in (1, 2):
        point = frames[joint_index - 1][1]
        for joint_name, x in (("Left", -RAIL_C2C / 2.0), ("Main", 0.0), ("Right", RAIL_C2C / 2.0)):
            joint = add_feature(
                egress, "%sRamp%sJoint_%02d" % (set_name, joint_name, joint_index),
                "%s %s folding joint %d of 2" % (set_name, joint_name.lower(), joint_index),
                folding_joint(point, x), "tank",
                "Pinned joint between independent rail sections; collars and cheeks shown for packaging clearance.")
            ramp_parts.append({"obj": joint, "kind": "joint", "set_name": set_name,
                               "index": joint_index, "x": x})

    hinge_point = frames[0][0]
    for hinge_name, x in (("Left", -RAIL_C2C / 2.0), ("Main", 0.0), ("Right", RAIL_C2C / 2.0)):
        hinge = add_feature(
            egress, "%sRamp%sDeckHinge" % (set_name, hinge_name),
            "%s %s deck-edge hinge" % (set_name, hinge_name.lower()),
            deck_hinge(hinge_point, x), "tank",
            "Primary hinge axis at the lander deck edge; folds the packed three-section ramp assembly outward.")
        ramp_parts.append({"obj": hinge, "kind": "hinge", "set_name": set_name, "index": 0, "x": x})

    for actuator_name, x in (("Left", -RAIL_C2C / 2.0), ("Main", 0.0), ("Right", RAIL_C2C / 2.0)):
        actuator = add_feature(
            egress, "%sRamp%sActuator" % (set_name, actuator_name),
            "%s %s ramp actuator" % (set_name, actuator_name.lower()),
            actuator_shape(side, shifted(hinge_point, x), frames[0][2]), "orange",
            "Actuator/link proxy from the lander hardpoint to the first ramp section.")
        ramp_parts.append({"obj": actuator, "kind": "actuator", "set_name": set_name,
                           "index": 0, "x": x, "side": side})

controller = doc.addObject("Part::Feature", "RampDeployment")
controller.Label = "Ramp deployment - 3-section jointed rail mechanism"
controller.Shape = Part.Shape()
egress.addObject(controller)
controller.addProperty("App::PropertyEnumeration", "State", "Ramp")
controller.State = ["Stowed", "Deployed"]
controller.State = "Stowed"
controller.addProperty("App::PropertyAngle", "OpenAngle", "Ramp")
controller.OpenAngle = NOMINAL_ANGLE
controller.addProperty("App::PropertyAngle", "MaxRampAngle", "Ramp")
controller.MaxRampAngle = MAX_TOTAL_ANGLE
controller.addProperty("App::PropertyAngle", "MaxTotalAngle", "Ramp")
controller.MaxTotalAngle = MAX_TOTAL_ANGLE
controller.addProperty("App::PropertyAngle", "DeckPitch", "Terrain")
controller.DeckPitch = 0.0
controller.addProperty("App::PropertyAngle", "TerrainSlope", "Terrain")
controller.TerrainSlope = 0.0
controller.addProperty("App::PropertyAngle", "EffectiveAngle", "Ramp")
controller.addProperty("App::PropertyString", "Compliance", "Ramp")
controller.addProperty("App::PropertyString", "OpeningMechanism", "Documentation")
controller.OpeningMechanism = "Three independent rail/deck sections fold about pinned joints; all three are driven from deck-edge hinges and link actuators."
controller.addProperty("App::PropertyString", "PackedPosition", "Documentation")
controller.PackedPosition = "Base section folds inboard/upward; middle and outer sections nest back over it on the top deck."
controller.addProperty("App::PropertyString", "RailLayout", "Documentation")
controller.RailLayout = "Each fore/aft rampway: left rail + segmented main rail + right rail, with four transverse main-rail connectors."
controller.addProperty("App::PropertyString", "OpeningLimits", "Documentation")
controller.OpeningLimits = "Nominal 24 deg deployed; effective deck pitch plus terrain slope must remain at or below 30 deg."

note = doc.addObject("Part::Feature", "RampJointPackagingNote")
note.Label = "Ramp joints and packed rail layout - iteration 4"
note.Shape = Part.Shape()
note.addProperty("App::PropertyString", "Note", "Research")
note.Note = "Lander-only study geometry based on the supplied packed Griffin photograph and public NASA/Astrobotic ramp references; exact as-built joint dimensions are not public."
documentation.addObject(note)

# Persist a visible assembly state so reopening the FCStd does not hide the
# top-level lander group and make the viewport appear empty.
for obj in doc.Objects:
    try:
        obj.ViewObject.Visibility = True
    except Exception:
        pass

doc.recompute()
if hasattr(Gui, "activeDocument"):
    Gui.activeDocument().activeView().viewAxonometric()
    Gui.activeDocument().activeView().fitAll()
doc.recompute()
doc.saveAs(OUTPUT)
print("Griffin-1 iteration 4 saved to: %s" % OUTPUT)
