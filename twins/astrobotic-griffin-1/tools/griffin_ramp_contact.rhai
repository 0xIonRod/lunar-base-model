// Passive traversal evidence from native cooked stock and live rigid poses.
// No source-pose reconstruction, pose writes, or hinge-target approximation.
import "griffin_spec" as spec;
import "lunco://scripting/tools/sysml_requirements" as requirements;
fn _collider(body,path){
    let state=query("QueryPhysicsState",#{id:find_path(body)});
    if state==() || state.physics_state_ready!=true || state.rigid_body_disabled!=false
        || state.physics_initialization_pending!=false || state.colliders==(){throw("Ramp physics is not ready: "+body);}
    let matches=[];for c in state.colliders{if c.source_path==path{matches.push(c);}}
    if matches.len()!=1{throw("Expected one native track collider: "+path);}
    let c=matches[0];
    if c.body_is_query_body!=true || c.body_relationship_present!=true || c.body_usd_prim_path!=body
        || c.disabled!=false || c.broad_phase_present!=true || c.broad_phase_body_disabled!=false
        || c.scale!=[1.0,1.0,1.0] || c.shape_local_bounds.frame!="collider_local"{
        throw("Ramp collider ownership, scale or admission changed: "+path);
    }c
}
fn _body_point(c,p){vec3_from(c.body_local_translation_m)+qrot(quat_from(c.body_local_rotation_xyzw),p)}
fn _stock(doc,body,path,kind,sign){
    let r=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[],collision_geometry:true});
    let g=r.collision_geometry;let c=_collider(body,path);
    if r.active!=true || g==() || g.shape!="convex_hull" || g.frame!="canonical_stage"
        || g.vertices==() || g.vertices.len()!=8 || g.local_to_stage==(){throw("Native track stock unavailable: "+path);}
    let q=g.local_to_stage.rotation_wxyz;
    let origin=vec3_from(g.local_to_stage.translation_m);
    let inverse=quat_from([-q[1],-q[2],-q[3],q[0]]);
    let points=[];let lo=[1.0e30,1.0e30,1.0e30];let hi=[-1.0e30,-1.0e30,-1.0e30];
    for v in g.vertices{
        let local=qrot(inverse,vec3_from(v)-origin);let a=vec3_array(local);
        for i in 0..3{if !a[i].is_finite(){throw("Nonfinite native ramp vertex");}lo[i]=min(lo[i],a[i]);hi[i]=max(hi[i],a[i]);}
        points.push(vec3_array(_body_point(c,local)));
    }
    let fit=spec::ramp_section_geometry_tolerance_m();
    for i in 0..3{if abs(lo[i]-c.shape_local_bounds.min[i])>fit || abs(hi[i]-c.shape_local_bounds.max[i])>fit{
        throw("Cooked ramp stock disagrees with installed collider bounds: "+path);}}
    let xmin=1.0e30;let xmax=-1.0e30;let ymax=-1.0e30;
    for p in points{xmin=min(xmin,p[0]*sign);xmax=max(xmax,p[0]*sign);ymax=max(ymax,p[1]);}
    let selected=[];
    for p in points{
        if (kind=="toe" && p[0]*sign>(xmin+xmax)/2.0)
            || (kind=="entry" && abs(p[0]*sign-xmin)<0.00001 && abs(p[1]-ymax)<0.00001)
            || (kind=="bridge" && abs(p[0]*sign-xmax)<0.00001 && abs(p[1]-ymax)<0.00001){selected.push(p);}
    }
    if selected.len()!=if kind=="toe"{4}else{2}{throw("Native ramp edge selection is ambiguous: "+path);}
    #{body:body,path:path,points:selected,collider:c,document_generation:r.document_generation,stage_generation:r.stage_generation}
}
fn capture(){
    try{
        let root="/Griffin1SurfaceOps/Lander";
        let source=query("QueryUsdPrim",#{path:root,attrs:[]});
        if source.spawned!=true || source.position_frame!="active_physics"{throw("Active Griffin source identity unavailable");}
        let tracks=[];let bridges=[];
        for bank in 0..2{
            let body=root+"/"+spec::physical_ramp_transition_body_name(if bank==0{"port"}else{"starboard"});let pair=[];
            for name in ["RampTrackPort","RampTrackStarboard"]{pair.push(_stock(source.doc_id,body,body+"/"+name,"bridge",if bank==0{1.0}else{-1.0}));}bridges.push(pair);
        }
        for t in spec::ramp_track_bindings(){
            let body=root+"/"+t.body;let name=if t.track==0{"RampTrackPort"}else{"RampTrackStarboard"};
            tracks.push(#{name:t.body,bank:t.bank,
                entry:_stock(source.doc_id,body,body+"/DeckSection/"+name,"entry",1.0),
                toe:_stock(source.doc_id,body+"/MiddleSection/ToeSection",body+"/MiddleSection/ToeSection/"+name,"toe",1.0)});
        }
        for t in tracks{for shape in [t.entry,t.toe]{if shape.document_generation!=source.document_generation || shape.stage_generation!=source.stage_generation{throw("Ramp source changed during capture");}}}
        for pair in bridges{for shape in pair{if shape.document_generation!=source.document_generation || shape.stage_generation!=source.stage_generation{throw("Transition source changed during capture");}}}
        return #{ok:true,doc_id:source.doc_id,document_generation:source.document_generation,stage_generation:source.stage_generation,
            source_revision:requirements::model().source_revision,tracks:tracks,bridges:bridges}
    }catch(error){return #{ok:false,error:error.to_string()};}
}
fn _world_edge(stock){
    let c=_collider(stock.body,stock.path);let old=stock.collider;
    let fit=spec::ramp_section_geometry_tolerance_m();
    if vlen(vec3_from(c.body_local_translation_m)-vec3_from(old.body_local_translation_m))>fit
        || c.body_local_rotation_xyzw!=old.body_local_rotation_xyzw || c.shape_local_bounds!=old.shape_local_bounds{
        throw("Installed collider frame or stock changed: "+stock.path);}
    let position=world_pos3(find_path(stock.body));let rotation=world_rotation_quat(find_path(stock.body));
    if position==() || rotation==(){throw("Live ramp body pose unavailable");}
    if vlen(position+qrot(rotation,vec3_from(c.body_local_translation_m))-vec3_from(c.physics_position_m))>fit{
        throw("Ramp body/collider physics frames disagree: "+stock.path);}
    let result=[];for p in stock.points{
        let world=position+qrot(rotation,vec3_from(p));
        for v in vec3_array(world){if !v.is_finite(){throw("Nonfinite live ramp vertex");}}
        result.push(world);
    }result
}
fn _distance(p,a,b){let d=b-a;let length=vdot(d,d);if length<=0.0{throw("Degenerate deck edge");}let u=max(0.0,min(1.0,vdot(p-a,d)/length));vlen(p-a-d*u)}
fn observe(cache){
    try{
        if cache==() || cache.ok!=true || cache.tracks==() || cache.tracks.len()!=4
            || cache.bridges==() || cache.bridges.len()!=2{throw("Complete native ramp geometry was not captured");}
        let r=query("QueryUsdPrim",#{path:"/Griffin1SurfaceOps/Lander",attrs:[]});
        if r.doc_id!=cache.doc_id || r.spawned!=true || r.position_frame!="active_physics"
            || r.document_generation!=cache.document_generation || r.stage_generation!=cache.stage_generation
            || requirements::model().source_revision!=cache.source_revision{throw("Ramp source changed after contact capture");}
        let bridges=[];for pair in cache.bridges{if pair.len()!=2{throw("Both deck bridge tracks are required");}let edges=[];for stock in pair{edges.push(_world_edge(stock));}bridges.push(edges);}
        let tolerance=f64_from(spec::physical_ramp_terrain_contact_tolerance_m());
        let interface=f64_from(spec::physical_ramp_traversal_interface_tolerance_m());let width=f64_from(spec::rover_wheel_width_m());
        if tolerance==() || interface==() || width==() || tolerance<=0.0 || interface<=0.0 || width<=0.0 || !tolerance.is_finite() || !interface.is_finite() || !width.is_finite(){throw("Traversal observation policy unavailable");}
        let rows=[];let ready=true;
        for t in cache.tracks{
            let tip=_world_edge(t.toe);let minimum=1.0e30;let corners=[];
            for p in tip{
                let terrain=query("TerrainHeight",#{x:p.x,z:p.z});
                if terrain==() || terrain.found!=true || !terrain.height.is_finite(){throw("Actual ramp toe has no retained DEM surface");}
                let gap=p.y-terrain.height;minimum=min(minimum,gap);corners.push(#{point_m:vec3_array(p),clearance_m:gap});
            }
            let entry=_world_edge(t.entry);let center=(entry[0]+entry[1])*0.5;let span=vlen(entry[1]-entry[0]);
            if span<width{throw("Installed ramp tread is narrower than the rover tire");}
            let across=(entry[1]-entry[0])*(width/(2.0*span));let seam=0.0;
            for p in [center-across,center,center+across]{let nearest=1.0e30;
                for edge in bridges[t.bank]{nearest=min(nearest,_distance(p,edge[0],edge[1]));}seam=max(seam,nearest);}
            let contact=minimum>=-tolerance && minimum<=tolerance;let continuous=seam<=interface;
            ready=ready && contact && continuous;
            rows.push(#{track:t.name,minimum_toe_clearance_m:minimum,entry_gap_m:seam,toe_contact:contact,deck_continuous:continuous,toe_corners:corners});
        }
        return #{ok:true,ready:ready,tolerance_m:tolerance,interface_tolerance_m:interface,tire_width_m:width,tracks:rows,
            source_revision:cache.source_revision,document_generation:cache.document_generation,stage_generation:cache.stage_generation}
    }catch(error){return #{ok:false,ready:false,error:error.to_string()};}
}
