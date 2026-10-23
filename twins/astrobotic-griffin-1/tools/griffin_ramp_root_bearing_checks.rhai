import "griffin_ramp_root_bearing" as bearing;
import "lunco://scripting/tools/sysml_requirements" as requirements;
import "lunco://scripting/tools/sysml_requirement_checks" as checks;
import "usd_geometry_inspection" as inspection;
fn dependencies(){#{modelica_entities:[],entity_reads:[],entity_writes:[],query_reads:["AnalyzeSysml","QueryUsdPrim","QueryUsdPrims"],required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_name()}]}}
fn observe(doc,root){
    let doc=if doc==(){inspection::document_owner(root)}else{doc};
    let own=bearing::owner();let package_name="GriffinRampRootBearingRequirements";let verification="Verify_GriffinRampRootBearing";
    let names=[];for n in ["pinRadiusM","innerRadiusM","outerRadiusM","axialLengthM","minimumRadialClearanceM","geometryToleranceM"]{names.push(own+n);}
    let source=requirements::source_with_selection(names,[package_name+"::grb001"],[package_name+"::"+verification]);
    let inner=requirements::number(source,own+"innerRadiusM");let outer=requirements::number(source,own+"outerRadiusM");let length=requirements::number(source,own+"axialLengthM");
    let pin=requirements::number(source,own+"pinRadiusM");let tolerance=requirements::number(source,own+"geometryToleranceM");
    let r=query("QueryUsdPrim",#{doc_id:doc,path:root+"/Housing",attrs:["points","faceVertexCounts","faceVertexIndices","physics:collisionEnabled","purpose"],relationships:true,geometry_bounds:true});
    let roles=r.type_name=="Mesh" && r.attrs["physics:collisionEnabled"]==false && r.attrs.purpose=="render"
        && r.relationships["material:binding"]==[root+"/Looks/Structure"];
    let error=();let clearance=();let inner_faces=0;let topology=false;
    if r.attrs.points!=() && r.attrs.faceVertexCounts!=() && r.attrs.faceVertexIndices!=() && r.geometry_bounds!=(){
        let points=r.attrs.points;let counts=r.attrs.faceVertexCounts;let indices=r.attrs.faceVertexIndices;let cursor=0;let edges=#{};
        error=0.0;topology=points.len()>=32 && counts.len()>=32;
        for p in points{let v=vec3_from(p);let radius=vlen(vec3(v.x,v.y,0.0));error=max(error,min(abs(radius-inner),abs(radius-outer)));error=max(error,abs(abs(v.z)-length/2.0));}
        for count in counts{
            if count!=4 || cursor+count>indices.len(){throw("Bearing topology is malformed");}
            let inside=true;let face=[];
            for j in 0..count{let index=indices[cursor+j];if index<0 || index>=points.len(){throw("Bearing index is invalid");}let p=vec3_from(points[index]);face.push(p);if abs(vlen(vec3(p.x,p.y,0.0))-inner)>tolerance{inside=false;}
                let next=indices[cursor+(j+1)%count];let key=min(index,next).to_string()+":"+max(index,next).to_string();edges[key]=if edges[key]==(){1}else{edges[key]+1};}
            if inside{inner_faces+=1;for j in 0..count{let a=vec3(face[j].x,face[j].y,0.0);let b=vec3(face[(j+1)%count].x,face[(j+1)%count].y,0.0);let span=vlen(b-a);if span>tolerance{let gap=vlen(vcross(a,b))/span-pin;if clearance==() || gap<clearance{clearance=gap;}}}}
            cursor+=count;
        }
        if cursor!=indices.len() || inner_faces<8{topology=false;}
        for key in edges.keys(){if edges[key]!=2{topology=false;}}
        let b=r.geometry_bounds;if b.frame!="canonical_stage"{throw("Bearing envelope frame is unavailable");}
        error=max(error,abs(b.max[0]-b.min[0]-2.0*outer));error=max(error,abs(b.max[1]-b.min[1]-2.0*outer));error=max(error,abs(b.max[2]-b.min[2]-length));
    }
    let bindings=#{measuredMinimumClearanceM:inspection::measurement(clearance,r,"Measured inner-wall aperture is unavailable"),
        measuredDimensionErrorM:inspection::measurement(error,r,"Measured bearing envelope is unavailable"),
        topologyAndRoles:inspection::measurement(topology && roles,r,"Bearing topology and roles are unavailable"),
        minimumClearanceM:#{provider:"source_literal",state:"value",value:requirements::number(source,own+"minimumRadialClearanceM"),source_revision:source.source_revision,provider_generation:source.source_revision},
        toleranceM:#{provider:"source_literal",state:"value",value:tolerance,source_revision:source.source_revision,provider_generation:source.source_revision}};
    let list=[requirements::required_constraint_check("GRB-001-open-bore","ramp_root_bearing","grb001",verification,
        package_name+"::GRBC001_OpenBore",bindings,"typed",0.0),
        checks::exists("GRB-001-axis","ramp_root_bearing","grb001",verification,root+"/HingeAxis","Xform"),
        checks::exists("GRB-001-material","ramp_root_bearing","grb001",verification,root+"/Looks/Structure","Material")];
    for i in 0..3{list.push(checks::array_component("GRB-001-axis-"+i.to_string(),"ramp_root_bearing","grb001",verification,root+"/HingeAxis","xformOp:translate",[i],0.0,tolerance));}
    for i in 0..list.len(){list[i].doc_id=doc;}
    #{source:source,checks:list,path:root,package_name:package_name,verification:verification,measurements:#{minimum_clearance_m:clearance,maximum_dimension_error_m:error,inner_faces:inner_faces,topology:topology,roles:roles}}
}
fn inspect(doc,root){let found=observe(doc,root);let result=requirements::evaluate_document(found.source,doc,found.checks);result.measurements=found.measurements;result}
