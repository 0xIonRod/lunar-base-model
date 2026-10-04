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
        RoverRampApproach; RoverRampExit; RoverTarget1; RoverTarget2; BaseSite;
    }

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
        // Isolated Editor review pad only; absent from the surface mission.
        attribute visualReviewPadHalfExtentM : Real = 6.0;
        // Measured from the processed NOBILE03 DEM at scene X=Z=0 using
        // TerrainHeight, 2026-10-04. The crop datum is 5187.322 m. This is
        // the selected study anchor height, not a confirmed mission site.
        attribute landingTerrainDatumY : Real = .21062861382961273;
        attribute visualReviewGroundWidthM : Real = 36.0;
        // Operator-selected five-point surface route, 2026-10-03.
        // The estimated deployed ramp is now 5.397 m, rooted near X=1.90 m;
        // at 27.83 degrees its tip is approximately X=6.67 m. Exit X=8.50
        // reserves the 1.30 m rover half-envelope and 0.30 m arrival radius.
        // Survey/base points form a shallow turn rather than ten closely
        // spaced intermediate targets. These are simulation mission choices,
        // not a published Griffin site plan. Source: user scene-cleanup request
        // and the ramp/FLIP dimensions in griffin-size-evidence.md.
        attribute surfaceRouteMarkerNames : GriffinSurfaceRouteMarkerName[5] =
            ("RoverRampApproach", "RoverRampExit", "RoverTarget1", "RoverTarget2", "BaseSite");
        attribute surfaceRouteMarkerX : Real[5] = (2.00, 8.50, 13.00, 22.00, 31.00);
        attribute surfaceRouteMarkerY : Real[5] = (0.00, 0.00, 0.00, 0.00, 0.00);
        attribute surfaceRouteMarkerZ : Real[5] = (0.00, 0.00, 0.00, -4.00, -10.00);
        // Estimated normalized throttle limits, not flight speeds. Slow down
        // on the survey/base turn; retain tight egress arrival tolerances.
        attribute surfaceRouteThrottleLimit : Real[5] = (0.22, 0.22, 0.20, 0.16, 0.16);
        attribute surfaceRouteArrivalRadiusM : Real[5] = (0.35, 0.30, 1.20, 1.20, 1.20);
        // Source-backed DEM is the physical support surface. No artificial
        // landing slab or egress apron is allowed in the production mission.
        // Four raycast wheel contacts must reach that DEM at the exit gate.
        // 0.10 m allows bilinear height sampling vs collider triangulation of
        // the 4 m LROC cells; it is a study tolerance, not survey precision.
        // Source: local processed NOBILE03 crop and user scene-cleanup request.
        attribute egressTerrainWheelContactCount : Integer = 4;
        attribute egressTerrainContactHeightToleranceM : Real = .10;
        // Zero is only the component geometry-test datum. Runtime touchdown
        // and toe support are measured against the DEM, not this flat plane.
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
