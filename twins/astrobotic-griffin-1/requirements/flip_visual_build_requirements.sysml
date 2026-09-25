package FlipVisualBuildRequirements {
    private import ScalarValues::Integer;
    private import ScalarValues::String;

    // Visual authoring target; distinct from runtime and flight qualification.
    // Verification is PLANNED until a saved-model inspection supplies evidence.
    part def FlipVisualBuild {
        attribute scope : String = "reference-based visual CAD and optional visual USD";
        attribute referenceSet : String = "contracts/flip_visual_build.md";
        attribute primaryReference : String = "Astrolab FLIP product-page renders captured in research/flip-review-2026-09-25";
        attribute referenceStatus : String = "presentation evidence; not as-built dimensions";
        attribute wheelCount : Integer = 4;
        attribute wheelNames : String = "FL,FR,RL,RR";
        attribute coordinateFrame : String = "X lateral, Y up, Z longitudinal; signed forward recorded by build";
        attribute parameterPolicy : String = "one selected study parameter record; reconcile legacy tables before use";
        attribute geometryTolerancePolicy : String = "record numerical inspection tolerances before checks; not manufacturing tolerances";
        attribute posePolicy : String = "explicit stowed/deployed study poses; no inferred flight joint count or limits";
        attribute verificationStatus : String = "PLANNED; saved-model and visual evidence required";
    }

    requirement def FVB001_ReferenceRevision {
        doc /* FVB-001 [visual build]
        The visual model shall identify one primary reference revision and a dated evidence record for every secondary reference used.
        Acceptance: Compare source images with the model; record image type, URL or local path, date if known and which visible feature each image supports.
        */
    }
    requirement fvb001 : FVB001_ReferenceRevision { subject model : FlipVisualBuild; }

    requirement def FVB002_Frame {
        doc /* FVB-002 [visual build]
        The model shall expose a documented origin, X-lateral/Y-up/Z-longitudinal frame, signed forward axis and explicit CAD-to-export unit transform.
        Acceptance: Inspect root metadata and named mount datums; round-trip a known length and orientation through any requested export.
        */
    }
    requirement fvb002 : FVB002_Frame { subject model : FlipVisualBuild; }

    requirement def FVB003_Dimensions {
        doc /* FVB-003 [visual build]
        The visual build shall use one selected set of study dimensions and distinguish primitive size, complete component bounds and whole-vehicle bounds.
        Acceptance: Compare measured bounds to the selected parameter record. Resolve legacy CAD/SysML conflicts before reusing their values.
        */
    }
    requirement fvb003 : FVB003_Dimensions { subject model : FlipVisualBuild; }

    requirement def FVB004_ChassisSilhouette {
        doc /* FVB-004 [visual build]
        The chassis shall reproduce the selected reference's low central equipment-body silhouette and its relationship to wheel height and wheelbase.
        Acceptance: Inspect front, side and three-quarter views beside the primary reference; record any intentional proportional deviation as a study choice.
        */
    }
    requirement fvb004 : FVB004_ChassisSilhouette { subject model : FlipVisualBuild; }

    requirement def FVB005_ComponentOwnership {
        doc /* FVB-005 [visual build]
        Chassis, each wheel station, solar assembly, sensors, battery enclosures and power controller shall have separate stable identities and documented mount ownership.
        Acceptance: Inspect the object tree and component map; every visible part shall belong to one intended assembly and be independently selectable at its required edit boundary.
        */
    }
    requirement fvb005 : FVB005_ComponentOwnership { subject model : FlipVisualBuild; }

    requirement def FVB006_WheelCount {
        doc /* FVB-006 [visual build]
        The visual rover shall contain exactly four active wheel stations with the names specified by wheelNames.
        Acceptance: Inspect the object tree and unobstructed views; repeated or hidden legacy wheel geometry shall not appear in the deliverable.
        */
    }
    requirement fvb006 : FVB006_WheelCount { subject model : FlipVisualBuild; }

    requirement def FVB007_WheelConstruction {
        doc /* FVB-007 [visual build]
        Each wheel shall visibly distinguish an open hub/spoke or web structure, outer rim and tire band consistent with the selected reference.
        Acceptance: Inspect a focused wheel face and oblique view; opaque hub disks shall not substitute for the reference's visible open construction.
        */
    }
    requirement fvb007 : FVB007_WheelConstruction { subject model : FlipVisualBuild; }

    requirement def FVB008_TireAppearance {
        doc /* FVB-008 [visual build]
        The visible tire band and tread shall match the selected reference's broad continuous band and fine supporting structure.
        Acceptance: Compare a focused wheel view; remove the legacy chunky lug pattern unless the chosen dated reference supports it.
        */
    }
    requirement fvb008 : FVB008_TireAppearance { subject model : FlipVisualBuild; }

    requirement def FVB009_StationConnectivity {
        doc /* FVB-009 [visual build]
        Every wheel station shall have visible, geometrically connected supports between its chassis attachment and hub datum.
        Acceptance: Measure support-to-mount distances in a common frame; intentional joints/gaps require named interfaces and documented purpose. A compound containing detached arm and knuckle is insufficient.
        */
    }
    requirement fvb009 : FVB009_StationConnectivity { subject model : FlipVisualBuild; }

    requirement def FVB010_WheelClearance {
        doc /* FVB-010 [visual build]
        Wheel geometry shall clear the chassis and other non-mating parts in every authored presentation pose.
        Acceptance: Run pairwise interference checks with a named intentional-contact allowlist; inspect the wheel/body region from more than one direction.
        */
    }
    requirement fvb010 : FVB010_WheelClearance { subject model : FlipVisualBuild; }

    requirement def FVB011_ArraySilhouette {
        doc /* FVB-011 [visual build]
        The deployed solar assembly shall reproduce the primary reference's large upright array and its location relative to the chassis.
        Acceptance: Compare deployed front, side and oblique views; the legacy elevated horizontal two-wing canopy does not satisfy this selected target. Internal segmentation remains a labelled study choice.
        */
    }
    requirement fvb011 : FVB011_ArraySilhouette { subject model : FlipVisualBuild; }

    requirement def FVB012_CellLayout {
        doc /* FVB-012 [visual build]
        The array shall expose distinct backing, perimeter frame and a dense organized cell pattern matching the selected reference.
        Acceptance: Inspect the array face and edge; record row/group layout and border arrangement from the selected image without asserting electrical cell count or efficiency.
        */
    }
    requirement fvb012 : FVB012_CellLayout { subject model : FlipVisualBuild; }

    requirement def FVB013_HingeSupport {
        doc /* FVB-013 [visual build]
        The solar assembly's visible hinge and supports shall reach both the panel and body mount datums.
        Acceptance: Measure support continuity and inspect a close-up; decorative hinge cylinders separated from the panel do not satisfy this requirement.
        */
    }
    requirement fvb013 : FVB013_HingeSupport { subject model : FlipVisualBuild; }

    requirement def FVB014_PresentationPoses {
        doc /* FVB-014 [visual build]
        The solar assembly shall support an explicitly named stowed pose and deployed pose with one documented controllable motion owner.
        Acceptance: Change the pose control, verify panel/frame/cells and attached hardware move together, and record the chosen study limits. No flight mechanism is inferred from this presentation motion.
        */
    }
    requirement fvb014 : FVB014_PresentationPoses { subject model : FlipVisualBuild; }

    requirement def FVB015_DeploymentClearance {
        doc /* FVB-015 [visual build]
        The moving solar assembly shall clear non-mating chassis, wheels, payload and sensors across the authored pose range.
        Acceptance: Perform and document a pose sweep with angles, sampling interval and worst measured clearances. Endpoints alone are insufficient; sampled results do not prove continuous clearance.
        */
    }
    requirement fvb015 : FVB015_DeploymentClearance { subject model : FlipVisualBuild; }

    requirement def FVB016_SensorPlacement {
        doc /* FVB-016 [visual build]
        Visible cameras, antenna-like elements and their supports shall occupy the reference-supported locations without intersecting or being unintentionally hidden by the panel.
        Acceptance: Compare focused views, check mount continuity and optical-facing clearance; ambiguous hardware receives a neutral visual label rather than an invented sensor type.
        */
    }
    requirement fvb016 : FVB016_SensorPlacement { subject model : FlipVisualBuild; }

    requirement def FVB017_EquipmentPackaging {
        doc /* FVB-017 [visual build]
        Battery-pack envelopes and power-controller geometry shall be separately identifiable and fit the selected equipment layout without unintended overlaps.
        Acceptance: Inspect named envelopes and pair intersections; use dated supplier information to guide pack count while labelling unresolved dimensions, placement and articulation.
        */
    }
    requirement fvb017 : FVB017_EquipmentPackaging { subject model : FlipVisualBuild; }

    requirement def FVB018_Finish {
        doc /* FVB-018 [visual build]
        Visible frame, body, wheel and cell surface appearance shall be consistent with the selected reference revision.
        Acceptance: Review neutrally lit views; explain differences caused by alternate reference generations and avoid interpreting rendered colour as material certification.
        */
    }
    requirement fvb018 : FVB018_Finish { subject model : FlipVisualBuild; }

    requirement def FVB019_SavedDeliverable {
        doc /* FVB-019 [visual build]
        The saved CAD document shall preserve component identities, geometry, appearance and presentation-pose controls when reopened in a fresh application session.
        Acceptance: Open the delivered file without rebuilding it; repeat object, bounds and pose checks and record its hash. A newer generator alone is not evidence of saved-model compliance.
        */
    }
    requirement fvb019 : FVB019_SavedDeliverable { subject model : FlipVisualBuild; }

    requirement def FVB020_VisualAcceptance {
        doc /* FVB-020 [visual build]
        The completed visual build shall include comparable front, side, top and three-quarter views plus focused wheel, hinge and sensor views with requirement-specific findings.
        Acceptance: Pair each result with saved-model hash, reference revision and pose. If USD is delivered, record CAD-to-USD identity and pose mapping and compare both; do not claim physics qualification.
        */
    }
    requirement fvb020 : FVB020_VisualAcceptance { subject model : FlipVisualBuild; }

    verification def Verify_FLIPVisualBuildRequirements {
        subject model : FlipVisualBuild;
        verify fvb001;
        verify fvb002;
        verify fvb003;
        verify fvb004;
        verify fvb005;
        verify fvb006;
        verify fvb007;
        verify fvb008;
        verify fvb009;
        verify fvb010;
        verify fvb011;
        verify fvb012;
        verify fvb013;
        verify fvb014;
        verify fvb015;
        verify fvb016;
        verify fvb017;
        verify fvb018;
        verify fvb019;
        verify fvb020;
    }
}
