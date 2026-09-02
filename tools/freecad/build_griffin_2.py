"""Build Griffin-1 iteration 2: research-informed lander-only study.

This is an editable visual/structural proxy, not flight CAD.  It keeps the
lander separate from any rover and models the ramp interface explicitly:

* compact aluminum/isogrid bus with four landing legs;
* four evenly spaced propellant COPV proxies and three pressurant proxies;
* seven current-configuration main-engine proxies and four ACS clusters;
* polar side solar arrays, radiator panels, payload adapter, and avionics;
* two fore/aft ramp sets, each made from two folding ramp segments.

The ``Ramp deployment`` object exposes ``State``, ``OpenAngle``,
``DeckPitch``, and ``TerrainSlope`` properties.  Changing them and pressing
Recompute updates the ramp geometry.  The deployed ramp angle is bounded by
the 30-degree total-angle requirement in the NASA VIPER technical interface
document; terrain/deck attitude is included in the reported effective angle.

Run from FreeCAD's Python console or Macro manager.  The script saves
``griffin_2_lander.FCStd`` at the NASA-lunar-base-model project root.
"""

import math
import os

import FreeCAD as App
import Part

try:
    Gui  # noqa: F821 - available when run inside the FreeCAD GUI
except NameError:
    Gui = None


V = App.Vector

COLORS = {
    "body": (0.63, 0.66, 0.69),
    "structure": (0.25, 0.29, 0.33),
    "radiator": (0.78, 0.80, 0.80),
    "dark": (0.10, 0.12, 0.15),
    "tank": (0.73, 0.49, 0.18),
    "solar": (0.025, 0.075, 0.28),
    "white": (0.86, 0.86, 0.82),
    "orange": (0.93, 0.43, 0.06),
    "warning": (0.80, 0.12, 0.05),
}


# Research-informed presentation dimensions in millimetres.  Public Griffin
# documents provide interfaces, system counts, and payload constraints more
# often than complete manufacturing dimensions, so these are explicit study
# assumptions rather than claimed as-built dimensions.
DECK_X = 4500.0
DECK_Y = 4500.0
DECK_Z = 2150.0
BUS_X = 3600.0
BUS_Y = 3600.0
BUS_Z0 = 600.0
BUS_Z1 = 1850.0
FRAME_T = 95.0
LEG_MOUNT_Z = 1600.0
LEG_FOOT_R = 2550.0
RAMP_LENGTH = 5050.0
RAMP_WIDTH = 700.0
RAMP_TRACK_C2C = 2300.0
RAMP_THICK = 80.0
RAMP_RAIL_H = 155.0
RAMP_MAX_TOTAL = 30.0
NOMINAL_RAMP_ANGLE = 24.0


def set_color(obj, color, transparency=0):
    view = getattr(obj, "ViewObject", None)
    if view is None:
        return
    view.ShapeColor = COLORS[color] if isinstance(color, str) else color
    view.LineColor = (0.10, 0.11, 0.12)
    view.Transparency = transparency
    view.DisplayMode = "Flat Lines"


def add_string(obj, name, group_name, value):
    obj.addProperty("App::PropertyString", name, group_name)
    setattr(obj, name, value)


def add_length(obj, name, group_name, value):
    obj.addProperty("App::PropertyLength", name, group_name)
    setattr(obj, name, value)


def add_angle(obj, name, group_name, value):
    obj.addProperty("App::PropertyAngle", name, group_name)
    setattr(obj, name, value)


def add_feature(parent, name, label, shape, color, description="", status="study proxy"):
    obj = doc.addObject("Part::Feature", name)
    obj.Label = label
    obj.Shape = shape
    parent.addObject(obj)
    set_color(obj, color)
    add_string(obj, "ComponentType", "Griffin 2", "Study geometry")
    add_string(obj, "ModelStatus", "Griffin 2", status)
    add_string(obj, "Description", "Griffin 2", description)
    return obj


def add_group(parent, name, label):
    obj = doc.addObject("App::Part", name)
    obj.Label = label
    parent.addObject(obj)
    return obj


def beam(p1, p2, radius):
    delta = p2.sub(p1)
    return Part.makeCylinder(radius, delta.Length, p1, delta)


def box_centered(length, width, height, center):
    return Part.makeBox(
        length,
        width,
        height,
        V(center.x - length / 2.0, center.y - width / 2.0, center.z - height / 2.0),
    )


