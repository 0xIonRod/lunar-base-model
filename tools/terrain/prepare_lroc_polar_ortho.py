#!/usr/bin/env python3
"""Prepare a polar orthophoto crop for the native LunCoSim albedo processor.

Only reprojection happens here. The generated, disposable Twin carries a local
source and an ordinary `kind = "albedo"` manifest, so radiometric normalization,
sRGB encoding, bake keys and output publication keep their native owner.
Requires Pillow for numeric TIFF decoding. Does not edit USD or download data.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image
from reproject_lroc_polar_dem import MOON_RADIUS_M, destination, polar_pixel


def prepare(source: Path, output: Path, lat: float, lon: float, window: int) -> None:
    image = Image.open(source)
    if image.mode != "L":
        raise ValueError("expected an 8-bit grayscale LROC orthophoto")
    keys = image.tag_v2.get(34735, ())
    if len(keys) < 4 or len(keys) < 4 + keys[3] * 4:
        raise ValueError("missing or malformed GeoKey directory")
    values = {keys[i]: tuple(keys[i + 1:i + 4]) for i in range(4, 4 + keys[3] * 4, 4)}
    doubles = image.tag_v2.get(34736, ())

    def key(code: int) -> float:
        if code not in values:
            raise ValueError(f"missing GeoKey {code}")
        location, count, offset = values[code]
        if count != 1 or location not in (0, 34736):
            raise ValueError(f"unsupported GeoKey {code}")
        if location == 34736 and not 0 <= offset < len(doubles):
            raise ValueError(f"invalid GeoKey {code} double offset")
        return float(offset if location == 0 else doubles[offset])

    if (key(3075), key(3081), key(3095), key(3092)) != (15, -90, 0, 1):
        raise ValueError("requires south-polar stereographic, longitude 0, scale 1")
    if key(2057) != MOON_RADIUS_M or key(2058) != MOON_RADIUS_M:
        raise ValueError("requires the spherical LROC lunar datum")
    if key(3082) != 0 or key(3083) != 0 or key(1025) != 1:
        raise ValueError("requires zero false origin and pixel-is-area")
    scale, tie = image.tag_v2[33550], image.tag_v2[33922]
    pixels = image.load()
    # One-metre pixel centres, with a half-window margin. The native crop's
    # central `window` pixels then span exactly [-window/2, +window/2].
    size = window * 2
    out = Image.new("F", (size, size))
    samples = []
    for row in range(size):
        for col in range(size):
            phi, theta = destination(lat, lon, col + .5 - size / 2,
                                     size / 2 - row - .5, MOON_RADIUS_M)
            x, y = polar_pixel(phi, theta, MOON_RADIUS_M, scale, tie)
            x, y = x - .5, y - .5
            x0, y0 = math.floor(x), math.floor(y)
            if not (0 <= x0 < image.width - 1 and 0 <= y0 < image.height - 1):
                raise ValueError("requested preparation margin exceeds source coverage")
            tx, ty = x - x0, y - y0
            corners = [(pixels[x0, y0], (1-tx)*(1-ty)),
                       (pixels[x0+1, y0], tx*(1-ty)),
                       (pixels[x0, y0+1], (1-tx)*ty),
                       (pixels[x0+1, y0+1], tx*ty)]
            # Zero is the product's unmapped mask. Preserve it for the native
            # albedo processor's explicit missing-coverage policy.
            valid = [(v, w) for v, w in corners if v > 0]
            weight = sum(w for _, w in valid)
            samples.append(sum(v*w for v, w in valid)/weight if weight > 0 else 0.)
    out.putdata(samples)
    cache = output / ".cache"
    cache.mkdir(parents=True, exist_ok=True)
    raster = cache / "local_ortho.tif"
    out.save(raster, compression="raw")
    source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    raster_hash = hashlib.sha256(raster.read_bytes()).hexdigest()
    lat_half = math.degrees(size / (2 * MOON_RADIUS_M))
    lon_half = lat_half / math.cos(math.radians(lat))
    (output / "twin.toml").write_text('name = "NobileAlbedoPreparation"\nversion = "0.1.0"\n')
    (output / "Assets.toml").write_text(f'''[albedo]
name = "Reprojected Nobile orthophoto; local preparation input"
url = {json.dumps(raster.resolve().as_uri())}
dest = "local_ortho.tif"
sha256 = "{raster_hash}"
[albedo.process]
kind = "albedo"
output_root = "twin"
output = "albedo.png"
center_lat = {lat}
center_lon = {lon}
window_m = {window}
pixel_scale_m = 1.0
target_resolution = [{window}, {window}]
src_min_lat = {lat-lat_half}
src_max_lat = {lat+lat_half}
src_min_lon = {lon-lon_half}
src_max_lon = {lon+lon_half}
albedo_base_linear = 0.13
albedo_detail_strength = 0.9
albedo_illumination_radius_m = 40.0
''')
    (output / "provenance.json").write_text(json.dumps({
        "source": source.name, "sha256": source_hash,
        "center_lat": lat, "center_lon": lon, "window_m": window,
        "output_pixel_m": 1, "frame": "MOON_ME",
        "radiometry": "native albedo processor; local contrast, not calibrated reflectance",
    }, indent=2) + "\n")
    print(f"Prepared {output}; process its albedo dataset with LunCoSim, then install albedo.png beside the DEM.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--center-lat", required=True, type=float)
    parser.add_argument("--center-lon", required=True, type=float)
    parser.add_argument("--window-m", type=int, default=512)
    args = parser.parse_args()
    if args.window_m < 2 or args.window_m % 2 or not -90 < args.center_lat < 0 or not 0 <= args.center_lon <= 360:
        parser.error("requires an even positive window and a southern latitude / 0-360 longitude")
    prepare(args.source, args.output, args.center_lat, args.center_lon, args.window_m)
