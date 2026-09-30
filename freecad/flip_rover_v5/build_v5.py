"""Build the FLIP v5 visual-study iteration from the checked-in v4 snapshot.

Run with FreeCAD 1.1 command line:
  FreeCADCmd.exe build_v5.py

This builds visual geometry only. The source wheel's spring/cable counts are
represented for appearance and traceability; the CAD solids are not mass,
collision, compliance, or strength models.
"""
from pathlib import Path
import json
import math
import hashlib
import traceback

import FreeCAD as App
import Part


W = Path(__file__).resolve().parent
INPUT = W / "FLIP_rover_v4_input.FCStd"
OUTPUT = W / "FLIP_rover_v5_geometry.FCStd"
PARAMS = json.loads((W / "parameters_v5.json").read_text(encoding="utf-8"))
V = App.Vector


def require_property(obj, kind, name, group):
    if name not in obj.PropertiesList:
        obj.addProperty(kind, name, group)


def ring(outer, inner, width, x):
    outer_s = Part.makeCylinder(outer, width, V(x, 0, 0), V(1, 0, 0))
    inner_s = Part.makeCylinder(inner, width, V(x, 0, 0), V(1, 0, 0))
    return outer_s.cut(inner_s)


def tapered_spoke(x0, angle_deg, radius_inner, radius_outer, width_inner, width_outer, depth):
    a = math.radians(angle_deg)
    radial = V(0, math.sin(a), math.cos(a))
    tangent = V(0, math.cos(a), -math.sin(a))

    def point(radius, width_sign, tangential_width):
        return V(x0, 0, 0) + radial * radius + tangent * (width_sign * tangential_width / 2.0)

    points = [
        point(radius_inner, -1, width_inner),
        point(radius_inner, 1, width_inner),
        point(radius_outer, 1, width_outer),
        point(radius_outer, -1, width_outer),
    ]
    wire = Part.makePolygon(points + [points[0]])
    return Part.Face(wire).extrude(V(depth, 0, 0))


def make_spider(p):
    half = p["rim_axial_thickness_mm"] / 2.0
    offset = p["inner_rim_axial_center_mm"]
    body = Part.makeCylinder(
        p["hub_radius_mm"],
        p["wheel_width_mm"],
        V(-p["wheel_width_mm"] / 2.0, 0, 0),
        V(1, 0, 0),
    )
    details = []
    for x0 in [-offset - half, offset - half]:
        details.append(Part.makeCylinder(280.0, 20.0, V(x0, 0, 0), V(1, 0, 0)).cut(
            Part.makeCylinder(265.0, 20.0, V(x0, 0, 0), V(1, 0, 0))))
        details.append(ring(p["inner_rim_radius_mm"], p["inner_rim_radius_mm"] - 10.0,
                            p["rim_axial_thickness_mm"], x0))
        for i in range(p["spoke_count_per_face"]):
            details.append(tapered_spoke(
                x0, i * 360.0 / p["spoke_count_per_face"],
                80.0, p["inner_rim_radius_mm"] - 1.0,
                p["spoke_width_inner_mm"], p["spoke_width_outer_mm"],
                p["rim_axial_thickness_mm"],
            ))
    body = body.multiFuse(details)
    if not body.isValid():
        raise RuntimeError("revised tapered-spoke wheel spider is not a valid B-rep")
    return body.removeSplitter()


def make_spring_coil(length, pitch, coil_radius, wire_radius):
    # A circular sweep gives a real, editable visual spring solid. Its sampled
    # dimensions are appearance choices, not the proprietary spring ICD.
    helix_edge = Part.makeHelix(pitch, length, coil_radius).Edges[0]
    spine = Part.Wire([helix_edge])
    profile = Part.Wire([Part.makeCircle(wire_radius, V(coil_radius, 0, 0), V(0, 1, 0))])
    coil = spine.makePipeShell([profile], True, True)
    if not coil.isValid() or len(coil.Solids) != 1:
        raise RuntimeError("spring-sweep generation failed")
    return coil


