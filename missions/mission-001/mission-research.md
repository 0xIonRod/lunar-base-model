# Mission One research — Blue Moon MK1 Endurance

**Repository mapping:** `M01` → `mission-001`  
**Research checked:** 2026-08-26  
**Evidence rule:** public mission facts are separated from simulator assumptions.

## Confirmed mission identity

Mission One is Blue Origin’s **Blue Moon Mark 1 (MK1) Endurance**. NASA
describes it as an uncrewed lunar lander demonstration targeting the lunar
South Pole and attempting a landing at the Shackleton Connecting Ridge. Its
demonstrations include precision landing, autonomous guidance/navigation/
control, cryogenic propulsion, and lunar-environment characterization.

The two NASA payloads are:

- **SCALPSS** — Stereo Cameras for Lunar Plume-Surface Studies, which images
  the interaction between the landing-engine plume and the lunar surface.
- **LRA** — Laser Retroreflector Array, which provides a precise reference
  point for lunar-orbit tracking.

Blue Origin describes MK1 as a single-launch cargo lander that remains on the
surface, uses the New Glenn 7 m fairing, and can deliver up to 3 metric tons of
cargo. Its Pathfinder mission description identifies the BE-7 engine,
cryogenic fluid power/propulsion, avionics, continuous downlink
communications, and precision landing within 100 m site accuracy.

## Parameter register

| Parameter | Current value | Evidence status |
|---|---:|---|
| Target year | 2026 | Public NASA planning information |
| Launch window | No earlier than fall 2026 | Public NASA mission announcement |
| Landing region | Shackleton Connecting Ridge, lunar South Pole | Public NASA mission description |
| Lander type | Blue Moon MK1 / Endurance | Public NASA and Blue Origin descriptions |
| Cargo capability | Up to 3,000 kg | Public Blue Origin MK1 page; capability, not Endurance manifest mass |
| Lander dimensions | `TBD` | Not published in reviewed primary sources |
| Lander dry mass | `TBD` | Not published in reviewed primary sources |
| Propellant | Liquid oxygen / liquid hydrogen for BE-7 | Public Blue Origin BE-7 description |
| Propellant mass and tank volume | `TBD` | Not published in reviewed primary sources |
| BE-7 vacuum thrust | 44.5 kN per engine | Public Blue Origin engine page |
| BE-7 deep-throttle floor | 8.9 kN per engine | Public Blue Origin engine page |
| Specific impulse | `TBD` | Not published in reviewed primary sources |
| Engine count | `TBD` | Not published in reviewed primary sources |
| Solar-array area and placement | `TBD` | Not published in reviewed primary sources |
| Battery capacity | `TBD` | Not published in reviewed primary sources |
| Rover carried by Endurance | None publicly manifested | NASA lists SCALPSS and LRA as the two payloads |

## Simulator representation

The executable twin intentionally uses a flat 1 km × 1 km plane. This is a
local test tile, not the geographic size or shape of the Shackleton Connecting
Ridge. It is useful for validating landing, payload, communications, and
telemetry behavior before importing a real DEM.

The rover in the scene is explicitly a **simulator-only test asset**. It is
retained to exercise the repository’s lander/rover interaction scenarios and
must not be presented as an Endurance payload. Replace or remove it when a
mission-faithful Endurance scene is required.

## Primary sources

- [NASA Moon Base phases](https://www.nasa.gov/moonbase-phases/)
- [NASA Moon Base cargo landers and technology demonstrations](https://www.nasa.gov/missions/moon-base/nasa-provides-updates-on-moon-base-cargo-landers-tech-demonstrations/)
- [NASA Blue Moon Mark 1 vacuum testing](https://www.nasa.gov/missions/artemis/blue-origin-moon-lander-completes-testing-at-nasa-vacuum-chamber/)
- [Blue Origin Blue Moon Mark 1](https://www.blueorigin.com/blue-moon/mark-1)
- [Blue Origin BE-7 engine](https://www.blueorigin.com/engines/be-7)

