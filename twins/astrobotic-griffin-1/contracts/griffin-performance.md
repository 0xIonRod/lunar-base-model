# Griffin interactive performance acceptance

The user selected **60 FPS at 1280 × 720, High quality, with real-time
physics on this laptop** on 22 October 2026. This is an interactive simulator
target, independent of flight-model calibration and component conformance.

Use the production executable, standard PBR materials, authored shadows and
terrain, the standard fixed timestep and substeps, and time rate 1×. Keep
the complete Griffin/FLIP mission model. Changing to unlit materials, reducing
terrain quality, disabling physical systems or dropping simulation steps does
not qualify the target.

Measure the same 24-second settled window used in the earlier mission
checkpoint in `verification.md`. Enter that window only after the mission's
authored verdict, ready admission, resolved connections and completed terrain
streaming. Record the active camera and physical viewport dimensions before
and after the window, with a rendered capture of the actual scene. An Editor
component preview has a different workload and cannot qualify the mission.

Report frames delivered per monotonic wall second from `EnginePerformance`
sample counters, completed simulation seconds per wall second from the shared
clock, frame-time distribution, pending simulation demand, and runtime/render
diagnostics. The frame-rate target applies to the window average. Report clock
endpoint quantization and API timing uncertainty alongside throughput; do not
hide a sustained simulation deficit behind the FPS result. Rendering that has
stopped or a faulted/held simulation invalidates the window.

Use a task-owned `LUNCOSIM_CONFIG` directory to prevent workspace restoration
from installing old documents or window geometry. Set
`LUNCOSIM_EPHEMERAL_SETTINGS=1` as well. Verify the actual viewport through
`SceneCameraAudit`; a requested window size does not prove the resulting
render resolution. Record executable and source hashes, GPU/driver, quality,
camera, terrain residency, and concurrent CPU/GPU work. A contention-affected
sample is diagnostic evidence, not clean acceptance.

Status: open. The native motor/latch sequencing repair passed the 16-check
headless mission in its recorded source cohort. The latest cleaned model
completes ramp deployment but fails the later surface route. Landing stability
and the shared physics repair remain open in optimization. No clean qualifying
windowed mission performance window has been measured. Component passes and
Editor/scene captures do not establish this target. The earlier 32.37 FPS /
0.5658 simulation-seconds-per-wall-second checkpoint does not meet the selected
target and remains evidence for its own source cohort.
