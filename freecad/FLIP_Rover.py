"""Build an articulated Astrolab FLIP rover study model in FreeCAD.

The solar array is authored as a separate rigid-body group driven by a named
revolute joint. The saved default is CLOSED/STOWED on the payload deck. In the
FreeCAD Python console, use deploy_solar_panel() or stow_solar_panel() to move
it between the closed pose and the upright pose shown in the supplied visual
reference.

Run from FreeCAD's Python console with:
    p = r"C:/path/to/FLIP_Rover.py"
    scope = globals(); scope["__file__"] = p; exec(compile(open(p).read(), p, "exec"), scope)
"""

import math
import os

import FreeCAD as App
import Part

try:
    import FreeCADGui as Gui
except ImportError:
    Gui = None


DOC_NAME = "FLIP_Rover"
COLORS = {
    "body": (0.84, 0.85, 0.84),
    "structure": (0.52, 0.55, 0.57),
    "dark": (0.10, 0.11, 0.13),
    "solar": (0.035, 0.08, 0.19),
    "blue": (0.08, 0.20, 0.40),
    "black": (0.025, 0.03, 0.035),
    "gold": (0.73, 0.52, 0.15),
}


def V(x, y, z):
    return App.Vector(float(x), float(y), float(z))


def set_color(obj, color, transparency=0):
    obj.ViewObject.ShapeColor = COLORS[color] if isinstance(color, str) else color
    obj.ViewObject.LineColor = (0.12, 0.13, 0.15)
    obj.ViewObject.Transparency = transparency
    try:
        obj.ViewObject.DisplayMode = "Flat Lines"
    except Exception:
        pass


def string_property(obj, name, group, value):
    obj.addProperty("App::PropertyString", name, group)
    setattr(obj, name, value)


def length_property(obj, name, group, value):
    obj.addProperty("App::PropertyLength", name, group)
    setattr(obj, name, value)


def feature(doc, parent, name, label, shape, color, description=""):
    obj = doc.addObject("Part::Feature", name)
    obj.Label = label
    obj.Shape = shape
    parent.addObject(obj)
    set_color(obj, color)
    string_property(obj, "ComponentType", "Design", "Study geometry")
    string_property(obj, "ModelStatus", "Design", "Study proxy; not flight-qualified")
    if description:
        string_property(obj, "Description", "Design", description)
    return obj


def box(x_size, y_size, z_size, x, y, z):
    return Part.makeBox(x_size, y_size, z_size, V(x, y, z))


def beam(start, end, radius):
    delta = end.sub(start)
    return Part.makeCylinder(radius, delta.Length, start, delta)


def wheel_shape(center, radius=450.0, width=280.0):
    axis = V(1, 0, 0)
    tire = Part.makeTorus(radius - 72.0, 72.0, center, axis)
    hub = Part.makeCylinder(220.0, width, center - V(width / 2.0, 0, 0), axis)
    cap = Part.makeCylinder(145.0, width + 18.0, center - V(width / 2.0 + 9.0, 0, 0), axis)
    grousers = []
    for index in range(16):
        lug = box(width + 26.0, 62.0, 115.0, center.x - width / 2.0 - 13.0, center.y + radius - 52.0, center.z - 57.5)
        lug.rotate(center, axis, index * 360.0 / 16.0)
        grousers.append(lug)
    return Part.makeCompound([tire, hub, cap] + grousers)


def trapezoid_cell(x, z, width, height):
    points = [
        V(x - width * 0.48, 58.0, z),
        V(x + width * 0.48, 58.0, z),
        V(x + width * 0.37, 58.0, z - height),
        V(x - width * 0.37, 58.0, z - height),
        V(x - width * 0.48, 58.0, z),
    ]
    return Part.Face(Part.makePolygon(points)).extrude(V(0, 8.0, 0))


class SolarRevoluteJoint:
    """FreeCAD Python feature that drives the panel body placement."""

    def __init__(self):
        pass

    def execute(self, obj):
        child = getattr(obj, "ChildBody", None)
        if child is None:
            return
        angle = max(float(obj.MinAngle), min(float(obj.MaxAngle), float(obj.Angle)))
        placement = App.Placement(obj.HingePosition, App.Rotation(obj.Axis, angle))
        child.Placement = placement

    def onChanged(self, obj, property_name):
        if property_name == "Angle" and hasattr(obj, "MinAngle") and hasattr(obj, "MaxAngle"):
            bounded = max(float(obj.MinAngle), min(float(obj.MaxAngle), float(obj.Angle)))
            if abs(float(obj.Angle) - bounded) > 1e-7:
                obj.Angle = bounded

    def __getstate__(self):
        return None

    def __setstate__(self, state):
        return None


