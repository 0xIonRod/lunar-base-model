import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
import "twin://astrobotic-griffin-1/tools/usd_geometry_inspection.rhai" as usd_geometry_inspection;
// Standalone FLIP chassis verification.

const PACKAGE = "FlipChassisRequirements";
const VERIFICATION = "Verify_FLIPChassisRequirements";

fn simulation_dependencies(me, ctx) { usd_geometry_inspection::dependencies() }

fn own(name) { PACKAGE + "::FlipChassisComponent::" + name }

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn finish_checks(source, root) {
    let model=sysml_requirements::model();
    let owner=sysml_requirements::attribute(source,own("usdPath")).record.owner_handle;
    let silver=sysml_requirements::vector_from_reference(source,owner,"metalDisplayColor");
    if !silver.ok {throw(silver.error);}
    let tolerance=f64_from(model.value(PACKAGE+"::FCC006_ChassisFinish::projectionTolerance"));
    if tolerance==() {throw("Chassis finish projection tolerance is unavailable");}
    let checks=[];
    let members=sysml_requirement_checks::source_enum_identifiers(source,own("childNames"));
    let roles=sysml_requirement_checks::source_enum_identifiers(source,own("appearanceRoles"));
    if members.is_empty() || members.len()!=roles.len() {throw("Chassis finish roles do not cover the source members");}
    for role in roles {if role!="Metal" && role!="Enclosure" {throw("Unknown chassis finish role: "+role);}}
    for prefix in ["metal","enclosure"] {
        let name=model.value(own(prefix+"MaterialName"));
        if !sysml_enum_is(name) {throw("Chassis material identity is unavailable");}
        let selected=[];
        for index in 0..members.len() {if roles[index].to_lower()==prefix {selected.push(members[index]);}}
        let profile=#{name:name.literal,prefix:prefix,members:selected};
        let material=root+"/Looks/"+profile.name;let shader=material+"/Surface";
        let id="FCC-006-"+profile.name;
        checks.push(sysml_requirement_checks::exists(id+"-material","chassis","fcc006",VERIFICATION,material,"Material"));
        checks.push(sysml_requirement_checks::exists(id+"-shader","chassis","fcc006",VERIFICATION,shader,"Shader"));
        checks.push(sysml_requirement_checks::attribute_equals(id+"-surface-model","chassis","fcc006",VERIFICATION,shader,"info:id","UsdPreviewSurface"));
        for member in profile.members {
            checks.push(#{id:id+"-binding-"+member,component:"chassis",requirement:"fcc006",verification:VERIFICATION,
                kind:"relationship",path:root+"/"+member,rel:"material:binding",targets:[material]});
        }
        let expected_color=if profile.prefix=="metal" {silver.value} else {model.value(own(profile.prefix+"DisplayColor"))};
        for axis in 0..3 {
            checks.push(#{id:id+"-color-"+axis,component:"chassis",requirement:"fcc006",verification:VERIFICATION,
                kind:"attribute_component",path:shader,attr:"inputs:diffuseColor",index:axis,
                expected:expected_color[axis],tolerance:tolerance});
        }
        for field in [["Metallic","inputs:metallic"],["Roughness","inputs:roughness"]] {
            checks.push(#{id:id+"-"+field[0],component:"chassis",requirement:"fcc006",verification:VERIFICATION,
                kind:"attribute",path:shader,attr:field[1],expected:f64_from(model.value(own(profile.prefix+field[0]))),tolerance:tolerance});
        }
        let surface=query("QueryUsdPrim",#{path:shader,attrs:["inputs:diffuseColor","inputs:metallic","inputs:roughness"]});
        let network=query("QueryUsdPrim",#{path:material,connections:true});
        let record=if usd_geometry_inspection::same_snapshot([surface,network]) {surface} else {()};
        let color=surface.attrs["inputs:diffuseColor"];
        let inputs=[];
        for field in [["red",0],["green",1],["blue",2]] {
            inputs.push([field[0],usd_geometry_inspection::measurement(if color!=() {color[field[1]]} else {()},record,"Chassis surface color is unavailable")]);
        }
        for field in [["metallic","inputs:metallic"],["roughness","inputs:roughness"]] {
            inputs.push([field[0],usd_geometry_inspection::measurement(surface.attrs[field[1]],record,"Chassis surface parameter is unavailable")]);
        }
        inputs.push(["surfaceConnected",usd_geometry_inspection::measurement(
            network.connections!=() && network.connections["outputs:surface"]==[shader+".outputs:surface"],record,"Chassis material surface connection is unavailable")]);
        let constraint=PACKAGE+"::FCCC006_NormalizedPreviewSurface";
        let observations=sysml_requirements::required_constraint_input_observations(model,model.requirement(PACKAGE+"::fcc006"),constraint,inputs);
        checks.push(sysml_requirements::required_constraints_check(id+"-normalized-controls","chassis","fcc006",VERIFICATION,constraint,observations,"typed",0.0));
    }
    checks
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let root = sysml_requirements::text(source, own("usdPath"));
    let source_owner = sysml_requirements::attribute(source, own("usdPath")).record.owner_handle;
    let chassis_width = sysml_requirements::number_from_reference(source,
        source_owner, "lowerFrameWidthM");
    let chassis_length = sysml_requirements::number_from_reference(source,
        source_owner, "lowerFrameLengthM");
    let member_names = sysml_requirement_checks::source_enum_identifiers(source,
        own("childNames"));
    let child_paths = [];
    for name in member_names { child_paths.push(root + "/" + name); }
    let checks = [];
    checks.push(sysml_requirement_checks::exists("FCC-001-root", "chassis", "fcc001", VERIFICATION, root, "Xform"));
    checks.push(sysml_requirement_checks::children("FCC-001-structure", "chassis", "fcc001", VERIFICATION, root, child_paths));
    checks.push(#{id: "FCC-002-width", component: "chassis", requirement: "fcc002",
        verification: VERIFICATION, kind: "extent_component", path: root + "/LowerFrame",
        index: 2, multiplier: 1.0, expected: chassis_width.value,
        tolerance: 0.002});
    checks.push(#{id: "FCC-002-length", component: "chassis", requirement: "fcc002",
        verification: VERIFICATION, kind: "extent_component", path: root + "/LowerFrame",
        index: 0, multiplier: 1.0, expected: chassis_length.value,
        tolerance: 0.002});
    for path in [root + "/LowerFrame", root + "/WhiteEquipmentBox",
        root + "/FrontBumper", root + "/PayloadDeck"] {
        checks.push(sysml_requirement_checks::attribute_equals("FCC-003-collision-" + path,
            "chassis", "fcc003", VERIFICATION, path, "physics:collisionEnabled", true));
    }
    checks.push(sysml_requirement_checks::attribute_equals("FCC-003-service-cover-render-only",
        "chassis", "fcc003", VERIFICATION, root + "/ServicePanel", "physics:collisionEnabled", false));
    for field in [
        #{id: "FCC-005-box-width", path: root + "/WhiteEquipmentBox", index: 2, attr: "equipmentBoxWidthM"},
        #{id: "FCC-005-box-height", path: root + "/WhiteEquipmentBox", index: 1, attr: "equipmentBoxHeightM"},
        #{id: "FCC-005-box-length", path: root + "/WhiteEquipmentBox", index: 0, attr: "equipmentBoxLengthM"},
        #{id: "FCC-005-deck-width", path: root + "/PayloadDeck", index: 2, attr: "payloadDeckWidthM"},
        #{id: "FCC-005-deck-thickness", path: root + "/PayloadDeck", index: 1, attr: "payloadDeckThicknessM"},
        #{id: "FCC-005-deck-length", path: root + "/PayloadDeck", index: 0, attr: "payloadDeckLengthM"}
    ] {
        let datum=sysml_requirements::number_from_reference(source, source_owner, field.attr);
        if !datum.ok {throw(datum.error);}
        checks.push(#{id:field.id,component:"chassis",requirement:"fcc005",verification:VERIFICATION,
            kind:"extent_component",path:field.path,index:field.index,expected:datum.value,tolerance:0.002});
    }
    checks.push(#{id: "FCC-005-box-y", component: "chassis", requirement: "fcc005",
        verification: VERIFICATION, kind: "attribute_component", path: root + "/WhiteEquipmentBox",
        attr: "xformOp:translate", index: 1, expected: sysml_requirements::number_from_reference(source, source_owner, "equipmentBoxCenterYM").value, tolerance: 0.002});
    checks.push(#{id: "FCC-005-deck-y", component: "chassis", requirement: "fcc005",
        verification: VERIFICATION, kind: "attribute_component", path: root + "/PayloadDeck",
        attr: "xformOp:translate", index: 1, expected: sysml_requirements::number_from_reference(source, source_owner, "payloadDeckCenterYM").value, tolerance: 0.002});
    checks.push(sysml_requirement_checks::coverage("FCC-003-ownership", "chassis", "fcc003", VERIFICATION));
    checks.push(sysml_requirement_checks::coverage("FCC-004-traceability", "chassis", "fcc004", VERIFICATION));
    for check in finish_checks(source,root) {checks.push(check);}
    sysml_requirement_checks::finish(source, checks, "FLIP CHASSIS REQUIREMENTS", "FLIP_CHASSIS_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
