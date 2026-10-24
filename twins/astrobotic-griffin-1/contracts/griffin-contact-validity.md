# Griffin contact-model validity

`vehicles/griffin_1.usda` owns the contact observer and its explicit 5 m/s study
limit. Native hull and four-leg `contact_approach_speed` outputs feed
`models/GriffinContactValidity.mo`, which composes the shared
`LunCo.Sensors.ContactSpeedEnvelope`. The limit applies at contact; ordinary
flight may exceed it. It is a conservative presentation-study cutoff, not a
calibrated material damage or absorption rating. Ramp-only and detached-payload
contacts are outside this observer's scope.

The existing lander `Subsystems` supervisor loads
`scenarios/griffin_impact_policy.rhai`. It imports the shared lander supervisor
for flight handoff and propellant reactions, and handles the retained validity
event through `PauseSimulationObject`. The warning includes measured approach
speed, the study limit and the producer tick. Native motion, constraints,
connected continuous models and object-owned scripts stop together. The external
mission observer and the rest of the scene remain usable. Restarting the scene
is the supported recovery boundary; resetting one backend is insufficient.

Production qualification on 2026-10-24 used the regular development build with
Tracy enabled, standard eight physics substeps and one scene-test thread:

- `griffin_high_impact_validity`: seven checks pass. A one-tick native force input
  accelerates every authored dynamic body together; peak descent is 300.406 m/s.
  The retained contact observation is 299.677 m/s at tick 18. The complete
  20-body assembly pauses, and its pose, flight controller, guidance and validity
  observer clocks remain fixed. The warning identifies the exceeded study limit.
- `griffin_nominal_contact_validity`: five checks pass. Production powered
  descent confirms touchdown at tick 1339, without a validity event or object
  pause; the observer continues for another 30 ticks. Peak flight descent is
  6.586 m/s, demonstrating that this policy is not a flight-speed clamp.
- `griffin_engine_off_impact`: seven checks pass. The production flight-input
  path disables guidance while throttle remains zero. The ballistic drop
  reaches 13.839 m/s; a retained 13.803 m/s contact observation causes one warning
  and a coupled pause. Pose, flight controller, guidance and observer clocks
  remain stopped for another 30 ticks.

All three cases are registered against GR-040 in `twin.toml`. Their receipts, logs and
authoring plans remain untracked under the application worktree's
`.cache/codex-evidence/performance-20261023/instability-latest/`. Application
commits `c82cd0072`, `5e5dc8c9a`, `248b5a230` and `731716005` provide initial
velocity admission, coupled warnings, native port ownership and unambiguous
supervisor activation respectively. These gates do not qualify the complete
surface mission, long-term landing stability or impact absorption.

The mounted `ValidateSysml` source-set check and active Twin verification
registry report no errors. GR-040 has its typed source-evidence link and formal
response predicate; the source set retains 153 unrelated acceptance warnings.

A separate graphical observation through simulation tick 5422 (90.367 s)
retains the same identities and sessions for all 12 continuous participants;
their clocks never move backwards, and authored source hashes and modification
times remain unchanged. This covers nominal descent and post-touchdown operation.
It does not reproduce or close the reported interactive mid-flight reload.
