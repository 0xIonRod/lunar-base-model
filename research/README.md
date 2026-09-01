# Lunar Mission Research

The repository orientation and simulator workflow live in the root [`README.md`](../README.md). This directory is the curated evidence layer for missions, vehicles, locations, sources, and assumptions.
**Scope:** Upcoming lunar missions and infrastructure relevant to a lunar-base simulator, with emphasis on NASA Moon Base Phase One, Artemis, commercial lunar delivery, and international south-polar exploration.

## Technical summary

The research is organized as a small, auditable mission dataset rather than a single narrative. NASA describes a broad Moon Base architecture, while only a subset of missions has been publicly named. The mission register therefore separates named missions from planned assets and an explicit unnamed-deliveries placeholder.

Every mission entry includes a direct source link, target date or date range, location or orbit, operator, carrier/lander, rover or other surface vehicle, purpose, status, and confidence. Dates are planning targets, not guarantees.

## Files

- [missions.md](missions.md) — the main mission register; one row per mission, asset, or clearly marked placeholder.
- [vehicles.md](vehicles.md) — normalized catalog of landers, rovers, drones, orbiters, relays, and crew-transport systems.
- [locations.md](locations.md) — landing sites, orbital regions, terrain descriptions, and simulator-relevant environmental data.
- [data-model.md](data-model.md) — proposed fields and relationships for turning the research into simulator data.
- [sources.md](sources.md) — primary source inventory with retrieval date and intended use.
- [assumptions.md](assumptions.md) — schedule conflicts, confidence rules, aliases, and known gaps.
- [flip_rover.md](flip_rover.md) — Griffin-1 FLIP video extraction, public engineering facts, and simulator parameter boundary.

## Recommended use

Use `missions.md` as the starting input for the first landing-and-surface model. Join each mission to `vehicles.md` and `locations.md` through the IDs proposed in `data-model.md`. Keep uncertain dates, locations, and vehicle assignments as explicit `TBD` or range values instead of silently converting them into precise values.

## Important boundary

This is a maintained research register, not a complete launch manifest for every country or commercial company. It prioritizes missions with an official agency, provider, or program source and includes a separate placeholder for NASA's additional unnamed Moon Base/CLPS deliveries. Generated briefs and dated snapshot exports are intentionally kept out of this folder; update the source registers and preserve uncertainty instead.

