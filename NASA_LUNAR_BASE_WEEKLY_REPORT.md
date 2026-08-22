# NASA Lunar Base Project — Reusable Weekly Report

**Baseline snapshot:** 2026-08-22  
**Workspace:** `NASA-lunar-base-model`  
**Audience:** Technical project maintainers and weekly reviewers  
**Report role:** Living handoff and weekly continuation document

## Technical summary

The workspace contains four connected workstreams:

1. A sourced lunar-mission research register covering 25 mission or asset records, 29 vehicles, and 12 locations.
2. A Luna 2 / Sinus Lunicus terrain pipeline with a NASA LOLA source raster, direct DEM conversion, Twin assets, USD scenes, previews, and simulator logs.
3. A local seven-day lunar-base news agent with configurable RSS feeds and Markdown/JSON output.
4. A reproducible data-quality audit with Python code, a notebook scaffold, SQLite snapshot data, JSON results, and an HTML handoff.

The project is not yet at a clean integration milestone. The research tables are structurally tidy but need typed status and relationship fields before automated joins. The direct and Twin terrain arrays contain identical elevation values, but their numeric type and georeferencing contracts differ. The active Luna 2 simulator process reports core readiness while the UI remains near 10% terrain bake, so terrain completion cannot currently be trusted. The news workflow is useful for discovery, but it does not yet preserve durable history across weekly runs.

The highest-value next step is to make one small, auditable terrain smoke test pass end to end while adding truthful bake-stage observability. In parallel, normalize the research schema and fix the news agent’s persistence/retention behavior so next week’s report can compare against this baseline.

## Current project state

| Area | Current state | Confidence | Weekly implication |
|---|---|---:|---|
| Mission research | 25 records with unique IDs and primary links; explicit uncertainty is preserved | High for local structure; medium for external facts | Re-run source verification and schema checks before using as simulator input |
| Vehicle/location joins | 21 of 25 mission/asset IDs are referenced by the vehicle catalog; M09 is absent from the location table | High | Add typed relationship coverage tests |
| Luna 2 terrain data | Direct and Twin 32×32 arrays match exactly after float conversion; metadata differs | High | Choose one canonical DEM contract before more runtime tests |
| Twin terrain runtime | Core reports ready, but bake remains around 10%; 4106 stderr is clean | High for symptom; medium for cause | Instrument stages and test with a tiny synthetic DEM |
| Direct terrain runtime | Runs a 1 km diagnostic path; target resolution 8 was clamped to 16 | High | Record effective runtime settings, not only requested settings |
| News agent | Generated a seven-day briefing with 24 tracked article URLs in state | High for current output; low for historical continuity | Fix persistent dedupe/history before relying on trend reporting |
| Data-quality audit | `quality_audit_v2.py` produced JSON evidence and a partial HTML artifact | High for local checks | Re-run after schema/terrain changes; add a real notebook execution record |
| Moon treaty / policy research | No dedicated treaty/policy file or explicit treaty record found in the workspace inventory | High for workspace coverage | Add a policy register if legal/governance context is in scope |
| Chat exports | No chat transcript files or chat archive surfaced in the workspace inventory | High for workspace coverage | Treat this report as file-based evidence only; attach/export chats if needed |

## 1. Research and mission model

### The register has good provenance but mixed semantics

`research/missions.md` contains 25 rows: `M01`–`M22` plus assets/placeholders `A01`–`A03`. All expected IDs are present, there are no duplicate IDs, every row has 11 columns, and every row has at least one primary-source URL. The register intentionally keeps planning uncertainty such as “date not published,” “TBD,” and “pending approval.” That is the right behavior for a planning dataset.

The main defect is that `Status / confidence` is not a stable field. The current register includes lifecycle states such as `planned`, `conditional`, `proposed`, `schedule conflict`, and `approved`, but also role descriptions such as “Payload, not a standalone landing mission” and “Program, not one mission.” The declared vocabulary in `research/data-model.md` does not include `approved` or the placeholder form used by `A03`.

