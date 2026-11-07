"""Reference-upgraded Griffin-1 lander builder for FreeCAD.

Run this file with FreeCAD 1.1+ (GUI macro or FreeCADCmd). It saves
griffin_1_lander.FCStd at the project root. Units are millimetres, Z-up.
This is a reference-informed visual/structural study proxy, not an as-built
or flight-validated vehicle.
"""

import os

import FreeCAD as App
import Part

try:
    import FreeCADGui as Gui
except ImportError:
    Gui = None

V = App.Vector

COLORS = {
    "bus": (0.70, 0.72, 0.74), "silver": (0.84, 0.85, 0.84),
    "frame": (0.96, 0.58, 0.10), "gold": (0.78, 0.58, 0.18),
    "dark": (0.08, 0.10, 0.13), "solar": (0.025, 0.055, 0.19),
    "solar_cell": (0.015, 0.025, 0.09), "black": (0.025, 0.03, 0.035),
    "orange": (0.92, 0.34, 0.05), "white": (0.92, 0.92, 0.88),
}


def set_color(obj, color):
    # FreeCADCmd has no GUI view provider; shape creation and saving still work.
    view = getattr(obj, "ViewObject", None)
    if view is not None:
        view.ShapeColor = color
        view.LineColor = (0.12, 0.12, 0.12)
        view.DisplayMode = "Flat Lines"


def make_group(parent, name, label):
    obj = doc.addObject("App::Part", name)
    obj.Label = label
    parent.addObject(obj)
    return obj


def add_feature(parent, name, label, shape, color, description=""):
    obj = doc.addObject("Part::Feature", name)
    obj.Label = label
    obj.Shape = shape
    parent.addObject(obj)
    set_color(obj, COLORS[color] if isinstance(color, str) else color)
    obj.addProperty("App::PropertyString", "ComponentType", "Griffin 1")
    obj.ComponentType = "Study geometry"
    obj.addProperty("App::PropertyString", "ModelStatus", "Griffin 1")
    obj.ModelStatus = "Visual/structural proxy"
    obj.addProperty("App::PropertyString", "Description", "Griffin 1")
    obj.Description = description
    return obj


def add_note(parent, label, text):
    obj = doc.addObject("App::FeaturePython", label.replace(" ", "_"))
    obj.Label = label
    obj.addProperty("App::PropertyString", "Note", "Documentation")
    obj.Note = text
    parent.addObject(obj)
    return obj


def beam(p1, p2, radius):
    delta = p2.sub(p1)
    return Part.makeCylinder(radius, delta.Length, p1, delta)


def centered_box(length, width, height, center):
    return Part.makeBox(length, width, height,
                        V(center.x - length / 2.0,
                          center.y - width / 2.0,
                          center.z - height / 2.0))


def polygon_prism(points, z0, height):
    vertices = [V(x, y, z0) for x, y in points]
    vertices.append(vertices[0])
    wire = Part.makePolygon(vertices)
    return Part.Face(wire).extrude(V(0, 0, height))


def rotate_about(shape, center, axis, angle):
    copy = shape.copy()
    copy.rotate(center, axis, angle)
    return copy


def solar_panel(parent, key, backing, cell_origin, cell_size, rows, cols, axes):
    """Add one orange-backed, dark-cell photovoltaic wall."""
    add_feature(parent, "SolarBacking_" + key, key + " solar backing", backing,
                "frame", "Orange cell interconnect/backing visible between cells.")
    cw, ch = cell_size
    gap = 55
    cells = []
    for r in range(rows):
        for c in range(cols):
            if axes[0] == "front":
                x = cell_origin.x + c * (cw + gap)
                z = cell_origin.z + r * (ch + gap)
                cells.append(Part.makeBox(cw, 28, ch, V(x, cell_origin.y, z)))
            else:
                y = cell_origin.y + c * (cw + gap)
                z = cell_origin.z + r * (ch + gap)
                cells.append(Part.makeBox(28, cw, ch, V(cell_origin.x, y, z)))
    add_feature(parent, "SolarCells_" + key, key + " solar cell field",
                Part.makeCompound(cells), "solar_cell",
                "Grouped photovoltaic tiles; cell count is presentation geometry.")
    if axes[0] == "front":
        total_w = cols * cw + (cols - 1) * gap
        total_h = rows * ch + (rows - 1) * gap
        x0, y0, z0 = cell_origin.x - 100, cell_origin.y - 40, cell_origin.z - 100
        frame = Part.makeCompound([
            Part.makeBox(total_w + 200, 55, 55, V(x0, y0, z0)),
            Part.makeBox(total_w + 200, 55, 55, V(x0, y0, z0 + total_h + 145)),
            Part.makeBox(55, 55, total_h + 200, V(x0, y0, z0)),
            Part.makeBox(55, 55, total_h + 200, V(x0 + total_w + 145, y0, z0)),
        ])
    else:
        total_w = cols * cw + (cols - 1) * gap
        total_h = rows * ch + (rows - 1) * gap
        x0, y0, z0 = cell_origin.x - 40, cell_origin.y - 100, cell_origin.z - 100
        frame = Part.makeCompound([
            Part.makeBox(55, total_w + 200, 55, V(x0, y0, z0)),
            Part.makeBox(55, total_w + 200, 55, V(x0, y0, z0 + total_h + 145)),
            Part.makeBox(55, 55, total_h + 200, V(x0, y0, z0)),
            Part.makeBox(55, 55, total_h + 200, V(x0, y0 + total_w + 145, z0)),
        ])
    add_feature(parent, "SolarFrame_" + key, key + " solar perimeter frame", frame,
                "silver", "Perimeter panel frame and blanket restraint.")


