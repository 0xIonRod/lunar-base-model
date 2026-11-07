"""Convert a tessellated FreeCAD OBJ into a LunCoSim-ready GLB.

FreeCAD remains the editable NURBS/BRep source. FreeCAD's headless OBJ
exporter performs the required tessellation; this Blender stage applies units,
the source-axis transform, and writes the runtime visual payload.

Example, from the project root:

    blender -b --factory-startup --python convert_obj_to_glb.py -- \
        --input model.obj --output model.glb --model griffin_1 --source-up z
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy


def parse_args() -> argparse.Namespace:
    separator = sys.argv.index("--") if "--" in sys.argv else len(sys.argv)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--model", required=True, choices=("flip", "griffin_1"))
    parser.add_argument(
        "--source-up",
        choices=("y", "z"),
        default="z",
        help="Up axis in the FreeCAD source; the GLB target is always Y-up.",
    )
    return parser.parse_args(sys.argv[separator + 1 :])


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.materials,
        bpy.data.cameras,
        bpy.data.lights,
    ):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def make_material(name: str, color: tuple[float, float, float]) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    if principled is not None:
        principled.inputs["Base Color"].default_value = (*color, 1.0)
        principled.inputs["Metallic"].default_value = 0.55
        principled.inputs["Roughness"].default_value = 0.38
    return material


def import_obj(path: Path) -> list[bpy.types.Object]:
    before = set(bpy.data.objects)
    if hasattr(bpy.ops.wm, "obj_import"):
        bpy.ops.wm.obj_import(filepath=str(path))
    else:
        bpy.ops.import_scene.obj(filepath=str(path))
    return [obj for obj in bpy.data.objects if obj not in before]


def prepare_objects(objects: list[bpy.types.Object], source_up: str, material: bpy.types.Material) -> None:
    for obj in objects:
        if obj.type != "MESH":
            continue

        # FreeCAD models are authored in millimetres. The simulator is metres
        # and Y-up. Rotating Z-up -> Y-up about X preserves handedness:
        # (x, y, z) -> (x, -z, y). Y-up sources need no axis rotation.
        obj.scale = (0.001, 0.001, 0.001)
        if source_up == "z":
            obj.rotation_euler[0] = math.radians(90.0)
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        obj.select_set(False)

        obj.data.materials.clear()
        obj.data.materials.append(material)
        for polygon in obj.data.polygons:
            polygon.use_smooth = False


def main() -> None:
    args = parse_args()
    if not args.input.is_file():
        raise FileNotFoundError(args.input)
    args.output.parent.mkdir(parents=True, exist_ok=True)

    clear_scene()
    material = make_material(
        f"{args.model} FreeCAD visual",
        (0.26, 0.29, 0.33) if args.model == "griffin_1" else (0.20, 0.24, 0.28),
    )
    objects = import_obj(args.input)
    prepare_objects(objects, args.source_up, material)

    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.length_unit = "METERS"
    scene.unit_settings.scale_length = 1.0
    bpy.ops.export_scene.gltf(
        filepath=str(args.output),
        export_format="GLB",
        export_yup=True,
        export_apply=True,
        use_selection=False,
    )
    mesh_count = len([obj for obj in objects if obj.type == "MESH"])
    print(f"WROTE {args.output} ({mesh_count} mesh objects, source-up={args.source_up}, target-up=y)")


if __name__ == "__main__":
    main()
