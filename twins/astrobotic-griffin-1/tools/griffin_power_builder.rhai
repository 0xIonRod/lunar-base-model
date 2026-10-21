import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;
import "griffin_geometry" as geometry;

fn study() {"GriffinPowerThermalRequirements::GriffinPowerThermalStudy::"}

// Convert only at the USD/Modelica parameter boundary. A suffix spelling is
// never a unit: the SysML resolver must supply an exact native SI definition.
fn si(model, name, dimension) {
    let value=model.value(name);
    if !sysml_quantity_is(value) || value.measurement_reference==() {
        throw("unit-bearing source property required: "+name);
    }
    let unit=value.measurement_reference.engineering_unit;
    if unit==() || unit.dimension!=dimension || unit.scale_is_exact!=true {
        throw("source property has no exact unit of the required dimension: "+name);
    }
    quantity_si_value(quantity(value.value,unit))
}
fn number(model, name) {
    let value=f64_from(model.value(name));
    if value==() || !value.is_finite() {throw("finite scalar required: "+name);}
    value
}
fn configuration() {
    let model=sysml_requirements::model();
    if !sysml_model_is(model) {throw("Griffin source model unavailable");}
    let selection=model.attribute(study()+"photovoltaicMaterial");
    if selection==() || selection.declared_type==() || selection.declared_type.resolved_type==() {
        throw("typed photovoltaic material selection unavailable");
    }
    let material=selection.declared_type.resolved_type.qualified_name+"::";
    let voltage=[2,1,-3,-1,0,0,0];let current=[0,0,0,1,0,0,0];
    let temperature=[0,0,0,0,1,0,0];let power=[2,1,-3,0,0,0,0];
    let vm=si(model,material+"maximumPowerVoltage",voltage);
    let im=si(model,material+"maximumPowerCurrent",current);
    let dv=si(model,material+"voltageTemperatureSlope",[2,1,-3,-1,-1,0,0]);
    let di=si(model,material+"currentTemperatureSlope",[0,0,0,1,-1,0,0]);
    if vm<=0.0 || im<=0.0 {throw("positive reference maximum-power point required");}
    let config=#{material:material,source_revision:model.source_revision,
        efficiency:number(model,material+"referenceEfficiency"),
        absorptivity:number(model,material+"absorptivityUpperBound"),
        reference_temperature:si(model,material+"referenceTemperature",temperature),
        maximum_temperature:si(model,material+"maximumTemperature",temperature),
        reference_irradiance:si(model,material+"referenceIrradiance",[0,1,-3,0,0,0,0]),
        power_temperature_coefficient:dv/vm+di/im,
        bus_voltage:si(model,study()+"busVoltage",voltage),
        // The shared Battery contract uses ampere-hours, rather than coulombs.
        capacity_ah:si(model,study()+"batteryChargeCapacity",[0,0,1,1,0,0,0])/3600.0,
        battery_resistance:si(model,study()+"batteryResistance",[2,1,-3,-2,0,0,0]),
        initial_soc:number(model,study()+"initialStateOfCharge"),
        baseline_power:si(model,study()+"avionicsBaselinePower",power),
        guidance_power:si(model,study()+"avionicsGuidancePower",power),
        voltage_off:si(model,study()+"avionicsVoltageOff",voltage),
        voltage_on:si(model,study()+"avionicsVoltageOn",voltage),
        heat_capacity:si(model,study()+"panelHeatCapacity",[2,1,-2,0,-1,0,0]),
        initial_temperature:si(model,study()+"panelInitialTemperature",temperature),
        maximum_cooling:si(model,study()+"maximumPanelCooling",power),
        minimum_temperature:si(model,study()+"minimumCoolantTemperature",temperature),
        conductance:si(model,study()+"coolingConductance",[2,1,-3,0,-1,0,0]),
        duration:si(model,study()+"observationDuration",[0,0,1,0,0,0,0]),
        power_tolerance:si(model,study()+"powerResidualTolerance",power),
        temperature_tolerance:number(model,study()+"temperatureLawTolerance")};
    config.area_tolerance=si(model,study()+"collectingAreaTolerance",[2,0,0,0,0,0,0]);
    config.sample_offset=si(model,study()+"visibilitySampleOffset",[1,0,0,0,0,0,0]);
    config.normal=model.value("GriffinSolarRequirements::GriffinSolarArrayAssembly::illuminatedFaceNormal");
    if !vec3_is_native(config.normal) || abs(config.normal.x)>1.0e-12
        || abs(config.normal.y-1.0)>1.0e-12 || abs(config.normal.z)>1.0e-12 {
        throw("the installed cell field requires the source-owned outward +Y face");
    }
    if config.efficiency<=0.0 || config.efficiency>config.absorptivity
        || config.absorptivity>1.0 || config.power_temperature_coefficient>=0.0
        || config.heat_capacity<=0.0 || config.maximum_cooling<0.0 || config.conductance<=0.0 {
        throw("invalid selected photovoltaic/thermal study parameters");
    }
    config
}

