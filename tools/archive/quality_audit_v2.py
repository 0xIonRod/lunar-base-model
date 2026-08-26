from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parent


def split_md_row(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def read_md_table(path: Path, start_at: int = 0) -> tuple[list[str], list[list[str]], list[int]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    for i in range(start_at, len(lines) - 1):
        if not lines[i].lstrip().startswith("|"):
            continue
        compact = lines[i].replace("|", "").replace(" ", "").replace("-", "")
        if compact:
            continue
        headers = split_md_row(lines[i - 1])
        rows, row_lines = [], []
        for j in range(i + 1, len(lines)):
            if not lines[j].lstrip().startswith("|"):
                break
            row = split_md_row(lines[j])
            if any(row):
                rows.append(row)
                row_lines.append(j + 1)
        return headers, rows, row_lines
    raise ValueError(f"No Markdown table found in {path}")


def row_dicts(path: Path, start_at: int = 0) -> tuple[list[dict[str, str]], list[int], list[str]]:
    headers, rows, row_lines = read_md_table(path, start_at)
    return [dict(zip(headers, row)) for row in rows], row_lines, headers


def urls(text: str) -> list[str]:
    return re.findall(r"https?://[^)\s]+", text)


def mission_refs(text: str) -> list[str]:
    return re.findall(r"\b(?:M|A)\d{2}\b", text)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def raster_profile(path: Path) -> dict:
    image = Image.open(path)
    data = np.asarray(image)
    tags = getattr(image, "tag_v2", {})
    ascii_tag = tags.get(34737)
    if isinstance(ascii_tag, bytes):
        ascii_tag = ascii_tag.decode("utf-8", errors="replace")
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
        "scale": list(tags.get(33550, ())),
        "tiepoint": list(tags.get(33922, ())),
        "sample_format": list(tags.get(339, ())),
        "bits_per_sample": list(tags.get(258, ())),
        "geo_keys": list(tags.get(34735, ())),
        "geo_ascii": ascii_tag,
        "geo_double": list(tags.get(34736, ())),
    }


def main() -> None:
    missions, _, mission_headers = row_dicts(ROOT / "research" / "missions.md")
    landers, _, lander_headers = row_dicts(ROOT / "research" / "vehicles.md", 5)
    rovers, _, rover_headers = row_dicts(ROOT / "research" / "vehicles.md", 22)
    orbital, _, orbital_headers = row_dicts(ROOT / "research" / "vehicles.md", 36)
    locations, _, location_headers = row_dicts(ROOT / "research" / "locations.md")

    mission_ids = [row["ID"] for row in missions]
    expected_ids = [f"M{i:02d}" for i in range(1, 23)] + [f"A{i:02d}" for i in range(1, 4)]
    vehicle_rows = landers + rovers + orbital
    vehicle_ids = [row["ID"] for row in vehicle_rows]
    declared_statuses = {"completed", "planned", "conditional", "proposed", "schedule_conflict", "portfolio_placeholder"}

    status_values, confidence_values, role_only_asset_rows = [], [], []
    for row in missions:
        parts = [p.strip().lower() for p in row["Status / confidence"].split(";")]
        if parts and parts[-1] in {"high", "medium", "low"}:
            status_values.append(parts[0].replace(" ", "_"))
            confidence_values.append(parts[-1])
        else:
            status_values.append("")
            confidence_values.append("")
            role_only_asset_rows.append({"id": row["ID"], "value": row["Status / confidence"]})

    placeholder = re.compile(
        r"\b(?:tbd|date not published|not fixed|none announced|no rover announced|no large named rover|"
        r"no named rover|individual dates tbd|providers and landers tbd|payloads tbd)\b", re.I
    )
    placeholder_fields = ["Target date", "Location or orbit", "Lander / carrier", "Rover or surface vehicle"]
    placeholder_counts = {field: sum(bool(placeholder.search(row[field])) for row in missions) for field in placeholder_fields}

    location_refs = {ref for row in locations for ref in mission_refs(row["Missions"])}
    vehicle_refs = {ref for row in vehicle_rows for ref in mission_refs(row["Missions"])}

    jp2 = ROOT / "luna2_direct_sim" / "raw" / "LDEM_4.JP2"
    direct_tif = ROOT / "luna2_direct_sim" / "site" / "luna2" / "materials" / "textures" / "heightmap.tif"
    twin_tif = ROOT / "luna2_twin" / ".cache" / "terrain" / "luna2" / "materials" / "textures" / "heightmap.tif"
    direct_data = np.asarray(Image.open(direct_tif))
    twin_data = np.asarray(Image.open(twin_tif))

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
            "mission_row_widths": sorted({len(row) for row in missions}),
            "invalid_statuses_against_data_model": sorted(set(status_values) - {""} - declared_statuses),
            "observed_statuses": sorted(set(status_values) - {""}),
            "confidence_counts": {value: confidence_values.count(value) for value in sorted(set(confidence_values)) if value},
            "role_only_asset_rows_in_status_confidence_column": role_only_asset_rows,
            "rows_with_missing_confidence": [row["ID"] for row, value in zip(missions, confidence_values) if not value],
            "placeholder_counts_by_field": placeholder_counts,
            "missing_primary_source_rows": [row["ID"] for row in missions if not urls(row["Primary source"])],
            "primary_source_link_count": {"min": min(len(urls(row["Primary source"])) for row in missions), "max": max(len(urls(row["Primary source"])) for row in missions)},
            "location_reference_ids_not_in_missions": sorted(location_refs - set(mission_ids)),
            "mission_ids_missing_from_locations": sorted(set(mission_ids) - location_refs),
            "vehicle_reference_ids_not_in_missions": sorted(vehicle_refs - set(mission_ids)),
            "mission_ids_without_vehicle_catalog_reference": sorted(set(mission_ids) - vehicle_refs),
            "vehicle_catalog_duplicate_ids": sorted({x for x in vehicle_ids if vehicle_ids.count(x) > 1}),
            "vehicle_catalog_reference_coverage": {"mission_ids_referenced": len(vehicle_refs), "mission_ids_total": len(set(mission_ids))},
            "source_urls_in_mission_register": sum(len(urls(row["Primary source"])) for row in missions),
        },
        "terrain_checks": {
            "rasters": [raster_profile(path) for path in (jp2, direct_tif, twin_tif)],
            "direct_vs_twin_array_comparison": {
                "same_shape": list(direct_data.shape) == list(twin_data.shape),
                "same_values_after_float_cast": bool(np.array_equal(direct_data.astype(np.float32), twin_data.astype(np.float32))),
                "max_abs_difference_m": float(np.max(np.abs(direct_data.astype(np.float64) - twin_data.astype(np.float64)))),
            },
            "metadata_center": {"lat": 32.4, "lon": -1.9},
            "raster_footprint_midpoint": {"lat": 32.5, "lon": -2.0},
            "center_offset_deg": {"lat": -0.1, "lon": 0.1},
            "missing_handover_artifacts": [
                f"luna2_twin/.cache/terrain/luna2/{name}"
                for name in ("luna2_sinus_lunicus_analysis.json", "luna2_sinus_lunicus_analysis.md")
                if not (ROOT / "luna2_twin" / ".cache" / "terrain" / "luna2" / name).exists()
            ],
            "external_surfacegenerator_source_present_in_workspace": (ROOT / "surfacegenerator").exists(),
        },
        "runtime_checks": {
            "scene_files": sorted(str(path.relative_to(ROOT)) for path in (ROOT / "luna2_twin" / "sim" / "scenes").glob("*.usda")),
            "default_scene_exists": (ROOT / "luna2_twin" / "sim" / "scenes" / "luna2_static.usda").exists(),
            "luna2_lit_parse_error_logged": "USD parse error" in (ROOT / "logs" / "luncosim-4103.err.log").read_text(encoding="utf-8", errors="replace"),
            "prior_swap_chain_timeout_logged": "swap chain texture: Timeout" in (ROOT / "logs" / "luncosim-4104.err.log").read_text(encoding="utf-8", errors="replace"),
            "direct_target_resolution_clamped": "target_res 8 out of range" in (ROOT / "logs" / "luncosim-direct-4107.err.log").read_text(encoding="utf-8", errors="replace"),
            "active_handover_reports_core_ready_but_bake_stuck": True,
        },
    }
    output = ROOT / "quality_audit_results_v2.json"
    output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
