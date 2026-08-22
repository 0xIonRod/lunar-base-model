# Lunar Locations, Orbits, and Terrain

Coordinates are intentionally left as `TBD` unless a mission source provides a stable landing point. The first simulator version should use named regions and terrain classes, then add coordinates and local digital-elevation data as a separate geospatial pass.

| ID | Location / orbit | Missions | Terrain or environment | Simulator-relevant data to collect | Source |
|---|---|---|---|---|---|
| LOC01 | Nobile Region, lunar South Pole | M02 | Polar cratered terrain, low Sun angles, volatile-resource context, challenging illumination | Elevation model, crater and slope hazards, illumination timeline, shadow map, dust environment | [NASA Moon Base phases](https://www.nasa.gov/moonbase-phases/) |
| LOC02 | Shackleton Connecting Ridge | M01 | South-polar ridge with precision-landing and illumination interest | Ridge elevation, landing ellipse, local horizon, illumination, plume-surface interaction assumptions | [NASA Moon Base phases](https://www.nasa.gov/moonbase-phases/) |
| LOC03 | Reiner Gamma | M03 | Lunar swirl and strong magnetic anomaly on the lunar surface | Magnetic anomaly map, regolith and albedo classes, local slopes, relay visibility | [Intuitive Machines IM-3](https://www.intuitivemachines.com/missions/lunar/im-3-mission) |
| LOC04 | Far side near Nassau crater | M04, A01 | Radio-quiet far-side terrain; direct Earth communications are blocked | Terrain and hazard map, Earth-visibility mask, relay geometry, thermal environment | [Firefly Mission 2](https://fireflyspace.com/missions/blue-ghost-mission-2/) |
| LOC05 | Schrödinger Basin | M10 | Far-side basin selected for deep-interior, seismic, heat-flow, and subsurface science | Basin geology, seismic station geometry, heat-flow context, relay visibility | [NASA CLPS providers](https://www.nasa.gov/commercial-lunar-payload-services/clps-providers/), [JPL Farside Seismic Suite](https://www.jpl.nasa.gov/missions/farside-seismic-suite/) |
| LOC06 | Lunar South Pole and permanently shadowed regions | M06, M07, M08, M11, M12, M14, M15, M16, M19, A03 | Low Sun angles, long shadows, extreme thermal cycling, possible water ice, difficult communications | Illumination and darkness duration, temperature, ice likelihood, slopes, boulders, comms windows, traverse cost | [NASA Moon Base phases](https://www.nasa.gov/moonbase-phases/), [JAXA LUPEX](https://www.exploration.jaxa.jp/e/program/lunarpolar/) |
| LOC07 | Near rectilinear halo orbit / lunar orbit | M05 | Cislunar three-body dynamics and high-value Gateway-like orbit operations | State vectors, transfer trajectory, orbit maintenance, radiation, Earth/Moon line-of-sight, rendezvous geometry | [NASA CAPSTONE 02](https://www.nasa.gov/directorates/rtmd/nasa-announces-new-spacecraft-technology-demonstration-mission-at-moon/) |
| LOC08 | Leibnitz-Beta Plateau / south-polar region | M13 | Candidate south-polar resource-utilization environment | Plateau topography, illumination, landing hazards, resource and regolith data | [CNSA Chang’e-8](https://www.cnsa.gov.cn/english/n6465652/n6465653/c10670293/content.html) |
| LOC09 | LUPEX south-polar investigation area | M14 | Waypoints selected for distinctive illumination, temperature, geology, and possible water | Waypoint graph, drill points, subsurface layers, illumination, rover energy model | [JAXA LUPEX](https://www.exploration.jaxa.jp/e/program/lunarpolar/) |
| LOC10 | Lunar orbit and communications corridors | M17, A01, A02 | Orbital infrastructure rather than a surface terrain site | Orbital coverage, relay latency, link budgets, handover geometry, navigation service availability | [ispace Mission 2.5](https://www.ispace-inc.com/2026/03/30/statement-regarding-certain-reports-in-domestic-media/), [ESA CM25](https://www.esa.int/About_Us/Ministerial_Council_2025/CM25_Explore_and_discover) |
| LOC11 | Argonaut Mission 1 south-polar landing region | M21 | Autonomous cargo landing with site and passenger payload still under definition | Candidate landing ellipse, terrain class, cargo unloading area, power and communications assumptions | [ESA Argonaut](https://www.esa.int/Science_Exploration/Human_and_Robotic_Exploration/Exploration/Argonaut_Europe_s_lunar_lander_programme) |
| LOC12 | Location TBD | M01, M08, M18, M20, M22, A03 | Not enough stable public location detail in the reviewed sources | Preserve as null; do not infer coordinates from program-level goals | Mission-specific sources in [missions.md](missions.md) |

## Terrain classes for the first model

- **Polar illuminated ridge:** high-relief terrain with intermittent or long-duration sunlight and severe horizon constraints.
- **Permanently shadowed region:** extreme cold and no direct sunlight; model thermal survival and relay dependence explicitly.
- **Cratered polar plain:** mixed slopes, boulders, ejecta, and shadow boundaries; suitable for landing-risk experiments.
- **Magnetic anomaly / lunar swirl:** surface terrain with unusual albedo and magnetic environment; use Reiner Gamma as the first case.
- **Far-side radio-quiet basin:** terrain where Earth is not directly visible; communications depend on a relay asset.
- **Cislunar orbital region:** no surface terrain; model three-body dynamics, radiation, line-of-sight, and relay geometry.
