#!/usr/bin/env bash
# Run the Twin-authored Rhai landing trial twice and compare its typed metrics.
# The shell is only process orchestration; all observations and limits live in
# scenarios/tests/griffin_surface_ops_contract.rhai and SysML.
set -euo pipefail

if [[ $# -gt 0 ]]; then
    LUNCOSIM_BIN=$1
fi
if [[ -z "${LUNCOSIM_BIN:-}" ]]; then
    echo "usage: LUNCOSIM_BIN=/path/to/luncosim $0 [optional-binary]" >&2
    exit 2
fi
if [[ ! -x "$LUNCOSIM_BIN" ]]; then
    echo "luncosim binary is not executable: $LUNCOSIM_BIN" >&2
    exit 2
fi

twin_root=$(cd "$(dirname "$0")/.." && pwd)
scene="$twin_root/tests/griffin_surface_ops_contract.usda"
verification="GriffinSimulationAccuracyRequirements::Verify_GriffinLandingStability"
# This trial must include the descent and a full 60 s post-touchdown window.
# A 70 s bound ended before prior powered-descent diagnostics reached contact.
max_ticks=${GRIFFIN_LANDING_MAX_TICKS:-30000}
readiness_timeout=${GRIFFIN_LANDING_READINESS_TIMEOUT:-120}
if [[ -n "${GRIFFIN_LANDING_EVIDENCE_DIR:-}" ]]; then
    work=$GRIFFIN_LANDING_EVIDENCE_DIR
    mkdir -p "$work"
else
    work=$(mktemp -d "${TMPDIR:-/tmp}/griffin-landing-determinism.XXXXXX")
    trap 'rm -rf "$work"' EXIT
fi

# Pin all executable Twin/library sources, not only the SysML revision. An
# edited USD between trials invalidates repeatability even if its requirements
# are unchanged. Resolve the same native asset owner as LunCoSim.
source_snapshot() {
    python3 - "$twin_root" "$LUNCOSIM_BIN" <<'SOURCE_PY'
import hashlib
import json
import os
from pathlib import Path
import sys

twin = Path(sys.argv[1]).resolve()
binary = Path(sys.argv[2]).resolve()
configured = os.environ.get("LUNCO_ASSET_ROOT")
if configured:
    library = Path(configured).resolve()
else:
    library = next((parent / "assets" for parent in binary.parents
                    if (parent / "assets").is_dir()), None)
if library is None or not library.is_dir():
    raise SystemExit("Cannot pin the simulator asset owner; set LUNCO_ASSET_ROOT")
extensions = {".usda", ".usd", ".usdc", ".rhai", ".sysml", ".kerml", ".mo", ".toml"}
def digest_file(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()
def digest_tree(root):
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        if path.is_file() and path.suffix in extensions:
            digest.update(str(path.relative_to(root)).encode())
            digest.update(b"\0")
            digest.update(digest_file(path).encode())
            digest.update(b"\0")
    return digest.hexdigest()
print(json.dumps({"binary": digest_file(binary), "twin": digest_tree(twin),
                  "library": digest_tree(library)}, sort_keys=True))
SOURCE_PY
}
source_snapshot >"$work/source-baseline.json"

for run in 1 2; do
    log="$work/run-$run.log"
    source_snapshot >"$work/source-before-$run.json"
    if ! cmp -s "$work/source-baseline.json" "$work/source-before-$run.json"; then
        echo "INVALID landing trial $run: executable sources changed before the run" >&2
        exit 2
    fi
    set +e
    "$LUNCOSIM_BIN" test \
        --scene "$scene" \
        --verification "$verification" \
        --max-ticks "$max_ticks" \
        --tick-hz 60 \
        --threads 1 \
        --jitter 0 \
        --readiness-timeout "$readiness_timeout" >"$log" 2>&1
    exit_code=$?
    set -e
    source_snapshot >"$work/source-after-$run.json"
    if ! cmp -s "$work/source-baseline.json" "$work/source-after-$run.json"; then
        echo "INVALID landing trial $run: executable sources changed during the run" >&2
        exit 2
    fi
    printf '%s\n' "$exit_code" >"$work/run-$run.exit"
    if [[ $exit_code -ne 0 ]]; then
        # Keep collecting the second fresh process. A Rhai stability verdict
        # can fail because the authored physical envelope is too tight while
        # the two metric streams are still exactly repeatable.
        echo "landing trial $run returned exit $exit_code; collecting metrics for repeatability" >&2
    fi
    metrics=$(sed -n 's/^.*GRIFFIN_LANDING_STABILITY_METRICS //p' "$log" | tail -1)
    if [[ -z "$metrics" ]]; then
        echo "landing trial $run emitted no Rhai stability metrics" >&2
        tail -80 "$log" >&2
        exit 2
    fi
    echo "landing trial $run metrics: $metrics" >&2
    printf '%s\n' "$metrics" >"$work/run-$run.json"
done

python3 - "$work/run-1.json" "$work/run-2.json" <<'PY'
import json
import math
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    first = json.load(handle)
with open(sys.argv[2], encoding="utf-8") as handle:
    second = json.load(handle)

if first.get("source_revision") != second.get("source_revision"):
    raise SystemExit(
        f"FAIL landing source revisions differ: {first.get('source_revision')} != {second.get('source_revision')}"
    )
if first.get("sample_count") != second.get("sample_count"):
    raise SystemExit(
        f"FAIL landing sample counts differ: {first.get('sample_count')} != {second.get('sample_count')}"
    )
if first.get("clock_tick_delta") != second.get("clock_tick_delta"):
    raise SystemExit(
        f"FAIL fixed-clock tick counts differ: {first.get('clock_tick_delta')} != {second.get('clock_tick_delta')}"
    )
if first.get("clock_contract_ok") is not True or second.get("clock_contract_ok") is not True:
    raise SystemExit("FAIL deterministic clock contract was not satisfied")
if first.get("finite") is not True or second.get("finite") is not True:
    raise SystemExit("FAIL landing telemetry was not finite")

# Categorical outcomes are part of the deterministic state.  A replay that
# changes touchdown/hold state but remains inside a broad physical envelope is
# still a simulation divergence and must fail loudly.
for key in ("touchdown", "barrier_held"):
    if first.get(key) != second.get(key):
        raise SystemExit(
            f"FAIL {key} diverged: {first.get(key)!r} != {second.get(key)!r}"
        )

def number(name):
    value = first.get(name)
    if not isinstance(value, (int, float)) or not math.isfinite(value):
        raise SystemExit(f"FAIL {name} is not finite in run 1")
    return float(value)

tol_pos = number("replay_tolerance_m")
tol_upright = number("replay_tolerance_upright")
tol_speed = number("replay_tolerance_speed_mps")
tol_time = number("replay_tolerance_time_s")

for index, axis in enumerate(("x", "y", "z")):
    delta = abs(float(first["position"][index]) - float(second["position"][index]))
    if delta > tol_pos:
        raise SystemExit(f"FAIL position {axis} diverged by {delta:.6g} m (limit {tol_pos:.6g})")

for key, tolerance in (
    ("upright_axis_y", tol_upright),
    ("ground_speed_mps", tol_speed),
    ("angular_speed_rad_per_sec", tol_speed),
    ("min_upright_axis_y", tol_upright),
    ("max_ground_speed_mps", tol_speed),
    ("max_angular_speed_rad_per_sec", tol_speed),
    ("max_horizontal_drift_m", tol_pos),
):
    # Validate both samples before comparing. A single non-finite extrema value
    # must never be hidden by a finite final pose.
    for run, sample in ((1, first), (2, second)):
        value = sample.get(key)
        if not isinstance(value, (int, float)) or not math.isfinite(value):
            raise SystemExit(f"FAIL {key} is not finite in run {run}")
    delta = abs(float(first[key]) - float(second[key]))
    if delta > tolerance:
        raise SystemExit(f"FAIL {key} diverged by {delta:.6g} (limit {tolerance:.6g})")

for key in ("elapsed_s", "admitted_sim_elapsed_delta_s"):
    first_value = number(key)
    second_value = second.get(key)
    if not isinstance(second_value, (int, float)) or not math.isfinite(second_value):
        raise SystemExit(f"FAIL {key} is not finite in run 2")
    if abs(first_value - float(second_value)) > tol_time:
        raise SystemExit(f"FAIL {key} diverged by {abs(first_value - float(second_value)):.6g} s")

print("GRIFFIN LANDING DETERMINISM: PASS")
print(f"source_revision={first['source_revision']} horizon_s={first['horizon_s']} samples={first['sample_count']}")
print("position_delta_m=" + str([abs(float(first['position'][i]) - float(second['position'][i])) for i in range(3)]))
print("upright_delta=" + str(abs(float(first['upright_axis_y']) - float(second['upright_axis_y'])))
      + " ground_speed_delta_mps=" + str(abs(float(first['ground_speed_mps']) - float(second['ground_speed_mps'])))
      + " angular_speed_delta_rad_per_sec=" + str(abs(float(first['angular_speed_rad_per_sec']) - float(second['angular_speed_rad_per_sec']))) )
PY

run1_exit=$(<"$work/run-1.exit")
run2_exit=$(<"$work/run-2.exit")
if [[ "$run1_exit" -ne 0 || "$run2_exit" -ne 0 ]]; then
    echo "GRIFFIN LANDING ACCEPTANCE: FAIL (trial exits: $run1_exit, $run2_exit)" >&2
    exit 1
fi
