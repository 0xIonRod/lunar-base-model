"""Build an editable Griffin-1 lander study model in FreeCAD.

Run from FreeCAD's Python console or Macro manager.  The script creates a
native document made from Part::Feature objects grouped into named
subassemblies, then saves griffin_1_lander.FCStd at the project root.

Coordinate convention: FreeCAD Z-up, millimetres.  This is a visual/structural
study model based on the explicit Griffin-1 prototype assumptions in
twins/astrobotic-griffin-1/research/griffin_1_assumptions.md; it is not a
flight-validated engineering model.
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

# Palette: muted lunar hardware with blue photovoltaic cells and safety orange.
COLORS = {
    "body": (0.68, 0.70, 0.72),
    "structure": (0.34, 0.37, 0.40),
    "dark": (0.12, 0.14, 0.17),
    "gold": (0.83, 0.61, 0.16),
    "solar": (0.035, 0.09, 0.30),
    "white": (0.88, 0.88, 0.84),
    "orange": (0.93, 0.45, 0.08),
    "black": (0.035, 0.04, 0.045),
    "red": (0.72, 0.10, 0.06),
}


def set_color(obj, color, transparency=0):
    obj.ViewObject.ShapeColor = color
    obj.ViewObject.LineColor = (0.12, 0.12, 0.12)
    obj.ViewObject.Transparency = transparency
    obj.ViewObject.DisplayMode = "Flat Lines"


def group(parent, name, label):
    obj = doc.addObject("App::Part", name)
    obj.Label = label
    parent.addObject(obj)
    return obj


def feature(parent, name, label, shape, color, description="", status="study proxy"):
    obj = doc.addObject("Part::Feature", name)
    obj.Label = label
    obj.Shape = shape
    parent.addObject(obj)
    set_color(obj, COLORS[color] if isinstance(color, str) else color)
    obj.addProperty("App::PropertyString", "ComponentType", "Griffin 1")
    obj.ComponentType = "Study geometry"
    obj.addProperty("App::PropertyString", "ModelStatus", "Griffin 1")
    obj.ModelStatus = status
    obj.addProperty("App::PropertyString", "Description", "Griffin 1")
    obj.Description = description
    return obj


def beam(p1, p2, radius):
    delta = p2.sub(p1)
    return Part.makeCylinder(radius, delta.Length, p1, delta)


def centered_box(length, width, height, center):
    return Part.makeBox(length, width, height, V(center.x - length / 2.0,
                                                 center.y - width / 2.0,
                                                 center.z - height / 2.0))


def rotate_about(shape, center, axis, angle):
    shape = shape.copy()
    shape.rotate(center, axis, angle)
    return shape


def add_note(parent, label, text):
    note = doc.addObject("App::FeaturePython", label.replace(" ", "_"))
    note.Label = label
    note.addProperty("App::PropertyString", "Note", "Documentation")
    note.Note = text
    parent.addObject(note)
    return note


doc = App.newDocument("Griffin1_Lander")
root = doc.addObject("App::Part", "Griffin1")
root.Label = "Griffin-1 Lander (MoonDAO prototype study)"
root.addProperty("App::PropertyString", "Mission", "Provenance")
root.Mission = "Astrobotic Griffin Mission One / NASA Moon Base II"
root.addProperty("App::PropertyString", "LandingRegion", "Provenance")
root.LandingRegion = "Nobile Crater area, lunar South Pole"
root.addProperty("App::PropertyString", "Status", "Provenance")
root.Status = "Editable visual/structural study proxy; not flight validated"
root.addProperty("App::PropertyString", "CoordinateSystem", "Provenance")
root.CoordinateSystem = "FreeCAD Z-up, millimetres"
root.addProperty("App::PropertyString", "SourceRecord", "Provenance")
root.SourceRecord = "twins/astrobotic-griffin-1/research/griffin_1_assumptions.md"

structure = group(root, "Structure", "01 Structure")
propulsion = group(root, "Propulsion", "02 Propulsion")
landing = group(root, "LandingGear", "03 Landing gear")
deck = group(root, "PayloadDeck", "04 Isogrid payload deck")
power = group(root, "Power", "05 Side solar arrays")
egress = group(root, "Egress", "06 Deployable egress ramps")
annotations = group(root, "Documentation", "07 Documentation")

# Main lander pressure/tank body: a faceted descent-stage frustum with an
# upper avionics ring.  Dimensions are deliberately presentation-scale.
body = Part.makeCone(2600, 2100, 1500, V(0, 0, 1200), V(0, 0, 1))
feature(structure, "DescentStageBody", "Descent stage body", body, "body",
        "Faceted pressure/tank body; dimensions are Griffin-1 prototype geometry.")

upper = Part.makeCylinder(1800, 520, V(0, 0, 2700), V(0, 0, 1))
feature(structure, "AvionicsRing", "Upper avionics ring", upper, "white",
        "Upper equipment ring above the descent-stage frustum.")

lower_ring = Part.makeTorus(2480, 65, V(0, 0, 1200), V(0, 0, 1), 0, 360, 360)
feature(structure, "LowerTankRing", "Lower tank ring", lower_ring, "structure",
        "Visual tank/bulkhead ring around the body base.")

upper_ring = Part.makeTorus(1770, 55, V(0, 0, 2700), V(0, 0, 1), 0, 360, 360)
feature(structure, "UpperDeckRing", "Upper deck ring", upper_ring, "structure",
        "Visual ring beneath the payload deck.")

# Propulsion cluster: four engine bells beneath the lander and small feed
# pipes leading into the body.
engine_xy = [(-1200, -1200), (-1200, 1200), (1200, -1200), (1200, 1200)]
for idx, (x, y) in enumerate(engine_xy, 1):
    bell = Part.makeCone(230, 125, 320, V(x, y, 880), V(0, 0, 1))
    feature(propulsion, "EngineBell_%02d" % idx, "Descent engine bell %02d" % idx,
            bell, "dark", "Powered-descent engine visual proxy.")
    pipe = beam(V(x, y, 1200), V(x * 0.72, y * 0.72, 1650), 42)
    feature(propulsion, "FeedLine_%02d" % idx, "Engine feed line %02d" % idx,
            pipe, "gold", "Propulsion feed-line visual proxy.")

central_nozzle = Part.makeCone(260, 150, 260, V(0, 0, 780), V(0, 0, 1))
feature(propulsion, "CentralServiceNozzle", "Central service nozzle", central_nozzle,
        "black", "Central underside service/nozzle detail.")

# Four landing legs, each with twin struts, an oleo barrel, and a wide footpad.
leg_positions = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
for idx, (sx, sy) in enumerate(leg_positions, 1):
    x_hi, y_hi = sx * 1780, sy * 1780
    x_lo, y_lo = sx * 3520, sy * 3520
    hi = V(x_hi, y_hi, 1550)
    lo = V(x_lo, y_lo, 320)
    strut = beam(hi, lo, 105)
    feature(landing, "LegStrut_%02d" % idx, "Leg %02d primary strut" % idx,
            strut, "structure", "Primary landing-leg strut.")
    rear = beam(V(sx * 1500, sy * 1500, 1780), V(x_lo, y_lo, 480), 72)
    feature(landing, "LegBrace_%02d" % idx, "Leg %02d rear brace" % idx,
            rear, "dark", "Secondary triangular landing-leg brace.")
    oleo_axis = V(sx * 95, sy * 95, 210)
    oleo = Part.makeCylinder(145, 430, lo.sub(oleo_axis), oleo_axis)
    feature(landing, "Oleo_%02d" % idx, "Leg %02d oleo" % idx,
            oleo, "gold", "Shock/oleo visual proxy.")
    pad = Part.makeBox(680, 560, 110, V(x_lo - 340, y_lo - 280, 0))
    feature(landing, "Footpad_%02d" % idx, "Leg %02d footpad" % idx,
            pad, "white", "Wide lunar landing footpad.")
    pad_rim = Part.makeBox(720, 600, 35, V(x_lo - 360, y_lo - 300, 110))
    feature(landing, "FootpadRim_%02d" % idx, "Leg %02d footpad rim" % idx,
            pad_rim, "structure", "Footpad perimeter reinforcement.")

# Payload deck and visible isogrid members.
deck_plate = centered_box(6300, 6300, 150, V(0, 0, 3340))
feature(deck, "DeckPlate", "Isogrid deck plate", deck_plate, "body",
        "6.3 m prototype deck; collision/contact surface in the Twin wrapper.")

grid_specs = [
    ("GridDiagonal_NE", 5800, 80, 80, 45),
    ("GridDiagonal_NW", 5800, 80, 80, -45),
    ("GridCrossbar_X", 5600, 80, 80, 0),
    ("GridCrossbar_Y", 80, 5600, 80, 0),
    ("GridCrossbar_X2", 4000, 65, 65, 0),
    ("GridCrossbar_Y2", 65, 4000, 65, 0),
]
for name, lx, ly, lz, angle in grid_specs:
    member = centered_box(lx, ly, lz, V(0, 0, 3445))
    if angle:
        member = rotate_about(member, V(0, 0, 3445), V(0, 0, 1), angle)
    feature(deck, name, name.replace("_", " "), member, "structure",
            "Non-colliding isogrid presentation member.")

adapter = centered_box(2900, 2900, 160, V(0, 0, 3525))
feature(deck, "PayloadAdapterPlate", "Four-point payload adapter plate", adapter, "dark",
        "Visual payload adapter; FLIP interface remains a study assumption.")
for idx, (x, y) in enumerate([(-1050, -1050), (-1050, 1050), (1050, -1050), (1050, 1050)], 1):
    post = Part.makeCylinder(90, 300, V(x, y, 3525), V(0, 0, 1))
    feature(deck, "AdapterPost_%02d" % idx, "Payload adapter restraint %02d" % idx,
            post, "structure", "Payload retention post visual proxy.")

# Two top-side avionics boxes make the deck read as a lander rather than a
# generic cone, while leaving the adapter visible.
for idx, x in enumerate((-1450, 1450), 1):
    avionics = centered_box(620, 900, 520, V(x, 820, 3810))
    feature(deck, "AvionicsBox_%02d" % idx, "Deck avionics box %02d" % idx,
            avionics, "white", "Deck-mounted avionics/equipment study volume.")

# Vertical side-mounted solar wings.  The dark blue cell plate is backed by a
# silver frame and four crossbars per wing.
for side, x, sign in (("Port", -4050, -1), ("Starboard", 3930, 1)):
    panel = Part.makeBox(120, 3200, 3600, V(x, -1600, 980))
    feature(power, "SolarCells" + side, side + " solar cell wing", panel, "solar",
            "Side-mounted photovoltaic wing; electrical sizing is TBD.")
    outer = Part.makeBox(65, 3340, 3740, V(x - 30 if sign < 0 else x - 10,
                                             -1670, 910))
    feature(power, "SolarFrame" + side, side + " solar wing frame", outer, "white",
            "Photovoltaic wing perimeter frame.")
    for row in range(1, 4):
        y = -1600 + row * 800
        cross = Part.makeBox(90, 3200, 42, V(x - 5, y, 980))
        feature(power, "SolarCrossbar%s_%02d" % (side, row),
                side + " solar crossbar %02d" % row, cross, "structure",
                "Photovoltaic wing crossbar.")

# A small communications mast and dish on the deck.
mast = Part.makeCylinder(70, 900, V(0, -980, 3525), V(0, 0, 1))
feature(structure, "CommsMast", "Communications mast", mast, "structure",
        "Top-deck communications mast visual proxy.")
dish = Part.makeCone(420, 120, 180, V(0, -980, 4425), V(0, 0, 1))
feature(structure, "CommsDish", "Communications dish", dish, "white",
        "Top-deck communications dish visual proxy.")

# Deployable side ramps.  They are authored in the deployed, slightly
# downhill presentation pose; the Twin's USD asset owns the revolute-joint
# control and stowed/deployed timing.
ramp_length = 5200
ramp_width = 3000
ramp_thick = 120
ramp_hinges = (("Port", 3150, 1, 20), ("Starboard", -3150, -1, -20))
for side, hinge_x, direction, angle in ramp_hinges:
    if direction > 0:
        ramp = Part.makeBox(ramp_length, ramp_width, ramp_thick,
                            V(hinge_x, -ramp_width / 2.0, 3260))
        ramp = rotate_about(ramp, V(hinge_x, 0, 3260), V(0, 1, 0), angle)
        outer_x = hinge_x + ramp_length
    else:
        ramp = Part.makeBox(ramp_length, ramp_width, ramp_thick,
                            V(hinge_x - ramp_length, -ramp_width / 2.0, 3260))
        ramp = rotate_about(ramp, V(hinge_x, 0, 3260), V(0, 1, 0), angle)
        outer_x = hinge_x - ramp_length
    feature(egress, "RampSurface" + side, side + " egress ramp surface", ramp, "structure",
            "Physical contact surface; 12 m collision envelope remains in the Twin USD study asset.")
    # Edge rails follow the same rigid-body transform as the ramp surface.
    rail_a = Part.makeBox(ramp_length, 100, 220,
                          V(hinge_x if direction > 0 else hinge_x - ramp_length,
                            -ramp_width / 2.0 - 70, 3380))
    rail_b = Part.makeBox(ramp_length, 100, 220,
                          V(hinge_x if direction > 0 else hinge_x - ramp_length,
                            ramp_width / 2.0 - 30, 3380))
    rail_a = rotate_about(rail_a, V(hinge_x, 0, 3260), V(0, 1, 0), angle)
    rail_b = rotate_about(rail_b, V(hinge_x, 0, 3260), V(0, 1, 0), angle)
    feature(egress, "RampRail" + side + "A", side + " ramp edge rail A", rail_a, "white",
            "Raised ramp edge rail.")
    feature(egress, "RampRail" + side + "B", side + " ramp edge rail B", rail_b, "white",
            "Raised ramp edge rail.")
    hinge = Part.makeCylinder(145, ramp_width, V(hinge_x, -ramp_width / 2.0, 3260), V(0, 1, 0))
    feature(egress, "RampHinge" + side, side + " ramp revolute hinge", hinge, "gold",
            "Visual hinge; USD PhysicsRevoluteJoint owns simulation articulation.")
    # A small orange deployment actuator is intentionally visible at the hinge.
    actuator_end = V(outer_x - direction * 950, 0, 2350)
    actuator = beam(V(hinge_x, 0, 3260), actuator_end, 70)
    feature(egress, "RampActuator" + side, side + " ramp deployment actuator", actuator, "orange",
            "Deployment actuator visual proxy.")

# Documentation objects keep provenance close to the model in the FreeCAD tree.
add_note(annotations, "Prototype boundary",
         "This is an editable visual/structural study model. Griffin-1 as-built dimensions, masses, propulsion data, leg geometry, and landing qualification data remain unknown.")
add_note(annotations, "Payload boundary",
         "The 625 kg payload class, four-leg deck, side solar wings, and two ramps are MoonDAO prototype requirements recorded in the repository, not public Griffin flight values.")
add_note(annotations, "Twin mapping",
         "The companion LunCoSim wrapper is twins/astrobotic-griffin-1/vehicles/griffin_1.usda. FreeCAD uses Z-up for presentation; the Twin USD wrapper uses its own authored transform conventions.")

doc.recompute()

project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))) if "__file__" in globals() else os.getcwd()
output_path = os.path.join(project_root, "griffin_1_lander.FCStd")
doc.recompute()
doc.saveAs(output_path)

if Gui is not None:
    Gui.activeDocument().activeView().viewAxonometric()
    Gui.activeDocument().activeView().fitAll()

print("Griffin-1 FreeCAD study model saved to: %s" % output_path)
