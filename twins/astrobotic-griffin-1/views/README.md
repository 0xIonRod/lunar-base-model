# Griffin system diagrams

Open the Griffin Twin and `scenes/griffin_1_surface_ops.usda`, select **Systems**,
then choose **View → Load views** and one of these files:

| File | Starting view |
| --- | --- |
| `griffin-full.lunco-view.toml` | Complete scene grouped into ten functional systems |
| `griffin-all-connections.lunco-view.toml` | Every composed prim and authored connection, without collapsed groups |
| `griffin-propellant-feed.lunco-view.toml` | Both reservoirs and all seven engine assemblies; expand an engine to see its valve, chamber, plume and wall parts |
| `griffin-engine-detail.lunco-view.toml` | Engine01 internal valve-to-chamber connections and readable declared ports |

The full view includes main propulsion, RCS, electrical and thermal systems,
GNC and dynamics, landing gear, static exit and payload, tether rigging, FLIP,
structure, and external interfaces. Counts include geometry and other composed
USD prims. Collapsed groups retain every original boundary endpoint; select a
port or wire to inspect exact USD identities and connected peers. Expand a
group for its internal connections, or open a program facet for its source.

Main-engine plumbing is authored in USD: each shared tank feeds seven valves,
and each fuel/oxidizer valve pair feeds its own chamber. All fourteen valves
and seven chambers belong to one coupled MainPropulsion solver, together with
the reservoirs, nozzle design, plume photometry and nozzle-wall thermal models.
The engine detail is scoped to internal wiring; use the feed view for external
tank, control and telemetry connections. Modelica owns equations and state.
Pressure-feed parameters remain study
assumptions; the four visible tank assemblies are render geometry, while the
fuel and oxidizer reservoir models own propellant mass. RCS retains its existing
simplified feed-availability and consumption model.

Tether forces are produced by the tether Modelica model and applied by the
mission's native wrench bridge. They are not static USD signal connections;
enable **Scenario access** to inspect the admitted scenario reads and writes
as a separate dashed overlay. Counts and exact endpoints remain available when
grouped cards aggregate repeated accesses. Access declarations authorize actions;
they do not claim measured force-transfer provenance. The exit ramp is static.
See `contracts/griffin-safe-egress-2026-11-13.md` for the guarded deployment and
explicit disconnect contract.

USD owns topology; these view files own grouping and placement. New composed
nodes remain visible even before they are assigned to a saved group. The saved
source URI is stable across Twin remounts.

The electrical/thermal network includes the winch converter, heat source, thermal
mass and radiator. Expand **Power & thermal** to follow the two signed spool-power
inputs, damping heat and solved drive-availability return to the tether. The
[system architecture](../contracts/system-architecture.md) distinguishes solved
parts, lumped representations and unresolved physical detail.
