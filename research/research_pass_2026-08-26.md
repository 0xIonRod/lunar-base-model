# Research Pass — 2026-08-26

This is a public-source update against the six gaps in `assumptions.md`. It is a research register, not a flight-dynamics data package. `TBD` means that the information was not found in an authoritative public source as of 2026-08-26.

## 1. Launch vehicle, launch site, and launch window

| Register item | Publicly supported result | What remains missing | Modeling status |
|---|---|---|---|
| M01 Blue Moon MK1 Endurance | Blue Origin **New Glenn** is the launch vehicle family for MK1. The mission is targeted for **fall 2026** and lands at the Shackleton Connecting Ridge. New Glenn launches from **LC-36, Cape Canaveral Space Force Station**. | Exact launch date, T-0, pad assignment for the lunar mission, and translunar injection profile. | Use `New Glenn / LC-36 / fall 2026 / T-0 TBD`. |
| M02 Griffin-1 | Astrobotic selected **SpaceX Falcon Heavy** from **LC-39A, Kennedy Space Center** in the original Griffin contract announcement. The current mission is described as launching in **late 2026**; the current Astrobotic update does not re-issue a new pad or window. | Current launch-provider confirmation, exact date/window, and final trajectory. | Keep Falcon Heavy and LC-39A as a source-history value with a verification flag. |
| M03 IM-3 Trinity | Intuitive Machines identifies Nova-C Trinity, Reiner Gamma, and Altus-1 as flying on the same rocket. The mission was originally contracted on **Falcon 9**; current planning remains a 2026 mission in NASA/IM materials. | Exact Florida pad, launch date/T-0, and final launch opportunity. | Use `Falcon 9 / Florida (pad TBD) / 2026 / T-0 TBD`. |
| M04 Blue Ghost Mission 2 | Firefly publishes **NET 2027**, a roughly **44-day** lunar transit, and a dual stack of Blue Ghost plus Elytra Dark. An investor presentation describes a seven-day launch window each month, but the launch vehicle and pad are not identified on the current mission page. | Launch vehicle, pad, exact window, and final injection state. | Do not infer Falcon 9 from Mission 1 heritage. Keep vehicle/site `TBD`. |
| M07 VIPER delivery | NASA identifies a **second Blue Moon MK1** lander and a late-2027 South Pole delivery. The vehicle family implies New Glenn, but NASA has not published a mission-specific pad or T-0. | Firm launch contract, exact date/window, and mission designation. | Use `Blue Moon MK1 / New Glenn family / late 2027 / exact site and T-0 TBD`. |
| M08 IM-4 | Intuitive Machines selected **SpaceX Falcon 9** and says the mission is scheduled for **2027** and launches from Florida. | Exact pad, date/T-0, trajectory, and landing ellipse. | Use `Falcon 9 / Florida (pad TBD) / 2027 / T-0 TBD`. |
| M10 CP-12 / Draper / ispace-U.S. | ispace-U.S. states **APEX 1.0**, **Falcon 9**, and **Kennedy Space Center** for the legacy CP-12 plan. The public mission page describes a five-day launch window each month. ispace's 2026 schedule update changes the U.S. mission proposal to 2030 and says NASA approval is pending. | Whether APEX 1.0 remains the flight vehicle, exact month/date, pad, and approved 2030 plan. | Preserve the schedule conflict; do not collapse it into a single firm date. |
| M11 MoonFall | NASA says four drones ride to the Moon on Firefly **Elytra** and target arrival in 2028. | Earth launch vehicle, launch site/window, and detailed carrier trajectory. | Model as Elytra-carried; Earth launch fields `TBD`. |
| M12 CLV-1/Pegasus deliveries | NASA selected Blue Origin to deliver Astrolab **CLV-1** and Lunar Outpost **Pegasus** in 2028 under two task orders. | Named delivery mission(s), lander, launch vehicle, pad, date, and landing site. | Keep delivery mission ID and carrier `TBD`; these are surface rovers, not launch vehicles. |
| M18 ispace Mission 3 ULTRA | ispace and MHI signed a contract for **H3**, currently scheduled for **2028**. H3 operations are based at Tanegashima, but the release does not state the pad or launch window. | Exact H3 configuration, pad, date/T-0, landing site, and trajectory. | Use `H3 / Tanegashima area (pad TBD) / 2028 / T-0 TBD`. |
| M19 ispace Mission 4 / MAGPIE | The ULTRA design is intended for later Mission 4, planned for 2029. | Launch contract, launch vehicle, site/window, landing site, and final lander designation. | Keep all launch fields `TBD`; do not automatically inherit Mission 3's H3 contract. |