def add_joint(doc, parent, parent_body, child_body, hinge_position):
    joint = doc.addObject("App::FeaturePython", "SolarArrayJoint")
    joint.Label = "SolarArrayJoint — revolute hinge (CLOSED default)"
    parent.addObject(joint)
    joint.Proxy = SolarRevoluteJoint()
    joint.addProperty("App::PropertyString", "JointType", "Joint")
    joint.JointType = "Revolute"
    joint.addProperty("App::PropertyString", "JointStatus", "Joint")
    joint.JointStatus = "Explicit articulated study joint"
    joint.addProperty("App::PropertyLink", "ParentBody", "Joint")
    joint.ParentBody = parent_body
    joint.addProperty("App::PropertyLink", "ChildBody", "Joint")
    joint.ChildBody = child_body
    joint.addProperty("App::PropertyVector", "Axis", "Joint")
    joint.Axis = V(1, 0, 0)
    joint.addProperty("App::PropertyVector", "HingePosition", "Joint")
    joint.HingePosition = hinge_position
    joint.addProperty("App::PropertyAngle", "Angle", "Joint")
    joint.Angle = "0 deg"
    joint.addProperty("App::PropertyAngle", "MinAngle", "Joint")
    joint.MinAngle = "0 deg"
    joint.addProperty("App::PropertyAngle", "MaxAngle", "Joint")
    joint.MaxAngle = "90 deg"
    joint.addProperty("App::PropertyAngle", "StowedAngle", "Joint")
    joint.StowedAngle = "0 deg"
    joint.addProperty("App::PropertyAngle", "DeployedAngle", "Joint")
    joint.DeployedAngle = "82 deg"
    joint.addProperty("App::PropertyEnumeration", "State", "Joint")
    joint.State = ["CLOSED / STOWED", "OPEN / DEPLOYED", "CUSTOM"]
    joint.State = "CLOSED / STOWED"
    joint.addProperty("App::PropertyBool", "LockAtPose", "Joint")
    joint.LockAtPose = False
    joint.addProperty("App::PropertyString", "MotionContract", "Joint")
    joint.MotionContract = "Separate panel rigid body; bounded rotation about X hinge axis"
    joint.addProperty("App::PropertyString", "Acceptance", "Joint")
    joint.Acceptance = "0 deg closed; 82 deg open; panel clears deck, mast, and wheels"
    return joint


