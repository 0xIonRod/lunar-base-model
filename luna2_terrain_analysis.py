from __future__ import annotations

import argparse
import json
import math
import shutil
import sys
from pathlib import Path

import numpy as np
import rasterio
from PIL import Image
from rasterio.windows import Window


MOON_RADIUS_M = 1_737_400.0
LUNA2_LAT = 32.4
LUNA2_LON = -1.9


def crop_window(src: rasterio.DatasetReader, lat: float, lon: float, width_deg: float, height_deg: float):
    left = lon - width_deg / 2.0
    right = lon + width_deg / 2.0
    top = lat + height_deg / 2.0
    bottom = lat - height_deg / 2.0
    row0, col0 = src.index(left, top)
    row1, col1 = src.index(right, bottom)
    col0, col1 = sorted((max(0, col0), min(src.width, col1)))
    row0, row1 = sorted((max(0, row0), min(src.height, row1)))
    return Window(col0, row0, max(1, col1 - col0), max(1, row1 - row0))


def rgb_relief(data: np.ndarray) -> Image.Image:
    lo, hi = np.percentile(data, [2, 98])
    norm = np.clip((data - lo) / max(hi - lo, 1e-9), 0.0, 1.0)
    # A simple lunar-relief palette: dark lowlands, warm highlands.
    stops = np.array(
        [[18, 24, 32], [55, 67, 82], [112, 119, 126], [178, 169, 148], [245, 235, 205]],
        dtype=np.float32,
    )
    scaled = norm * (len(stops) - 1)
    i0 = np.floor(scaled).astype(np.int32).clip(0, len(stops) - 2)
    frac = (scaled - i0)[..., None]
    rgb = stops[i0] * (1.0 - frac) + stops[i0 + 1] * frac
    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), mode="RGB")


