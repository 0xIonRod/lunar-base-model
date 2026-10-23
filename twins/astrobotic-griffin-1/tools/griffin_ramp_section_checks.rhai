import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;
import "griffin_spec" as spec;
import "griffin_ramp_section_component" as component;
import "lunco://scripting/tools/mechanical_relations" as mechanical;
import "usd_geometry_inspection" as inspection;
import "lunco://scripting/tools/sysml_requirement_checks" as checks;

fn dependencies(){inspection::dependencies()}
fn check(profile,id,kind,path){#{id:id,component:profile.component,requirement:profile.requirement,verification:profile.verification,kind:kind,path:path}}
fn coordinate(profile,id,path,attr,index,expected,tolerance){
    let c=check(profile,id,"attribute_component",path);
    c.attr=attr;c.index=index;c.expected=expected;c.tolerance=tolerance;c
}
fn attribute(profile,id,path,attr,expected){
    let c=check(profile,id,"attribute_equals",path);c.attr=attr;c.expected=expected;c
}
fn observe(doc,root,profile){
    // Static geometry is read from its exact authored document. A spawned
    // static collider need not have an active dynamic-body frame.
    let selected_doc=if doc==() {inspection::document_owner(root)} else {doc};
    let names=[];
    for name in ["lengthM","geometryToleranceM","entryFrameName","exitFrameName","entryAxisYM","exitAxisYM","plateAttachmentRunM","forkWebSizeM","hasExitHinge"]{
        names.push((profile.owner+"::")+name);
    }
    if profile.section_index==0 || profile.section_index==2{names.push(profile.owner+"::deploymentAngleRad");}
    if profile.section_index==0{names.push(profile.owner+"::entryShaftRadiusM");}
    let source=sysml_requirements::source_with_selection(names,
        [profile.package_name+"::"+profile.requirement],[profile.package_name+"::"+profile.verification]);
    let length=sysml_requirements::number(source,(profile.owner+"::")+"lengthM");
    let tolerance=sysml_requirements::number(source,(profile.owner+"::")+"geometryToleranceM");
    if length==() || tolerance==(){throw("Ramp-section source is unavailable");}
    let list=[];
    let width=spec::ramp_contact_track_width_m();
    let thickness=spec::ramp_surface_thickness_m();
    let bevel=if profile.section_index==2 {
        mechanical::planar_horizontal_face_bevel_run(thickness,
            sysml_requirements::number(source,profile.owner+"::deploymentAngleRad"))
    }else{0.0};
    if bevel==() || !bevel.is_finite() || bevel<0.0 || bevel>=length{throw("Toe miter source is invalid");}
    let inlet=if profile.section_index==0{component::entry_bevel(thickness,
        sysml_requirements::number(source,profile.owner+"::deploymentAngleRad"))}else{0.0};
    if inlet==() || !inlet.is_finite() || inlet<0.0 || inlet>=length{throw("Entrance miter source is invalid");}
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
    let connected=fittings_connected(selected_doc,root,profile,source,length,tolerance,owner);
    let bindings=#{connectedFittings:inspection::measurement(connected,owner,"Connected hinge stock is unavailable"),sourceLengthM:#{provider:"source_literal",state:"value",value:length,
        source_revision:source.source_revision,provider_generation:source.source_revision},
        measuredDimensionErrorM:inspection::measurement(maximum_error,owner,"Ramp track canonical metric span is unavailable"),
        toleranceM:#{provider:"source_literal",state:"value",value:tolerance,
            source_revision:source.source_revision,provider_generation:source.source_revision}};
    list.push(sysml_requirements::required_constraint_check(profile.short_name+"-native-metric-span",
        profile.component,profile.requirement,profile.verification,profile.package_name+"::"+profile.constraint,bindings,"typed",0.0));
    if profile.section_index==0{list.push(checks::attribute_check("GRS-001-entry-shaft-radius",profile.component,profile.requirement,profile.verification,
        root+"/HingeBarrel","radius",profile.owner+"::entryShaftRadiusM",0.0));}
    for i in 0..2{
        let path=paths[i];let id=profile.short_name+"-track-"+i.to_string();
        let exists=check(profile,id,"exists",path);exists.expected_type="Mesh";list.push(exists);
        list.push(attribute(profile,id+"-contact",path,"physics:collisionEnabled",true));
        list.push(attribute(profile,id+"-hull",path,"physics:approximation","convexHull"));
        for vertex in [2,3,6,7]{list.push(checks::array_component(id+"-tip-"+vertex.to_string(),
            profile.component,profile.requirement,profile.verification,path,"points",[vertex,0],length-if vertex==3 || vertex==7 {bevel}else{0.0},tolerance));}
        if profile.section_index==0{
            for vertex in [0,1,4,5]{list.push(checks::array_component(id+"-entrance-"+vertex.to_string(),
                profile.component,profile.requirement,profile.verification,path,"points",[vertex,0],
                if vertex==0 || vertex==4{inlet}else{0.0},tolerance));}
        }
        list.push(coordinate(profile,id+"-station",path,"xformOp:translate",2,
            if i==0 {abs(spec::rover_wheel_station_z()[0])} else {-abs(spec::rover_wheel_station_z()[0])},tolerance));
        list.push(coordinate(profile,id+"-plane",path,"xformOp:translate",1,0.0,tolerance));
    }
    for side in ["Port","Starboard"]{
        let beam=root+"/UnderBeam"+side;
        list.push(coordinate(profile,profile.short_name+"-beam-span-"+side,beam,"xformOp:scale",0,length-inlet,tolerance));
        list.push(coordinate(profile,profile.short_name+"-beam-center-"+side,beam,"xformOp:translate",0,(length+inlet)/2.0,tolerance));
        for i in 0..spec::ramp_tread_count_per_section(){
            let tread=root+"/Tread"+side+(i+1).to_string();
            list.push(coordinate(profile,profile.short_name+"-tread-"+side+i.to_string(),tread,"xformOp:translate",0,
                length*(i.to_float()+0.5)/spec::ramp_tread_count_per_section(),tolerance));
        }
    }
    for guide in guides {
        let path=root+"/"+guide.name;
        let c=check(profile,profile.short_name+"-guide-"+guide.name,"exists",path);c.expected_type="Mesh";list.push(c);
        list.push(coordinate(profile,profile.short_name+"-guide-center-"+guide.name,path,"xformOp:translate",0,length/2.0,tolerance));
        list.push(attribute(profile,profile.short_name+"-guide-contact-"+guide.name,path,"physics:collisionEnabled",true));
        list.push(attribute(profile,profile.short_name+"-guide-hull-"+guide.name,path,"physics:approximation","convexHull"));
        let chord=root+"/SideTrussLowerChord"+guide.side;
        list.push(coordinate(profile,profile.short_name+"-lower-chord-span-"+guide.name,chord,"xformOp:scale",0,length,tolerance));
        list.push(coordinate(profile,profile.short_name+"-lower-chord-center-"+guide.name,chord,"xformOp:translate",0,length/2.0,tolerance));
        let posts=spec::ramp_side_post_count_per_section_per_side();
        for index in 0..posts {
            list.push(coordinate(profile,profile.short_name+"-post-"+guide.name+index.to_string(),
                root+"/SidePost"+guide.side+(index+1).to_string(),"xformOp:translate",0,
                length*index.to_float()/(posts-1.0),tolerance));
        }
        let braces=spec::ramp_side_truss_brace_count_per_side();
        for index in 0..braces {
            list.push(coordinate(profile,profile.short_name+"-brace-"+guide.name+index.to_string(),
                root+"/SideTrussBrace"+guide.side+(index+1).to_string(),"xformOp:translate",0,
                length*(index.to_float()+0.5)/braces,tolerance));
        }
    }
    for datum in [#{name:"entryFrameName",x:0.0,y:"entryAxisYM"},#{name:"exitFrameName",x:length,y:"exitAxisYM"}]{
        let identity=sysml_requirements::native_value(source,(profile.owner+"::")+datum.name);
        if !sysml_enum_is(identity){throw("Ramp-section datum identity must be a typed enum");}
        let name=identity.literal;let path=root+"/"+name;
        let c=check(profile,profile.short_name+"-frame-"+name,"exists",path);c.expected_type="Xform";list.push(c);
        list.push(coordinate(profile,profile.short_name+"-frame-x-"+name,path,"xformOp:translate",0,datum.x,tolerance));
        list.push(coordinate(profile,profile.short_name+"-frame-y-"+name,path,"xformOp:translate",1,
            sysml_requirements::number(source,(profile.owner+"::")+datum.y),tolerance));
        list.push(coordinate(profile,profile.short_name+"-frame-z-"+name,path,"xformOp:translate",2,0.0,tolerance));
    }
    let has_exit=sysml_requirements::native_value(source,profile.owner+"::hasExitHinge");
    if has_exit!=true && has_exit!=false{throw("Section exit-hinge topology must be Boolean");}
    if !has_exit{
        for guide in guides{
            for suffix in ["DistalNegativeLug","DistalPositiveLug","ForkWeb"]{
                list.push(checks::not_exists(profile.short_name+"-free-toe-"+guide.pin+suffix,
                    profile.component,profile.requirement,profile.verification,root+"/"+guide.pin+suffix));
            }
        }
    }
    for index in 0..list.len(){list[index].doc_id=selected_doc;}
    #{source:source,checks:list,path:root,package_name:profile.package_name,verification:profile.verification}
}