The launch sources establish vehicle families and planning years, not flight-ready launch opportunities. Exact launch windows should remain ranges until the operator publishes a mission-specific launch notice or press kit.

## 2. Landing coordinates, ellipses, and local DEMs

Public sources currently provide named regions or landmarks, not mission-grade targeting products:

- Endurance: Shackleton Connecting Ridge.
- Griffin-1: Nobile region / Nobile Crater area.
- IM-3: Reiner Gamma.
- Blue Ghost Mission 2: far side near Nassau crater.
- CP-12: Schrödinger Basin.
- Chang'e-7: South Pole-Aitken Basin, with the public opportunity document specifying latitude above 85°S.
- Chang'e-8: Leibnitz-Beta Plateau / south-polar region.

No authoritative public source located in this pass provides the final latitude/longitude, covariance, orientation, or landing ellipse for these future missions. NASA's public landing-region work is useful for regional context and candidate-site analysis, but it is not a substitute for a provider's final targeting product.

For a local simulator tile, the defensible public data stack is:

1. LRO/LOLA global topography for the base DEM and slopes.
2. LROC NAC/WAC imagery for meter-scale hazard context and regional illumination.
3. Diviner thermal data for temperature and cold-trap context.
4. NASA's Lunar Surface Data Book and Moon-to-Mars geospatial products where a named south-polar region overlaps the mission.

MoonFall is especially relevant to the future data contract: NASA says its drones are intended to create high-resolution digital terrain maps of potential Artemis landing sites. That is a planned future mapping product, not a currently available landing ellipse for the missions above.

Recommended schema addition: `target_region`, `target_lat_lon`, `ellipse_major_km`, `ellipse_minor_km`, `ellipse_azimuth_deg`, `dem_source`, `dem_resolution_m`, and `illumination_epoch`. Keep the numeric fields null until a mission-specific product is released.

## 3. Surface power, thermal survival, and lunar-night plans

| Asset | Publicly supported power/thermal information | Public gap |
|---|---|---|
| Endurance | Blue Origin's MK1 is being tested in thermal-vacuum conditions; NASA describes a precision-landing and cryogenic-propulsion demonstration. | No public power budget, battery capacity, radiator sizing, or lunar-night survival plan. |
| Griffin-1 | Griffin has a solar panel and battery; Astrobotic says the panel is Sun-pointed where possible and the battery covers eclipse/short-duration loads. | No mission-level energy balance, thermal limits, or night-survival duration. |
| FLIP | Astrolab publishes a collapsible solar array charging a Venturi battery. FLIP is intended to traverse and validate systems for FLEX, including lunar-night survival. | No public watt-hours, solar-array output, thermal set points, or hibernation timeline. |
| IM-3 Trinity | Public IM material identifies a 130 kg payload-to-Moon Nova-C and Reiner Gamma operations. | No public IM-3 lander power/thermal budget or lunar-night plan. |
| Blue Ghost Mission 2 | Firefly says Blue Ghost will support payloads for at least 10 days, then power off before lunar nightfall; LuSEE-Night remains on the lander and is intended to operate up to two years. Firefly's general Blue Ghost service page advertises 400 W and day/night capability, but the mission-specific page governs this mission. | No mission-specific array/battery/thermal numbers or exact shutdown state. |
| CP-12 APEX 1.0 | Public material describes the far-side relay architecture and payloads, but not the lander's survival architecture. | No public power, thermal, or night-survival data. |
| LUPEX | JAXA explicitly identifies surface mobility, excavation, and night survivability as technology objectives; the rover uses a deployable flat solar array. | Detailed lander/rover energy and thermal budgets are not public. |
| Chang'e-7/8 | Public mission descriptions establish polar science and resource-utilization objectives. | Detailed power generation, thermal-control, and lunar-night operations are not publicly specified in the reviewed sources. |
| CLV-1/Pegasus | NASA requires South Pole operation, autonomous/teleoperated modes, and advanced power management and communications for LTV-class vehicles. | Vehicle-specific power, thermal, and night-survival designs are not public. |

NASA's broader surface-technology work confirms why these fields matter: lunar day/night periods are each roughly 14–15 Earth days, with extreme temperature swings, and sustained operations need localized power through darkness. The Northrop Grumman demonstrations described by NASA are the most direct Moon Base technology activity found in this pass for shared surface power and survive-the-night systems.

