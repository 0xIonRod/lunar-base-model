package GriffinBusRequirements {
    private import ScalarValues::String;

    // The bus component owns the visual frame and envelope contract.  Metric
    // dimensions are intentionally read from GriffinLanderRequirements so the
    // component package cannot drift from the lander source of truth.
    part def GriffinBusComponent {
        attribute usdPath : String = "/World/Griffin1/Bus";
        attribute sourceComponent : String = "GriffinLanderRequirements::GriffinLanderComponent";
        attribute profileAttribute : String = "lunco:visual:body_profile";
        attribute profileValue : String = "hexagonal-prism";
        attribute envelopeSource : String = "bodyWidthM,bodyDepthM,bodyHeightM";
        attribute sourceReference : String = "https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/";
        attribute sourceFact : String = "Griffin uses a stout aluminum frame and main isogrid deck for payload mounting";
        attribute sourceRationale : String = "The bus is the structural datum from which tanks, legs, engines, solar arrays and ramps are placed; its faceted envelope must remain independently inspectable";
        attribute geometryStatus : String = "metric visual study proxy; public page does not publish a complete CAD envelope";
    }

    requirement def GBC001_BusIdentity {
        doc /* GBC-001 [topology] the bus is a named, visible hexagonal visual component with a perimeter frame, equipment body, and upper deck. */
    }
    requirement def GBC002_BusEnvelope {
        doc /* GBC-002 [geometry] the bus envelope is checked against the lander SysML metric width, depth, and height values. */
    }
    requirement def GBC003_BusPresentationOwnership {
        doc /* GBC-003 [visual ownership] the bus presentation component is render-only and does not replace the flight body or collider owner. */
    }
    requirement def GBC004_BusTraceability {
        doc /* GBC-004 [evidence] the bus path, profile, and envelope source names resolve from this package and its referenced lander source. */
    }

    requirement gbc001 : GBC001_BusIdentity { subject bus : GriffinBusComponent; }
    requirement gbc002 : GBC002_BusEnvelope { subject bus : GriffinBusComponent; }
    requirement gbc003 : GBC003_BusPresentationOwnership { subject bus : GriffinBusComponent; }
    requirement gbc004 : GBC004_BusTraceability { subject bus : GriffinBusComponent; }

    verification def Verify_GriffinBusRequirements {
        subject bus : GriffinBusComponent;
        verify gbc001;
        verify gbc002;
        verify gbc003;
        verify gbc004;
    }
}
