# NASA Lunar Base Model

This repository is the working model for a future lunar-base campaign.

The durable project inputs are:

- [`research/`](research/) — curated mission, vehicle, location, source, and assumption records.
- [`missions/`](missions/) — versioned executable mission twins.
- [`scenarios/`](scenarios/) — operational scenario contracts.
- [`tools/`](tools/) — validation and analysis utilities.

The repository contains Mission One: Blue Origin’s Blue Moon MK1 Endurance,
and the executable Astrobotic Griffin-1 / FLIP Twin. The Griffin package now
uses a reproducibly processed LROC NOBILE03 regional terrain crop alongside
its lander and rover study assets. Neither Twin is a flight-ready model;
public facts and unknowns are recorded in
[`missions/mission-001/mission-research.md`](missions/mission-001/mission-research.md).

## Repository map

| Path | Contents |
|---|---|
| [`research/`](research/) | Human-reviewed evidence and explicit research gaps. |
| [`missions/mission-001/`](missions/mission-001/) | M01 Endurance twin, research record, and physical assumptions. |
| [`missions/mission-002/`](missions/mission-002/) | M02 Griffin-1 / FLIP mission record and project index scene. |
| [`twins/astrobotic-griffin-1/`](twins/astrobotic-griffin-1/) | Executable Griffin-1 Twin package with Modelica lander/FLIP integration and handover. |
| [`scenarios/`](scenarios/) | Five initial mission scenarios. |
| [`tools/`](tools/) | Scripts and notebooks; analysis code does not live beside project data. |
| [`NASA_LUNAR_BASE_OVERVIEW.md`](NASA_LUNAR_BASE_OVERVIEW.md) | Plain-language lunar-base context. |

## Working rules

- Keep facts, assumptions, and simulator inputs separate.
- Use `TBD` or `null` when a source does not provide a value.
- Record units, provenance, and confidence for every physical parameter.
- Prefer LunCoSim-native scene and visual-processing features.
- Iterate from the simple twin toward a realistic mission model.
- Validate the repository after each mission-parameter change.

Run the structural checks from the project root:

```powershell
python .\tools\validate_repository.py
```