def rotate(shape, center, axis, angle):
    result = shape.copy()
    result.rotate(center, axis, angle)
    return result


def radial_box(length, width, height, center, angle):
    return rotate(box_centered(length, width, height, center), V(center.x, center.y, center.z), V(0, 0, 1), angle)


def point_on_ramp(side, x, distance, angle_deg):
    angle = math.radians(angle_deg)
    return V(
        x,
        side * (DECK_Y / 2.0 + distance * math.cos(angle)),
        DECK_Z - distance * math.sin(angle),
    )


def make_ramp_box(side, x, width, length, thick, angle_deg):
    hinge_y = side * DECK_Y / 2.0
    if side > 0:
        shape = Part.makeBox(width, length, thick, V(x - width / 2.0, hinge_y, DECK_Z - thick / 2.0))
        return rotate(shape, V(x, hinge_y, DECK_Z), V(1, 0, 0), -angle_deg)
    shape = Part.makeBox(width, length, thick, V(x - width / 2.0, hinge_y - length, DECK_Z - thick / 2.0))
    return rotate(shape, V(x, hinge_y, DECK_Z), V(1, 0, 0), angle_deg)


def make_ramp_rail(side, x, lane_sign, angle_deg):
    rail_width = 90.0
    rail_x = x + lane_sign * (RAMP_WIDTH / 2.0 - rail_width / 2.0)
    shape = make_ramp_box(side, rail_x, rail_width, RAMP_LENGTH, RAMP_RAIL_H, angle_deg)
    return shape


def make_ramp_texture(side, x, angle_deg):
    strips = []
    for distance in range(420, int(RAMP_LENGTH - 200), 360):
        strip = make_ramp_box(side, x, RAMP_WIDTH - 100.0, 22.0, 8.0, angle_deg)
        offset = distance * math.cos(math.radians(angle_deg))
        dz = -distance * math.sin(math.radians(angle_deg))
        strip.translate(V(0, side * offset, dz))
        strips.append(strip)
    return Part.makeCompound(strips)


class RampController:
    """Small FeaturePython controller for the four folding ramp segments."""

    def __init__(self, obj, ramp_parts):
        self.obj = obj
        self.ramp_parts = ramp_parts
        obj.Proxy = self

    def execute(self, obj):
        commanded = float(obj.OpenAngle)
        if obj.State == "Stowed":
            geometry_angle = 85.0
        else:
            geometry_angle = min(commanded, float(obj.MaxRampAngle))
        effective = geometry_angle + abs(float(obj.DeckPitch)) + abs(float(obj.TerrainSlope))
        obj.EffectiveAngle = effective
        obj.Compliance = "PASS" if effective <= float(obj.MaxTotalAngle) else "CHECK"

        for part in self.ramp_parts:
            side = part["side"]
            x = part["x"]
            kind = part["kind"]
            if kind == "surface":
                part["obj"].Shape = make_ramp_box(side, x, RAMP_WIDTH, RAMP_LENGTH, RAMP_THICK, geometry_angle)
            elif kind == "outer_rail":
                part["obj"].Shape = make_ramp_rail(side, x, part["lane_sign"], geometry_angle)
            elif kind == "texture":
                part["obj"].Shape = make_ramp_texture(side, x, geometry_angle)
            elif kind == "actuator":
                hinge_y = side * DECK_Y / 2.0
                base = V(x, hinge_y - side * 320.0, DECK_Z - 430.0)
                end = point_on_ramp(side, x, RAMP_LENGTH * 0.52, geometry_angle)
                part["obj"].Shape = beam(base, end, 38.0)

    def onChanged(self, obj, prop):
        if prop in ("State", "OpenAngle", "DeckPitch", "TerrainSlope", "MaxRampAngle", "MaxTotalAngle"):
            obj.touch()

    def __getstate__(self):
        return {"version": 1}

    def __setstate__(self, state):
        return None


doc = App.newDocument("Griffin2_Lander")
root = doc.addObject("App::Part", "Griffin2")
root.Label = "Griffin-1 Lander — iteration 2 (research-informed study)"
add_string(root, "Mission", "Provenance", "Astrobotic Griffin Mission One / lander only")
add_string(root, "Scope", "Provenance", "Rover excluded; payload interface and egress hardware retained")
add_string(root, "CoordinateSystem", "Provenance", "FreeCAD Z-up, millimetres")
add_string(root, "Status", "Provenance", "Editable visual/structural proxy; not flight validated")
add_string(root, "ResearchBasis", "Provenance", "Astrobotic Griffin PUG, NASA VIPER interface requirements, Griffin-1 updates")

