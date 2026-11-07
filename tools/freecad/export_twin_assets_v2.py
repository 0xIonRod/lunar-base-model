"""Export the newest FreeCAD study models into the Griffin-1 Twin.

Run this file with FreeCADCmd from the repository root. It scans all
project-owned FCStd files for each model family and selects the newest
filesystem version. This makes a later CAD revision the integration input
without requiring a USD edit that hard-codes a stale source path.

The generated GLB files are visual payloads only. The USD vehicle files keep
their existing collision, mass, actuator, and Modelica contracts.
"""

from __future__ import annotations

import datetime
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

import FreeCAD as App
import Mesh


PROJECT_ROOT = Path(__file__).resolve().parents[2]
TWIN_ROOT = PROJECT_ROOT / "twins" / "astrobotic-griffin-1"
RUNTIME_TWIN_ROOT = PROJECT_ROOT / "luncosim-griffin-1" / "twins" / "astrobotic-griffin-1"
VISUAL_ROOT = TWIN_ROOT / "visuals"
CONVERTER = Path(__file__).with_name("convert_obj_to_glb.py")


def candidates_for(model: str) -> list[Path]:
    needle = "flip" if model == "flip" else "griffin_1_lander"
    candidates = []
    for path in PROJECT_ROOT.rglob("*.FCStd"):
        # The nested simulator checkout has its own historical copy of the
        # Twin, but the project-level CAD files are the source authority.
        if "luncosim-griffin-1" in path.parts:
            continue
        if needle in path.stem.lower():
            candidates.append(path)
    return sorted(set(candidates))


def latest_source(model: str) -> tuple[Path, list[Path]]:
    candidates = candidates_for(model)
    if not candidates:
        raise FileNotFoundError(f"No FCStd source found for {model}")
    return max(candidates, key=lambda path: (path.stat().st_mtime_ns, str(path).lower())), candidates


def blender_executable() -> str:
    configured = os.environ.get("BLENDER_EXE")
    if configured and Path(configured).is_file():
        return configured
    for candidate in (
        Path(r"C:\Program Files\Blender Foundation\Blender 4.1\blender.exe"),
        Path(r"C:\Program Files\Blender Foundation\Blender 5.1\blender.exe"),
    ):
        if candidate.is_file():
            return str(candidate)
    found = shutil.which("blender")
    if found:
        return found
    raise FileNotFoundError("Blender was not found; set BLENDER_EXE to a Blender executable")


def export_one(model: str, source: Path, destination: Path, staging: Path, blender: str) -> dict[str, object]:
    document = App.openDocument(str(source))
    try:
        objects = [
            obj
            for obj in document.Objects
            if obj.TypeId == "Part::Feature" and hasattr(obj, "Shape") and not obj.Shape.isNull()
        ]
        if not objects:
            raise RuntimeError(f"No Part::Feature geometry found in {source}")
        obj_path = staging / f"{model}.obj"
        Mesh.export(objects, str(obj_path))
    finally:
        App.closeDocument(document.Name)

    source_up = "y" if model == "flip" else "z"
    command = [
        blender,
        "-b",
        "--factory-startup",
        "--python",
        str(CONVERTER),
        "--",
        "--input",
        str(obj_path),
        "--output",
        str(destination),
        "--model",
        model,
        "--source-up",
        source_up,
    ]
    subprocess.run(command, check=True)
    if not destination.is_file() or destination.stat().st_size == 0:
        raise RuntimeError(f"Blender did not create {destination}")
    stat = source.stat()
    return {
        "model": model,
        "source": source.relative_to(PROJECT_ROOT).as_posix(),
        "source_mtime_ns": stat.st_mtime_ns,
        "source_mtime_iso": datetime.datetime.fromtimestamp(stat.st_mtime).isoformat(timespec="seconds"),
        "source_size_bytes": stat.st_size,
        "visual_asset": destination.relative_to(TWIN_ROOT).as_posix(),
        "exporter": "FreeCAD Mesh.export -> Blender glTF GLB",
        "units": "millimetres converted to metres",
        "source_up_axis": source_up,
        "target_up_axis": "y",
        "coordinate_transform": "Z-up sources rotate +90 degrees about X; Y-up sources are unchanged",
        "physics_boundary": "visual payload only; USD/Modelica physics remains authoritative",
    }


def main() -> None:
    VISUAL_ROOT.mkdir(parents=True, exist_ok=True)
    blender = blender_executable()
    manifest: dict[str, object] = {
        "schema": "lunco.freecad-visual-source.v1",
        "selection_policy": "newest project-owned .FCStd by filesystem modification time; path breaks ties",
        "twin": "astrobotic-griffin-1",
        "sources": {},
    }
    with tempfile.TemporaryDirectory(prefix="lunco-freecad-export-") as temp_dir:
        staging = Path(temp_dir)
        for model, filename in (("flip", "flip_freecad.glb"), ("griffin_1", "griffin_1_freecad.glb")):
            source, candidates = latest_source(model)
            print(f"{model}: selected {source}")
            print("  candidates: " + ", ".join(str(path) for path in candidates))
            destination = VISUAL_ROOT / filename
            manifest["sources"][model] = export_one(model, source, destination, staging, blender)

    manifest_path = VISUAL_ROOT / "source-manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"WROTE {manifest_path}")

    if RUNTIME_TWIN_ROOT.is_dir():
        runtime_visual_root = RUNTIME_TWIN_ROOT / "visuals"
        runtime_visual_root.mkdir(parents=True, exist_ok=True)
        for filename in ("flip_freecad.glb", "griffin_1_freecad.glb", "source-manifest.json"):
            runtime_destination = runtime_visual_root / filename
            shutil.copy2(VISUAL_ROOT / filename, runtime_destination)
            print(f"MIRRORED {runtime_destination}")


if __name__ == "__main__":
    main()