// Bound one-shot Editor work without changing the interpreter's limits.
fn inspect(doc,root,profile,batch){
    let found=observe(doc,root,profile);
    let count=(found.checks.len()+23)/24;
    if batch<0 || batch>=count {throw("Ramp-section inspection batch is outside the report");}
    let selected=[];
    for index in batch*24..min((batch+1)*24,found.checks.len()) {selected.push(found.checks[index]);}
    let result=sysml_requirements::evaluate_document(found.source,doc,selected);
    result.batch_count=count;
    result.batch_index=batch;
    result
}

// Observe the actual native envelopes, roles and material targets of the
// tongue, two cheeks and heel web. A named datum alone cannot pass this gate.
fn fittings_connected(doc,root,profile,source,length,tolerance,owner){
    if owner==(){return ();}
    let prefix=profile.owner+"::";
    let has_exit=sysml_requirements::native_value(source,prefix+"hasExitHinge");
    if has_exit!=true && has_exit!=false{return ();}
    let entry=sysml_requirements::number(source,prefix+"entryAxisYM");
    let exit=sysml_requirements::number(source,prefix+"exitAxisYM");
    let run=sysml_requirements::number(source,prefix+"plateAttachmentRunM");
    let web=sysml_requirements::number(source,prefix+"forkWebSizeM");
    let width=spec::_sysml_attribute("rampPivotLugWidthM");
    let tongue=spec::_sysml_attribute("rampPivotLugThicknessM");
    let cheek=spec::_sysml_attribute("rampRailWidthM");
    let lower=spec::_sysml_attribute("assemblySideTrussLowerChordCenterYM");
    if entry==() || exit==() || run==() || web==() || width==() || tongue==() || cheek==() || lower==(){return ();}
    let parts=[];let paths=[];
    let entry_support=if entry<0.0 {lower}else{spec::ramp_guide_center_y_m(profile.section_index,run,length)};
    let exit_support=if exit<0.0 {lower}else{spec::ramp_guide_center_y_m(profile.section_index,length-run,length)};
    for guide in spec::ramp_guide_stations(){
        let expected=[#{name:guide.pin+"Lug",a:[0.0,entry],b:[run,entry_support],z:guide.z,stock:tongue}];
        if has_exit{
        for side in [#{name:"Negative",sign:-1.0},#{name:"Positive",sign:1.0}]{
            expected.push(#{name:guide.pin+"Distal"+side.name+"Lug",a:[length,exit],b:[length-run,exit_support],
                z:guide.z+side.sign*(tongue+cheek)/2.0,stock:cheek});
        }
        }
        for part in expected{
            let lo=[min(part.a[0],part.b[0])-width/2.0,min(part.a[1],part.b[1])-width/2.0,part.z-part.stock/2.0];
            let hi=[max(part.a[0],part.b[0])+width/2.0,max(part.a[1],part.b[1])+width/2.0,part.z+part.stock/2.0];
            parts.push(#{path:root+"/"+part.name,kind:"Mesh",lo:lo,hi:hi});
        }
        if has_exit{
        parts.push(#{path:root+"/"+guide.pin+"ForkWeb",kind:"Cube",
            lo:[length-run-web/2.0,exit_support-web/2.0,guide.z-(tongue+2.0*cheek)/2.0],
            hi:[length-run+web/2.0,exit_support+web/2.0,guide.z+(tongue+2.0*cheek)/2.0]});
        }
    }
    let pin_radius=spec::ramp_rail_joint_pin_radius_m();let pin_length=spec::ramp_rail_joint_pin_length_m();
    for guide in spec::ramp_guide_stations(){
        parts.push(#{path:root+"/"+guide.pin,kind:"Cylinder",
            lo:[-pin_radius,entry-pin_radius,guide.z-pin_length/2.0],
            hi:[pin_radius,entry+pin_radius,guide.z+pin_length/2.0]});
    }
    let shaft_radius=if profile.section_index==0{sysml_requirements::number(source,prefix+"entryShaftRadiusM")}else{spec::ramp_section_hinge_barrel_radius_m()};
    let shaft_length=spec::ramp_section_hinge_barrel_length_m();
    parts.push(#{path:root+"/HingeBarrel",kind:"Cylinder",
        lo:[-shaft_radius,entry-shaft_radius,-shaft_length/2.0],
        hi:[shaft_radius,entry+shaft_radius,shaft_length/2.0]});
    for part in parts{paths.push(part.path);}
    let snapshot=query("QueryUsdPrims",#{doc_id:doc,paths:paths,geometry_bounds:true,relationships:true,
        attrs:["physics:collisionEnabled","purpose"]});
    if snapshot==() || snapshot.records==() || snapshot.records.len()!=parts.len()
        || !inspection::same_snapshot(snapshot.records){return ();}
    let first=snapshot.records[0];
    if first.doc_id!=owner.doc_id || first.document_generation!=owner.document_generation
        || first.stage_generation!=owner.stage_generation{return ();}
    for index in 0..parts.len(){
        let record=snapshot.records[index];let expected=parts[index];let bounds=record.geometry_bounds;
        if record.error!=() || record.type_name!=expected.kind || bounds==() || bounds.frame!="canonical_stage"
            || record.attrs["physics:collisionEnabled"]!=false || record.attrs["purpose"]!="render"
            || record.relationships["material:binding"]!=[root+"/Looks/RampStructure"]{return false;}
        for axis in 0..3{
            if abs(bounds.min[axis]-expected.lo[axis])>tolerance
                || abs(bounds.max[axis]-expected.hi[axis])>tolerance{return false;}
        }
    }
    true
}
