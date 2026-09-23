package Griffin1Requirements {
    // Requirement definitions are grouped by engineering domain; this package
    // owns integration subjects, source-backed context, and mission interfaces.
    private import ScalarValues::Real;
    private import ScalarValues::Integer;
    private import ScalarValues::String;
    private import ScalarValues::Boolean;

    enum def GriffinMissionDesignation { AstroboticGriffinMissionOne; }
    enum def GriffinLandingRegion { NobileSouthPole; }
    enum def HostedRoverDesignation { AstrolabFLIP; }

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
        attribute frameUnits : String = "metres";
        attribute frameRootDatum : String = "Griffin1";
        // Geometry-derived COM target for the vertical landing study.  The
        // inline pad/compound colliders settle at this composed contact datum
        // above the authored 0.35 m pad surface; keep the value in SysML so
        // the scene and Rhai checks share one source of truth.
        attribute landingComTouchdownY : Real = 3.98;
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
        // Visual review contract.  These are intentionally small, stable
        // presentation datums, not a hidden CAD model: the Twin graphics test
        // reads them and compares them with composed USD geometry.
        attribute visualCameraName : String = "VisualCamera";
        attribute visualLanderName : String = "Griffin1";
        attribute visualLanderDeckWidthM : Real = 4.50;
        attribute visualLandingPadRadiusM : Real = 6.0;
        attribute visualReviewGroundWidthM : Real = 36.0;
        attribute visualRenderOwnership : String = "render-only review layer; physics colliders remain authored by vehicle components";
        // Reusable assembly identities are source data as well. Rhai derives
        // paths and pair checks from these names instead of carrying a second
        // list of Griffin topology constants.
        attribute solarArrayNames : String[2] = ("SolarPanelPort", "SolarPanelStarboard");
        attribute landingLegNames : String[4] = ("LegPX", "LegNX", "LegPZ", "LegNZ");
        attribute landingPadNames : String[4] = ("PadPX", "PadNX", "PadPZ", "PadNZ");
        attribute rampNames : String[2] = ("EgressRampPort", "EgressRampStarboard");
        attribute rampHingeNames : String[2] = ("RampHingePort", "RampHingeStarboard");
        attribute mainEngineNames : String[7] = ("Engine01", "Engine02", "Engine03", "Engine04", "Engine05", "Engine06", "Engine07");
        // Route markers are mission-interface datums, not navigation-code
        // constants.  Keep the complete marker table in SysML so the scene
        // can be regenerated through the typed Editor bridge without a
        // second literal table in Rhai or a hand-edited USDA file.
        attribute surfaceRouteMarkerNames : String[15] = ("RoverRampApproach", "RoverRampExit", "RoverTarget1", "RoverTransit1", "RoverTransit2", "RoverTransit3", "RoverTransit4", "RoverTransit5", "RoverTransit6", "RoverTarget2", "RoverBaseArc1", "RoverBaseArc2", "RoverBaseApproach", "RoverBaseFinal", "BaseSite");
        // The approach marker is the rover-centre datum before the
        // 3.20 m ramp hinge. The source-owned transition length reaches the
        // adapter's full-width octagonal corners with the required overlap.
        // With FLIP's roughly 1.2 m forward half-envelope, x=2.00 m brings
        // the front wheels onto the transition without
        // placing the route target itself on the moving ramp body. The
        // The 12.228605 m track at 49 degrees reaches terrain near x=11.22 m
        // from the +3.20 m hinge. Put the exit gate at x=12.80 m: even at the
        // near edge of its 0.30 m arrival radius the trailing wheel stations
        // lie beyond the ramp tip. Recheck the route after applying the new
        // composed geometry in Editor.
        attribute surfaceRouteMarkerX : Real[15] = (2.00, 12.80, 16.00, 19.00, 21.00, 22.50, 23.70, 24.60, 25.20, 25.40, 25.80, 26.70, 28.00, 29.50, 31.00);
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
        // the forward (12.80,0.00) exit gate, after the trailing axle clears the ramp;
        // its forward centreline placement avoids asking Ackermann guidance
        // to reverse toward a lateral marker during the transition. The later diagonal legs deliberately reduce
        // speed to 0.18..0.14 m/s because the shared Ackermann law must turn
        // through the bounded corner sequence without overshooting a survey
        // marker; these are measured study-vehicle limits, not supplier data.
        attribute surfaceRouteSpeedMps : Real[15] = (0.22, 0.22, 0.35, 0.35, 0.35, 0.22, 0.20, 0.18, 0.16, 0.14, 0.14, 0.15, 0.18, 0.20, 0.22);
        // RoverTarget2 is the first survey gate on the finite-turn arc. Its
        // 1.20 m arrival radius is a route-control study value; it is not a
        // ramp-interface tolerance or a claimed current replay measurement.
        attribute surfaceRouteArrivalRadiusM : Real[15] = (0.35, 0.30, 1.20, 1.20, 1.20, 1.00, 1.00, 1.00, 1.00, 1.20, 1.00, 1.00, 1.00, 1.00, 1.20);
        // The deployed 12.228605 m ramp tip is near x=11.22 m, and the
        // 12.80 m exit gate is outside the 12 m landing pad. This
        // named apron is a small prepared transition surface, not a hidden
        // teleport or terrain override: it overlaps the ramp tip and gives
        // all four wheels a continuous collision plane before survey route
        // control begins.  Its dimensions are replaceable Twin study values
        // until the Griffin site ICD is available.
        attribute egressApronName : String = "EgressApron";
        attribute egressApronCenterX : Real = 13.50;
        attribute egressApronCenterY : Real = -0.05;
        attribute egressApronCenterZ : Real = -1.00;
        attribute egressApronLengthM : Real = 10.00;
        attribute egressApronWidthM : Real = 8.00;
        attribute egressApronThicknessM : Real = 0.10;
        attribute egressApronSurfaceY : Real = 0.00;
    }

    part def Griffin1Lander {
        // Public product/mission values.
        attribute payloadCapacityKg : Real = 625.0;
        attribute landingLegCount : Integer = 4;
        attribute mainEngineCount : Integer = 7;
        attribute propellantTankCount : Integer = 4;
        attribute solarArrayCount : Integer = 2;
        // Mechanical ICD values remain explicit study inputs until supplied.
        attribute geometryStatus : String = "study surrogate; Griffin ICD TBD";
        attribute massPropertiesStatus : String = "replaceable simulator mass-property proxies; component center-of-mass and as-built data TBD";
        attribute rampStatus : String = "optional Griffin egress hardware; mechanism ICD TBD";
        attribute solarArrayStatus : String = "visual/power study proxy; flight layout TBD";
    }

    // Generic integration subject.  Rover-owned values and rover visual
    // requirements live in requirements/flip_requirements.sysml; Griffin only
    // verifies that a hosted vehicle interface exists at the release boundary.
    part def HostedRoverInterface {
        attribute interfaceName : String = "hosted rover interface";
    }











































    verification def Verify_GriffinSurfaceOperations {
        subject lander : Griffin1Lander;
        subject rover : HostedRoverInterface;
        objective {
            verify GriffinFunctionalRequirements::gr004;
            verify GriffinFunctionalRequirements::gr007;
            verify GriffinFunctionalRequirements::gr026;
        }
    }


}