def analyze(elevations: np.ndarray, pixel_x_m: float, pixel_y_m: float) -> dict:
    values = elevations[np.isfinite(elevations)].astype(np.float64)
    gy, gx = np.gradient(elevations.astype(np.float64), pixel_y_m, pixel_x_m)
    slope_deg = np.degrees(np.arctan(np.hypot(gx, gy)))
    dx = np.diff(elevations.astype(np.float64), axis=1)
    dy = np.diff(elevations.astype(np.float64), axis=0)
    return {
        "elevation_min_m": float(values.min()),
        "elevation_max_m": float(values.max()),
        "elevation_range_m": float(values.max() - values.min()),
        "elevation_mean_m": float(values.mean()),
        "elevation_median_m": float(np.median(values)),
        "elevation_std_m": float(values.std()),
        "elevation_percentiles_m": {
            "p05": float(np.percentile(values, 5)),
            "p25": float(np.percentile(values, 25)),
            "p75": float(np.percentile(values, 75)),
            "p95": float(np.percentile(values, 95)),
        },
        "slope_mean_deg": float(slope_deg.mean()),
        "slope_max_deg": float(slope_deg.max()),
        "slope_percentiles_deg": {
            "p50": float(np.percentile(slope_deg, 50)),
            "p90": float(np.percentile(slope_deg, 90)),
            "p95": float(np.percentile(slope_deg, 95)),
        },
        "neighbor_relief_mean_m": float((np.abs(dx).mean() + np.abs(dy).mean()) / 2.0),
        "neighbor_relief_max_m": float(max(np.abs(dx).max(), np.abs(dy).max())),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate and analyze a regional Luna 2 terrain model.")
    parser.add_argument("--dem", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--writer-root", required=True, type=Path)
    parser.add_argument("--width-deg", type=float, default=8.0)
    parser.add_argument("--height-deg", type=float, default=8.0)
    args = parser.parse_args()

    sys.path.insert(0, str(args.writer_root))
    from model_writers.sdf_model_writer import SDFModelWriter

    with rasterio.open(args.dem) as src:
        window = crop_window(src, LUNA2_LAT, LUNA2_LON, args.width_deg, args.height_deg)
        elevations = src.read(1, window=window).astype(np.float32)
        transform = src.window_transform(window)
        bounds = rasterio.windows.bounds(window, src.transform)
        cols, rows = elevations.shape[1], elevations.shape[0]

    # The source is a 0.25-degree global map. Convert the local angular grid to
    # approximate metric dimensions on a spherical Moon for Gazebo sizing.
    lat_mid_rad = math.radians(LUNA2_LAT)
    pixel_x_m = abs(transform.a) * math.pi / 180.0 * MOON_RADIUS_M * math.cos(lat_mid_rad)
    pixel_y_m = abs(transform.e) * math.pi / 180.0 * MOON_RADIUS_M
    size_x_m = int(round(cols * pixel_x_m))
    size_y_m = int(round(rows * pixel_y_m))
    stats = analyze(elevations, pixel_x_m, pixel_y_m)

    args.output.mkdir(parents=True, exist_ok=True)
    model_dir = SDFModelWriter(args.output).write(
        site_id="luna2_sinus_lunicus",
        display_name="Luna 2 Sinus Lunicus",
        description=(
            "Regional terrain model centered on the Luna 2 commemorative region "
            "at Sinus Lunicus, Mare Imbrium; generated from the NASA LOLA LDEM_4 DEM."
        ),
        elevations=elevations,
        dem_profile={
            "crs": "ESRI:104903",
            "transform": transform,
            "nodata": None,
        },
        size_x_m=size_x_m,
        size_y_m=size_y_m,
        elevation_min=stats["elevation_min_m"],
        elevation_max=stats["elevation_max_m"],
        lat=LUNA2_LAT,
        lon=LUNA2_LON,
        source="NASA LOLA GDR LDEM_4.JP2 (4 pixels/degree; regional approximation)",
    )

    materials = args.writer_root.parent / "models" / "materials"
    if materials.exists():
        shutil.copytree(materials, model_dir / "materials", dirs_exist_ok=True)

    preview = rgb_relief(elevations)
    preview_path = args.output / "luna2_sinus_lunicus_preview.png"
    preview.save(preview_path)

    report = {
        "mission": "Luna 2",
        "year": 1959,
        "reference_region": "Sinus Lunicus, Mare Imbrium",
        "center_coordinates": {"latitude_deg": LUNA2_LAT, "longitude_deg": LUNA2_LON},
        "roi": {
            "width_deg": args.width_deg,
            "height_deg": args.height_deg,
            "west_deg": bounds[0],
            "east_deg": bounds[2],
            "south_deg": bounds[1],
            "north_deg": bounds[3],
        },
        "grid": {
            "rows": int(rows),
            "columns": int(cols),
            "source_resolution_deg_per_pixel": [abs(transform.e), abs(transform.a)],
            "approx_pixel_size_m": {"x": pixel_x_m, "y": pixel_y_m},
            "model_size_m": {"x": size_x_m, "y": size_y_m},
        },
        "terrain_statistics": stats,
        "interpretation": [
            "The regional surface is a relatively smooth mare setting compared with nearby crater rims and highlands.",
            "The elevation range and slope distribution indicate broad relief at regional scale, but the 0.25-degree source grid cannot resolve lander-scale rocks, small craters, or local hazards.",
            "This output is suitable for historical/regional visualization and coarse vehicle-simulation context, not precision landing-site certification.",
        ],
        "outputs": {
            "model_directory": str(model_dir),
            "preview_png": str(preview_path),
            "heightmap": str(model_dir / "materials" / "textures" / "heightmap.tif"),
        },
    }
    report_path = args.output / "luna2_sinus_lunicus_analysis.json"
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    markdown = [
        "# Luna 2 terrain analysis",
        "",
        "Regional model centered on Sinus Lunicus, Mare Imbrium (32.4°N, 1.9°W).",
        "",
        f"- Source: NASA LOLA GDR LDEM_4.JP2, 0.25°/pixel",
        f"- Grid: {rows} × {cols} samples; model footprint approximately {size_x_m:,} m × {size_y_m:,} m",
        f"- Elevation range: {stats['elevation_range_m']:.1f} m ({stats['elevation_min_m']:.1f} to {stats['elevation_max_m']:.1f} m)",
        f"- Mean slope: {stats['slope_mean_deg']:.2f}°; 95th-percentile slope: {stats['slope_percentiles_deg']['p95']:.2f}°",
        f"- Mean adjacent-cell relief: {stats['neighbor_relief_mean_m']:.1f} m",
        "",
        "## Interpretation",
        "",
        "The crop represents a broad, relatively smooth mare environment with regional relief associated with the Imbrium basin and nearby cratered terrain. Because the source grid is about 7–8 km per pixel, it is appropriate for regional visualization only; it does not resolve landing-scale boulders, small craters, or detailed hazard slopes.",
        "",
        "## Mission context",
        "",
        "Luna 2 reached the lunar surface in 1959, before detailed terrain mapping existed. This model reconstructs the present-day mapped regional topography around the Luna 2 commemorative region, rather than the spacecraft’s exact impact footprint.",
    ]
    (args.output / "luna2_sinus_lunicus_analysis.md").write_text("\n".join(markdown) + "\n", encoding="utf-8")
    print(json.dumps({"model_dir": str(model_dir), "report": str(report_path), "preview": str(preview_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


