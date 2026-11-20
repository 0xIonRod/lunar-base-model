#!/usr/bin/env python3
"""Qualify a Twin package with one pinned LunCoSim source and shared asset set.

No builds or USD edits are performed here. Optional dataset provisioning uses
the pinned LunCoSim Nightly runtime's native API. Native preflight and registered
scene verdicts remain separate, required gates; a timeout or missing report
never qualifies a release.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import socket
import subprocess
import sys
import time
import tomllib

from validate_repository import ROOT, validate_twin


def git(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()


def sha256(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def source_digest(twin: Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(twin.rglob("*"), key=lambda entry: entry.relative_to(twin).as_posix()):
        relative = path.relative_to(twin)
        if not path.is_file() or {".cache", ".lunco", "__pycache__", "results"}.intersection(relative.parts):
            continue
        if relative == Path("QUALIFICATION.json"):
            continue
        digest.update(relative.as_posix().encode("utf-8") + b"\0")
        digest.update(bytes.fromhex(sha256(path)))
    return digest.hexdigest()


def require_free_port(port: int) -> None:
    with socket.socket() as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind(("127.0.0.1", port))


def check_engine(engine: Path, expected: str) -> None:
    actual = git(engine, "rev-parse", "HEAD")
    if actual != expected:
        raise RuntimeError(f"engine revision {actual} does not match qualification pin {expected}")
    dirty = git(engine, "status", "--porcelain", "--untracked-files=normal")
    if dirty:
        raise RuntimeError(f"engine source/assets must be clean for release qualification:\n{dirty}")


def native_preflight(engine: Path, binary: Path, twin: Path, output: Path, port: int,
                     expected: str, scenes: set[str], twin_name: str) -> None:
    os.environ.update(LUNCOSIM_BIN=str(binary), LUNCO_ASSET_ROOT=str(engine / "assets"),
                      LUNCOSIM_EPHEMERAL_SETTINGS="1", LUNCOSIM_ISOLATED_RUN="1",
                      LUNCOSIM_API_READY_TIMEOUT_S="240")
    sys.path.insert(0, str(engine / "scripts/api"))
    from runtime import ProductionSession

    reports = []
    log_path = output / "native-preflight.log"
    with ProductionSession(port, log_path=log_path,
                           extra_args=["--no-load-default-scene"]) as session:
        identity = re.search(r"\[lunco\] luncosim \S+ \(([^)]+)\)", log_path.read_text(errors="replace"))
        if identity is None or identity.group(1) != git(engine, "rev-parse", "--short=8", expected):
            raise RuntimeError("production binary build identity does not match the clean pinned checkout")

        def query(name: str, params: dict) -> dict:
            response = session.post({"type": "ExecuteCommand", "command": name, "params": params})
            if response.get("error") or response.get("ok") is False:
                raise RuntimeError(f"{name} rejected: {response}")
            result = response.get("data")
            if not isinstance(result, dict):
                raise RuntimeError(f"{name} returned no typed report envelope: {response}")
            return result

        def validate(name: str, params: dict) -> dict:
            envelope = query(name, params)
            deadline = time.monotonic() + 240
            while envelope.get("state") == "pending":
                operation = envelope.get("operation_id")
                if not isinstance(operation, int) or time.monotonic() >= deadline:
                    raise RuntimeError(f"{name} preparation did not finish: {envelope}")
                time.sleep(0.25)
                envelope = query(name, {"operation_id": operation})
            reports.append({"query": name, "params": params, "result": envelope})
            (output / "native-preflight.json").write_text(json.dumps(reports, indent=2) + "\n")
            if envelope.get("state") != "ready" or envelope.get("report", {}).get("ok") is not True:
                raise RuntimeError(f"{name} failed: {envelope}")
            return envelope["report"]

        query("OpenTwin", {"path": str(twin)})
        deadline = time.monotonic() + 60
        while True:
            workspace = query("ReadActiveWorkspace", {})
            if workspace.get("open") is True and Path(workspace.get("root", "")).resolve() == twin:
                break
            if time.monotonic() >= deadline:
                raise RuntimeError(f"Twin source opening did not finish: {workspace}")
            time.sleep(0.1)
        contract = query("ReadActiveTwinContract", {})
        if contract.get("open") is not True or contract.get("name") != twin_name:
            raise RuntimeError(f"Wrong Twin source contract admitted: {contract}")
        validate("ValidateTwin", {"path": str(twin), "policy": "error"})
        # The source-set URI validates every indexed requirement file under
        # the mounted Twin, including packages not imported by its entry file.
        deadline = time.monotonic() + 240
        while True:
            analysis = query("AnalyzeSysml", {"path": "twin://" + twin_name, "tables": []})
            if analysis.get("state") == "ready" and analysis.get("ok") is True:
                break
            if analysis.get("state") != "pending" or time.monotonic() >= deadline:
                raise RuntimeError(f"Twin SysML analysis did not become ready: {analysis}")
            time.sleep(0.25)
        source_revision = analysis["analysis"]["source_revision"]
        sysml = validate("ValidateSysml", {"path": "twin://" + twin_name})
        if sysml.get("source_revision") != source_revision:
            raise RuntimeError("Twin SysML analysis changed during validation")
        if sysml.get("ok") is not True or not sysml.get("source_files") or type(sysml.get("source_revision")) is not int:
            raise RuntimeError(f"Twin SysML source-set validation failed: {sysml}")
        for scene in sorted(scenes):
            validate("ValidateAsset", {"path": str(twin / scene)})
    require_free_port(port)


def report_passes(report: dict, code: int, verification: str, channel: str) -> bool:
    """Accept one current-source, terminal native process-boundary report."""
    return isinstance(report, dict) and code == 0 and type(report.get("schema_version")) is int \
        and report.get("schema_version") == 2 \
        and report.get("verification") == verification \
        and report.get("process_status") == "verdict_produced" \
        and type(report.get("process_exit_code")) is int and report.get("process_exit_code") == 0 \
        and report.get("verdict_channel") == channel \
        and str(report.get("verdict", "")).lower() == "pass" \
        and type(report.get("source_revision_at_start")) is int \
        and type(report.get("source_revision_at_end")) is int \
        and report.get("source_revision_at_start") == report.get("source_revision_at_end") \
        and report.get("runner_diagnostic") is None and report.get("non_pass_checks") == []


def provision_twin_datasets(engine: Path, binary: Path, twin: Path,
                            datasets: list[str], output: Path, port: int) -> None:
    """Prepare declared Twin assets using the Nightly app's built-in provisioner."""
    os.environ.update(LUNCOSIM_BIN=str(binary), LUNCO_ASSET_ROOT=str(engine / "assets"),
                      LUNCOSIM_EPHEMERAL_SETTINGS="1", LUNCOSIM_ISOLATED_RUN="1",
                      LUNCOSIM_API_READY_TIMEOUT_S="240")
    sys.path.insert(0, str(engine / "scripts/api"))
    from runtime import ProductionSession

    log_path = output / "dataset-provisioning.log"
    with ProductionSession(port, log_path=log_path, windowed=True,
                           extra_args=["--no-load-default-scene"]) as session:
        def execute(name: str, params: dict | None = None) -> dict:
            response = session.post({"type": "ExecuteCommand", "command": name,
                                     "params": params or {}})
            if response.get("error") or response.get("ok") is False:
                raise RuntimeError(f"{name} rejected: {response}")
            result = response.get("data")
            if not isinstance(result, dict):
                raise RuntimeError(f"{name} returned no typed result: {response}")
            return result

        execute("OpenTwin", {"path": str(twin)})
        deadline = time.monotonic() + 60
        while True:
            workspace = execute("ReadActiveWorkspace")
            if workspace.get("open") is True and Path(workspace.get("root", "")).resolve() == twin:
                break
            if time.monotonic() >= deadline:
                raise RuntimeError(f"Twin source opening did not finish: {workspace}")
            time.sleep(0.1)

        def find_dataset(key: str) -> dict | None:
            rows = execute("ListDatasets").get("datasets", [])
            return next((row for row in rows
                         if row.get("scope", "").startswith("twin:")
                         and row.get("key") == key), None)

        def wait_installed(key: str, timeout: float = 1200) -> dict:
            deadline = time.monotonic() + timeout
            last = None
            while time.monotonic() < deadline:
                last = find_dataset(key)
                if last is not None:
                    state = last.get("state", {})
                    if state.get("kind") == "failed":
                        raise RuntimeError(f"dataset {key} failed: {state.get('error', state)}")
                    if state.get("kind") == "installed":
                        return last
                time.sleep(0.5)
            raise RuntimeError(f"dataset {key} did not become ready within {timeout:g}s; last={last}")

        def wait_processed(key: str, timeout: float = 1200) -> dict:
            deadline = time.monotonic() + timeout
            last = None
            while time.monotonic() < deadline:
                last = find_dataset(key)
                if last is not None:
                    state = last.get("state", {})
                    if state.get("kind") == "failed":
                        raise RuntimeError(f"dataset {key} processing failed: {state.get('error', state)}")
                    if key == "nobile03_dem":
                        outputs = (
                            twin / ".cache/terrain/nobile03/materials/textures/heightmap.tif",
                            twin / ".cache/terrain/nobile03/materials/textures/albedo.png",
                            twin / ".cache/terrain/nobile03/materials/textures/coverage.png",
                            twin / ".cache/terrain/nobile03/.bakekey",
                        )
                        if state.get("kind") == "installed" and all(
                            path.is_file() and path.stat().st_size > 0 for path in outputs
                        ):
                            return last
                time.sleep(0.5)
            raise RuntimeError(f"dataset {key} outputs were not published within {timeout:g}s; last={last}")

        for key in datasets:
            deadline = time.monotonic() + 120
            row = None
            while time.monotonic() < deadline:
                row = find_dataset(key)
                if row is not None:
                    break
                time.sleep(0.25)
            if row is None:
                raise RuntimeError(f"Twin did not declare required dataset {key}")
            if row.get("processed") is not True:
                raise RuntimeError(f"dataset {key} has no native processing recipe")

            if row.get("state", {}).get("kind") in {"missing", "failed", "cancelled"}:
                execute("RequestDataset", {"id": row["id"]})
            row = wait_installed(key)

            print(f"Processing Twin dataset {key}", flush=True)
            execute("ProcessDataset", {"id": row["id"], "force": False})
            wait_processed(key)
            print(f"Twin dataset ready: {key}", flush=True)


