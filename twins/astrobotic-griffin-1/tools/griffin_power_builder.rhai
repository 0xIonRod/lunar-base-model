import "lunco://scripting/tools/assembly_edit" as assembly_edit;
import "griffin_spec" as griffin_spec;
import "griffin_assembly_support" as support;
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
    let result=quantity_si_value(quantity(value.value,unit));
    if result==() || !result.is_finite() {throw("finite SI source value required: "+name);}
    result
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
    let infrared=model.attribute(study()+"radiativeMaterial");
    if infrared==() || infrared.declared_type==() || infrared.declared_type.resolved_type==() {
        throw("typed infrared surface reference unavailable");
    }
    let infrared_material=infrared.declared_type.resolved_type.qualified_name+"::";
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
        infrared_emissivity:number(model,infrared_material+"infraredEmissivity"),
        radiation_constant:si(model,study()+"stefanBoltzmannConstant",[0,1,-3,0,-4,0,0]),
        sky_view_factor:number(model,study()+"skyViewFactor"),
        ground_view_factor:number(model,study()+"groundViewFactor"),
        sky_temperature:si(model,study()+"skyRadiationTemperature",temperature),
        ground_temperature:si(model,study()+"groundRadiationTemperature",temperature),
        sustained_duration:si(model,study()+"sustainedObservationDuration",[0,0,1,0,0,0,0]),
        equilibrium_duration:si(model,study()+"equilibriumObservationDuration",[0,0,1,0,0,0,0]),
        settled_duration:si(model,study()+"minimumSettledDuration",[0,0,1,0,0,0,0]),
        settling_rate:si(model,study()+"maximumSettledTemperatureRate",[0,0,-1,0,1,0,0]),
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
    if config.infrared_emissivity<=0.0 || config.infrared_emissivity>1.0
        || config.sky_view_factor<0.0 || config.ground_view_factor<0.0
        || abs(config.sky_view_factor+config.ground_view_factor-1.0)>1.0e-12
        || config.sky_temperature<0.0 || config.ground_temperature<0.0 {
        throw("invalid radiative study boundary");
    }
    if config.sustained_duration<=0.0 || config.equilibrium_duration<3600.0
        || config.equilibrium_duration<config.sustained_duration
        || config.settled_duration<=0.0 || config.settled_duration>=config.sustained_duration
        || config.settled_duration>=config.equilibrium_duration || config.settling_rate<=0.0 {
        throw("thermal studies require positive horizons and rate threshold, an equilibrium horizon of at least one hour and at least as long as the transient, and a shorter positive settled window");
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
    let row_ends=[];
    for row in 0..layout.rows {
        for column in geometry::solar_cell_row_columns(layout,row) {
            centers.push([(-layout.columns/2.0+column+0.5)*layout.pitch_m/layout.scale_x,
                height,(-layout.rows/2.0+row+0.5)*layout.pitch_z_m]);
        }
        row_ends.push(centers.len());
    }
    // Equal weights in the native terrain-visibility probe. Stratify by active
    // cell population, then use a base-two radical inverse across each row.
    let lateral_rank=[0,8,4,12,2,10,6,14,1,9,5,13,3,11,7,15];
    let samples=[];let row=0;let count=lateral_rank.len();
    if centers.len()<count {throw("insufficient active cells for visibility sampling");}
    for i in 0..count {
        let ordinal=((i+0.5)*centers.len()/count).floor().to_int();
        while ordinal>=row_ends[row] {row+=1;}
        let first=if row==0 {0} else {row_ends[row-1]};
        let width=row_ends[row]-first;
        let col=((lateral_rank[i]+0.5)*width/count).floor().to_int();
        samples.push(centers[first+col]);
    }
    #{area:cell_area*centers.len().to_float(),cell_count:centers.len(),samples:samples}
}

fn visibility_points_op(edit,probe,samples) {
    let points="[";
    for i in 0..samples.len() {
        if i>0 {points+=", ";}
        let p=samples[i];points+="("+p[0]+", "+p[1]+", "+p[2]+")";
    }
    support::attribute(edit,probe,"points","point3f[]",points+"]")
}