structure = add_group(root, "Structure", "01 Structure and isogrid bus")
propulsion = add_group(root, "Propulsion", "02 Propulsion: main engines, tanks, ACS")
landing = add_group(root, "LandingGear", "03 Landing gear")
deck = add_group(root, "PayloadDeck", "04 Payload deck and adapter")
power = add_group(root, "Power", "05 Polar solar arrays and radiators")
egress = add_group(root, "Egress", "06 Folding ramp sets")
avionics = add_group(root, "Avionics", "07 Avionics, sensors, communications")
documentation = add_group(root, "Documentation", "08 Research notes and interface assumptions")

# Box/isogrid primary bus: four solid deck/radiator panels and a central
# lower service volume, following the common Griffin bus description.
bus = box_centered(BUS_X, BUS_Y, BUS_Z1 - BUS_Z0, V(0, 0, (BUS_Z0 + BUS_Z1) / 2.0))
add_feature(structure, "PrimaryBus", "Primary aluminum bus", bus, "body",
            "Compact box bus proxy; public Griffin material describes an aluminum frame and solid deck panels.")

deck_plate = box_centered(DECK_X, DECK_Y, 120.0, V(0, 0, DECK_Z))
add_feature(deck, "MainIsogridDeck", "Main isogrid payload deck", deck_plate, "body",
            "Regular payload mounting surface; exact bolt pattern is mission-specific.")

for name, center, length, width in (
    ("DeckRailNorth", V(0, DECK_Y / 2.0 - FRAME_T / 2.0, DECK_Z + 95.0), DECK_X, FRAME_T),
    ("DeckRailSouth", V(0, -DECK_Y / 2.0 + FRAME_T / 2.0, DECK_Z + 95.0), DECK_X, FRAME_T),
    ("DeckRailEast", V(DECK_X / 2.0 - FRAME_T / 2.0, 0, DECK_Z + 95.0), FRAME_T, DECK_Y),
    ("DeckRailWest", V(-DECK_X / 2.0 + FRAME_T / 2.0, 0, DECK_Z + 95.0), FRAME_T, DECK_Y),
):
    add_feature(structure, name, name.replace("Deck", "Deck "), box_centered(length, width, 190.0, center), "structure",
                "Primary isogrid/deck perimeter beam.")

for idx, (x, y) in enumerate(((-1450, -1450), (-1450, 1450), (1450, -1450), (1450, 1450)), 1):
    add_feature(deck, "PayloadLock_%02d" % idx, "Payload adapter restraint %02d" % idx,
                Part.makeCylinder(70.0, 220.0, V(x, y, DECK_Z + 55.0), V(0, 0, 1)), "structure",
                "Study proxy for payload release/retention interface.")

adapter = box_centered(2700.0, 2700.0, 110.0, V(0, 0, DECK_Z + 175.0))
adapter_obj = add_feature(deck, "PayloadAdapter", "Dedicated payload adapter", adapter, "dark",
                          "Mission-specific adapter plate; rover omitted from this lander-only model.")
add_length(adapter_obj, "AdapterLength", "Interface", 2700.0)
add_length(adapter_obj, "AdapterWidth", "Interface", 2700.0)

# Four side radiator panels below the deck.  The polar configuration uses
# side-mounted solar panels and radiator-mounted avionics.
for side, axis in (("North", "Y+"), ("South", "Y-"), ("East", "X+"), ("West", "X-")):
    if axis.startswith("Y"):
        panel = box_centered(DECK_X - 500.0, 90.0, 760.0, V(0, 1800.0 if axis == "Y+" else -1800.0, 1450.0))
    else:
        panel = box_centered(90.0, DECK_Y - 500.0, 760.0, V(1800.0 if axis == "X+" else -1800.0, 0, 1450.0))
    add_feature(power, "Radiator" + side, side + " radiator panel", panel, "radiator",
                "Side radiator / avionics mounting panel proxy.")

# Four current Griffin-1 COPV propellant tank proxies, evenly spaced around
# the bus; alternate labels retain the fuel/oxidizer study distinction.
tank_positions = [(-1400.0, -1500.0, "Fuel"), (1400.0, -1500.0, "Oxidizer"),
                  (-1400.0, 1500.0, "Oxidizer"), (1400.0, 1500.0, "Fuel")]