// The same contour/cell layout as the rendered rows. Each clipped rectangle
// loses four right triangles; the omitted grid sites contribute no area.
fn panel_geometry(index) {
    let layout=griffin_spec::solar_installed_cell_layout(index);
    if layout==() {throw("panel cell layout unavailable");}
    let gap=griffin_spec::solar_component_number("cellGapM");
    let corner=griffin_spec::solar_component_number("cellCornerClipM");
    let cell_area=(layout.pitch_m-gap)*(layout.pitch_z_m-gap)-2.0*corner*corner;
    if cell_area<=0.0 {throw("positive active cell area required");}
    let centers=[];
    let thickness=griffin_spec::solar_component_number("cellThicknessM");
    let first_row=geometry::solar_cell_row_geometry(layout,0,
        griffin_spec::solar_component_number("cellOffsetYM")+thickness,thickness,gap,corner);
    if !first_row.ok || first_row.points.is_empty() {throw("collecting-face geometry unavailable");}
    let height=-1.0e30;
    for point in first_row.points {height=max(height,point[1]);}
    let model=sysml_requirements::model();
    height+=si(model,study()+"visibilitySampleOffset",[1,0,0,0,0,0,0]);
    for row in 0..layout.rows {for column in geometry::solar_cell_row_columns(layout,row) {
            centers.push([(-layout.columns/2.0+column+0.5)*layout.pitch_m/layout.scale_x,
                height,
                (-layout.rows/2.0+row+0.5)*layout.pitch_z_m]);
    }}
    if centers.len()<9 {throw("nine active-cell visibility strata required");}
    let samples=[];
    for i in 0..9 {samples.push(centers[((i+0.5)*centers.len().to_float()/9.0).floor().to_int()]);}
    #{area:cell_area*centers.len().to_float(),cell_count:centers.len(),samples:samples}
}

fn _add(edit, parent, name, kind) {
    #{AddPrim:#{edit_target:edit,parent_path:parent,name:name,type_name:kind,reference:(),reference_prim_path:()}}
}
fn _value(edit, path, name, kind, value) {
    #{SetAttribute:#{edit_target:edit,path:path,name:name,type_name:kind,value:value}}
}
fn _scalar(edit, path, name, value) {_value(edit,path,name,"double",value.to_string())}
fn _wire(edit, path, name, kind, sources) {
    #{SetConnection:#{edit_target:edit,path:path,name:name,type_name:kind,sources:sources}}
}
fn _program(edit, parent, name, source) {
    let path=parent+"/"+name;
    [_add(edit,parent,name,"Scope"),
     #{SetApiSchemas:#{edit_target:edit,path:path,schemas:["LunCoProgramAPI"]}},
     _value(edit,path,"info:implementationSource","token","\"sourceAsset\""),
     _value(edit,path,"info:sourceAsset","asset","@lunco://models/LunCo/"+source+".mo@"),
     _value(edit,path,"lunco:program:realtimeSafe","bool","true")]
}
fn _outputs(edit, path, names) {
    let ops=[];for name in names {ops.push(_scalar(edit,path,"outputs:"+name,0.0));}ops
}
fn _exports(edit, net, component, prefix, names) {
    let ops=[];
    for name in names {
        ops.push(_wire(edit,net,"outputs:"+prefix+name,"double",
            [component+".outputs:"+name]));
    }
    ops
}

