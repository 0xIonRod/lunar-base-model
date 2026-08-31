# Mission 002 research — Griffin-1 and Astrolab FLIP

**Repository mapping:** `M02` → `mission-002`
**Research checked:** 2026-08-30
**Evidence rule:** public mission facts are separated from simulator assumptions.

## Identity and current public baseline

Griffin Mission One is Astrobotic's lunar cargo mission, presented by NASA as
Griffin-1 / Moon Base II. The public target is the lunar South Pole, with the
Nobile Crater region used as the mission reference. Astrolab's FLIP rover is a
manifested payload. Astrobotic announced an agreement to join Voyager
Technologies in 2026; the mission name Griffin-1 remains unchanged in the
current public material.

NASA describes the mission as carrying more than 1,100 lb of cargo. Astrolab
describes FLIP as nearly half a metric ton with 30 kg payload capacity and
describes direct egress from the top of the lander for the upcoming mission.
The exact flight trajectory, landing coordinates, as-built lander data, and
FLIP ICD are not public in the reviewed sources. The MoonDAO backlog additionally
requires a 625 kg payload-class, four-leg polar Griffin prototype with an
isogrid deck, side solar arrays, and two physical egress ramps; those are project
requirements, not public flight facts.

## Video extraction

The supplied [Astrolab FLIP rover design video](https://www.youtube.com/watch?v=UFEMOrg27KE)
is an artist's-rendering design overview for the current FLIP concept heading
to the Moon on Griffin Mission One. Its technical emphasis is the maturation
of full-size batteries, tires, avionics, sensors, and software, plus lunar-dust
mitigation. It is a design reference, not a released mechanical ICD or a
flight-qualification report.

## Engineering interpretation for the simulator

The executable Twin represents the public design intent as separable contracts:

- a guided powered-descent lander with Modelica propulsion, attitude, sensor,
  and touchdown signals;
- a top-deck FLIP body held by a scene-level fixed payload-adapter joint during
  descent, then detached after touchdown;
- two finite-mass, collision-enabled side ramps on physical revolute joints,
  commanded by the scenario after touchdown;
- a ramp approach → ramp exit → waypoints → base-site behavior-tree route;
- four wheels with all-wheel steering as a study topology, explicit motor and
  gearbox chains, finite battery and solar inputs, and a motor thermal network;
- a Griffin-local behavior tree whose target paths match the authored deck
  approach, ramp exit, surface waypoints, and base-site marker.

The four-wheel topology, 450 kg body mass, 2.4 m × 1.8 m × 0.7 m envelope,
0.45 m wheels, 28 V / 83.33 Ah battery proxy, 3 m² solar proxy, actuator limits,
and inertia are simulator assumptions. They must be replaced when Astrolab,
Astrobotic, Voyager, NASA, or a qualified supplier releases FLIP or Griffin
engineering data.

## Primary sources

- [Astrolab FLIP rover](https://www.astrolab.space/flip-rover/)
- [Astrolab FLIP joins Griffin-1](https://www.astrolab.space/2025/02/05/astrolabs-flip-rover-joins-astrobotics-griffin-1-to-the-moon/)
- [Astrolab NASA payload announcement](https://www.astrolab.space/2026/05/18/astrolab-announces-nasa-payloads-for-upcoming-mission-to-the-moon/)
- [NASA Griffin Mission One](https://www.nasa.gov/event/clps-flight-astrobotic-griffin-mission-one/)
- [NASA Moon Base cargo lander update](https://www.nasa.gov/missions/moon-base/nasa-provides-updates-on-moon-base-cargo-landers-tech-demonstrations/)
- [Voyager Technologies / Astrobotic announcement](https://www.astrobotic.com/astrobotic-to-join-voyager-technologies-accelerating-americas-moon-base/)