fn _program(edit, parent, name, source) {
    let path=parent+"/"+name;
    [support::add(edit,parent,name,"Scope"),
     #{SetApiSchemas:#{edit_target:edit,path:path,schemas:["LunCoProgramAPI"]}},
     support::attribute(edit,path,"info:implementationSource","token","\"sourceAsset\""),
     support::attribute(edit,path,"info:sourceAsset","asset","@lunco://models/LunCo/"+source+".mo@"),
     support::attribute(edit,path,"lunco:program:realtimeSafe","bool","true")]
}
fn _exports(edit, net, component, prefix, names) {
    let ops=[];
    for name in names {
        ops.push(support::connection(edit,net,"outputs:"+prefix+name,"double",
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
        ops.push(support::add(edit,root,"ElectricalPower","Scope"));
        ops.push(#{SetApiSchemas:#{edit_target:edit,path:net,schemas:["CollectionAPI:components"]}});
        ops.push(support::attribute(edit,net,"collection:components:expansionRule","token","\"explicitOnly\""));
        let battery=net+"/Battery";let load=net+"/AvionicsLoad";
        if part == -1 {
        ops+=_program(edit,net,"Battery","Electrical/Battery");
        ops.push(support::attribute(edit,battery,"connectors:p","token","\"\""));
        for p in [#{name:"voltage_nom",value:c.bus_voltage},#{name:"capacity",value:c.capacity_ah},
            #{name:"R_internal",value:c.battery_resistance},#{name:"soc_init",value:c.initial_soc}] {
            ops.push(support::scalar(edit,battery,"parameters:"+p.name,p.value));
        }
        ops+=support::outputs(edit,battery,["terminal_voltage_v","terminal_current_a","net_power_w","stored_power_w","stored_energy_j","heat_w","soc_out"]);
        ops+=_exports(edit,net,battery,"battery_",["terminal_voltage_v","terminal_current_a","net_power_w","stored_power_w","stored_energy_j","heat_w","soc_out"]);
        ops+=_program(edit,net,"AvionicsLoad","Electrical/OnboardComputer");
        ops.push(support::attribute(edit,load,"connectors:p","token","\"\""));
        for p in [#{name:"p_baseline_w",value:c.baseline_power},#{name:"p_gnc_w",value:c.guidance_power},
            #{name:"voltage_off_v",value:c.voltage_off},#{name:"voltage_on_v",value:c.voltage_on}] {
            ops.push(support::scalar(edit,load,"parameters:"+p.name,p.value));
        }
        // Requested guidance processing remains a load even when its supply is
        // insufficient; the load's UVLO owns actual powered availability.
        ops.push(support::scalar(edit,load,"inputs:gnc_active",1.0));
        ops+=support::outputs(edit,load,["powered","power_draw_w","heat_w","processing_active"]);
        ops+=_exports(edit,net,load,"avionics_",["powered","power_draw_w","heat_w","processing_active"]);
        }
        let members=[battery,load];let pins=[load+".connectors:p"];let panels=[];
        let names=griffin_spec::solar_array_names();
        let selected=if part>=0 && part<3 {[part]} else {[]};
        for index in selected {
            let g=panel_geometry(index);let name=names[index];let parent=root+"/"+name;
            let probe=parent+"/PowerEnvironment";
            ops.push(support::add(edit,parent,"PowerEnvironment","Points"));
            ops.push(#{SetApiSchemas:#{edit_target:edit,path:probe,schemas:["LunCoEnvironmentProbeAPI"]}});
            ops.push(visibility_points_op(edit,probe,g.samples));
            ops.push(support::attribute(edit,probe,"visibility","token","\"invisible\""));
            ops+=support::outputs(edit,probe,["sun_irradiance_w_m2","sun_visibility","sun_mount_x","sun_mount_y","sun_mount_z"]);
            let pv=net+"/"+name;ops+=_program(edit,net,name,"Electrical/SolarPanel");
            ops.push(support::attribute(edit,pv,"connectors:p","token","\"\""));
            for p in [#{name:"area",value:g.area},#{name:"efficiency",value:c.efficiency},
                #{name:"reference_temperature_k",value:c.reference_temperature},
                #{name:"temperature_curve_min_k",value:c.reference_temperature},
                #{name:"temperature_curve_max_k",value:c.maximum_temperature},
                #{name:"power_temperature_coefficient_per_k",value:c.power_temperature_coefficient},
                #{name:"solar_absorptivity",value:c.absorptivity},
                #{name:"peak_power_rating_w",value:g.area*c.efficiency*c.reference_irradiance},
                // Reduced direct bus connection at the study's nominal voltage;
                // a flight string/MPPT electrical design is not inferred.
                #{name:"v_mp",value:c.bus_voltage}] {ops.push(support::scalar(edit,pv,"parameters:"+p.name,p.value));}
            for pair in [["irradiance","sun_irradiance_w_m2"],["sun_visibility","sun_visibility"],
                ["target_mount_x","sun_mount_x"],["target_mount_y","sun_mount_y"],["target_mount_z","sun_mount_z"]] {
                ops.push(support::connection(edit,net,"inputs:"+name+"_"+pair[0],"double",[probe+".outputs:"+pair[1]]));
                ops.push(support::connection(edit,pv,"inputs:"+pair[0],"double",[net+".inputs:"+name+"_"+pair[0]]));
            }
            let normal=[c.normal.x,c.normal.y,c.normal.z];let axes=["x","y","z"];
            for i in 0..3 {ops.push(support::scalar(edit,pv,"inputs:panel_normal_"+axes[i],normal[i]));}
            ops+=support::outputs(edit,pv,["power_out","available_power_w","incident_power_w","absorbed_power_w","reflected_power_w","heat_w","temperature_k","temperature_factor","curve_temperature_k","curve_limited","curve_in_range","cos_incidence"]);
            let mass=net+"/"+name+"Mass";ops+=_program(edit,net,name+"Mass","Thermal/ThermalMass");
            ops.push(support::attribute(edit,mass,"connectors:port","token","\"\""));
            ops.push(support::scalar(edit,mass,"parameters:c_th",c.heat_capacity));ops.push(support::scalar(edit,mass,"parameters:T_init",c.initial_temperature));
            ops+=support::outputs(edit,mass,["temp_k","heat_flow_w"]);
            let heat=net+"/"+name+"Heat";ops+=_program(edit,net,name+"Heat","Thermal/HeatLoad");
            ops.push(support::attribute(edit,heat,"connectors:port","token","\"\""));
            ops.push(support::connection(edit,heat,"inputs:heat_w","double",[pv+".outputs:heat_w"]));
            ops+=support::outputs(edit,heat,["heat_in_w"]);
            let cooler=net+"/"+name+"Cooler";ops+=_program(edit,net,name+"Cooler","Thermal/LimitedCoolingSink");
            ops.push(support::attribute(edit,cooler,"connectors:port","token","\"\""));
            for p in [#{name:"maximum_heat_rejection_w",value:c.maximum_cooling},
                #{name:"minimum_temperature_k",value:c.minimum_temperature},#{name:"conductance_w_per_k",value:c.conductance}] {
                ops.push(support::scalar(edit,cooler,"parameters:"+p.name,p.value));
            }
            ops+=support::outputs(edit,cooler,["heat_rejection_w","temperature_k"]);
            for boundary in [#{suffix:"SkyRadiation",factor:c.sky_view_factor,temperature:c.sky_temperature},
                #{suffix:"GroundRadiation",factor:c.ground_view_factor,temperature:c.ground_temperature}] {
                let radiator=pv+boundary.suffix;
                ops+=_program(edit,net,name+boundary.suffix,"Thermal/Radiator");
                ops.push(support::attribute(edit,radiator,"connectors:port","token","\"\""));
                for p in [#{name:"area",value:g.area*boundary.factor},#{name:"sigma",value:c.radiation_constant},
                    #{name:"emissivity",value:c.infrared_emissivity},#{name:"T_sink",value:boundary.temperature}] {
                    ops.push(support::scalar(edit,radiator,"parameters:"+p.name,p.value));
                }
                ops+=support::outputs(edit,radiator,["heat_rejection_w","temperature_k"]);
                ops+=_exports(edit,net,radiator,name+"_"+boundary.suffix+"_",["heat_rejection_w","temperature_k"]);
            }
            ops.push(support::connection(edit,pv,"inputs:cell_temperature_k","double",[mass+".outputs:temp_k"]));
            ops.push(support::connection(edit,mass,"connectors:port","token",[heat+".connectors:port",cooler+".connectors:port",
                pv+"SkyRadiation.connectors:port",pv+"GroundRadiation.connectors:port"]));
            ops+=_exports(edit,net,pv,name+"_",["power_out","available_power_w","incident_power_w","absorbed_power_w","reflected_power_w","heat_w","temperature_k","temperature_factor","curve_temperature_k","curve_limited","curve_in_range","cos_incidence"]);
            ops+=_exports(edit,net,mass,name+"_mass_",["temp_k","heat_flow_w"]);
            ops+=_exports(edit,net,cooler,name+"_cooler_",["heat_rejection_w","temperature_k"]);
            for member in [pv,mass,heat,cooler,pv+"SkyRadiation",pv+"GroundRadiation"] {members.push(member);}
            pins.push(pv+".connectors:p");panels.push(#{name:name,area:g.area,cell_count:g.cell_count});
        }
        if part==3 {
        // Review this cross-part wiring against explicit prim declarations.
        // The coordinator deduplicates these identical declarations when it
        // joins all preparation parts into one complete atomic proposal.
        ops.push(support::add(edit,net,"Battery","Scope"));
        ops.push(support::add(edit,net,"AvionicsLoad","Scope"));
        ops.push(support::scalar(edit,load,"outputs:powered",0.0));
        for name in names {
            let pv=net+"/"+name;
            for suffix in ["","Mass","Heat","Cooler","SkyRadiation","GroundRadiation"] {
                members.push(pv+suffix);
                ops.push(support::add(edit,net,name+suffix,"Scope"));
            }
            pins.push(pv+".connectors:p");
        }
        ops.push(support::connection(edit,battery,"connectors:p","token",pins));
        ops.push(#{SetRelationship:#{edit_target:edit,path:net,name:"collection:components:includes",targets:members}});
        ops.push(support::connection(edit,root,"inputs:control_powered","double",[net+".outputs:avionics_powered"]));
        }
        return #{ok:true,ops:ops,panels:panels,source_revision:c.source_revision,kind:"griffin_power_thermal",part:part};
    } catch(error) {return #{ok:false,error:error};}
}

// Realize FLIP source-owned electrical ratings at the USD/Modelica boundary.
fn flip_electrical_model_plan(doc, edit_target, root) {
    if doc == () || edit_target == () || !support::absolute_root(root) {
        return support::plan_error("griffin_power_assembly", "flip_electrical_model_plan requires a document, edit target, and absolute root");
    }
    let energy_kwh = griffin_spec::rover_battery_energy_kwh();
    let nominal_voltage_v = griffin_spec::rover_battery_nominal_voltage_v();
    let capacity_ah = griffin_spec::rover_battery_capacity_ah();
    let peak_power_w = griffin_spec::rover_solar_peak_power_w();
    if energy_kwh == () || nominal_voltage_v == () || capacity_ah == () || peak_power_w == ()
        || nominal_voltage_v <= 0.0 || energy_kwh <= 0.0 || peak_power_w <= 0.0 {
        return support::plan_error("griffin_power_assembly", "FLIP electrical requirement values are missing or invalid");
    }
    for path in [root + "/Battery", root + "/SolarArray"] {
        if !support::component_query(doc, path).ok {
            return support::plan_error("griffin_power_assembly", "FLIP electrical component is missing at " + path);
        }
    }
    let battery = root + "/Battery";
    let solar = root + "/SolarArray";
    let ops = [
        #{RemoveAttribute: #{edit_target: edit_target, path: battery, name: "inputs:voltage_nom"}},
        #{RemoveAttribute: #{edit_target: edit_target, path: battery, name: "inputs:capacity"}},
        #{RemoveAttribute: #{edit_target: edit_target, path: solar, name: "inputs:peak_power_rating_w"}},
        #{SetAttribute: #{edit_target: edit_target, path: battery,
            name: "inputs:voltage_nom", type_name: "double",
            value: nominal_voltage_v.to_string()}},
        #{SetAttribute: #{edit_target: edit_target, path: battery,
            name: "inputs:capacity", type_name: "double",
            value: capacity_ah.to_string()}},
        #{SetAttribute: #{edit_target: edit_target, path: solar,
            name: "inputs:peak_power_rating_w", type_name: "double",
            value: peak_power_w.to_string()}}
    ];
    #{ok: true, kind: "flip_electrical_model", root: root,
      battery_energy_kwh: energy_kwh, battery_nominal_voltage_v: nominal_voltage_v,
      battery_capacity_ah: capacity_ah, solar_peak_power_w: peak_power_w,
      paths: [battery, solar], ops: ops, no_op: false}
}

fn apply_flip_electrical_model(doc, edit_target, root, parent_gen) {
    let plan = flip_electrical_model_plan(doc, edit_target, root);
    if !plan.ok { return plan; }
    let command = assembly_edit::batch(doc, "Realize FLIP source-owned electrical ratings",
        plan.ops, parent_gen);
    #{ok: command.ok != false, kind: plan.kind, root: root,
      battery_energy_kwh: plan.battery_energy_kwh,
      battery_capacity_ah: plan.battery_capacity_ah,
      solar_peak_power_w: plan.solar_peak_power_w, command: command}
}
