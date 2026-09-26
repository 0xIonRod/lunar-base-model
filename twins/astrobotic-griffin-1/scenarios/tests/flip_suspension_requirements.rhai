import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
// Detached FLIP suspension component gate.
//
// The fixture contains only the Mission harness. This test deliberately loads
// the component asset through the live Rhai authoring path: the typed
// referenced-instance planner emits AddPrim/RemovePrim operations and the
// document owner performs composition for this Twin-local asset identity.

const PACKAGE = "FlipSuspensionRequirements";
const VERIFICATION = "Verify_FLIPSuspensionRequirements";
fn own(name) { PACKAGE + "::FlipSuspensionComponent::" + name }

fn query_ok(record) {
    record != () && record.ok != false
}

fn fail(me, message) {
    if !me.done {
        me.done = true;
        report_verdict([t_true(false, message)], "FLIP SUSPENSION REQUIREMENTS", "FLIP_SUSPENSION_REQUIREMENTS");
    }
}

// Discover the exact document opened for this test from the runtime workspace.
fn find_document() {
    let docs = query("ListOpenDocuments");
    if docs == () || docs.open_documents == () { return -1; }
    let active = -1;
    for item in docs.open_documents {
        if item.kind != "usd" { continue; }
        if item.active == true { active = item.doc_id; }
        let world = assembly_edit::inspect(item.doc_id, "/World");
        if query_ok(world) && world.prim != () && world.prim.exists == true {
            return item.doc_id;
        }
    }
    active
}

fn prim_exists(doc, path) {
    let composed = query("QueryUsdPrim", #{
        doc_id: doc,
        path: path,
        children: false,
    });
    if query_ok(composed) { return true; }
    let authored = assembly_edit::inspect(doc, path);
    query_ok(authored) && authored.prim != () && authored.prim.exists == true
}

fn source_contract() {
    let source = sysml_requirements::source();
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let component = sysml_requirements::text(source, own("componentAsset"));
    if root == () || root == "" || !root.starts_with("/")
        || component == () || component == "" {
        return #{ok: false, error: "FlipSuspensionRequirements source contract is incomplete"};
    }
    let asset = if component.starts_with("twin://") {
        component
    } else {
        "twin://" + twin_name() + "/" + component
    };
    #{ok: true, source: source, root: root, asset: asset}
}