doc = App.newDocument("Griffin1_Lander_Upgrade")
root = doc.addObject("App::Part", "Griffin1")
root.Label = "Griffin-1 Lander — reference-upgraded study"
for prop, value in (
    ("Mission", "Astrobotic Griffin Mission One / NASA Moon Base II"),
    ("LandingRegion", "Nobile Crater area, lunar South Pole"),
    ("Status", "Reference-informed visual/structural proxy; not flight validated"),
    ("CoordinateSystem", "FreeCAD Z-up, millimetres"),
    ("SourceRecord", "twins/astrobotic-griffin-1/research/griffin_1_assumptions.md"),
):
    root.addProperty("App::PropertyString", prop, "Provenance")
    setattr(root, prop, value)

structure = make_group(root, "Structure", "01 Main bus and structure")
solar = make_group(root, "SolarWalls", "02 Wraparound solar-panel walls")
tanks = make_group(root, "UpperTanks", "03 Gold-wrapped upper tanks")
payload = make_group(root, "PayloadBay", "04 Central payload and egress")
pods = make_group(root, "CornerPods", "05 Corner avionics / sensor pods")
landing = make_group(root, "LandingGear", "06 Splayed landing gear")
propulsion = make_group(root, "Propulsion", "07 Thrusters and service hardware")
docs = make_group(root, "Documentation", "08 Reference and assumption notes")

# Broad, low, faceted Griffin-style central bus.
bus_outline = [(-3800, -2450), (-1900, -3350), (1900, -3350), (3800, -2450),
               (3800, 2450), (1900, 3350), (-1900, 3350), (-3800, 2450)]
bus = polygon_prism(bus_outline, 720, 1640)
add_feature(structure, "MainFacetedBus", "Faceted main lander bus", bus, "bus",
            "Broad low Griffin-style bus; dimensions are a visual study assumption.")
lower_skirt = polygon_prism(bus_outline, 520, 230)
add_feature(structure, "LowerStructuralSkirt", "Lower structural skirt", lower_skirt, "dark",
            "Dark lower equipment/thermal skirt below the bus.")
top_ring = Part.makeTorus(2850, 70, V(0, 0, 2360), V(0, 0, 1), 0, 360, 360)
add_feature(structure, "TopStructuralRing", "Upper structural ring", top_ring, "silver",
            "Visible ring under the payload and tank deck.")

# Four independent walls keep the solar wrap editable and visually obvious.
solar_panel(solar, "Front", Part.makeBox(6200, 90, 1740, V(-3100, -3410, 700)),
            V(-3000, -3455, 790), (260, 150), 8, 20, ("front",))
solar_panel(solar, "Rear", Part.makeBox(6200, 90, 1740, V(-3100, 3320, 700)),
            V(-3000, 3365, 790), (260, 150), 8, 20, ("front",))
solar_panel(solar, "Port", Part.makeBox(90, 4200, 1740, V(-3850, -2100, 700)),
            V(-3895, -2000, 790), (260, 150), 8, 13, ("side",))
solar_panel(solar, "Starboard", Part.makeBox(90, 4200, 1740, V(3760, -2100, 700)),
            V(3825, -2000, 790), (260, 150), 8, 13, ("side",))

