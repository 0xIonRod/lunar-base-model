// Current FreeCAD v3 contract. Existing runtime FlipRequirements stays separate.
// Review uses SysML v2 concepts. Parser/tool conformance is not established.
// Numerical scalars follow repository conventions: units are explicit in names
// and docs (Mm, Mm3, Kg, Deg), not dimensionally checked quantity types.
package FlipCadRequirements {
    private import ScalarValues::*;
    part def CadStudy {
        doc /* Reference-informed CAD only. All dimensions and angles are estimates.
        Four-wheel skid steer and 480 kg launch constraint: Astrolab LPSC 2026
        https://www.hou.usra.edu/meetings/lpsc2026/pdf/1874.pdf .
        Side hinge orientation: official rendering
        https://www.astrolab.space/wp-content/uploads/2025/06/Picture1-1.jpg .
        30 kg is historical payload capacity, not measured CAD mass.
        Actual mass, component masses, center of mass, inertia and dynamics TBD. */
        attribute wheelCount : Integer = 4;
        attribute wheelBandRadiusMm : Real = 450.0;
        attribute wheelRibRadiusMm : Real = 458.0;
        attribute wheelWidthMm : Real = 280.0;
        attribute wheelbaseMm : Real = 1700.0;
        attribute trackMm : Real = 2000.0;
        attribute wheelCenterHeightMm : Real = 458.0;
        attribute baseplateWidthMm : Real = 1460.0;
        attribute baseplateLengthMm : Real = 2100.0;
        attribute baseplateThicknessMm : Real = 20.0;
        attribute bodyWidthMm : Real = 1476.0;
        attribute bodyLengthMm : Real = 2116.0;
        attribute bodyHeightMm : Real = 396.0;
        attribute panelAlongHingeMm : Real = 1800.0;
        attribute panelFoldSpanMm : Real = 1380.0;
        attribute panelThicknessMm : Real = 20.0;
        attribute hingeXmm : Real = -690.0;
        attribute hingeYmm : Real = 0.0;
        attribute hingeZmm : Real = 950.0;
        attribute solarMinDeg : Real = 0.0;
        attribute solarMaxDeg : Real = 90.0;
        attribute solarExampleDeg : Real = 82.0;
        attribute launchMassConstraintKg : Real = 480.0;
        attribute legacyRuntimeMassKg : Real = 450.0;
        attribute historicalPayloadCapacityKg : Real = 30.0;
        attribute gapToleranceMm : Real = 0.01;
        attribute penetrationToleranceMm3 : Real = 1.0;
        attribute frame : String = "right-handed mm; X lateral; Y longitudinal; front -Y; Z up";
        attribute steering : String = "skid steer; native CAD wheel roll only";
        attribute actualMassStatus : String = "TBD; not calculated or measured";
        attribute runtimePromotionStatus : String = "OPEN; legacy USD/Modelica not updated";
        attribute panelSamplesDeg : String = "0,5,10,20,30,40,50,60,70,82,90";
        attribute wheelSamplesDeg : String = "0,15,45,90,180,270; right=-left; panel closed";
    }
    part cadStudy : CadStudy;
    requirement def FR001 {
        subject model : CadStudy;
        doc /* FR-001: CAD shall identify chassis, exterior, battery, controller and payload deck as distinct named components. Verification allocation: V1 requirements_check.json. */
    }
    requirement fr001 : FR001;
    requirement def FR002 {
        subject model : CadStudy;
        doc /* FR-002: CAD shall expose four fixed-X-axis wheel stations and left/right independent roll controls; skid steering is source-backed, traction dynamics remain OPEN. Verification allocation: V2 requirements_check.json; V4 v3_audit_latest.json. */
    }
    requirement fr002 : FR002;
    requirement def FR003 {
        subject model : CadStudy;
        doc /* FR-003: Panel backing, frame, cells, moving knuckles, sensor bar and cameras shall share panel motion. Verification allocation: V1/V3 requirements_check.json. */
    }
    requirement fr003 : FR003;
    requirement def FR004 {
        subject model : CadStudy;
        doc /* FR-004: Panel shall hinge along global Y at (-690,0,950) mm; native Rz(90) Rx(-clamp(SolarAngle,0,90)); 0 to 90 degree effective geometry angle, including out-of-range scripted requests, saved 0, example 82. Verification allocation: V3 requirements_check.json; v3_presentation.json. */
    }
    requirement fr004 : FR004;
    requirement def FR005 {
        subject model : CadStudy;
        doc /* FR-005: Battery and controller shall remain fixed during panel actuation. Verification allocation: V3 requirements_check.json. */
    }
    requirement fr005 : FR005;
    requirement def FR006 {
        subject model : CadStudy;
        doc /* FR-006: Future Twin shall hold rover before release and release only after touchdown and authorized egress. OPEN: no CAD release mechanism. Verification allocation: V6 OPEN runtime integration. */
    }
    requirement fr006 : FR006;
    requirement def FR007 {
        subject model : CadStudy;
        doc /* FR-007: CAD major subassemblies shall remain separately selectable. Verification allocation: V1 requirements_check.json. */
    }
    requirement fr007 : FR007;
    requirement def FR008 {
        subject model : CadStudy;
        doc /* FR-008: Specifications shall identify units, configuration, source/estimate and verification status. Verification allocation: V7 flip-sysml-review.md. */
    }
    requirement fr008 : FR008;
    requirement def FR009 {
        subject model : CadStudy;
        doc /* FR-009: CAD wheel radii, width, center coordinates, wheelbase and track shall match this study contract within 0.01 mm. Verification allocation: V2 requirements_check.json. */
    }
    requirement fr009 : FR009;
    requirement def FR010 {
        subject model : CadStudy;
        doc /* FR-010: Mass record shall distinguish 480 kg source constraint, unknown actual mass and 450 kg legacy simulation assumption. No CAD mass compliance claimed. Verification allocation: V7 documentation review; physical mass OPEN. */
    }
    requirement fr010 : FR010;
    requirement def FR011 {
        subject model : CadStudy;
        doc /* FR-011: CAD chassis and panel dimensions shall match the study contract within 0.01 mm. Verification allocation: V2 requirements_check.json. */
    }
    requirement fr011 : FR011;
    requirement def FR012 {
        subject model : CadStudy;
        doc /* FR-012: Each physical solid shall be valid and attached through its named chain to the baseplate, gap at most 0.01 mm. Verification allocation: V4 v3_audit_latest.json. */
    }
    requirement fr012 : FR012;
    requirement def FR013 {
        subject model : CadStudy;
        doc /* FR-013: The specified 11 panel and 6 wheel sample sets shall show no tested intersection above 1 mm^3. Continuous clearance and combined pose products remain OPEN. Verification allocation: V4 v3_audit_latest.json. */
    }
    requirement fr013 : FR013;
    requirement def FR014 {
        subject model : CadStudy;
        doc /* FR-014: Saved CAD shall reopen with visible physical leaves and retained native expressions. Verification allocation: V3 v3_presentation.json; V5 v3_geometry_comparison.json. */
    }
    requirement fr014 : FR014;
    requirement def FR015 {
        subject model : CadStudy;
        doc /* FR-015: Future runtime promotion shall preserve side hinge, separate panel, units and skid steering and verify drive, release, energy and telemetry. OPEN. Verification allocation: V6 OPEN runtime integration. */
    }
    requirement fr015 : FR015;
    requirement def FR016 {
        subject model : CadStudy;
        doc /* FR-016: Handoff shall retain baseline and preserve all 84 non-Power physical components exactly. Verification allocation: V5 v3_change_report.json. */
    }
    requirement fr016 : FR016;
    verification def InspectCAD {
        subject model : CadStudy;
        verify fr001;
        verify fr007;
    }
    verification def MeasureCAD {
        subject model : CadStudy;
        verify fr002;
        verify fr009;
        verify fr011;
    }
    verification def ExercisePanel {
        subject model : CadStudy;
        verify fr003;
        verify fr004;
        verify fr005;
        verify fr014;
    }
    verification def AuditGeometry {
        subject model : CadStudy;
        verify fr012;
        verify fr013;
    }
    verification def PreserveBaseline {
        subject model : CadStudy;
        verify fr016;
    }
    verification def ReviewProvenance {
        subject model : CadStudy;
        verify fr008;
        verify fr010;
    }
    verification def FutureRuntime {
        subject model : CadStudy;
        verify fr006;
        verify fr015;
    }
}