def build_flip_rover():
    if DOC_NAME in App.listDocuments():
        App.closeDocument(DOC_NAME)
    doc = App.newDocument(DOC_NAME, "Astrolab FLIP Rover - articulated study proxy")

    # Study parameters remain visible in the document tree.
    params = doc.addObject("Spreadsheet::Sheet", "Parameters")
    params.Label = "FLIP Rover Parameters (study proxy)"
    table = [
        ("Parameter", "Value", "Status"),
        ("Chassis envelope", "2400 x 1800 x 700 mm", "Project study assumption"),
        ("Wheelbase / track", "2100 / 1900 mm", "Packaging proxy"),
        ("Wheel radius / width", "450 / 280 mm", "Study proxy"),
        ("Vehicle mass", "450 kg", "Engineering midpoint"),
        ("Payload capacity", "30 kg", "Public Astrolab description"),
        ("Battery", "28 V / 83.33 Ah", "Simulator electrical proxy"),
        ("Solar array", "3.0 m^2", "Study assumption"),
        ("Solar joint", "0 to 90 deg; 82 deg deployed", "Articulation contract"),
    ]
    for row_index, row in enumerate(table, start=1):
        for col_index, value in enumerate(row, start=1):
            params.set(chr(64 + col_index) + str(row_index), value)
    params.setColumnWidth("A", 190)
    params.setColumnWidth("B", 190)
    params.setColumnWidth("C", 230)

    assembly = doc.addObject("App::Part", "FLIP_Rover_Assembly")
    assembly.Label = "FLIP Rover — reference-inspired articulated study proxy"
    string_property(assembly, "Vehicle", "Documentation", "Astrolab FLIP / FLEX Lunar Innovation Platform")
    string_property(assembly, "CoordinateConvention", "Documentation", "X lateral / track, Y up, Z longitudinal")
    string_property(assembly, "ReferenceBoundary", "Documentation", "User-supplied visual reference is presentation evidence only; no dimensions inferred from it")
    string_property(assembly, "Provenance", "Documentation", "https://www.astrolab.space/flip-rover/")
    string_property(assembly, "ModelBoundary", "Documentation", "Packaging and articulation study proxy; replace with as-built CAD and test data")
    assembly.addObject(params)

    rover_body = doc.addObject("App::Part", "RoverBody")
    rover_body.Label = "RoverBody — separate chassis rigid-body envelope"
    rover_body.addProperty("App::PropertyBool", "RigidBody", "Physics study")
    rover_body.RigidBody = True
    string_property(rover_body, "BodyRole", "Physics study", "Parent rigid body for articulated solar panel")
    assembly.addObject(rover_body)

    chassis_group = doc.addObject("App::Part", "Chassis")
    chassis_group.Label = "01 — Chassis and protective structure"
    rover_body.addObject(chassis_group)
    mobility_group = doc.addObject("App::Part", "Mobility")
    mobility_group.Label = "02 — Four-wheel all-wheel-steer study proxy"
    rover_body.addObject(mobility_group)
    payload_group = doc.addObject("App::Part", "Payload")
    payload_group.Label = "03 — Payload deck, battery, and sensors"
    rover_body.addObject(payload_group)
    power_group = doc.addObject("App::Part", "Power")
    power_group.Label = "04 — Articulated solar array and power controller"
    rover_body.addObject(power_group)
    notes_group = doc.addObject("App::DocumentObjectGroup", "EngineeringNotes")
    notes_group.Label = "05 — Engineering notes and provenance"
    assembly.addObject(notes_group)

    chassis_w, chassis_h, chassis_l, chassis_y = 1800.0, 700.0, 2400.0, 300.0
    body_shape = box(chassis_w, chassis_h, chassis_l, -chassis_w / 2.0, chassis_y, -chassis_l / 2.0)
    body_shape = body_shape.fuse(box(chassis_w + 80.0, 95.0, 115.0, -chassis_w / 2.0 - 40.0, chassis_y + 20.0, -chassis_l / 2.0 - 35.0))
    body_shape = body_shape.fuse(box(chassis_w + 80.0, 95.0, 115.0, -chassis_w / 2.0 - 40.0, chassis_y + 20.0, chassis_l / 2.0 - 80.0))
    chassis_obj = feature(doc, chassis_group, "MainChassis", "Main chassis shell", body_shape, "body", "Low broad body inspired by the supplied FLIP visual reference.")
    length_property(chassis_obj, "Length", "Dimensions", chassis_l)
    length_property(chassis_obj, "Width", "Dimensions", chassis_w)
    length_property(chassis_obj, "Height", "Dimensions", chassis_h)

    rail_shapes = [box(80.0, 130.0, chassis_l - 180.0, x, chassis_y + 70.0, -chassis_l / 2.0 + 90.0) for x in (-chassis_w / 2.0 - 35.0, chassis_w / 2.0 - 45.0)]
    feature(doc, chassis_group, "SideProtectionRails", "Side protection rails", Part.makeCompound(rail_shapes), "dark")
    feature(doc, chassis_group, "BellySkid", "Central belly skid", box(1320.0, 65.0, 1700.0, -660.0, chassis_y - 65.0, -850.0), "structure")

    for corner, x_sign, z_sign in (("FL", -1, -1), ("FR", 1, -1), ("RL", -1, 1), ("RR", 1, 1)):
        center = V(x_sign * 950.0, 450.0, z_sign * 1050.0)
        wheel_obj = feature(doc, mobility_group, "Wheel_" + corner, "Wheel " + corner + " — airless tire proxy", wheel_shape(center), "dark", "Four-wheel visual proxy; wheel count and tire data remain unconfirmed.")
        length_property(wheel_obj, "Radius", "Dimensions", 450.0)
        length_property(wheel_obj, "Width", "Dimensions", 280.0)
        string_property(wheel_obj, "Steering", "Mobility", "All-wheel-steer study input")
        arm_x = -chassis_w / 2.0 + 735.0 if x_sign < 0 else chassis_w / 2.0 - 815.0
        arm = box(80.0, 125.0, 560.0, arm_x, 370.0, center.z - 280.0)
        knuckle = Part.makeCylinder(95.0, 95.0, V(center.x - 47.5, center.y, center.z), V(1, 0, 0))
        carrier = feature(doc, mobility_group, "Suspension_" + corner, "Suspension carrier " + corner, Part.makeCompound([arm, knuckle]), "structure")
        string_property(carrier, "Station", "Mobility", corner)

    deck_l, deck_w, deck_t = 1900.0, 1400.0, 120.0
    deck_y = chassis_y + chassis_h
    deck_obj = feature(doc, payload_group, "PayloadDeck", "Payload deck", box(deck_w, deck_t, deck_l, -deck_w / 2.0, deck_y, -deck_l / 2.0), "structure")
    length_property(deck_obj, "Length", "Dimensions", deck_l)
    length_property(deck_obj, "Width", "Dimensions", deck_w)
    length_property(deck_obj, "Thickness", "Dimensions", deck_t)
    feature(doc, payload_group, "PayloadRails", "Payload interface rails", Part.makeCompound([box(70.0, 95.0, deck_l, -deck_w / 2.0 + 35.0, deck_y + deck_t, -deck_l / 2.0), box(70.0, 95.0, deck_l, deck_w / 2.0 - 105.0, deck_y + deck_t, -deck_l / 2.0)]), "dark")
    battery = box(520.0, 320.0, 620.0, 520.0, 390.0, -320.0).fuse(box(380.0, 100.0, 70.0, 590.0, 710.0, -250.0))
    battery_obj = feature(doc, payload_group, "BatteryBox", "Battery / avionics enclosure", battery, "dark", "Battery remains body-mounted; only the solar panel articulates.")
    string_property(battery_obj, "ElectricalStudyValue", "Engineering", "28 V / 83.33 Ah proxy")

    # Fixed rover sensor mast. The solar-panel sensor bar is a separate moving part below.
    mast_base = Part.makeCylinder(105.0, 55.0, V(0.0, deck_y + deck_t, 820.0), V(0, 1, 0))
    mast_post = Part.makeCylinder(60.0, 550.0, V(0.0, deck_y + deck_t + 45.0, 820.0), V(0, 1, 0))
    mast_bar = box(840.0, 120.0, 160.0, -420.0, deck_y + deck_t + 595.0, 740.0)
    mast_obj = feature(doc, payload_group, "SensorMast", "Fixed sensor mast and crossbar", Part.makeCompound([mast_base, mast_post, mast_bar]), "structure")
    string_property(mast_obj, "Function", "Payload", "Fixed navigation/sensor reference")

    cameras = []
    for x in (-275.0, 275.0):
        camera = Part.makeCylinder(72.0, 120.0, V(x, deck_y + deck_t + 620.0, 655.0), V(0, 0, -1))
        camera = camera.fuse(Part.makeSphere(68.0, V(x, deck_y + deck_t + 620.0, 535.0)))
        cameras.append(camera)
    feature(doc, payload_group, "NavigationCameras", "Navigation camera pair", Part.makeCompound(cameras), "black")

    # Articulated solar panel. The local origin is the hinge center. At 0 deg the
    # panel lies closed over the deck; +82 deg rotates its local -Z edge upward.
    solar_group = doc.addObject("App::Part", "SolarArrayPanelBody")
    solar_group.Label = "SolarArrayPanelBody — separate rigid body"
    solar_group.addProperty("App::PropertyBool", "RigidBody", "Physics study")
    solar_group.RigidBody = True
    string_property(solar_group, "BodyRole", "Physics study", "Child rigid body driven by SolarArrayJoint")
    power_group.addObject(solar_group)

    panel_w, panel_h, panel_t = 2340.0, 1320.0, 50.0
    base_shape = box(panel_w, panel_t, panel_h, -panel_w / 2.0, 0.0, -panel_h)
    base = feature(doc, solar_group, "SolarPanelBase", "Solar panel backplate", base_shape, "body")
    frame_shapes = [
        box(panel_w + 80.0, 62.0, 46.0, -panel_w / 2.0 - 40.0, 0.0, -panel_h - 22.0),
        box(panel_w + 80.0, 62.0, 46.0, -panel_w / 2.0 - 40.0, 0.0, -46.0),
        box(46.0, 62.0, panel_h - 60.0, -panel_w / 2.0 - 22.0, 0.0, -panel_h + 30.0),
        box(46.0, 62.0, panel_h - 60.0, panel_w / 2.0 - 24.0, 0.0, -panel_h + 30.0),
    ]
    frame = feature(doc, solar_group, "SolarPanelFrame", "White perimeter frame", Part.makeCompound(frame_shapes), "body")

    cells = []
    columns, rows = 8, 7
    gap_x, gap_z = 28.0, 26.0
    cell_w = (panel_w - gap_x * (columns + 1)) / columns
    cell_h = (panel_h - gap_z * (rows + 1)) / rows
    for row in range(rows):
        for column in range(columns):
            x = -panel_w / 2.0 + gap_x + cell_w / 2.0 + column * (cell_w + gap_x)
            z = -panel_h + gap_z + cell_h + row * (cell_h + gap_z)
            cells.append(trapezoid_cell(x, z, cell_w, cell_h))
    cell_obj = feature(doc, solar_group, "SolarCellSurface", "Dark photovoltaic cell surface", Part.makeCompound(cells), "solar")
    string_property(cell_obj, "Pattern", "Power", "8 x 7 trapezoid cell study pattern")

    # The visual reference shows two small sensor/antenna elements above the panel.
    panel_sensor_shapes = [
        box(840.0, 70.0, 70.0, -420.0, 60.0, -panel_h - 35.0),
        Part.makeCylinder(32.0, 180.0, V(-260.0, 60.0, -panel_h - 35.0), V(0, 1, 0)),
        Part.makeCylinder(32.0, 180.0, V(260.0, 60.0, -panel_h - 35.0), V(0, 1, 0)),
    ]
    panel_sensors = feature(doc, solar_group, "SolarPanelSensors", "Moving panel sensor bar and antenna pair", Part.makeCompound(panel_sensor_shapes), "black")
    string_property(panel_sensors, "Motion", "Payload", "Moves with SolarArrayPanelBody")

    # Hinge datum is on the rear edge of the deck. The x-axis runs across the
    # rover, so a positive angle lifts the panel into the upright visual pose.
    hinge_position = V(0.0, deck_y + deck_t + 35.0, 560.0)
    hinge_barrels = Part.makeCompound([
        Part.makeCylinder(48.0, 150.0, V(-760.0, hinge_position.y, hinge_position.z), V(1, 0, 0)),
        Part.makeCylinder(48.0, 150.0, V(610.0, hinge_position.y, hinge_position.z), V(1, 0, 0)),
    ])
    hinge_visual = feature(doc, power_group, "SolarHingeHardware", "Solar hinge barrels and datum", hinge_barrels, "gold")
    string_property(hinge_visual, "Axis", "Joint", "X axis / lateral hinge line")
    length_property(hinge_visual, "HingeHeight", "Joint", hinge_position.y)

    joint = add_joint(doc, power_group, chassis_obj, solar_group, hinge_position)
    # Ensure the saved document starts CLOSED/STOWED, as requested.
    joint.Angle = joint.StowedAngle
    joint.State = "CLOSED / STOWED"

    metadata = doc.addObject("App::FeaturePython", "StudyMetadata")
    metadata.Label = "FLIP study boundary — read before reuse"
    string_property(metadata, "Vehicle", "Provenance", "Astrolab FLIP / FLEX Lunar Innovation Platform")
    string_property(metadata, "Source", "Provenance", "https://www.astrolab.space/flip-rover/")
    string_property(metadata, "VisualReference", "Provenance", "User-supplied FLIP image in chat; visual-only evidence")
    string_property(metadata, "Status", "Provenance", "Study proxy; public material does not provide as-built FLIP CAD or full vehicle ICD")
    string_property(metadata, "Articulation", "Provenance", "SolarArrayPanelBody is a separate child body driven by SolarArrayJoint")
    notes_group.addObject(metadata)

    doc.recompute()
    if Gui is not None:
        Gui.activeDocument().activeView().viewAxonometric()
        Gui.activeDocument().activeView().fitAll()

    script_dir = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else os.getcwd()
    output_path = os.path.join(script_dir, "FLIP_Rover.FCStd")
    doc.saveAs(output_path)
    print("FLIP rover model saved to: " + output_path)
    print("Default state: CLOSED / STOWED at SolarArrayJoint.Angle = 0 deg")
    print("Use deploy_solar_panel() for 82 deg upright pose or stow_solar_panel() for 0 deg")
    return doc


def set_solar_panel_angle(angle):
    doc = App.getDocument(DOC_NAME)
    if doc is None:
        raise RuntimeError("Open FLIP_Rover.FCStd or run FLIP_Rover_hinged.py first")
    joint = doc.getObject("SolarArrayJoint")
    bounded = max(float(joint.MinAngle), min(float(joint.MaxAngle), float(angle)))
    joint.Angle = bounded
    if abs(bounded - float(joint.StowedAngle)) < 1e-7:
        joint.State = "CLOSED / STOWED"
    elif abs(bounded - float(joint.DeployedAngle)) < 1e-7:
        joint.State = "OPEN / DEPLOYED"
    else:
        joint.State = "CUSTOM"
    doc.recompute()
    return joint.Angle


def deploy_solar_panel():
    """Move the solar panel to the upright reference pose and return the angle."""
    return set_solar_panel_angle(82.0)


def stow_solar_panel():
    """Close the solar panel flat on the deck and return the angle."""
    return set_solar_panel_angle(0.0)


build_flip_rover()
