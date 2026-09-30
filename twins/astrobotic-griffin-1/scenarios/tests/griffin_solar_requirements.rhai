import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
import "twin://astrobotic-griffin-1/tools/usd_geometry_inspection.rhai" as usd_geometry_inspection;
// Standalone Griffin solar-array component verification. Mission placement
// remains inconclusive until the controlled installation datums are available.

const PACKAGE = "GriffinSolarRequirements";
const VERIFICATION = "Verify_GriffinSolarRequirements";
const PI = 3.141592653589793;

fn simulation_dependencies(me, ctx) { usd_geometry_inspection::dependencies() }

fn own(name) { PACKAGE + "::GriffinSolarArrayAssembly::" + name }
fn visual(name) { "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::" + name }

fn position(id, path, index, expected, tolerance) {
    #{id: id, component: "solar_array", requirement: "gsa005",
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: tolerance}
}

fn component_position(id, requirement, path, index, expected, tolerance) {
    #{id: id, component: "solar_array", requirement: requirement,
      verification: VERIFICATION, kind: "attribute_component", path: path,
      attr: "xformOp:translate", index: index, expected: expected, tolerance: tolerance}
}

fn bounds_overlap_depth(left, right) {
    if left == () || right == () || left.min == () || right.min == ()
        || left.max == () || right.max == () { return (); }
    let depth = [];
    for axis in 0..3 {
        let lower = if left.min[axis] > right.min[axis] { left.min[axis] } else { right.min[axis] };
        let upper = if left.max[axis] < right.max[axis] { left.max[axis] } else { right.max[axis] };
        if upper < lower { return 0.0; }
        depth.push(upper - lower);
    }
    let result = depth[0];
    if depth[1] < result { result = depth[1]; }
    if depth[2] < result { result = depth[2]; }
    result
}

fn minimum(left, right) { if left < right { left } else { right } }

fn point_bounds(points) {
    if points == () || points.len() == 0 { return (); }
    let minimum_point = [points[0][0], points[0][1], points[0][2]];
    let maximum_point = [points[0][0], points[0][1], points[0][2]];
    for point in points {
        if point == () || point.len() < 3 { return (); }
        for axis in 0..3 {
            if point[axis] < minimum_point[axis] { minimum_point[axis] = point[axis]; }
            if point[axis] > maximum_point[axis] { maximum_point[axis] = point[axis]; }
        }
    }
    let extent = [];
    let center = [];
    for axis in 0..3 {
        extent.push(maximum_point[axis] - minimum_point[axis]);
        center.push((maximum_point[axis] + minimum_point[axis]) / 2.0);
    }
    #{minimum: minimum_point, maximum: maximum_point, extent: extent, center: center}
}

fn mesh_measurement(records, path, axis, quantity) {
    let record = records[path];
    let bounds = if record == () || record.attrs == () { () }
        else { point_bounds(record.attrs["points"]) };
    if bounds == () {
        return #{provider: "usd", state: "unavailable",
            detail: "composed Mesh points unavailable at " + path};
    }
    let value = if quantity == "center" { bounds.center[axis] }
        else { bounds.extent[axis] };
    usd_geometry_inspection::measurement(value, record, "mesh measurement lacks snapshot identity")
}

fn mesh_geometry(records, path) {
    let record = records[path];
    if record == () || record.attrs == () { return (); }
    point_bounds(record.attrs["points"])
}

fn composed_attribute(records, path, name) {
    let record = records[path];
    if record == () || record.attrs == () { return (); }
    record.attrs[name]
}

fn source_observation(model, name) {
    let attribute = model.attribute(name);
    if attribute == () {
        return #{path: [], provider: "source_literal", state: "invalid",
            detail: "typed SysML attribute is missing: " + name};
    }
    model.source_literal_observation(attribute)
}

