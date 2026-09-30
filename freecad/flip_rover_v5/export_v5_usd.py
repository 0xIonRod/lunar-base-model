"""Export the saved FLIP v5 visual model as one self-contained binary USD stage.

Run with FreeCADCmd/freecadcmd.exe and this script's path. The FreeCAD Python
runtime must be able to import Pixar OpenUSD's pxr modules (for example, set
FLIP_USD_PXR_PATH to a directory containing pxr from usd-core). Geometry is
tessellated from the final FCStd in its saved global placement, converted from
millimetres to metres exactly once, and written as visual-only USD meshes.
This stage does not create physics, collision geometry, mass properties, or a
runtime solar-array joint.
"""

from __future__ import print_function

import datetime
import gc
import hashlib
import json
import os
import re
import sys
import traceback
from pathlib import Path

pxr_path = os.environ.get("FLIP_USD_PXR_PATH")
if pxr_path and pxr_path not in sys.path:
    sys.path.insert(0, pxr_path)

import FreeCAD as App
from pxr import Gf, Sdf, Usd, UsdGeom, Vt

HERE = Path(__file__).resolve().parent
SOURCE = HERE / "FLIP_rover_v5.FCStd"
OUTPUT = HERE / "FLIP_rover_v5.usdc"
REPORT = HERE / "usd_export_report.json"
TEMP_OUTPUT = HERE / "FLIP_rover_v5.tmp.usdc"
LINEAR_DEFLECTION_MM = 1.0
DETAIL_DEFLECTION_MM = 2.0
MM_TO_METRES = 0.001
EXPECTED_VISUAL_FEATURES = 195

STATIONS = {
    "LF": "FrontLeft",
    "RF": "FrontRight",
    "LR": "RearLeft",
    "RR": "RearRight",
}
WHEEL_PREFIXES = (
    "Drive", "Tire", "Spider", "HubCap", "HubBolt", "CableWeb",
    "SpringDetail", "Rim", "InnerWheel", "OuterBand",
)


def ident(value):
    result = re.sub(r"[^A-Za-z0-9_]", "_", str(value))
    if not result or not re.match(r"[A-Za-z_]", result):
        result = "_" + result
    return result


def classify(obj):
    name = obj.Name
    for suffix, station in STATIONS.items():
        if name.endswith(suffix) and name.startswith(WHEEL_PREFIXES):
            return ("WheelStations", station)
    if name in ("BatteryEnclosure", "BatteryPackB", "BatteryTray") or name.startswith("Battery"):
        return ("BatteryPacks", None)
    if any(token in name.lower() for token in ("solar", "panel", "cell", "camera", "sensor", "antenna")):
        return ("SolarArrayAndSensors", None)
    if name.startswith("Payload") or any(token in name.lower() for token in ("metal", "ldes", "lidar", "retroreflector")):
        return ("PayloadDeckAndInstruments", None)
    return ("ChassisAndEquipment", None)


def shape_world(obj):
    shape = obj.Shape.copy()
    shape.Placement = obj.getGlobalPlacement()
    return shape


def set_custom(prim, name, value_type, value):
    prim.CreateAttribute(name, value_type, custom=True).Set(value)


def to_stage_point(vector):
    return Gf.Vec3f(
        float(vector.x) * MM_TO_METRES,
        float(vector.y) * MM_TO_METRES,
        float(vector.z) * MM_TO_METRES,
    )


