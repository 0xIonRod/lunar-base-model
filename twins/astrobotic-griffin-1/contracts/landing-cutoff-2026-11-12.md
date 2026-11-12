# Qualified pad cutoff and landing stability — 2026-11-12

The near-ground fly-away was reproduced in the production surface mission.
Gentle first-pad contact could not close the main engines because the shared
airframe required the final settled angular rate before cutoff. With thrust
still supporting the vehicle, the partially loaded gear drifted; guidance
then correctly requested its existing off-target recovery climb.

LunCoSim commit `002a6130d` updates `assets/models/Lander.mo` to separate the cutoff rate
limit (`engine_cutoff_angular_speed_rad_s`, default 0.05 rad/s) from final
settled handoff (unchanged 0.005 rad/s). Both are study settings. Native pad
contact, upright attitude, low linear speeds and GNC target qualification
remain necessary. Rate damping remains available until all four pads and the
original settled predicates qualify handoff. No contact, pose, physics step
or landing acceptance result is fabricated.

Two fresh production runs of the unchanged
`tests/griffin_surface_ops_contract.usda` pass the source-backed 60-second
post-touchdown stability horizon. Touchdown occurs at tick 1342; the tests end
at tick 4950 (82.5 s). Every one of 361 post-touchdown samples retains all four
pad contacts. Maximum drift is 0.0201222 m, minimum upright projection
0.9962432, maximum ground speed 0.0111598 m/s and maximum body rate
0.00979892 rad/s. Physical replay metrics match exactly. The GNC toggle test
also passes its 22 checks; 78 shared authored checks cover the contact phases
and unsafe-contact rejection.

Native visible inspection also observes engine cutoff, four-pad support and
flight handoff. The simulator checkout retains the complete implementation
review at `docs/reviews/lander-contact-cutoff-2026-11-12.md` and runtime evidence
under `.cache/perf/plume-completion/`. Deploy the matching shared Modelica asset
and reload the scene; editing the Twin alone cannot update an already-running
simulator's selected asset library. This accepts the study landing, not flight
GNC tolerances or the deferred restrained rover descent.
