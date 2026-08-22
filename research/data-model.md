# Mission Data Model

The research should become structured records before it is connected to the terrain or landing simulation. The fields below keep mission facts, uncertain planning values, and simulator inputs separate.

## Mission record

```yaml
mission_id: M02
name: Griffin-1
aliases:
  - Griffin Mission One
operator: Voyager Technologies / Astrobotic
program: NASA Moon Base / CLPS
participating_countries: [United States]
mission_class: robotic_lander_delivery
status: planned
confidence: high
target_date: 2026
target_date_precision: year
target_date_status: target
launch_provider: TBD
launch_vehicle: TBD
transit_profile: TBD
orbit_before_descent: TBD
landing_site_id: LOC01
landing_site_name: Nobile Region
landing_coordinates: TBD
lander_ids: [L03]
rover_ids: [R01]
drone_ids: []
orbital_vehicle_ids: []
payloads:
  - Lunar Dust Level Sensor and Effects on Surfaces
  - Lunar LiDAR Demonstration
  - Laser Retroreflector Arrays
  - Moon Exploration for Titanium with Active Lighting
objectives:
  - surface mobility
  - dust characterization
  - local mapping and navigation
  - resource characterization
terrain_class: cratered_polar_plain
communications: TBD
source_urls:
  - https://www.nasa.gov/moonbase-phases/
last_verified: 2026-08-22
notes: Dates and coordinates remain planning inputs until the provider publishes a firmer manifest.
```

## Required fields

| Field | Purpose |
|---|---|
| `mission_id` | Stable internal key; never reuse it for a different mission. |
| `name`, `aliases` | Human-readable name plus provider or historical names. |
| `operator`, `program`, `participating_countries` | Ownership, program context, and international involvement. |
| `mission_class` | `orbiter`, `lander`, `rover_delivery`, `sample_return`, `crewed_demo`, `infrastructure`, or `portfolio_placeholder`. |
| `status`, `confidence` | Separate schedule state from evidence quality. |
| `target_date`, `target_date_precision`, `target_date_status` | Preserve year/range/TBD without false precision. |
| `launch_provider`, `launch_vehicle` | Earth-launch information; use `TBD` when not publicly fixed. |
| `transit_profile`, `orbit_before_descent` | Add trajectory and orbital parameters in the next modeling phase. |
| `landing_site_id`, `landing_coordinates`, `terrain_class` | Connect mission records to `locations.md` and terrain simulation. |
| `lander_ids`, `rover_ids`, `drone_ids`, `orbital_vehicle_ids` | Normalize vehicle relationships instead of embedding free text only. |
| `payloads`, `objectives` | What is carried and why it matters to the lunar-base model. |
| `communications` | Direct-to-Earth, relay, or constellation dependency. |
| `source_urls`, `last_verified` | Audit trail for every material claim. |

## Relationships

```text
mission
  ├── launches_on → launch_vehicle
  ├── uses → lander
  ├── deploys → rover | drone | surface_asset
  ├── operates_in → landing_site | orbital_region
  ├── depends_on → relay | communications_constellation
  └── carries → payload
```

## Status vocabulary

- `completed` — no longer upcoming; retained only for historical context.
- `planned` — a provider or agency has publicly described the mission.
- `conditional` — dependent on an option, funding, review, or a later mission decision.
- `proposed` — publicly described but not yet at a stable execution commitment.
- `schedule_conflict` — authoritative sources disagree or a revised plan is awaiting approval.
- `portfolio_placeholder` — the program promises additional missions, but individual missions are not named.