def define_mesh(stage, obj, component, station, shape, counts):
    detail_feature = obj.Name.startswith(("CableWeb", "SpringDetail"))
    deflection_mm = DETAIL_DEFLECTION_MM if detail_feature else LINEAR_DEFLECTION_MM
    points_mm, triangles = shape.tessellate(deflection_mm)
    if not points_mm or not triangles:
        raise RuntimeError("empty tessellation for " + obj.Name)

    points = [to_stage_point(point) for point in points_mm]
    indices = []
    for triangle in triangles:
        if len(triangle) != 3:
            raise RuntimeError("non-triangle tessellation for " + obj.Name)
        i, j, k = (int(index) for index in triangle)
        indices.extend((i, j, k))

    mins = tuple(min(float(point[axis]) for point in points) for axis in range(3))
    maxs = tuple(max(float(point[axis]) for point in points) for axis in range(3))
    for axis in range(3):
        counts["min_m"][axis] = min(counts["min_m"][axis], mins[axis])
        counts["max_m"][axis] = max(counts["max_m"][axis], maxs[axis])

    path = "/FLIP/Visuals/" + ident(component)
    if station:
        path += "/" + ident(station)
    path += "/" + ident(obj.Name)
    mesh = UsdGeom.Mesh.Define(stage, Sdf.Path(path))
    mesh.CreatePointsAttr().Set(Vt.Vec3fArray(points))
    mesh.CreateFaceVertexCountsAttr().Set(Vt.IntArray([3] * len(triangles)))
    mesh.CreateFaceVertexIndicesAttr().Set(Vt.IntArray(indices))
    mesh.CreateSubdivisionSchemeAttr().Set(UsdGeom.Tokens.none)
    mesh.CreateOrientationAttr().Set(UsdGeom.Tokens.rightHanded)
    mesh.CreateExtentAttr().Set(Vt.Vec3fArray([Gf.Vec3f(*mins), Gf.Vec3f(*maxs)]))

    color = tuple(max(0.0, min(1.0, float(c))) for c in obj.StudyColor[:3])
    display_color = UsdGeom.PrimvarsAPI(mesh).CreatePrimvar(
        "displayColor", Sdf.ValueTypeNames.Color3fArray, UsdGeom.Tokens.constant)
    display_color.Set(Vt.Vec3fArray([Gf.Vec3f(*color)]))
    if len(obj.StudyColor) > 3 and float(obj.StudyColor[3]) < 0.999999:
        opacity = UsdGeom.PrimvarsAPI(mesh).CreatePrimvar(
            "displayOpacity", Sdf.ValueTypeNames.FloatArray, UsdGeom.Tokens.constant)
        opacity.Set(Vt.FloatArray([float(obj.StudyColor[3])]))

    prim = mesh.GetPrim()
    set_custom(prim, "cad:sourceName", Sdf.ValueTypeNames.String, obj.Name)
    set_custom(prim, "cad:sourceLabel", Sdf.ValueTypeNames.String, obj.Label)
    set_custom(prim, "cad:sourceComponent", Sdf.ValueTypeNames.String,
               component + ("/" + station if station else ""))
    set_custom(prim, "cad:visualOnly", Sdf.ValueTypeNames.Bool, True)
    set_custom(prim, "cad:collisionGeometry", Sdf.ValueTypeNames.Bool, False)
    set_custom(prim, "cad:linearDeflectionMm", Sdf.ValueTypeNames.Float, deflection_mm)
    if station:
        set_custom(prim, "cad:wheelStation", Sdf.ValueTypeNames.String, station)

    counts["objects"] += 1
    counts["points"] += len(points)
    counts["triangles"] += len(triangles)
    return (mins, maxs)


