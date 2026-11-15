# Controlled FLIP egress acceptance — 14 November 2026

`scene-test-evidence.json` records the final 7/7 native scene-test verdict.
`trajectory.csv` and `egress-telemetry.png` show the measured descent, transfer
and manual-drive proof; CSV samples are every 30 fixed ticks. The raw test log
is retained as `scene-test.log.gz`.

`desktop-evidence.json` records the complete normal desktop DEPLOY and native
manual-input proof: 1.17591 m travel and braking to 0.00581 m/s. The native
release event records stable four-wheel terrain support and zero line load.
`desktop-accepted.log.gz` begins at the accepted delayed DEPLOY request;
`desktop-history.log.gz` also retains the earlier unloading-stop diagnostic.
`desktop-verification.log` is the verifier stdout. The final desktop is paused
with the verifier's inputs released. Its saved post-release velocity is not a
stationary-parking claim. `desktop-complete.png` and `desktop-near-vertical.png`
show the completed rover and the earlier near-vertical dismount.

`operator-takeover.json` records the negative normal-DEPLOY takeover test:
all four wheel brake requests, both coupled body pauses, a stopped clock and
unchanged physical pose. This is separate from the successful complete run.

`mobility-tests.log`, `brake-contract.log`, `modelica-contract.log`,
`sampled-wrench.log`, `shader-policy-contract.log` and `production-build.log`
retain focused checks and the final desktop binary build.

`engine-fixes.patch` contains the seven native engine files changed by this
task. `source-manifest.json` identifies the engine base revision, binary SHA256,
and current Twin/native source hashes. The native patch is required for this
acceptance; running the Twin with an older installed engine is unverified.
The changes remain local and uncommitted.

Reproduce the full scene test using the command in `source-manifest.json`
from the engine checkout. Set TWIN to this Twin's absolute path first. For the
standalone continuous-law contracts run `python3 "$TWIN/tools/check_tether_model.py"`.
To extract a new scene-test log use `python3 extract_trace.py LOG OUTPUT_DIR`.
Regenerate the scientific figure with `uv run --with matplotlib python plot_telemetry.py`.

The balanced rear-wheel bridle resultants, ideal powered winches and actuator
response are explicit study assumptions. These results do not establish the
flight end rigging, fabric strength, failure tolerance or a flight procedure.
The visible strips show rest routing rather than simulated cloth.