**Required normalization:** split the current column into at least `record_kind`, `status`, `confidence`, and `uncertainty_reason`. Keep `A01` and `A02` as typed assets/programs rather than forcing them into mission semantics.

### Explicit uncertainty is concentrated in integration fields

The audit found placeholders in:

| Field | Rows with explicit uncertainty | Share of 25 rows | Why it matters |
|---|---:|---:|---|
| Rover or surface vehicle | 8 | 32% | Vehicle joins and surface operations cannot be deterministic yet |
| Lander / carrier | 7 | 28% | Delivery and launch modeling remain incomplete |
| Target date | 4 | 16% | Scheduling must preserve ranges and unknowns |
| Location or orbit | 3 | 12% | Terrain and orbital joins need nullable, typed locations |

The `TBD` values should remain explicit values with a precision/status field. They should not be silently converted into empty strings or guessed coordinates.

### Cross-file integrity gaps

The vehicle catalog references 21 of 25 mission/asset IDs. Missing references are:

| ID | Missing from | Assessment | Severity |
|---|---|---|---|
| M09 | `research/vehicles.md` | Artemis III is a low-Earth-orbit systems demonstration with no normalized vehicle rows | Medium |
| M17 | `research/vehicles.md` | In-space transportation vehicle remains TBD | Medium |
| M22 | `research/vehicles.md` | Chandrayaan-4 sample-return architecture is not normalized | Medium |
| A03 | `research/vehicles.md` | Intentional unnamed portfolio placeholder | Low |

The location table references every record except M09. That omission is conceptually understandable because M09 is modeled in low Earth orbit, but an inner join would erase it. Add a location-domain field or an explicit orbital-region row.

### Research schedule conflicts to preserve

The register already documents the highest-risk conflicts and should keep them visible in weekly reports:

- Draper CP-12: NASA’s older page presents a 2026 plan; ispace’s later update proposes Mission 5 in 2030 pending approval.
- Blue Ghost Mission 2: older NASA material says 2026; Firefly’s current page says no earlier than 2027.
- Chang’e 8: source material supports a 2028–2029 range.
- VIPER: NASA’s current Moon Base architecture describes a conditional late-2027 delivery despite the standalone project’s prior cancellation history.

These are not simple formatting problems. They require source timestamps, typed schedule status, and a rule that current provider/agency pages outrank stale program pages when the conflict is documented.

## 2. Terrain and simulator findings

### The terrain values match; the file contracts do not

The source `luna2_direct_sim/raw/LDEM_4.JP2` is a 1440×720 JPEG2000 with unsigned storage values and no embedded GeoTIFF tags. `direct_luna2_dem.py` subtracts the 32768 digital-number offset and writes a 32×32 signed-int TIFF. The Twin cache contains the same 32×32 elevations as float32. The audit found:

- Same shape: yes.
- Same values after float conversion: yes.
- Maximum absolute elevation difference: 0 m.
- Direct derivative: int32, EPSG:4326-style tags, 0.25° scale.
- Twin derivative: float32, Moon 2000 keys, 0.25° scale, Moon radius metadata.
- Elevation range: −9,249 m to −1,209 m.

This is a high-confidence data-equivalence result, but the semantic mismatch is a credible import risk. Select one canonical sample type, lunar CRS/georeference, pixel-area convention, nodata policy, and metadata file, then make both runtime paths consume the same contract.

### The model is regional, not landing-scale

The 0.25°/pixel source grid is approximately 7–8 km per pixel near the modeled region. The derived regional footprint is approximately 204.8 km × 242.6 km with 32×32 samples. The existing analysis reports a mean slope of 3.42° and a 95th-percentile slope of 15.83°.

This is appropriate for regional context, historical visualization, and coarse vehicle-simulation experiments. It cannot support landing-site certification, boulder detection, small-crater detection, or local hazard scoring. A future landing-scale pass needs a higher-resolution local DEM and an explicit hazard-data contract.

### The active blocker is observability, not proven source corruption