def write_stage(doc, objects, source_hash):
    grouped = {}
    for obj in objects:
        component, station = classify(obj)
        grouped.setdefault(component, {}).setdefault(station, []).append(obj)
    for component in grouped:
        for station in grouped[component]:
            grouped[component][station].sort(key=lambda item: item.Name)

    if TEMP_OUTPUT.exists():
        TEMP_OUTPUT.unlink()
    stage = Usd.Stage.CreateNew(str(TEMP_OUTPUT))
    if not stage:
        raise RuntimeError("OpenUSD could not create " + str(TEMP_OUTPUT))
    UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
    UsdGeom.SetStageMetersPerUnit(stage, 1.0)
    layer = stage.GetRootLayer()
    layer.customLayerData = {
        "freecadSourceFile": SOURCE.name,
        "freecadSourceSha256": source_hash,
        "geometryRole": "visual-only tessellated CAD; no physics or collision",
        "sourceFrame": "X lateral, Y up, +Z forward; millimetres",
        "linearDeflectionMm": LINEAR_DEFLECTION_MM,
        "wireDetailDeflectionMm": DETAIL_DEFLECTION_MM,
    }
    layer.documentation = "FLIP v5 FreeCAD visual export. Global placements are baked into mesh points; coordinates are metres, Y-up."

    root = UsdGeom.Xform.Define(stage, "/FLIP")
    stage.SetDefaultPrim(root.GetPrim())
    root.GetPrim().SetMetadata("kind", "assembly")
    set_custom(root.GetPrim(), "cad:sourceDocument", Sdf.ValueTypeNames.String, SOURCE.name)
    set_custom(root.GetPrim(), "cad:sourceSha256", Sdf.ValueTypeNames.String, source_hash)
    set_custom(root.GetPrim(), "cad:coordinatePolicy", Sdf.ValueTypeNames.String,
               "global FreeCAD placements baked into mesh points; mm converted to m once")
    set_custom(root.GetPrim(), "cad:visualOnly", Sdf.ValueTypeNames.Bool, True)

    visuals = UsdGeom.Xform.Define(stage, "/FLIP/Visuals")
    set_custom(visuals.GetPrim(), "cad:transformPolicy", Sdf.ValueTypeNames.String,
               "organizational hierarchy; component transforms are baked into mesh points")
    for component in sorted(grouped):
        component_path = "/FLIP/Visuals/" + ident(component)
        component_prim = UsdGeom.Xform.Define(stage, component_path).GetPrim()
        component_prim.SetMetadata("kind", "component")
        station_map = grouped[component]
        if component == "WheelStations":
            for station in sorted(station_map):
                station_path = component_path + "/" + ident(station)
                station_prim = UsdGeom.Xform.Define(stage, station_path).GetPrim()
                station_prim.SetMetadata("kind", "component")
                set_custom(station_prim, "cad:wheelStation", Sdf.ValueTypeNames.String, station)

    counts = {"objects": 0, "points": 0, "triangles": 0,
              "min_m": [float("inf")] * 3, "max_m": [float("-inf")] * 3}
    exact_bounds_mm = [float("inf"), float("inf"), float("inf"),
                       float("-inf"), float("-inf"), float("-inf")]
    wheel_centers_m = {}
    wheel_dimensions_m = {}

    for component in sorted(grouped):
        for station in sorted(grouped[component], key=lambda value: value or ""):
            for obj in grouped[component][station]:
                world_shape = shape_world(obj)
                bounds = world_shape.BoundBox
                exact_bounds_mm[0] = min(exact_bounds_mm[0], bounds.XMin)
                exact_bounds_mm[1] = min(exact_bounds_mm[1], bounds.YMin)
                exact_bounds_mm[2] = min(exact_bounds_mm[2], bounds.ZMin)
                exact_bounds_mm[3] = max(exact_bounds_mm[3], bounds.XMax)
                exact_bounds_mm[4] = max(exact_bounds_mm[4], bounds.YMax)
                exact_bounds_mm[5] = max(exact_bounds_mm[5], bounds.ZMax)
                mins, maxs = define_mesh(stage, obj, component, station, world_shape, counts)

                if obj.Name.startswith("Tire"):
                    station_code = next(code for code in STATIONS if obj.Name.endswith(code))
                    station_name = STATIONS[station_code]
                    wheel_centers_m[station_name] = [
                        (bounds.XMin + bounds.XMax) * 0.5 * MM_TO_METRES,
                        (bounds.YMin + bounds.YMax) * 0.5 * MM_TO_METRES,
                        (bounds.ZMin + bounds.ZMax) * 0.5 * MM_TO_METRES,
                    ]
                    wheel_dimensions_m[station_name] = [
                        bounds.XLength * MM_TO_METRES,
                        bounds.YLength * MM_TO_METRES,
                        bounds.ZLength * MM_TO_METRES,
                    ]

                if counts["objects"] % 20 == 0:
                    print("USD authored %d / %d visual features" % (
                        counts["objects"], len(objects)), flush=True)

    if counts["objects"] != EXPECTED_VISUAL_FEATURES:
        raise RuntimeError("USD mesh count %d does not match %d CAD features" % (
            counts["objects"], EXPECTED_VISUAL_FEATURES))
    stage.Save()
    stage = None
    gc.collect()
    os.replace(str(TEMP_OUTPUT), str(OUTPUT))

    dimensions_m = [counts["max_m"][i] - counts["min_m"][i] for i in range(3)]
    report = {
        "exported_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "source_file": SOURCE.name,
        "source_sha256": source_hash,
        "usd_file": OUTPUT.name,
        "usd_format": "USDC binary, self-contained",
        "stage_up_axis": "Y",
        "stage_meters_per_unit": 1.0,
        "source_linear_units": "mm",
        "linear_scale_mm_to_m": MM_TO_METRES,
        "source_global_transforms": "baked into mesh point positions once",
        "component_transforms": "organizational Xform hierarchy; mesh points are in global stage coordinates",
        "geometry_role": "visual-only; no collision, mass, physics, or articulated runtime joint",
        "tessellation_linear_deflection_mm": {
            "general_geometry": LINEAR_DEFLECTION_MM,
            "wheel_cable_and_spring_details": DETAIL_DEFLECTION_MM,
        },
        "normal_policy": "per-face normals omitted; USD consumers derive triangle normals",
        "mesh_count": counts["objects"],
        "point_count": counts["points"],
        "triangle_count": counts["triangles"],
        "exact_source_bounds_mm": exact_bounds_mm,
        "tessellated_bounds_m": [counts["min_m"], counts["max_m"]],
        "tessellated_dimensions_m": dimensions_m,
        "wheel_centers_m": wheel_centers_m,
        "wheel_dimensions_m": wheel_dimensions_m,
        "saved_solar_angle_deg": float(doc.getObject("Motion").SolarAngle),
        "usd_sha256": hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
    }
    REPORT.write_text(json.dumps(report, indent=2), encoding="utf-8")
    return report


