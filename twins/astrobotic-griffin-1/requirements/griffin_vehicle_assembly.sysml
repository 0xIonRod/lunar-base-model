package GriffinVehicleAssemblyRequirements {
    private import ScalarValues::Boolean;
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
        part solarArrays : GriffinSolarArrayAssembly[4];
        part optionalEgressRamps : GriffinEgressRamp[0..2];
        part payloadInterface : GriffinPayloadAdapterInterface;
        part engineSkirt : GriffinEngineSkirtComponent;
    }

}
