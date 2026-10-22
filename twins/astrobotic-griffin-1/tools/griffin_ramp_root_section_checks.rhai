import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;
import "griffin_spec" as spec;
import "usd_geometry_inspection" as inspection;
import "lunco://scripting/tools/sysml_requirement_checks" as checks;

fn package_name(){"GriffinRampRootSectionRequirements"}
fn own(){"GriffinRampRootSectionRequirements::RampRootSection::"}
fn verification(){"Verify_GriffinRampRootSection"}

fn dependencies(){inspection::dependencies()}
fn check(id,kind,path){#{id:id,component:"ramp_root_section",requirement:"grs001",verification:verification(),kind:kind,path:path}}
fn coordinate(id,path,attr,index,expected,tolerance){
    let c=check(id,"attribute_component",path);
    c.attr=attr;c.index=index;c.expected=expected;c.tolerance=tolerance;c
}
fn attribute(id,path,attr,expected){
    let c=check(id,"attribute_equals",path);c.attr=attr;c.expected=expected;c
}
fn observe(doc,root){
    // Static geometry is read from its exact authored document. A spawned
    // static collider need not have an active dynamic-body frame.
    let selected_doc=if doc==() {inspection::document_owner(root)} else {doc};
    let names=[];
    for name in ["lengthM","geometryToleranceM","deckFrameName","foldFrameName","deckAxisYM","foldAxisYM"]{
        names.push(own()+name);
    }
    let source=sysml_requirements::source_with_selection(names,
        [package_name()+"::grs001"],[package_name()+"::"+verification()]);
    let length=sysml_requirements::number(source,own()+"lengthM");
    let tolerance=sysml_requirements::number(source,own()+"geometryToleranceM");
    if length==() || tolerance==(){throw("Root-section source is unavailable");}
    let list=[];
    let width=spec::ramp_contact_track_width_m();
    let thickness=spec::ramp_surface_thickness_m();
    let paths=[root+"/RampTrackPort",root+"/RampTrackStarboard"];
    let guides=spec::ramp_guide_stations();
    for guide in guides {paths.push(root+"/"+guide.name);}
    let snapshot=query("QueryUsdPrims",#{doc_id:selected_doc,paths:paths,collision_bounds:true,
        attrs:["physics:collisionEnabled"]});
    let coherent=snapshot!=() && snapshot.records!=()
        && snapshot.records.len()==paths.len() && inspection::same_snapshot(snapshot.records);
    let maximum_error=();let owner=();
    if coherent {
        maximum_error=0.0;owner=snapshot.records[0];
        for index in 0..snapshot.records.len() {
            let record=snapshot.records[index];
            let bounds=record.collision_bounds;
            if bounds==() || bounds.frame!="canonical_stage" {maximum_error=();break;}
            maximum_error=max(maximum_error,abs(bounds.max[0]-bounds.min[0]-length));
            if index<2 {
                maximum_error=max(maximum_error,abs(bounds.max[1]-bounds.min[1]-thickness));
                maximum_error=max(maximum_error,abs(bounds.max[2]-bounds.min[2]-width));
            }
        }
    }
    let bindings=#{sourceLengthM:#{provider:"source_literal",state:"value",value:length,
        source_revision:source.source_revision,provider_generation:source.source_revision},
        measuredDimensionErrorM:inspection::measurement(maximum_error,owner,"Root track canonical metric span is unavailable"),
        toleranceM:#{provider:"source_literal",state:"value",value:tolerance,
            source_revision:source.source_revision,provider_generation:source.source_revision}};
    list.push(sysml_requirements::required_constraint_check("GRS-001-native-metric-span",
        "ramp_root_section","grs001",verification(),package_name()+"::GRSC001_PositiveSpan",bindings,"typed",0.0));
    for i in 0..2{
        let path=paths[i];let id="GRS-001-track-"+i.to_string();
        let exists=check(id,"exists",path);exists.expected_type="Mesh";list.push(exists);
        list.push(attribute(id+"-contact",path,"physics:collisionEnabled",true));
        list.push(attribute(id+"-hull",path,"physics:approximation","convexHull"));
        for vertex in [2,3,6,7]{list.push(checks::array_component(id+"-tip-"+vertex.to_string(),
            "ramp_root_section","grs001",verification(),path,"points",[vertex,0],length,tolerance));}
        list.push(coordinate(id+"-station",path,"xformOp:translate",2,
            if i==0 {abs(spec::rover_wheel_station_z()[0])} else {-abs(spec::rover_wheel_station_z()[0])},tolerance));
        list.push(coordinate(id+"-plane",path,"xformOp:translate",1,0.0,tolerance));
    }
    for side in ["Port","Starboard"]{
        let beam=root+"/UnderBeam"+side;
        list.push(coordinate("GRS-001-beam-span-"+side,beam,"xformOp:scale",0,length,tolerance));
        list.push(coordinate("GRS-001-beam-center-"+side,beam,"xformOp:translate",0,length/2.0,tolerance));
        for i in 0..spec::ramp_tread_count_per_section(){
            let tread=root+"/Tread"+side+(i+1).to_string();
            list.push(coordinate("GRS-001-tread-"+side+i.to_string(),tread,"xformOp:translate",0,
                length*(i.to_float()+0.5)/spec::ramp_tread_count_per_section(),tolerance));
        }
    }
    for guide in guides {
        let path=root+"/"+guide.name;
        let c=check("GRS-001-guide-"+guide.name,"exists",path);c.expected_type="Mesh";list.push(c);
        list.push(coordinate("GRS-001-guide-center-"+guide.name,path,"xformOp:translate",0,length/2.0,tolerance));
        list.push(attribute("GRS-001-guide-contact-"+guide.name,path,"physics:collisionEnabled",true));
        list.push(attribute("GRS-001-guide-hull-"+guide.name,path,"physics:approximation","convexHull"));
        let chord=root+"/SideTrussLowerChord"+guide.side;
        list.push(coordinate("GRS-001-lower-chord-span-"+guide.name,chord,"xformOp:scale",0,length,tolerance));
        list.push(coordinate("GRS-001-lower-chord-center-"+guide.name,chord,"xformOp:translate",0,length/2.0,tolerance));
        let posts=spec::ramp_side_post_count_per_section_per_side();
        for index in 0..posts {
            list.push(coordinate("GRS-001-post-"+guide.name+index.to_string(),
                root+"/SidePost"+guide.side+(index+1).to_string(),"xformOp:translate",0,
                length*index.to_float()/(posts-1.0),tolerance));
        }
        let braces=spec::ramp_side_truss_brace_count_per_side();
        for index in 0..braces {
            list.push(coordinate("GRS-001-brace-"+guide.name+index.to_string(),
                root+"/SideTrussBrace"+guide.side+(index+1).to_string(),"xformOp:translate",0,
                length*(index.to_float()+0.5)/braces,tolerance));
        }
    }
    for datum in [#{name:"deckFrameName",x:0.0,y:"deckAxisYM"},#{name:"foldFrameName",x:length,y:"foldAxisYM"}]{
        let identity=sysml_requirements::native_value(source,own()+datum.name);
        if !sysml_enum_is(identity){throw("Root-section datum identity must be a typed enum");}
        let name=identity.literal;let path=root+"/"+name;
        let c=check("GRS-001-frame-"+name,"exists",path);c.expected_type="Xform";list.push(c);
        list.push(coordinate("GRS-001-frame-x-"+name,path,"xformOp:translate",0,datum.x,tolerance));
        list.push(coordinate("GRS-001-frame-y-"+name,path,"xformOp:translate",1,
            sysml_requirements::number(source,own()+datum.y),tolerance));
        list.push(coordinate("GRS-001-frame-z-"+name,path,"xformOp:translate",2,0.0,tolerance));
    }
    for index in 0..list.len(){list[index].doc_id=selected_doc;}
    #{source:source,checks:list,path:root,package_name:package_name(),verification:verification()}
}

fn fixture_path(){let model=sysml_requirements::model();model.value(own()+"usdPath")}

// Bound one-shot Editor work without changing the interpreter's limits.
fn inspect(doc,root,batch){
    let found=observe(doc,root);
    let count=(found.checks.len()+23)/24;
    if batch<0 || batch>=count {throw("Root-section inspection batch is outside the report");}
    let selected=[];
    for index in batch*24..min((batch+1)*24,found.checks.len()) {selected.push(found.checks[index]);}
    let result=sysml_requirements::evaluate_document(found.source,doc,selected);
    result.batch_count=count;
    result.batch_index=batch;
    result
}