fn derived_measurement(value, detail, model) {
    if value == () {
        return #{provider: "derived", state: "unavailable", detail: detail};
    }
    #{provider: "derived", state: "value", value: value,
        provider_generation: model.source_revision, source_revision: model.source_revision,
        document_id: (), document_generation: ()}
}

fn panel_local_rail(rail, bus_mount, station, rotation_z_deg) {
    let alpha = rotation_z_deg * PI / 180.0;
    let cosine = cos(alpha);
    let sine = sin(alpha);
    let dx = rail.x + bus_mount.x - station.x;
    let dy = rail.y + bus_mount.y - station.y;
    let dz = rail.z + bus_mount.z - station.z;
    #{x: cosine * dx + sine * dz,
      y: -sine * dx + cosine * dz,
      z: -dy}
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let source = sysml_requirements::source();
    let model = sysml_requirements::model();
    let gsa005 = model.requirement(PACKAGE + "::gsa005");
    let gsa006 = model.requirement(PACKAGE + "::gsa006");
    let gsa009 = model.requirement(PACKAGE + "::gsa009");
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let geometry_tolerance = sysml_requirements::number(source, visual("geometryVerificationToleranceM"));
    let names = sysml_requirement_checks::source_enum_identifiers(source, visual("solarArrayInstances"));
    let stations = sysml_requirement_checks::source_position_list(source, visual("solarStations"));
    let members = sysml_requirement_checks::source_enum_identifiers(source, own("childNames"));
    let count = "GriffinLanderRequirements::GriffinLanderComponent::solarArrayCount";
    let rotx = sysml_requirement_checks::source_number_list(source, visual("solarStationRotationXDeg"));
    let rotz = sysml_requirement_checks::source_number_list(source, visual("solarStationRotationZDeg"));
    let rail_names = sysml_requirement_checks::source_enum_identifiers(source, visual("frameRails"));
    let rail_stations = sysml_requirement_checks::source_position_list(source, visual("railStations"));
    let mount_rails = sysml_requirement_checks::source_enum_identifiers(source, visual("solarMountRails"));
    let bus_mount = sysml_requirements::native_value(source, visual("bodyMount"));
    let frame_width = sysml_requirements::number(source, own("frameWidthM"));
    let edge_clearance = sysml_requirements::number(source, visual("solarArrayEdgeClearanceM"));
    let local_mount_rails = [];
    if names.len() == stations.len() && mount_rails.len() == names.len() * 2
        && rail_names.len() == rail_stations.len() && vec3_is_native(bus_mount)
        && rotz.len() == names.len() {
        for array_index in 0..names.len() {
            for endpoint in 0..2 {
                let rail_name = mount_rails[array_index * 2 + endpoint];
                let rail_station = ();
                for rail_index in 0..rail_names.len() {
                    if rail_names[rail_index] == rail_name {
                        rail_station = rail_stations[rail_index];
                        break;
                    }
                }
                if rail_station == () { break; }
                local_mount_rails.push(panel_local_rail(rail_station, bus_mount,
                    stations[array_index], rotz[array_index]));
            }
            if local_mount_rails.len() != (array_index + 1) * 2 { break; }
        }
    }
    let mount_overlap = sysml_requirements::number(source, own("minimumMountOverlapM"));
    let mesh_paths = [];
    for name in names {
        let path = root + "/" + name;
        mesh_paths.push(path);
        mesh_paths.push(path + "/Frame");
        mesh_paths.push(path + "/Cells");
        mesh_paths.push(path + "/ArrayBackplane");
    }
    let mesh_batch = if mesh_paths.len() > 0 {
        query("QueryUsdPrims", #{paths: mesh_paths, attrs: ["points", "xformOp:scale"]})
    } else { () };
    let composed = #{};
    if mesh_batch != () && usd_geometry_inspection::same_snapshot(mesh_batch.records) {
        for record in mesh_batch.records { composed[record.path] = record; }
    }
    let checks = [];
    checks.push(sysml_requirement_checks::source_list_count("GSA-001-count", "lander_solar", "gsa001", VERIFICATION, visual("solarArrayInstances"), count));
    checks.push(sysml_requirement_checks::source_list_count("GSA-005-stations", "solar_array", "gsa005", VERIFICATION, visual("solarStations"), count));
    checks.push(sysml_requirement_checks::source_list_count("GSA-005-rotation-x", "solar_array", "gsa005", VERIFICATION, visual("solarStationRotationXDeg"), count));
    checks.push(sysml_requirement_checks::source_list_count("GSA-005-rotation-z", "solar_array", "gsa005", VERIFICATION, visual("solarStationRotationZDeg"), count));
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        checks.push(sysml_requirement_checks::exists("GSA-001-" + name, "solar_array", "gsa001", VERIFICATION, path, "Xform"));
        let required_children = [];
        for member in members { required_children.push(path + "/" + member); }
        checks.push(sysml_requirement_checks::children("GSA-002-" + name, "solar_array", "gsa002", VERIFICATION, path,
            required_children));
        if stations.len() == names.len() {
            checks.push(position("GSA-005-" + name + "-x", path, 0, stations[index].x, geometry_tolerance));
            checks.push(position("GSA-005-" + name + "-y", path, 1, stations[index].y, geometry_tolerance));
            checks.push(position("GSA-005-" + name + "-z", path, 2, stations[index].z, geometry_tolerance));
        }
        let q = griffin_spec::component_solar_orientation(index);
        if quat_is_valid(q) {
            let expected = [q.w,q.x,q.y,q.z];
            for axis in 0..4 {
                checks.push(#{id: "GSA-005-"+name+"-orientation-"+axis,
                    component: "solar_array", requirement: "gsa005", verification: VERIFICATION,
                    kind: "attribute_component", path: path, attr: "xformOp:orient",
                    index: axis, expected: expected[axis], tolerance: sysml_requirements::number(source, own("orientationTolerance"))});
            }
        }
        for member in ["Frame", "Cells", "ArrayBackplane"] {
            checks.push(sysml_requirement_checks::exists("GSA-006-" + name + "-" + member,
                "solar_array", "gsa006", VERIFICATION, path + "/" + member, "Mesh"));
        }
        let frame_geometry = mesh_geometry(composed, path + "/Frame");
        let scale = composed_attribute(composed, path, "xformOp:scale");
        let installed_width = if frame_geometry != () && scale != () && scale.len() > 0 {
            frame_geometry.extent[0] * scale[0]
        } else { () };
        let negative_rail = if local_mount_rails.len() == names.len() * 2 {
            local_mount_rails[index * 2]
        } else { () };
        let positive_rail = if local_mount_rails.len() == names.len() * 2 {
            local_mount_rails[index * 2 + 1]
        } else { () };
        let expected_installed_width = if negative_rail != () && positive_rail != ()
            && edge_clearance != () {
            (positive_rail.x - negative_rail.x).abs() - edge_clearance
        } else { () };
        let placement_constraint = sysml_requirements::required_constraint_ir(model,
            gsa005, "GriffinSolarRequirements::GSAC005_RailSpanFit");
        let placement_observations = sysml_requirements::scalar_constraint_observations(
            placement_constraint, [
            ["expectedInstalledFrameWidthM", derived_measurement(expected_installed_width,
                "typed bus rail pair or array edge clearance is unavailable", model)],
            ["measuredInstalledFrameWidthM", usd_geometry_inspection::measurement(installed_width, composed[path + "/Frame"], "composed frame points or instance scale unavailable")],
        ]);
        placement_observations.push(source_observation(model,
            visual("geometryVerificationToleranceM")));
        checks.push(sysml_requirements::required_constraints_check("GSA-005-" + name + "-rail-span-fit",
            "solar_array", "gsa005", VERIFICATION,
            "GriffinSolarRequirements::GSAC005_RailSpanFit", placement_observations, "typed", 0.0));

        let panel_envelope_constraint = sysml_requirements::required_constraint_ir(model,
            gsa006, "GriffinSolarRequirements::GSAC006_PanelMeshEnvelope");
        let panel_envelope_observations = sysml_requirements::scalar_constraint_observations(
            panel_envelope_constraint, [
            ["measuredFrameWidthM", mesh_measurement(composed, path + "/Frame", 0, "extent")],
            ["measuredFrameThicknessM", mesh_measurement(composed, path + "/Frame", 1, "extent")],
            ["measuredFrameDepthM", mesh_measurement(composed, path + "/Frame", 2, "extent")],
            ["measuredCellWidthM", mesh_measurement(composed, path + "/Cells", 0, "extent")],
            ["measuredCellThicknessM", mesh_measurement(composed, path + "/Cells", 1, "extent")],
            ["measuredCellDepthM", mesh_measurement(composed, path + "/Cells", 2, "extent")],
            ["measuredCellCenterYM", mesh_measurement(composed, path + "/Cells", 1, "center")],
            ["measuredBackplaneWidthM", mesh_measurement(composed, path + "/ArrayBackplane", 0, "extent")],
            ["measuredBackplaneThicknessM", mesh_measurement(composed, path + "/ArrayBackplane", 1, "extent")],
            ["measuredBackplaneDepthM", mesh_measurement(composed, path + "/ArrayBackplane", 2, "extent")],
            ["measuredBackplaneCenterYM", mesh_measurement(composed, path + "/ArrayBackplane", 1, "center")]
        ]);
        for source_name in [
            own("frameWidthM"), own("frameThicknessM"), own("frameDepthM"),
            own("cellWidthM"), own("cellThicknessM"), own("cellDepthM"),
            own("cellOffsetYM"), own("arrayBackplaneThicknessM"),
            own("arrayBackplaneCenterYM"), visual("geometryVerificationToleranceM")
        ] {
            panel_envelope_observations.push(source_observation(model, source_name));
        }
        checks.push(sysml_requirements::required_constraints_check("GSA-006-" + name + "-mesh-envelope",
            "solar_array", "gsa006", VERIFICATION,
            "GriffinSolarRequirements::GSAC006_PanelMeshEnvelope", panel_envelope_observations, "typed", 0.0));

        for side in ["NegativeX", "PositiveX"] {
            let bracket_path = path + "/MountBracket" + side;
            checks.push(sysml_requirement_checks::exists("GSA-007-" + name + "-" + side + "-bracket",
                "solar_array", "gsa007", VERIFICATION, bracket_path, "Cube"));
            checks.push(sysml_requirement_checks::extent_component("GSA-007-" + name + "-" + side + "-mount-width", "solar_array", "gsa007", VERIFICATION,
                bracket_path, 0, own("mountBracketWidthM"), 1.0, geometry_tolerance));
            checks.push(sysml_requirement_checks::extent_component("GSA-007-" + name + "-" + side + "-mount-thickness", "solar_array", "gsa007", VERIFICATION,
                bracket_path, 1, own("mountBracketThicknessM"), 1.0, geometry_tolerance));
            checks.push(sysml_requirement_checks::extent_component("GSA-007-" + name + "-" + side + "-mount-depth", "solar_array", "gsa007", VERIFICATION,
                bracket_path, 2, own("mountBracketDepthM"), 1.0, geometry_tolerance));
            if local_mount_rails.len() == names.len() * 2 && frame_width != () {
                let mount_index = if side == "NegativeX" { 0 } else { 1 };
                let sign = if mount_index == 0 { -1.0 } else { 1.0 };
                let first_rail = local_mount_rails[index * 2];
                let second_rail = local_mount_rails[index * 2 + 1];
                let expected_x = sign * frame_width / 2.0;
                let expected_y = (first_rail.y + second_rail.y) / 2.0;
                let expected_z = (first_rail.z + second_rail.z) / 2.0;
                checks.push(component_position("GSA-007-" + name + "-" + side + "-bracket-station",
                    "gsa007", bracket_path, 0, expected_x, geometry_tolerance));
                checks.push(component_position("GSA-007-" + name + "-" + side + "-bracket-local-y",
                    "gsa007", bracket_path, 1, expected_y, geometry_tolerance));
                checks.push(component_position("GSA-007-" + name + "-" + side + "-bracket-local-z",
                    "gsa007", bracket_path, 2, expected_z, geometry_tolerance));
            }
        }
        checks.push(#{id: "GSA-008-" + name + "-hinge-axis", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute",
            path: path + "/HingeBar", attr: "axis", expected: "X"});
        checks.push(#{id: "GSA-008-" + name + "-hinge-radius", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute",
            path: path + "/HingeBar", attr: "radius", expected_attr: own("hingeBarRadiusM"), tolerance: geometry_tolerance});
        checks.push(#{id: "GSA-008-" + name + "-hinge-length", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute",
            path: path + "/HingeBar", attr: "height", expected_attr: own("hingeBarLengthM"), tolerance: geometry_tolerance});
        checks.push(#{id: "GSA-008-" + name + "-hinge-y", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute_component",
            path: path + "/HingeBar", attr: "xformOp:translate", index: 1,
            expected_attr: own("hingeBarCenterYM"), tolerance: geometry_tolerance});
        checks.push(#{id: "GSA-008-" + name + "-hinge-z", component: "solar_array",
            requirement: "gsa008", verification: VERIFICATION, kind: "attribute_component",
            path: path + "/HingeBar", attr: "xformOp:translate", index: 2,
            expected_attr: own("hingeBarCenterZM"), tolerance: geometry_tolerance});
        for side in ["NegativeX", "PositiveX"] {
            let link_path = path + "/MountLink" + side;
            checks.push(sysml_requirement_checks::exists("GSA-008-" + name + "-" + side + "-link",
                "solar_array", "gsa008", VERIFICATION, link_path, "Cube"));
            checks.push(sysml_requirement_checks::extent_component("GSA-008-" + name + "-" + side + "-link-height", "solar_array", "gsa008", VERIFICATION,
                link_path, 1, own("mountLinkHeightM"), 1.0, geometry_tolerance));
            checks.push(sysml_requirement_checks::extent_component("GSA-008-" + name + "-" + side + "-link-depth", "solar_array", "gsa008", VERIFICATION,
                link_path, 2, own("mountLinkDepthM"), 1.0, geometry_tolerance));
            if frame_width != () {
                let sign = if side == "NegativeX" { -1.0 } else { 1.0 };
                checks.push(component_position("GSA-008-" + name + "-" + side + "-link-station",
                    "gsa008", link_path, 0,
                    sign * frame_width / 2.0, geometry_tolerance));
                checks.push(component_position("GSA-008-" + name + "-" + side + "-link-y",
                    "gsa008", link_path, 1,
                    sysml_requirements::number(source, own("mountLinkCenterYM")), geometry_tolerance));
                checks.push(component_position("GSA-008-" + name + "-" + side + "-link-z",
                    "gsa008", link_path, 2,
                    sysml_requirements::number(source, own("mountLinkCenterZM")), geometry_tolerance));
            }
            checks.push(sysml_requirement_checks::extent_component("GSA-008-" + name + "-" + side + "-link-width", "solar_array", "gsa008", VERIFICATION,
                link_path, 0, own("mountBracketWidthM"), 1.0, geometry_tolerance));
        }
    }
    if mount_overlap != () && local_mount_rails.len() == names.len() * 2
        && names.len() > 0 {
        let bus_rails = [];
        for mount_rail in mount_rails {
            bus_rails.push(root + "/Bus/" + mount_rail);
        }
        let paths = [];
        for bus_rail in bus_rails { paths.push(bus_rail); }
        for name in names {
            for side in ["NegativeX", "PositiveX"] {
                paths.push(root + "/" + name + "/MountBracket" + side);
                paths.push(root + "/" + name + "/MountLink" + side);
                paths.push(root + "/" + name + "/Frame");
            }
        }
        let batch = query("QueryUsdPrims", #{paths: paths, geometry_bounds: true});
        let bounds = #{};
        if batch.records != () {
            for record in batch.records { bounds[record.path] = record.geometry_bounds; }
        }
        let bus_to_bracket = 1.0e30;
        let bracket_to_link = 1.0e30;
        let link_to_frame = 1.0e30;
        let available = usd_geometry_inspection::same_snapshot(batch.records)
            && batch.records.len() == paths.len();
        if available {
            for array_index in 0..names.len() {
                let name = names[array_index];
                for mount_index in 0..2 {
                    let side = if mount_index == 0 { "NegativeX" } else { "PositiveX" };
                    let rail_index = array_index * 2 + mount_index;
                    let bus_rail = bus_rails[rail_index];
                    let bracket = root + "/" + name + "/MountBracket" + side;
                    let link = root + "/" + name + "/MountLink" + side;
                    let frame = root + "/" + name + "/Frame";
                    let overlap_bus = bounds_overlap_depth(bounds[bus_rail], bounds[bracket]);
                    let overlap_arm = bounds_overlap_depth(bounds[bracket], bounds[link]);
                    let overlap_panel = bounds_overlap_depth(bounds[link], bounds[frame]);
                    if overlap_bus == () || overlap_arm == () || overlap_panel == () {
                        available = false;
                    } else {
                        bus_to_bracket = minimum(bus_to_bracket, overlap_bus);
                        bracket_to_link = minimum(bracket_to_link, overlap_arm);
                        link_to_frame = minimum(link_to_frame, overlap_panel);
                    }
                }
            }
        }
        let mount_constraint = sysml_requirements::required_constraint_ir(model,
            gsa009, "GriffinSolarRequirements::GSAC009_MountPathOverlap");
        let mount_observations = sysml_requirements::scalar_constraint_observations(
            mount_constraint, [
            ["busToBracketOverlapM", usd_geometry_inspection::measurement(if available { bus_to_bracket } else { () }, if available { batch.records[0] } else { () }, "composed corner-post/bracket bounds unavailable")],
            ["bracketToLinkOverlapM", usd_geometry_inspection::measurement(if available { bracket_to_link } else { () }, if available { batch.records[0] } else { () }, "composed bracket/link bounds unavailable")],
            ["linkToFrameOverlapM", usd_geometry_inspection::measurement(if available { link_to_frame } else { () }, if available { batch.records[0] } else { () }, "composed link/frame bounds unavailable")]
        ]);
        mount_observations.push(source_observation(model,
            own("minimumMountOverlapM")));
        checks.push(sysml_requirements::required_constraints_check("GSA-009-mount-path-overlap", "solar_array",
            "gsa009", VERIFICATION, "GriffinSolarRequirements::GSAC009_MountPathOverlap",
            mount_observations, "typed", 0.0));
    }
    // This is requirement/verification-link coverage only. It does not verify
    // the panel quadrant; that needs mission solar ephemeris and approved
    // installation frames, neither of which is in the current Twin sources.
    checks.push(sysml_requirement_checks::coverage("GSA-003-verification-link-coverage", "solar_array", "gsa003", VERIFICATION));
    checks.push(sysml_requirement_checks::coverage("GSA-004-traceability", "solar_array", "gsa004", VERIFICATION));
    sysml_requirement_checks::finish(source, checks, "GRIFFIN SOLAR REQUIREMENTS", "GRIFFIN_SOLAR_REQUIREMENTS", root, PACKAGE, VERIFICATION);
    this.done = true;
}
