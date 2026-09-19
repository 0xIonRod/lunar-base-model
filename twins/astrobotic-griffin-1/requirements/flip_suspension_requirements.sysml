package FlipSuspensionRequirements {
    private import ScalarValues::Real;
    private import ScalarValues::String;

    // The public FLIP sources describe four-wheel mobility and independent
    // suspension technology.  Exact arm/knuckle/strut dimensions below are
    // explicitly labelled Twin visual-study values until an ICD is released.
    part def FlipSuspensionComponent {
        attribute usdRootPath : String = "/FlipSuspension";
        attribute componentAsset : String = "components/rover/flip_suspension_visual.usda";
        attribute sourceReference : String = "https://www.astrolab.space/flip-rover/";
        attribute secondaryReference : String = "https://venturi.space/rovers/";
        attribute sourceFact : String = "FLIP is a four-wheeled lunar rover; each wheel flank has an independent suspension system";
        attribute sourceRationale : String = "The sources establish the mobility architecture; a detached suspension asset keeps each wheel mechanism reusable and independently verifiable";
        attribute geometryStatus : String = "metric visual study proxy; production suspension ICD not public";
        attribute localFrame : String = "Y-up, right-handed, SI metres; origin at wheel hub; canonical arm points +X";
        attribute collisionPolicy : String = "all suspension geometry is render-only; PhysicsCollisionAPI collisionEnabled=false";
        attribute armScale : Real[3] = (0.65, 0.16, 0.16);
        attribute armOffsetM : Real = 0.325;
        attribute knuckleRadiusM : Real = 0.18;
        attribute knuckleWidthM : Real = 0.36;
        attribute strutScale : Real[3] = (0.14, 0.36, 0.14);
        attribute strutOffset : Real[3] = (0.0, 0.20, 0.0);
        attribute transformOrder : String[2] = ("xformOp:translate", "xformOp:scale");
        attribute childNames : String[3] = ("SuspensionArm", "SuspensionKnuckle", "SuspensionStrut");
        attribute armEnvelopeM : Real[3] = (0.65, 0.16, 0.16);
        attribute knuckleAxis : String = "X";
        attribute strutEnvelopeM : Real[3] = (0.14, 0.72, 0.14);
        // The physical transition datum is owned once by FlipRequirements::FlipRover.
        // Keeping a qualified reference here avoids a second, silently divergent
        // suspension-length literal in the detached component contract.
        attribute physicalRestLengthRequirement : String = "FlipRequirements::FlipRover::physicalSuspensionRestLengthM";
        attribute physicalRestLengthStatus : String = "ramp-transition simulator assumption; FLIP as-built suspension ICD not public";
        attribute presentationOwnership : String = "all three members are render-only; wheel carrier owns contact and suspension physics";
    }

    requirement def FSR001_SourceTraceability {
        doc /* FSR-001 [evidence] public mobility/suspension sources and the visual-study status are recorded on the component contract. */
    }
    requirement def FSR002_LocalFrame {
        doc /* FSR-002 [frame] the component uses the canonical Y-up SI-metre frame with its origin at the wheel hub. */
    }
    requirement def FSR003_Topology {
        doc /* FSR-003 [topology] one detached component root exposes an arm, knuckle, and strut with stable USD types. */
    }
    requirement def FSR004_Dimensions {
        doc /* FSR-004 [geometry] child scales, offsets, radius, and width match the metric values in this package. */
    }
    requirement def FSR005_RenderOnlyCollision {
        doc /* FSR-005 [physics boundary] suspension presentation geometry is render-only and cannot create a second collider. */
    }
    requirement def FSR006_TransformOrder {
        doc /* FSR-006 [transform] translated suspension members shall use translate-before-scale so metric offsets remain true in the composed stage. */
    }
    requirement def FSR007_EnvelopeAndAxis {
        doc /* FSR-007 [geometry] the arm and strut shall use the declared metric envelopes, the knuckle shall be a 0.18 m radius by 0.36 m X-axis cylinder, and all child axes shall match this component contract. */
    }
    requirement def FSR008_PhysicalTransitionEnvelope {
        doc /* FSR-008 [physics boundary] the physical FLIP realization shall expose the 1.20 m ramp-transition suspension rest length as a separate study datum from the 0.70 m generic suspension default. Source: Griffin physical-ramp replay evidence. Rationale: the longer envelope is required to acquire the steep ramp surface before the released chassis loses support; it is explicitly replaceable when supplier data arrives. */
    }

    requirement fsr001 : FSR001_SourceTraceability { subject suspension : FlipSuspensionComponent; }
    requirement fsr002 : FSR002_LocalFrame { subject suspension : FlipSuspensionComponent; }
    requirement fsr003 : FSR003_Topology { subject suspension : FlipSuspensionComponent; }
    requirement fsr004 : FSR004_Dimensions { subject suspension : FlipSuspensionComponent; }
    requirement fsr005 : FSR005_RenderOnlyCollision { subject suspension : FlipSuspensionComponent; }
    requirement fsr006 : FSR006_TransformOrder { subject suspension : FlipSuspensionComponent; }
    requirement fsr007 : FSR007_EnvelopeAndAxis { subject suspension : FlipSuspensionComponent; }
    requirement fsr008 : FSR008_PhysicalTransitionEnvelope { subject suspension : FlipSuspensionComponent; }

    verification def Verify_FLIPSuspensionRequirements {
        subject suspension : FlipSuspensionComponent;
        verify fsr001;
        verify fsr002;
        verify fsr003;
        verify fsr004;
        verify fsr005;
        verify fsr006;
        verify fsr007;
        verify fsr008;
    }
}
