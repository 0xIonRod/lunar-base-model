// Shared Griffin parametric mesh construction used by both the Editor
// builder and the read-only requirement observer. The source datums are
// inputs; this module supplies the deterministic geometric realization.

fn scalar_is_finite(value) {
    let scalar = f64_from(value);
    if scalar == () { return false; }
    scalar == scalar && scalar < 1.7976931348623157e308
        && scalar > -1.7976931348623157e308
}

// Build a watertight centered box as a Mesh using native f64 profile
// extrusion. The caller may position it by supplying a component-local centre.
fn rectangular_prism_geometry(center, dimensions) {
    if !vec3_is_native(center) || !vec3_is_finite(center)
        || !vec3_is_native(dimensions) || !vec3_is_finite(dimensions)
        || dimensions.x <= 0.0 || dimensions.y <= 0.0 || dimensions.z <= 0.0 {
        return #{ok: false, error: "rectangular prism requires finite center and positive dimensions"};
    }
    let half_x = dimensions.x / 2.0;
    let half_z = dimensions.z / 2.0;
    let profile = [vec2(-half_x, -half_z), vec2(half_x, -half_z),
        vec2(half_x, half_z), vec2(-half_x, half_z)];
    let mesh = extrude_profile(profile, dimensions.y, profile_plane_xz());
    let points = [];
    for point in mesh.points {
        points.push([point.x + center.x, point.y + center.y, point.z + center.z]);
    }
    #{ok: true, points: points, face_counts: mesh.face_vertex_counts,
      face_indices: mesh.face_vertex_indices}
}

// Join independently generated closed meshes into one USD Mesh without
// changing their local geometry or storing mesh values as numeric strings.
fn merge_mesh_geometries(parts) {
    if !array_is(parts) || parts.is_empty() {
        return #{ok: false, error: "mesh merge requires at least one geometry"};
    }
    let points = [];
    let face_counts = [];
    let face_indices = [];
    for part in parts {
        if part == () || part.ok != true || part.points == ()
            || part.face_counts == () || part.face_indices == () {
            return #{ok: false, error: "mesh merge input is incomplete"};
        }
        let base = points.len();
        for point in part.points { points.push(point); }
        for count in part.face_counts { face_counts.push(count); }
        for index in part.face_indices { face_indices.push(index + base); }
    }
    #{ok: true, points: points, face_counts: face_counts,
      face_indices: face_indices}
}

fn perimeter_beam_geometry(stations, ring_y, section) {
    if !array_is(stations) || stations.len() < 3
        || !array_is(ring_y) || ring_y.len() == 0
        || section == () || section <= 0.0 {
        return #{ok: false, error: "perimeter mesh requires stations, ring planes, and positive section"};
    }
    for station in stations {
        if !vec3_is_native(station) || !vec3_is_finite(station) {
            return #{ok: false, error: "perimeter stations must be finite typed Vec3 values"};
        }
    }
    for center_y in ring_y {
        if !scalar_is_finite(center_y) {
            return #{ok: false, error: "perimeter ring planes must be finite values"};
        }
    }

    let points = [];
    let face_counts = [];
    let face_indices = [];
    let half_section = section / 2.0;
    for ring_index in 0..ring_y.len() {
        for edge in 0..stations.len() {
            let start_index = edge;
            let end_index = (edge + 1) % stations.len();
            let ax = stations[start_index].x;
            let az = stations[start_index].z;
            let bx = stations[end_index].x;
            let bz = stations[end_index].z;
            let dx = bx - ax;
            let dz = bz - az;
            let length = (dx * dx + dz * dz).sqrt();
            if length <= 0.0 {
                return #{ok: false, error: "perimeter contains a zero-length edge"};
            }
            let tx = dx / length;
            let tz = dz / length;
            let nx = -tz;
            let nz = tx;
            let mx = (ax + bx) / 2.0;
            let mz = (az + bz) / 2.0;
            let half_length = length / 2.0;
            let cy = ring_y[ring_index];
            let base = points.len();
            for vertex in [
                [-tx * half_length - nx * half_section, cy - half_section, -tz * half_length - nz * half_section],
                [ tx * half_length - nx * half_section, cy - half_section,  tz * half_length - nz * half_section],
                [ tx * half_length - nx * half_section, cy + half_section,  tz * half_length - nz * half_section],
                [-tx * half_length - nx * half_section, cy + half_section, -tz * half_length - nz * half_section],
                [-tx * half_length + nx * half_section, cy - half_section, -tz * half_length + nz * half_section],
                [ tx * half_length + nx * half_section, cy - half_section,  tz * half_length + nz * half_section],
                [ tx * half_length + nx * half_section, cy + half_section,  tz * half_length + nz * half_section],
                [-tx * half_length + nx * half_section, cy + half_section, -tz * half_length + nz * half_section]
            ] {
                points.push([mx + vertex[0], vertex[1], mz + vertex[2]]);
            }
            for face in 0..6 { face_counts.push(4); }
            for index in [0, 4, 7, 3, 1, 2, 6, 5, 0, 3, 2, 1,
                4, 5, 6, 7, 0, 1, 5, 4, 3, 7, 6, 2] {
                face_indices.push(base + index);
            }
        }
    }
    #{ok: true, points: points, face_counts: face_counts,
      face_indices: face_indices, face_vertex_counts: face_counts,
      face_vertex_indices: face_indices}
}

