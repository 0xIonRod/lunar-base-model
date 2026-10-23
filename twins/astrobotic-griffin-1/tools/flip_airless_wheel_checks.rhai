import "flip_airless_wheel" as wheel;
import "usd_geometry_inspection" as inspection;
import "lunco://scripting/tools/assembly_builder" as frames;
import "lunco://scripting/tools/sysml_requirements" as requirements;
import "lunco://scripting/tools/sysml_requirement_checks" as checks;
fn package_name(){"FlipAirlessWheelRequirements"}
fn verification(){"Verify_FLIPAirlessWheel"}
fn dependencies(){inspection::dependencies()}
fn begin(doc,root){
    let names=[];
    for name in ["radiusM","widthM","treadThicknessM","treadBladeThicknessM","cableCount","cableRows","cablesPerRow","cableSegments","springCount","springsPerMesh","treadBladeCount","webCount","maximumTriangles","maximumMeshes","geometryToleranceM","materialProjectionTolerance"]{names.push(wheel::owner()+name);}
    for prefix in ["metal","cable","blade","carrier"]{for field in ["Color","Metallic","Roughness"]{names.push(wheel::owner()+prefix+field);}}
    let source=requirements::source_with_selection(names,[package_name()+"::faw001",package_name()+"::faw002",package_name()+"::faw003"],[package_name()+"::"+verification()]);
    if !source.ok{throw("Airless wheel source is unavailable");}
    let record=query("QueryUsdPrim",#{doc_id:doc,path:root,children:true,schemas:true,attrs:[]});
    let expected=wheel::groups();let roles=record.type_name=="Xform" && record.children.len()==expected.len()+2
        && !record.api_schemas.contains("PhysicsRigidBodyAPI") && !record.api_schemas.contains("LunCoProgramAPI");
    for name in expected{if !record.children.contains(root+"/"+name){roles=false;}}
    let pose=frames::mount_local_transform(doc,root);if !pose.ok{throw("Wheel root frame must retain its source metric scale");}
    #{doc:doc,root:root,source:source,revision:source.source_revision,fence:record,names:expected,index:0,phase:"load",current:(),
      valid:roles,triangles:0,cables:0,springs:0,blades:0,maximum_radius:(),minimum_z:(),maximum_z:(),excess:(),checks:[],done:false,
      cable_seats:[],cable_ends:[],spring_seats:[],seat_uses:[],seat_index:0,maximum_seat_error:(),maximum_tread_excess:(),carrier_inner:(),carrier_outer:(),carrier_min_z:(),carrier_max_z:()}
}
fn component_root(parents,index){let r=index;while parents[r]!=r{r=parents[r];}r}
fn number(state,name){requirements::number(state.source,wheel::owner()+name)}
fn assert_current(state){
    let r=query("QueryUsdPrim",#{doc_id:state.doc,path:state.root,attrs:[]});
    if r.document_generation!=state.fence.document_generation || r.stage_generation!=state.fence.stage_generation
        || requirements::model().source_revision!=state.revision{throw("Airless wheel document, stage or source changed during observation");}
}
fn advance(state){
    assert_current(state);
    if state.phase=="load"{
        let name=state.names[state.index];let path=state.root+"/"+name;
        let r=query("QueryUsdPrim",#{doc_id:state.doc,path:path,schemas:true,relationships:true,
            attrs:["points","faceVertexCounts","faceVertexIndices","purpose","physics:collisionEnabled"]});
        if r.type_name!="Mesh" || r.attrs.points==() || r.attrs.points.len()==0 || r.attrs.faceVertexCounts==() || r.attrs.faceVertexIndices==(){throw("Wheel mesh data is incomplete: "+path);}
        let native_points=[];for point in r.attrs.points{native_points.push(vec3_from(point));}r.attrs.points=native_points;
        let pose=frames::mount_frame_in_body(state.doc,state.root,path);if !pose.ok{throw("Wheel member metric frame is invalid: "+path);}
        let tf=transform(vec3_from(pose.value.translation),quat_from(pose.value.rotation),vec3(1.0,1.0,1.0));
        let parents=[];let used=[];let incidence=[];for i in 0..r.attrs.points.len(){parents.push(i);used.push(false);incidence.push(0);}
        state.valid=state.valid && r.attrs.purpose=="render" && r.attrs["physics:collisionEnabled"]==false
            && !r.api_schemas.contains("PhysicsRigidBodyAPI") && !r.api_schemas.contains("PhysicsMassAPI") && !r.api_schemas.contains("LunCoProgramAPI");
        state.current=#{record:r,pose:tf,vertex:0,face:0,cursor:0,parents:parents,used:used,incidence:incidence,edges:#{},volume:0.0};
        state.checks.push(#{id:"FAW-002-binding-"+name,component:"airless_wheel",requirement:"faw002",verification:verification(),
            kind:"relationship",path:path,rel:"material:binding",targets:[state.root+"/Looks/"+wheel::role(name)],doc_id:state.doc});
        state.phase="vertices";return state;
    }
    if state.phase=="vertices"{
        let c=state.current;let points=c.record.attrs.points;let stop=min(c.vertex+128,points.len());let required_radius=number(state,"radiusM");let required_width=number(state,"widthM");
        for i in c.vertex..stop{let p=transform_apply_point(c.pose,vec3_from(points[i]));let radius=vlen(vec3(p.x,p.y,0.0));
            if state.maximum_radius==(){state.maximum_radius=radius;state.minimum_z=p.z;state.maximum_z=p.z;}
            else{state.maximum_radius=max(state.maximum_radius,radius);state.minimum_z=min(state.minimum_z,p.z);state.maximum_z=max(state.maximum_z,p.z);}
            let excess=max(radius-required_radius,abs(p.z)-required_width/2.0);
            state.excess=if state.excess==(){excess}else{max(state.excess,excess)};
            if state.names[state.index]=="Carrier"{
                let inner=required_radius-number(state,"treadThicknessM");let outer=required_radius-number(state,"treadBladeThicknessM");let tolerance=number(state,"geometryToleranceM");
                if abs(radius-inner)<=tolerance{state.carrier_inner=if state.carrier_inner==(){radius}else{max(state.carrier_inner,radius)};}
                else if abs(radius-outer)>tolerance{state.valid=false;}
                if state.carrier_min_z==(){state.carrier_min_z=p.z;state.carrier_max_z=p.z;}else{state.carrier_min_z=min(state.carrier_min_z,p.z);state.carrier_max_z=max(state.carrier_max_z,p.z);}
            }
        }c.vertex=stop;state.current=c;if stop==points.len(){state.phase="faces";}return state;
    }
    if state.phase=="faces"{
        let c=state.current;let points=c.record.attrs.points;let counts=c.record.attrs.faceVertexCounts;let indices=c.record.attrs.faceVertexIndices;
        let stop=min(c.face+40,counts.len());
        for face in c.face..stop{let count=counts[face];if count<3 || c.cursor+count>indices.len(){throw("Wheel face topology is malformed");}
            for j in 0..count{let a=indices[c.cursor+j];let b=indices[c.cursor+(j+1)%count];
                if a<0 || a>=points.len() || b<0 || b>=points.len() || a==b{throw("Wheel mesh index is invalid");}
                c.used[a]=true;c.incidence[a]+=1;let x=a;let y=b;while c.parents[x]!=x{x=c.parents[x];}while c.parents[y]!=y{y=c.parents[y];}
                if x!=y{c.parents[max(x,y)]=min(x,y);}
                let key=min(a,b).to_string()+":"+max(a,b).to_string();let direction=if a<b{1}else{-1};
                if c.edges[key]==(){c.edges[key]=#{count:1,direction:direction};}else{c.edges[key].count+=1;c.edges[key].direction+=direction;}
            }
            let a=vec3_from(points[indices[c.cursor]]);
            if state.names[state.index]=="Carrier"{
                let wall=true;let outer=number(state,"radiusM")-number(state,"treadBladeThicknessM");let tolerance=number(state,"geometryToleranceM");
                for j in 0..count{let p=transform_apply_point(c.pose,vec3_from(points[indices[c.cursor+j]]));if abs(vlen(vec3(p.x,p.y,0.0))-outer)>tolerance{wall=false;}}
                if wall{let pa=transform_apply_point(c.pose,a);let pb=transform_apply_point(c.pose,vec3_from(points[indices[c.cursor+1]]));let pd=transform_apply_point(c.pose,vec3_from(points[indices[c.cursor+2]]));let n=vcross(pb-pa,pd-pa);let plane=abs(vdot(n,pa))/vlen(n);state.carrier_outer=if state.carrier_outer==(){plane}else{min(state.carrier_outer,plane)};}
            }
            for j in 1..(count-1){let b=vec3_from(points[indices[c.cursor+j]]);let d=vec3_from(points[indices[c.cursor+j+1]]);
                if vlen(vcross(b-a,d-a))<=1.0e-15{state.valid=false;}
                c.volume+=vdot(a,vcross(b,d))/6.0;
            }state.triangles+=count-2;c.cursor+=count;
        }c.face=stop;state.current=c;if stop==counts.len(){state.phase="mesh-result";}return state;
    }
    if state.phase=="mesh-result"{
        let c=state.current;let components=0;
        if c.cursor!=c.record.attrs.faceVertexIndices.len() || c.volume<=0.0{state.valid=false;}
        for i in 0..c.parents.len(){if !c.used[i]{state.valid=false;}if c.parents[i]==i{components+=1;}}
        for key in c.edges.keys(){if c.edges[key].count!=2 || c.edges[key].direction!=0{state.valid=false;}}
        let name=state.names[state.index];let expected=1;
        if name.starts_with("Cables"){expected=number(state,"cablesPerRow");state.cables+=components;}
        else if name.starts_with("Springs"){expected=number(state,"springsPerMesh");state.springs+=components;}
        else if name.starts_with("Blades"){expected=number(state,"treadBladeCount")/2;state.blades+=components;}
        else if name.starts_with("Web"){expected=number(state,"webCount");}
        else if name=="Fasteners"{expected=number(state,"webCount")*2;}
        if name.starts_with("Cables") || name.starts_with("Springs"){
            let caps=#{};let points=c.record.attrs.points;
            if name.starts_with("Cables"){
                for i in 0..points.len(){if c.incidence[i]==number(state,"cableSegments"){
                    let key=component_root(c.parents,i).to_string();let p=transform_apply_point(c.pose,vec3_from(points[i]));let radius=vlen(vec3(p.x,p.y,0.0));
                    if caps[key]==(){caps[key]=#{count:1,position:p,radius:radius,outer_position:p,outer_radius:radius};}else{
                        caps[key].count+=1;if radius<caps[key].radius{caps[key].position=p;caps[key].radius=radius;}
                        if radius>caps[key].outer_radius{caps[key].outer_position=p;caps[key].outer_radius=radius;}
                    }
                }}
            }else{
                let cursor=0;for count in c.record.attrs.faceVertexCounts{
                    let terminal=count==4;let centre=vec3(0.0,0.0,0.0);
                    for j in 0..count{let index=c.record.attrs.faceVertexIndices[cursor+j];terminal=terminal && c.incidence[index]==3;centre+=transform_apply_point(c.pose,vec3_from(points[index]));}
                    if terminal{centre=centre*(1.0/count.to_float());let key=component_root(c.parents,c.record.attrs.faceVertexIndices[cursor]).to_string();let radius=vlen(vec3(centre.x,centre.y,0.0));
                        if caps[key]==(){caps[key]=#{count:1,position:centre,radius:radius};}else{
                            caps[key].count+=1;if radius>caps[key].radius{caps[key].position=centre;caps[key].radius=radius;}
                        }
                    }cursor+=count;
                }
            }
            if caps.len()!=components{state.valid=false;}
            for key in caps.keys(){if caps[key].count!=2{state.valid=false;}
                if name.starts_with("Cables"){state.cable_seats.push(caps[key].position);state.cable_ends.push(caps[key].outer_position);}
                else{state.spring_seats.push(caps[key].position);state.seat_uses.push(0);}
            }
        }
        state.valid=state.valid && components==expected;
        print("FLIP_AIRLESS_MESH "+#{name:name,components:components,expected:expected,signed_volume_m3:c.volume,valid:state.valid}.to_string());
        state.current=();state.index+=1;state.phase=if state.index==state.names.len(){"seats"}else{"load"};return state;
    }
    if state.phase=="seats"{
        if state.cable_seats.len()!=number(state,"cableCount") || state.spring_seats.len()!=number(state,"springCount"){throw("Measured cable/spring terminal coverage is incomplete");}
        if state.carrier_inner==() || state.carrier_outer==() || state.carrier_min_z==() || state.carrier_max_z==(){throw("Measured carrier annulus is incomplete");}
        let stop=min(state.seat_index+16,state.cable_seats.len());
        for i in state.seat_index..stop{let closest=();let selected=();
            for j in 0..state.spring_seats.len(){let distance=vlen(state.cable_seats[i]-state.spring_seats[j]);if closest==() || distance<closest{closest=distance;selected=j;}}
            if selected==(){throw("No measured spring terminal is available");}state.seat_uses[selected]+=1;
            state.maximum_seat_error=if state.maximum_seat_error==(){closest}else{max(state.maximum_seat_error,closest)};
            let end=state.cable_ends[i];let radius=vlen(vec3(end.x,end.y,0.0));let excess=max(max(state.carrier_inner-radius,radius-state.carrier_outer),max(state.carrier_min_z-end.z,end.z-state.carrier_max_z));
            state.maximum_tread_excess=if state.maximum_tread_excess==(){excess}else{max(state.maximum_tread_excess,excess)};
        }state.seat_index=stop;if stop==state.cable_seats.len(){
            for count in state.seat_uses{if count!=number(state,"cableCount")/number(state,"springCount"){state.valid=false;}}
            state.phase="materials";
        }return state;
    }
    if state.phase=="materials"{
        let model=requirements::model();let tolerance=number(state,"materialProjectionTolerance");
        let looks=query("QueryUsdPrim",#{doc_id:state.doc,path:state.root+"/Looks",children:true,attrs:[]});
        if looks.children.len()!=4{state.valid=false;}
        for role in ["Metal","Cable","Blade","Carrier"]{
            let material=state.root+"/Looks/"+role;let shader=material+"/Surface";let prefix=role.to_lower();let id="FAW-002-"+role;
            state.checks.push(checks::exists(id+"-material","airless_wheel","faw002",verification(),material,"Material"));
            state.checks.push(checks::attribute_equals(id+"-surface-model","airless_wheel","faw002",verification(),shader,"info:id","UsdPreviewSurface"));
            let color=model.value(wheel::owner()+prefix+"Color");
            for i in 0..3{state.checks.push(checks::array_component(id+"-color-"+i.to_string(),"airless_wheel","faw002",verification(),shader,"inputs:diffuseColor",[i],color[i],tolerance));}
            for field in [["Metallic","inputs:metallic"],["Roughness","inputs:roughness"]]{state.checks.push(#{id:id+"-"+field[0],component:"airless_wheel",requirement:"faw002",verification:verification(),kind:"attribute",path:shader,attr:field[1],expected:number(state,prefix+field[0]),tolerance:tolerance});}
            let r=query("QueryUsdPrim",#{doc_id:state.doc,path:shader,attrs:["inputs:diffuseColor","inputs:metallic","inputs:roughness"],children:true});
            let network=query("QueryUsdPrim",#{doc_id:state.doc,path:material,attrs:[],connections:true,children:true});
            let connected=network.connections["outputs:surface"]==[shader+".outputs:surface"] && network.children==[shader] && r.children.len()==0;
            let bindings=#{surfaceConnected:inspection::measurement(connected,r,"Material network is unavailable"),
                red:inspection::measurement(r.attrs["inputs:diffuseColor"][0],r,"Color unavailable"),green:inspection::measurement(r.attrs["inputs:diffuseColor"][1],r,"Color unavailable"),blue:inspection::measurement(r.attrs["inputs:diffuseColor"][2],r,"Color unavailable"),
                metallic:inspection::measurement(r.attrs["inputs:metallic"],r,"Metallic unavailable"),roughness:inspection::measurement(r.attrs["inputs:roughness"],r,"Roughness unavailable")};
            state.checks.push(requirements::required_constraint_check(id+"-normalized","airless_wheel","faw002",verification(),"FlipChassisRequirements::FCCC006_NormalizedPreviewSurface",bindings,"typed",0.0));
        }state.phase="result";return state;
    }
    let geometry_valid=state.valid && state.cables==number(state,"cableCount") && state.springs==number(state,"springCount") && state.blades==number(state,"treadBladeCount");
    let radius_error=abs(state.maximum_radius-number(state,"radiusM"));let width_error=abs(state.maximum_z-state.minimum_z-number(state,"widthM"));
    let bindings=#{measuredRadiusErrorM:inspection::measurement(radius_error,state.fence,"Radius unavailable"),measuredWidthErrorM:inspection::measurement(width_error,state.fence,"Width unavailable"),
        maximumEnvelopeExcessM:inspection::measurement(state.excess,state.fence,"Envelope unavailable"),maximumCableSeatErrorM:inspection::measurement(state.maximum_seat_error,state.fence,"Cable seating unavailable"),maximumCableTreadExcessM:inspection::measurement(state.maximum_tread_excess,state.fence,"Tread seating unavailable"),topologyAndRoles:inspection::measurement(geometry_valid,state.fence,"Topology unavailable"),
        toleranceM:#{provider:"source_literal",state:"value",value:number(state,"geometryToleranceM"),source_revision:state.revision,provider_generation:state.revision}};
    state.checks.push(requirements::required_constraint_check("FAW-001-geometry","airless_wheel","faw001",verification(),package_name()+"::FAWC001_ContainedGeometry",bindings,"typed",0.0));
    let limits=requirements::model();
    let cost=#{measuredMeshes:inspection::measurement(state.names.len(),state.fence,"Mesh count unavailable"),measuredTriangles:inspection::measurement(state.triangles,state.fence,"Triangle count unavailable"),
        maximumMeshes:#{provider:"source_literal",state:"value",value:limits.value(wheel::owner()+"maximumMeshes"),source_revision:state.revision,provider_generation:state.revision},
        maximumTriangles:#{provider:"source_literal",state:"value",value:limits.value(wheel::owner()+"maximumTriangles"),source_revision:state.revision,provider_generation:state.revision}};
    state.checks.push(requirements::required_constraint_check("FAW-003-cost","airless_wheel","faw003",verification(),package_name()+"::FAWC003_RenderCost",cost,"typed",0.0));
    state.checks.push(checks::exists("FAW-001-axis","airless_wheel","faw001",verification(),state.root+"/HubAxis","Xform"));
    for i in 0..3{state.checks.push(checks::array_component("FAW-001-axis-"+i.to_string(),"airless_wheel","faw001",verification(),state.root+"/HubAxis","xformOp:translate",[i],0.0,number(state,"geometryToleranceM")));}
    for i in 0..state.checks.len(){state.checks[i].doc_id=state.doc;}
    assert_current(state);state.done=true;
    print("FLIP_AIRLESS_MEASUREMENTS "+#{meshes:state.names.len(),triangles:state.triangles,cables:state.cables,springs:state.springs,blades:state.blades,maximum_radius_error_m:radius_error,width_error_m:width_error,envelope_excess_m:state.excess,maximum_cable_seat_error_m:state.maximum_seat_error,maximum_cable_tread_excess_m:state.maximum_tread_excess,geometry_valid:geometry_valid}.to_string());
    checks::finish(state.source,state.checks,"FLIP AIRLESS WHEEL","FLIP_AIRLESS_WHEEL",state.root,package_name(),verification());state
}
