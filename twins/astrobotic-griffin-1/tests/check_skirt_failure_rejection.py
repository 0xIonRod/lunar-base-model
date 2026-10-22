#!/usr/bin/env python3
"""Qualify skirt wall rejection using disposable USD document forks.

The caller owns the windowed authoring session and supplies the production
binary through LUNCOSIM_BIN. USD edits use the document API, never text edits.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import uuid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", type=Path, required=True)
    parser.add_argument("--author-port", type=int, required=True)
    parser.add_argument("--test-port", type=int, required=True)
    parser.add_argument("--case", choices=["zero_lower_wall", "excessive_lower_wall"], action="append")
    args = parser.parse_args()
    engine = args.engine.resolve()
    twin = Path(__file__).resolve().parents[1]
    sys.path.insert(0, str(engine / "scripts/api"))
    from runtime import port_is_open, request_json

    if args.author_port == args.test_port:
        parser.error("author and test ports must differ")
    binary = Path(os.environ.get("LUNCOSIM_BIN", engine / "target/debug/luncosim")).resolve()
    with binary.open("rb") as stream:
        binary_hash = hashlib.file_digest(stream, "sha256").hexdigest()
    out = twin / ".cache/skirt-failure-qualification"
    out.mkdir(parents=True, exist_ok=True)

    def command(command_name, **params):
        response = request_json(args.author_port, {
            "type": "ExecuteCommand", "command": command_name, "params": params,
        }, timeout_s=90)
        if response.get("error") or response.get("ok") is False:
            raise RuntimeError(response)
        return response["data"]

    def wait_for(read, accept, description):
        deadline = time.monotonic() + 90
        while True:
            value = read()
            if accept(value):
                return value
            if time.monotonic() >= deadline:
                raise RuntimeError("timed out waiting for " + description)
            time.sleep(.15)

    def documents():
        return command("ListOpenDocuments")["open_documents"]

    def preview_ready(doc, generation=None):
        wait_for(lambda: command("InspectUsdViewport")["previews"],
            lambda previews: any(p["doc_id"] == doc and p["projection_ready"] and p["text_ready"]
                and (generation is None or p["projected_generation"] == generation) for p in previews),
            "disposable skirt preview")

    source = twin / "tests/griffin_propulsion_requirements.usda"
    command("OpenFile", path=str(source))
    opened = wait_for(documents,
        lambda docs: any(d["origin"].get("path") == str(source) for d in docs), "source document")
    original = next(d for d in opened if d["origin"].get("path") == str(source))
    if original["dirty"]:
        raise RuntimeError("refusing to fork unsaved positive source")
    liner = "/World/Griffin1/Nozzle/MainEngineCluster/EngineSkirt/ThermalLiner"
    results = []
    for case in args.case or ["zero_lower_wall", "excessive_lower_wall"]:
        if port_is_open(args.test_port):
            raise RuntimeError("test port is occupied")
        # A restored document can still own a deleted scratch path. Give each
        # trial its own identity instead of reusing a stale document's address.
        target = twin / "tests" / ("_skirt_failure_qualification_" + case + "_" + uuid.uuid4().hex + ".usda")
        if target.exists():
            raise RuntimeError("disposable fixture already exists: " + str(target))
        doc = command("ForkDocument", source_doc_id=original["doc_id"], name="Skirt fault " + case)["doc_id"]
        try:
            command("InspectUsdEditSession", doc_id=doc)
            command("SaveAsDocument", doc_id=doc, path=str(target))
            command("OpenUsdPreview", preview=doc, doc_id=doc, edit_target="@root@")
            preview_ready(doc)
            before = command("QueryUsdPrim", doc_id=doc, path=liner, attrs=["points"])
            points = before["attrs"]["points"]
            if len(points) != 32:
                raise RuntimeError("expected the closed liner's four octagonal loops")
            points = [list(point) for point in points]
            # Outer lower loop 8..15 and inner lower loop 24..31 share Y.
            # The excessive case preserves the upper lip and all topology;
            # checking minimum stock alone therefore cannot detect it.
            for index in range(8, 16):
                if case == "zero_lower_wall":
                    points[index] = list(points[index + 16])
                else:
                    inner = points[index + 16]
                    points[index] = [inner[axis] + 4 * (points[index][axis] - inner[axis])
                        if axis != 1 else points[index][axis] for axis in range(3)]
            value = "[" + ", ".join("(" + ", ".join(map(str, point)) + ")" for point in points) + "]"
            receipt = command("ApplyUsdOps", doc_id=doc, ops=[{"SetAttribute": dict(
                edit_target="@root@", path=liner, name="points", type_name="point3f[]", value=value)}])
            if receipt.get("status") != "applied":
                raise RuntimeError(receipt)
            preview_ready(doc, receipt["generation"])
            readback = command("QueryUsdPrim", doc_id=doc, path=liner, attrs=["points"])
            command("SaveDocument", doc_id=doc)
            wait_for(documents, lambda docs: any(d["doc_id"] == doc and not d["dirty"] for d in docs),
                "saved fault document")
        except BaseException:
            target.unlink(missing_ok=True)
            raise
        finally:
            command("CloseDocument", doc_id=doc)
        try:
            log = out / (case + ".log")
            with log.open("w") as stream:
                process = subprocess.Popen([str(binary), "test", "--api", str(args.test_port),
                    "--scene", str(target), "--max-ticks", "300",
                    "--verdict-channel", "GRIFFIN_PROPULSION_REQUIREMENTS"], cwd=engine,
                    stdout=stream, stderr=subprocess.STDOUT, env=dict(os.environ,
                        LUNCO_ASSET_ROOT=str(engine / "assets"), LUNCOSIM_EPHEMERAL_SETTINGS="1"))
                print(case, "pid", process.pid, flush=True)
                try:
                    code = process.wait(timeout=300)
                except subprocess.TimeoutExpired:
                    request_json(args.test_port, {"type": "ExecuteCommand", "command": "Exit", "params": {}})
                    process.wait(timeout=30)
                    raise RuntimeError("trial timed out; timeout is not rejection evidence")
            reports = [json.loads(line.split(" ", 1)[1]) for line in log.read_text().splitlines()
                if line.startswith("LUNCO_SCENE_TEST_REPORT ")]
            report = reports[-1] if reports else {}
            events = [json.loads(line.split(" ", 1)[1]) for line in log.read_text().splitlines()
                if line.startswith("LUNCO_SCENE_TEST_EVIDENCE ")]
            checks = [event.get("data", {}).get("Map", {}).get("result", {}).get("Map", {})
                for event in events + report.get("non_pass_checks", [])]
            summaries = [event["data"]["Map"] for event in events
                if event.get("name") == "GRIFFIN_PROPULSION_REQUIREMENTS_EVIDENCE"]
            summary = summaries[-1] if summaries else {}
            rejected = code == 1 and summary.get("verdict", {}).get("String") == "fail" and any(
                check.get("id", {}).get("String") == "GES-002-finite-walls"
                and check.get("verdict", {}).get("String") == "fail" for check in checks)
            result = dict(case=case, exit_code=code, expected_rejection=rejected,
                receipt=receipt, readback=readback, report=report, final_summary=summary,
                failed_checks=[c for c in checks if c and c.get("verdict", {}).get("String") != "pass"])
            results.append(result)
            (out / "results.json").write_text(json.dumps(dict(binary_sha256=binary_hash, results=results), indent=2))
            if not rejected:
                raise RuntimeError("expected GES-002 geometry rejection was not produced; see " + str(log))
            print("PASS rejection", case, flush=True)
        finally:
            target.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
