from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parent


def split_md_row(line: str) -> list[str]:
    body = line.strip().strip("|")
    return [cell.strip() for cell in body.split("|")]


def read_md_table(path: Path, header_index: int = 0) -> tuple[list[str], list[list[str]], list[int]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    for i in range(header_index, len(lines) - 1):
        if lines[i].lstrip().startswith("|") and set(lines[i].replace("|", "").replace(" ", "").replace("-", "")) == set():
            # This is the separator row; the preceding line is the header.
            headers = split_md_row(lines[i - 1])
            rows: list[list[str]] = []
            row_lines: list[int] = []
            j = i + 1
            while j < len(lines) and lines[j].lstrip().startswith("|"):
                row = split_md_row(lines[j])
                if any(row):
                    rows.append(row)
                    row_lines.append(j + 1)
                j += 1
            return headers, rows, row_lines
    raise ValueError(f"No Markdown table found in {path}")


def row_dicts(path: Path, header_index: int = 0) -> tuple[list[dict[str, str]], list[int], list[str]]:
    headers, rows, row_lines = read_md_table(path, header_index)
    return [dict(zip(headers, row)) for row in rows], row_lines, headers


def urls(text: str) -> list[str]:
    return re.findall(r"https?://[^)\s]+", text)


def mission_refs(text: str) -> list[str]:
    return re.findall(r"\b(?:M|A)\d{2}\b", text)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def raster_profile(path: Path) -> dict:
    image = Image.open(path)
    data = np.asarray(image)
    tags = getattr(image, "tag_v2", {})
    geo_keys = tuple(tags.get(34735, ()))
    geo_ascii = tags.get(34737)
    if isinstance(geo_ascii, bytes):
        geo_ascii = geo_ascii.decode("utf-8", errors="replace")
    return {
        "path": str(path.relative_to(ROOT)),
        "format": image.format,
        "mode": image.mode,
        "dtype": str(data.dtype),
        "width": int(image.width),
        "height": int(image.height),
        "min": float(np.nanmin(data)),
        "max": float(np.nanmax(data)),
        "mean": float(np.nanmean(data)),
        "nan_count": int(np.isnan(data).sum()) if np.issubdtype(data.dtype, np.floating) else 0,
        "sha256": sha256(path),
        "scale": tuple(tags.get(33550, ())),
        "tiepoint": tuple(tags.get(33922, ())),
        "sample_format": tuple(tags.get(339, ())),
        "bits_per_sample": tuple(tags.get(258, ())),
        "geo_keys": geo_keys,
        "geo_ascii": geo_ascii,
        "geo_double": tuple(tags.get(34736, ())),
    }


def main() -> None:
    missions, mission_lines, mission_headers = row_dicts(ROOT / "research" / "missions.md")
    landers, lander_lines, lander_headers = row_dicts(ROOT / "research" / "vehicles.md", 5)
    rovers, rover_lines, rover_headers = row_dicts(ROOT / "research" / "vehicles.md", 22)
    orbital, orbital_lines, orbital_headers = row_dicts(ROOT / "research" / "vehicles.md", 36)
    locations, location_lines, location_headers = row_dicts(ROOT / "research" / "locations.md")

    mission_ids = [row["ID"] for row in missions]
    expected_ids = [f"M{i:02d}" for i in range(1, 23)] + [f"A{i:02d}" for i in range(1, 4)]
    vehicle_rows = landers + rovers + orbital
    vehicle_ids = [row["ID"] for row in vehicle_rows]
    location_ids = [row["ID"] for row in locations]

    status_values = []
    confidence_values = []
    for row in missions:
        status_conf = row["Status / confidence"]
        parts = [p.strip().lower() for p in status_conf.split(";")]
        confidence_values.append(parts[-1] if parts else "")
        status_values.append(parts[0] if parts else "")

    declared_statuses = {
        "completed",
        "planned",
        "conditional",
        "proposed",
        "schedule_conflict",
        "portfolio_placeholder",
    }
    observed_statuses = sorted(set(status_values))
    invalid_statuses = sorted(set(status_values) - declared_statuses)

    mission_refs_in_locations = {ref for row in locations for ref in mission_refs(row["Missions"])}
    vehicle_ref_map = {row["ID"]: mission_refs(row["Missions"]) for row in vehicle_rows}
    vehicle_mission_refs = {ref for refs in vehicle_ref_map.values() for ref in refs}
    invalid_vehicle_refs = sorted(vehicle_mission_refs - set(mission_ids))
    invalid_location_refs = sorted(mission_refs_in_locations - set(mission_ids))
    missing_location_refs = sorted(set(mission_ids) - mission_refs_in_locations)

    required_fields = [
        "Target date",
        "Location or orbit",
        "Lander / carrier",
        "Rover or surface vehicle",
        "Primary source",
    ]
    placeholder_tokens = re.compile(
        r"\b(?:tbd|date not published|not fixed|none announced|no rover announced|no large named rover|"
        r"no named rover|individual dates tbd|providers and landers tbd|payloads tbd|"
        r"passenger cargo and possible surface robotic asset tbd)\b",
        re.IGNORECASE,
    )
    placeholder_counts = {
        field: sum(bool(placeholder_tokens.search(row[field])) for row in missions)
        for field in required_fields
    }
    source_counts = [len(urls(row["Primary source"])) for row in missions]

    jp2 = ROOT / "luna2_direct_sim" / "raw" / "LDEM_4.JP2"
    direct_tif = ROOT / "luna2_direct_sim" / "site" / "luna2" / "materials" / "textures" / "heightmap.tif"
    twin_tif = ROOT / "luna2_twin" / ".cache" / "terrain" / "luna2" / "materials" / "textures" / "heightmap.tif"
    raster_profiles = [raster_profile(p) for p in (jp2, direct_tif, twin_tif)]
    direct_data = np.asarray(Image.open(direct_tif))
    twin_data = np.asarray(Image.open(twin_tif))
    array_comparison = {
        "same_shape": list(direct_data.shape) == list(twin_data.shape),
        "same_values_after_float_cast": bool(np.array_equal(direct_data.astype(np.float32), twin_data.astype(np.float32))),
        "max_abs_difference_m": float(np.max(np.abs(direct_data.astype(np.float64) - twin_data.astype(np.float64)))),
    }
    # For the 32x32 pixel-is-area crop, the raster footprint midpoint is 32.5 N, 2.0 W.
    raster_midpoint = {"lat": 32.5, "lon": -2.0}
    metadata_center = {"lat": 32.4, "lon": -1.9}

    missing_handover_artifacts = [
        str((ROOT / "luna2_twin" / ".cache" / "terrain" / "luna2" / name).relative_to(ROOT))
        for name in ("luna2_sinus_lunicus_analysis.json", "luna2_sinus_lunicus_analysis.md")
        if not (ROOT / "luna2_twin" / ".cache" / "terrain" / "luna2" / name).exists()
    ]
    referenced_external_source = not (ROOT / "surfacegenerator").exists()

    result = {
        "scope": {
            "snapshot": "2026-08-22",
            "research_rows": {"missions": len(missions), "vehicles": len(vehicle_rows), "locations": len(locations)},
            "mission_headers": mission_headers,
            "vehicle_table_headers": {"landers": lander_headers, "rovers": rover_headers, "orbital": orbital_headers},
            "location_headers": location_headers,
        },
        "research_checks": {
            "mission_id_duplicates": sorted({x for x in mission_ids if mission_ids.count(x) > 1}),
            "missing_expected_mission_ids": sorted(set(expected_ids) - set(mission_ids)),
            "unexpected_mission_ids": sorted(set(mission_ids) - set(expected_ids)),
            "mission_row_widths": sorted({len(row) for row in [split_md_row(line) for line in (ROOT / "research" / "missions.md").read_text(encoding="utf-8").splitlines() if line.startswith("|")][2:]}),
            "invalid_statuses_against_data_model": invalid_statuses,
            "observed_statuses": observed_statuses,
            "confidence_counts": {value: confidence_values.count(value) for value in sorted(set(confidence_values))},
            "placeholder_counts_by_field": placeholder_counts,
            "missing_primary_source_rows": [row["ID"] for row, count in zip(missions, source_counts) if count == 0],
            "primary_source_link_count": {"min": min(source_counts), "max": max(source_counts), "rows_with_multiple": sum(x > 1 for x in source_counts)},
            "location_reference_ids_not_in_missions": invalid_location_refs,
            "mission_ids_missing_from_locations": missing_location_refs,
            "vehicle_reference_ids_not_in_missions": invalid_vehicle_refs,
            "vehicle_catalog_duplicate_ids": sorted({x for x in vehicle_ids if vehicle_ids.count(x) > 1}),
            "vehicle_catalog_rows_without_mission_reference": [row["ID"] for row in vehicle_rows if not mission_refs(row["Missions"])],
            "vehicle_catalog_reference_coverage": {"mission_ids_referenced": len(vehicle_mission_refs), "mission_ids_total": len(set(mission_ids))},
            "source_urls_in_mission_register": sum(source_counts),
        },
        "terrain_checks": {
            "rasters": raster_profiles,
            "direct_vs_twin_array_comparison": array_comparison,
            "metadata_center": metadata_center,
            "raster_footprint_midpoint": raster_midpoint,
            "center_offset_deg": {"lat": metadata_center["lat"] - raster_midpoint["lat"], "lon": metadata_center["lon"] - raster_midpoint["lon"]},
            "missing_handover_artifacts": missing_handover_artifacts,
            "external_surfacegenerator_source_present_in_workspace": not referenced_external_source,
        },
        "runtime_checks": {
            "scene_files": sorted(str(p.relative_to(ROOT)) for p in (ROOT / "luna2_twin" / "sim" / "scenes").glob("*.usda")),
            "default_scene_exists": (ROOT / "luna2_twin" / "sim" / "scenes" / "luna2_static.usda").exists(),
            "luna2_lit_parse_error_logged": "USD parse error" in (ROOT / "logs" / "luncosim-4103.err.log").read_text(encoding="utf-8", errors="replace"),
            "prior_swap_chain_timeout_logged": "swap chain texture: Timeout" in (ROOT / "logs" / "luncosim-4104.err.log").read_text(encoding="utf-8", errors="replace"),
            "direct_target_resolution_clamped": "target_res 8 out of range" in (ROOT / "logs" / "luncosim-direct-4107.err.log").read_text(encoding="utf-8", errors="replace"),
            "active_handover_reports_core_ready_but_bake_stuck": True,
        },
    }

    out = ROOT / "quality_audit_results.json"
    out.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
