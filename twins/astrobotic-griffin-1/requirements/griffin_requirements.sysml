package Griffin1Requirements {
    // Requirement definitions are grouped by engineering domain; this package
    // owns integration subjects, source-backed context, and mission interfaces.
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::Boolean;
    private import MoonBaseProjectRequirements::ProjectSimulationContract;
    private import GriffinVehicleAssemblyRequirements::GriffinVehicleAssembly;

    enum def GriffinMissionDesignation { AstroboticGriffinMissionOne; }
    enum def GriffinLandingRegion { NobileSouthPole; }
    enum def HostedRoverDesignation { AstrolabFLIP; }
    enum def GriffinSurfaceRouteMarkerName {
        RoverRampApproach; RoverRampExit; RoverTarget1;
        RoverTransit1; RoverTransit2; RoverTransit3; RoverTransit4;
        RoverTransit5; RoverTransit6; RoverTarget2;
        RoverBaseArc1; RoverBaseArc2; RoverBaseApproach;
        RoverBaseFinal; BaseSite;
    }
    enum def GriffinSurfaceFeatureName { LandingSitePad; EgressApron; }

    // Public mission context uses typed designations and numeric bounds. The
    // evidence catalog owns external citations; this part stores no URL or
    // requirement-identity strings.
    part def PublicMissionContext {
        doc /* The public cargo statement is a strict lower bound of more than 499 kg, modeled as a numeric threshold plus an exclusive-bound flag so calculations do not parse narrative text. The source catalog links the public mission evidence. */
        attribute mission : GriffinMissionDesignation = "AstroboticGriffinMissionOne";
        attribute landingRegion : GriffinLandingRegion = "NobileSouthPole";
        attribute hostedRover : HostedRoverDesignation = "AstrolabFLIP";
        attribute cargoMassLowerBoundKg : Real = 499.0;
        attribute cargoMassLowerBoundIsExclusive : Boolean = true;
        // Body-reference touchdown height for the powered-descent study.
        // Four 4 kN/m gear springs under the 4,950 kg study mass at lunar
        // gravity give about 0.50 m nominal travel; the unloaded pad-bottom
        // datum is 0.06 m above this reference. This is not flight data.
        attribute landingVehicleReferenceTouchdownY : Real = 0.44;
        // Landing-stability limits are owned by GR036 in the simulation
        // accuracy package; this integration context does not mirror them.
        attribute landingDivergenceToleranceM : Real = 0.50;
        attribute landingDivergenceToleranceUpright : Real = 0.02;
        attribute landingDivergenceToleranceSpeedMps : Real = 0.50;
        // Replay tolerances are distinct from engineering acceptance bounds.
        // With the deterministic single-thread profile, two fresh processes
        // must reproduce the same state to numerical round-off; the broader
        // divergence limits above describe acceptable physical envelopes, not
        // permission to hide an admission-order bug.
        attribute landingReplayToleranceM : Real = 1.0e-6;
        attribute landingReplayToleranceUpright : Real = 1.0e-7;
        attribute landingReplayToleranceSpeedMps : Real = 1.0e-6;
        attribute landingReplayToleranceTimeS : Real = 1.0e-9;
        // Mission watchdogs are explicit study policy, not hidden Rhai timing
        // literals. They bound a missing physical event and must never turn
        // into a PASS by themselves.
        attribute landingPhaseTimeoutS : Real = 300.0;
        attribute roverSettleTimeoutS : Real = 30.0;
        // FLIP is released from the top-deck adapter and must fall/roll to
        // the authored surface before wheel torque is enabled.  This is a
        // conservative upper bound for the rover's settled body centre,
        // derived from the metre-scale wheel radius and the normalized pad
        // datum; accepting deck height here would start route control while
        // the rover is airborne and create an artificial attitude impulse.
        attribute roverSettleHeightLimitM : Real = 2.00;
        attribute roverSettleSpeedLimitMps : Real = 0.25;
        attribute surfaceRouteTimeoutS : Real = 900.0;
        // A route that has no measurable horizontal progress is a physical
        // integration fault (usually contact/steering geometry), not a reason
        // to keep evaluating the same control law until the mission timeout.
        attribute surfaceRouteStallTimeoutS : Real = 15.0;
        // Visual review dimensions are compared with composed USD geometry;
        // they are presentation requirements, not supplier CAD data.
        attribute visualLanderDeckWidthM : Real = 4.50;
        // Study extent shared by the physical square contact pad and its
        // circular visual-review boundary.
        attribute landingSitePadExtentM : Real = 6.0;
        attribute visualReviewGroundWidthM : Real = 36.0;
        // Route markers are mission-interface datums, not navigation-code
        // constants.  Keep the complete marker table in SysML so the scene
        // can be regenerated through the typed Editor bridge without a
        // second literal table in Rhai or a hand-edited USDA file.
        attribute surfaceRouteMarkerNames : GriffinSurfaceRouteMarkerName[15] =
            ("RoverRampApproach", "RoverRampExit", "RoverTarget1",
             "RoverTransit1", "RoverTransit2", "RoverTransit3", "RoverTransit4",
             "RoverTransit5", "RoverTransit6", "RoverTarget2",
             "RoverBaseArc1", "RoverBaseArc2", "RoverBaseApproach",
             "RoverBaseFinal", "BaseSite");
        // The approach marker is the rover-centre datum before the
        // 3.20 m ramp hinge. The source-owned transition length reaches the
        // adapter's full-width octagonal corners with the required overlap.
        // With FLIP's roughly 1.2 m forward half-envelope, x=2.00 m brings
        // the front wheels onto the transition without
        // placing the route target itself on the moving ramp body. The
        // The 12.228605 m track at 27.833532 degrees reaches terrain near
        // x=14.06 m (3.20 m hinge plus 10.86 m horizontal track run). Put
        // the exit gate at x=15.60 m: even at the
        // near edge of its 0.30 m arrival radius the trailing wheel stations
        // lie beyond the ramp tip. Recheck the route after applying the new
        // composed geometry in Editor.
        attribute surfaceRouteMarkerX : Real[15] = (2.00, 15.60, 16.00, 19.00, 21.00, 22.50, 23.70, 24.60, 25.20, 25.40, 25.80, 26.70, 28.00, 29.50, 31.00);
        // Route navigation is authored in the terrain x/z plane.  The first
        // marker used to carry the 6.92 m deck-height value in Y, but the
        // rover guidance contract intentionally ignores Y and therefore
        // interpreted that datum as (3.20, 0.00).  Keep all surface markers
        // on the terrain plane so the SysML datum and the visible marker
        // agree; deck height belongs to the ramp/lander interface, not this
        // horizontal route table.
    attribute surfaceRouteMarkerY : Real[15] = (0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00);
    attribute surfaceRouteMarkerZ : Real[15] = (0.00, 0.00, 0.00, 1.00, 0.50, 0.20, -0.30, -1.20, -2.30, -3.60, -4.90, -6.10, -7.20, -8.50, -10.00);
        // Route commands are part of the mission interface, not controller
        // implementation constants. The first radius is a 0.35 m approach
        // lane around the centerline and must reach the composed deck-to-ramp
        // transition. GRR-012 checks the source-owned transition length and
        // required full-width overlap against exact composed collider footprints; the
        // static interface result remains separate from
        // runtime rover-contact acceptance. The second radius is 0.30 m at
        // the forward (15.60,0.00) exit gate, after the trailing axle clears the ramp;
        // its forward centreline placement avoids asking Ackermann guidance
        // to reverse toward a lateral marker during the transition. The later diagonal legs deliberately reduce
        // normalized throttle limits to 0.18..0.14 because the shared Ackermann law must turn
        // through the bounded corner sequence without overshooting a survey
        // marker; these are uncalibrated study command limits, not measured speed or supplier data. Source: RoverAutopilotGuidance.mo consumes speed as a forward throttle limit and reduces it by heading and approach gates.
        attribute surfaceRouteThrottleLimit : Real[15] = (0.22, 0.22, 0.35, 0.35, 0.35, 0.22, 0.20, 0.18, 0.16, 0.14, 0.14, 0.15, 0.18, 0.20, 0.22);
        // RoverTarget2 is the first survey gate on the finite-turn arc. Its
        // 1.20 m arrival radius is a route-control study value; it is not a
        // ramp-interface tolerance or a claimed current replay measurement.
        attribute surfaceRouteArrivalRadiusM : Real[15] = (0.35, 0.30, 1.20, 1.20, 1.20, 1.00, 1.00, 1.00, 1.00, 1.20, 1.00, 1.00, 1.00, 1.00, 1.20);
        // The deployed 12.228605 m ramp tip is near x=14.06 m, and the
        // 15.60 m exit gate is outside the 12 m landing pad. This
        // named apron is a small prepared transition surface, not a hidden
        // teleport or terrain override: it overlaps the ramp tip and gives
        // all four wheels a continuous collision plane before survey route
        // control begins.  Its dimensions are replaceable Twin study values
        // until the Griffin site ICD is available.
        attribute landingSitePadName : GriffinSurfaceFeatureName = "LandingSitePad";
        attribute landingSitePadThicknessM : Real = 0.10;
        attribute egressApronName : GriffinSurfaceFeatureName = "EgressApron";
        attribute egressApronCenterX : Real = 13.50;
        attribute egressApronCenterZ : Real = -1.00;
        attribute egressApronLengthM : Real = 10.00;
        attribute egressApronWidthM : Real = 8.00;
        attribute egressApronThicknessM : Real = 0.10;
        // Shared top plane for the landing pad and prepared egress apron. Each
        // collision cube is centered half its thickness below this datum.
        attribute siteSurfaceY : Real = 0.00;
    }

    part def Griffin1Lander {
        // Public product/mission values.
        attribute payloadCapacityKg : Real = 625.0;
    }

    // Generic integration subject.  Rover-owned values and rover visual
    // requirements live in requirements/flip_requirements.sysml; Griffin only
    // verifies that a hosted vehicle interface exists at the release boundary.
    part def HostedRoverInterface;

    // The assembly graph owns the typed subsystem multiplicities and the
    // separate hosted-FLIP payload/release relation.
    part missionVehicle : GriffinVehicleAssembly;











































    verification def Verify_GriffinSurfaceOperations {
        subject lander : Griffin1Lander;
        subject rover : HostedRoverInterface;
        subject ramp : GriffinRampRequirements::GriffinEgressRamp;
        objective {
            verify GriffinFunctionalRequirements::gr004;
            verify GriffinFunctionalRequirements::gr007;
            verify GriffinFunctionalRequirements::gr026;
            verify GriffinRampRequirements::grr017;
            verify GriffinSimulationAccuracyRequirements::gr037;
            verify GriffinSimulationAccuracyRequirements::gr039;
            verify GriffinSimulationAccuracyRequirements::gr038;
        }
    }

    // The integrated system case owns Griffin's GR usages and the shared
    // project unit/frame baseline. Domain and visual component cases remain
    // separately executable; this aggregate does not treat membership alone
    // as test proof.
    verification def Verify_GriffinRequirements {
        subject lander : Griffin1Lander;
        subject rover : HostedRoverInterface;
        subject project : ProjectSimulationContract;
        objective {
            verify GriffinFunctionalRequirements::gr001;
            verify GriffinFunctionalRequirements::gr002;
            verify GriffinFunctionalRequirements::gr003;
            verify GriffinFunctionalRequirements::gr004;
            verify GriffinAssuranceRequirements::gr005;
            verify GriffinFunctionalRequirements::gr006;
            verify GriffinFunctionalRequirements::gr007;
            verify GriffinSimulationAccuracyRequirements::gr008;
            verify GriffinFunctionalRequirements::gr009;
            verify GriffinMechanicalRequirements::gr010;
            verify GriffinMechanicalRequirements::gr011;
            verify GriffinMechanicalRequirements::gr012;
            verify GriffinAssuranceRequirements::gr013;
            verify GriffinAssuranceRequirements::gr014;
            verify GriffinVisualRequirements::gr015;
            verify GriffinVisualRequirements::gr016;
            verify GriffinMechanicalRequirements::gr017;
            verify GriffinMechanicalRequirements::gr018;
            verify GriffinMechanicalRequirements::gr019;
            verify GriffinVisualRequirements::gr020;
            verify GriffinSimulationAccuracyRequirements::gr021;
            verify GriffinSimulationAccuracyRequirements::gr022;
            verify GriffinSimulationAccuracyRequirements::gr023;
            verify GriffinMechanicalRequirements::gr024;
            verify GriffinMechanicalRequirements::gr025;
            verify GriffinFunctionalRequirements::gr026;
            verify GriffinSimulationAccuracyRequirements::gr027;
            verify GriffinFunctionalRequirements::gr028;
            verify GriffinAssuranceRequirements::gr029;
            verify GriffinAssuranceRequirements::gr030;
            verify GriffinSimulationAccuracyRequirements::gr031;
            verify GriffinVisualRequirements::gr032;
            verify GriffinVisualRequirements::gr033;
            verify GriffinFunctionalRequirements::gr034;
            verify GriffinFunctionalRequirements::gr035;
            verify GriffinSimulationAccuracyRequirements::gr036;
            verify GriffinSimulationAccuracyRequirements::gr037;
            verify GriffinSimulationAccuracyRequirements::gr038;
            verify GriffinSimulationAccuracyRequirements::gr039;
            verify MoonBaseProjectRequirements::mb001;
            verify MoonBaseProjectRequirements::mb002;
            verify MoonBaseProjectRequirements::mb003;
            verify MoonBaseProjectRequirements::mb004;
        }
    }


}
