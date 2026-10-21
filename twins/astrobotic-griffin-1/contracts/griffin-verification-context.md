# Powered Griffin verification context

The reusable vehicle now contains an electrical/thermal network that consumes
physical Sun samples. A component fixture which instantiates that complete
vehicle must supply an environment even when its observer only checks geometry.
An unavailable irradiance or framed direction is not a valid zero-light input.

The standalone system, lander, visual-configuration, landing-leg, propulsion,
tank, solar, ramp and ramp-touchdown fixtures reference the existing
`environments/lunar_surface_base.usda` at their fixture root. This supplies the
shared lunar gravity, physical Sun and contact-material preamble. It adds no
terrain, rover mission, guidance sequence or descent lifecycle. The controlled
fixture lighting is not a qualification of a flight epoch or touchdown site.
The separate bus fixture already uses this same preamble.

The original system fixture remained held before initialization: all five
forward-panel Sun outputs were unavailable and seven admission tickets remained
pending. Adding the environment through the document API admits its unchanged
observer, which passes 40 checks. The eight similarly affected fixtures then
pass another 1,873 checks. No requirement predicate, comparison tolerance,
physical vehicle parameter or Modelica equation was relaxed.

Qualification uses committed engine `b9f29853b`, built in a clean worktree,
binary SHA-256
`fa7c94a1428a81baec36b7cd1798daa96d6491ed200a8ac2bed1e47ba94b5b9b`.
The same binary separately passes the full windowed landing-stability horizon
at High quality and 1024 × 1024, with ready admission, zero runtime diagnostics
and zero broken connections. The landed screenshot was inspected. This
separates the committed baseline from the uncommitted coupled-drive failure
described in the model audit; it does not qualify that pending implementation.

Evidence is in the clean engine worktree's
`.cache/codex-evidence/griffin-committed-20261021/`: the before/after system
fixture logs and probe reads, typed authoring receipts, `fixture-cohort.json`,
`fixture-results.json`, `native-qualification.json` and `landed-1024.png`.
These functional results are not FPS acceptance. The longer native run also
exposes the thermal operating-range gap recorded in the power contract.
