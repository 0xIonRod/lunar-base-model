#!/usr/bin/env python3
"""Check an extracted Griffin Twin's DEM payload without network or global cache."""

from __future__ import annotations

import argparse
import hashlib
import math
from pathlib import Path
import tomllib

from reproject_lroc_polar_dem import read_source_tiff


def verify(twin: Path) -> None:
    contract = tomllib.loads((twin / "twin.toml").read_text())
    if contract["name"] != "astrobotic-griffin-1":
        raise ValueError("expected the astrobotic-griffin-1 Twin")
    if not (twin / contract["usd"]["default_scene"]).is_file():
        raise ValueError("default scene is missing")

    manifest = tomllib.loads((twin / "Assets.toml").read_text())
    for key, asset in manifest.items():
        # Each manifest source must travel with the Twin, even when a global
        # cache could otherwise make an incomplete local package look ready.
        relative = Path(asset["dest"])
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError(f"unsafe destination for {key}")
        if asset.get("shared") or asset.get("process"):
            raise ValueError(f"{key} needs an explicit portable artifact check")
        source = twin / ".cache" / relative
        with source.open("rb") as stream:
            actual = hashlib.file_digest(stream, "sha256").hexdigest()
        if actual != asset["sha256"]:
            raise ValueError(f"SHA-256 mismatch for {key}")
        print(f"OK: cached source {key}")

    site = twin / ".cache" / "terrain" / "nobile03"
    width, height, samples, fields = read_source_tiff(
        site / "materials" / "textures" / "heightmap.tif"
    )
    if (width, height) != (129, 129) or not all(math.isfinite(v) for v in samples):
        raise ValueError("expected a complete finite 129 x 129 terrain crop")
    if 33550 not in fields or 33922 not in fields or 34735 not in fields:
        raise ValueError("terrain georeferencing is missing")
    print("OK: processed NOBILE03 DEM and georeferencing")
    print("OK: extracted Twin contains its DEM sources and runtime crop offline")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("twin", type=Path, help="extracted astrobotic-griffin-1 folder")
    args = parser.parse_args()
    try:
        verify(args.twin)
    except (OSError, ValueError, KeyError) as error:
        parser.exit(1, f"Griffin bundle is incomplete: {error}\n")


if __name__ == "__main__":
    main()