def make_springs(p):
    unit = make_spring_coil(
        p["spring_visual_length_mm"], p["spring_visual_pitch_mm"],
        p["spring_visual_coil_radius_mm"], p["spring_visual_wire_radius_mm"],
    )
    springs = []
    count_per_face = p["springs_per_face"]
    for side in [-1, 1]:
        for i in range(count_per_face):
            angle = (i + 0.5) * 360.0 / count_per_face
            a = math.radians(angle)
            radial = V(0, math.sin(a), math.cos(a))
            tangent = V(0, math.cos(a), -math.sin(a))
            axle = V(1, 0, 0)
            center = V(side * p["inner_rim_axial_center_mm"], 0, 0) + radial * p["spring_visual_ring_radius_mm"]
            placement = App.Placement(
                center - tangent * (p["spring_visual_length_mm"] / 2.0),
                App.Rotation(radial, axle, tangent, "ZXY"),
            )
            spring = unit.copy()
            spring.Placement = placement
            springs.append(spring)
    return Part.makeCompound(springs)


def add_v5_ledger(doc):
    old = doc.getObject("FLIPV5SourceLedger")
    if old:
        doc.removeObject(old.Name)
    sheet = doc.addObject("Spreadsheet::Sheet", "FLIPV5SourceLedger")
    sheet.Label = "FLIP v5 | public facts / study choices / unresolved values"
    rows = [
        ("Parameter", "Value", "Evidence status"),
        ("Wheel count", "4", "Public visual and LPSC 2026 configuration"),
        ("Wheel diameter", "930 mm", "Venturi wheel family; Astrolab says FLIP uses full-size FLEX wheels"),
        ("Wheel axial width", "280 mm", "v5 packaging-study choice; not published"),
        ("Wheel construction", "192 sprung cables; 96 springs", "Venturi wheel-family source; exact FLIP assembly geometry unpublished"),
        ("Wheel centers (FL, FR, RL, RR)", "(-1000,465,850), (1000,465,850), (-1000,465,-850), (1000,465,-850) mm", "Measured v5 global datums; X lateral, Y up, +Z forward; study layout"),
        ("Chassis assembly bounds", "1460 x 400 x 2100 mm", "Measured v5 global X/Y/Z bounds; packaging study, excludes wheels and array"),
        ("Overall bounds, stowed/deployed", "2332 x 1107 x 2630 / 2332 x 2634 x 2630 mm", "Measured v5 global X/Y/Z bounds; study poses only"),
        ("BatteryPackA / BatteryPackB envelopes", "305 x 220 x 884 mm each", "two separately named v5 envelope geometries; not supplier dimensions or physical mass"),
        ("Solar backplate", "1800 x 1380 mm", "v5 study choice; not a released array dimension"),
        ("Recessed rim-face inset", "65 mm each side", "Photo-informed concentric axial setback; not dimensioned by supplier"),
        ("Vehicle mass", "450 kg", "Venturi FLIP product listing; mass-properties ICD not published"),
        ("Launch mass envelope", "480 kg", "LPSC 2026 paper describes Griffin-space/launch constraint; not separate rover mass"),
        ("Payload capacity", "30 kg maximum", "Astrolab 2025 announcement and Venturi FLIP listing"),
        ("Chassis envelope", "TBD", "No current FLIP dimensioned drawing found"),
        ("Wheelbase / track", "1,700 / 2,000 mm", "v5 packaging-study choices; not published"),
        ("Solar array", "collapsible; one articulated panel in this CAD", "Collapsible is public; panel/joint count and kinematics are not"),
        ("Solar pose values", "0 deg stowed; 82 deg deployed; 0..90 deg study clamp", "CAD study control; no published flight hinge limits"),
        ("Battery packs", "2, behind solar panels", "Venturi 2025 media kit; pack dimensions/electrical ratings TBD"),
        ("Cameras", "2 mast-mounted, opposite directions", "Canadensys supplier post; exact camera geometry TBD"),
        ("NASA payloads", "METAL, LRA, LDES, Lunar LiDAR", "Astrolab announcement 2026; mount geometry/ICDs TBD"),
        ("Mass/inertia in CAD", "not assigned", "Visual solids are not material or mass properties"),
    ]
    for row_index, row in enumerate(rows, 1):
        for col_index, value in enumerate(row, 1):
            sheet.set(chr(64 + col_index) + str(row_index), value)
    sheet.setColumnWidth("A", 220)
    sheet.setColumnWidth("B", 300)
    sheet.setColumnWidth("C", 520)
    return sheet


