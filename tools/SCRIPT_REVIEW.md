# Python script review

Reviewed 2026-08-26.

| Script | Decision | Reason |
|---|---|---|
| `validate_repository.py` | Keep active | Small, dependency-free structural and stale-reference check for the current repository. |
| `archive/quality_audit.py` | Removed | Duplicate legacy raster audit hard-coded to deleted terrain paths and old snapshot outputs. |
| `archive/quality_audit_v2.py` | Removed | Newer duplicate of the same obsolete terrain/image-processing pipeline. |
| `archive/news/artemis_news_agent.py` | Removed | News collection is not a simulator input or part of the first-mission model. |
| `archive/lunar_base_research_agent.py` | Removed | Snapshot/brief generator wrote dated outputs and targeted the previous research layout. |

The active workflow should use LunCoSim for scene, terrain, and visual
processing. Python remains appropriate for small repository checks or offline
data preparation only when the simulator does not provide the required feature.