fn tank_support_perimeter_geometry(profile, radius, center_y, section) {
    if !array_is(profile) || profile.len() < 3
        || radius == () || radius <= 0.0 || center_y == ()
        || section == () || section <= 0.0 {
        return #{ok: false, error: "tank-support profile requires typed points and positive radius/section"};
    }
    let stations = [];
    for point in profile {
        if !vec2_is_native(point) || !vec2_is_finite(point) {
            return #{ok: false, error: "tank-support profile requires finite typed Vec2 values"};
        }
        stations.push(vec3(point.x * radius, 0.0, point.y * radius));
    }
    let levels = if array_is(center_y) { center_y } else { [center_y] };
    perimeter_beam_geometry(stations, levels, section)
}

// A continuous mitered ring for the source's regular clipped-square profile.
// Scaling the inner profile reduces every edge's apothem by the stock width;
// it avoids square beam ends projecting beyond the bus chamfers.
fn octagonal_ring_geometry(profile, radius, center_y, width, height) {
    if !array_is(profile) || profile.len()!=8 || radius<=width
        || width<=0.0 || height<=0.0 || !scalar_is_finite(center_y) {
        return #{ok:false,error:"octagonal ring requires eight profile vertices and positive stock dimensions"};
    }
    let points=[];let counts=[];let indices=[];
    for y in [center_y-height/2.0,center_y+height/2.0] {
        for r in [radius,radius-width] {
            for p in profile {
                if !vec2_is_native(p) || !vec2_is_finite(p) {
                    return #{ok:false,error:"octagonal ring profile must be finite typed Vec2 values"};
                }
                points.push([p.x*r,y,p.y*r]);
            }
        }
    }
    for i in 0..8 {
        let j=(i+1)%8;
        for face in [[i,i+16,j+16,j], [i+8,j+8,j+24,i+24],
            [i,j,j+8,i+8], [i+16,i+24,j+24,j+16]] {
            counts.push(4);for v in face {indices.push(v);}
        }
    }
    #{ok:true,points:points,face_counts:counts,face_indices:indices}
}


// The positive-X/Z brace uses Rz(-tilt) * Rx(-tilt). Other braces
// mirror these coordinates. Anchor its lower endpoint on the pad plane;
// derive its center and vessel contact from the same actual rotation.
fn tank_brace_datum(pad_top_y, offset, length, tilt_deg) {
    let a = tilt_deg * 3.141592653589793 / 180.0;
    let direction = [-a.sin() * a.cos(), a.cos() * a.cos(), -a.sin()];
    #{center: [offset + direction[0] * length / 2.0,
        pad_top_y + direction[1] * length / 2.0,
        offset + direction[2] * length / 2.0],
      tip: [offset + direction[0] * length,
        pad_top_y + direction[1] * length,
        offset + direction[2] * length]}
}


// Signed distance to the nearest edge half-plane of a convex X/Z polygon.
// Positive means inside, so subtracting a circular part radius measures its
// conservative clearance. Reversing polygon winding preserves the result.
fn convex_polygon_clearance_xz(point, polygon) {
    if polygon.len()<3 {return ();}
    let area=0.0;
    for i in 0..polygon.len() {let a=polygon[i];let b=polygon[(i+1)%polygon.len()];area+=a.x*b.z-b.x*a.z;}
    if area.abs()<=1.0e-12 {return ();}
    let sign=if area>0.0 {1.0} else {-1.0};
    let minimum=1.0e30;
    for i in 0..polygon.len() {
        let a=polygon[i];let b=polygon[(i+1)%polygon.len()];let dx=b.x-a.x;let dz=b.z-a.z;
        let length=(dx*dx+dz*dz).sqrt();if length<=1.0e-12 {return ();}
        let distance=sign*(dx*(point.z-a.z)-dz*(point.x-a.x))/length;
        if distance<minimum {minimum=distance;}
    }
    minimum
}