fn on_start(me, ctx) {
    this.doc = -1;
    this.phase = 0;
    this.elapsed = 0.0;
    this.wait_generation = -1;
    this.load_generation = -1;
    this.root = "";
    this.asset = "";
    this.source = ();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done { return; }
    this.elapsed += dt();
    if this.elapsed > 30.0 {
        fail(this, "FLIP suspension runtime asset load timed out in phase " + this.phase.to_string());
        return;
    }

    if this.doc < 0 {
        this.doc = find_document();
        if this.doc < 0 { return; }
    }
    let document = assembly_edit::describe(this.doc);
    if !query_ok(document) || document.generation == () {
        fail(this, "FLIP suspension fixture did not expose a document generation");
        return;
    }

    if this.phase == 0 {
        let contract = source_contract();
        if !contract.ok {
            fail(this, contract.error);
            return;
        }
        this.source = contract.source;
        this.root = contract.root;
        this.asset = contract.asset;

        // Remove the fixture's placeholder opinion, if one is present. The
        // subsequent AddPrim is the only asset-loading operation in this gate.
        if prim_exists(this.doc, this.root) {
            let removed = assembly_edit::batch(this.doc, "Prepare detached FLIP suspension", [
                #{RemovePrim: #{edit_target: "@root@", path: this.root}}
            ], document.generation);
            if !query_ok(removed) {
                fail(this, "typed RemovePrim could not clear the suspension fixture");
                return;
            }
            this.wait_generation = document.generation;
        }
        this.phase = 1;
        return;
    }

    if this.phase == 1 {
        if this.wait_generation >= 0 {
            if document.generation <= this.wait_generation || prim_exists(this.doc, this.root) {
                return;
            }
        }
        let plan = assembly_builder::referenced_instance_plan(
            this.doc, "@root@", "/", "FlipSuspension", "Xform", this.asset,
            (), (), (), (), (),
        );
        if !query_ok(plan) {
            fail(this, "typed FLIP suspension reference plan failed: " + plan.error);
            return;
        }
        let added = assembly_edit::batch(
            this.doc, "Load detached FLIP suspension component", plan.ops, document.generation,
        );
        if !query_ok(added) {
            fail(this, "typed FLIP suspension reference operation was rejected");
            return;
        }
        this.load_generation = document.generation;
        this.phase = 2;
        return;
    }

    if this.phase == 2 {
        if document.generation <= this.load_generation { return; }
        let source = this.source;
        let children = sysml_requirement_checks::source_enum_identifiers(source, own("childNames"));
        if children.len() != 3 { fail(this, "FLIP suspension childNames source datum is incomplete"); return; }
        let root_record = query("QueryUsdPrim", #{
            doc_id: this.doc, path: this.root, children: true,
        });
        if !query_ok(root_record) { return; }
        let missing = [];
        for child in children {
            let path = this.root + "/" + child;
            if !query_ok(query("QueryUsdPrim", #{doc_id: this.doc, path: path, children: false})) {
                missing.push(path);
            }
        }
        if missing.len() > 0 { return; }
        this.phase = 3;
        return;
    }

    // Every expected value below is read from SysML. The Rhai code only
    // declares generic observation records and never duplicates geometry
    // datums or writes a USD source file.
    let source = this.source;
    let root = this.root;
    let children = sysml_requirement_checks::source_enum_identifiers(source, own("childNames"));
    let arm_scale = sysml_requirement_checks::source_number_list(source, own("armScale"));
    let arm_offset = sysml_requirements::number(source, own("armOffsetM"));
    let knuckle_radius = sysml_requirements::number(source, own("knuckleRadiusM"));
    let knuckle_width = sysml_requirements::number(source, own("knuckleWidthM"));
    let strut_scale = sysml_requirement_checks::source_number_list(source, own("strutScale"));
    let strut_offset = sysml_requirement_checks::source_number_list(source, own("strutOffset"));
    let source_owner = sysml_requirements::attribute(source, own("usdRootPath")).record.owner_handle;
    let physical_rest_source = sysml_requirements::number_from_reference(
        source, source_owner, "physicalRestLength");
    let physical_rest_length = if physical_rest_source.ok == true {
        physical_rest_source.value
    } else { () };
    let physical_rest_status = sysml_requirements::text(source, own("physicalRestLengthStatus"));
    let transform_operations = sysml_requirement_checks::source_enum_identifiers(source, own("transformOrder"));
    let transform_order = [];
    for operation in transform_operations {
        if operation == "Translate" { transform_order.push("xformOp:translate"); }
        else if operation == "Scale" { transform_order.push("xformOp:scale"); }
    }
    let requirement_handle = sysml_requirements::requirement_handle_by_short_name(source, "FSR-001");
    let provenance = if requirement_handle.ok == true {
        sysml_requirements::provenance(source, requirement_handle.handle)
    } else { requirement_handle };
    if root == () || root == "" || children.len() != 3 || arm_scale.len() != 3
        || strut_scale.len() != 3 || strut_offset.len() != 3
        || transform_order.len() != 2
        || arm_offset == () || knuckle_radius == () || knuckle_width == ()
        || physical_rest_length == () || physical_rest_status == () || physical_rest_status == ""
        || physical_rest_source.ok != true || provenance.ok != true
        || provenance.evidence.sources.len() != 2 {
        fail(this, "FlipSuspensionRequirements source contract is incomplete");
        return;
    }
    let arm = root + "/" + children[0];
    let knuckle = root + "/" + children[1];
    let strut = root + "/" + children[2];
    let checks = [];
    checks.push(sysml_requirement_checks::exists("FSR-003-root", "suspension", "fsr003", VERIFICATION, root, "Xform"));
    checks.push(sysml_requirement_checks::children("FSR-003-children", "suspension", "fsr003", VERIFICATION, root, [arm, knuckle, strut]));
    checks.push(sysml_requirement_checks::exists("FSR-003-arm", "suspension", "fsr003", VERIFICATION, arm, "Cube"));
    checks.push(sysml_requirement_checks::exists("FSR-003-knuckle", "suspension", "fsr003", VERIFICATION, knuckle, "Cylinder"));
    checks.push(sysml_requirement_checks::exists("FSR-003-strut", "suspension", "fsr003", VERIFICATION, strut, "Cube"));
    checks.push(sysml_requirement_checks::attribute_equals("FSR-001-source", "suspension", "fsr001", VERIFICATION, root, "lunco:visual:component", "flip_suspension"));
    checks.push(sysml_requirement_checks::attribute_equals("FSR-002-units", "suspension", "fsr002", VERIFICATION, root, "lunco:visual:units", "SI metres, Y-up"));
    for axis in 0..3 {
        checks.push(#{id: "FSR-007-arm-scale-" + axis.to_string(), component: "suspension", requirement: "fsr007", verification: VERIFICATION, kind: "attribute_component", path: arm, attr: "xformOp:scale", index: axis, expected: arm_scale[axis], tolerance: 0.002});
        checks.push(#{id: "FSR-007-strut-scale-" + axis.to_string(), component: "suspension", requirement: "fsr007", verification: VERIFICATION, kind: "attribute_component", path: strut, attr: "xformOp:scale", index: axis, expected: strut_scale[axis], tolerance: 0.002});
        checks.push(#{id: "FSR-007-strut-offset-" + axis.to_string(), component: "suspension", requirement: "fsr007", verification: VERIFICATION, kind: "attribute_component", path: strut, attr: "xformOp:translate", index: axis, expected: strut_offset[axis], tolerance: 0.002});
    }
    checks.push(#{id: "FSR-007-arm-offset", component: "suspension", requirement: "fsr007", verification: VERIFICATION, kind: "attribute_component", path: arm, attr: "xformOp:translate", index: 0, expected: arm_offset, tolerance: 0.002});
    checks.push(sysml_requirement_checks::attribute_equals("FSR-006-arm-order", "suspension", "fsr006", VERIFICATION, arm, "xformOpOrder", transform_order));
    checks.push(sysml_requirement_checks::attribute_equals("FSR-006-strut-order", "suspension", "fsr006", VERIFICATION, strut, "xformOpOrder", transform_order));
    checks.push(#{id: "FSR-007-knuckle-axis", component: "suspension", requirement: "fsr007",
        verification: VERIFICATION, kind: "attribute_equals", path: knuckle,
        attr: "axis", expected_attr: own("knuckleAxis")});
    checks.push(#{id: "FSR-007-knuckle-radius", component: "suspension", requirement: "fsr007", verification: VERIFICATION, kind: "attribute", path: knuckle, attr: "radius", expected: knuckle_radius, tolerance: 0.002});
    checks.push(#{id: "FSR-007-knuckle-width", component: "suspension", requirement: "fsr007", verification: VERIFICATION, kind: "attribute", path: knuckle, attr: "height", expected: knuckle_width, tolerance: 0.002});
    checks.push(sysml_requirements::constraint_check(
        "FSR-008-physical-rest-length", "suspension", "fsr008", VERIFICATION,
        "FlipSuspensionRequirements::FSRC008_PositiveRestLength",
        #{restLengthM: physical_rest_length}, "source_sysml", 0.0));
    checks.push(sysml_requirement_checks::coverage("FSR-004-dimensions", "suspension", "fsr004", VERIFICATION));
    for path in [arm, knuckle, strut] {
        checks.push(sysml_requirement_checks::attribute_equals("FSR-005-purpose-" + path, "suspension", "fsr005", VERIFICATION, path, "purpose", "render"));
        checks.push(sysml_requirement_checks::attribute_equals("FSR-005-collision-" + path, "suspension", "fsr005", VERIFICATION, path, "physics:collisionEnabled", false));
    }
    sysml_requirement_checks::finish(source, checks, "FLIP SUSPENSION REQUIREMENTS", "FLIP_SUSPENSION_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
