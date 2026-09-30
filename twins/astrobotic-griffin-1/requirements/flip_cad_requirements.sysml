// FreeCAD v3 source contract. FlipRequirements derives its runtime SI geometry
// from these CAD-owned values. SysML v2 parser/tool conformance is unverified.
// CAD-native scalar values carry explicit units in their names and documentation.
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
        attribute millimetresPerMetre : Real = 1000.0;
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
        attribute solarSavedDeg : Real = 0.0;
        attribute solarExampleDeg : Real = 82.0;
        attribute panelHingeRotationZDeg : Real = 90.0;
        attribute panelSolarRotationSign : Real = -1.0;
        attribute launchMassConstraintKg : Real = 480.0;
        attribute legacyRuntimeMassKg : Real = 450.0;
        attribute historicalPayloadCapacityKg : Real = 30.0;
        attribute gapToleranceMm : Real = 0.01;
        attribute penetrationToleranceMm3 : Real = 1.0;
        attribute frame : String = "right-handed mm; X lateral; Y longitudinal; front -Y; Z up";
        attribute steering : String = "skid steer; native CAD wheel roll only";
        attribute actualMassStatus : String = "TBD; not calculated or measured";
        attribute runtimePromotionStatus : String = "separate Twin runtime is owned by FlipRequirements; this CAD study is geometry-only";
        attribute panelSamplesDeg : String = "0,5,10,20,30,40,50,60,70,82,90";
        attribute wheelSamplesDeg : String = "0,15,45,90,180,270; right=-left; panel closed";
    }
    part cadStudy : CadStudy;
    requirement def FR001 {
        subject model : CadStudy;
        doc /* CAD shall identify chassis, exterior, battery, controller and payload deck as distinct named components. Verification allocation: InspectCAD. */
    }
    requirement <'FR-001'> fr001 : FR001 { subject redefines model = cadStudy; }
    requirement def FR002 {
        subject model : CadStudy;
        doc /* CAD shall expose the source-owned wheel count, wheelbase, track and fixed-axis wheel stations with independent left/right roll controls. Skid steering is source-backed; traction dynamics remain OPEN. Verification allocation: MeasureCAD. */
    }
    requirement <'FR-002'> fr002 : FR002 { subject redefines model = cadStudy; }
    requirement def FR003 {
        subject model : CadStudy;
        doc /* Panel backing, frame, cells, moving knuckles, sensor bar and cameras shall share panel motion. Verification allocation: ExercisePanel. */
    }
    requirement <'FR-003'> fr003 : FR003 { subject redefines model = cadStudy; }
    requirement def FR004 {
        subject model : CadStudy;
        doc /* The panel hinge location and native transform shall use the source-owned hinge coordinates and rotation attributes. Scripted solar requests shall clamp to the source-owned angle bounds; saved and example states shall use their source-owned values. Verification allocation: ExercisePanel. */
    }
    requirement <'FR-004'> fr004 : FR004 { subject redefines model = cadStudy; }
    requirement def FR005 {
        subject model : CadStudy;
        doc /* Battery and controller shall remain fixed during panel actuation. Verification allocation: ExercisePanel. */
    }
    requirement <'FR-005'> fr005 : FR005 { subject redefines model = cadStudy; }
    requirement def FR006 {
        subject model : CadStudy;
        doc /* The CAD study does not define rover attachment or release. The separate Twin runtime contract owns release sequencing; runtime acceptance remains OPEN. Verification allocation: FutureRuntime (OPEN). */
    }
    requirement <'FR-006'> fr006 : FR006 { subject redefines model = cadStudy; }
    requirement def FR007 {
        subject model : CadStudy;
        doc /* CAD major subassemblies shall remain separately selectable. Verification allocation: InspectCAD. */
    }
    requirement <'FR-007'> fr007 : FR007 { subject redefines model = cadStudy; }
    requirement def FR008 {
        subject model : CadStudy;
        doc /* Specifications shall identify units, configuration, source/estimate and verification status. Verification allocation: ReviewProvenance. */
    }
    requirement <'FR-008'> fr008 : FR008 { subject redefines model = cadStudy; }
    requirement def FR009 {
        subject model : CadStudy;
        doc /* CAD wheel dimensions and stations shall match the source-owned study values within gapToleranceMm. Verification allocation: MeasureCAD. */
    }
    requirement <'FR-009'> fr009 : FR009 { subject redefines model = cadStudy; }
    requirement def FR010 {
        subject model : CadStudy;
        doc /* Mass records shall distinguish the source launch constraint, unknown actual CAD mass and separate legacy simulation mass. No physical mass compliance is claimed. Verification allocation: ReviewProvenance. */
    }
    requirement <'FR-010'> fr010 : FR010 { subject redefines model = cadStudy; }
    requirement def FR011 {
        subject model : CadStudy;
        doc /* CAD chassis and panel dimensions shall match the source-owned study values within gapToleranceMm. Verification allocation: MeasureCAD. */
    }
    requirement <'FR-011'> fr011 : FR011 { subject redefines model = cadStudy; }
    requirement def FR012 {
        subject model : CadStudy;
        doc /* Each physical solid shall be valid and attached through its named chain to the baseplate, with gaps no greater than gapToleranceMm. Verification allocation: AuditGeometry. */
    }
    requirement <'FR-012'> fr012 : FR012 { subject redefines model = cadStudy; }
    requirement def FR013 {
        subject model : CadStudy;
        doc /* The source-owned panelSamplesDeg and wheelSamplesDeg shall show no tested intersection above penetrationToleranceMm3. Continuous clearance and combined pose products remain OPEN. Verification allocation: AuditGeometry. */
    }
    requirement <'FR-013'> fr013 : FR013 { subject redefines model = cadStudy; }
    requirement def FR014 {
        subject model : CadStudy;
        doc /* Saved CAD shall reopen with visible physical leaves and retained native expressions. Verification allocation: ExercisePanel. */
    }
    requirement <'FR-014'> fr014 : FR014 { subject redefines model = cadStudy; }
    requirement def FR015 {
        subject model : CadStudy;
        doc /* This CAD-only model does not qualify the separate Twin runtime. Runtime drive, release, energy and telemetry acceptance remains OPEN in FutureRuntime. Verification allocation: FutureRuntime (OPEN). */
    }
    requirement <'FR-015'> fr015 : FR015 { subject redefines model = cadStudy; }
    requirement def FR016 {
        subject model : CadStudy;
        doc /* Handoff shall identify its baseline CAD artifact and source revision, then account for each intentional change and retained physical component. The baseline artifact is currently unidentified, so no component count or preservation pass is claimed. Verification allocation: PreserveBaseline (OPEN). */
    }
    requirement <'FR-016'> fr016 : FR016 { subject redefines model = cadStudy; }
    verification def InspectCAD {
        subject model : CadStudy;
        objective {
            verify fr001;
            verify fr007;
        }
    }
    verification def MeasureCAD {
        subject model : CadStudy;
        objective {
            verify fr002;
            verify fr009;
            verify fr011;
        }
    }
    verification def ExercisePanel {
        subject model : CadStudy;
        objective {
            verify fr003;
            verify fr004;
            verify fr005;
            verify fr014;
        }
    }
    verification def AuditGeometry {
        subject model : CadStudy;
        objective {
            verify fr012;
            verify fr013;
        }
    }
    verification def PreserveBaseline {
        subject model : CadStudy;
        objective {
            verify fr016;
        }
    }
    verification def ReviewProvenance {
        subject model : CadStudy;
        objective {
            verify fr008;
            verify fr010;
        }
    }
    verification def FutureRuntime {
        subject model : CadStudy;
        objective {
            verify fr006;
            verify fr015;
        }
    }
}
