import "griffin_geometry" as griffin_geometry;
import "usd_geometry_inspection" as usd_geometry_inspection;
import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;

// The Editor and integrated propulsion gate inspect the same actual meshes.
fn wall_measurements(doc, root) {
    let names=["EngineSkirtShell","ThermalApron","ThermalLiner"];
    let paths=[];for name in names {paths.push(root+"/"+name);}
    let params=#{paths:paths,attrs:["points","faceVertexCounts","faceVertexIndices","doubleSided"]};
    if doc!=() {params.doc_id=doc;}
    let batch=query("QueryUsdPrims",params);
    if batch==() || batch.records==() || batch.records.len()!=names.len()
        || !usd_geometry_inspection::same_snapshot(batch.records) {return #{available:false};}
    let boundary=0;let nonmanifold=0;let winding=0;let single_sided=0;
    let volume=1.0e30;let allowance=1.0e30;let maximum_allowance=0.0;
    for index in 0..names.len() {
        let record=batch.records[index];let a=record.attrs;
        if record.type_name!="Mesh" || record.active!=true {return #{available:false};}
        let metrics=griffin_geometry::closed_mesh_metrics(a.points,a.faceVertexCounts,a.faceVertexIndices);
        if !metrics.available {return #{available:false};}
        boundary+=metrics.boundary;nonmanifold+=metrics.nonmanifold;winding+=metrics.winding;
        volume=min(volume,metrics.volume);
        if a.doubleSided==false {single_sided+=1;}
        if a.points.len()!=32 {return #{available:false};}
        if index==1 {
            for i in 0..16 {
                let stock=abs(a.points[16+i][1]-a.points[i][1]);
                allowance=min(allowance,stock);
                maximum_allowance=max(maximum_allowance,stock);
            }
        } else {
            for i in 0..16 {
                let outer=a.points[i];let inner=a.points[16+i];
                let stock=max(abs(outer[0]-inner[0]),abs(outer[2]-inner[2]));
                allowance=min(allowance,stock);
                maximum_allowance=max(maximum_allowance,stock);
            }
        }
    }
    #{available:true,identity:batch.records[0],boundaryEdgeCount:boundary,
      nonManifoldEdgeCount:nonmanifold,inconsistentEdgeWindingCount:winding,
      singleSidedSurfaceCount:single_sided,expectedSurfaceCount:names.len(),
      minimumSignedVolumeM3:volume,minimumWallAllowanceM:allowance,
      maximumWallAllowanceM:maximum_allowance}
}

fn wall_check(doc, root, verification) {
    let model=sysml_requirements::model();
    let prefix="GriffinPropulsionRequirements::";
    let requirement=model.requirement(prefix+"ges002");
    let name=prefix+"GESC002_FiniteWallGeometry";
    let ir=sysml_requirements::required_constraint_ir(model,requirement,name);
    let data=wall_measurements(doc,root);let bindings=[];
    for field in ["boundaryEdgeCount","nonManifoldEdgeCount","inconsistentEdgeWindingCount",
        "singleSidedSurfaceCount","expectedSurfaceCount","minimumSignedVolumeM3",
        "minimumWallAllowanceM","maximumWallAllowanceM"] {
        bindings.push([field,usd_geometry_inspection::measurement(
            if data.available {data[field]} else {()},data.identity,"composed finite-wall geometry unavailable")]);
    }
    let observations=sysml_requirements::scalar_constraint_observations(ir,bindings);
    for attribute in [prefix+"GriffinEngineSkirtComponent::shellWallAllowanceM",
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::geometryVerificationToleranceM"] {
        observations.push(model.source_literal_observation(model.attribute(attribute)));
    }
    sysml_requirements::required_constraint_check("GES-002-finite-walls","engine_skirt","ges002",
        verification,name,observations,"typed",0.0)
}