try:
    if not INPUT.exists():
        raise FileNotFoundError(INPUT)
    doc = App.openDocument(str(INPUT))
    doc.recompute()

    metal = (0.72, 0.75, 0.77)
    tire_white = (0.82, 0.83, 0.80)
    hub_dark = (0.08, 0.095, 0.11)
    spider = make_spider(PARAMS)
    spring_details = make_springs(PARAMS)
    for tag in ["LF", "LR", "RF", "RR"]:
        wheel = doc.getObject("Wheel" + tag)
        tire = doc.getObject("Tire" + tag)
        spider_obj = doc.getObject("Spider" + tag)
        hub = doc.getObject("HubCap" + tag)
        if not all([wheel, tire, spider_obj, hub]):
            raise RuntimeError("v4 input lacks expected wheel subassembly " + tag)

        tire.StudyColor = tire_white
        tire.DesignBasis = "930 mm family diameter; white continuous band from selected public render; 280 mm width is a study choice"
        spider_obj.Shape = spider.copy()
        spider_obj.StudyColor = metal
        spider_obj.DesignBasis = "12 tapered spokes per face; render-informed study geometry"
        hub.StudyColor = hub_dark

        name = "SpringDetail" + tag
        if doc.getObject(name):
            doc.removeObject(name)
        spring_obj = doc.addObject("Part::Feature", name)
        spring_obj.Label = "96 spring details | " + {"LF": "front-left", "LR": "rear-left", "RF": "front-right", "RR": "rear-right"}[tag]
        spring_obj.Shape = spring_details.copy()
        wheel.addObject(spring_obj)
        spring_obj.addProperty("App::PropertyColor", "StudyColor", "Presentation")
        spring_obj.StudyColor = metal
        spring_obj.addProperty("App::PropertyString", "AttachmentTo", "Assembly")
        spring_obj.AttachmentTo = "Spider" + tag
        spring_obj.addProperty("App::PropertyString", "GeometryRole", "Design")
        spring_obj.GeometryRole = "VISUAL-ONLY spring detail; no physical force, mass, or collision authority"
        spring_obj.addProperty("App::PropertyInteger", "PublicSpringCount", "Reference")
        spring_obj.PublicSpringCount = PARAMS["springs_per_wheel"]
        spring_obj.addProperty("App::PropertyString", "SourceBasis", "Reference")
        spring_obj.SourceBasis = "Venturi wheel-family source; 96 springs per wheel; v5 coil size/layout are study geometry"

    # Preserve the existing stable object names while making the tree labels
    # explicit that these are two separate packaging envelopes, not detailed
    # flight battery CAD.
    doc.getObject("BatteryEnclosure").Label = "BatteryPackA | envelope (study)"
    doc.getObject("BatteryPackB").Label = "BatteryPackB | envelope (study)"

    mobility = doc.getObject("Mobility")
    require_property(mobility, "App::PropertyString", "SteeringArchitecture", "Reference configuration")
    mobility.SteeringArchitecture = "Four-wheel skid steer; individual wheel steering angles are not authored"
    require_property(mobility, "App::PropertyString", "ArchitectureSource", "Reference configuration")
    mobility.ArchitectureSource = "LPSC 2026 abstract #1874: https://www.hou.usra.edu/meetings/lpsc2026/pdf/1874.pdf"

    root = doc.getObject("FLIP")
    props = [
        ("App::PropertyFloat", "PublicMassClaim_kg", 450.0),
        ("App::PropertyFloat", "LaunchMassConstraint_kg", 480.0),
        ("App::PropertyFloat", "PublicPayloadCapacity_kg", 30.0),
        ("App::PropertyFloat", "PublishedWheelDiameter_mm", 930.0),
        ("App::PropertyFloat", "WheelWidthStudy_mm", PARAMS["wheel_width_mm"]),
        ("App::PropertyFloat", "PublishedMaxSpeed_kmh", 20.0),
    ]
    for kind, name, value in props:
        require_property(root, kind, name, "Public facts / study parameters")
        setattr(root, name, value)
    require_property(root, "App::PropertyString", "MassInterpretation", "Public facts / study parameters")
    root.MassInterpretation = "450 kg is a published FLIP vehicle-level claim; mass distribution, inertia, payload inclusion and CAD mass are not established. 480 kg is a separate launch/available-space constraint."
    require_property(root, "App::PropertyString", "SteeringArchitecture", "Public facts / study parameters")
    root.SteeringArchitecture = "4-wheel skid steer (LPSC 2026); replaces the older unsupported all-wheel-steer study mapping"
    require_property(root, "App::PropertyString", "PublicConfigurationSource", "Public facts / study parameters")
    root.PublicConfigurationSource = "LPSC 2026 #1874; Astrolab FLIP page; Venturi Rovers and wheel pages; see LUNCO_SIM_RECREATION.md"
    require_property(root, "App::PropertyString", "CADStatus", "Public facts / study parameters")
    root.CADStatus = "Reference-based visual study proxy; not as-built, mass-calibrated, or flight-qualified"
    require_property(root, "App::PropertyString", "Frame", "Public facts / study parameters")
    root.Frame = "X lateral, Y up, Z longitudinal, forward +Z; native FreeCAD lengths in mm; LunCoSim USD in m"

    motion = doc.getObject("Motion")
    motion.SolarAngle = PARAMS["panel_deployed_deg"]
    panel = doc.getObject("SolarArrayPanelBody")
    require_property(panel, "App::PropertyString", "MechanismEvidence", "Reference configuration")
    panel.MechanismEvidence = "Public source confirms collapsible array only; v5 revolute axis and 0..90 deg study clamp are not flight mechanism data"
    require_property(panel, "App::PropertyString", "VisualDefault", "Reference configuration")
    panel.VisualDefault = "DEPLOYED reference pose 82 deg; STOWED pose 0 deg remains available"

    add_v5_ledger(doc)
    doc.Label = "FLIP v5 | 2026 public-source reconciliation | deployed visual-study pose"
    doc.recompute()

    leaves = [o for o in doc.Objects if "StudyColor" in o.PropertiesList]
    spring_counts = {"SpringDetail" + t: len(doc.getObject("SpringDetail" + t).Shape.Solids) for t in ["LF", "LR", "RF", "RR"]}
    cable_counts = {"CableWeb" + t: len(doc.getObject("CableWeb" + t).Shape.Solids) for t in ["LF", "LR", "RF", "RR"]}
    invalid = [o.Name for o in leaves if o.Shape.isNull() or not o.Shape.isValid()]
    report = {
        "source": INPUT.name,
        "source_sha256": hashlib.sha256(INPUT.read_bytes()).hexdigest(),
        "freecad_version": list(App.Version()),
        "feature_count": len(leaves),
        "invalid_features": invalid,
        "wheel_names": ["FL", "RL", "FR", "RR"],
        "wheel_radius_mm": PARAMS["wheel_diameter_mm"] / 2.0,
        "wheel_width_mm_status": "study choice",
        "published_cables_per_wheel": PARAMS["cables_per_wheel"],
        "actual_cable_solids_per_wheel": cable_counts,
        "published_springs_per_wheel": PARAMS["springs_per_wheel"],
        "actual_spring_solids_per_wheel": spring_counts,
        "spring_visual_only": True,
        "solar_angle_saved_deg": float(motion.SolarAngle),
        "frame": "X lateral, Y up, Z longitudinal; forward +Z; mm",
        "mass_properties_assigned": False,
    }
    if invalid or any(v != PARAMS["cables_per_wheel"] for v in cable_counts.values()) or any(v != PARAMS["springs_per_wheel"] for v in spring_counts.values()):
        raise RuntimeError("v5 feature validation did not meet the source-count contract: " + json.dumps(report))
    doc.saveAs(str(OUTPUT))
    (W / "build_v5_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    App.closeDocument(doc.Name)
    print("FLIP v5 geometry built: " + str(OUTPUT), flush=True)
except Exception:
    (W / "build_v5_error.txt").write_text(traceback.format_exc(), encoding="utf-8")
    raise
