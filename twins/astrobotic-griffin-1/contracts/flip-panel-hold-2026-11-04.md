# FLIP panel holding drive — 4 November 2026

The operator reported panel wobble while driving. The active v5 panel uses a
15 kg rigid body and a torque-limited revolute hinge. Its previous angular force
drive had stiffness 1 N·m/degree and damping 0.1 N·m·s/degree. With the authored
mass, COM and hinge-axis inertia, the planar holding response has damping ratio
0.123: a lightly damped spring rather than a steady holding servo.

The native USD reader converts angular gains from per-degree to per-radian
units. The saved drive now uses stiffness 20 N·m/degree and damping
3.5 N·m·s/degree (1145.916 N·m/rad and 200.535 N·m·s/rad). Its planar damping
ratio is 0.960. The 60 N·m torque cap, separate moving body, hinge travel,
Modelica slew/easing controller, electrical model and geometry are unchanged.
This is simulator tuning, not supplier actuator qualification.

Only the two drive attributes were changed through a generation-checked
SourceAsset proposal and SaveDocument in the headful production Editor.
Typed readback confirms stiffness 20, damping 3.5 and torque cap 60 at document
121896497267638, generation 2, using binary 0.6.0-dev (`8cc192e5-dirty`).

## Checks and execution boundary

`tests/check_flip_panel_response.py` reads the open canonical document through
the API, derives hinge inertia using the parallel-axis theorem, and integrates
a torque-limited planar holding response at the initial 82-degree deployment.
The imposed acceleration is +3 m/s² from 2–4 s and -3 m/s² from 6–8 s, with
lunar gravity and a 1 ms RK4 step over 12 s. Hinge inertia is 9.524 kg·m².

The revised response peaks at 1.663 degrees tracking error and 6.422 degrees/s,
within the SysML study bounds of 3 degrees and 15 degrees/s. The old coefficients
fail the same reduced-model error bound. This excludes 3D chassis rotation,
contact/hard stops and native solver compliance; it is not native driving or
deployment acceptance. Reproduce while the canonical v5 document is open:

```sh
python tests/check_flip_panel_response.py --port 4127 --baseline-stiffness 1 --baseline-damping 0.1
```

The native `flip_motion.rhai` observer now samples actual hinge angle and angular
velocity against the controller's output setpoint on every drive, brake and
stopped-dwell tick, in both directions. Missing/nonfinite samples or exceeded
limits fail the existing verdict. It retains sample count and peak error/rate;
the positive gate now has 44 checks. No drive, braking or posture limits were
relaxed. Stow/deploy remains covered by `flip_cad_capabilities.rhai`.

Both changed Rhai files pass the production parser. The reduced response check
passes against the composed authored values. `git diff --check` passes.

**Native execution remains unqualified in this installation.** Before editing,
the native motion test returned NO-VERDICT at its 30-second readiness timeout:
the installed Modelica library index has no namespaces, core tool sources and
NOBILE03 data are unavailable, and the panel Modelica participant never becomes
ready. Logs are `logs/panel-baseline.stdout.log` and
`logs/panel-baseline.stderr.log` in the workspace. Standalone USD/SysML validation
also cannot resolve the Twin/import closure in that invocation. Editor lint
retains seven unavailable rigid-body output-port diagnostics. Neither the
native motion gate nor the existing stow/deploy gate is claimed to pass here.