The handover report identifies the active `4106` instance as core-ready (`ready: true`, `faulted: false`, `pending_count: 0`) while the UI remains near 10% at “Baking terrain — luna2.” A final sample showed only 0.41 seconds of CPU time over 8 seconds. That establishes a stall/wait symptom, not a root cause.

Recorded runtime evidence:

| Evidence | Interpretation | Severity |
|---|---|---|
| 4106 core ready while bake remains near 10% | Core readiness is not terrain completion | High |
| `luna2_lit.usda` parse failure | One scene variant was not loadable; later scene loads may drop the prim | High |
| Swap-chain texture timeout on 4104 | Renderer synchronization is a plausible contributor | Medium |
| Direct `target_res 8` clamped to 16 | Requested diagnostic settings were not the effective settings | Medium |
| 4103 scene had no DirectionalLight | Scene illumination contract was incomplete in that run | Medium |
| 4101 had EarthDirectionWorld degeneracy and pending compile tickets | Celestial anchor/readiness behavior needs isolation | Medium |
| 4101 reported telemetry over the 1024-channel limit | Some telemetry was dropped | Medium |
| 4101 reported many algebraic loops and unknown input ports | Modelica/co-sim wiring may be running with inserted delays or dropped values | Medium |
| Python runtime unavailable for two sandbox programs | Those programs were inert in the recorded binary | Low/Medium |

The best next diagnostic is a 4×4 or 8×8 synthetic GeoTIFF through the direct `SpawnDemTerrain` path with the effective resolution recorded. If it also stalls, focus on runtime stage synchronization. If it succeeds, compare source tags, numeric type, CRS, nodata, and dimensions against the Luna 2 derivative.

### Configuration and reproducibility issues

- `luna2_twin/twin.toml` correctly points at `sim/scenes/luna2_static.usda` as the default scene.
- The static scene disables LOD visualization, collider-ring generation, and horizon shadows and uses a 50 km window, which is a reasonable diagnostic configuration.
- `luna2.usda` and `luna2_clean.usda` retain 200 km windows and enabled LOD/collider paths, so they should not be used as the first smoke test.
- `first_mission_base.usda` references `lunco://tutorials/sandbox/build_base.usda` and other packaged assets; it is not a self-contained scene in this workspace.
- Logs show a bare filesystem path was passed to `LoadScene`; use scheme addresses for `LoadScene` or `OpenFile` for local paths.
- The handover references generated terrain analysis files that are not present under `luna2_twin/.cache/terrain/luna2`; either regenerate them into the workspace or update the handover links.

## 3. News agent and weekly evidence pipeline

`news/artemis_news_agent.py` is a useful local seven-day discovery agent. Its configuration covers NASA Artemis/Moon Base feeds, SpaceNews, ESA feeds, and broad Google News searches across base architecture, habitats, power, communications, robotics, resources, international programs, and commercial activity. The current output was generated at `2026-08-22 12:40 UTC` and includes recent stories about NASA’s Moon Base strategy, Chang’e-7 water-ice work, lunar power/thermal systems, India/NASA cooperation, and Firefly/Zeno Power hardware.

The workflow is documented in `news/README.md` and is intended for a Sunday review. The current report should preserve the news output as a weekly artifact, but two code/configuration issues weaken continuity:

1. `.gitignore` excludes `news/artemis_news.md`, `news/artemis_news.json`, and `news/.artemis_news_state.json`, so the generated briefing and state are not naturally retained in version history.
2. The agent writes the current run’s URLs to state but does not load the previous state before filtering. The `--max-state` argument is defined but not used. This means state is not functioning as durable cross-run deduplication.

Additional quality cautions:

- Google News URLs are opaque redirect URLs, so canonical publisher URLs should be captured when possible.
- The seven-day window is good for discovery but not enough to prove a trend without archived weekly outputs.
- Feed failures are warnings; a report should record which feeds failed and whether the output was partial.
- The agent is news discovery, not an evidence-verification system. Primary agency/provider sources should remain the basis for mission status changes.

