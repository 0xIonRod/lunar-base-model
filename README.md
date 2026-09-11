# NASA Lunar Base Model

This repository is the working model for a future lunar-base campaign.

The durable project inputs are:

- [`research/`](research/) — curated mission, vehicle, location, source, and assumption records.
- [`missions/`](missions/) — versioned executable mission twins.
- [`scenarios/`](scenarios/) — operational scenario contracts.
- [`tools/`](tools/) — validation and analysis utilities.

The first twin is intentionally simple: a flat 1 km × 1 km lunar terrain tile,
one lander, and one rover. It is a smoke-test scene, not a flight-ready model.
Values marked `engineering_assumption` must be replaced with sourced
specifications during later iterations.

## Repository map

| Path | Contents |
|---|---|
| [`research/`](research/) | Human-reviewed evidence and explicit research gaps. |
| [`missions/mission-001/`](missions/mission-001/) | Minimal first mission twin and physical assumptions. |
| [`scenarios/`](scenarios/) | Five initial mission scenarios. |
| [`tools/`](tools/) | Scripts and notebooks; analysis code does not live beside project data. |
| [`NASA_LUNAR_BASE_OVERVIEW.md`](NASA_LUNAR_BASE_OVERVIEW.md) | Plain-language lunar-base context. |

## Working rules

- Keep facts, assumptions, and simulator inputs separate.
- Use `TBD` or `null` when a source does not provide a value.
- Record units, provenance, and confidence for every physical parameter.
- Iterate from the simple twin toward realistic lander and rover models.
- Validate the repository after each mission-parameter change.

Run the structural checks from the project root:

```powershell
python .\tools\validate_repository.py
```


## Weekly lunar news

See [research/news/](research/news/) for source-linked briefings, AI-readable evidence records, and actionable simulation research tasks. The weekly GitHub workflow commits news to a review branch and opens a pull request.