# Four gold-wrapped spherical tanks on the upper deck.
for idx, (x, y) in enumerate([(-1850, -1150), (1850, -1150), (-1850, 1150), (1850, 1150)], 1):
    sphere = Part.makeSphere(920, V(x, y, 2850))
    add_feature(tanks, "Tank_%02d" % idx, "Gold-wrapped propellant tank %02d" % idx,
                sphere, "gold", "Upper spherical tank with gold thermal-blanket study finish.")
    ring = Part.makeTorus(905, 48, V(x, y, 2850), V(0, 0, 1), 0, 360, 360)
    add_feature(tanks, "TankBand_%02d" % idx, "Tank restraint band %02d" % idx, ring, "frame",
                "Tank restraint band visual detail.")
    cradle = Part.makeCompound([
        beam(V(x - 700, y, 2290), V(x - 700, y, 2450), 60),
        beam(V(x + 700, y, 2290), V(x + 700, y, 2450), 60),
        beam(V(x - 700, y, 2360), V(x + 700, y, 2360), 55),
    ])
    add_feature(tanks, "TankCradle_%02d" % idx, "Tank cradle %02d" % idx, cradle, "silver",
                "Lightweight upper-deck tank support.")

# Central payload/egress structure.
outer = Part.makeCylinder(1250, 220, V(0, 0, 3060), V(0, 0, 1), 8)
inner = Part.makeCylinder(820, 260, V(0, 0, 3040), V(0, 0, 1), 8)
add_feature(payload, "PayloadOpening", "Central octagonal payload opening", outer.cut(inner), "silver",
            "Central payload aperture inspired by the supplied Griffin references.")
add_feature(payload, "PayloadAdapter", "Payload adapter plate",
            centered_box(2500, 2500, 120, V(0, 0, 3150)), "dark",
            "Study payload interface; final FLIP ICD remains unresolved.")
for idx, (x, y) in enumerate([(-920, -920), (-920, 920), (920, -920), (920, 920)], 1):
    add_feature(payload, "AdapterPost_%02d" % idx, "Payload restraint post %02d" % idx,
                Part.makeCylinder(75, 300, V(x, y, 3150), V(0, 0, 1)), "silver",
                "Four-point payload retention post.")

# Paired visual egress guides with rails and truss-like supports.
for side, sign in (("Port", -1), ("Starboard", 1)):
    hinge_x = sign * 1300
    base_x = hinge_x if sign > 0 else hinge_x - 3600
    ramp = Part.makeBox(3600, 1100, 110, V(base_x, -550, 3040))
    ramp = rotate_about(ramp, V(hinge_x, 0, 3040), V(0, 1, 0), sign * 11)
    add_feature(payload, "EgressRamp_" + side, side + " payload egress guide", ramp, "silver",
                "Reference-informed egress guide; articulation is a visual study pose.")
    for rail_y in (-520, 420):
        rail = Part.makeBox(3600, 80, 240, V(base_x, rail_y, 3100))
        rail = rotate_about(rail, V(hinge_x, 0, 3040), V(0, 1, 0), sign * 11)
        add_feature(payload, "EgressRail_%s_%s" % (side, abs(rail_y)),
                    side + " egress guide rail", rail, "white", "Raised egress guide rail.")
    for t in range(4):
        tx = base_x + 450 + t * 900
        add_feature(payload, "EgressTruss_%s_%02d" % (side, t),
                    side + " egress truss %02d" % t,
                    beam(V(tx, -540, 3080), V(tx, -540, 3400), 38), "frame",
                    "Egress guide support truss.")

# Corner equipment pods with outward sensor booms and heads.
for idx, (sx, sy) in enumerate([(-1, -1), (-1, 1), (1, -1), (1, 1)], 1):
    x, y = sx * 3200, sy * 2550
    add_feature(pods, "CornerPod_%02d" % idx, "Corner avionics pod %02d" % idx,
                centered_box(620, 620, 360, V(x, y, 2460)), "silver",
                "Corner avionics/sensor pod.")
    boom = beam(V(x, y, 2600), V(x + sx * 520, y, 2600), 45)
    add_feature(pods, "SensorBoom_%02d" % idx, "Corner sensor boom %02d" % idx, boom, "frame",
                "Outboard sensor/landing-aid boom.")
    head = Part.makeCylinder(95, 280, V(x + sx * 520, y, 2600), V(0, 0, 1))
    add_feature(pods, "SensorHead_%02d" % idx, "Corner sensor head %02d" % idx, head, "white",
                "Vertical hazard-detection/navigation sensor proxy.")
    dish = Part.makeCone(190, 75, 150, V(x + sx * 520, y, 2880), V(0, 0, 1))
    add_feature(pods, "SensorDish_%02d" % idx, "Corner sensor dish %02d" % idx, dish, "white",
                "Small directional sensor/dish proxy.")

