#!/usr/bin/env python3
"""Read-only comparison of a running FLIP with public nameplate specifications.

Run with the FLIP scene already playing:
  python tests/check_flip_public_power.py --port 4202 --output power-result.json
No scene changes, input overrides, pause/resume or hardware commands are issued.
Passing validates nameplate agreement and observed consistency, not flight fidelity.
"""
import argparse
import datetime
import json
import math
from pathlib import Path
import time
import urllib.request

SOURCE = ("https://www.linkedin.com/posts/astrolabspace_our-flip-rover-is-equipped-"
          "with-a-622-kwh-activity-7508563602279309312-W5Le")
NAMES = ["bus_voltage", "bus_current", "bus_power", "battery_soc", "solar_power",
         "solar_available_power", "solar_temperature_k", "solar_cos_incidence"]


def outputs(batch):
    rows = batch["entities"][0]["ports"]
    result = {}
    for name in NAMES:
        matches = [p for p in rows if p["name"] == name and p["direction"] == "out"]
        if len(matches) != 1:
            raise ValueError(f"Expected exactly one output for {name}")
        row = matches[0]
        if row["metadata"].get("authority") != "solver":
            raise ValueError(f"{name} is not a solver observation")
        value = row["value"]
        if not isinstance(value, (int, float)) or not math.isfinite(value):
            raise ValueError(f"Missing/nonfinite {name}: {value}")
        result[name] = value
    return result


def evaluate(battery, solar, batches):
    checks = []

    def check(name, passed, detail):
        checks.append(dict(name=name, passed=bool(passed), detail=detail))

    energy = battery["attrs"]["inputs:capacity"] * battery["attrs"]["inputs:voltage_nom"]
    # These are numerical regression allowances, not manufacturer tolerances.
    check("published_battery_energy", abs(energy - 6220) <= 1.0,
          dict(observed_wh=energy, published_wh=6220, numerical_allowance_wh=1.0))
    peak = solar["attrs"]["parameters:peak_power_rating_w"]
    check("rounded_public_solar_rating", abs(peak - 270) <= 0.01,
          dict(observed_w=peak, rounded_public_w=270, numerical_allowance_w=0.01))
    values = [outputs(b) for b in batches]
    check("simulation_advances", all(b["sim_tick"] > a["sim_tick"]
          for a, b in zip(batches, batches[1:])),
          dict(first_tick=batches[0]["sim_tick"], last_tick=batches[-1]["sim_tick"]))
    check("soc_bounds", all(0 <= v["battery_soc"] <= 1 for v in values), "SOC in [0,1]")
    check("incidence_bounds", all(0 <= v["solar_cos_incidence"] <= 1 for v in values),
          "Clamped incidence cosine in [0,1]")
    residuals = [abs(v["bus_power"] - v["bus_voltage"] * v["bus_current"]) for v in values]
    check("terminal_power_arithmetic", max(residuals) <= 0.05,
          dict(max_residual_w=max(residuals), numerical_allowance_w=0.05))
    check("solar_delivery_bound", all(0 <= v["solar_power"] <= v["solar_available_power"] + 0.01
          for v in values), "Delivered solar power is nonnegative and does not exceed availability")
    check("positive_voltage_and_temperature", all(v["bus_voltage"] > 0 and
          v["solar_temperature_k"] > 0 for v in values), "Positive bus voltage and absolute cell temperature")
    # Require an informative interval away from the battery saturation bounds.
    # Do not infer simulated seconds from wall-clock time or assume a tick rate.
    currents = [v["bus_current"] for v in values]
    delta = values[-1]["battery_soc"] - values[0]["battery_soc"]
    interior = all(0.001 < v["battery_soc"] < 0.999 for v in values)
    same_sign = min(currents) > 0.01 or max(currents) < -0.01
    check("battery_responds_to_current", interior and same_sign and delta * currents[0] > 0,
          dict(soc_delta=delta, current_min_a=min(currents), current_max_a=max(currents),
               prerequisite="Interior SOC and stable current sign; otherwise rerun under steady load/charge"))
    return checks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=4202)
    parser.add_argument("--root", default="/Griffin1SurfaceOps/FLIP")
    parser.add_argument("--samples", type=int, default=12)
    parser.add_argument("--interval", type=float, default=0.5)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.samples < 2 or not math.isfinite(args.interval) or args.interval <= 0:
        parser.error("Need at least two samples and a positive finite interval")
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))

    def call(command, **params):
        payload = json.dumps(dict(type="ExecuteCommand", command=command, params=params)).encode()
        req = urllib.request.Request(f"http://127.0.0.1:{args.port}/api/commands", data=payload,
                                     headers={"Content-Type": "application/json"})
        with opener.open(req, timeout=15) as response:
            result = json.load(response)
        if result.get("error") or result.get("ok") is False:
            raise RuntimeError(result)
        return result["data"]

    report = dict(checked_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  source=SOURCE, published=dict(battery_energy_wh=6220, solar_peak_w="nearly 270"),
                  root=args.root, port=args.port, passed=False,
                  scope="Public nameplate agreement and live simulator consistency only",
                  unverified=["flight pack voltage and discharge curve", "panel I-V curve and MPPT/converter",
                              "panel collection area and cell efficiency", "thermal losses and night survival",
                              "mobility and mechanical fidelity"])
    try:
        ready = call("GetReadiness")
        if not ready["ready"] or ready["faulted"]:
            raise RuntimeError(f"Scene not ready: {ready}")
        entity = int(call("RunRhai", code="find_path(" + json.dumps(args.root) + ")")["stdout"])
        battery = call("QueryUsdPrim", path=args.root + "/Battery")
        solar = call("QueryUsdPrim", path=args.root + "/SolarMechanism/Photovoltaics")
        report.update(battery=battery, solar=solar, entity=entity, batches=[])
        for i in range(args.samples):
            if i:
                time.sleep(args.interval)
            report["batches"].append(call("ReadPortsBatch", targets=[dict(api_id=entity, port_names=NAMES)]))
        # Catch reloads/edits during acquisition instead of mixing configurations.
        for before in [battery, solar]:
            after = call("QueryUsdPrim", path=before["path"])
            for key in ["doc_id", "document_generation", "stage_generation", "attrs"]:
                if before.get(key) != after.get(key):
                    raise RuntimeError(f"Configuration changed while sampling: {before['path']} {key}")
        ready = call("GetReadiness")
        if not ready["ready"] or ready["faulted"]:
            raise RuntimeError(f"Scene faulted during sample: {ready}")
        report["checks"] = evaluate(battery, solar, report["batches"])
        report["passed"] = all(c["passed"] for c in report["checks"])
    except Exception as exc:
        report["error"] = str(exc)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2), encoding="utf-8")
    for check in report.get("checks", []):
        print(("PASS" if check["passed"] else "FAIL") + " " + check["name"])
    if "error" in report:
        print("ERROR " + report["error"])
    print("Report: " + str(args.output.resolve()))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
