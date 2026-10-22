# Bounded landing preflight

The powered-descent preflight selects the four requirement identities it
evaluates: GR-037, GR-038, GLL-009 and GLL-010. It uses the shared
`sysml_requirements::source_with_selection` interface and the source-owned
landing and spring attributes. It does not enumerate the Twin's full requirement,
component or verification registries during mission startup.

This keeps the input proportional to the landing check as other components add
requirements. A full-Twin report exceeded Rhai's aggregate string budget after
the ramp source set grew. The mission retried that failing task every tick;
Tracy attributed 42.72 seconds to 51 failed calls in a 75-second diagnostic
capture. The shared sandbox limits remain unchanged.

`scenarios/tests/griffin_landing_preflight.rhai` exercises the real helper on the
full surface-operations scene. Its four production checks require the authored
target and DEM datums, all four spring rest poses, rejection of an elevated
target, and equal source revisions across the positive and negative checks.
Attach it with `RunScenarioAsset` after the scene's participants are admitted.
Its verdict channel is `GRIFFIN_LANDING_PREFLIGHT`.

The regular optimization production binary with Tracy, SHA-256
`ed2ebf7a2eba3b5a1f11132f88c572ec74d0e3bb4ba2077417b9565c0816b365`,
passes all four checks in the windowed host, PID 68464/API 4836. The normal
mission also reports its geometry/spring and dynamic assembly-mass preflights
passing before descent. The screenshot was inspected; API Exit releases the
process and port. Evidence resides in the optimization checkout under
`.cache/codex-evidence/performance-20261023/griffin-preflight-gate/`.

This qualifies preflight, not touchdown, ramp deployment, the complete mission
or performance targets. Generic task-callback errors still require a terminal
failure boundary instead of implicit retry; that engine issue is separate from
the bounded landing input repaired here.
