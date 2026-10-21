# Griffin solar geometry acceptance — 21 October 2026

The mounted model is a reconstruction of the three faceted arrays in the
June 2026 hardware reference. The source catalog retains the Astrobotic/NASA
photographs and the source-owned reconstruction datums. Metric dimensions,
attachment stock and clearances remain study assumptions. This checkpoint
does not establish a flight installation drawing, deployment mechanism or
structural qualification.

The active `Verify_GriffinSolarRequirements` objective contains ten requirements:

| Requirement | Acceptance evidence |
| --- | --- |
| GSA-001 | Typed declared count, unique source identities and active composed array roots agree with the canonical lander count. |
| GSA-002 | Every source-declared member and installed cell-row mesh is active and has visibility other than invisible. |
| GSA-003 | Composed centres and collecting normals face the forward and signed forward chamfers; no opposite array is installed. Geometric and dimensionless tolerances retain their separate source values. |
| GSA-004 | Every requirement selected by the resolved verification coverage graph has an unambiguous typed source-catalog link. |
| GSA-005 | Installed dimensions, stations and orientations match the source-defined reconstruction. |
| GSA-006 | Frame, cell surface and backplane mesh envelopes match their source datums. |
| GSA-007 | Installed cell rows retain the common metric pitch rather than squeezing cells to fit narrower faces. |
| GSA-008 | Hinge axis/dimensions/station and both support-link axial endpoints match their source-derived stations, including seating overlap. |
| GSA-009 | Rail, bracket, link and frame bounds preserve the required visible seating overlap. |
| GSA-012 | Adjacent frame corners meet within the source closure tolerance. |

Acceptance predicates are declared in SysML. Rhai reads composed USD facts,
derives measurements and executes the named required constraint memberships.
Missing pose or mesh data remain unavailable observations. GSA-008 previously
referred to an approved mechanism definition that was not present; it now
accepts the actual fixed presentation geometry. Endpoint measurement includes
the authored link rotation, scale, Cube size and translation, so a correctly
sized link cannot pass while pointing away from its mounting stations.

The unbaselined GSA-010 transit Sun-pointing placeholder and its unused verify
and catalog links are removed from this geometry objective. Its required
mission envelope, exceptions and time-aligned attitude/power data remain in
`implementation_gaps.md`. The separate GSA-011 descent Sun-pointing requirement
and mapped runtime case are retained.

Production evidence is under engine
`.cache/codex-evidence/griffin-solar-acceptance-20261021/`. All 170 checks pass,
with typed results for each of the ten declared requirements. Source revision
is `3808276921538989802` at test start and completion. The pinned executable
SHA-256 is
`39f60840b5ea0412f5eb3aabc0769d1ceb57e671050ad563f3674ec62962834c`;
the committed physics baseline and shared runtime assets are the same as the
preceding thermal/bus qualification, independently of concurrent engine edits.

A disposable document fork, authored only through the live USD API, sets the
forward negative-X link rotation to zero while retaining its dimensions and
centre. The solar observer rejects it with exit 1 and exactly one failed
check: `GSA-008-SolarPanelForwardNegativeX-link-endpoints`. Its maximum squared
endpoint error is `0.0014658793861161271 m²` (about 38.3 mm distance), exceeding
the source's 2 mm tolerance. The other 169 checks pass. The test explicitly
selects `GRIFFIN_SOLAR_REQUIREMENTS` as its verdict channel. Fixture-admission,
lint and timeout outcomes do not count as fault rejection. The disposable
layer was removed and owned API ports 4291/4294 were released.

SysML validation has zero errors, no remaining solar formal-acceptance warnings,
and 154 total warnings. Of those, 98 are remaining Griffin usages without
formal acceptance in other packages. The full Griffin acceptance audit and
uncontended performance qualification remain open.