def run_case(engine: Path, binary: Path, twin: Path, case: dict, mapping: dict,
             output: Path, port: int, env: dict[str, str]) -> dict:
    require_free_port(port)
    name = case["verification"]
    log_path = output / (name.replace("::", "_") + ".log")
    argv = [str(binary), "test", "--scene", str(twin / mapping["scene"]),
            "--verification", name, "--verdict-channel", mapping["verdict_channel"],
            "--max-ticks", str(case["max_ticks"]), "--tick-hz", "60", "--threads", "1",
            "--jitter", "0", "--readiness-timeout", "240", "--api", str(port)]
    started = time.monotonic()
    with log_path.open("w") as log:
        process = subprocess.Popen(argv, cwd=engine, env=env, stdout=log, stderr=subprocess.STDOUT)
        try:
            code = process.wait(timeout=1200)
        except subprocess.TimeoutExpired:
            # Send the owned process its normal Exit command before reaping it.
            from runtime import request_json
            try:
                request_json(port, {"type": "ExecuteCommand", "command": "Exit", "params": {}})
                process.wait(timeout=15)
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait()
            raise RuntimeError(f"{name}: wall timeout; no qualified verdict; log={log_path}")
    require_free_port(port)
    lines = log_path.read_text(errors="replace").splitlines()
    prefix = "LUNCO_SCENE_TEST_REPORT "
    reports = [json.loads(line[len(prefix):]) for line in lines if line.startswith(prefix)]
    result = {"verification": name, "exit_code": code,
              "elapsed_s": round(time.monotonic() - started, 3), "log": log_path.name}
    if len(reports) != 1:
        raise RuntimeError(f"{name}: expected one native verification report, found {len(reports)}; log={log_path}")
    report = reports[0]
    result["report"] = report
    if not report_passes(report, code, name, mapping["verdict_channel"]):
        raise RuntimeError(f"{name}: native verification did not pass: {report}; log={log_path}")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", type=Path, required=True)
    parser.add_argument("--config", type=Path, default=ROOT / "tools/qualification.toml")
    parser.add_argument("--twin", type=Path)
    parser.add_argument("--output", type=Path, default=ROOT / "runs/qualification")
    parser.add_argument("--api-port", type=int, default=4299)
    parser.add_argument("--provision", action="store_true", help="Download/process declared datasets with the pinned LunCoSim Nightly runtime")
    args = parser.parse_args()
    config = tomllib.loads(args.config.read_text(encoding="utf-8"))
    if config.get("schema_version") != 1:
        raise RuntimeError("unsupported qualification config schema_version")
    expected = config["engine"]["revision"]
    if not re.fullmatch(r"[0-9a-f]{40}", expected):
        raise RuntimeError("qualification engine revision must be a full Git SHA")
    engine = args.engine.resolve()
    twin = (args.twin or ROOT / config["twin"]).resolve()
    output = args.output.resolve()
    if output.is_relative_to(twin):
        raise RuntimeError("qualification output must be outside the Twin package")
    output.mkdir(parents=True, exist_ok=True)
    receipt = output / "QUALIFICATION.json"
    receipt.unlink(missing_ok=True)
    check_engine(engine, expected)
    errors = validate_twin(twin)
    if errors:
        raise RuntimeError("Twin manifest/package validation failed:\n" + "\n".join(errors))
    manifest = tomllib.loads((twin / "twin.toml").read_text(encoding="utf-8"))
    mappings = {case["name"]: case for case in manifest["verification"]["cases"]}
    cases = config["cases"]
    if not cases or len({case["verification"] for case in cases}) != len(cases):
        raise RuntimeError("qualification cases must be non-empty and unique")
    for case in cases:
        if case["verification"] not in mappings or type(case["max_ticks"]) is not int or case["max_ticks"] <= 0:
            raise RuntimeError(f"invalid or unregistered qualification case: {case}")
    suffix = ".exe" if os.name == "nt" else ""
    binary = engine / "target/debug" / ("luncosim" + suffix)
    if not binary.is_file():
        raise RuntimeError("install the pinned LunCoSim Nightly runtime before qualification")
    env = dict(os.environ, LUNCOSIM_BIN=str(binary), LUNCO_ASSET_ROOT=str(engine / "assets"),
               LUNCOSIM_EPHEMERAL_SETTINGS="1", LUNCOSIM_ISOLATED_RUN="1")
    source = source_digest(twin)
    binaries = {str(binary.relative_to(engine)): sha256(binary)}
    if args.provision:
        provision_twin_datasets(engine, binary, twin, config["datasets"], output, args.api_port)
    scenes = {mapping["scene"] for mapping in mappings.values()} | {manifest["usd"]["default_scene"]}
    native_preflight(engine, binary, twin, output, args.api_port, expected, scenes, manifest["name"])
    results = []
    for case in cases:
        print("Qualifying", case["verification"], flush=True)
        results.append(run_case(engine, binary, twin, case, mappings[case["verification"]], output, args.api_port, env))
        (output / "gate-results.json").write_text(json.dumps(results, indent=2) + "\n")
    check_engine(engine, expected)
    if source_digest(twin) != source or any(sha256(engine / path) != digest for path, digest in binaries.items()):
        raise RuntimeError("Twin sources or production binaries changed during qualification")
    result = {"schema_version": 1, "qualified_at_utc": datetime.now(timezone.utc).isoformat(),
              "twin": manifest["name"], "twin_source_sha256": source,
              "engine_repository": config["engine"]["repository"], "engine_revision": expected,
              "binaries_sha256": binaries, "native_preflight": "pass", "gates": results,
              "runtime_platform": sys.platform, "terrain_included": False}
    receipt.write_text(json.dumps(result, indent=2) + "\n")
    print("Qualified:", receipt)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (KeyError, OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"QUALIFICATION FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
