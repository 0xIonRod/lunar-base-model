# Lunar Mission Research

**Snapshot date:** 2026-08-22  
**Scope:** Upcoming lunar missions and infrastructure relevant to a lunar-base simulator, with emphasis on NASA Moon Base Phase One, Artemis, commercial lunar delivery, and international south-polar exploration.

## Technical summary

The research is organized as a small, auditable mission dataset rather than a single narrative. NASA describes Phase One of its Moon Base architecture as running through 2029 and including more than twenty robotic landings, while only a subset of those missions has been publicly named. The mission register therefore separates named missions from planned assets and an explicit unnamed-deliveries placeholder.

Every mission entry includes a direct source link, target date or date range, location or orbit, operator, carrier/lander, rover or other surface vehicle, purpose, status, and confidence. Dates are planning targets, not guarantees.

## Files

- [missions.md](missions.md) — the main mission register; one row per mission, asset, or clearly marked placeholder.
- [vehicles.md](vehicles.md) — normalized catalog of landers, rovers, drones, orbiters, relays, and crew-transport systems.
- [locations.md](locations.md) — landing sites, orbital regions, terrain descriptions, and simulator-relevant environmental data.
- [data-model.md](data-model.md) — proposed fields and relationships for turning the research into simulator data.
- [sources.md](sources.md) — primary source inventory with retrieval date and intended use.
- [assumptions.md](assumptions.md) — schedule conflicts, confidence rules, aliases, and known gaps.

## Recommended use

Use `missions.md` as the starting input for the first landing-and-surface model. Join each mission to `vehicles.md` and `locations.md` through the IDs proposed in `data-model.md`. Keep uncertain dates, locations, and vehicle assignments as explicit `TBD` or range values instead of silently converting them into precise values.

## Important boundary

This is a research snapshot, not a complete launch manifest for every country or commercial company. It prioritizes missions with an official agency, provider, or program source and includes a separate placeholder for NASA's additional unnamed Moon Base/CLPS deliveries.
