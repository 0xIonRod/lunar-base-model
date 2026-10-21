#!/usr/bin/env python3
"""Cut one production connection per disposable USD fork and require rejection.

The supplied authoring port must belong to your own windowed LunCoSim session
with this Twin open. USD changes use its document API; no USD text is written.
The engine checkout supplies the shared API transport and production binary.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time


def qualifies(name, code, evidence, rejection):
    net = "/Griffin1SurfaceOps/Lander/ElectricalPower"
    panel = net + "/SolarPanelForward"
    if rejection and rejection["owner"]["name"] == net \
            and rejection["readiness"]["world_hold"] and not rejection["readiness"]["ready"]:
        error = rejection["owner"]["modelica_error"]
        if name == "temperature_feedback":
            return panel + ".inputs:cell_temperature_k" in error
        if name == "electrical_connection":
            return panel in error and "acausal connector that nothing connects to" in error
    expected = "gep003" if name == "electrical_connection" else "gep002"
    for event in evidence:
        if event["name"] != "GRIFFIN_POWER_THERMAL_EVIDENCE_RESULT":
            continue
        # Consume the transport's tagged TelemetryValue fields directly;
        # malformed evidence is an error, never a substitute for rejection.
        result = event["data"]["Map"]["result"]["Map"]
        if code == 1 and result["requirement"]["String"] == "GriffinPowerThermalRequirements::" + expected \
                and result["verdict"]["String"] == "fail":
            return True
    return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", type=Path, required=True)
    parser.add_argument("--author-port", type=int, required=True)
    parser.add_argument("--test-port", type=int, required=True)
    parser.add_argument("--case", action="append", choices=["temperature_feedback",
        "thermal_connection", "radiation_connection", "electrical_connection"], help="Run only named faults; default: all four")
    args = parser.parse_args()
    engine = args.engine.resolve()
    twin = Path(__file__).resolve().parents[1]
    sys.path.insert(0, str(engine / "scripts/api"))
    from runtime import request_json

    binary = Path(os.environ.get("LUNCOSIM_BIN", engine / "target/debug/luncosim")).resolve()
    out = twin / ".cache/power-failure-qualification"
    out.mkdir(parents=True, exist_ok=True)
    if args.test_port == args.author_port:
        parser.error("author and test ports must differ")

    def command(command_name, **params):
        result = request_json(args.author_port, {
            "type": "ExecuteCommand", "command": command_name, "params": params,
        }, timeout_s=90)
        if result.get("error") or result.get("ok") is False:
            raise RuntimeError(result)
        return result["data"]

    def documents():
        return command("ListOpenDocuments")["open_documents"]

    source = twin / "tests/griffin_power_thermal.usda"
    command("OpenFile", path=str(source))
    deadline = time.monotonic() + 30
    while not any(d["origin"].get("path") == str(source) for d in documents()):
        if time.monotonic() > deadline:
            raise RuntimeError("positive control document did not open")
        time.sleep(0.1)
    original = next(d for d in documents() if d["origin"].get("path") == str(source))
    if original["dirty"]:
        raise RuntimeError("positive source has unsaved changes; refusing to fork")

    net = "/Griffin1SurfaceOps/Lander/ElectricalPower"
    panel = net + "/SolarPanelForward"
    cuts = {
        "temperature_feedback": dict(path=panel, name="inputs:cell_temperature_k",
                                     type_name="double", sources=[]),
        "thermal_connection": dict(path=panel + "Mass", name="connectors:port",
            type_name="token", sources=[panel + "Cooler.connectors:port",
                panel + "SkyRadiation.connectors:port", panel + "GroundRadiation.connectors:port"]),
        "radiation_connection": dict(path=panel + "Mass", name="connectors:port",
            type_name="token", sources=[panel + "Heat.connectors:port",
                panel + "Cooler.connectors:port", panel + "GroundRadiation.connectors:port"]),
        "electrical_connection": dict(path=net + "/Battery", name="connectors:p",
            type_name="token", sources=[net + "/AvionicsLoad.connectors:p",
                net + "/SolarPanelFrontStarboard.connectors:p",
                net + "/SolarPanelFrontPort.connectors:p"]),
    }
    # Pin the same vehicle/equations and executable across all fault trials.
    def hashes():
        return {str(p.relative_to(twin)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(twin.rglob("*")) if p.is_file()
            and not {".cache", ".lunco", "terrain", "handover"}.intersection(p.relative_to(twin).parts)
            and not p.name.startswith("_power_failure_")
            and p.suffix in {".usda", ".usd", ".usdc", ".sysml", ".rhai", ".mo", ".toml"}}

    source_hashes = hashes()
    binary_hash = hashlib.sha256(binary.read_bytes()).hexdigest()
    results = []
    for name, cut in cuts.items():
        if args.case and name not in args.case:
            continue
        if hashes() != source_hashes or hashlib.sha256(binary.read_bytes()).hexdigest() != binary_hash:
            raise RuntimeError("source or binary changed during qualification")
        # CLI startup admits indexed Twin scenes. Cache directories are not
        # indexed, so put generated forks in the existing tests/*.usda source
        # scope with an explicit ignored prefix.
        target = twin / "tests" / ("_power_failure_" + name + ".usda")
        for doc in documents():
            if doc["origin"].get("path") == str(target):
                if doc["dirty"]:
                    raise RuntimeError("negative fixture has unsaved changes")
                command("CloseDocument", doc_id=doc["doc_id"])
        fork = command("ForkDocument", source_doc_id=original["doc_id"], name="Power fault " + name)
        doc = fork["doc_id"]
        try:
            command("SaveAsDocument", doc_id=doc, path=str(target))
            operation = {"SetConnection": dict(edit_target="@root@", **cut)}
            receipt = command("ApplyUsdOps", doc_id=doc, ops=[operation])
            if receipt.get("status") != "applied":
                raise RuntimeError(receipt)
            command("SaveDocument", doc_id=doc)
            # SaveDocument is asynchronous; a clean registry state acknowledges persistence.
            deadline = time.monotonic() + 30
            while next(d for d in documents() if d["doc_id"] == doc)["dirty"]:
                if time.monotonic() > deadline:
                    raise RuntimeError("negative fixture save did not finish")
                time.sleep(0.1)
        finally:
            command("CloseDocument", doc_id=doc)
        with socket.socket() as sock:
            if sock.connect_ex(("127.0.0.1", args.test_port)) == 0:
                raise RuntimeError("test port is already in use")
        log_path = out / (name + ".log")
        env = dict(os.environ, LUNCO_ASSET_ROOT=str(engine / "assets"),
                   LUNCOSIM_EPHEMERAL_SETTINGS="1")
        # No --verification: the registry intentionally maps that identity to
        # the unmodified positive fixture, never to these malformed forks.
        with log_path.open("w") as log:
            process = subprocess.Popen([str(binary), "test", "--api", str(args.test_port),
                "--scene", str(target)], cwd=engine, env=env, stdout=log, stderr=subprocess.STDOUT)
            print(name, "pid", process.pid, flush=True)
            deadline = time.monotonic() + 900
            rejection = None
            while process.poll() is None:
                if time.monotonic() > deadline:
                    process.terminate()
                    process.wait(timeout=15)
                    raise RuntimeError("fault trial timed out; timeout is not rejection evidence")
                try:
                    status = request_json(args.test_port, {
                        "type": "ExecuteCommand", "command": "CosimStatus", "params": {},
                    }, timeout_s=5)["data"]
                    owner = next((e for e in status["entities"] if e["name"] == net), None)
                    if owner and owner["status"].startswith("Error:") and owner.get("modelica_error"):
                        ready = request_json(args.test_port, {"type": "ExecuteCommand",
                            "command": "GetReadiness", "params": {}}, timeout_s=5)["data"]
                        rejection = dict(owner=owner, readiness=ready)
                        request_json(args.test_port, {"type": "ExecuteCommand",
                            "command": "Exit", "params": {}}, timeout_s=5)
                        break
                except (RuntimeError, OSError, TimeoutError):
                    # API admission may lag process startup or retire after a
                    # terminal report. Neither observation proves rejection.
                    pass
                time.sleep(0.5)
            code = process.wait(timeout=15)
        lines = log_path.read_text().splitlines()
        report = next((json.loads(line.split(" ", 1)[1])
            for line in reversed(lines)
            if line.startswith("LUNCO_SCENE_TEST_REPORT ")), None)
        evidence = [json.loads(line.split(" ", 1)[1]) for line in lines
            if line.startswith("LUNCO_SCENE_TEST_EVIDENCE ")]
        if report is None and rejection is None and not evidence:
            raise RuntimeError("missing production scene report: " + str(log_path))
        # A negative result must be caused by this subsystem, not an unrelated
        # source failure, crash, timeout or test-selection error.
        diagnostic = rejection["owner"]["modelica_error"] if rejection else (report or {}).get("runner_diagnostic")
        accepted = qualifies(name, code, evidence, rejection)
        results.append(dict(name=name,expected_rejection=accepted,exit_code=code,
            operation=operation,scene_sha256=hashlib.sha256(target.read_bytes()).hexdigest(),
            admission_rejection=rejection,report=report,evidence=evidence))
        (out / "results.json").write_text(json.dumps(dict(binary_sha256=binary_hash,
            source_hashes=source_hashes,results=results), indent=2))
        print(name, "expected rejection:", accepted, diagnostic, flush=True)
        if not accepted:
            raise RuntimeError("unexpected fault result; inspect " + str(log_path))
    if hashes() != source_hashes:
        raise RuntimeError("sources changed during qualification")
    print("PASS:", len(results), "production fault rejection(s); evidence:", out)


if __name__ == "__main__":
    main()
