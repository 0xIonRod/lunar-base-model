# Griffin-1 reconstruction basis — reviewed 23 October 2026

This Twin reconstructs the June 2026 integration configuration. Its numerical
study datums live in the typed SysML owners below; this document explains their
meaning. Public photographs establish arrangement and silhouette, not a flight
mechanical ICD. The current native checks and source hashes are recorded in the
[complete review](../twins/astrobotic-griffin-1/contracts/griffin-complete-review-2026-10-23.md).

## Public evidence and configuration boundaries

- [Astrobotic's June 2026 unveiling](https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/)
  and [NASA's June hardware gallery](https://www.nasa.gov/gallery/astrobotics-griffin-1/)
  establish the selected integrated silhouette. The tall, stepped photovoltaic
  faces, leg openings, open lower equipment bays and compact central engine bay
  take precedence over older promotional concepts.
- [Astrobotic's Griffin product page](https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/)
  identifies seven main engines and a 625 kg payload capacity. The
  [2021 payload guide](https://www.astrobotic.com/wp-content/uploads/2022/01/PUGLanders_011222.pdf)
  describes five main engines, four propellant tanks, twelve attitude engines,
  pressure-fed hypergolic propulsion, a 28 V electrical bus and side-mounted
  panels for polar missions. Its five-engine topology is historical.
- [NASA's October 2026 test report](https://www.jpl.nasa.gov/news/nasa-jpl-testing-readies-voyager-technologies-lander-for-moon-mission/)
  gives a 1,265 kg environmental-test spacecraft mass. This is not an identified
  fueled flight mass or a released component mass budget. The
  [associated photojournal](https://science.nasa.gov/photojournal/voyager-technologies-griffin-1-completes-environmental-testing-at-nasa-jpl/)
  identifies the striped upper box as a payload simulator. Test fixtures,
  protective blankets, missing arrays and payload simulators must not become
  flight geometry without configuration evidence.
- [Agile's A110 specification](https://static1.squarespace.com/static/634ee7b32099c80fdfcc8cac/t/6418ea80e1144560207215ca/1679505951405/AgileSpace_A110SpecDoc.pdf)
  supports the retained 111.2 N nominal attitude-thruster rating and 60.96 mm
  exit diameter. Cluster brackets and mounting coordinates remain reconstructed.
- [Astrolab's FLIP page](https://www.astrolab.space/flip-rover/) and
  [Venturi's wheel publication](https://www.venturi.com/wp-content/uploads/2023/06/PR_19_06_2023.pdf)
  support full-size FLEX tires and the selected 930 mm wheel scale. Rover
  wheelbase, track, chassis dimensions and suspension details remain a study
  reconstruction. They do not justify resizing the lander from a visual guess.

References were checked on 23 October 2026. Product-family capacity, a historical
prototype, an environmental-test configuration and the hosted rover are distinct
measurement boundaries.

## Current authored configuration

| Area | Current reconstruction | Authoritative SysML owner |
| --- | --- | --- |
| Bus and deck | 4.50 m exterior bus; 4.40 m perimeter deck; 3.60 m inner tank frame; open structural bays | `GriffinVisualConfigurationRequirements`, `GriffinBusRequirements` |
| Landing gear | Four broad-face stations; three-member appearance; bus-to-foot axial suspension proxy | `GriffinLandingLegRequirements` |
| Propellant packaging | Four separately wrapped spherical tank assemblies; 1.008 m installed body diameter | `GriffinTankRequirements` |
| Main propulsion | Seven actual force owners; one centre and six outer stations on a 0.64 m ring; pressure-fed valve/chamber network | `GriffinPropulsionRequirements` |
| Attitude propulsion | Twelve force owners in four corner clusters; open-bore rings and connected support stock | `GriffinPropulsionRequirements` |
| Solar layout | Three adjacent stepped faces; photo-derived cell contours and leg/equipment openings; source-linked stock colliders | `GriffinSolarRequirements` |
| Ramp mechanism | Two exits, each with two independent three-span wheel tracks; twelve hinges and twelve flight latches | `GriffinRampRequirements` and root/middle/toe component owners |
| Ramp stow/deployment | Inward 120-degree study stow; root clearance, middle unfold, opposite toe unfold, then terrain-fitted root lowering | `GriffinRampRequirements` |
| Ramp contact path | 5.397 m total span; actual toe clearance and deck-entry continuity join the angle/rate/dwell readiness gate | `GriffinRampRequirements` |
| Hosted payload | One fixed adapter until solver-owned release; separate live rover body after retirement | `GriffinFunctionalRequirements` |
| Electrical and thermal | 28 V bus; battery/solar power network; temperature-dependent photovoltaic and reduced thermal models | `GriffinPowerThermalRequirements` |
| Guidance and sensors | Modelica descent/control with IMU, altimeter and environment connections; measured landing/handoff gates | `GriffinSimulationAccuracyRequirements` |
| Terrain and route | NOBILE03 regional DEM study; route frozen to the landed egress frame; annotations resampled at actual terrain coordinates | `Griffin1Requirements::PublicMissionContext` |

All dimensions in this table except the separately sourced tire scale are study
estimates. The old 5.4 m box, diagonal-leg stations, 45-degree outward stow,
equal-span coupled ramps and 0.90 m tires are superseded configurations.
The selected gold MLI finish is an operator presentation preference; it does not
identify flight blanket material or its thermal properties.

The inherited propulsion study uses a 2,000 kg dry-mass input and 1,000 kg per
reactant, with an assumed 2.6 oxidizer/fuel flow ratio. These are not measured
flight inventories. Equal initial reactant masses do not imply equal usable
burn time; oxidizer depletion leaves fuel. Finite helium inventory, regulator
redundancy, slosh, detailed injector physics, discrete flight valve pulsing and
a supplier mass/inertia budget remain unqualified. The new JPL test mass is
recorded as evidence, without substituting it for a different mass boundary.

## Acceptance and operator behavior

USD owns geometry, materials, collision stock and joint topology. SysML owns
configuration and tolerances. Modelica owns continuous subsystem equations.
Rhai observes and sequences the existing native mechanisms. USD changes use
native document operations and saved-document readback, as required by
[the authoring procedure](../twins/astrobotic-griffin-1/contracts/authoring.md).

U / OPEN RAMPS and lander F / DETACH ROVER remain manual operator commands.
A detach acknowledgement means the request was accepted. Solver retirement is
observed separately; automatic control transfer also waits for landing and
ramp readiness. A paused simulation must explain that handover resumes with
simulation time instead of displaying a permanently pending physics claim.
The production release check requires an absent adapter, consistent native
joint graph, exactly-once release/control events, independent travel beyond
the deck, and measured wheel support at the ramp exit. It never moves FLIP
through a pose override.

The earlier claims that compound-child contact was unavailable and articulated
ramps were categorically unsupported are superseded by the native landing,
deployment and panel-contact records. Test results qualify their recorded
source revision and scenario, rather than every conceivable flight condition.
Supplier flight dimensions, impact/load qualification, a calibrated propulsion
inventory, mission thermal validation and clean 60 FPS real-time acceptance
remain separate evidence requirements.