## 4. Data-quality audit status

The workspace includes both a runnable script path and an inspectable result path:

- `quality_audit_v2.py` — current audit implementation.
- `quality_audit_results_v2.json` — machine-readable snapshot used for this report.
- `quality_audit_snapshot.sqlite` — bounded queryable snapshot for audit tables.
- `data_quality_audit.ipynb` — companion notebook scaffold.
- `data_quality_report_artifact.json` and `nasa_lunar_base_data_quality_report.html` — prior report surfaces.

The audit is marked partial for two explicit reasons:

- Linked external mission pages were not independently fetched during the local-file audit.
- The workspace has one snapshot and no versioned partitions, so freshness, drift rates, and historical change points cannot be measured.

The notebook is not executed in the workspace; it documents how to rerun the Python audit and inspect the JSON result. Treat the JSON/script pair as the current reproducible evidence path until a Jupyter-enabled execution is recorded.

## 5. Coverage gaps: treaty, chats, skills, and agents

### Moon treaty / policy

No dedicated Moon Treaty, Outer Space Treaty, Moon Agreement, Artemis Accords, space-resource law, or policy register was found in the workspace inventory. This report therefore makes no treaty or legal claims. If governance or mission-policy analysis is in scope, add a `research/policy.md` or `research/treaties.md` register with source, jurisdiction, scope, date checked, and interpretation status.

### Chats

No chat transcript, exported conversation, or meeting-notes archive was present in the workspace inventory. The report is based on files, logs, generated outputs, and the current local audit results. Future chat-derived decisions should be saved as dated Markdown notes if they are intended to drive the weekly handoff.

### Skills and agents

No project-local `skills/` directory or agent instruction bundle surfaced in the recursive file inventory. The one explicit local agent is the worldwide lunar-base news agent. The quality audit scripts behave as analysis agents but are not scheduled agents. The weekly MoonDAO automation is external to this repository and is not represented as a local script or config file here.

## 6. Reusable weekly continuation protocol

Use this report as the baseline and append one dated update block per week. Do not rewrite prior dated findings unless correcting an error; record corrections in the changelog.

### Sunday review sequence

1. Run `python .\\news\\artemis_news_agent.py` from the project root.
2. Record feed failures, article count, generated timestamp, and any primary-source confirmations in the new weekly block.
3. Run `python .\\quality_audit_v2.py` and compare `quality_audit_results_v2.json` with the prior snapshot.
4. Check `git status --short` and `git diff --stat`; confirm whether generated news/audit artifacts are intentionally tracked.
5. Review current simulator logs and record new process IDs, scene name, effective terrain settings, bake stage, and whether the UI/API agree.
6. Run the smallest terrain smoke test before retrying the full Twin bake.
7. Update the action table and carry forward only unresolved items.

### Week-over-week update template

Copy this block at the end of the report for the next review:

```markdown
## Weekly update — YYYY-MM-DD

### Change since last report

- Research:
- Terrain/runtime:
- News:
- Data quality:
- Policy/treaty:
- Chats/decisions:

### Evidence reviewed

- News run timestamp / article count:
- Audit result hash or modified time:
- New or changed logs:
- New commits or diff summary:
- External sources rechecked:

### Decisions and implications

- 

### Open blockers

| ID | Blocker | Severity | Owner | Next evidence | Status |
|---|---|---:|---|---|---|
| B01 |  |  |  |  | Open |

### Next-week actions

- [ ] 
- [ ] 

### Confidence and gaps

- High-confidence findings:
- Medium-confidence inferences:
- Missing sources or unavailable files:
```

## 7. Prioritized action list

