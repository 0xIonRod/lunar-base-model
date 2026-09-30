"""Bounded, read-only integrity audit for the high-detail v5 FCStd.

This deliberately avoids all-pairs OpenCascade common/intersection calls over
hundreds of visual cable and spring solids. Such checks are computationally
unbounded here and would incorrectly present render details as collision
geometry. Clearance and physics remain explicitly not evaluated by this audit.
"""
import FreeCAD as App
from pathlib import Path
import json
import datetime
import hashlib
import traceback

W = Path(__file__).resolve().parent
MODEL = W / "FLIP_rover_v5.FCStd"
OUT = W / "audit_v5.json"
R = {
    "started_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "audit_scope": "native document integrity, published wheel-family dimensions/counts, saved pose",
    "clearance_status": "NOT EVALUATED; this visual model has no authoritative flight collision geometry",
    "mass_properties_status": "NOT ASSIGNED; do not infer from visual B-rep solids",
}


def world(obj):
    shape = obj.Shape.copy()
    shape.Placement = obj.getGlobalPlacement()
    return shape


def dims_mm(box):
    return [box.XLength, box.YLength, box.ZLength]


try:
    if not MODEL.exists():
        raise FileNotFoundError(MODEL)
    R["model_sha256"] = hashlib.sha256(MODEL.read_bytes()).hexdigest()
    doc = App.openDocument(str(MODEL))
    doc.recompute()
    leaves = [o for o in doc.Objects if "StudyColor" in o.PropertiesList]
    R["feature_count"] = len(leaves)
    R["invalid_features"] = [o.Name for o in leaves if o.Shape.isNull() or not o.Shape.isValid()]
    R["wheel_stations"] = ["FL", "RL", "FR", "RR"]
    R["wheel_measurements"] = {}
    R["wheel_source_count_checks"] = {}

    for tag, label in zip(["LF", "LR", "RF", "RR"], R["wheel_stations"]):
        tire = doc.getObject("Tire" + tag)
        cables = doc.getObject("CableWeb" + tag)
        springs = doc.getObject("SpringDetail" + tag)
        spider = doc.getObject("Spider" + tag)
        if not all([tire, cables, springs, spider]):
            raise RuntimeError("missing named wheel parts at station " + label)
        tb = world(tire).BoundBox
        diameter = max(tb.YLength, tb.ZLength)
        R["wheel_measurements"][label] = {
            "nominal_visual_diameter_mm": diameter,
            "visual_axial_width_mm": tb.XLength,
            "center_world_mm": [
                (tb.XMin + tb.XMax) / 2.0,
                (tb.YMin + tb.YMax) / 2.0,
                (tb.ZMin + tb.ZMax) / 2.0,
            ],
            "tire_shape_valid": tire.Shape.isValid(),
            "spider_shape_valid": spider.Shape.isValid(),
            "nominal_diameter_source_mm": 930.0,
            "axial_width_status": "study choice; not publicly dimensioned",
        }
        R["wheel_source_count_checks"][label] = {
            "expected_cables": 192,
            "actual_cable_solids": len(cables.Shape.Solids),
            "expected_springs": 96,
            "actual_spring_solids": len(springs.Shape.Solids),
            "springs_geometry_role": springs.GeometryRole,
            "springs_visual_only": springs.GeometryRole.startswith("VISUAL-ONLY"),
        }

    R["study_component_bounds_mm"] = {}
    for object_name, report_name in [
        ("Chassis", "Chassis"),
        ("BatteryEnclosure", "BatteryPackA"),
        ("BatteryPackB", "BatteryPackB"),
    ]:
        obj = doc.getObject(object_name)
        if not obj:
            raise RuntimeError("missing required study component " + object_name)
        R["study_component_bounds_mm"][report_name] = dims_mm(world(obj).BoundBox)

    motion = doc.getObject("Motion")
    R["saved_solar_angle_deg"] = float(motion.SolarAngle)
    R["solar_pose_samples"] = []
    for angle in [0, 10, 20, 30, 45, 60, 75, 82, 90]:
        motion.SolarAngle = angle
        doc.recompute()
        panel_shapes = [o for o in leaves if "Panel" in o.Name or "Solar" in o.Name or "Camera" in o.Name]
        R["solar_pose_samples"].append({
            "angle_deg": angle,
            "panel_shapes_valid": bool(panel_shapes) and all(o.Shape.isValid() for o in panel_shapes),
            "clearance_checked": False,
        })
    motion.SolarAngle = 0
    doc.recompute()
    stowed_bounds = [world(o).BoundBox for o in leaves]
    R["overall_bounds_stowed_mm"] = [
        min(b.XMin for b in stowed_bounds), min(b.YMin for b in stowed_bounds), min(b.ZMin for b in stowed_bounds),
        max(b.XMax for b in stowed_bounds), max(b.YMax for b in stowed_bounds), max(b.ZMax for b in stowed_bounds),
    ]

    motion.SolarAngle = 82
    doc.recompute()

    world_bounds = [world(o).BoundBox for o in leaves]
    R["overall_bounds_deployed_mm"] = [
        min(b.XMin for b in world_bounds), min(b.YMin for b in world_bounds), min(b.ZMin for b in world_bounds),
        max(b.XMax for b in world_bounds), max(b.YMax for b in world_bounds), max(b.ZMax for b in world_bounds),
    ]
    deployed_bounds = R["overall_bounds_deployed_mm"]
    R["overall_dimensions_deployed_mm"] = [
        deployed_bounds[3] - deployed_bounds[0],
        deployed_bounds[4] - deployed_bounds[1],
        deployed_bounds[5] - deployed_bounds[2],
    ]
    R["source_frame"] = doc.FLIP.Frame
    R["public_mass_claim_kg"] = float(doc.FLIP.PublicMassClaim_kg)
    R["launch_mass_constraint_kg"] = float(doc.FLIP.LaunchMassConstraint_kg)
    R["mass_properties_assigned"] = False
    for q in R["wheel_measurements"].values():
        q["diameter_check_passed"] = abs(q["nominal_visual_diameter_mm"] - 930.0) <= 0.01

    R["model_integrity_passed"] = not (
        R["invalid_features"]
        or any(not q["diameter_check_passed"] for q in R["wheel_measurements"].values())
        or any(q["actual_cable_solids"] != 192 or q["actual_spring_solids"] != 96 or not q["springs_visual_only"]
               for q in R["wheel_source_count_checks"].values())
        or any(not q["panel_shapes_valid"] for q in R["solar_pose_samples"])
        or R["saved_solar_angle_deg"] != 82.0
        or any(abs(a-b) > 0.01 for a, b in zip(R["study_component_bounds_mm"]["Chassis"], [1460.0, 400.0, 2100.0]))
        or any(abs(a-b) > 0.01 for name in ["BatteryPackA", "BatteryPackB"]
               for a, b in zip(R["study_component_bounds_mm"][name], [305.0, 220.0, 884.0]))
    )
    R["passed"] = R["model_integrity_passed"]
    OUT.write_text(json.dumps(R, indent=2), encoding="utf-8")
    print("V5 bounded audit complete: model_integrity_passed=" + str(R["model_integrity_passed"]), flush=True)
    App.closeDocument(doc.Name)
except Exception:
    R["error"] = traceback.format_exc()
    OUT.write_text(json.dumps(R, indent=2), encoding="utf-8")
    print(R["error"], flush=True)
    raise
