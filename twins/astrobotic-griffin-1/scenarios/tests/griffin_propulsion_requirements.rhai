// Standalone Griffin main-propulsion visual verification.  Thrust and
// collision remain owned by the flight model; this observer checks only the
// replaceable bell/throat presentation components.

const PACKAGE = "GriffinPropulsionRequirements";
const VERIFICATION = "Verify_GriffinPropulsionRequirements";

fn own(name) { PACKAGE + "::GriffinMainPropulsionAssembly::" + name }
fn skirt(name) { PACKAGE + "::GriffinEngineSkirtComponent::" + name }
fn parent(name) { "GriffinLanderRequirements::GriffinLanderComponent::" + name }
fn visual(name) { "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::" + name }

fn position(id, path, index, expected) {
    #{id: id, component: "engine", requirement: "gpp005",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: 0.002}
}

fn component_position(id, path, index, expected) {
    #{id: id, component: "engine_skirt", requirement: "ges003",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: 0.002}
}

fn attribute(id, requirement, path, attr, expected) {
    #{id: id, component: "engine", requirement: requirement,
      verification: VERIFICATION, kind: "attribute", path: path,
      attr: attr, expected: expected, tolerance: 0.002}
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let bell_radius = sysml_requirements::number(source, own("bellRadiusM"));
    let bell_height = sysml_requirements::number(source, own("bellHeightM"));
    let throat_radius = sysml_requirements::number(source, own("throatRadiusM"));
    let throat_height = sysml_requirements::number(source, own("throatHeightM"));
    let names = component_requirements::source_enum_identifiers(source, visual("mainEngineInstances"));
    let stations = component_requirements::source_position_list(source, visual("engineStations"));
    let skirt_root = root + "/" + sysml_requirements::text(source, skirt("componentRootName"));
    let skirt_names = component_requirements::source_text_list(source, skirt("componentMemberNames"));
    let skirt_shell = skirt_root + "/" + sysml_requirements::text(source, skirt("shellName"));
    let skirt_width = sysml_requirements::number(source, skirt("railLengthM"));
    let skirt_depth = skirt_width;
    let skirt_height = sysml_requirements::number(source, skirt("railHeightM"));
    let skirt_section = sysml_requirements::number(source, skirt("railWidthM"));
    let skirt_shell_depth = sysml_requirements::number(source, skirt("shellDepthM"));
    let skirt_assembly_y = sysml_requirements::number(source, skirt("assemblyMountYM"));
    let adapter_name = sysml_requirements::text(source, skirt("adapterPlateName"));
    let adapter_width = sysml_requirements::number(source, skirt("adapterPlateWidthM"));
    let adapter_depth = sysml_requirements::number(source, skirt("adapterPlateDepthM"));
    let adapter_height = sysml_requirements::number(source, skirt("adapterPlateHeightM"));
    let skirt_transform_order = sysml_requirements::string_vector(source, skirt("transformOrder"));
    let skirt_transform_order = if skirt_transform_order == () { [] } else { skirt_transform_order };
    let checks = [];
    checks.push(component_requirements::source_list_count("GPP-001-count", "propulsion", "gpp001", VERIFICATION, visual("mainEngineInstances"), parent("engineCount")));
    checks.push(component_requirements::source_list_count("GPP-005-stations", "engine", "gpp005", VERIFICATION, visual("engineStations"), parent("engineCount")));
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        checks.push(component_requirements::exists("GPP-001-" + name, "engine", "gpp001", VERIFICATION, path, "Xform"));
        checks.push(component_requirements::children("GPP-002-" + name, "engine", "gpp002", VERIFICATION, path,
            [path + "/Bell", path + "/Throat"]));
            checks.push(component_requirements::attribute_equals("GPP-002-" + name + "-purpose", "engine", "gpp002", VERIFICATION,
                path + "/Bell", "purpose", "render"));
        if bell_radius != () && bell_height != () && throat_radius != () && throat_height != () {
            checks.push(attribute("GPP-006-" + name + "-bell-radius", "gpp006", path + "/Bell", "radius", bell_radius));
            checks.push(attribute("GPP-006-" + name + "-bell-height", "gpp006", path + "/Bell", "height", bell_height));
            checks.push(attribute("GPP-006-" + name + "-throat-radius", "gpp006", path + "/Throat", "radius", throat_radius));
            checks.push(attribute("GPP-006-" + name + "-throat-height", "gpp006", path + "/Throat", "height", throat_height));
            checks.push(component_requirements::attribute_equals("GPP-006-" + name + "-bell-axis", "engine", "gpp006", VERIFICATION,
                path + "/Bell", "axis", "Y"));
            checks.push(#{id: "GPP-006-" + name + "-throat-center", component: "engine",
                requirement: "gpp006", verification: VERIFICATION, kind: "attribute_component",
                path: path + "/Throat", attr: "xformOp:translate", index: 1,
                expected_attr: own("throatCenterYM"), tolerance: 0.002});
        }
        if stations.len() == names.len() {
            checks.push(position("GPP-005-" + name + "-x", path, 0, stations[index].x));
            checks.push(position("GPP-005-" + name + "-y", path, 1, stations[index].y));
            checks.push(position("GPP-005-" + name + "-z", path, 2, stations[index].z));
        }
    }
    // The skirt is a separate referenced component.  Validate its four rails
    // and shell in the composed assembly; the source file remains the only
    // owner of the component geometry.
    if skirt_names.len() == 4 && skirt_width != () && skirt_depth != ()
        && skirt_height != () && skirt_section != ()
        && skirt_shell_depth != () && skirt_assembly_y != ()
        && adapter_name != () && adapter_name != ""
        && adapter_width != () && adapter_depth != () && adapter_height != ()
        && skirt_transform_order.len() == 2 {
        let rail_paths = [];
        for name in skirt_names { rail_paths.push(skirt_root + "/" + name); }
        checks.push(component_requirements::exists("GES-001-component", "engine_skirt", "ges001", VERIFICATION, skirt_root, "Xform"));
        checks.push(component_requirements::children("GES-001-rails", "engine_skirt", "ges001", VERIFICATION, skirt_root, rail_paths));
        checks.push(component_position("GES-003-assembly-y", skirt_root, 1, skirt_assembly_y));
        for index in 0..skirt_names.len() {
            let rail = rail_paths[index];
            checks.push(component_requirements::exists("GES-001-" + skirt_names[index], "engine_skirt", "ges001", VERIFICATION, rail, "Cube"));
            checks.push(component_requirements::attribute_equals("GES-005-" + skirt_names[index] + "-purpose", "engine_skirt", "ges005", VERIFICATION, rail, "purpose", "render"));
            checks.push(component_requirements::attribute_equals("GES-005-" + skirt_names[index] + "-collision", "engine_skirt", "ges005", VERIFICATION, rail, "physics:collisionEnabled", false));
            checks.push(component_requirements::attribute_equals("GES-005-" + skirt_names[index] + "-order", "engine_skirt", "ges005", VERIFICATION, rail, "xformOpOrder", skirt_transform_order));
            if index < 2 {
                checks.push(component_requirements::extent_component("GES-006-" + skirt_names[index] + "-length", "engine_skirt", "ges006", VERIFICATION, rail, 0, skirt("railLengthM"), 1.0, 0.002));
                checks.push(component_requirements::extent_component("GES-006-" + skirt_names[index] + "-height", "engine_skirt", "ges006", VERIFICATION, rail, 1, skirt("railHeightM"), 1.0, 0.002));
                checks.push(component_requirements::extent_component("GES-006-" + skirt_names[index] + "-width", "engine_skirt", "ges006", VERIFICATION, rail, 2, skirt("railWidthM"), 1.0, 0.002));
                checks.push(component_position("GES-006-" + skirt_names[index] + "-z", rail, 2, if index == 0 { sysml_requirements::number(source, skirt("railFrontCenterZM")) } else { sysml_requirements::number(source, skirt("railRearCenterZM")) }));
            } else {
                checks.push(component_requirements::extent_component("GES-006-" + skirt_names[index] + "-length", "engine_skirt", "ges006", VERIFICATION, rail, 2, skirt("railLengthM"), 1.0, 0.002));
                checks.push(component_requirements::extent_component("GES-006-" + skirt_names[index] + "-height", "engine_skirt", "ges006", VERIFICATION, rail, 1, skirt("railHeightM"), 1.0, 0.002));
                checks.push(component_requirements::extent_component("GES-006-" + skirt_names[index] + "-width", "engine_skirt", "ges006", VERIFICATION, rail, 0, skirt("railWidthM"), 1.0, 0.002));
                checks.push(component_position("GES-006-" + skirt_names[index] + "-x", rail, 0, if index == 2 { sysml_requirements::number(source, skirt("railPortCenterXM")) } else { sysml_requirements::number(source, skirt("railStarboardCenterXM")) }));
            }
        }
        checks.push(component_requirements::exists("GES-002-shell", "engine_skirt", "ges002", VERIFICATION, skirt_shell, "Mesh"));
        checks.push(component_requirements::bounds_component("GES-007-shell-width", "engine_skirt", "ges007", VERIFICATION, skirt_shell, 0, skirt("railLengthM"), 2.0, 0.002));
        checks.push(component_requirements::bounds_component("GES-007-shell-depth-y", "engine_skirt", "ges007", VERIFICATION, skirt_shell, 1, skirt("shellDepthM"), 2.0, 0.002));
        checks.push(component_requirements::bounds_component("GES-007-shell-envelope-depth", "engine_skirt", "ges007", VERIFICATION, skirt_shell, 2, skirt("railLengthM"), 2.0, 0.002));
        let adapter_path = skirt_root + "/" + adapter_name;
        checks.push(component_requirements::exists("GES-007-adapter-plate", "engine_skirt", "ges007", VERIFICATION, adapter_path, "Cube"));
        checks.push(component_requirements::extent_component("GES-007-adapter-width", "engine_skirt", "ges007", VERIFICATION, adapter_path, 0, skirt("adapterPlateWidthM"), 1.0, 0.002));
        checks.push(component_requirements::extent_component("GES-007-adapter-height", "engine_skirt", "ges007", VERIFICATION, adapter_path, 1, skirt("adapterPlateHeightM"), 1.0, 0.002));
        checks.push(component_requirements::extent_component("GES-007-adapter-depth", "engine_skirt", "ges007", VERIFICATION, adapter_path, 2, skirt("adapterPlateDepthM"), 1.0, 0.002));
        checks.push(component_requirements::attribute_equals("GES-005-adapter-purpose", "engine_skirt", "ges005", VERIFICATION, adapter_path, "purpose", "render"));
        checks.push(component_requirements::attribute_equals("GES-005-adapter-collision", "engine_skirt", "ges005", VERIFICATION, adapter_path, "physics:collisionEnabled", false));
        checks.push(component_requirements::attribute_equals("GES-005-shell-purpose", "engine_skirt", "ges005", VERIFICATION, skirt_shell, "purpose", "render"));
        checks.push(component_requirements::attribute_equals("GES-005-shell-collision", "engine_skirt", "ges005", VERIFICATION, skirt_shell, "physics:collisionEnabled", false));
        checks.push(component_requirements::coverage("GES-004-clearance", "engine_skirt", "ges004", VERIFICATION));
        checks.push(component_requirements::coverage("GES-002-envelope", "engine_skirt", "ges002", VERIFICATION));
    } else {
        checks.push(component_requirements::coverage("GES-001-source", "engine_skirt", "ges001", VERIFICATION));
    }
    checks.push(component_requirements::coverage("GPP-003-ownership", "propulsion", "gpp003", VERIFICATION));
    checks.push(component_requirements::coverage("GPP-004-traceability", "propulsion", "gpp004", VERIFICATION));
    component_requirements::finish(source, checks, "GRIFFIN PROPULSION REQUIREMENTS", "GRIFFIN_PROPULSION_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
