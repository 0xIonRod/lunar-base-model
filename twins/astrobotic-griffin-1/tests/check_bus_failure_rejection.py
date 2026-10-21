#!/usr/bin/env python3
"""Require the bus gate to reject faults authored into disposable USD forks.

The authoring port must belong to the caller's own windowed production app.
All USD changes use its live document API. The supplied production binary is
reused for each serial headless trial; no build or USD text editing occurs.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", type=Path, required=True)
    parser.add_argument("--author-port", type=int, required=True)
    parser.add_argument("--test-port", type=int, required=True)
    parser.add_argument("--case", action="append", choices=["nested_collision", "nested_mass_owner", "hidden_deck"],
                        help="Run selected faults; default: all three")
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
    out = twin / ".cache/bus-failure-qualification"
    out.mkdir(parents=True, exist_ok=True)

    def command(command_name, **params):
        response = request_json(args.author_port, {
            "type": "ExecuteCommand", "command": command_name, "params": params,
        }, timeout_s=90)
        if response.get("error") or response.get("ok") is False:
            raise RuntimeError(response)
        return response["data"]

    def documents():
        return command("ListOpenDocuments")["open_documents"]

    def preview_ready(doc, generation=None):
        if generation is None:
            command("OpenUsdPreview", preview=doc, doc_id=doc, edit_target="@root@")
        deadline = time.monotonic() + 90
        while True:
            previews = command("InspectUsdViewport")["previews"]
            if any(p["doc_id"] == doc and p["projection_ready"] and p["text_ready"]
                    and (generation is None or p["projected_generation"] == generation) for p in previews):
                return
            if time.monotonic() > deadline:
                raise RuntimeError("disposable preview did not compose")
            time.sleep(.15)

    source = twin / "tests/griffin_bus_requirements.usda"
    command("OpenFile", path=str(source))
    deadline = time.monotonic() + 30
    while not any(d["origin"].get("path") == str(source) for d in documents()):
        if time.monotonic() > deadline:
            raise RuntimeError("positive bus document did not open")
        time.sleep(.1)
    original = next(d for d in documents() if d["origin"].get("path") == str(source))
    if original["dirty"]:
        raise RuntimeError("refusing to fork unsaved positive source")
    nested = "/World/Griffin1/Bus/TankSupportPlate/OpeningTankPXUpper"
    cases = [
        ("nested_collision", "GBC-003-physics-ownership", nested, "physics:collisionEnabled", "bool", "true"),
        ("nested_mass_owner", "GBC-003-physics-ownership", nested, None, None, None),
        ("hidden_deck", "GBC-001-visible-component-identity", "/World/Griffin1/Bus/TopDeckOctagon", "visibility", "token", '"invisible"'),
    ]
    results = []
    previous = out / "results.json"
    if args.case and previous.exists():
        retained = json.loads(previous.read_text())
        if retained["binary_sha256"] != binary_hash:
            raise RuntimeError("selected rerun would mix executable identities")
        results = [r for r in retained["results"] if r["case"] not in args.case]
    for label, expected_check, path, attribute, usd_type, value in cases:
        if args.case and label not in args.case:
            continue
        if port_is_open(args.test_port):
            raise RuntimeError("test port is occupied")
        target = twin / "tests" / ("_bus_failure_" + label + ".usda")
        if target.exists():
            raise RuntimeError("disposable fixture already exists: " + str(target))
        fork = command("ForkDocument", source_doc_id=original["doc_id"], name="Bus fault " + label)
        doc = fork["doc_id"]
        try:
            session = command("InspectUsdEditSession", doc_id=doc)
            command("SaveAsDocument", doc_id=doc, path=str(target))
            preview_ready(doc)
            before = command("QueryUsdPrim", doc_id=doc, path=path, schemas=True)
            if before.get("active") is not True:
                raise RuntimeError("fault target is not active: " + str(before))
            if attribute:
                ops = [{"SetAttribute": dict(edit_target="@root@", path=path,
                    name=attribute, type_name=usd_type, value=value)}]
            else:
                ops = [{"SetApiSchemas": dict(edit_target="@root@", path=path,
                    schemas=before["api_schemas"] + ["PhysicsMassAPI"])}]
            receipt = command("ApplyUsdOps", doc_id=doc, ops=ops)
            if receipt.get("status") != "applied":
                raise RuntimeError(receipt)
            preview_ready(doc, receipt["generation"])
            readback = command("QueryUsdPrim", doc_id=doc, path=path, schemas=True)
            command("SaveDocument", doc_id=doc)
            deadline = time.monotonic() + 30
            while next(d for d in documents() if d["doc_id"] == doc)["dirty"]:
                if time.monotonic() > deadline:
                    raise RuntimeError("disposable fixture save did not finish")
                time.sleep(.1)
        except BaseException:
            target.unlink(missing_ok=True)
            raise
        finally:
            command("CloseDocument", doc_id=doc)
        try:
            log = out / (label + ".log")
            with log.open("w") as stream:
                process = subprocess.Popen([str(binary), "test", "--api", str(args.test_port),
                    "--scene", str(target)], cwd=engine, stdout=stream, stderr=subprocess.STDOUT,
                    env=dict(os.environ, LUNCO_ASSET_ROOT=str(engine / "assets"), LUNCOSIM_EPHEMERAL_SETTINGS="1"))
                print(label, "pid", process.pid, flush=True)
                try:
                    code = process.wait(timeout=300)
                except subprocess.TimeoutExpired:
                    process.terminate()
                    process.wait(timeout=15)
                    raise RuntimeError("trial timed out; timeout is not rejection evidence")
            reports = [json.loads(line.split(" ", 1)[1]) for line in log.read_text().splitlines()
                if line.startswith("LUNCO_SCENE_TEST_REPORT ")]
            report = reports[-1] if reports else {}
            events = [json.loads(line.split(" ", 1)[1]) for line in log.read_text().splitlines()
                if line.startswith("LUNCO_SCENE_TEST_EVIDENCE ")]
            checks = []
            for event in events + report.get("non_pass_checks", []):
                payload = event.get("data", {}).get("Map", {}).get("result", {}).get("Map", {})
                if payload:
                    checks.append(payload)
            summaries = [event["data"]["Map"] for event in events
                if event.get("name") == "GRIFFIN_BUS_REQUIREMENTS_EVIDENCE"]
            final_verdict = summaries[-1].get("verdict", {}).get("String") if summaries else None
            rejected = code == 1 and final_verdict == "fail" and any(
                c.get("id", {}).get("String") == expected_check
                and c.get("verdict", {}).get("String") == "fail" for c in checks)
            result = dict(case=label, exit_code=code, expected_rejection=rejected,
                session=session, operations=ops, receipt=receipt, readback=readback, report=report,
                failed_checks=[c for c in checks if c.get("verdict", {}).get("String") != "pass"],
                final_summary=summaries[-1] if summaries else None)
            results.append(result)
            revisions = {r["final_summary"]["source_revision"]["U64"] for r in results
                if r.get("expected_rejection") and r.get("final_summary")}
            if len(revisions) > 1:
                raise RuntimeError("selected rerun would mix SysML source revisions")
            (out / "results.json").write_text(json.dumps(dict(binary_sha256=binary_hash, results=results), indent=2))
            if not rejected:
                raise RuntimeError("expected typed failing check was not produced: " + str(report)[:2000])
            print("PASS rejection", label, flush=True)
        finally:
            target.unlink(missing_ok=True)
    print("PASS: selected bus fault cases rejected" if args.case else "PASS: three bus fault cases rejected", flush=True)


if __name__ == "__main__":
    main()