## 4. Detailed payload manifests

### Chang'e-7

CNSA publicly confirms six international instruments from six countries plus one international organization:

- Italian laser retroreflector array on the lander.
- Russian lunar dust/electric-field instrument on the lander.
- International Lunar Observatory Association lunar telescope on the lander.
- Egypt/Bahrain lunar hyperspectral camera on the orbiter.
- Swiss/Chinese two-channel Earth-radiation spectrometer on the orbiter.
- Orbiter space-weather global-monitoring sensor package.

The mission architecture is publicly described as orbiter, lander, relay satellite, rover, and flyby spacecraft. A scientific mission paper and Chinese Academy of Sciences reporting describe an 18-payload configuration, but a complete, current, authoritative instrument-by-instrument flight manifest was not found. Keep the Chinese core payloads and final interfaces as `partially disclosed`.

### Chang'e-8

CNSA confirms a 2029 target, the Leibnitz-Beta Plateau region, and international payloads from 11 countries/regions plus one international organization. The publicly named collaborative projects include a Hong Kong multifunctional robot; Pakistan/ISTVS and Türkiye rovers; South African and Peruvian radio-astronomy instruments; Italian laser retroreflectors; Russian plasma/dust and high-energy-particle instruments; a Thai neutron analyzer; Bahrain/Egypt imaging; and an Iranian lunar-potential monitor.

This is a list of selected international projects, not a full Chinese mission manifest. The lander, rover, ISRU hardware, relay, and core Chinese instrument list remain incomplete in public sources.

### Chandrayaan-4

ISRO publicly defines five modules: Ascender, Descender, Re-entry, Transfer, and Propulsion. Two LVM3 launches are planned: one for the Descender + Ascender stack and one for the Transfer + Re-entry + Propulsion stack. The surface sampling robot is designed to collect approximately 2–3 kg of surface samples; a drill will collect subsurface material; cameras and module sensors provide landing-site context.

ISRO has not published a conventional finalized payload table comparable to Chandrayaan-3's instrument manifest. The five-module architecture and sample-handling hardware are public; detailed instrument names, allocations, masses, power, and data rates remain `TBD`.

### Artemis IV/V

NASA's current Gateway description identifies these co-manifested elements:

- Artemis IV: SLS Block 1B + Orion + Lunar I-Hab to Gateway, plus a commercial HLS for the surface expedition.
- Artemis V: SLS Block 1B + Orion + Lunar View to Gateway, plus a commercial HLS for the surface expedition.
- Artemis V surface mobility: NASA-selected LTV capability; NASA has also selected Blue Origin to deliver CLV-1 and Pegasus in 2028 under separate task orders.
- Publicly selected LTV science instruments: AIRES and L-MAPS for an LTV, with UCIS-Moon selected for a future orbital opportunity.

There is no final flight manifest with payload masses, stowage locations, power/data interfaces, or exact HLS surface cargo in the reviewed public sources. Model the architecture, not a complete manifest.

### Unnamed CLPS / Moon Base deliveries

NASA's Moon Base materials describe an expanding cadence of robotic landings and identify broad classes of cargo, but they do not publish a complete named mission list, provider assignment, payload manifest, landing ellipse, or launch contract for the unnamed deliveries. Keep the existing `A03` portfolio placeholder and do not expand it into fabricated mission rows.

## 5. Orbital state vectors, transfers, and relay-link budgets

| Asset | Publicly usable information | Not public / not safe to synthesize as fact |
|---|---|---|
| CAPSTONE 02 | Two approximately 400 kg Terran Orbital spacecraft; 2027 target; rendezvous/proximity operations, formation flying, autonomous navigation, communications, and radiation characterization. A NASA technical presentation describes low-energy transfer to the same 9:2 southern L2 NRHO. | Final launch state, SPICE kernels/TLEs, epoch, maneuver plan, covariance, and mission-specific RF link budget. |
| Altus-1 | First of five Intuitive Machines lunar relay satellites; rides with IM-3; carries NASA NavCube3-mini and three payloads. A published network study describes a high-inclination elliptical frozen lunar-orbit concept and a ballistic lunar transfer for the first satellite. | Final orbital elements, deployment epoch, station-keeping profile, antenna/EIRP/sensitivity, availability, and service link budget. |
| Lunar Pathfinder | Deployed from Firefly's Elytra after lunar transfer; Firefly states dual S-band user links and X-band Earth relay. Public SSTL service material gives up to 30 kbps Earth forward, up to 5 Mbps Earth return, and up to 2 Mbps-class lunar-user service depending on link and service mode. | Final orbit elements, deployment state, provider margin tables, pointing losses, coding/modulation schedule, and mission-specific availability. |
| LASSO | DARPA describes a lunar-orbit spacecraft for autonomous navigation, maneuverability, and high-resolution resource mapping; the stated goal is identifying areas above 5% water concentration at no larger than 4 km² resolution. | Performer, launcher, launch site, orbit, transfer, state vectors, sensor characteristics, and link budget. |
| Moonlight | ESA describes five satellites—one communications and four navigation—in highly elliptical lunar orbits, with south-pole coverage, initial service by end-2028, and full service by 2030. ESA also advertises up to 3 m navigation performance. | Final constellation elements, phasing, launch manifest, ground-station allocation, RF budgets, service availability, and operational ephemerides. |

