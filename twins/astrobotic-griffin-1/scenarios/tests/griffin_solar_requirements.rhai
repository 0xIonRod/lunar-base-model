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

// One row per tick keeps geometry observations below Rhai's execution and
// aggregate-array limits. Retain only scalar errors and the snapshot identity.
fn observe_cell_row(path, layout, row, gap) {
    let max_x_error=0.0;let max_z_error=0.0;let max_extent_error=0.0;let count_error=0.0;
    let record=query("QueryUsdPrim",#{path:path+"/CellRow"+row.to_string(),attrs:["points"]});
    let points=if record==() || record.attrs==() {()} else {record.attrs["points"]};
    if !array_is(points) || points.len()%16!=0 {return #{available:false,identity:()};}
    let actual_count=points.len()/16;let expected_columns=[];
    // Independent ray crossing over the source contour selects this row.
    for column in 0..layout.columns {
        let x=column+0.5;let z=row+0.5;let crossings=0;
        let previous=layout.contour[layout.contour.len()-1];
        for point in layout.contour {
            if (point.z>z)!=(previous.z>z)
                && x<point.x+(previous.x-point.x)*(z-point.z)/(previous.z-point.z) {crossings+=1;}
            previous=point;
        }
        if crossings%2==1 {expected_columns.push(column);}
    }
    count_error=max(count_error,abs(actual_count-expected_columns.len()).to_float());
    for cell in 0..min(actual_count,expected_columns.len()) {
        let cell_points=[];
        for point in cell*16..(cell+1)*16 {cell_points.push(points[point]);}
        let measured=point_bounds(cell_points);
        let expected_x=-layout.local_cell_width_m/2.0+(expected_columns[cell]+0.5)*layout.pitch_m/layout.scale_x;
        let expected_z=-layout.cell_depth_m/2.0+(row+0.5)*layout.pitch_z_m;
        max_x_error=max(max_x_error,abs(measured.center[0]-expected_x)*layout.scale_x);
        max_z_error=max(max_z_error,abs(measured.center[2]-expected_z));
        max_extent_error=max(max_extent_error,abs(measured.extent[0]*layout.scale_x-(layout.pitch_m-gap)));
        max_extent_error=max(max_extent_error,abs(measured.extent[2]-(layout.pitch_z_m-gap)));
    }
    #{available:true,x:max_x_error,z:max_z_error,extent:max_extent_error,count:count_error,
      identity:#{doc_id:record.doc_id,document_generation:record.document_generation,stage_generation:record.stage_generation}}
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
    this.grid=[];this.grid_panel=0;this.grid_row=0;this.grid_source_revision=();
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    let model = sysml_requirements::model();
    if this.grid_source_revision==() {this.grid_source_revision=model.source_revision;}
    if this.grid_source_revision!=model.source_revision {throw("Solar source changed during cell observations");}
    let array_names=griffin_spec::solar_array_names();
    if this.grid_panel<array_names.len() {
        let index=this.grid_panel;let layout=griffin_spec::solar_installed_cell_layout(index);
        if layout==() {throw("Solar row source unavailable");}
        let root=model.value(own("usdRootPath"));
        let gap=f64_from(model.value(own("cellGapM")));
        let row=observe_cell_row(root+"/"+array_names[index],layout,this.grid_row,gap);
        if this.grid_row==0 {
            this.grid.push(#{available:row.available,identity:row.identity,x:0.0,z:0.0,extent:0.0,count:0.0});
        }
        let grid=this.grid[index];
        grid.available=grid.available && row.available && usd_geometry_inspection::same_snapshot([grid.identity,row.identity]);
        if row.available {
            grid.x=max(grid.x,row.x);grid.z=max(grid.z,row.z);
            grid.extent=max(grid.extent,row.extent);grid.count=max(grid.count,row.count);
        }
        this.grid[index]=grid;this.grid_row+=1;
        if this.grid_row>=layout.rows {this.grid_row=0;this.grid_panel+=1;}
        return;
    }
    let source = sysml_requirements::source();
    let gsa005 = model.requirement(PACKAGE + "::gsa005");
    let gsa006 = model.requirement(PACKAGE + "::gsa006");
    let gsa009 = model.requirement(PACKAGE + "::gsa009");
    let root = sysml_requirements::text(source, own("usdRootPath"));
    let geometry_tolerance = sysml_requirements::number(source, visual("geometryVerificationToleranceM"));
    let names = sysml_requirement_checks::source_enum_identifiers(source, visual("solarArrayInstances"));
    let stations = griffin_spec::component_solar_stations();
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
    for index in 0..names.len() {
        let name=names[index];
        let layout=griffin_spec::solar_installed_cell_layout(index);
        if layout==() {throw("solar installed cell layout unavailable");}
        let path = root + "/" + name;
        mesh_paths.push(path);
        mesh_paths.push(path + "/Frame");
        mesh_paths.push(path + "/Cells");
        mesh_paths.push(path + "/ArrayBackplane");
    }
    let mesh_batch = if mesh_paths.len() > 0 {
        query("QueryUsdPrims", #{paths: mesh_paths, attrs: ["points", "xformOp:scale","xformOp:translate","visibility"]})
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
    checks.push(sysml_requirement_checks::not_exists("GSA-003-no-speculative-opposite-array",
        "solar_array", "gsa003", VERIFICATION, root+"/SolarPanelRear"));
    for index in 0..names.len() {
        let name = names[index];
        let path = root + "/" + name;
        checks.push(sysml_requirement_checks::exists("GSA-001-" + name, "solar_array", "gsa001", VERIFICATION, path, "Xform"));
        let layout=griffin_spec::solar_installed_cell_layout(index);
        if layout==() {throw("solar installed cell layout unavailable");}
        let required_children = [];
        for member in griffin_spec::solar_installed_visible_members(index,members) {required_children.push(path+"/"+member);}
        checks.push(sysml_requirement_checks::children("GSA-002-" + name, "solar_array", "gsa002", VERIFICATION, path,
            required_children));
        if stations.len() == names.len() {
            checks.push(position("GSA-005-" + name + "-x", path, 0, stations[index].x, geometry_tolerance));
            checks.push(position("GSA-005-" + name + "-y", path, 1, stations[index].y, geometry_tolerance));
            checks.push(position("GSA-005-" + name + "-z", path, 2, stations[index].z, geometry_tolerance));
        }
        for check in griffin_requirements::solar_orientation_checks(
            "GSA-005-" + name, path, index, "gsa005", VERIFICATION) { checks.push(check); }
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
            griffin_spec::component_solar_array_widths_m()[index]
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
            ["installedLocalCellWidthM", derived_measurement(layout.local_cell_width_m,"whole source-pitch columns in fitted face",model)],
            ["installedLocalFrameDepthM", derived_measurement(layout.frame_depth_m,"selected rows plus frame border",model)],
            ["installedLocalCellDepthM", derived_measurement(layout.cell_depth_m,"selected rows at source cell pitch",model)],
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
            own("frameWidthM"), own("frameThicknessM"),
            own("cellWidthM"), own("cellThicknessM"),
            own("cellOffsetYM"), own("arrayBackplaneThicknessM"),
            own("arrayBackplaneCenterYM"), visual("geometryVerificationToleranceM")
        ] {
            panel_envelope_observations.push(source_observation(model, source_name));
        }
        checks.push(sysml_requirements::required_constraints_check("GSA-006-" + name + "-mesh-envelope",
            "solar_array", "gsa006", VERIFICATION,
            "GriffinSolarRequirements::GSAC006_PanelMeshEnvelope", panel_envelope_observations, "typed", 0.0));

        let grid=this.grid[index];
        let grid_available=grid.available && usd_geometry_inspection::same_snapshot([grid.identity,composed[path+"/Cells"]]);
        let max_x_error=grid.x;let max_z_error=grid.z;
        let max_extent_error=grid.extent;let count_error=grid.count;
        let grid_constraint=sysml_requirements::required_constraint_ir(model,model.requirement(PACKAGE+"::gsa007"),PACKAGE+"::GSAC007_UniformMetricCellPitch");
        let grid_inputs=sysml_requirements::scalar_constraint_observations(grid_constraint,[
            ["maximumColumnPitchErrorM",usd_geometry_inspection::measurement(if grid_available {max_x_error} else {()},composed[path+"/Cells"],"visible column spacing unavailable")],
            ["maximumRowPitchErrorM",usd_geometry_inspection::measurement(if grid_available {max_z_error} else {()},composed[path+"/Cells"],"row spacing unavailable")],
            ["maximumCellExtentErrorM",usd_geometry_inspection::measurement(if grid_available {max_extent_error} else {()},composed[path+"/Cells"],"cell dimensions unavailable")],
            ["maximumCellCountError",usd_geometry_inspection::measurement(if grid_available {count_error} else {()},composed[path+"/Cells"],"contour cell count unavailable")]
        ]);
        grid_inputs.push(source_observation(model,visual("geometryVerificationToleranceM")));
        checks.push(sysml_requirements::required_constraints_check("GSA-007-"+name+"-metric-cell-pitch","solar_array","gsa007",VERIFICATION,PACKAGE+"::GSAC007_UniformMetricCellPitch",grid_inputs,"typed",0.0));
        for side in ["NegativeX", "PositiveX"] {
            let bracket_path = path + "/MountBracket" + side;
            checks.push(sysml_requirement_checks::exists("GSA-007-" + name + "-" + side + "-bracket",
                "solar_array", "gsa007", VERIFICATION, bracket_path, "Cube"));
            checks.push(#{id:"GSA-007-"+name+side+"-mount-width",component:"solar_array",requirement:"gsa007",verification:VERIFICATION,
                kind:"attribute_component",path:bracket_path,attr:"xformOp:scale",index:0,
                expected:sysml_requirements::number(source,own("mountBracketWidthM"))/layout.scale_x,tolerance:geometry_tolerance});
            checks.push(sysml_requirement_checks::extent_component("GSA-007-" + name + "-" + side + "-mount-thickness", "solar_array", "gsa007", VERIFICATION,
                bracket_path, 1, own("mountBracketThicknessM"), 1.0, geometry_tolerance));
            checks.push(sysml_requirement_checks::extent_component("GSA-007-" + name + "-" + side + "-mount-depth", "solar_array", "gsa007", VERIFICATION,
                bracket_path, 2, own("mountBracketDepthM"), 1.0, geometry_tolerance));
            if local_mount_rails.len() == names.len() * 2 && frame_width != () {
                let mount_index = if side == "NegativeX" { 0 } else { 1 };
                let sign = if mount_index == 0 { -1.0 } else { 1.0 };
                let first_rail = local_mount_rails[index * 2];
                let second_rail = local_mount_rails[index * 2 + 1];
                let expected_x = if mount_index==0 {first_rail.x/layout.scale_x} else {second_rail.x/layout.scale_x};
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
            expected:sysml_requirements::number(source,own("hingeBarCenterZM"))
                +layout.datum_offset_m, tolerance: geometry_tolerance});
        for side in ["NegativeX", "PositiveX"] {
            let link_path = path + "/MountLink" + side;
            checks.push(sysml_requirement_checks::exists("GSA-008-" + name + "-" + side + "-link",
                "solar_array", "gsa008", VERIFICATION, link_path, "Cube"));
            if negative_rail!=() && positive_rail!=() {
                let rail=if side=="NegativeX" {negative_rail} else {positive_rail};
                let sign=if side=="NegativeX" {-1.0} else {1.0};
                let panel_x=sign*frame_width/2.0;let rail_x=rail.x/layout.scale_x;
                let dx=panel_x-rail_x;let dy=-rail.y;
                let height=sqrt(dx*dx+dy*dy)+sysml_requirements::number(source,own("mountLinkHeightM"))-dy;
                let dims=[sysml_requirements::number(source,own("mountBracketWidthM"))/layout.scale_x,height,sysml_requirements::number(source,own("mountLinkDepthM"))];
                for axis in 0..3 {
                    checks.push(#{id:"GSA-008-"+name+side+"-link-stock-"+axis.to_string(),component:"solar_array",requirement:"gsa008",verification:VERIFICATION,
                        kind:"attribute_component",path:link_path,attr:"xformOp:scale",index:axis,expected:dims[axis],tolerance:geometry_tolerance});
                }
                for datum in [#{axis:0,value:(panel_x+rail_x)/2.0},#{axis:1,value:rail.y/2.0},#{axis:2,value:rail.z}] {
                    checks.push(component_position("GSA-008-"+name+side+"-link-center-"+datum.axis.to_string(),"gsa008",link_path,datum.axis,datum.value,geometry_tolerance));
                }
            }
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
