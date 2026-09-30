import "twin://astrobotic-griffin-1/tools/griffin_geometry.rhai" as griffin_geometry;
import "lunco://scripting/tools/sysml_requirement_checks" as sysml_requirement_checks;
import "twin://astrobotic-griffin-1/tools/usd_geometry_inspection.rhai" as usd_geometry_inspection;
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

fn simulation_dependencies(me, ctx) { usd_geometry_inspection::dependencies() }

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

fn station_ring_is_centered_square(stations, tolerance) {
    if stations.len() != 5 { return false; }
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
    let chord = [radius * (2.0).sqrt(), radius * 2.0];
    let counts = [0, 0];
    for left in 1..stations.len() {
        for right in left + 1..stations.len() {
            let dx = stations[left].x - stations[right].x;
            let dz = stations[left].z - stations[right].z;
            let distance = (dx * dx + dz * dz).sqrt();
            let matched = if absolute(distance - chord[0]) <= tolerance { 0 }
                else if absolute(distance - chord[1]) <= tolerance { 1 }
                else { -1 };
            if matched < 0 { return false; }
            counts[matched] += 1;
        }
    }
    counts[0] == 4 && counts[1] == 2
}

// Observe the rendered mesh itself: a closed Cone cap cannot pass this gate.
fn open_bell_mesh(points, counts, indices) {
    if !array_is(points) || !array_is(counts) || !array_is(indices)
        || points.len()==0 || counts.len()==0 {return #{available:false};}
    let vertices=[]; let maximum=0.0; let minimum=1.0e30;
    let lower=1.0e30; let upper=-1.0e30;
    for point in points {
        let p=vec3_from(point);vertices.push(p);
        let radius=(p.x*p.x+p.z*p.z).sqrt();
        if radius>maximum {maximum=radius;}
        if radius<minimum {minimum=radius;}
        if p.y<lower {lower=p.y;}
        if p.y>upper {upper=p.y;}
    }
    let open=true; let offset=0;
    for count in counts {
        if count!=4 || offset+count>indices.len() {return #{available:false};}
        let x=0.0;let z=0.0;
        for i in 0..count {
            let index=indices[offset+i];
            if index<0 || index>=vertices.len() {return #{available:false};}
            x+=vertices[index].x;z+=vertices[index].z;
        }
        // Annular rim and wall quads remain away from the flow axis.
        // A face spanning/closing the bore fails, including a flat disk cap.
        if (x*x+z*z).sqrt()/count < minimum/2.0 {open=false;}
        offset+=count;
    }
    #{available:offset==indices.len(),radius:maximum,height:upper-lower,
      minimum:minimum,lower:lower,upper:upper,open:open && minimum>0.0}
}

// One composed snapshot of the skirt, plate, rail stock and throat ends.
fn skirt_fit_observation(skirt_root, engine_records, bell_observations, tolerance) {
    let paths=[skirt_root+"/EngineSkirtShell",skirt_root+"/EngineAdapterPlate",skirt_root];
    for name in ["RailFront","RailRear","RailPort","RailStarboard"] {paths.push(skirt_root+"/"+name);}
    for record in engine_records {paths.push(record.path+"/Throat");}
    let batch=query("QueryUsdPrims",#{paths:paths,attrs:["points","xformOp:translate","xformOp:scale","height"]});
    let snapshot=_query_snapshot(batch);
    if snapshot.ok!=true || batch.records.len()!=paths.len() {return #{available:false,snapshot:snapshot};}
    let shell=batch.records[0];let plate=batch.records[1];let mount=batch.records[2];
    if shell.attrs.points==() || shell.attrs.points.len()!=16
        || plate.attrs["xformOp:translate"]==() || plate.attrs["xformOp:scale"]==()
        || mount.attrs["xformOp:translate"]==() {return #{available:false,snapshot:snapshot};}
    let lower=1.0e30;
    for p in shell.attrs.points {if p[1]<lower {lower=p[1];}}
    let contour=[];
    for p in shell.attrs.points {if (p[1]-lower).abs()<=tolerance {contour.push(vec3_from(p));}}
    if contour.len()!=8 {return #{available:false,snapshot:snapshot};}
    let mount_y=mount.attrs["xformOp:translate"][1];
    let plate_bottom=mount_y+plate.attrs["xformOp:translate"][1]-plate.attrs["xformOp:scale"][1]/2.0;
    let clearance=1.0e30;let visible=1.0e30;let separation=1.0e30;
    for i in 0..engine_records.len() {
        let record=engine_records[i];let bell=bell_observations[i];
        let center=vec3_from(record.attrs["xformOp:translate"]);
        let gap=griffin_geometry::convex_polygon_clearance_xz(center,contour);
        if gap==() || !bell.available {return #{available:false,snapshot:snapshot};}
        if gap-bell.radius<clearance {clearance=gap-bell.radius;}
        let exposed=(mount_y+lower-center.y-bell.lower)/bell.height;
        if exposed<visible {visible=exposed;}
        for rail_index in 3..7 {
            let rail=batch.records[rail_index];let t=rail.attrs["xformOp:translate"];let scale=rail.attrs["xformOp:scale"];
            if t==() || scale==() {return #{available:false,snapshot:snapshot};}
            let dx=(center.x-t[0]).abs()-scale[0]/2.0;
            let dz=(center.z-t[2]).abs()-scale[2]/2.0;
            if dx<0.0 {dx=0.0;}if dz<0.0 {dz=0.0;}
            let rail_gap=(dx*dx+dz*dz).sqrt()-bell.radius;
            if rail_gap<clearance {clearance=rail_gap;}
        }
        let throat=batch.records[7+i];let t=throat.attrs["xformOp:translate"];let h=throat.attrs.height;
        if t==() || h==() {return #{available:false,snapshot:snapshot};}
        let gap=plate_bottom-center.y-t[1]-h/2.0;
        if gap<separation {separation=gap;}
    }
    #{available:true,snapshot:snapshot,clearance:clearance,visible:visible,separation:separation}
}

fn on_start(me, ctx) {
    this.started = elapsed_seconds();
    this.done = false;
    this.pending_checks = ();
    this.mesh_results = [];
    this.mesh_count = ();
    this.mesh_snapshot = ();
    this.mesh_source_revision = ();
}

fn on_tick(me, ctx) {
    if this.done || elapsed_seconds() - this.started < 0.1 { return; }
    if this.pending_checks != () {
        let current_source=sysml_requirements::source_with_attributes([own("bellRadiusM")]);
        let current=query("QueryUsdPrim",#{path:this.root,attrs:[]});
        if current_source.source_revision!=this.source.source_revision
            || current.doc_id!=this.snapshot.doc_id
            || current.document_generation!=this.snapshot.document_generation
            || current.stage_generation!=this.snapshot.stage_generation {
            throw("Propulsion source or USD snapshot changed before reporting");
        }
        sysml_requirement_checks::finish(this.source,this.pending_checks,
            "GRIFFIN PROPULSION REQUIREMENTS","GRIFFIN_PROPULSION_REQUIREMENTS",
            this.root,PACKAGE,VERIFICATION);
        this.done=true;
        return;
    }
    // Measure one actual nozzle mesh per callback. Dense contours must not
    // exceed the bounded authored-script budget or weaken mesh verification.
    if this.mesh_count==() || this.mesh_results.len() < this.mesh_count {
        let mesh_source=sysml_requirements::source_with_attributes([
            own("usdRootPath"),visual("mainEngineInstances")]);
        let mesh_names=sysml_requirement_checks::source_enum_identifiers(mesh_source,visual("mainEngineInstances"));
        if mesh_names.len()==0 {throw("Griffin engine layout is unavailable");}
        if this.mesh_count!=() && this.mesh_count!=mesh_names.len() {throw("Engine instance count changed during measurement");}
        this.mesh_count=mesh_names.len();
        let mesh_root=sysml_requirements::text(mesh_source,own("usdRootPath"));
        let mesh_path=mesh_root+"/"+mesh_names[this.mesh_results.len()]+"/Bell";
        // Keep large native arrays in separate observations, below the Rhai
        // value-size limit. Fence all three against the same USD generation.
        let record=query("QueryUsdPrim",#{path:mesh_path,attrs:["points"]});
        let counts=query("QueryUsdPrim",#{path:mesh_path,attrs:["faceVertexCounts"]});
        let indices=query("QueryUsdPrim",#{path:mesh_path,attrs:["faceVertexIndices"]});
        for part in 0..2 {
            let other=if part==0 {counts} else {indices};
            if other.doc_id!=record.doc_id || other.document_generation!=record.document_generation
                || other.stage_generation!=record.stage_generation || other.type_name!="Mesh" {
                throw("Nozzle topology and vertex observations do not share a mesh snapshot");
            }
        }
        let snapshot=#{ok:record!=() && record.doc_id!=(),doc_id:record.doc_id,
            document_generation:record.document_generation,stage_generation:record.stage_generation};
        if this.mesh_snapshot!=() && (!_same_snapshot(snapshot,this.mesh_snapshot)
            || mesh_source.source_revision!=this.mesh_source_revision) {
            throw("Griffin nozzle observation changed between mesh samples");
        }
        this.mesh_snapshot=snapshot;
        this.mesh_source_revision=mesh_source.source_revision;
        this.mesh_results.push(open_bell_mesh(record.attrs.points,counts.attrs.faceVertexCounts,indices.attrs.faceVertexIndices));
        return;
    }
    let selected_attributes = [];
    for name in ["usdRootPath", "bellRadiusM", "bellHeightM", "throatRadiusM",
        "throatHeightM", "throatCenterYM", "minimumBellClearanceM", "clusterOuterRadiusM", "bellVisualWallThicknessM", "bellContourExponent"] {
        selected_attributes.push(own(name));
    }
    for name in ["componentRootName", "componentMemberNames", "shellName",
        "adapterPlateName", "railFrontCenterZM", "railRearCenterZM",
        "railPortCenterXM", "railStarboardCenterXM", "railLengthM",
        "railWidthM", "railHeightM", "shellDepthM", "adapterPlateWidthM",
        "adapterPlateHeightM", "adapterPlateDepthM", "adapterPlateCenterYM", "minimumSkirtBellClearanceM", "minimumVisibleBellHeightFraction", "transformOrder"] {
        selected_attributes.push(skirt(name));
    }
    selected_attributes.push(parent("engineCount"));
    for name in ["engineClusterMountYM", "engineStations", "geometryVerificationToleranceM",
        "mainEngineInstances"] {
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
    let skirt_outer_radius = sysml_requirements::number(source, own("clusterOuterRadiusM"));
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
    checks.push(attribute("GPP-006-nozzle-design-contour", "gpp006",
        nozzle_design_path, "inputs:contour",
        sysml_requirements::number(source,own("bellContourExponent")), geometry_tolerance));
    if source.source_revision!=this.mesh_source_revision {throw("Source changed after nozzle measurement");}
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
            let bell=query("QueryUsdPrim",#{path:path+"/Bell",
                attrs:[]});
            let mesh=this.mesh_results[index];
            let snapshot=#{ok:bell!=() && bell.doc_id!=(),doc_id:bell.doc_id,
                document_generation:bell.document_generation,stage_generation:bell.stage_generation};
            if !_same_snapshot(snapshot,this.mesh_snapshot) {throw("USD changed after nozzle measurement");}
            let bindings=_required_constraint_bindings(source_model,"gpp006","GPPC006_OpenBellEnvelope",[
                ["measuredExitRadiusM",_usd_observation(snapshot,mesh.available,mesh.radius,"bell mesh unavailable")],
                ["measuredHeightM",_usd_observation(snapshot,mesh.available,mesh.height,"bell mesh unavailable")],
                ["measuredMinimumRadiusM",_usd_observation(snapshot,mesh.available,mesh.minimum,"bell mesh unavailable")],
                ["boreOpen",_usd_observation(snapshot,mesh.available,mesh.open,"bell mesh unavailable")],
                ["exitRadiusM",_source_literal(source_model,own("bellRadiusM"))],
                ["heightM",_source_literal(source_model,own("bellHeightM"))],
                ["throatRadiusM",_source_literal(source_model,own("throatRadiusM"))],
                ["wallThicknessM",_source_literal(source_model,own("bellVisualWallThicknessM"))],
                ["toleranceM",_source_literal(source_model,visual("geometryVerificationToleranceM"))]
            ]);
            checks.push(sysml_requirements::required_constraint_check("GPP-006-"+name+"-open-bell",
                "engine","gpp006",VERIFICATION,PACKAGE+"::GPPC006_OpenBellEnvelope",bindings,"typed",0.0));
            checks.push(attribute("GPP-006-" + name + "-throat-radius", "gpp006", path + "/Throat", "radius", throat_radius, geometry_tolerance));
            checks.push(attribute("GPP-006-" + name + "-throat-height", "gpp006", path + "/Throat", "height", throat_height, geometry_tolerance));
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
        plume_paths.push(path + "/Exhaust/Flame");
        plume_paths.push(path + "/Exhaust/FlameCore");
        light_paths.push(path + "/Exhaust/FlameCore/PlumeLight");
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
            let flame_path = engine_path + "/Exhaust/Flame";
            let core_path = engine_path + "/Exhaust/FlameCore";
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
                        engine_path + "/Exhaust/Looks/Flame_Mat")
                    && has_single_relationship_target(core, "material:binding",
                        engine_path + "/Exhaust/Looks/FlameCore_Mat");
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
        && names.len() > 0 && stations.len() == names.len()
        && bell_radius != () && required_clearance != ()
        && skirt_outer_radius != () && geometry_tolerance != ()
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
        typed_stations_match = station_ring_is_centered_square(stations,
            geometry_tolerance)
            && station_ring_is_centered_square(actual_stations,
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
            ["skirtOuterRadiusM", _source_literal(source_model,
                own("clusterOuterRadiusM"))],
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
        checks.push(component_position("GES-007-adapter-y", adapter_path, 1,
            sysml_requirements::number(source,skirt("adapterPlateCenterYM")),geometry_tolerance));
        let fit=skirt_fit_observation(skirt_root,observed_engines.records,this.mesh_results,geometry_tolerance);
        let fit_available=fit.available==true && _same_snapshot(fit.snapshot,usd_snapshot);
        let fit_bindings=_required_constraint_bindings(source_model,"ges004","GESC004_SkirtAndBellFit",[
            ["minimumRadialClearanceM",_usd_observation(fit.snapshot,fit_available,fit.clearance,"skirt/rail contour unavailable")],
            ["visibleBellHeightFraction",_usd_observation(fit.snapshot,fit_available,fit.visible,"bell exposure unavailable")],
            ["adapterThroatSeparationM",_usd_observation(fit.snapshot,fit_available,fit.separation,"adapter/throat datums unavailable")],
            ["requiredRadialClearanceM",_source_literal(source_model,skirt("minimumSkirtBellClearanceM"))],
            ["requiredVisibleBellHeightFraction",_source_literal(source_model,skirt("minimumVisibleBellHeightFraction"))],
            ["toleranceM",_source_literal(source_model,visual("geometryVerificationToleranceM"))]
        ]);
        checks.push(sysml_requirements::required_constraint_check("GES-004-skirt-fit","engine_skirt","ges004",VERIFICATION,"GriffinPropulsionRequirements::GESC004_SkirtAndBellFit",fit_bindings,"typed",0.0));

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
    // Geometry measurement and reporting each use one bounded script turn.
    this.pending_checks=checks;
    this.source=source;
    this.root=root;
    this.snapshot=usd_snapshot;
}