// Prepare bounded, uncommitted parts for review. Combine their typed ops at
// the document boundary and apply the complete closed network atomically; an
// individual part must never be mounted as an unconnected live participant.
fn network_part_plan(doc, edit, root, part) {
    try {
        if part < -1 || part > 3 {throw("unknown network preparation part");}
        let c=configuration();let ops=[];let net=root+"/ElectricalPower";
        ops.push(_add(edit,root,"ElectricalPower","Scope"));
        ops.push(#{SetApiSchemas:#{edit_target:edit,path:net,schemas:["CollectionAPI:components"]}});
        ops.push(_value(edit,net,"collection:components:expansionRule","token","\"explicitOnly\""));
        let battery=net+"/Battery";let load=net+"/AvionicsLoad";
        if part == -1 {
        ops+=_program(edit,net,"Battery","Electrical/Battery");
        ops.push(_value(edit,battery,"connectors:p","token","\"\""));
        for p in [#{name:"voltage_nom",value:c.bus_voltage},#{name:"capacity",value:c.capacity_ah},
            #{name:"R_internal",value:c.battery_resistance},#{name:"soc_init",value:c.initial_soc}] {
            ops.push(_scalar(edit,battery,"parameters:"+p.name,p.value));
        }
        ops+=_outputs(edit,battery,["terminal_voltage_v","terminal_current_a","net_power_w","stored_power_w","stored_energy_j","heat_w","soc_out"]);
        ops+=_exports(edit,net,battery,"battery_",["terminal_voltage_v","terminal_current_a","net_power_w","stored_power_w","stored_energy_j","heat_w","soc_out"]);
        ops+=_program(edit,net,"AvionicsLoad","Electrical/OnboardComputer");
        ops.push(_value(edit,load,"connectors:p","token","\"\""));
        for p in [#{name:"p_baseline_w",value:c.baseline_power},#{name:"p_gnc_w",value:c.guidance_power},
            #{name:"voltage_off_v",value:c.voltage_off},#{name:"voltage_on_v",value:c.voltage_on}] {
            ops.push(_scalar(edit,load,"parameters:"+p.name,p.value));
        }
        // Requested guidance processing remains a load even when its supply is
        // insufficient; the load's UVLO owns actual powered availability.
        ops.push(_scalar(edit,load,"inputs:gnc_active",1.0));
        ops+=_outputs(edit,load,["powered","power_draw_w","heat_w","processing_active"]);
        ops+=_exports(edit,net,load,"avionics_",["powered","power_draw_w","heat_w","processing_active"]);
        }
        let members=[battery,load];let pins=[load+".connectors:p"];let panels=[];
        let names=griffin_spec::solar_array_names();
        let selected=if part>=0 && part<3 {[part]} else {[]};
        for index in selected {
            let g=panel_geometry(index);let name=names[index];let parent=root+"/"+name;
            let probe=parent+"/PowerEnvironment";
            ops.push(_add(edit,parent,"PowerEnvironment","Points"));
            ops.push(#{SetApiSchemas:#{edit_target:edit,path:probe,schemas:["LunCoEnvironmentProbeAPI"]}});
            let points="[";
            for i in 0..g.samples.len() {
                if i>0 {points+=", ";}let p=g.samples[i];
                points+="("+p[0]+", "+p[1]+", "+p[2]+")";
            }
            ops.push(_value(edit,probe,"points","point3f[]",points+"]"));
            ops.push(_value(edit,probe,"visibility","token","\"invisible\""));
            ops+=_outputs(edit,probe,["sun_irradiance_w_m2","sun_visibility","sun_mount_x","sun_mount_y","sun_mount_z"]);
            let pv=net+"/"+name;ops+=_program(edit,net,name,"Electrical/SolarPanel");
            ops.push(_value(edit,pv,"connectors:p","token","\"\""));
            for p in [#{name:"area",value:g.area},#{name:"efficiency",value:c.efficiency},
                #{name:"reference_temperature_k",value:c.reference_temperature},
                #{name:"power_temperature_coefficient_per_k",value:c.power_temperature_coefficient},
                #{name:"solar_absorptivity",value:c.absorptivity},
                #{name:"peak_power_rating_w",value:g.area*c.efficiency*c.reference_irradiance},
                // Reduced direct bus connection at the study's nominal voltage;
                // a flight string/MPPT electrical design is not inferred.
                #{name:"v_mp",value:c.bus_voltage}] {ops.push(_scalar(edit,pv,"parameters:"+p.name,p.value));}
            for pair in [["irradiance","sun_irradiance_w_m2"],["sun_visibility","sun_visibility"],
                ["target_mount_x","sun_mount_x"],["target_mount_y","sun_mount_y"],["target_mount_z","sun_mount_z"]] {
                ops.push(_wire(edit,net,"inputs:"+name+"_"+pair[0],"double",[probe+".outputs:"+pair[1]]));
                ops.push(_wire(edit,pv,"inputs:"+pair[0],"double",[net+".inputs:"+name+"_"+pair[0]]));
            }
            let normal=[c.normal.x,c.normal.y,c.normal.z];let axes=["x","y","z"];
            for i in 0..3 {ops.push(_scalar(edit,pv,"inputs:panel_normal_"+axes[i],normal[i]));}
            ops+=_outputs(edit,pv,["power_out","available_power_w","incident_power_w","absorbed_power_w","reflected_power_w","heat_w","temperature_k","temperature_factor","cos_incidence"]);
            let mass=net+"/"+name+"Mass";ops+=_program(edit,net,name+"Mass","Thermal/ThermalMass");
            ops.push(_value(edit,mass,"connectors:port","token","\"\""));
            ops.push(_scalar(edit,mass,"parameters:c_th",c.heat_capacity));ops.push(_scalar(edit,mass,"parameters:T_init",c.initial_temperature));
            ops+=_outputs(edit,mass,["temp_k","heat_flow_w"]);
            let heat=net+"/"+name+"Heat";ops+=_program(edit,net,name+"Heat","Thermal/HeatLoad");
            ops.push(_value(edit,heat,"connectors:port","token","\"\""));
            ops.push(_wire(edit,heat,"inputs:heat_w","double",[pv+".outputs:heat_w"]));
            ops+=_outputs(edit,heat,["heat_in_w"]);
            let cooler=net+"/"+name+"Cooler";ops+=_program(edit,net,name+"Cooler","Thermal/LimitedCoolingSink");
            ops.push(_value(edit,cooler,"connectors:port","token","\"\""));
            for p in [#{name:"maximum_heat_rejection_w",value:c.maximum_cooling},
                #{name:"minimum_temperature_k",value:c.minimum_temperature},#{name:"conductance_w_per_k",value:c.conductance}] {
                ops.push(_scalar(edit,cooler,"parameters:"+p.name,p.value));
            }
            ops+=_outputs(edit,cooler,["heat_rejection_w","temperature_k"]);
            ops.push(_wire(edit,pv,"inputs:cell_temperature_k","double",[mass+".outputs:temp_k"]));
            ops.push(_wire(edit,mass,"connectors:port","token",[heat+".connectors:port",cooler+".connectors:port"]));
            ops+=_exports(edit,net,pv,name+"_",["power_out","available_power_w","incident_power_w","absorbed_power_w","reflected_power_w","heat_w","temperature_k","temperature_factor","cos_incidence"]);
            ops+=_exports(edit,net,mass,name+"_mass_",["temp_k","heat_flow_w"]);
            ops+=_exports(edit,net,cooler,name+"_cooler_",["heat_rejection_w","temperature_k"]);
            for member in [pv,mass,heat,cooler] {members.push(member);}
            pins.push(pv+".connectors:p");panels.push(#{name:name,area:g.area,cell_count:g.cell_count});
        }
        if part==3 {
        // Review this cross-part wiring against explicit prim declarations.
        // The coordinator deduplicates these identical declarations when it
        // joins all preparation parts into one complete atomic proposal.
        ops.push(_add(edit,net,"Battery","Scope"));
        ops.push(_add(edit,net,"AvionicsLoad","Scope"));
        ops.push(_scalar(edit,load,"outputs:powered",0.0));
        for name in names {
            let pv=net+"/"+name;
            for suffix in ["","Mass","Heat","Cooler"] {
                members.push(pv+suffix);
                ops.push(_add(edit,net,name+suffix,"Scope"));
            }
            pins.push(pv+".connectors:p");
        }
        ops.push(_wire(edit,battery,"connectors:p","token",pins));
        ops.push(#{SetRelationship:#{edit_target:edit,path:net,name:"collection:components:includes",targets:members}});
        ops.push(_wire(edit,root,"inputs:control_powered","double",[net+".outputs:avionics_powered"]));
        }
        return #{ok:true,ops:ops,panels:panels,source_revision:c.source_revision,kind:"griffin_power_thermal",part:part};
    } catch(error) {return #{ok:false,error:error};}
}