For simulator use, create a separate `ephemeris_source` field with values such as `official_kernel`, `operator_tle`, `published_reference_orbit`, `analyst_assumption`, and `TBD`. Do not turn a reference orbit into a claimed operational state vector.

## 6. CLV-1 / Pegasus relationships

The key relationship is now clear:

`Blue Origin commercial lunar delivery mission(s) → surface delivery and deployment → Astrolab CLV-1 + Lunar Outpost Pegasus → remote/autonomous operations → Artemis crew use`

NASA explicitly says Blue Origin will deliver both vehicles in 2028 under two task orders, with options for later deliveries. CLV-1 and Pegasus are unpressurized surface vehicles; they are not launch vehicles and are not the Artemis SLS/Orion stack. The current public material does not name the Blue Origin cargo lander serial number, mission name, launch vehicle flight number, landing site, or whether both rovers fly on one mission or on separate missions.

The Griffin-1 relationship is different: its publicly manifested Astrolab vehicle is **FLIP**, a technology demonstrator for FLEX. Griffin-1 should not be joined to CLV-1 or Pegasus unless NASA or Astrolab publishes a new task-order assignment.

## Data-model actions

1. Keep exact launch date/T-0, final pad, landing ellipse, state vector, and detailed link-budget fields nullable.
2. Add provenance and confidence at field level; mission-level confidence is too coarse for these mixed public/private records.
3. Split `lander_or_carrier` from `surface_vehicle_delivery` so CLV-1/Pegasus do not appear as launchers.
4. Add `manifest_scope`: `full`, `international_subset`, `architecture_only`, or `unknown`.
5. Add `power_mode`: `day_only`, `night_survival_demo`, `night_hibernation`, `continuous_infrastructure`, or `unknown`.

## Primary sources

- [NASA Moon Base phases](https://www.nasa.gov/moonbase-phases/)
- [NASA Moon Base cargo landers and technology demonstrations](https://www.nasa.gov/missions/moon-base/nasa-provides-updates-on-moon-base-cargo-landers-tech-demonstrations/)
- [NASA Gateway mission description](https://www.nasa.gov/reference/gateway-about/)
- [NASA CAPSTONE 02 announcement](https://www.nasa.gov/directorates/rtmd/nasa-announces-new-spacecraft-technology-demonstration-mission-at-moon/)
- [Firefly Blue Ghost Mission 2](https://fireflyspace.com/missions/blue-ghost-mission-2/)
- [ispace-U.S. Mission 3 / CP-12](https://ispace-us.com/mission-3/)
- [ispace/MHI ULTRA launch agreement](https://www.ispace-inc.com/2026/07/29/ispace-and-mitsubishi-heavy-industries-agree-to-launch-mission-3-ultra-lunar-lander-aboard-h3-rocket/)
- [CNSA Chang'e-7 international instruments](https://www.cnsa.gov.cn/english/n6465652/n6465653/c10517200/content.html)
- [CNSA Chang'e-8 international payload update](https://www.cnsa.gov.cn/english/n6465652/n6465653/c10670293/content.html)
- [ISRO Chandrayaan-4 architecture](https://www.isro.gov.in/ISRO_EN/UnionCabinetApprovesIndiasMission.html)
- [DARPA LASSO](https://www.darpa.mil/research/programs/lunar-assay-small-satellite-orbiter)
- [ESA Moonlight](https://www.esa.int/Newsroom/Press_Releases/ESA_launches_Moonlight_to_establish_lunar_communications_and_navigation_infrastructure)
- [NASA lunar surface technology](https://www.nasa.gov/lunar-surface-technology/)
