// Run in the landed Griffin tracking view, before requesting FLIP release.

fn simulation_dependencies(me,ctx) {
    let spans=[];
    for side in ["Left","Right"] {spans.push(find_path("/Griffin1SurfaceOps/Lander/LiveTethers/"+side+"/Span"));}
    #{modelica_entities:[],entity_reads:spans,entity_writes:spans,
      query_reads:["ScriptingCatalog","QueryUsdPrim","InspectUsdCurveView"],required_inputs:[]}
}

fn on_start(me,ctx) {
    this.rows=[];
    for side in ["Left","Right"] {
        let path="/Griffin1SurfaceOps/Lander/LiveTethers/"+side;
        this.rows.push(#{doc:ctx.doc_id,root:find_path(path),span:find_path(path+"/Span")});
    }
    this.phase="parked";
    this.start=sim_tick();
    this.revisions=();
    this.done=false;
}

fn on_tick(me,ctx) {
    if this.done || sim_tick()%6!=0 {return;}
    try {
        if sim_tick()-this.start>600 {throw("Timed out waiting for "+this.phase+" ribbon geometry");}
        if this.rows.len()!=2 {throw("Both Griffin ribbon views must be present");}
        let revisions=[];
        for row in this.rows {
            let view=query("InspectUsdCurveView",#{doc_id:row.doc,entity_id:row.span});
            if view.error!="" {throw(view.error);}
            if view.state!="ready" || view.local_visibility=="hidden" || view.result_segment_count<=0 {return;}
            revisions.push(view.applied_revision);
        }
        if this.phase=="parked" {
            if this.revisions==() {this.revisions=revisions;this.parked_at=sim_tick();return;}
            if this.revisions!=revisions {throw("Parked ribbons were rebuilt at tick "+sim_tick());}
            if sim_tick()-this.parked_at<60 {return;}
            let row=this.rows[0];
            let attrs=query("QueryUsdPrim",#{doc_id:row.doc,path:usd_path(row.span),attrs:["widths"]});
            let cleared=cmd("UpdateUsdCurveView",#{doc_id:row.doc,root_entity_id:row.root,curve_entity_id:row.span,
                points:[],normals:[],width_m:attrs.attrs.widths[0],projection:"Spatial"});
            if cleared.ok!=true {throw("Could not clear the displayed left ribbon");}
            this.phase="restored";
        } else if this.phase=="restored" {
            if revisions[0]<=this.revisions[0] {return;}
            this.revisions=revisions;
            let request=griffin_surface_ops::request_rover_release();
            if request.ok!=true {throw("FLIP release was rejected");}
            this.phase="deploying";
        } else {
            if revisions[0]<=this.revisions[0] || revisions[1]<=this.revisions[1] {return;}
            report_verdict([t_true(true,"Both parked ribbons retained their applied revisions for 60 ticks"),
                            t_true(true,"Clearing a span caused it to be displayed again"),
                            t_true(true,"Both ribbons updated on deployment")],
                           "GRIFFIN PARKED TETHER VIEWS","GRIFFIN_PARKED_TETHER_VIEWS");
            this.done=true;
        }
    } catch(error) {
        report_verdict([t_true(false,error.to_string())],"GRIFFIN PARKED TETHER VIEWS","GRIFFIN_PARKED_TETHER_VIEWS");
        this.done=true;
    }
}