// One row of thin, corner-clipped solar cells. Native extrusion owns topology;
// a row is one render mesh, rather than one entity/draw per cell.
fn solar_cell_row_geometry(layout, row, center_y, thickness, gap, corner) {
    if layout==() || row<0 || row>=layout.rows || gap<=0.0
        || gap>=layout.pitch_z_m || corner<=0.0
        || corner*2.0>=layout.pitch_z_m-gap || thickness<=0.0 {
        return #{ok:false,error:"solar row dimensions incomplete"};
    }
    let sx=layout.scale_x;let half_x=(layout.pitch_m-gap)/2.0;
    let half_z=(layout.pitch_z_m-gap)/2.0;
    let profile=[vec2((-half_x+corner)/sx,-half_z),vec2((half_x-corner)/sx,-half_z),
        vec2(half_x/sx,-half_z+corner),vec2(half_x/sx,half_z-corner),
        vec2((half_x-corner)/sx,half_z),vec2((-half_x+corner)/sx,half_z),
        vec2(-half_x/sx,half_z-corner),vec2(-half_x/sx,-half_z+corner)];
    let cell=extrude_profile(profile,thickness,profile_plane_xz());let pieces=[];
    let z=-layout.cell_depth_m/2.0+(row+0.5)*layout.pitch_z_m;
    for column in 0..layout.columns {
        let x=-layout.local_cell_width_m/2.0+(column+0.5)*layout.pitch_m/sx;
        if !solar_contour_contains(layout.contour,column+0.5,row+0.5) {continue;}
        let points=[];
        for point in cell.points {points.push([point.x+x,point.y+center_y,point.z+z]);}
        pieces.push(#{ok:true,points:points,face_counts:cell.face_vertex_counts,face_indices:cell.face_vertex_indices});
    }
    merge_mesh_geometries(pieces)
}

// Contours are simple, source-owned orthogonal polygons in cell-pitch units.
fn solar_contour_contains(contour, x, z) {
    let inside=false;let previous=contour[contour.len()-1];
    for point in contour {
        if (point.z>z)!=(previous.z>z)
            && x<(previous.x-point.x)*(z-point.z)/(previous.z-point.z)+point.x {inside=!inside;}
        previous=point;
    }
    inside
}

fn solar_contour_geometry(layout, width, center_y, thickness) {
    // Native extrusion accepts convex profiles. Partition the orthogonal
    // source contour at its row boundaries into closed rectangular bands.
    let levels=[];
    for point in layout.contour {if !levels.contains(point.z) {levels.push(point.z);}}
    levels.sort();let pieces=[];
    for band in 0..levels.len()-1 {
        let middle=(levels[band]+levels[band+1])/2.0;let crosses=[];
        let previous=layout.contour[layout.contour.len()-1];
        for point in layout.contour {
            if (point.z>middle)!=(previous.z>middle) {
                crosses.push(point.x+(previous.x-point.x)*(middle-point.z)/(previous.z-point.z));
            }
            previous=point;
        }
        crosses.sort();
        if crosses.len()%2!=0 {return #{ok:false,error:"solar contour has unpaired edges"};}
        for pair in 0..crosses.len()/2 {
            let x0=-width/2.0+crosses[pair*2]*width/layout.columns;
            let x1=-width/2.0+crosses[pair*2+1]*width/layout.columns;
            let z0=-layout.cell_depth_m/2.0+levels[band]*layout.pitch_z_m;
            let z1=-layout.cell_depth_m/2.0+levels[band+1]*layout.pitch_z_m;
            pieces.push(rectangular_prism_geometry(vec3((x0+x1)/2.0,center_y,(z0+z1)/2.0),vec3(x1-x0,thickness,z1-z0)));
        }
    }
    merge_mesh_geometries(pieces)
}

fn solar_contour_frame_geometry(layout, width, section) {
    let stations=[];let cell_width=layout.local_cell_width_m;
    for point in layout.contour {
        let x=-cell_width/2.0+point.x*cell_width/layout.columns;
        let z=-layout.cell_depth_m/2.0+point.z*layout.pitch_z_m;
        if point.x==0.0 {x=-width/2.0+section/2.0;}
        if point.x==layout.columns.to_float() {x=width/2.0-section/2.0;}
        if point.z==0.0 {z=-layout.frame_depth_m/2.0+section/2.0;}
        if point.z==layout.rows.to_float() {z=layout.frame_depth_m/2.0-section/2.0;}
        stations.push(vec3(x,0.0,z));
    }
    perimeter_beam_geometry(stations,[0.0],section)
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


// Shared SI section for an open, thin bell shell. The caller owns the sourced
// engineering dimensions; the profile includes both surfaces and annular rims.
fn hollow_bell_profile(throat, exit, height, wall, contour, axial) {
    let profile=[];
    for i in 0..(axial+1) {
        let station=(i.to_float()/axial.to_float()) ** 2.0;
        profile.push([throat+(exit-throat)*(station ** contour),height*(0.5-station)]);
    }
    for i in 0..(axial+1) {
        let station=((axial-i).to_float()/axial.to_float()) ** 2.0;
        profile.push([throat+(exit-throat)*(station ** contour)-wall,height*(0.5-station)]);
    }
    profile
}
