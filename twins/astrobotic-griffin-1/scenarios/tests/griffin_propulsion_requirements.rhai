// Standalone Griffin main-propulsion visual verification.  Thrust and
// collision remain owned by the flight model; this observer checks only the
// replaceable bell/throat presentation components.

const PACKAGE = "GriffinPropulsionRequirements";
const VERIFICATION = "GriffinPropulsionRequirements::Verify_GriffinPropulsionRequirements";

fn own(name) { PACKAGE + "::GriffinMainPropulsionAssembly::" + name }
fn skirt(name) { PACKAGE + "::GriffinEngineSkirtComponent::" + name }
fn parent(name) { "GriffinLanderRequirements::GriffinLanderComponent::" + name }

fn position(id, path, index, expected) {
    #{id: id, component: "engine", requirement: "GriffinPropulsionRequirements::gpp005",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: 0.002}
}

fn component_position(id, path, index, expected) {
    #{id: id, component: "engine_skirt", requirement: "GriffinPropulsionRequirements::ges003",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: 0.002}
}

fn attribute(id, requirement, path, attr, expected) {
    #{id: id, component: "engine", requirement: requirement,
      verification: VERIFICATION, kind: "attribute", path: path,
      attr: attr, expected: expected, tolerance: 0.002}
}

fn on_start(me) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let names_source = sysml_requirements::text(source, own("namesSource"));
    let count_source = sysml_requirements::text(source, own("countSource"));
    let bell_radius = sysml_requirements::number(source, own("bellRadiusM"));
    let bell_height = sysml_requirements::number(source, own("bellHeightM"));
    let throat_radius = sysml_requirements::number(source, own("throatRadiusM"));
    let throat_height = sysml_requirements::number(source, own("throatHeightM"));
    let names = component_requirements::source_text_list(source, names_source);
    let xs = component_requirements::source_number_list(source, parent("engineStationX"));
    let ys = component_requirements::source_number_list(source, parent("engineStationY"));
    let zs = component_requirements::source_number_list(source, parent("engineStationZ"));
    let skirt_root = root + "/" + sysml_requirements::text(source, skirt("componentRootName"));
    let skirt_names = component_requirements::source_text_list(source, skirt("componentMemberNames"));
    let skirt_shell = skirt_root + "/" + sysml_requirements::text(source, skirt("shellName"));
    let skirt_width = sysml_requirements::number(source, parent("engineClusterWidthM"));
    let skirt_depth = sysml_requirements::number(source, parent("engineClusterDepthM"));
    let skirt_height = sysml_requirements::number(source, parent("engineSkirtHeightM"));
    let skirt_section = sysml_requirements::number(source, parent("engineSkirtRailSectionM"));
    let skirt_mount_y = sysml_requirements::number(source, parent("engineMountYM"));
    let skirt_transform_order_text = sysml_requirements::text(source, skirt("transformOrder"));
    let skirt_transform_order = if skirt_transform_order_text == () || skirt_transform_order_text == "" { [] } else { skirt_transform_order_text.split(",") };
    let checks = [];
    checks.push(component_requirements::source_list_count("GPP-001-count", "propulsion", "GriffinPropulsionRequirements::gpp001", VERIFICATION, names_source, count_source));
    for axis in ["engineStationX", "engineStationY", "engineStationZ"] {
        checks.push(component_requirements::source_list_count("GPP-005-" + axis,
            "engine", "GriffinPropulsionRequirements::gpp005", VERIFICATION,
            parent(axis), count_source));
    }
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        checks.push(component_requirements::exists("GPP-001-" + name, "engine", "GriffinPropulsionRequirements::gpp001", VERIFICATION, path, "Xform"));
        checks.push(component_requirements::children("GPP-002-" + name, "engine", "GriffinPropulsionRequirements::gpp002", VERIFICATION, path,
            [path + "/Bell", path + "/Throat"]));
        checks.push(component_requirements::attribute_equals("GPP-002-" + name + "-purpose", "engine", "GriffinPropulsionRequirements::gpp002", VERIFICATION,
            path + "/Bell", "purpose", "render"));
        if bell_radius != () && bell_height != () && throat_radius != () && throat_height != () {
            checks.push(attribute("GPP-002-" + name + "-bell-radius", "GriffinPropulsionRequirements::gpp002", path + "/Bell", "radius", bell_radius));
            checks.push(attribute("GPP-002-" + name + "-bell-height", "GriffinPropulsionRequirements::gpp002", path + "/Bell", "height", bell_height));
            checks.push(attribute("GPP-002-" + name + "-throat-radius", "GriffinPropulsionRequirements::gpp002", path + "/Throat", "radius", throat_radius));
            checks.push(attribute("GPP-002-" + name + "-throat-height", "GriffinPropulsionRequirements::gpp002", path + "/Throat", "height", throat_height));
        }
        if xs.len() == names.len() && ys.len() == names.len() && zs.len() == names.len() {
            checks.push(position("GPP-005-" + name + "-x", path, 0, xs[index]));
            checks.push(position("GPP-005-" + name + "-y", path, 1, ys[index]));
            checks.push(position("GPP-005-" + name + "-z", path, 2, zs[index]));
        }
    }
    // The skirt is a separate referenced component.  Validate its four rails
    // and shell in the composed assembly; the source file remains the only
    // owner of the component geometry.
    if skirt_names.len() == 4 && skirt_width != () && skirt_depth != ()
        && skirt_height != () && skirt_section != () && skirt_mount_y != ()
        && skirt_transform_order.len() == 2 {
        let rail_paths = [];
        for name in skirt_names { rail_paths.push(skirt_root + "/" + name); }
        checks.push(component_requirements::exists("GES-001-component", "engine_skirt", "GriffinPropulsionRequirements::ges001", VERIFICATION, skirt_root, "Xform"));
        checks.push(component_requirements::children("GES-001-rails", "engine_skirt", "GriffinPropulsionRequirements::ges001", VERIFICATION, skirt_root, rail_paths));
        for index in 0..skirt_names.len() {
            let rail = rail_paths[index];
            checks.push(component_requirements::exists("GES-001-" + skirt_names[index], "engine_skirt", "GriffinPropulsionRequirements::ges001", VERIFICATION, rail, "Cube"));
            checks.push(component_requirements::attribute_equals("GES-005-" + skirt_names[index] + "-purpose", "engine_skirt", "GriffinPropulsionRequirements::ges005", VERIFICATION, rail, "purpose", "render"));
            checks.push(component_requirements::attribute_equals("GES-005-" + skirt_names[index] + "-collision", "engine_skirt", "GriffinPropulsionRequirements::ges005", VERIFICATION, rail, "physics:collisionEnabled", false));
            checks.push(component_requirements::attribute_equals("GES-005-" + skirt_names[index] + "-order", "engine_skirt", "GriffinPropulsionRequirements::ges005", VERIFICATION, rail, "xformOpOrder", skirt_transform_order));
            if index < 2 {
                checks.push(component_requirements::extent_component("GES-002-" + skirt_names[index] + "-width", "engine_skirt", "GriffinPropulsionRequirements::ges002", VERIFICATION, rail, 0, parent("engineClusterWidthM"), 2.0, 0.002));
                checks.push(component_requirements::extent_component("GES-002-" + skirt_names[index] + "-height", "engine_skirt", "GriffinPropulsionRequirements::ges002", VERIFICATION, rail, 1, parent("engineSkirtHeightM"), 2.0, 0.002));
                checks.push(component_position("GES-003-" + skirt_names[index] + "-z", rail, 2, if index == 0 { skirt_depth / 2.0 - skirt_section / 2.0 } else { -(skirt_depth / 2.0 - skirt_section / 2.0) }));
            } else {
                checks.push(component_requirements::extent_component("GES-002-" + skirt_names[index] + "-depth", "engine_skirt", "GriffinPropulsionRequirements::ges002", VERIFICATION, rail, 2, parent("engineClusterDepthM"), 2.0, 0.002));
                checks.push(component_requirements::extent_component("GES-002-" + skirt_names[index] + "-height", "engine_skirt", "GriffinPropulsionRequirements::ges002", VERIFICATION, rail, 1, parent("engineSkirtHeightM"), 2.0, 0.002));
                checks.push(component_position("GES-003-" + skirt_names[index] + "-x", rail, 0, if index == 2 { skirt_width / 2.0 - skirt_section / 2.0 } else { -(skirt_width / 2.0 - skirt_section / 2.0) }));
            }
        }
        checks.push(component_requirements::exists("GES-002-shell", "engine_skirt", "GriffinPropulsionRequirements::ges002", VERIFICATION, skirt_shell, "Mesh"));
        checks.push(component_requirements::bounds_component("GES-002-shell-width", "engine_skirt", "GriffinPropulsionRequirements::ges002", VERIFICATION, skirt_shell, 0, parent("engineClusterWidthM"), 2.0, 0.002));
        checks.push(component_requirements::bounds_component("GES-002-shell-height", "engine_skirt", "GriffinPropulsionRequirements::ges002", VERIFICATION, skirt_shell, 1, parent("engineSkirtHeightM"), 2.0, 0.002));
        checks.push(component_requirements::bounds_component("GES-002-shell-depth", "engine_skirt", "GriffinPropulsionRequirements::ges002", VERIFICATION, skirt_shell, 2, parent("engineClusterDepthM"), 2.0, 0.002));
        checks.push(component_requirements::attribute_equals("GES-005-shell-purpose", "engine_skirt", "GriffinPropulsionRequirements::ges005", VERIFICATION, skirt_shell, "purpose", "render"));
        checks.push(component_requirements::attribute_equals("GES-005-shell-collision", "engine_skirt", "GriffinPropulsionRequirements::ges005", VERIFICATION, skirt_shell, "physics:collisionEnabled", false));
        checks.push(component_requirements::coverage("GES-004-clearance", "engine_skirt", "GriffinPropulsionRequirements::ges004", VERIFICATION));
    } else {
        checks.push(component_requirements::coverage("GES-001-source", "engine_skirt", "GriffinPropulsionRequirements::ges001", VERIFICATION));
    }
    checks.push(component_requirements::coverage("GPP-003-ownership", "propulsion", "GriffinPropulsionRequirements::gpp003", VERIFICATION));
    checks.push(component_requirements::coverage("GPP-004-traceability", "propulsion", "GriffinPropulsionRequirements::gpp004", VERIFICATION));
    component_requirements::finish(source, checks, "GRIFFIN PROPULSION REQUIREMENTS", "GRIFFIN_PROPULSION_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