for idx, (x, y, fluid) in enumerate(tank_positions, 1):
    tank = Part.makeCylinder(330.0, 1900.0, V(x, y - 950.0, 1150.0), V(0, 1, 0))
    tank_obj = add_feature(propulsion, "COPV_%02d" % idx, "%s COPV tank %02d" % (fluid, idx), tank, "tank",
                           "Current Griffin-1 four-tank propulsion architecture study proxy.")
    add_length(tank_obj, "TankDiameter", "Dimensions", 660.0)
    add_length(tank_obj, "TankLength", "Dimensions", 1900.0)

# Three helium pressurant tank proxies grouped near the central service bay.
for idx, x in enumerate((-430.0, 0.0, 430.0), 1):
    pressurant = Part.makeCylinder(150.0, 1100.0, V(x, -550.0, 1550.0), V(0, 1, 0))
    add_feature(propulsion, "Pressurant_%02d" % idx, "Helium pressurant tank %02d" % idx,
                pressurant, "white", "Three-tank pressurant study proxy from Griffin-1 propulsion updates.")

# Seven current-configuration main engines: one center plus six around it.
engine_positions = [(0.0, 0.0)]
for idx in range(6):
    a = math.radians(idx * 60.0)
    engine_positions.append((1050.0 * math.cos(a), 1050.0 * math.sin(a)))
for idx, (x, y) in enumerate(engine_positions, 1):
    bell = Part.makeCone(230.0, 135.0, 300.0, V(x, y, 220.0), V(0, 0, 1))
    add_feature(propulsion, "MainEngine_%02d" % idx, "Main engine %02d" % idx, bell, "dark",
                "Current Griffin main-engine visual proxy; engine count follows current Astrobotic product information.")

# Four ACS clusters, each represented by three small outward-facing thrusters.
for cluster_idx, (x, y, direction) in enumerate(((0, 1780, V(0, 1, 0)), (1780, 0, V(1, 0, 0)),
                                                   (0, -1780, V(0, -1, 0)), (-1780, 0, V(-1, 0, 0))), 1):
    cluster_shapes = []
    for thruster_idx, z in enumerate((1050.0, 1350.0, 1650.0), 1):
        base = V(x, y, z)
        cluster_shapes.append(Part.makeCone(85.0, 48.0, 170.0, base, direction))
    add_feature(propulsion, "ACSCluster_%02d" % cluster_idx, "ACS thruster cluster %02d" % cluster_idx,
                Part.makeCompound(cluster_shapes), "dark",
                "Three-nozzle attitude-control cluster; actual plumbing and cant angles remain TBD.")

# Four landing legs with hinge barrels, primary struts, braces, oleos, and
# circular footpads.  The four-foot geometry defines the landing support base.
for idx, (sx, sy) in enumerate(((-1, -1), (-1, 1), (1, -1), (1, 1)), 1):
    mount = V(sx * 1650.0, sy * 1650.0, LEG_MOUNT_Z)
    foot = V(sx * LEG_FOOT_R, sy * LEG_FOOT_R, 310.0)
    hinge = Part.makeCylinder(95.0, 420.0, V(mount.x - 210.0, mount.y, mount.z), V(1, 0, 0))
    add_feature(landing, "LegHinge_%02d" % idx, "Leg %02d bus hinge" % idx, hinge, "structure",
                "Landing-leg primary hinge proxy.")
    add_feature(landing, "LegStrut_%02d" % idx, "Leg %02d primary strut" % idx,
                beam(mount, foot, 115.0), "structure", "Primary shock-bearing leg strut.")
    brace_start = V(sx * 1380.0, sy * 1380.0, 1850.0)
    add_feature(landing, "LegBrace_%02d" % idx, "Leg %02d diagonal brace" % idx,
                beam(brace_start, foot, 72.0), "dark", "Secondary landing-leg brace.")
    oleo_axis = V(sx * 70.0, sy * 70.0, 205.0)
    add_feature(landing, "Oleo_%02d" % idx, "Leg %02d oleo" % idx,
                Part.makeCylinder(125.0, 400.0, foot.sub(oleo_axis), oleo_axis), "tank",
                "Shock/oleo visual proxy.")
    pad = Part.makeCylinder(300.0, 85.0, V(foot.x, foot.y, 0.0), V(0, 0, 1))
    add_feature(landing, "Footpad_%02d" % idx, "Leg %02d circular footpad" % idx, pad, "white",
                "Circular lunar footpad; surface contact proxy.")

