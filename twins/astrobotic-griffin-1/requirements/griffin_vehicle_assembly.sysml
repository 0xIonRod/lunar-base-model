package GriffinVehicleAssemblyRequirements {
    private import ScalarValues::Boolean;
    private import ScalarValues::Real;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;
    private import GriffinBusRequirements::GriffinBusComponent;
    private import GriffinPropulsionRequirements::GriffinMainPropulsionAssembly;
    private import GriffinPropulsionRequirements::GriffinEngineSkirtComponent;
    private import GriffinLandingLegRequirements::GriffinLandingLegAssembly;
    private import GriffinTankRequirements::GriffinPropellantTankAssembly;
    private import GriffinSolarRequirements::GriffinSolarArrayAssembly;
    private import GriffinRampRequirements::GriffinEgressRamp;
    private import GriffinVisualConfigurationRequirements::GriffinVisualConfiguration;
    private import FlipRequirements::FlipRover;
    private import GriffinFlipEgressStudy::CompactEgress;

    // The bus owns the adapter solid. The mission scene owns the releasable
    // joint because that relation crosses the independently loaded FLIP asset.
    part def GriffinPayloadAdapterInterface {
        attribute adapterPrimPath : UsdPrimPath = "/Griffin1/PayloadAdapter";
        attribute releaseJointPrimPath : UsdPrimPath = "/Griffin1SurfaceOps/FLIPPayloadAdapterJoint";
        attribute releaseRequiresTouchdownAndSettle : Boolean = true;
        attribute releaseRequiresEgressPathReady : Boolean = true;
        attribute jointEnabledBeforeRelease : Boolean = true;
        attribute releaseTransfersRoverAuthorityOnce : Boolean = true;
        ref part hostedRover : FlipRover;
    }

    // A reusable visual engine bell is a presentation part. Thrust, flow,
    // mass, and engine dynamics remain owned by the separate propulsion model.
    part def GriffinEngineVisualAssembly {
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_engine_bell_visual.usda";
        attribute parentPrimPath : UsdPrimPath = "/Griffin1/Nozzle/MainEngineCluster";
    }

    // One typed source graph for the Griffin system boundary. The visual
    // configuration part owns the SI frame, identities, and station values;
    // the subsystem definitions own their local geometry and assumptions.
    part def GriffinVehicleAssembly {
        attribute componentAsset : TwinAssetPath = "vehicles/griffin_1.usda";
        attribute usdRootPath : UsdPrimPath = "/Griffin1";
        part visualConfiguration : GriffinVisualConfiguration;
        part bus : GriffinBusComponent;
        part mainPropulsion : GriffinMainPropulsionAssembly;
        part engineVisuals : GriffinEngineVisualAssembly[7];
        part propellantTanks : GriffinPropellantTankAssembly[4];
        part landingLegs : GriffinLandingLegAssembly[4];
        part solarArrays : GriffinSolarArrayAssembly[3];
        part flipEgress : CompactEgress;
        part payloadInterface : GriffinPayloadAdapterInterface;
        part engineSkirt : GriffinEngineSkirtComponent;
    }

    enum def RampPackagingBankIdentity { CandidateRampPort; CandidateRampStarboard; }

    // A detached integration fixture for the unequal-section reconstruction.
    // Its qualified component datums also own the installed mechanism interfaces.
    part def GriffinRampPackagingStudy {
        doc /* SI metres/radians. Native 2026-10-23 interference and path study:
         * contracts/griffin-ramp-packaging-study-2026-10-23.md. Optional ramps
         * and adapter are source-backed; dimensions and phase choices are
         * reconstruction assumptions. This fixture qualifies static geometry,
         * not loaded deployment or flight hardware. */
        attribute fixtureAsset : TwinAssetPath = "tests/griffin_ramp_packaging.usda";
        attribute usdRootPath : UsdPrimPath = "/GriffinFlipVisual";
        attribute landerPath : UsdPrimPath = "/GriffinFlipVisual/Griffin1";
        attribute roverPath : UsdPrimPath = "/GriffinFlipVisual/FLIP";
        attribute banks : RampPackagingBankIdentity[2] = ("CandidateRampPort", "CandidateRampStarboard");
        attribute mountZ : Real = GriffinEgressRamp::physicalRampMountZ;
        attribute transitionLengthM : Real = GriffinEgressRamp::physicalRampDeckTransitionLengthM;
        attribute transitionOutboardX : Real = GriffinEgressRamp::physicalRampDeckTransitionOutboardX;
        // Positive running clearance at the nominal mitered entrance. The
        // native rigid-frame relation solves the raised bearing from the
        // fixed deck top, this corner offset and the root's entry datum.
        attribute hingeRunningClearanceM : Real = GriffinEgressRamp::physicalRampDeckTransitionInterfaceToleranceM;
        attribute transitionTrackWidthM : Real = GriffinEgressRamp::physicalRampDeckTransitionTrackWidthM;
        attribute bridgeTireSideClearanceM : Real = (GriffinRampPackagingStudy::transitionTrackWidthM
            - FlipRover::wheelWidthM) / 2.0;
        attribute rootClearanceAngleRad : Real = -GriffinEgressRamp::physicalRampSectionJointFrameOffsetRad;
        attribute payloadClearanceM : Real = 0.05;
        attribute nonAdjacentClearanceM : Real = 0.02;
        attribute rootClearanceStepRad : Real = GriffinRampPackagingStudy::rootClearanceAngleRad / 900.0;
        attribute sectionStepRad : Real = GriffinRampPackagingStudy::rootClearanceAngleRad / 90.0;
        attribute rootLoweringStepRad : Real = GriffinRampPackagingStudy::rootClearanceStepRad;
        ref part root : GriffinRampRootSectionRequirements::RampRootSection;
        ref part middle : GriffinRampMiddleSectionRequirements::RampMiddleSection;
        ref part toe : GriffinRampToeSectionRequirements::RampToeSection;
        ref part rover : FlipRover;
    }

    constraint def GVAC001_RampPayloadClearance {
        in observedMinimumGapM : Real;
        in requiredGapM : Real;
        in completeCoverage : Boolean;
        completeCoverage and requiredGapM > 0.0
            and observedMinimumGapM >= requiredGapM;
    }
    requirement def GVA001_RampPayloadPackaging {
        doc /* GVA-001 both candidate ramp banks shall use the source component
         * references and named attachment frames. Their complete visual and
         * physical geometry shall retain payloadClearanceM from the source
         * FLIP assembly in transport and throughout the selected deployment
         * path. Root moves upright first with other folds latched; then middle
         * unfolds, then the toe in its opposite sense; the extended root then
         * lowers to the source nominal/terrain target. Native f64 bounds are
         * conservative envelopes; sampled gaps require a between-sample motion
         * bound before completeCoverage can be true. Source, document and stage
         * generations must match the measured assembly. A section-only pass,
         * broad-phase overlap or saved counterexample cannot accept this case.
         * Other-bank, lander, ground and mating-interface checks are separate
         * required integration work; loaded dynamics remain GRR-017/landing
         * and surface-operations responsibilities. */
        require GVAC001_RampPayloadClearance {
            in requiredGapM = GriffinRampPackagingStudy::payloadClearanceM;
        }
    }
    requirement <'GVA-001'> gva001 : GVA001_RampPayloadPackaging {
        subject installation : GriffinRampPackagingStudy;
    }
    verification def Verify_GriffinRampPayloadPackaging {
        subject installation : GriffinRampPackagingStudy;
        verify gva001;
    }

}
