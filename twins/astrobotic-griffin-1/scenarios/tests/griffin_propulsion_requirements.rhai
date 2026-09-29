import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
// Standalone Griffin main-propulsion visual verification.  Thrust and
// collision remain owned by the flight model; this observer checks only the
// replaceable bell/throat presentation components.

const PACKAGE = "GriffinPropulsionRequirements";
const VERIFICATION = "Verify_GriffinPropulsionRequirements";

fn own(name) { PACKAGE + "::GriffinMainPropulsionAssembly::" + name }
fn skirt(name) { PACKAGE + "::GriffinEngineSkirtComponent::" + name }
fn parent(name) { "GriffinLanderRequirements::GriffinLanderComponent::" + name }
fn visual(name) { "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::" + name }

fn position(id, path, index, expected, tolerance) {
    #{id: id, component: "engine", requirement: "gpp005",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: tolerance}
}

fn component_position(id, path, index, expected, tolerance) {
    #{id: id, component: "engine_skirt", requirement: "ges003",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: tolerance}
}

fn attribute(id, requirement, path, attr, expected, tolerance) {
    #{id: id, component: "engine", requirement: requirement,
      verification: VERIFICATION, kind: "attribute", path: path,
      attr: attr, expected: expected, tolerance: tolerance}
}

fn absolute(value) { if value < 0.0 { -value } else { value } }

fn simulation_dependencies(me, ctx) {
    #{modelica_entities: [], entity_reads: [], entity_writes: [],
      query_reads: ["AnalyzeSysml", "QueryUsdPrim", "QueryUsdPrims"],
      required_inputs: []}
}

fn record_at(result, path) {
    if result == () || result.records == () { return (); }
    for record in result.records {
        if record.path == path { return record; }
    }
    ()
}

fn has_single_connection(record, input_name, expected_source) {
    if record == () || record.connections == () { return false; }
    let sources = record.connections[input_name];
    sources != () && array_is(sources) && sources.len() == 1
        && sources[0] == expected_source
}

fn has_single_relationship_target(record, relationship, expected_target) {
    if record == () || record.relationships == () { return false; }
    let targets = record.relationships[relationship];
    targets != () && array_is(targets) && targets.len() == 1
        && targets[0] == expected_target
}

fn _query_snapshot(result) {
    if result == () || result.records == () || result.records.len() == 0 {
        return #{ok: false, error: "USD observation returned no composed records"};
    }
    let first = result.records[0];
    if first.doc_id == () || first.document_generation == ()
        || first.stage_generation == () {
        return #{ok: false, error: "USD observation lacks document or stage provenance"};
    }
    for record in result.records {
        if record.doc_id != first.doc_id
            || record.document_generation != first.document_generation
            || record.stage_generation != first.stage_generation {
            return #{ok: false,
                error: "USD records span more than one composed document snapshot"};
        }
    }
    #{ok: true, doc_id: first.doc_id,
      document_generation: first.document_generation,
      stage_generation: first.stage_generation}
}

fn _same_snapshot(left, right) {
    left != () && right != () && left.ok == true && right.ok == true
        && left.doc_id == right.doc_id
        && left.document_generation == right.document_generation
        && left.stage_generation == right.stage_generation
}

fn _usd_observation(snapshot, available, value, detail) {
    if !available || snapshot == () || snapshot.ok != true {
        return #{provider: "usd", state: "unavailable", detail: detail};
    }
    #{provider: "usd", state: "value", value: value,
      doc_id: snapshot.doc_id,
      document_generation: snapshot.document_generation,
      stage_generation: snapshot.stage_generation}
}

fn _source_literal(model, qualified_name) {
    let attribute = model.attribute(qualified_name);
    if attribute == () {
        throw("Typed SysML source literal is missing: " + qualified_name);
    }
    model.source_literal_observation(attribute)
}