| Priority | Action | Success criterion | Evidence to retain |
|---:|---|---|---|
| P0 | Add terrain bake stage, last-progress timestamp, error, and timeout state | A stalled bake reports a named stage and fails truthfully | Runtime log plus API response |
| P0 | Run a 4×4 or 8×8 synthetic DEM smoke test through `SpawnDemTerrain` | Tiny DEM completes or isolates the runtime defect | Scene, request, effective settings, log |
| P1 | Choose one canonical DEM numeric/geospatial contract | Direct and Twin derivatives use the same documented contract | Metadata file, hashes, audit result |
| P1 | Fix or quarantine `luna2_lit.usda` parse failure | Scene loads without dropping the stage | Clean log and scene-load result |
| P1 | Normalize research status/record-kind/confidence fields | Audit reports no schema-vocabulary violations | Updated data model and audit output |
| P1 | Add explicit cross-file relationship coverage | M09/M17/M22/A03 are represented as typed relationships or intentional nulls | Join test output |
| P1 | Make news state durable and retain weekly outputs | State is loaded, bounded, and historical weekly Markdown/JSON is preserved | Code diff and two-run test |
| P2 | Add policy/treaty register if in scope | Treaty/policy claims have dated primary sources | `research/policy.md` |
| P2 | Add chat/decision archive if needed | Important decisions are dated and linked to work items | `notes/` or `decisions/` Markdown |
| P2 | Remove external absolute-path dependencies from handover artifacts | A new checkout can follow all evidence links or clearly marks external dependencies | Handover audit |

## 8. Further questions for the next review

- Is the immediate product a regional lunar-base visualization or a landing-scale hazard model?
- Should the canonical terrain path be the direct diagnostic path or the Twin cache path?
- Which runtime version and terrain-runtime revision should be treated as the official test target?
- Should Artemis III live in a multi-domain location model that supports Earth orbit, lunar orbit, and lunar surface together?
- Should MoonDAO reporting remain separate from this technical project report, or should a short “external ecosystem” section be added weekly?
- Is policy/treaty analysis an explicit project requirement, or only a requested search category for this inventory?

## Evidence inventory

### Core reports and research

- [`NASA_LUNAR_BASE_OVERVIEW.md`](NASA_LUNAR_BASE_OVERVIEW.md)
- [`LUNA2_LUNCO_HANDOVER_REPORT.md`](LUNA2_LUNCO_HANDOVER_REPORT.md)
- [`research/README.md`](research/README.md)
- [`research/missions.md`](research/missions.md)
- [`research/vehicles.md`](research/vehicles.md)
- [`research/locations.md`](research/locations.md)
- [`research/data-model.md`](research/data-model.md)
- [`research/sources.md`](research/sources.md)
- [`research/assumptions.md`](research/assumptions.md)

### Terrain and simulator

- [`direct_luna2_dem.py`](direct_luna2_dem.py)
- [`luna2_terrain_analysis.py`](luna2_terrain_analysis.py)
- [`luna2_direct_sim/README.md`](luna2_direct_sim/README.md)
- [`luna2_twin/twin.toml`](luna2_twin/twin.toml)
- [`luna2_twin/sim/scenes/luna2_static.usda`](luna2_twin/sim/scenes/luna2_static.usda)
- [`luna2_twin/.cache/terrain/luna2/metadata.yaml`](luna2_twin/.cache/terrain/luna2/metadata.yaml)
- [`logs/`](logs/)

### News and audit tooling

- [`news/README.md`](news/README.md)
- [`news/artemis_news_agent.py`](news/artemis_news_agent.py)
- [`news/artemis_news_agent.json`](news/artemis_news_agent.json)
- [`news/artemis_news.md`](news/artemis_news.md)
- [`quality_audit_v2.py`](quality_audit_v2.py)
- [`quality_audit_results_v2.json`](quality_audit_results_v2.json)
- [`data_quality_audit.ipynb`](data_quality_audit.ipynb)
- [`data_quality_report_artifact.json`](data_quality_report_artifact.json)
- [`nasa_lunar_base_data_quality_report.html`](nasa_lunar_base_data_quality_report.html)

## Changelog

| Date | Change |
|---|---|
| 2026-08-22 | Created reusable baseline report from the full visible workspace inventory, research register, terrain artifacts, simulator logs, news agent, and data-quality outputs. |