# Two large polar side solar wings on the non-ramp sides.  The panels are
# vertical, with simple hinge/boom details and a perimeter frame.
for side, x, sign in (("Port", -2350.0, -1), ("Starboard", 2280.0, 1)):
    cells = Part.makeBox(80.0, 3000.0, 1450.0, V(x, -1500.0, 600.0))
    add_feature(power, "SolarCells" + side, side + " polar solar wing", cells, "solar",
                "Vertical side-mounted solar array for polar operations.")
    frame = Part.makeBox(55.0, 3140.0, 1590.0, V(x - 30.0 if sign < 0 else x + 20.0, -1570.0, 530.0))
    add_feature(power, "SolarFrame" + side, side + " solar wing frame", frame, "white",
                "Solar wing perimeter frame proxy.")
    boom = beam(V(sign * 1800.0, 0, 1550.0), V(x, 0, 1550.0), 38.0)
    add_feature(power, "SolarBoom" + side, side + " solar wing boom", boom, "structure",
                "Rigid solar-wing support boom.")

# Communications and landing sensors.
mast = Part.makeCylinder(55.0, 800.0, V(0, -720.0, DECK_Z + 120.0), V(0, 0, 1))
add_feature(avionics, "CommsMast", "Communications mast", mast, "structure",
            "Medium/high-gain communications mast proxy.")
dish = Part.makeCone(330.0, 110.0, 150.0, V(0, -720.0, DECK_Z + 920.0), V(0, 0, 1))
add_feature(avionics, "CommsDish", "Communications dish", dish, "white",
            "Actuated antenna/dish proxy; detailed pointing envelope is mission-specific.")
for idx, (x, y) in enumerate(((-1200, -1900), (1200, -1900), (-1200, 1900), (1200, 1900)), 1):
    sensor = Part.makeBox(240.0, 180.0, 180.0, V(x - 120.0, y - 90.0, DECK_Z - 300.0))
    add_feature(avionics, "LandingSensor_%02d" % idx, "Landing hazard sensor %02d" % idx, sensor, "white",
                "Landing/GNC sensor study proxy.")

# Build two fore/aft folding ramp sets.  Each set has two parallel ramp
# segments, an outer guide rail, low traction markings, hinge, and actuator.
ramp_parts = []
for set_name, side in (("Aft", 1), ("Fore", -1)):
    for lane_idx, lane_sign in enumerate((-1, 1), 1):
        x = lane_sign * RAMP_TRACK_C2C / 2.0
        surface = add_feature(egress, "%sRampSurface_%02d" % (set_name, lane_idx),
                              "%s ramp segment %02d" % (set_name, lane_idx),
                              make_ramp_box(side, x, RAMP_WIDTH, RAMP_LENGTH, RAMP_THICK, NOMINAL_RAMP_ANGLE),
                              "structure", "Folding ramp surface; angle is controlled by Ramp deployment.")
        outer_rail = add_feature(egress, "%sRampOuterRail_%02d" % (set_name, lane_idx),
                                 "%s ramp outer guide rail %02d" % (set_name, lane_idx),
                                 make_ramp_rail(side, x, lane_sign, NOMINAL_RAMP_ANGLE), "white",
                                 "Outer guard rail; inward-facing wall intentionally kept smooth.")
        texture = add_feature(egress, "%sRampTraction_%02d" % (set_name, lane_idx),
                              "%s ramp traction markings %02d" % (set_name, lane_idx),
                              make_ramp_texture(side, x, NOMINAL_RAMP_ANGLE), "orange",
                              "Low-profile engagement/marking pattern compatible with wheel contact study.")
        hinge_y = side * DECK_Y / 2.0
        hinge = Part.makeCylinder(78.0, RAMP_WIDTH, V(x - RAMP_WIDTH / 2.0, hinge_y, DECK_Z), V(1, 0, 0))
        add_feature(egress, "%sRampHinge_%02d" % (set_name, lane_idx), "%s ramp hinge %02d" % (set_name, lane_idx),
                    hinge, "tank", "Folding hinge barrel at deck edge.")
        actuator = add_feature(egress, "%sRampActuator_%02d" % (set_name, lane_idx),
                               "%s ramp deployment actuator %02d" % (set_name, lane_idx),
                               beam(V(x, hinge_y - side * 320.0, DECK_Z - 430.0),
                                    point_on_ramp(side, x, RAMP_LENGTH * 0.52, NOMINAL_RAMP_ANGLE), 38.0),
                               "orange", "Actuator proxy driving the folding ramp.")
        ramp_parts.extend((
            {"obj": surface, "kind": "surface", "side": side, "x": x},
            {"obj": outer_rail, "kind": "outer_rail", "side": side, "x": x, "lane_sign": lane_sign},
            {"obj": texture, "kind": "texture", "side": side, "x": x},
            {"obj": actuator, "kind": "actuator", "side": side, "x": x},
        ))

