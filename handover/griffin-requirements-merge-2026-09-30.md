# Griffin requirements integration — 2026-09-30

Integrated the uncommitted requirement and supporting builder/check changes from
`lunar-base-model-2` (base 68e4d3c) into main after 5444cf9. The sibling worktree
was left untouched; its binary patch SHA-256 remained
`c122b0950c94631de96fcc60a170cee5b3ad0482515b16150c914def9cecf644`.
This is a reviewed content integration, not a Git ancestry merge of dirty files.

Preserved the single physical/render wheel owner and the complete-assembly-mass
descent guard. Did not import the two mission-script diffs that removed the
guard and coherent telemetry. Retained 0.30 m suspension rest length; deferred
the 1.20 m proposal because its cited replay artifact is unidentified. This
remains an explicit study assumption pending a full physical driving replay.

CAD dimensions now own the runtime SI values through native SysML expressions.
Corrected width/length axis labels and the checks' redundant Cube extent factor.
The numeric geometry stays 2.116 m along X and 1.476 m across Z. No USD resize is
needed for these changes. Added evidence records for the 16 newly standardized
CAD requirements and existing GLL-010/GR-039 targets. Evidence links describe
provenance, not successful CAD or mission acceptance. Added the user-provided
Pittsburgh hardware photo and its configuration/measurement limits.

LunCoSim core commit 1aa9f323d projects bounded, resolved numeric constants through
the shared semantic unit-factor evaluator; authored expressions and provenance
remain intact. No Twin parser or SI literal fallback was retained. A follow-up
shared observer fix resolves typed requirement handles for provenance calls.

Validation: repository structure and requirement-source completeness pass
(207 targets, 207 evidence records, 45 sources). Production build passed; 18
core AST/IR/report/Rhai tests passed. Fresh production runtime reads return
0.45 m radius, all four CAD-derived wheel stations, 450 kg study mass and
0.476 m payload-deck center. Rover gate 60/60 and chassis gate 18/18 pass.
These results do not accept driving, touchdown or mission completion.

Next geometry work remains Griffin's leg endpoint/load paths, engine skirt and
hollow bells. The present thick parallel leg proxies and closed cone bells are
still unsuitable for visual acceptance. Keep numerical guesses explicit and
verify one component through the typed Editor before saving its USD source.
