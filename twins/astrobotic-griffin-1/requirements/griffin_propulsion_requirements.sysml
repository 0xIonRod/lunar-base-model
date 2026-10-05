package GriffinPropulsionRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;
    private import ScalarValues::Boolean;
    private import ScalarValues::Integer;
    private import VectorValues::CartesianThreeVectorValue;
    private import GriffinRequirementSources::TwinAssetPath;
    private import GriffinRequirementSources::UsdPrimPath;
    private import GriffinLanderRequirements::GriffinLanderComponent;
    private import GriffinVisualConfigurationRequirements::GriffinVisualConfiguration;

    attribute def Direction :> CartesianThreeVectorValue;
    enum def GriffinEngineVisualMember { Bell; Throat; }

    part def GriffinEngineControlStudy {
        doc /* Integration study, not current flight performance. Current
         * Astrobotic full-system hot-fire report confirms pressure-fed
         * hypergolic main/ACS operation with two fuel, two oxidizer and three
         * helium tanks: https://www.linkedin.com/posts/astrobotic_the-astrobotic-team-recently-completed-a-activity-7402458294524530689-09jf.
         * Checked 2026-10-05. Current seven-engine unit ratings, inventories,
         * regulator pressures and valve transients are unpublished here.
         * GriffinPressureFedStudy owns the explicit numerical assumptions.
         * Passive valve/injector loss and choked chamber pressure are solved
         * together by LunCo.Propulsion.PressureFedValve and
         * PressureFedCombustionChamber. They add no artificial pump work.
         * 50 kg/s bounds 28.8*sqrt(3 MPa/1 MPa) even at zero chamber pressure;
         * it is an actuator admission envelope, not predicted current flow.
         * Control closure source: lunco://models/Lander.mo. Its gyro damping
         * deadband is capped at half the settled-touchdown rate tolerance so
         * residual spin cannot prevent cutoff. This is a study control margin,
         * not an Astrobotic flight-controller specification. First qualified
         * contact closes autonomous main demand; possession selects pilot
         * demand without refilling or bypassing propellant availability.
         */
        attribute exhaustVelocityMps : Real = 2940.0;
        attribute combustionEfficiency : Real = .96;
        attribute actuatorFlowEnvelopeKgs : Real = 50.0;
        attribute actuatorForceEnvelopeN : Real = actuatorFlowEnvelopeKgs * exhaustVelocityMps * combustionEfficiency;
        // One input edge held for 5 s must still be climbing at the end,
        // rather than merely reaching a transient hop peak. 2 m clearance
        // and 2 m/s upward speed are study acceptance thresholds for this
        // initial lunar surface fixture, not a flight qualification criterion.
        attribute burnDurationS : Real = 5.0;
        // Study settling allowance: throttle spool tau=.35 s plus valve tau=.08 s.
        // .35*ln(1.706e6/100)=3.41 s for the pressure criterion; 4 s leaves
        // margin for cascaded valve response. Not a supplier shutdown rating.
        attribute releaseDurationS : Real = 4.0;
        attribute minimumSustainedLiftM : Real = 2.0;
        attribute minimumEndVerticalSpeedMps : Real = 2.0;
        attribute extinguishedThrustThresholdN : Real = 100.0;
        attribute touchdownTimeoutS : Real = 150.0;
    }

    part def GriffinPressureFedStudy {
        doc /* Reduced pressure-fed integration study, checked 2026-10-05.
         * Architecture source: https://www.linkedin.com/posts/astrobotic_the-astrobotic-team-recently-completed-a-activity-7402458294524530689-09jf.
         * Numerical pressures, flow, fuel load, O/F and response below are
         * simulator assumptions, not current flight specifications. Retain the
         * inherited 8 kg/s fuel reference and set oxidizer to 8*2.6 kg/s for
         * consistent modeled mixture. The inherited 2.5..3 MPa tank envelope
         * and 0.08 s valve response remain explicit study assumptions.
         * Chamber reference 1.5 MPa is chosen below the 2.5 MPa minimum supply
         * to leave 1 MPa valve/injector pressure loss. Effective c-star is
         * 1550 m/s times the inherited combustion efficiency 0.96. Aggregate
         * throat bore area follows nominal mass flow*c-star/Pc. Seven equal
         * bore radii are sqrt(area/(7*pi)); the written literal is derived.
         * At 3 MPa supply the coupled steady flow solves to 32.7588079 kg/s;
         * 33 kg/s is its upward-rounded controller capability. Throttle requests
         * this fraction of flow split at O/F 2.6. Each valve computes required
         * travel from current pressure head and retains the 0.08 s response
         * and physical saturation. This study feed compensation prevents
         * raw valve travel from amplifying low-throttle guidance demands;
         * it is not a sourced Astrobotic command interface. The actuator
         * admission bound is separately conservative at zero chamber pressure.
         * The helium regulator is represented by the existing tank pressure
         * envelope; finite pressurant inventory, slosh, detailed injector loss
         * and discrete pulsing remain unresolved. 1000 kg per reactant is an
         * inherited integration load, not a sourced flight inventory.
         */
        attribute fuelReferenceFlowKgs : Real = 8.0;
        attribute oxidizerToFuelRatio : Real = 2.6;
        attribute oxidizerReferenceFlowKgs : Real = fuelReferenceFlowKgs * oxidizerToFuelRatio;
        attribute referenceTotalFlowKgs : Real = fuelReferenceFlowKgs + oxidizerReferenceFlowKgs;
        attribute nominalTankPressurePa : Real = 2500000.0;
        attribute tankPressureHeadroomPa : Real = 500000.0;
        attribute referenceChamberPressurePa : Real = 1500000.0;
        attribute referencePressureDropPa : Real = nominalTankPressurePa - referenceChamberPressurePa;
        attribute characteristicVelocityMps : Real = 1550.0;
        attribute combustionEfficiency : Real = GriffinEngineControlStudy::combustionEfficiency;
        attribute totalThroatBoreAreaM2 : Real = referenceTotalFlowKgs * characteristicVelocityMps * combustionEfficiency / referenceChamberPressurePa;
        attribute throatBoreRadiusM : Real = .03604359686410814;
        attribute controllerFlowCapabilityKgs : Real = 33.0;
        attribute fuelCommandFlowKgs : Real = controllerFlowCapabilityKgs / (1.0 + oxidizerToFuelRatio);
        attribute oxidizerCommandFlowKgs : Real = fuelCommandFlowKgs * oxidizerToFuelRatio;
        attribute valveResponseS : Real = .08;
        attribute availabilityTransitionMassKg : Real = .01;
        attribute initialFuelMassKg : Real = 1000.0;
        attribute initialOxidizerMassKg : Real = 1000.0;
        attribute pressureObservationTolerancePa : Real = 100.0;
    }

    part def GriffinMainPropulsionAssembly {
        attribute usdRootPath : UsdPrimPath = "/World/Griffin1/Nozzle/MainEngineCluster";
        attribute componentAsset : TwinAssetPath = "components/lander/griffin_engine_bell_visual.usda";
        attribute childNames : GriffinEngineVisualMember[2] =
            ("Bell", "Throat");
        attribute bellRadiusM : Real = 0.34;
        attribute bellHeightM : Real = 0.52;
        // Exterior radius includes the source-owned render wall. Modelica uses
        // the bore radius, so gas area and visible bore share one dimension.
        attribute throatRadiusM : Real = GriffinPressureFedStudy::throatBoreRadiusM + GriffinMainPropulsionAssembly::bellVisualWallThicknessM;
        attribute exitBoreRadiusM : Real = bellRadiusM - bellVisualWallThicknessM;
        attribute throatHeightM : Real = 0.16;
        // Neck starts at the bell throat plane and extends upwards; the old
        // solid cylinder started inside the expanding bore and capped it.
        // Radius/height and the shared 6 mm visual wall remain reconstruction
        // estimates. Topology follows the throat-to-diverging-exit flow path:
        // https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/nozzle-design/
        attribute throatCenterYM : Real = GriffinMainPropulsionAssembly::bellHeightM / 2.0 + GriffinMainPropulsionAssembly::throatHeightM / 2.0;
        attribute bellAxis : Direction = (0.0, 1.0, 0.0);
        // Estimated bell contour, using LunCo.Propulsion.BellNozzle's law:
        // r(s)=throatRadiusM+(bellRadiusM-throatRadiusM)*s^bellContourExponent.
        // s=0 at the throat, s=1 at the downward-facing open exit.
        // .55 is the library approximation, not a supplier-qualified Rao design.
        // 16 axial intervals resolve the curve; 6 mm is a visual shell estimate.
        attribute bellContourExponent : Real = .55;
        attribute bellAxialSegments : Integer = 16;
        attribute bellVisualWallThicknessM : Real = .006;
        attribute bellAngularSegments : Integer = 48;
        // Estimated shading crease; keeps the physical rim sharp.
        attribute bellNormalCreaseAngleDeg : Real = 35.0;
        /* Dark gray nozzle appearance is an artistic estimate from the
         * selected Astrobotic rendering, not a material grade, emissivity or
         * temperature-dependent optical property. This prim displayColor
         * serves inspection; normal shading on both hollow shells reuses
         * Nozzle_Mat from lunco://components/propulsion/rocket_engine_visual.usda.
         * No duplicate nozzle shader or engineering optical data is authored.
         * https://www.astrobotic.com/wp-content/uploads/2021/02/g1.png */
        attribute bellDisplayColor : Real[3] = (.20, .22, .25);

        // Hypergolic family from PUG p.26 (M20 / MON3). Palette is heuristic;
        // 2.0 reference O/F is a provisional chemistry estimate, not flight data.
        attribute plumeFuelFamily : Real = 3;
        attribute plumeStoichiometricMixtureRatio : Real = 2.0;
        attribute minimumBellClearanceM : Real = 0.20;
        // Conservative reconstruction allowance to all named tank shapes,
        // including cradle/pad, lower fittings and mounting brackets. A 20 mm
        // gap is a study packaging allowance, not a thermal/flight margin.
        attribute minimumTankHardwareClearanceM : Real = 0.02;
        // The skirt bounds the engine cluster; the central adapter is an
        // internal structural shell and must not be treated as its boundary.
        attribute clusterOuterRadiusM : Real = GriffinEngineSkirtComponent::railLengthM / 2.0;
    }

    // The skirt is a visual/structural presentation component around the
    // engine adapter plate.  It is deliberately specified independently from
    // the bells: the flight model owns thrust and collision, while this frame
    // makes the seven-bell cluster legible and provides a stable placement
    // datum for the Editor.
    part def GriffinEngineSkirtComponent {
        attribute usdRootPath : String = "/World/Griffin1/Nozzle/MainEngineCluster";
        attribute componentRootName : String = "EngineSkirt";
        attribute perimeterRailName : String = "PerimeterRail";
        // Continuous mitered octagon, sharing the normalized outerBodyProfileCoordinates
        // of GriffinVisualConfiguration. The 3.44 m across-flats envelope is
        // inset 80 mm from the estimated 3.60 m bus on each cardinal side.
        // This avoids a square frame extending outside the bus chamfers.
        // PGH photo: https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png
        // ESA depiction: https://www.esa.int/ESA_Multimedia/Images/2022/09/Griffin_lander
        // Both establish the clipped footprint qualitatively; 80 mm stock,
        // envelope and taper remain packaging estimates, not measured hardware.
        attribute railLengthM : Real = 3.44;
        attribute railWidthM : Real = 0.08;
        attribute railHeightM : Real = 0.08;
        attribute shellName : String = "EngineSkirtShell";
        attribute adapterPlateName : String = "EngineAdapterPlate";
        attribute adapterPlateWidthM : Real = 2.84;
        attribute adapterPlateDepthM : Real = 2.84;
        attribute adapterPlateHeightM : Real = 0.12;
        // The PGH hardware photograph shows an open underside, rather than
        // a deep opaque shroud: https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png.
        // 80 mm frame stock, a 120 mm shallow fairing, and 60 mm taper are
        // explicit visualization estimates, not calibrated stock dimensions.
        attribute shellDepthM : Real = 0.12;
        attribute shellBottomInsetM : Real = 0.06;
        attribute shellUpperYM : Real = componentLocalCenterYM + railHeightM / 2.0;
        attribute shellLowerYM : Real = shellUpperYM - shellDepthM;
        // Rail tops seat against the lower bus skirt at the estimated
        // adapter plane; do not surround the expanding nozzle exits.
        attribute componentLocalCenterYM : Real = adapterPlateCenterYM;
        attribute minimumSkirtBellClearanceM : Real = 0.10;
        // Seat the plate's lower face at the upper throat end. A plate
        // centered on the rail plane would intersect all bell walls.
        attribute adapterPlateCenterYM : Real = GriffinMainPropulsionAssembly::throatCenterYM + GriffinMainPropulsionAssembly::throatHeightM / 2.0 + adapterPlateHeightM / 2.0;
        // Estimated minimum exposure below the shroud, to reject geometry
        // that encloses the bell exits while passing simple dimension checks.
        attribute minimumVisibleBellHeightFraction : Real = 0.30;
        attribute colliderPolicy : String = "render-only frame; no physics collision or thrust authority";
    }

    part def GriffinAttitudeEngineAssembly {
        doc /* A110 vendor-reference reconstruction, checked 2026-10-05.
         * Agile's 2023 Year in Review confirms delivery of A110 flight units
         * for Griffin: https://agilespaceindustries.com/press/2023-year-in-review.
         * Vendor datasheet: https://static1.squarespace.com/static/634ee7b32099c80fdfcc8cac/t/6418ea80e1144560207215ca/1679505951405/AgileSpace_A110SpecDoc.pdf.
         * It gives M20/MON3, 111.2 N nominal thrust, O/F 0.90, Isp >=305.5 s,
         * 19.25/17.33 g/s nominal flows, 220 psia chamber pressure, expansion
         * ratio 70 and startup/shutdown <10 ms. The 2.4-in exit diameter and
         * 9.0-in overall drawing dimensions convert exactly by 0.0254 m/in.
         * The model uses nominal Isp derived from thrust and stated total flow;
         * 305.5 s is a guaranteed lower bound, not that nominal operating point.
         * The bore throat radius derives as exitRadiusM/sqrt(expansionRatio).
         * Bell/chamber lengths and dual-valve envelopes are drawing-scaled
         * estimates, not an ICD. The contour and shell are visual estimates.
         * Twelve retained scalar force identities form four triples. Shared
         * library exhaust follows delivered thrust; no Twin flame proxies.
         * Mounts remain packaging estimates from bus chamfer midpoint, 40 mm
         * below the top, 60 mm outward and +/-120 mm tangent spacing, using
         * https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png
         * and https://www.astrobotic.com/griffin-1-lunar-lander-unveiled-ahead-of-environmental-testing/.
         * Symmetric mount offsets retain a pure requested attitude wrench.
         * Commands represent tick-averaged pulse duty. The 60 Hz physics step
         * cannot resolve the vendor's sub-5-ms pulses or <10-ms valve edges.
         * Do not claim pulse-transient fidelity from this averaged model.
         */
        attribute nominalForceN : Real = 111.2;
        attribute nominalFuelFlowKgs : Real = .01925;
        attribute nominalOxidizerFlowKgs : Real = .01733;
        attribute standardGravityMps2 : Real = 9.80665;
        attribute minimumSpecificImpulseS : Real = 305.5;
        attribute nominalSpecificImpulseS : Real = nominalForceN / ((nominalFuelFlowKgs + nominalOxidizerFlowKgs) * standardGravityMps2);
        attribute oxidizerToFuelRatio : Real = .90;
        attribute chamberPressurePa : Real = 1516846.6044969598;
        attribute expansionRatio : Real = 70.0;
        attribute exitRadiusM : Real = .03048;
        // Derived from the published bore-area ratio; sqrt is written out to
        // retain a resolved literal in the current scalar SysML projection.
        attribute throatRadiusM : Real = .0036430568012512316;
        // Drawing estimates: 157/430 of the 9-in total is the bell; 160/430
        // is the chamber neck. Rounded to 84 and 85 mm for the reconstruction.
        attribute bellHeightM : Real = .084;
        attribute collarHeightM : Real = .085;
        attribute chamberRadiusM : Real = .0085;
        attribute valveRadiusM : Real = .0065;
        attribute valveLengthM : Real = .028;
        attribute valveCenterOffsetM : Real = .012;
        attribute inletTubeRadiusM : Real = .0025;
        attribute inletTubeLengthM : Real = .030;
        attribute inletTubeCenterOffsetM : Real = .034;
        attribute valveCantDeg : Real = 45.0;
        // 0.5 mm is an explicit render-shell estimate, not pressure-wall sizing.
        attribute visualWallThicknessM : Real = .0005;
        attribute bellContourExponent : Real = .55;
        attribute bellAngularSegments : Integer = 32;
        attribute bellAxialSegments : Integer = 12;
        attribute geometryToleranceM : Real = .00001;
        // Numerical acceptance relative to the commanded moment/force capacity;
        // an observation tolerance, not a physical pointing requirement.
        attribute wrenchRelativeTolerance : Real = .00001;
        // Keep 10% reserve below the smallest pure-axis pair capacity derived
        // from composed mounts. This prevents an infeasible torque request
        // from trading unwanted translation against attitude correction.
        // Study control margin, not an Astrobotic released flight setting.
        attribute commandTorqueCapacityFraction : Real = .90;
        // Six seconds includes decay of the pilot's 0.35 s filter and the
        // observed allocator/feed publication delay before comparing directions.
        attribute commandSettlingS : Real = 6.0;
        // M20/MON3 is the vendor A110 propellant specification. The shared
        // plume class 3 is a heuristic hypergolic palette, not spectrometry.
        attribute plumeFuelFamily : Real = 3;
        // Packaging estimates relative to the bus top and diagonal faces.
        // 60 mm outward standoff clears the skin; +/-120 mm tangent offsets
        // separate the three retained actuator identities at each corner.
        attribute mountBelowBusTopM : Real = .04;
        attribute mountStandoffM : Real = .06;
        attribute memberTangentOffsetM : Real = .12;
    }

    requirement def GPP011_RcsFeedAvailability {
        doc /* GPP-011 [physics boundary] all twelve RCSJet instances receive fuel
         * and oxidizer availability from the owning live tank mass outputs.
         * Positive demand produces useful thrust only with both reactants.
         * Fuel or oxidizer depletion extinguishes delivered thrust, shared
         * plume activity and emitted light through Modelica equations, without
         * a Griffin-specific visibility rule. Source: user engine/no-fuel
         * contract; physical rationale: a bipropellant thruster needs both feeds.
         */
    }

    requirement def GPP012_RcsCommandWrench {
        doc /* GPP-012 [command boundary] positive and negative pitch, yaw and
         * roll demand shall select their corresponding one-sided valve pairs.
         * Each pair's composed position cross delivered force shall have the
         * requested moment sign, zero unwanted moments and zero net force within
         * the source numerical tolerance. The allocator's Newton-metre capacities
         * are synthesized from composed mount poses and nominal jet forces.
         * Normalized valve allocation metadata and physical force commands have
         * separate units and ownership. Force actuators
         * receive computed thrust in newtons, never normalized valve opening.
         * Source: user request to improve engine command reception; physical
         * rationale: paired attitude thrusters implement pure body torque.
         */
    }

    requirement def GPP001_EngineCount {
        doc /* GPP-001 [topology] exactly seven named main-engine visual owners are present in the cluster. Source: current Astrobotic product page https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ accessed 2026-10-03. Five in the August 2021 PUG is a historical configuration. Current unit performance is unavailable; this topology change must not rescale aggregate Modelica thrust. */
    }
    requirement def GPP002_BellGeometry {
        doc /* GPP-002 [visual] each engine includes its modeled bell and throat, with no placeholder circle or duplicate collider geometry. */
    }
    requirement def GPP003_ThrustOwnership {
        doc /* GPP-003 [physics boundary] bells and plumes are render-only. The Modelica propulsion and nozzle models remain the sole authority for thrust, propellant flow, nozzle design outputs, and plume photometry. Fuel starvation shall stop useful combustion and thrust through the feed/chamber equations; zero delivered jet momentum shall yield zero visible plume and light with the engine command still on. The griffin_fuel_exhaustion production fixture verifies this chain. */
    }
    requirement def GPP004_PropulsionTraceability {
        doc /* GPP-004 [evidence] engine identities resolve from GriffinVisualConfigurationRequirements, their cardinality agrees with the typed lander count, and each instance is checked individually. */
    }
    requirement def GPP005_EnginePlacement {
        doc /* GPP-005 [layout] each bell owner uses the ordered native Position datum owned by GriffinVisualConfigurationRequirements. */
    }
    constraint def GPPC006_OpenBellEnvelope {
        in measuredExitRadiusM : Real;
        in measuredHeightM : Real;
        in measuredMinimumRadiusM : Real;
        in measuredThroatOuterRadiusM : Real;
        in measuredThroatHeightM : Real;
        in measuredThroatCenterYM : Real;
        in measuredThroatBoreOpen : Boolean;
        in boreOpen : Boolean;
        in exitRadiusM : Real;
        in heightM : Real;
        in throatRadiusM : Real;
        in throatHeightM : Real;
        in throatCenterYM : Real;
        in wallThicknessM : Real;
        in toleranceM : Real;
        measuredExitRadiusM - exitRadiusM <= toleranceM
            and measuredExitRadiusM - exitRadiusM >= -toleranceM
            and measuredHeightM - heightM <= toleranceM
            and measuredHeightM - heightM >= -toleranceM
            and measuredMinimumRadiusM >= throatRadiusM - wallThicknessM - toleranceM
            and boreOpen
            and measuredThroatOuterRadiusM - throatRadiusM <= toleranceM
            and measuredThroatOuterRadiusM - throatRadiusM >= -toleranceM
            and measuredThroatHeightM - throatHeightM <= toleranceM
            and measuredThroatHeightM - throatHeightM >= -toleranceM
            and measuredThroatCenterYM - throatCenterYM <= toleranceM
            and measuredThroatCenterYM - throatCenterYM >= -toleranceM
            and measuredThroatBoreOpen
    }
    requirement def GPP006_BellAndThroatEnvelope {
        require GPPC006_OpenBellEnvelope {
            in exitRadiusM = GriffinMainPropulsionAssembly::bellRadiusM;
            in heightM = GriffinMainPropulsionAssembly::bellHeightM;
            in throatRadiusM = GriffinMainPropulsionAssembly::throatRadiusM;
            in throatHeightM = GriffinMainPropulsionAssembly::throatHeightM;
            in throatCenterYM = GriffinMainPropulsionAssembly::throatCenterYM;
            in wallThicknessM = GriffinMainPropulsionAssembly::bellVisualWallThicknessM;
            in toleranceM = GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        doc /* GPP-006 [geometry] each engine exposes an open Y-axis hollow bell Mesh and an uncapped hollow throat Mesh using the source-owned radius/height datums. Mesh vertices and faces shall establish the exit envelope, height, positive flow-bore radius and absence of a closing face in both parts. The throat lower rim shall meet the bell throat plane, and the upper rim seats against the adapter plate. bellContourExponent relates the reconstruction contour to those datums using the library BellNozzle law; the exponent and bellVisualWallThicknessM are explicit visual estimates, not flight nozzle design or wall sizing. See griffin-size-evidence.md. */
    }
    constraint def GPPC007_BellSeparation {
        in measuredMinimumClearanceM : Real;
        in requiredMinimumClearanceM : Real;
        in maximumRadialExtentM : Real;
        in skirtOuterRadiusM : Real;
        in typedStationsMatch : Boolean;
        measuredMinimumClearanceM >= requiredMinimumClearanceM
            and maximumRadialExtentM <= skirtOuterRadiusM
            and typedStationsMatch;
    }
    requirement def GPP007_BellSeparation {
        require GPPC007_BellSeparation {
            in requiredMinimumClearanceM = GriffinMainPropulsionAssembly::minimumBellClearanceM;
            in skirtOuterRadiusM = GriffinMainPropulsionAssembly::clusterOuterRadiusM;
        }
        doc /* GPP-007 [layout] the seven bell exit envelopes shall have at least minimumBellClearanceM pairwise clearance, be arranged as one centered engine and six equally spaced perimeter engines, and remain inside the engine-skirt envelope while clearing the central adapter shell. The layout is derived from the typed engineStations; the bell radius is owned by this propulsion component. */
    }
    constraint def GPPC008_EnginePlumeDataflow {
        in engineCount : Integer;
        in plumeEngineCount : Integer;
        in photometryConsumesEngineState : Boolean;
        in everyNozzleUsesPhotometry : Boolean;
        in everyNozzleHasBoundPlumeMaterials : Boolean;
        in plumeGeometryIsRenderOnly : Boolean;
        engineCount > 0
            and plumeEngineCount == engineCount
            and photometryConsumesEngineState
            and everyNozzleUsesPhotometry
            and everyNozzleHasBoundPlumeMaterials
            and plumeGeometryIsRenderOnly;
    }
    requirement def GPP008_EnginePlumeDataflow {
        require GPPC008_EnginePlumeDataflow {
            in engineCount = GriffinLanderComponent::engineCount;
        }
        doc /* GPP-008 [simulation presentation] each main-engine owner shall inherit its render-only outer plume from the LunCoSim rocket_engine_visual library component, without Twin-authored flame geometry or materials. The library helper connects physics to geometry envelope scale, shader colour and light colour. Nozzle radius and nominal thrust shall determine the envelope; fuel family and mixture richness shall determine a documented heuristic palette. Each nozzle shall have a render-only outer plume and hot core with the corresponding plume materials, plus a local light. The shader inputs and light intensity/size shall follow shared photometry outputs driven by live propulsion state and modeled nozzle geometry. Zero delivered thrust shall produce neither visible exhaust nor light. */
    }
    constraint def GPPC009_TankHardwareSeparation {
        in measuredVerticalGapM : Real;
        in requiredClearanceM : Real;
        measuredVerticalGapM >= requiredClearanceM;
    }
    requirement def GPP009_TankHardwareClearance {
        require GPPC009_TankHardwareSeparation {
            in requiredClearanceM = GriffinMainPropulsionAssembly::minimumTankHardwareClearanceM;
        }
        doc /* GPP-009 [interface] all bell and throat envelopes shall remain below the complete named tank vessel, cradle/pad, fittings and mounting brackets by at least minimumTankHardwareClearanceM. Observe composed geometry bounds in the same canonical frame, including assembly scale and transforms. This deliberately conservative vertical separation is a study packaging rule: Astrobotic publishes no current engine/tank mounting ICD. It prevents spacing-only checks from accepting a nozzle collar through lower tank hardware. Source architecture: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/ and https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png ; envelope sizes and clearance are explicit estimates. Structural tank-seat/adapter contacts are separate mount interfaces. */
    }

    requirement def GES001_SkirtTopology {
        doc /* GES-001 [topology] one named continuous mitered octagonal skirt rail forms a closed frame around the seven-engine cluster. */
    }
    requirement def GES002_SkirtEnvelope {
        doc /* GES-002 [geometry] the rail envelope, rail section, open-ended shell, and adapter plate shall use their typed dimensions and station datums in GriffinEngineSkirtComponent. */
    }
    requirement def GES003_SkirtDatum {
        doc /* GES-003 [placement] the skirt is centered on the engine adapter datum immediately below the bus. */
    }
    constraint def GESC004_SkirtAndBellFit {
        in minimumRadialClearanceM : Real;
        in requiredRadialClearanceM : Real;
        in visibleBellHeightFraction : Real;
        in requiredVisibleBellHeightFraction : Real;
        in adapterThroatSeparationM : Real;
        in toleranceM : Real;
        minimumRadialClearanceM >= requiredRadialClearanceM
            and visibleBellHeightFraction >= requiredVisibleBellHeightFraction
            and adapterThroatSeparationM >= -toleranceM;
    }
    requirement def GES004_BellClearance {
        require GESC004_SkirtAndBellFit {
            in requiredRadialClearanceM = GriffinEngineSkirtComponent::minimumSkirtBellClearanceM;
            in requiredVisibleBellHeightFraction = GriffinEngineSkirtComponent::minimumVisibleBellHeightFraction;
            in toleranceM = GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        doc /* GES-004 [clearance] the rails and lower shroud contour leave at least minimumSkirtBellClearanceM clearance to the full bell envelopes. At least minimumVisibleBellHeightFraction of bell height remains below the shroud edge, and the adapter plate lower face is at or above the upper throat ends. These conservative packaging checks must use composed geometry; a named shroud is not evidence of clearance. */
    }
    requirement def GES005_SkirtOwnership {
        doc /* GES-005 [ownership] skirt geometry is render-only and cannot introduce thrust, collider, or physics authority. */
    }
    constraint def GESC006_OctagonalProfile {
        in topologyMismatches : Integer;
        in maximumRailPointErrorM : Real;
        in maximumShellPointErrorM : Real;
        in maximumBusOverhangM : Real;
        in toleranceM : Real;
        topologyMismatches == 0
            and maximumRailPointErrorM <= toleranceM
            and maximumShellPointErrorM <= toleranceM
            and maximumBusOverhangM <= toleranceM;
    }
    requirement def GES006_RailGeometry {
        require GESC006_OctagonalProfile {
            in toleranceM = GriffinVisualConfiguration::geometryVerificationToleranceM;
        }
        doc /* GES-006 [geometry] the continuous skirt rail shall match railLengthM across flats, railWidthM normal to each edge, railHeightM and componentLocalCenterYM. Both rail and shell shall follow GriffinVisualConfiguration::outerBodyProfileCoordinates; all of their vertices shall remain inside the bus footprint. The bottom inset tapers the shell; it shall not define the plan-view corner clip. */
    }
    requirement def GES007_ShellAndAdapterEnvelope {
        doc /* GES-007 [geometry] the tapered shell shall use its typed upper/lower Y limits, and the adapter plate shall match its typed dimensions and declared datum. The plate center derives from the throat upper end and its own thickness, not from the skirt rail plane. */
    }

    requirement <'GPP-001'> gpp001 : GPP001_EngineCount { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-002'> gpp002 : GPP002_BellGeometry { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-003'> gpp003 : GPP003_ThrustOwnership { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-004'> gpp004 : GPP004_PropulsionTraceability { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-005'> gpp005 : GPP005_EnginePlacement { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-006'> gpp006 : GPP006_BellAndThroatEnvelope { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-007'> gpp007 : GPP007_BellSeparation { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-008'> gpp008 : GPP008_EnginePlumeDataflow { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-009'> gpp009 : GPP009_TankHardwareClearance { subject propulsion : GriffinMainPropulsionAssembly; }
    requirement <'GPP-011'> gpp011 : GPP011_RcsFeedAvailability {
        subject rcs : GriffinAttitudeEngineAssembly;
    }
    requirement <'GPP-012'> gpp012 : GPP012_RcsCommandWrench {
        subject rcs : GriffinAttitudeEngineAssembly;
    }
    verification def Verify_GriffinRcsRuntime {
        doc /* Production fixtures griffin_fuel_exhaustion and
         * griffin_oxidizer_exhaustion observe the same live feed/chamber/RCS
         * network with complementary depleted reservoirs. Geometry is checked
         * by griffin_rcs_wrench_check; runtime command acceptance must observe
         * all six signed demands through the generated allocator and jet models.
         */
        subject rcs : GriffinAttitudeEngineAssembly;
        objective { verify gpp011; verify gpp012; }
    }
    requirement <'GES-001'> ges001 : GES001_SkirtTopology { subject skirt : GriffinEngineSkirtComponent; }
    requirement <'GES-002'> ges002 : GES002_SkirtEnvelope { subject skirt : GriffinEngineSkirtComponent; }
    requirement <'GES-003'> ges003 : GES003_SkirtDatum { subject skirt : GriffinEngineSkirtComponent; }
    requirement <'GES-004'> ges004 : GES004_BellClearance { subject skirt : GriffinEngineSkirtComponent; }
    requirement <'GES-005'> ges005 : GES005_SkirtOwnership { subject skirt : GriffinEngineSkirtComponent; }
    requirement <'GES-006'> ges006 : GES006_RailGeometry { subject skirt : GriffinEngineSkirtComponent; }
    requirement <'GES-007'> ges007 : GES007_ShellAndAdapterEnvelope { subject skirt : GriffinEngineSkirtComponent; }

    verification def Verify_GriffinPropulsionRequirements {
        subject propulsion : GriffinMainPropulsionAssembly;
        subject skirt : GriffinEngineSkirtComponent;
        objective {
            verify gpp001;
            verify gpp002;
            verify gpp003;
            verify gpp004;
            verify gpp005;
            verify gpp006;
            verify gpp007;
            verify gpp008;
            verify gpp009;
            verify ges001;
            verify ges002;
            verify ges003;
            verify ges004;
            verify ges005;
            verify ges006;
            verify ges007;
        }
    }
    verification def Verify_GriffinEngineCommands {
        subject control : GriffinEngineControlStudy;
        objective { verify gpp010; }
    }
    requirement def GPP010_SustainedPilotThrust {
        doc /* GPP-010 [runtime integration] after qualified touchdown, one
         * semantic thrust input held for burnDurationS shall lift the vehicle
         * by minimumSustainedLiftM and retain at least minimumEndVerticalSpeedMps
         * upward velocity at the end of the burn. Releasing the input shall
         * reduce delivered chamber thrust below extinguishedThrustThresholdN
         * after releaseDurationS. Fuel must decrease during the burn. The
         * force actuator input envelope shall accept the modeled feed range
         * derived in GriffinEngineControlStudy. Cold/released chamber pressure
         * shall remain below GriffinPressureFedStudy::pressureObservationTolerancePa;
         * commanded combustion pressure shall follow useful reacting mass flow*c-star/throat
         * bore area within that tolerance, including the modeled combustion and mixture
         * efficiencies. No supply-line pressure shall be
         * substituted for combustion pressure. Verify through the production
         * pilot/controller/Modelica/physics path in
         * scenarios/tests/griffin_engine_commands.rhai. This is integration
         * acceptance with explicit study thresholds, not flight qualification.
         */
    }
    requirement <'GPP-010'> gpp010 : GPP010_SustainedPilotThrust {
        subject control : GriffinEngineControlStudy;
    }

}