# Ramp controller and explicit interface properties.
ramp_control = doc.addObject("App::FeaturePython", "RampDeployment")
ramp_control.Label = "Ramp deployment (interactive)"
egress.addObject(ramp_control)
ramp_control.addProperty("App::PropertyEnumeration", "State", "Ramp")
ramp_control.State = ["Deployed", "Stowed"]
ramp_control.State = "Deployed"
ramp_control.addProperty("App::PropertyAngle", "OpenAngle", "Ramp")
ramp_control.OpenAngle = NOMINAL_RAMP_ANGLE
ramp_control.addProperty("App::PropertyAngle", "MaxRampAngle", "Ramp")
ramp_control.MaxRampAngle = RAMP_MAX_TOTAL
ramp_control.addProperty("App::PropertyAngle", "MaxTotalAngle", "Ramp")
ramp_control.MaxTotalAngle = RAMP_MAX_TOTAL
ramp_control.addProperty("App::PropertyAngle", "DeckPitch", "Terrain")
ramp_control.DeckPitch = 0.0
ramp_control.addProperty("App::PropertyAngle", "TerrainSlope", "Terrain")
ramp_control.TerrainSlope = 0.0
ramp_control.addProperty("App::PropertyAngle", "EffectiveAngle", "Ramp")
ramp_control.addProperty("App::PropertyString", "Compliance", "Ramp")
ramp_control.addProperty("App::PropertyString", "OpeningDescription", "Documentation")
ramp_control.OpeningDescription = "Two fore/aft ramp sets fold about deck-edge hinges; each set has two parallel segments."
ramp_control.addProperty("App::PropertyString", "InterfaceBasis", "Documentation")
ramp_control.InterfaceBasis = "NASA VIPER requirements: <=30 deg total; smooth inner walls; positive wheel engagement; terrain/deck attitude matters."
RampController(ramp_control, ramp_parts)

# Research/provenance notes are kept in the document tree.
for label, text in (
    ("Scope boundary", "Lander only. VIPER/FLIP rover geometry is intentionally excluded; the deck and egress interfaces remain."),
    ("Structure basis", "Astrobotic describes an aluminum frame, solid deck panels, four radiator panels, a payload adapter, optional ramps, and four landing legs."),
    ("Propulsion basis", "Current Astrobotic Griffin information lists seven main engines and four ACS clusters; the older 2022 PUG listed five main engines for an earlier configuration."),
    ("Tank basis", "Griffin-1 updates describe four COPV propellant tanks; three helium pressurant tanks are represented as study proxies."),
    ("Ramp basis", "NASA describes two folding ramps/fore-aft ramp sets. The model exposes ramp state, angle, deck pitch, terrain slope, and a 30-degree effective-angle check."),
    ("Evidence boundary", "Public sources do not provide a complete current manufacturing drawing set. Dimensions marked here are explicit visual study assumptions."),
):
    note = doc.addObject("App::FeaturePython", label.replace(" ", "_"))
    note.Label = label
    note.addProperty("App::PropertyString", "Note", "Research")
    note.Note = text
    documentation.addObject(note)

doc.recompute()
for obj in doc.Objects:
    try:
        obj.ViewObject.Visibility = True
    except Exception:
        pass

if Gui is not None:
    Gui.activeDocument().activeView().viewAxonometric()
    Gui.activeDocument().activeView().fitAll()

project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) if "__file__" in globals() else os.getcwd()
output_path = os.path.join(project_root, "griffin_2_lander.FCStd")
doc.recompute()
doc.saveAs(output_path)
print("Griffin-1 iteration 2 saved to: %s" % output_path)