# Splayed legs, diagonal braces, and circular footpads.
for idx, (sx, sy) in enumerate([(-1, -1), (-1, 1), (1, -1), (1, 1)], 1):
    upper = V(sx * 2850, sy * 1850, 930)
    knee = V(sx * 3500, sy * 2350, 420)
    pad_center = V(sx * 4100, sy * 2850, 0)
    add_feature(landing, "MainLeg_%02d" % idx, "Main landing leg %02d" % idx,
                beam(upper, knee, 125), "black", "Splayed primary landing-leg strut.")
    add_feature(landing, "Oleo_%02d" % idx, "Landing-leg oleo %02d" % idx,
                beam(V(sx * 3150, sy * 2050, 720), knee, 78), "silver",
                "Shock/oleo barrel visual proxy.")
    add_feature(landing, "BraceA_%02d" % idx, "Landing leg diagonal brace A %02d" % idx,
                beam(V(sx * 2600, sy * 1650, 1050), V(sx * 3750, sy * 2550, 180), 62), "frame",
                "Triangulated landing-leg brace.")
    add_feature(landing, "BraceB_%02d" % idx, "Landing leg diagonal brace B %02d" % idx,
                beam(V(sx * 3000, sy * 1500, 760), V(sx * 3750, sy * 2550, 180), 62), "frame",
                "Triangulated landing-leg brace.")
    add_feature(landing, "RoundFootpad_%02d" % idx, "Round landing footpad %02d" % idx,
                Part.makeCylinder(360, 95, pad_center, V(0, 0, 1)), "silver",
                "Circular lunar landing footpad.")
    add_feature(landing, "FootpadRim_%02d" % idx, "Footpad rim %02d" % idx,
                Part.makeTorus(300, 28, V(pad_center.x, pad_center.y, 95), V(0, 0, 1), 0, 360, 360), "frame",
                "Footpad perimeter detail.")

# Underside thrusters and a service nozzle.
for idx, (sx, sy) in enumerate([(-1, -1), (-1, 1), (1, -1), (1, 1)], 1):
    x, y = sx * 2350, sy * 1900
    add_feature(propulsion, "ThrusterBell_%02d" % idx, "Underside thruster bell %02d" % idx,
                Part.makeCone(210, 100, 300, V(x, y, 300), V(0, 0, 1)), "black",
                "Powered-descent thruster visual proxy.")
    add_feature(propulsion, "PropLine_%02d" % idx, "Propellant line %02d" % idx,
                beam(V(x, y, 640), V(sx * 1750, sy * 1400, 910), 38), "gold",
                "Propulsion feed-line detail.")
add_feature(propulsion, "CentralNozzle", "Central service nozzle",
            Part.makeCone(260, 125, 320, V(0, 0, 220), V(0, 0, 1)), "black",
            "Central service/nozzle study detail.")

add_note(docs, "Reference mapping",
         "The supplied references show a broad faceted Griffin bus with wraparound dark solar-cell walls, four gold-wrapped spherical upper tanks, corner sensor/propulsion pods, splayed legs with circular feet, and central payload/egress hardware. This document models those visual components explicitly.")
add_note(docs, "Prototype boundary",
         "The model is reference-informed presentation geometry. As-built Griffin dimensions, mass properties, tank layout, propulsion data, leg qualification data, and final FLIP interface remain unresolved.")
add_note(docs, "Twin mapping",
         "The companion LunCoSim wrapper is twins/astrobotic-griffin-1/vehicles/griffin_1.usda. This FreeCAD document is Z-up and millimetres; it is not a replacement for the runtime Twin asset.")

doc.recompute()
project_root = (os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
                if "__file__" in globals() else os.getcwd())
output_path = os.path.join(project_root, "griffin_1_lander.FCStd")
doc.saveAs(output_path)

if Gui is not None:
    Gui.activeDocument().activeView().viewAxonometric()
    Gui.activeDocument().activeView().fitAll()

print("Reference-upgraded Griffin-1 FreeCAD study model saved to: %s" % output_path)
