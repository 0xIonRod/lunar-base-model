import "griffin_geometry" as geometry;

// Integrate the actual upper cap polygons. Multiplying by scale_x restores
// installed square metres after the renderer's inverse local-width scaling.
fn upper_face_area(mesh,scale_x) {
    let top=mesh.points[0][1];
    for p in mesh.points {top=max(top,p[1]);}
    let area=0.0;let offset=0;
    for count in mesh.face_counts {
        let on_top=true;let twice=0.0;
        let previous=mesh.points[mesh.face_indices[offset+count-1]];
        for i in 0..count {
            let p=mesh.points[mesh.face_indices[offset+i]];
            if p[1]!=top {on_top=false;}
            twice+=previous[0]*p[2]-p[0]*previous[2];
            previous=p;
        }
        if on_top {area+=abs(twice)*0.5*scale_x;}
        offset+=count;
    }
    area
}

fn regression() {
    // One narrow, non-square cell installed at a non-unit horizontal scale.
    let layout=#{columns:1,rows:1,pitch_m:0.06,pitch_z_m:0.10,scale_x:0.5,
        local_cell_width_m:0.12,cell_depth_m:0.10,
        contour:[vec3(0.0,0.0,0.0),vec3(1.0,0.0,0.0),
                 vec3(1.0,0.0,1.0),vec3(0.0,0.0,1.0)]};
    let mesh=geometry::solar_cell_row_geometry(layout,0,0.0,0.001,0.01,0.005);
    if !mesh.ok {return mesh;}
    let measured=upper_face_area(mesh,layout.scale_x);
    let wide_clip=geometry::solar_cell_row_geometry(layout,0,0.0,0.001,0.01,0.026);
    let wide_gap=geometry::solar_cell_row_geometry(layout,0,0.0,0.001,0.061,0.001);
    layout.pitch_z_m=0.04;
    let tall_clip=geometry::solar_cell_row_geometry(layout,0,0.0,0.001,0.01,0.016);
    #{ok:abs(measured-0.00445)<1.0e-12 && !wide_clip.ok && !wide_gap.ok && !tall_clip.ok,
      area_m2:measured,rejected_x_clip:!wide_clip.ok,rejected_x_gap:!wide_gap.ok,
      rejected_z_clip:!tall_clip.ok}
}