def main():
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    source_hash = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    doc = App.openDocument(str(SOURCE))
    try:
        doc.recompute()
        motion = doc.getObject("Motion")
        if motion is None:
            raise RuntimeError("missing CAD pose controller Motion")
        visual_objects = [
            obj for obj in doc.Objects
            if "StudyColor" in obj.PropertiesList
            and hasattr(obj, "Shape")
            and not obj.Shape.isNull()
        ]
        visual_objects.sort(key=lambda obj: obj.Name)
        if len(visual_objects) != EXPECTED_VISUAL_FEATURES:
            raise RuntimeError("expected %d visual features, found %d" % (
                EXPECTED_VISUAL_FEATURES, len(visual_objects)))
        invalid = [obj.Name for obj in visual_objects if not obj.Shape.isValid()]
        if invalid:
            raise RuntimeError("invalid CAD shapes: " + ", ".join(invalid))
        if abs(float(motion.SolarAngle) - 82.0) > 1e-6:
            raise RuntimeError("expected saved 82-degree solar presentation pose")
        report = write_stage(doc, visual_objects, source_hash)
        if report["saved_solar_angle_deg"] != 82.0:
            raise RuntimeError("export report does not record the expected pose")
        print("USD export complete: %s" % OUTPUT, flush=True)
        print("Meshes=%d, points=%d, triangles=%d" % (
            report["mesh_count"], report["point_count"], report["triangle_count"]), flush=True)
        print("Bounds m: %s" % json.dumps(report["tessellated_dimensions_m"]), flush=True)
        print("Wheel centers m: %s" % json.dumps(report["wheel_centers_m"], sort_keys=True), flush=True)
    finally:
        App.closeDocument(doc.Name)


try:
    main()
except Exception:
    traceback.print_exc()
    for path in (TEMP_OUTPUT,):
        if path.exists():
            try:
                path.unlink()
            except Exception:
                pass
    sys.exit(1)