fn _required_constraint_bindings(model, requirement_name, constraint_name,
                                 inputs) {
    let requirement = model.requirement(PACKAGE + "::" + requirement_name);
    if requirement == () {
        throw("Typed SysML requirement is missing: " + requirement_name);
    }
    let ir = sysml_requirements::required_constraint_ir(model, requirement,
        PACKAGE + "::" + constraint_name);
    if ir == () || ir.ok != true {
        throw("Required SysML constraint is invalid: " + constraint_name
            + "; " + if ir == () { "no constraint IR" } else { ir.error });
    }
    let bindings = [];
    for input in inputs {
        let bound = sysml_requirements::scalar_constraint_observation(ir,
            input[0], input[1]);
        if bound == () || bound.state == "invalid" {
            throw("Could not bind typed observation for " + constraint_name
                + "::" + input[0] + "; "
                + if bound == () { "no observation" } else { bound.detail });
        }
        bindings.push(bound);
    }
    bindings
}

fn station_ring_is_centered_hexagon(stations, tolerance) {
    if stations.len() != 7 { return false; }
    if absolute(stations[0].x) > tolerance || absolute(stations[0].z) > tolerance {
        return false;
    }
    let radius = (stations[1].x * stations[1].x
        + stations[1].z * stations[1].z).sqrt();
    if radius <= tolerance { return false; }
    for index in 1..stations.len() {
        let station_radius = (stations[index].x * stations[index].x
            + stations[index].z * stations[index].z).sqrt();
        if absolute(station_radius - radius) > tolerance { return false; }
    }
    let chord = [radius, radius * (3.0).sqrt(), radius * 2.0];
    let counts = [0, 0, 0];
    for left in 1..stations.len() {
        for right in left + 1..stations.len() {
            let dx = stations[left].x - stations[right].x;
            let dz = stations[left].z - stations[right].z;
            let distance = (dx * dx + dz * dz).sqrt();
            let matched = if absolute(distance - chord[0]) <= tolerance { 0 }
                else if absolute(distance - chord[1]) <= tolerance { 1 }
                else if absolute(distance - chord[2]) <= tolerance { 2 }
                else { -1 };
            if matched < 0 { return false; }
            counts[matched] += 1;
        }
    }
    counts[0] == 6 && counts[1] == 6 && counts[2] == 3
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let selected_attributes = [];
    for name in ["usdRootPath", "bellRadiusM", "bellHeightM", "throatRadiusM",
        "throatHeightM", "throatCenterYM", "minimumBellClearanceM"] {
        selected_attributes.push(own(name));
    }
    for name in ["componentRootName", "componentMemberNames", "shellName",
        "adapterPlateName", "railFrontCenterZM", "railRearCenterZM",
        "railPortCenterXM", "railStarboardCenterXM", "railLengthM",
        "railWidthM", "railHeightM", "shellDepthM", "adapterPlateWidthM",
        "adapterPlateHeightM", "adapterPlateDepthM", "transformOrder"] {
        selected_attributes.push(skirt(name));
    }
    selected_attributes.push(parent("engineCount"));
    for name in ["engineClusterMountYM", "engineStations", "geometryVerificationToleranceM",
        "lowerBucketOuterBottomRadiusM", "mainEngineInstances"] {
        selected_attributes.push(visual(name));
    }
    let selected_requirements = [];
    for name in ["gpp001", "gpp002", "gpp003", "gpp004", "gpp005", "gpp006",
        "gpp007", "gpp008"] {
        selected_requirements.push(PACKAGE + "::" + name);
    }
    for name in ["ges001", "ges002", "ges003", "ges004", "ges005", "ges006", "ges007"] {
        selected_requirements.push(PACKAGE + "::" + name);
    }
    let source = sysml_requirements::source_with_selection(selected_attributes,
        selected_requirements, [PACKAGE + "::" + VERIFICATION]);
    if source.ok != true || source.path == () || source.path == "" {
        throw("Griffin propulsion SysML selection failed: " + source.to_string());
    }
    let source_model = sysml_requirements::model();
    if source_model == () || !sysml_model_is(source_model) {
        throw("Griffin propulsion typed SysML model is unavailable");
    }
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let nozzle_suffix = "/Nozzle/MainEngineCluster";
    if root.len() < nozzle_suffix.len()
        || root.sub_string(root.len() - nozzle_suffix.len(), root.len()) != nozzle_suffix {
        throw("Griffin propulsion USD root must end in /Nozzle/MainEngineCluster; source value was "
            + root.to_string());
    }
    let vehicle_root_end = root.len() - nozzle_suffix.len();
    let vehicle_root = root.sub_string(0, vehicle_root_end);
    let propulsion_path = vehicle_root + "/MainPropulsion";
    let nozzle_design_path = propulsion_path + "/NozzleDesign";
    let photometry_path = propulsion_path + "/PlumePhotometry";
    let bell_radius = sysml_requirements::number(source, own("bellRadiusM"));
    let bell_height = sysml_requirements::number(source, own("bellHeightM"));
    let throat_radius = sysml_requirements::number(source, own("throatRadiusM"));
    let throat_height = sysml_requirements::number(source, own("throatHeightM"));
    let names = sysml_requirement_checks::source_enum_identifiers(source, visual("mainEngineInstances"));
    let stations = sysml_requirement_checks::source_position_list(source, visual("engineStations"));
    let geometry_tolerance = sysml_requirements::number(source, visual("geometryVerificationToleranceM"));
    let required_clearance = sysml_requirements::number(source, own("minimumBellClearanceM"));
    let bucket_outer_radius = sysml_requirements::number(source, visual("lowerBucketOuterBottomRadiusM"));
    let skirt_root = root + "/" + sysml_requirements::text(source, skirt("componentRootName"));
    let skirt_names = sysml_requirement_checks::source_text_list(source, skirt("componentMemberNames"));
    let skirt_shell = skirt_root + "/" + sysml_requirements::text(source, skirt("shellName"));
    let skirt_width = sysml_requirements::number(source, skirt("railLengthM"));
    let skirt_depth = skirt_width;
    let skirt_height = sysml_requirements::number(source, skirt("railHeightM"));
    let skirt_section = sysml_requirements::number(source, skirt("railWidthM"));
    let skirt_shell_depth = sysml_requirements::number(source, skirt("shellDepthM"));
    let skirt_assembly_y = sysml_requirements::number(source, visual("engineClusterMountYM"));
    let adapter_name = sysml_requirements::text(source, skirt("adapterPlateName"));
    let adapter_width = sysml_requirements::number(source, skirt("adapterPlateWidthM"));
    let adapter_depth = sysml_requirements::number(source, skirt("adapterPlateDepthM"));
    let adapter_height = sysml_requirements::number(source, skirt("adapterPlateHeightM"));
    let skirt_transform_order = sysml_requirements::string_vector(source, skirt("transformOrder"));
    let skirt_transform_order = if skirt_transform_order == () { [] } else { skirt_transform_order };
    let checks = [];
    checks.push(sysml_requirement_checks::source_list_count("GPP-001-count", "propulsion", "gpp001", VERIFICATION, visual("mainEngineInstances"), parent("engineCount")));
    checks.push(sysml_requirement_checks::source_list_count("GPP-005-stations", "engine", "gpp005", VERIFICATION, visual("engineStations"), parent("engineCount")));
    checks.push(attribute("GPP-001-photometry-engine-count", "gpp001",
        photometry_path, "inputs:engine_count",
        names.len(), 0.0));
    checks.push(attribute("GPP-006-nozzle-design-exit-radius", "gpp006",
        nozzle_design_path, "inputs:exit_radius",
        bell_radius, geometry_tolerance));
    checks.push(attribute("GPP-006-nozzle-design-throat-radius", "gpp006",
        nozzle_design_path, "inputs:throat_radius",
        throat_radius, geometry_tolerance));
    checks.push(attribute("GPP-006-nozzle-design-length", "gpp006",
        nozzle_design_path, "inputs:length",
        bell_height, geometry_tolerance));
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        checks.push(sysml_requirement_checks::exists("GPP-001-" + name, "engine", "gpp001", VERIFICATION, path, "Xform"));
        checks.push(#{id: "GPP-005-" + name + "-translate-order", component: "engine",
            requirement: "gpp005", verification: VERIFICATION, kind: "attribute_equals",
            path: path, attr: "xformOpOrder", expected: ["xformOp:translate"]});
        checks.push(sysml_requirement_checks::children("GPP-002-" + name, "engine", "gpp002", VERIFICATION, path,
            [path + "/Bell", path + "/Throat"]));
        checks.push(sysml_requirement_checks::attribute_equals("GPP-002-" + name + "-purpose", "engine", "gpp002", VERIFICATION,
            path + "/Bell", "purpose", "render"));
        if bell_radius != () && bell_height != () && throat_radius != () && throat_height != () {
            checks.push(attribute("GPP-006-" + name + "-bell-radius", "gpp006", path + "/Bell", "radius", bell_radius, geometry_tolerance));
            checks.push(attribute("GPP-006-" + name + "-bell-height", "gpp006", path + "/Bell", "height", bell_height, geometry_tolerance));
            checks.push(attribute("GPP-006-" + name + "-throat-radius", "gpp006", path + "/Throat", "radius", throat_radius, geometry_tolerance));
            checks.push(attribute("GPP-006-" + name + "-throat-height", "gpp006", path + "/Throat", "height", throat_height, geometry_tolerance));
            checks.push(sysml_requirement_checks::attribute_equals("GPP-006-" + name + "-bell-axis", "engine", "gpp006", VERIFICATION,
                path + "/Bell", "axis", "Y"));
            checks.push(#{id: "GPP-006-" + name + "-throat-center", component: "engine",
                requirement: "gpp006", verification: VERIFICATION, kind: "attribute_component",
                path: path + "/Throat", attr: "xformOp:translate", index: 1,
                expected_attr: own("throatCenterYM"), tolerance: geometry_tolerance});
        }
        if stations.len() == names.len() {
            checks.push(position("GPP-005-" + name + "-x", path, 0, stations[index].x, geometry_tolerance));
            checks.push(position("GPP-005-" + name + "-y", path, 1, stations[index].y, geometry_tolerance));
            checks.push(position("GPP-005-" + name + "-z", path, 2, stations[index].z, geometry_tolerance));
        }
    }
    let engine_paths = [];
    for name in names { engine_paths.push(root + "/" + name); }
    let observed_engines = query("QueryUsdPrims", #{paths: engine_paths,
        attrs: ["xformOp:translate", "xformOpOrder"], geometry_bounds: true,
        connections: true});
    let plume_paths = [];
    let light_paths = [];
    for path in engine_paths {
        plume_paths.push(path + "/Flame");
        plume_paths.push(path + "/FlameCore");
        light_paths.push(path + "/FlameCore/PlumeLight");
    }
    let observed_plumes = query("QueryUsdPrims", #{paths: plume_paths,
        attrs: ["purpose", "physics:collisionEnabled"],
        relationships: true, connections: true});
    let observed_lights = query("QueryUsdPrims", #{paths: light_paths,
        connections: true});
    let observed_photometry = query("QueryUsdPrims", #{
        paths: [photometry_path], connections: true});
    let snapshots = [
        _query_snapshot(observed_engines),
        _query_snapshot(observed_plumes),
        _query_snapshot(observed_lights),
        _query_snapshot(observed_photometry)
    ];
    let usd_snapshot = ();
    let usd_snapshots_match = true;
    for snapshot in snapshots {
        if snapshot.ok != true {
            usd_snapshots_match = false;
        } else if usd_snapshot == () {
            usd_snapshot = snapshot;
        } else if !_same_snapshot(usd_snapshot, snapshot) {
            usd_snapshots_match = false;
        }
    }
    let plume_engine_count = 0;
    let plume_connections_match = true;
    let plume_materials_match = true;
    let plume_geometry_is_render_only = true;
    let plume_observations_available = usd_snapshots_match
        && observed_engines.records != ()
        && observed_engines.records.len() == engine_paths.len()
        && observed_plumes.records != ()
        && observed_plumes.records.len() == plume_paths.len()
        && observed_lights.records != ()
        && observed_lights.records.len() == light_paths.len()
        && record_at(observed_photometry, photometry_path) != ();
    if plume_observations_available {
        for index in 0..engine_paths.len() {
            let engine_path = engine_paths[index];
            let engine_record = record_at(observed_engines, engine_path);
            let flame_path = engine_path + "/Flame";
            let core_path = engine_path + "/FlameCore";
            let flame = record_at(observed_plumes, flame_path);
            let core = record_at(observed_plumes, core_path);
            let light = record_at(observed_lights, core_path + "/PlumeLight");
            let has_pair = flame != () && core != () && light != ();
            if has_pair { plume_engine_count += 1; }
            let model_source = photometry_path + ".outputs:";
            plume_connections_match = plume_connections_match
                && has_single_connection(flame, "inputs:throttle",
                    model_source + "render_throttle")
                && has_single_connection(flame, "inputs:plume_length_fraction",
                    model_source + "visual_length_fraction")
                && has_single_connection(core, "inputs:throttle",
                    model_source + "render_throttle")
                && has_single_connection(core, "inputs:plume_length_fraction",
                    model_source + "visual_length_fraction")
                && has_single_connection(light, "inputs:light_intensity",
                    model_source + "intensity")
                && has_single_connection(light, "inputs:light_radius",
                    model_source + "radius");
            if has_pair {
                plume_materials_match = plume_materials_match
                    && has_single_relationship_target(flame, "material:binding",
                        vehicle_root + "/Looks/Flame_Mat")
                    && has_single_relationship_target(core, "material:binding",
                        vehicle_root + "/Looks/FlameCore_Mat");
                plume_geometry_is_render_only = plume_geometry_is_render_only
                    && flame.attrs["purpose"] == "render"
                    && flame.attrs["physics:collisionEnabled"] == false
                    && core.attrs["purpose"] == "render"
                    && core.attrs["physics:collisionEnabled"] == false;
            } else {
                plume_geometry_is_render_only = false;
            }
        }
    }
    let photometry_record = record_at(observed_photometry,
        photometry_path);
    let photometry_consumes_engine_state = plume_observations_available
        && has_single_connection(photometry_record, "inputs:throttle",
            propulsion_path + ".outputs:engine_activity")
        && has_single_connection(photometry_record, "inputs:thrust_n",
            propulsion_path + ".outputs:thrust_n")
        && has_single_connection(photometry_record, "inputs:maximum_thrust_n",
            propulsion_path + ".outputs:maximum_thrust_n")
        && has_single_connection(photometry_record, "inputs:propellant_flow_kgs",
            propulsion_path + ".outputs:propellant_flow")
        && has_single_connection(photometry_record, "inputs:exhaust_velocity_mps",
            propulsion_path + ".outputs:exhaust_velocity_mps")
        && has_single_connection(photometry_record, "inputs:design_exhaust_velocity_mps",
            propulsion_path + ".outputs:design_exhaust_velocity_mps")
        && has_single_connection(photometry_record, "inputs:nozzle_exit_radius_m",
            nozzle_design_path + ".outputs:exit_radius_m")
        && has_single_connection(photometry_record, "inputs:nozzle_exit_area_m2",
            nozzle_design_path + ".outputs:exit_area")
        && has_single_connection(photometry_record, "inputs:chamber_pressure_pa",
            propulsion_path + ".outputs:chamber_pressure_pa");
    let plume_requirement_bindings = _required_constraint_bindings(source_model,
        "gpp008", "GPPC008_EnginePlumeDataflow", [
            ["engineCount", _source_literal(source_model, parent("engineCount"))],
            ["plumeEngineCount", _usd_observation(usd_snapshot,
                plume_observations_available, plume_engine_count,
                "composed nozzle plume geometry is unavailable")],
            ["photometryConsumesEngineState", _usd_observation(usd_snapshot,
                plume_observations_available, photometry_consumes_engine_state,
                "composed photometry connections are unavailable")],
            ["everyNozzleUsesPhotometry", _usd_observation(usd_snapshot,
                plume_observations_available, plume_connections_match,
                "composed per-nozzle plume connections are unavailable")],
            ["everyNozzleHasBoundPlumeMaterials", _usd_observation(usd_snapshot,
                plume_observations_available, plume_materials_match,
                "composed plume material bindings are unavailable")],
            ["plumeGeometryIsRenderOnly", _usd_observation(usd_snapshot,
                plume_observations_available, plume_geometry_is_render_only,
                "composed plume geometry roles are unavailable")]
        ]);
    checks.push(sysml_requirements::required_constraint_check("GPP-008-engine-plume-dataflow",
        "engine", "gpp008", VERIFICATION,
        "GriffinPropulsionRequirements::GPPC008_EnginePlumeDataflow",
        plume_requirement_bindings,
        "typed", 0.0));
    let actual_stations = [];
    let measurement_available = observed_engines.records != ()
        && observed_engines.records.len() == names.len()
        && names.len() == 7 && stations.len() == names.len()
        && bell_radius != () && required_clearance != ()
        && bucket_outer_radius != () && geometry_tolerance != ()
        && usd_snapshots_match && usd_snapshot != ()
        && usd_snapshot.ok == true;
    if measurement_available {
        for record in observed_engines.records {
            // Source stations are expressed in the engine-cluster frame.
            // Use the composed local placement, not live world position,
            // which moves with the lander's rigid body during this fixture.
            let placement = record.attrs["xformOp:translate"];
            if placement == () || placement.len() != 3 {
                measurement_available = false;
            } else {
                actual_stations.push(vec3(placement[0], placement[1],
                    placement[2]));
            }
        }
    }
    let measured_clearance = 0.0;
    let maximum_radial_extent = 0.0;
    let typed_stations_match = true;
    if measurement_available && actual_stations.len() == stations.len() {
        measured_clearance = 1.0e30;
        for index in 0..actual_stations.len() {
            let actual = actual_stations[index];
            let expected = stations[index];
            if (actual.x - expected.x).abs() > geometry_tolerance
                || (actual.y - expected.y).abs() > geometry_tolerance
                || (actual.z - expected.z).abs() > geometry_tolerance {
                typed_stations_match = false;
            }
            let radial_extent = (actual.x * actual.x
                + actual.z * actual.z).sqrt() + bell_radius;
            if radial_extent > maximum_radial_extent {
                maximum_radial_extent = radial_extent;
            }
            for other in index + 1..actual_stations.len() {
                let dx = actual.x - actual_stations[other].x;
                let dz = actual.z - actual_stations[other].z;
                let clearance = (dx * dx + dz * dz).sqrt() - 2.0 * bell_radius;
                if clearance < measured_clearance { measured_clearance = clearance; }
            }
        }
        typed_stations_match = station_ring_is_centered_hexagon(stations,
            geometry_tolerance)
            && station_ring_is_centered_hexagon(actual_stations,
                geometry_tolerance)
            && typed_stations_match;
    }
    let separation_requirement_bindings = _required_constraint_bindings(source_model,
        "gpp007", "GPPC007_BellSeparation", [
            ["measuredMinimumClearanceM", _usd_observation(usd_snapshot,
                measurement_available, measured_clearance,
                "composed engine station readback unavailable")],
            ["requiredMinimumClearanceM",
                _source_literal(source_model, own("minimumBellClearanceM"))],
            ["maximumRadialExtentM", _usd_observation(usd_snapshot,
                measurement_available, maximum_radial_extent,
                "composed engine station readback unavailable")],
            ["bucketOuterRadiusM", _source_literal(source_model,
                visual("lowerBucketOuterBottomRadiusM"))],
            ["typedStationsMatch", _usd_observation(usd_snapshot,
                measurement_available, typed_stations_match,
                "typed engine stations are unavailable")]
        ]);
    checks.push(sysml_requirements::required_constraint_check("GPP-007-bell-separation",
        "engine", "gpp007", VERIFICATION,
        "GriffinPropulsionRequirements::GPPC007_BellSeparation",
        separation_requirement_bindings,
        "typed", 0.0));
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
        checks.push(sysml_requirement_checks::exists("GES-001-component", "engine_skirt", "ges001", VERIFICATION, skirt_root, "Xform"));
        checks.push(sysml_requirement_checks::children("GES-001-rails", "engine_skirt", "ges001", VERIFICATION, skirt_root, rail_paths));
        checks.push(component_position("GES-003-assembly-y", skirt_root, 1, skirt_assembly_y, geometry_tolerance));
        for index in 0..skirt_names.len() {
            let rail = rail_paths[index];
            checks.push(sysml_requirement_checks::exists("GES-001-" + skirt_names[index], "engine_skirt", "ges001", VERIFICATION, rail, "Cube"));
            checks.push(sysml_requirement_checks::attribute_equals("GES-005-" + skirt_names[index] + "-purpose", "engine_skirt", "ges005", VERIFICATION, rail, "purpose", "render"));
            checks.push(sysml_requirement_checks::attribute_equals("GES-005-" + skirt_names[index] + "-collision", "engine_skirt", "ges005", VERIFICATION, rail, "physics:collisionEnabled", false));
            checks.push(sysml_requirement_checks::attribute_equals("GES-005-" + skirt_names[index] + "-order", "engine_skirt", "ges005", VERIFICATION, rail, "xformOpOrder", skirt_transform_order));
            if index < 2 {
                checks.push(sysml_requirement_checks::extent_component("GES-006-" + skirt_names[index] + "-length", "engine_skirt", "ges006", VERIFICATION, rail, 0, skirt("railLengthM"), 1.0, geometry_tolerance));
                checks.push(sysml_requirement_checks::extent_component("GES-006-" + skirt_names[index] + "-height", "engine_skirt", "ges006", VERIFICATION, rail, 1, skirt("railHeightM"), 1.0, geometry_tolerance));
                checks.push(sysml_requirement_checks::extent_component("GES-006-" + skirt_names[index] + "-width", "engine_skirt", "ges006", VERIFICATION, rail, 2, skirt("railWidthM"), 1.0, geometry_tolerance));
                checks.push(component_position("GES-006-" + skirt_names[index] + "-z", rail, 2, if index == 0 { sysml_requirements::number(source, skirt("railFrontCenterZM")) } else { sysml_requirements::number(source, skirt("railRearCenterZM")) }, geometry_tolerance));
            } else {
                checks.push(sysml_requirement_checks::extent_component("GES-006-" + skirt_names[index] + "-length", "engine_skirt", "ges006", VERIFICATION, rail, 2, skirt("railLengthM"), 1.0, geometry_tolerance));
                checks.push(sysml_requirement_checks::extent_component("GES-006-" + skirt_names[index] + "-height", "engine_skirt", "ges006", VERIFICATION, rail, 1, skirt("railHeightM"), 1.0, geometry_tolerance));
                checks.push(sysml_requirement_checks::extent_component("GES-006-" + skirt_names[index] + "-width", "engine_skirt", "ges006", VERIFICATION, rail, 0, skirt("railWidthM"), 1.0, geometry_tolerance));
                checks.push(component_position("GES-006-" + skirt_names[index] + "-x", rail, 0, if index == 2 { sysml_requirements::number(source, skirt("railPortCenterXM")) } else { sysml_requirements::number(source, skirt("railStarboardCenterXM")) }, geometry_tolerance));
            }
        }
        checks.push(sysml_requirement_checks::exists("GES-002-shell", "engine_skirt", "ges002", VERIFICATION, skirt_shell, "Mesh"));
        checks.push(sysml_requirement_checks::bounds_component("GES-007-shell-width", "engine_skirt", "ges007", VERIFICATION, skirt_shell, 0, skirt("railLengthM"), 2.0, geometry_tolerance));
        checks.push(sysml_requirement_checks::bounds_component("GES-007-shell-depth-y", "engine_skirt", "ges007", VERIFICATION, skirt_shell, 1, skirt("shellDepthM"), 2.0, geometry_tolerance));
        checks.push(sysml_requirement_checks::bounds_component("GES-007-shell-envelope-depth", "engine_skirt", "ges007", VERIFICATION, skirt_shell, 2, skirt("railLengthM"), 2.0, geometry_tolerance));
        let adapter_path = skirt_root + "/" + adapter_name;
        checks.push(sysml_requirement_checks::exists("GES-007-adapter-plate", "engine_skirt", "ges007", VERIFICATION, adapter_path, "Cube"));
        checks.push(sysml_requirement_checks::extent_component("GES-007-adapter-width", "engine_skirt", "ges007", VERIFICATION, adapter_path, 0, skirt("adapterPlateWidthM"), 1.0, geometry_tolerance));
        checks.push(sysml_requirement_checks::extent_component("GES-007-adapter-height", "engine_skirt", "ges007", VERIFICATION, adapter_path, 1, skirt("adapterPlateHeightM"), 1.0, geometry_tolerance));
        checks.push(sysml_requirement_checks::extent_component("GES-007-adapter-depth", "engine_skirt", "ges007", VERIFICATION, adapter_path, 2, skirt("adapterPlateDepthM"), 1.0, geometry_tolerance));
        checks.push(sysml_requirement_checks::attribute_equals("GES-005-adapter-purpose", "engine_skirt", "ges005", VERIFICATION, adapter_path, "purpose", "render"));
        checks.push(sysml_requirement_checks::attribute_equals("GES-005-adapter-collision", "engine_skirt", "ges005", VERIFICATION, adapter_path, "physics:collisionEnabled", false));
        checks.push(sysml_requirement_checks::attribute_equals("GES-005-shell-purpose", "engine_skirt", "ges005", VERIFICATION, skirt_shell, "purpose", "render"));
        checks.push(sysml_requirement_checks::attribute_equals("GES-005-shell-collision", "engine_skirt", "ges005", VERIFICATION, skirt_shell, "physics:collisionEnabled", false));
        checks.push(sysml_requirement_checks::coverage("GES-004-clearance", "engine_skirt", "ges004", VERIFICATION));
        checks.push(sysml_requirement_checks::coverage("GES-002-envelope", "engine_skirt", "ges002", VERIFICATION));
    } else {
        checks.push(sysml_requirement_checks::coverage("GES-001-source", "engine_skirt", "ges001", VERIFICATION));
    }
    checks.push(sysml_requirement_checks::coverage("GPP-003-ownership", "propulsion", "gpp003", VERIFICATION));
    checks.push(sysml_requirement_checks::coverage("GPP-004-traceability", "propulsion", "gpp004", VERIFICATION));
    sysml_requirement_checks::finish(source, checks, "GRIFFIN PROPULSION REQUIREMENTS", "GRIFFIN_PROPULSION_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
