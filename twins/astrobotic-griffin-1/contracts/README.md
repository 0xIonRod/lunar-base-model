# Griffin contract architecture

This folder is the reviewable design-contract layer for the Griffin Twin. It
does not contain USD source and it is not a second runtime loader. The
executable contract surface remains in `../tools/`, because the current Twin
runtime discovers `tools/*.rhai` at the top level only.

## Ownership

| Layer | Owner | Purpose |
|---|---|---|
| `contracts/*.md` | Twin authors | Explain part obligations, units, provenance, and acceptance policy. |
| `requirements/griffin_requirements.sysml` | Twin authors | Normative Griffin lander/integration SysML v2 requirement/verification definitions, usages, and study limits. |
| `requirements/flip_requirements.sysml` | Twin authors | Rover-owned FLIP values and the four-wheel visual verification case. |
| `tools/griffin_spec.rhai` | Twin authors | Read-only compatibility projection of SysML values for the Rhai test API. |
| `tools/griffin_requirements.rhai` | Twin authors | Stable Rhai API for lint, reports, live gates, and command limiters. |
| `tools/griffin_visual_builder.rhai` | Twin authors | Dry/apply component assembly recipe over the generic typed USD tools. |
| `components/**/*.usda` | Twin authors | Small replaceable render-only component assets; no flight CAD/B-rep. |
| composed USD | Editor / typed USD command bus | Own authored geometry, transforms, schemas, relationships, and metadata. |
| scenario test | Twin scenario | Mount the composed stage and emit the production verdict. |
| Rust runtime | generic simulator | Supplies query, typed edit, projection, and test seams; no Griffin-specific policy. |

Do not duplicate a numeric requirement in a scene file and a script. A value
belongs in `requirements/griffin_requirements.sysml`; the Rhai spec module reads
that source through the compact `ValidateSysml` query and exposes a compatibility
function to the executable test. The Markdown records meaning and provenance.
A value that is not source-backed must remain explicitly marked as a study
proxy or `TBD`.

## Check execution

The same check functions are used in two contexts:

1. `griffin_requirements::lint((), root)` runs against the mounted Twin stage
   in a production scene test.
2. `griffin_requirements::runtime_report((), root)` is the runtime suite: it
   enumerates every executable rule, audits all 20 manifest parts, runs the
   relational layout report, and returns machine-readable failures for the
   Twin scenario to turn into one verdict.
3. `griffin_requirements::lint_live(doc_id, root)` and the focused reports run
   against an already open headful Editor document.

Before the structural assertions run, the production Rhai test validates the
co-located SysML source and confirms the selected
`Griffin1Requirements::Verify_GriffinRequirements` case exists. Rhai is still
the only executable Griffin test backend; SysML supplies intent, IDs, and
thresholds, while the generic Rust bridge only parses and reports the source.

Live authoring must use typed `ApplyUsdOps` plans through the Editor tools. A
check failure is evidence for the next edit; it is never repaired by hiding a
proxy, clamping a pose in Rust, or rewriting USDA on disk.

The runtime suite is driven through the existing headful session's
`RunRhai`/`RunScenario` path. It must not start a second simulator process.
The suite reports the executable contract set only; checks marked Planned in
`checks.md` remain outside the green verdict until a generic runtime seam
exists. Mission-only checks and process gates are returned in separate report
lists, so they are visible without being mislabeled as structural passes.

The visual suite follows the same boundary. `griffin_flip_visual.rhai` reads
the componentized presentation stage, checks every named child, and compares
selected composed geometry bounds with SysML SI datums. A live Editor document
can be updated with `griffin_visual_builder::apply_visual_components(...)`; the
single `ApplyUsdOps` acknowledgement and subsequent generation query are the
authoring/evidence pair. The visual suite emits its complete structured result
set on the generic `<channel>_EVIDENCE` telemetry event before the stable
verdict line, so a frame and composed query can be paired by source revision.
The presentation assembly uses four compact tank pods (`TankPX`, `TankNX`,
`TankPZ`, `TankNZ`) to match the four-tank SysML integration identity; these
remain render-only and do not replace the dynamic tank bodies.

## Planned evolution

The current monolithic engine is intentionally kept behind the stable public
library name while the contract data and documentation are separated. Future
suite modules may be added as additional flat `tools/*.rhai` libraries (for
example `griffin_checks_geometry.rhai`) and called by the facade. A recursive
tool directory would require a generic loader change in Rust and is not needed
for this Twin.
