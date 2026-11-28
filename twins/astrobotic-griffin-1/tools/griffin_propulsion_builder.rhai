import "lunco://scripting/tools/engine_exhaust" as engine_exhaust;
import "lunco://scripting/tools/assembly_builder" as assembly_builder;
import "lunco://scripting/tools/assembly_edit" as assembly_edit;
import "lunco://scripting/tools/sysml_requirements" as sysml_requirements;
import "lunco://scripting/tools/pressure_fed_engine" as pressure_fed_engine;
import "lunco://scripting/tools/network_boundary" as network_boundary;
import "griffin_voyager_detail" as detail;
import "griffin_spec" as griffin_spec;
import "griffin_assembly_support" as support;

// Executable main/RCS feed topology, mass properties, actuator installation
// and guidance authority. USD owns installed connections; Modelica owns state.

fn main_engine_model_path(root, name) { root + "/MainPropulsion/" + name + "/Chamber" }
// Plume photometry and nozzle-wall glow feed only rendering. Each engine's
// pair forms its own network root under one grouping scope, so the seven
// independent presentation solvers run beside the MainPropulsion physics
// network instead of at every one of its RK stages.
fn main_engine_presentation_path(root) { root + "/MainEnginePresentation" }
fn main_engine_presentation_network(root, name) { main_engine_presentation_path(root) + "/" + name }
fn main_engine_plume_path(root, name) { main_engine_presentation_network(root, name) + "/Plume" }
fn main_engine_wall_path(root, name) { main_engine_presentation_network(root, name) + "/Wall" }
// The presentation root's boundary input for one MainPropulsion producer.
// Chamber signals arrive through the MainPropulsion root's published
// `<engine>_<output>` ports: the chamber inherits its outputs from
// `CombustionChamber`, so the generated wrapper does not alias them per
// member. NozzleDesign declares its outputs directly and is read as itself.
// Any other producer is outside the presentation contract and has no name.
fn main_engine_presentation_input(source_prim, source_property) {
    if !source_property.starts_with("outputs:") {return "";}
    let output=source_property.sub_string("outputs:".len());
    if source_prim.ends_with("/MainPropulsion/NozzleDesign") {return "nozzle_"+output;}
    if source_prim.ends_with("/MainPropulsion") {
        for name in griffin_spec::main_engine_names() {
            if output.starts_with(griffin_spec::main_engine_port(name,"")) {return output;}
        }
    }
    ""
}
// Connect one presentation member input to a MainPropulsion producer through
// its engine presentation network's boundary input for that producer.
fn _presentation_input_ops(edit_target, presentation, member, input, type_name, source) {
    let split=source.index_of(".");
    let boundary=main_engine_presentation_input(source.sub_string(0,split),source.sub_string(split+1));
    if boundary=="" {throw source+": producer has no main-engine presentation boundary";}
    [#{SetConnection:#{edit_target:edit_target,path:presentation,name:"inputs:"+boundary,
        type_name:type_name,sources:[source]}},
     #{SetConnection:#{edit_target:edit_target,path:member,name:input,
        type_name:type_name,sources:[presentation+".inputs:"+boundary]}}]
}
// Root signals republished per engine for actuators, HUD, telemetry and tests.
fn main_engine_root_outputs() {
    ["thrust_n","maximum_thrust_n","activity","chamber_pressure_pa","propellant_flow",
     "fuel_flow_kgs","oxidizer_flow_kgs","mixture_efficiency","exhaust_velocity_mps","mixture_ratio"]
}

fn _engine_parameters(model) {
    let own="GriffinPropulsionRequirements::GriffinPressureFedStudy::";
    let resolved=[];
    for item in [
        #{parts:["FuelValve"],name:"maximum_flow_kgs",source:"engineFuelReferenceFlowKgs"},
        #{parts:["FuelValve"],name:"commanded_flow_kgs",source:"engineFuelCommandFlowKgs"},
        #{parts:["OxidizerValve"],name:"maximum_flow_kgs",source:"engineOxidizerReferenceFlowKgs"},
        #{parts:["OxidizerValve"],name:"commanded_flow_kgs",source:"engineOxidizerCommandFlowKgs"},
        #{parts:["FuelValve","OxidizerValve"],name:"nominal_pressure_drop_pa",source:"referencePressureDropPa"},
        #{parts:["FuelValve","OxidizerValve"],name:"opening_time_constant_s",source:"valveResponseS"},
        #{parts:["FuelValve","OxidizerValve"],name:"availability_transition_mass_kg",source:"availabilityTransitionMassKg"},
        #{parts:["Chamber"],name:"oxidizer_to_fuel_ratio",source:"oxidizerToFuelRatio"},
        #{parts:["Chamber"],name:"characteristic_velocity_mps",source:"characteristicVelocityMps"},
        #{parts:["Chamber"],name:"throat_area_m2",source:"engineThroatBoreAreaM2"},
        #{parts:["Chamber"],name:"combustion_efficiency",source:"combustionEfficiency"},
        #{parts:["Chamber"],name:"nominal_flow_kgs",source:"engineNominalFlowKgs"}] {
        let value=support::source_number(model,own+item.source);
        if value==() || value<=0.0 {return support::plan_error("griffin_propulsion_assembly", "missing main-engine datum: "+item.source);}
        resolved.push(#{parts:item.parts,name:item.name,value:value});
    }
    #{ok:true,parameters:resolved}
}

// Each reusable USD engine assembly exposes two valves and one chamber as
// members of the single MainPropulsion solver. One engine is one authoring
// batch; the final feed plan admits all physics members together and the
// presentation plan admits each engine's plume and wall programs.
fn _engine_parameter_ops(edit_target, assembly, parameters) {
    let ops=[];
    for item in parameters {
        for part in item.parts {ops.push(#{SetAttribute:#{edit_target:edit_target,path:assembly+"/"+part,
            name:"parameters:"+item.name,type_name:"double",value:item.value.to_string()}});}
    }
    ops
}

// Prepare the referenced component before its inherited ports are wired.
fn griffin_main_engine_component_plan(doc, edit_target, root, name) {
    if !griffin_spec::main_engine_names().contains(name) {return support::plan_error("griffin_propulsion_assembly", "unknown main-engine identity");}
    let main=root+"/MainPropulsion";let assembly=main+"/"+name;
    if !support::exists(doc,main) {return support::plan_error("griffin_propulsion_assembly", "MainPropulsion assembly has not composed");}
    let ops=[];
    if !support::exists(doc,assembly) {ops.push(#{AddPrim:#{edit_target:edit_target,parent_path:main,name:name,
        type_name:"Scope",reference:(),reference_prim_path:()}});}
    ops.push(#{SetReferenceArcs:#{edit_target:edit_target,path:assembly,
        references:[#{asset_path:"lunco://components/propulsion/pressure_fed_engine.usda",prim_path:"/PressureFedEngine"}],
        list_op:"Explicit"}});
    #{ok:true,kind:"griffin_main_engine_component",engine:name,ops:ops,no_op:false}
}

fn griffin_main_engine_plan(doc, edit_target, root, name) {
    let model=sysml_requirements::model();
    if !sysml_model_is(model) {return support::plan_error("griffin_propulsion_assembly", "main-engine source unavailable");}
    if !griffin_spec::main_engine_names().contains(name) {
        return support::plan_error("griffin_propulsion_assembly", name+" is not a typed main-engine identity");
    }
    let nozzle_source="GriffinPropulsionRequirements::GriffinMainPropulsionAssembly::";
    let parameters=_engine_parameters(model);
    if !parameters.ok {return parameters;}
    let force=support::source_number(model,
        "GriffinPropulsionRequirements::GriffinPressureFedStudy::engineActuatorForceEnvelopeN");
    let fuel_family=support::source_number(model,nozzle_source+"plumeFuelFamily");
    let stoichiometric=support::source_number(model,nozzle_source+"plumeStoichiometricMixtureRatio");
    if force==() || force<=0.0 || fuel_family==() || stoichiometric==() || stoichiometric<=0.0 {
        return support::plan_error("griffin_propulsion_assembly", "main-engine actuator or plume source is incomplete");
    }
    let main=root+"/MainPropulsion";
    let nozzle=main+"/NozzleDesign";
    let engine=main_engine_model_path(root,name);
    let group=main_engine_presentation_path(root);
    let presentation=main_engine_presentation_network(root,name);
    let plume=main_engine_plume_path(root,name);
    let visual=root+"/Nozzle/MainEngineCluster/"+name;
    if !support::exists(doc,visual) {return support::plan_error("griffin_propulsion_assembly", visual+": engine bell has not composed");}
    let ops=[];
    let assembly=main+"/"+name;
    for path in pressure_fed_engine::component_members(assembly) {
        if !support::exists(doc,path) {return support::plan_error("griffin_propulsion_assembly", "Install "+assembly+" component reference and wait for composed projection before wiring");}
    }
    for part in [#{path:assembly+"/FuelValve",label:name+" fuel valve"},
        #{path:assembly+"/OxidizerValve",label:name+" oxidizer valve"},
        #{path:engine,label:name+" chamber"}] {
        ops.push(#{SetAttribute:#{edit_target:edit_target,path:part.path,name:"ui:displayName",
            type_name:"string",value:part.label}});
    }
    if !support::exists(doc,group) {
        ops.push(#{AddPrim:#{edit_target:edit_target,parent_path:root,name:"MainEnginePresentation",
            type_name:"Scope",reference:(),reference_prim_path:()}});
    }
    if !support::exists(doc,presentation) {
        ops.push(#{AddPrim:#{edit_target:edit_target,parent_path:group,name:name,
            type_name:"Scope",reference:(),reference_prim_path:()}});
    }
    for prim in [#{path:plume,name:"Plume",asset:"PlumePhotometry.mo"}] {
        if !support::exists(doc,prim.path) {
            ops.push(#{AddPrim:#{edit_target:edit_target,parent_path:presentation,name:prim.name,
                type_name:"Scope",reference:(),reference_prim_path:()}});
        }
        ops.push(#{SetApiSchemas:#{edit_target:edit_target,path:prim.path,schemas:["LunCoProgramAPI"]}});
        ops.push(#{SetAttribute:#{edit_target:edit_target,path:prim.path,name:"info:implementationSource",
            type_name:"token",value:"\"sourceAsset\""}});
        ops.push(#{SetAttribute:#{edit_target:edit_target,path:prim.path,name:"info:sourceAsset",
            type_name:"asset",value:"@lunco://models/LunCo/Propulsion/"+prim.asset+"@"}});
        ops.push(#{SetAttribute:#{edit_target:edit_target,path:prim.path,name:"lunco:program:realtimeSafe",
            type_name:"bool",value:"true"}});
    }
    for op in _engine_parameter_ops(edit_target,assembly,parameters.parameters) {ops.push(op);}
    let enabled=griffin_spec::main_engine_port(name,"enabled");
    ops.push(#{SetAttribute:#{edit_target:edit_target,path:main,name:"inputs:"+enabled,
        type_name:"float",value:"1.0"}});
    for output in ["exit_mach","gamma_out","exit_lip_angle_rad"] {
        ops.push(#{SetAttribute:#{edit_target:edit_target,path:nozzle,name:"outputs:"+output,
            type_name:"double",value:"0.0"}});
    }
    for fluid in [#{valve:"FuelValve",tank:"FuelTank"},#{valve:"OxidizerValve",tank:"OxidizerTank"}] {
        let valve=assembly+"/"+fluid.valve;
        for connection in [
            #{name:"inputs:flow_fraction_command",source:main+".inputs:flow_fraction_command",kind:"float"},
            #{name:"inputs:enabled",source:main+".inputs:"+enabled,kind:"float"},
            #{name:"inputs:available_mass_kg",source:main+"/"+fluid.tank+".outputs:mass_kg",kind:"float"},
            #{name:"connectors:inlet",source:main+"/"+fluid.tank+".connectors:outlet",kind:"token"}] {
            ops.push(#{SetConnection:#{edit_target:edit_target,path:valve,name:connection.name,
                type_name:connection.kind,sources:[connection.source]}});
        }
    }
    // Publish the engine boundary first: presentation inputs read these ports.
    for output in main_engine_root_outputs() {
        ops.push(#{SetConnection:#{edit_target:edit_target,path:main,
            name:"outputs:"+griffin_spec::main_engine_port(name,output),type_name:"double",
            sources:[engine+".outputs:"+output]}});
    }
    ops.push(#{SetConnection:#{edit_target:edit_target,path:engine,name:"inputs:effective_exhaust_velocity_mps",
        type_name:"float",sources:[nozzle+".outputs:ideal_exhaust_velocity_mps"]}});
    for connection in [
        #{path:plume,name:"inputs:thrust_n",source:main+".outputs:"+griffin_spec::main_engine_port(name,"thrust_n"),kind:"double"},
        #{path:plume,name:"inputs:maximum_thrust_n",source:main+".outputs:"+griffin_spec::main_engine_port(name,"maximum_thrust_n"),kind:"double"},
        #{path:plume,name:"inputs:propellant_flow_kgs",source:main+".outputs:"+griffin_spec::main_engine_port(name,"propellant_flow"),kind:"double"},
        #{path:plume,name:"inputs:exhaust_velocity_mps",source:main+".outputs:"+griffin_spec::main_engine_port(name,"exhaust_velocity_mps"),kind:"double"},
        #{path:plume,name:"inputs:mixture_ratio",source:main+".outputs:"+griffin_spec::main_engine_port(name,"mixture_ratio"),kind:"double"},
        #{path:plume,name:"inputs:nozzle_exit_radius_m",source:nozzle+".outputs:exit_radius_m",kind:"double"},
        #{path:plume,name:"inputs:nozzle_exit_area_m2",source:nozzle+".outputs:exit_area",kind:"float"},
        #{path:plume,name:"inputs:nozzle_exit_mach",source:nozzle+".outputs:exit_mach",kind:"double"},
        #{path:plume,name:"inputs:gas_gamma",source:nozzle+".outputs:gamma_out",kind:"double"},
        #{path:plume,name:"inputs:exit_lip_angle_rad",source:nozzle+".outputs:exit_lip_angle_rad",kind:"double"},
        #{path:main_engine_wall_path(root,name),name:"inputs:propellant_flow_kgs",source:main+".outputs:"+griffin_spec::main_engine_port(name,"propellant_flow"),kind:"double"}] {
        for op in _presentation_input_ops(edit_target,presentation,connection.path,connection.name,connection.kind,connection.source) {ops.push(op);}
    }
    ops.push(#{RemoveAttribute:#{edit_target:edit_target,path:plume,name:"inputs:engine_count"}});
    ops.push(#{SetAttribute:#{edit_target:edit_target,path:plume,name:"parameters:engine_count",
        type_name:"int",value:"1"}});
    for parameter in [#{name:"fuel_family",value:fuel_family.to_string()},
        #{name:"stoichiometric_mixture_ratio",value:stoichiometric.to_string()},
        #{name:"ambient_pressure_pa",value:"0.0"}] {
        ops.push(#{SetAttribute:#{edit_target:edit_target,path:plume,name:"inputs:"+parameter.name,
            type_name:"float",value:parameter.value}});
    }
    for item in [#{input:"gas_constant_j_kg_k",source:"gasConstantJkgK"},
        #{input:"radiative_fraction",source:"mainRadiativeFraction"},
        #{input:"luminous_efficacy_lm_w",source:"luminousEfficacyLmW"}] {
        let value=support::source_number(model,"GriffinPropulsionRequirements::GriffinPlumeStudy::"+item.source);
        if value==() {return support::plan_error("griffin_propulsion_assembly", "plume optical assumption missing: "+item.source);}
        ops.push(#{SetAttribute:#{edit_target:edit_target,path:plume,name:"inputs:"+item.input,
            type_name:"double",value:value.to_string()}});
    }
    for output in engine_exhaust::physical_outputs() {
        ops.push(#{SetAttribute:#{edit_target:edit_target,path:plume,name:"outputs:"+output,
            type_name:if engine_exhaust::render_outputs().contains(output) {"float"} else {"double"},value:"0.0"}});
    }
    for op in engine_exhaust::connection_ops(edit_target,visual,plume,#{}) {ops.push(op);}

    // The bell owns its engine's thrust: force at the engine station, along
    // the body +Y axis, commanded by that engine's delivered thrust.
    let thrust=main+".outputs:"+griffin_spec::main_engine_port(name,"thrust_n");
    ops.push(#{SetApiSchemas:#{edit_target:edit_target,path:visual,schemas:["LunCoForceActuatorAPI"]}});
    ops.push(#{SetAttribute:#{edit_target:edit_target,path:visual,name:"lunco:forceActuator:direction",
        type_name:"float3",value:"(0, 1, 0)"}});
    ops.push(#{SetAttribute:#{edit_target:edit_target,path:visual,name:"lunco:forceActuator:maxForce",
        type_name:"double",value:force.to_string()}});
    ops.push(#{SetRelationship:#{edit_target:edit_target,path:visual,
        name:"lunco:forceActuator:commandSource",targets:[thrust]}});
    ops.push(#{SetConnection:#{edit_target:edit_target,path:visual,name:"inputs:force_command",
        type_name:"double",sources:[thrust]}});

    let telemetry=main+"/"+name+"ThrustTelemetry";
    if !support::exists(doc,telemetry) {
        ops.push(#{AddPrim:#{edit_target:edit_target,parent_path:main,name:name+"ThrustTelemetry",
            type_name:"Scope",reference:(),reference_prim_path:()}});
    }
    ops.push(#{SetApiSchemas:#{edit_target:edit_target,path:telemetry,schemas:["LunCoTelemetryAPI"]}});
    for field in [#{name:"lunco:telemetry",type_name:"bool",value:"true"},
        #{name:"ui:displayName",type_name:"string",value:name.to_upper()+" THRUST"},
        #{name:"lunco:telemetry:port",type_name:"string",value:griffin_spec::main_engine_port(name,"thrust_n")},
        #{name:"lunco:telemetry:name",type_name:"string",value:"lander."+griffin_spec::main_engine_port(name,"thrust")},
        #{name:"lunco:telemetry:unit",type_name:"string",value:"N"},
        #{name:"lunco:telemetry:description",type_name:"string",
            value:"Delivered thrust of main engine "+name+" from its USD-authored valve/chamber assembly."}] {
        if ["lunco:telemetry:port","lunco:telemetry:name","lunco:telemetry:unit"].contains(field.name) {
            ops.push(#{RemoveAttribute:#{edit_target:edit_target,path:telemetry,name:field.name}});
        }
        ops.push(#{SetAttribute:#{edit_target:edit_target,path:telemetry,name:field.name,
            type_name:field.type_name,value:field.value}});
    }
    ops.push(#{SetRelationship:#{edit_target:edit_target,path:telemetry,
        name:"lunco:telemetry:target",targets:[main]}});
    #{ok:true,kind:"griffin_main_engine",engine:name,ops:ops,no_op:false}
}

// Equal live mass at each station of an explicitly assigned tank pair.
// Reject layouts requiring products of inertia; the current body port owns
// a diagonal tensor and cannot represent an arbitrary asymmetric grouping.
fn _propellant_group(model, attribute, names, stations) {
    let members=model.value(attribute);
    if !array_is(members) || members.len()!=2 {return support::plan_error("griffin_propulsion_assembly", "two typed tank identities required: "+attribute);}
    let points=[];
    for member in members {
        if !sysml_enum_is(member) {return support::plan_error("griffin_propulsion_assembly", "invalid tank identity");}
        let index=names.index_of(member.literal);
        if index<0 {return support::plan_error("griffin_propulsion_assembly", "unknown tank identity: "+member.literal);}
        points.push(stations[index]);
    }
    if members[0].literal==members[1].literal {return support::plan_error("griffin_propulsion_assembly", "tank pair must contain distinct stations");}
    let a=points[0]; let b=points[1];
    if abs(a.x+b.x)>1.0e-8 || abs(a.z+b.z)>1.0e-8
        || abs(a.y-b.y)>1.0e-8 || abs(a.x*a.z)>1.0e-8 {
        return support::plan_error("griffin_propulsion_assembly", "mass study requires opposed axis-aligned horizontal pairs");
    }
    let c=[(a.x+b.x)/2.0,(a.y+b.y)/2.0,(a.z+b.z)/2.0];
    let spread=[0.0,0.0,0.0];
    for p in points {
        let x=p.x-c[0];let y=p.y-c[1];let z=p.z-c[2];
        spread[0]+=(y*y+z*z)/2.0;
        spread[1]+=(x*x+z*z)/2.0;
        spread[2]+=(x*x+y*y)/2.0;
    }
    #{ok:true,centroid:c,specific_inertia:spread}
}

fn griffin_propellant_mass_plan(doc, edit_target, root) {
    let model=sysml_requirements::model();
    if !sysml_model_is(model) {return support::plan_error("griffin_propulsion_assembly", "propellant mass source unavailable");}
    let own="GriffinPropulsionRequirements::GriffinPropellantMassStudy::";
    let names=griffin_spec::propellant_tank_names();
    let stations=griffin_spec::component_tank_stations();
    if names.len()!=4 || stations.len()!=4 {return support::plan_error("griffin_propulsion_assembly", "four typed tank stations required");}
    let fuel=_propellant_group(model,own+"fuelTankInstances",names,stations);
    let oxidizer=_propellant_group(model,own+"oxidizerTankInstances",names,stations);
    if !fuel.ok {return fuel;} if !oxidizer.ok {return oxidizer;}
    let used=[];
    for attr in ["fuelTankInstances","oxidizerTankInstances"] {
        for member in model.value(own+attr) {
            if used.contains(member.literal) {return support::plan_error("griffin_propulsion_assembly", "tank belongs to both reactant groups");}
            used.push(member.literal);
        }
    }
    let dry=support::source_number(model,own+"dryMassKg");
    let dc=[];let di=[];
    for axis in ["X","Y","Z"] {dc.push(support::source_number(model,own+"dryCom"+axis+"M"));}
    for axis in ["Xx","Yy","Zz"] {di.push(support::source_number(model,own+"dryInertia"+axis+"KgM2"));}
    if dry==() || dry<=0.0 {return support::plan_error("griffin_propulsion_assembly", "positive dry mass required");}
    for i in 0..3 {if dc[i]==() || di[i]==() || di[i]<=0.0 {return support::plan_error("griffin_propulsion_assembly", "dry tensor source unavailable");}}
    if abs(dc[0])>1.0e-8 || abs(dc[2])>1.0e-8 {
        return support::plan_error("griffin_propulsion_assembly", "diagonal mass study requires the dry centroid on the tank-pair symmetry axis");
    }
    let pressure="GriffinPropulsionRequirements::GriffinPressureFedStudy::";
    let fm=support::source_number(model,pressure+"initialFuelMassKg");
    let om=support::source_number(model,pressure+"initialOxidizerMassKg");
    if fm==() || om==() || fm<0.0 || om<0.0 {return support::plan_error("griffin_propulsion_assembly", "initial species masses unavailable");}
    let mass=dry+fm+om; let com=[]; let inertia=[];
    for i in 0..3 {com.push((dry*dc[i]+fm*fuel.centroid[i]+om*oxidizer.centroid[i])/mass);}
    for i in 0..3 {
        let j=(i+1)%3;let k=(i+2)%3;
        let value=di[i];
        for g in [#{m:dry,c:dc,s:[0.0,0.0,0.0]},
            #{m:fm,c:fuel.centroid,s:fuel.specific_inertia},
            #{m:om,c:oxidizer.centroid,s:oxidizer.specific_inertia}] {
            value+=g.m*(g.s[i]+(g.c[j]-com[j])**2+(g.c[k]-com[k])**2);
        }
        inertia.push(value);
    }
    let status=root+"/MainPropulsion/PropellantStatus";let params=[];
    params.push(#{name:"dry_mass_kg",value:dry});
    params.push(#{name:"initial_propellant_mass_kg",value:fm+om});
    let axes=["x","y","z"];
    for i in 0..3 {
        let axis=axes[i];
        params.push(#{name:"dry_com_"+axis+"_m",value:dc[i]});
        params.push(#{name:"dry_inertia_"+axis+axis+"_kg_m2",value:di[i]});
        for g in [#{name:"fuel",value:fuel},#{name:"oxidizer",value:oxidizer}] {
            params.push(#{name:g.name+"_position_"+axis+"_m",value:g.value.centroid[i]});
            params.push(#{name:g.name+"_specific_inertia_"+axis+axis+"_m2",value:g.value.specific_inertia[i]});
        }
    }
    let ops=[];
    for p in params {
        ops.push(#{RemoveAttribute:#{edit_target:edit_target,path:status,name:"inputs:"+p.name}});
        ops.push(#{SetAttribute:#{edit_target:edit_target,path:status,name:"inputs:"+p.name,type_name:"double",value:p.value.to_string()}});
    }
    for p in [#{name:"physics:mass",type_name:"float",value:mass.to_string()},
        #{name:"physics:centerOfMass",type_name:"point3f",value:"("+com[0]+", "+com[1]+", "+com[2]+")"},
        #{name:"physics:diagonalInertia",type_name:"float3",value:"("+inertia[0]+", "+inertia[1]+", "+inertia[2]+")"}] {
        // Recreate each schema declaration atomically with its typed value.
        ops.push(#{RemoveAttribute:#{edit_target:edit_target,path:root,name:p.name}});
        ops.push(#{SetAttribute:#{edit_target:edit_target,path:root,name:p.name,type_name:p.type_name,value:p.value}});
    }
    #{ok:true,kind:"griffin_propellant_mass",ops:ops,mass:mass,com:com,inertia:inertia,no_op:false}
}

// Admit every engine into the MainPropulsion network: shared throttle, tank
// outlets, nozzle design, and the explicit physics member collection.
fn griffin_main_engine_feed_plan(doc, edit_target, root) {
    let model=sysml_requirements::model();
    if !sysml_model_is(model) {return support::plan_error("griffin_propulsion_assembly", "main-engine source unavailable");}
    let names=griffin_spec::main_engine_names();
    let count=griffin_spec::main_engine_count();
    if count==() || count<=0 || names.len()!=count {
        return support::plan_error("griffin_propulsion_assembly", "typed main-engine identities and count are incomplete");
    }
    let own="GriffinPropulsionRequirements::GriffinPressureFedStudy::";
    let nozzle_source="GriffinPropulsionRequirements::GriffinMainPropulsionAssembly::";
    let main=root+"/MainPropulsion";
    let nozzle=main+"/NozzleDesign";
    let ops=[];
    let mass_plan=griffin_propellant_mass_plan(doc,edit_target,root);
    if !mass_plan.ok {return mass_plan;}
    for op in mass_plan.ops {ops.push(op);}
    // Lander.mo publishes the shared throttle; runtime Modelica is the writer.
    ops.push(#{SetAttribute:#{edit_target:edit_target,path:root,name:"outputs:throttle",
        type_name:"float",value:"0.0"}});
    ops.push(#{SetConnection:#{edit_target:edit_target,path:main,name:"inputs:flow_fraction_command",
        type_name:"float",sources:[root+".outputs:throttle"]}});
    for tank in [#{name:"FuelTank",mass:"initialFuelMassKg"},#{name:"OxidizerTank",mass:"initialOxidizerMassKg"}] {
        let path=main+"/"+tank.name;
        for item in [#{name:"initial_mass_kg",source:tank.mass},
            #{name:"nominal_pressure_pa",source:"nominalTankPressurePa"},
            #{name:"pressure_headroom_pa",source:"tankPressureHeadroomPa"}] {
            let value=support::source_number(model,own+item.source);
            if value==() || value<=0.0 {return support::plan_error("griffin_propulsion_assembly", "missing tank datum: "+item.source);}
            ops.push(#{RemoveAttribute:#{edit_target:edit_target,path:path,name:"inputs:"+item.name}});
            ops.push(#{SetAttribute:#{edit_target:edit_target,path:path,name:"inputs:"+item.name,
                type_name:"double",value:value.to_string()}});
        }
    }
    let members=[main+"/FuelTank",main+"/OxidizerTank",nozzle,main+"/PropellantStatus"];
    let fuel_inlets=[];
    let oxidizer_inlets=[];
    for name in names {
        let assembly=main+"/"+name;
        let required=pressure_fed_engine::component_members(assembly);
        for member in required {
            if !support::exists(doc,member) {return support::plan_error("griffin_propulsion_assembly", member+": required propulsion member has not composed");}
            members.push(member);
        }
        fuel_inlets.push(assembly+"/FuelValve.connectors:inlet");
        oxidizer_inlets.push(assembly+"/OxidizerValve.connectors:inlet");
    }
    ops.push(#{SetConnection:#{edit_target:edit_target,path:main+"/FuelTank",name:"connectors:outlet",
        type_name:"token",sources:fuel_inlets}});
    ops.push(#{SetConnection:#{edit_target:edit_target,path:main+"/OxidizerTank",name:"connectors:outlet",
        type_name:"token",sources:oxidizer_inlets}});
    ops.push(#{SetRelationship:#{edit_target:edit_target,path:main,name:"collection:components:includes",targets:members}});
    for item in [#{name:"throat_radius",source:own+"throatBoreRadiusM"},
        #{name:"exit_radius",source:nozzle_source+"exitBoreRadiusM"},
        #{name:"length",source:nozzle_source+"bellHeightM"},
        #{name:"contour",source:nozzle_source+"bellContourExponent"},
        #{name:"p_chamber",source:own+"referenceChamberPressurePa"},
        #{name:"gamma",source:own+"gasGamma"},
        #{name:"characteristic_velocity_mps",source:own+"characteristicVelocityMps"}] {
        let value=support::source_number(model,item.source);
        if value==() || value<=0.0 {return support::plan_error("griffin_propulsion_assembly", "missing nozzle datum: "+item.source);}
        ops.push(#{RemoveAttribute:#{edit_target:edit_target,path:nozzle,name:"inputs:"+item.name}});
        ops.push(#{SetAttribute:#{edit_target:edit_target,path:nozzle,name:"inputs:"+item.name,
            type_name:"double",value:value.to_string()}});
    }
    ops.push(#{SetAttribute:#{edit_target:edit_target,path:nozzle,name:"outputs:ideal_exhaust_velocity_mps",
        type_name:"float",value:"0.0"}});
    #{ok:true,kind:"griffin_main_engine_feed",engine_count:count,ops:ops,no_op:false}
}

// Admit one engine's plume photometry and nozzle-wall thermal programs into
// that engine's presentation network. Each MainPropulsion producer they read
// enters through one boundary input; no presentation output feeds a physics
// member, and the engines' presentation networks are mutually independent.
fn griffin_main_engine_presentation_plan(doc, edit_target, root, name) {
    if !griffin_spec::main_engine_names().contains(name) {return support::plan_error("griffin_propulsion_assembly", "unknown main-engine identity");}
    let presentation=main_engine_presentation_network(root,name);
    if !support::exists(doc,presentation) {
        return support::plan_error("griffin_propulsion_assembly", presentation+": presentation network has not composed");
    }
    let members=[main_engine_plume_path(root,name),main_engine_wall_path(root,name)];
    for member in members {
        if !support::exists(doc,member) {return support::plan_error("griffin_propulsion_assembly", member+": required presentation member has not composed");}
    }
    let ops=[
        #{SetApiSchemas:#{edit_target:edit_target,path:presentation,schemas:["CollectionAPI:components"]}},
        #{SetAttribute:#{edit_target:edit_target,path:presentation,name:"ui:displayName",
            type_name:"string",value:name+" exhaust presentation"}},
        #{SetAttribute:#{edit_target:edit_target,path:presentation,name:"collection:components:expansionRule",
            type_name:"token",value:"\"explicitOnly\""}},
        #{SetRelationship:#{edit_target:edit_target,path:presentation,name:"collection:components:includes",targets:members}}];
    let routes=network_boundary::route_external_inputs_plan(doc,edit_target,presentation,members,
        |prim,property| main_engine_presentation_input(prim,property));
    if !routes.ok {return support::plan_error("griffin_propulsion_assembly", routes.error);}
    for op in routes.ops {ops.push(op);}
    #{ok:true,kind:"griffin_main_engine_presentation",engine:name,ops:ops,no_op:false}
}

fn apply_griffin_main_engine_component(doc, edit_target, root, name, parent_gen) {
    let plan=griffin_main_engine_component_plan(doc,edit_target,root,name);
    if !plan.ok {return plan;}
    let command=assembly_edit::batch(doc,"Install Griffin engine component "+name,plan.ops,parent_gen);
    #{ok:command.ok!=false,kind:plan.kind,command:command,engine:name}
}

fn apply_griffin_main_engine(doc, edit_target, root, name, parent_gen) {
    let plan=griffin_main_engine_plan(doc,edit_target,root,name);
    if !plan.ok {return plan;}
    let command=assembly_edit::batch(doc,"Model Griffin main engine "+name,plan.ops,parent_gen);
    #{ok:command.ok!=false,kind:plan.kind,command:command,engine:name}
}

fn apply_griffin_main_engine_feed(doc, edit_target, root, parent_gen) {
    let plan=griffin_main_engine_feed_plan(doc,edit_target,root);
    if !plan.ok {return plan;}
    let command=assembly_edit::batch(doc,"Feed Griffin main engines from shared tanks",plan.ops,parent_gen);
    #{ok:command.ok!=false,kind:plan.kind,command:command,engine_count:plan.engine_count}
}

fn apply_griffin_main_engine_presentation(doc, edit_target, root, name, parent_gen) {
    let plan=griffin_main_engine_presentation_plan(doc,edit_target,root,name);
    if !plan.ok {return plan;}
    let command=assembly_edit::batch(doc,"Admit Griffin "+name+" exhaust presentation",plan.ops,parent_gen);
    #{ok:command.ok!=false,kind:plan.kind,command:command,engine:name}
}

// Guidance converts acceleration demand with the nominal cluster rating. It is
// a configuration fact, not a live sum, so an engine failure is not signalled
// to guidance; closed-loop guidance and RCS absorb it.
fn griffin_guidance_thrust_rating_plan(doc, edit_target, gnc) {
    let rating=griffin_spec::_typed_model_number(
        "GriffinPropulsionRequirements::GriffinPressureFedStudy::guidanceClusterThrustN");
    if rating==() || rating<=0.0 {return support::plan_error("griffin_propulsion_assembly", "guidance cluster thrust rating unavailable");}
    if !support::exists(doc,gnc) {return support::plan_error("griffin_propulsion_assembly", gnc+": guidance prim has not composed");}
    #{ok:true,kind:"griffin_guidance_thrust_rating",rating:rating,no_op:false,ops:[
        #{RemoveAttribute:#{edit_target:edit_target,path:gnc,name:"inputs:max_thrust"}},
        #{SetAttribute:#{edit_target:edit_target,path:gnc,name:"inputs:max_thrust",
            type_name:"float",value:rating.to_string()}}]}
}

fn apply_griffin_guidance_thrust_rating(doc, edit_target, gnc, parent_gen) {
    let plan=griffin_guidance_thrust_rating_plan(doc,edit_target,gnc);
    if !plan.ok {return plan;}
    let command=assembly_edit::batch(doc,"Use nominal Griffin cluster thrust rating",plan.ops,parent_gen);
    #{ok:command.ok!=false,kind:plan.kind,command:command,rating:plan.rating}
}

// Attitude propulsion shares the authored reactant inventories.
fn griffin_rcs_feed_plan(doc, edit_target, root) {
    let fuel=griffin_spec::_typed_model_number(
        "GriffinPropulsionRequirements::GriffinAttitudeEngineAssembly::plumeFuelFamily");
    let radius=griffin_spec::_typed_model_number(
        "GriffinPropulsionRequirements::GriffinAttitudeEngineAssembly::exitRadiusM");
    let own="GriffinPropulsionRequirements::GriffinAttitudeEngineAssembly::";
    let isp=griffin_spec::_typed_model_number(own+"nominalSpecificImpulseS");
    let mixture=griffin_spec::_typed_model_number(own+"oxidizerToFuelRatio");
    let throat=griffin_spec::_typed_model_number(own+"throatRadiusM");
    let length=griffin_spec::_typed_model_number(own+"bellHeightM");
    let contour=griffin_spec::_typed_model_number(own+"bellContourExponent");
    let force=griffin_spec::_typed_model_number(own+"nominalForceN");
    if fuel==() || radius==() || radius<=0.0 || isp==() || mixture==()
        || throat==() || length==() || contour==() || force==() {return support::plan_error("griffin_propulsion_assembly", "RCS feed source incomplete");}
    let ops=[];
    let aggregate=root+"/AttitudePropulsion/RcsFlowAggregator";
    ops.push(#{RemoveAttribute:#{edit_target:edit_target,path:aggregate,name:"inputs:oxidizer_to_fuel_ratio"}});
    ops.push(#{SetAttribute:#{edit_target:edit_target,path:aggregate,
        name:"inputs:oxidizer_to_fuel_ratio",type_name:"double",value:mixture.to_string()}});
    for reactant in [#{name:"fuel",tank:"FuelTank"},#{name:"oxidizer",tank:"OxidizerTank"}] {
        ops.push(#{SetConnection:#{edit_target:edit_target,path:root+"/MainPropulsion",
            name:"outputs:"+reactant.name+"_mass_kg",type_name:"float",
            sources:[root+"/MainPropulsion/"+reactant.tank+".outputs:mass_kg"]}});
        ops.push(#{SetConnection:#{edit_target:edit_target,path:root+"/AttitudePropulsion",
            name:"inputs:available_"+reactant.name+"_mass_kg",type_name:"float",
            sources:[root+"/MainPropulsion.outputs:"+reactant.name+"_mass_kg"]}});
    }
    for jet in griffin_spec::rcs_port_mapping() {
        let path=root+"/AttitudePropulsion/"+jet.model_name;
        for reactant in [#{input:"available_fuel_mass_kg",tank:"FuelTank"},
            #{input:"available_oxidizer_mass_kg",tank:"OxidizerTank"}] {
            ops.push(#{SetConnection:#{edit_target:edit_target,path:path,
                name:"inputs:"+reactant.input,type_name:"float",
                sources:[root+"/AttitudePropulsion.inputs:"+reactant.input]}});
        }
        for output in engine_exhaust::physical_outputs() {
            let name=if output=="intensity" {"light_intensity"}
                else if output=="radius" {"light_radius"} else {output};
            ops.push(#{SetAttribute:#{edit_target:edit_target,path:path,
                name:"outputs:"+name,
                type_name:if engine_exhaust::render_outputs().contains(output) {"float"} else {"double"},value:"0.0"}});
        }
        for item in [#{input:"gas_gamma",source:"rcsGasGamma"},
            #{input:"gas_constant_j_kg_k",source:"gasConstantJkgK"},
            #{input:"radiative_fraction",source:"rcsRadiativeFraction"},
            #{input:"luminous_efficacy_lm_w",source:"luminousEfficacyLmW"}] {
            let value=griffin_spec::_typed_model_number("GriffinPropulsionRequirements::GriffinPlumeStudy::"+item.source);
            if value==() {return support::plan_error("griffin_propulsion_assembly", "RCS optical assumption missing: "+item.source);}
            ops.push(#{SetAttribute:#{edit_target:edit_target,path:path,name:"inputs:"+item.input,
                type_name:"double",value:value.to_string()}});
        }
        for parameter in [#{name:"fuel_family",value:fuel},
            #{name:"plume_width_m",value:radius},#{name:"geometry_capacity_m",value:0.0},
            #{name:"nozzle_throat_radius_m",value:throat},
            #{name:"nozzle_length_m",value:length},#{name:"nozzle_contour",value:contour},
            #{name:"f_nom_n",value:force},
            #{name:"isp_sec",value:isp},#{name:"mixture_ratio",value:mixture}] {
            ops.push(#{RemoveAttribute:#{edit_target:edit_target,path:path,name:"inputs:"+parameter.name}});
            ops.push(#{SetAttribute:#{edit_target:edit_target,path:path,
                name:"inputs:"+parameter.name,type_name:"double",value:parameter.value.to_string()}});
        }
    }
    #{ok:true,ops:ops,jet_count:griffin_spec::rcs_port_mapping().len()}
}

fn _griffin_rcs_mount_frame(record, jet) {
    let own="GriffinPropulsionRequirements::GriffinAttitudeEngineAssembly::";
    let force=griffin_spec::_typed_model_number(own+"nominalForceN");
    let height=griffin_spec::_typed_model_number(own+"mountHeightAbovePayloadDeckM");
    let standoff=griffin_spec::_typed_model_number(own+"mountStandoffM");
    let offset=griffin_spec::_typed_model_number(own+"memberTangentOffsetM");
    let dimensions=griffin_spec::visual_body_dimensions();
    let profile=griffin_spec::visual_outer_body_profile_coordinates();
    if force==() || height==() || standoff==() || offset==()
        || dimensions==() || profile.len()!=8 {
        return support::plan_error("griffin_propulsion_assembly", "RCS mount and rating source unavailable");
    }
    let old=vec3_from(record.attrs["xformOp:translate"]);
    if !vec3_is_finite(old) || old.x==0.0 || old.z==0.0 {
        return support::plan_error("griffin_propulsion_assembly", "RCS corner identity requires a finite nonzero X/Z position");
    }
    let sx=old.x/old.x.abs();let sz=old.z/old.z.abs();
    let chamfer=(1.0+profile[0].x.abs())/2.0;
    let arm_x=dimensions.x/2.0*chamfer+standoff/2.0.sqrt();
    let arm_z=dimensions.z/2.0*chamfer+standoff/2.0.sqrt();
    let tangent=if jet.valve_port.contains("pitch") {-offset}
        else if jet.valve_port.contains("roll") {offset} else {0.0};
    tangent*=sx*sz;
    let position=[sx*arm_x-sz*tangent/2.0.sqrt(),
        griffin_spec::visual_payload_adapter_center_y_m()+griffin_spec::visual_payload_adapter_thickness_m()/2.0+height,
        sz*arm_z+sx*tangent/2.0.sqrt()];
    #{ok:true,position:position,force:force,sx:sx,sz:sz,arm_x:arm_x,arm_z:arm_z}
}

// Refit the existing actuator in place. The force owner, ordered station
// identity, live connections and per-emitter shader seed travel with it.
fn griffin_rcs_refit_plan(doc, root, index) {
    let jets=griffin_spec::rcs_port_mapping();
    if index<0 || index>=jets.len() {return support::plan_error("griffin_propulsion_assembly","RCS station index invalid");}
    let jet=jets[index];
    let path=root+"/"+jet.model_name.sub_string(0,jet.model_name.len()-5);
    let record=assembly_builder::composed_query(doc,#{path:path,attrs:["xformOp:translate"]});
    let frame=_griffin_rcs_mount_frame(record,jet);
    if !frame.ok {return frame;}
    let ops=[#{SetTranslate:#{edit_target:"@root@",path:path,value:frame.position}}];
    ops+=detail::rcs_optics_ops("@root@",path+"/Nozzle");
    #{ok:true,ops:ops}
}

fn griffin_rcs_nozzle_station_plan(doc, edit_target, root, index) {
    let jets=griffin_spec::rcs_port_mapping();
    if index<0 || index>=jets.len() {return support::plan_error("griffin_propulsion_assembly", "RCS station index invalid");}
    let jet=jets[index];let name=jet.model_name.sub_string(0,jet.model_name.len()-5);
    let path=root+"/"+name;let model=root+"/AttitudePropulsion/"+jet.model_name;
    let record=assembly_builder::composed_query(doc,#{path:path,
        attrs:["xformOp:translate","xformOp:rotateXYZ","lunco:forceActuator:direction","lunco:forceActuator:maxForce"]});
    if !support::query_ok(record) || record.attrs["xformOp:translate"]==()
        || record.attrs["xformOp:rotateXYZ"]==()
        || record.attrs["lunco:forceActuator:direction"]==() {
        return support::plan_error("griffin_propulsion_assembly", "RCS physical station unavailable");
    }
    let frame=_griffin_rcs_mount_frame(record,jet);
    if !frame.ok {return frame;}
    let position=frame.position;let force=frame.force;
    let ops=[#{RemovePrim:#{edit_target:edit_target,path:path}},
        #{AddPrim:#{edit_target:edit_target,parent_path:root,name:name,type_name:"Xform",reference:(),reference_prim_path:()}},
        #{SetApiSchemas:#{edit_target:edit_target,path:path,schemas:["LunCoForceActuatorAPI"]}},
        #{SetTranslate:#{edit_target:edit_target,path:path,value:position}},
        #{SetRotate:#{edit_target:edit_target,path:path,value:record.attrs["xformOp:rotateXYZ"]}},
        #{SetAttribute:#{edit_target:edit_target,path:path,name:"lunco:forceActuator:direction",type_name:"float3",value:support::color3_literal(record.attrs["lunco:forceActuator:direction"])}},
        #{SetAttribute:#{edit_target:edit_target,path:path,name:"lunco:forceActuator:maxForce",type_name:"double",value:force.to_string()}},
        #{SetRelationship:#{edit_target:edit_target,path:path,name:"lunco:forceActuator:commandSource",targets:[root+"/AttitudeActuation.outputs:"+jet.valve_port]}},
        #{SetConnection:#{edit_target:edit_target,path:path,name:"inputs:force_command",type_name:"float",sources:[root+"/AttitudePropulsion.outputs:"+jet.thrust_port]}},
        #{AddPrim:#{edit_target:edit_target,parent_path:path,name:"Nozzle",type_name:"Xform",
            reference:support::component_asset("lander/griffin_rcs_bell_visual.usda"),reference_prim_path:"/World"}},
        // Force is local -Y; the nozzle's exhaust must point local +Y.
        #{SetRotate:#{edit_target:edit_target,path:path+"/Nozzle",value:[180.0,0.0,0.0]}}];
    let core=assembly_builder::composed_query(doc,#{path:root+"/"+name+"Core"});
    if support::query_ok(core) {ops.push(#{RemovePrim:#{edit_target:edit_target,path:root+"/"+name+"Core"}});}
    ops.push(#{SetAttribute:#{edit_target:edit_target,path:model,name:"inputs:f_nom_n",type_name:"float",value:force.to_string()}});
    for op in engine_exhaust::connection_ops(edit_target,path+"/Nozzle",model,
        #{intensity:"light_intensity",radius:"light_radius"}) {ops.push(op);}
    ops+=detail::rcs_optics_ops(edit_target,path+"/Nozzle");
    let shader=path+"/Nozzle/Exhaust/Looks/Flame_Mat/Surface";
    let previous=assembly_builder::composed_query(doc,#{path:shader,attrs:["inputs:seed"]});
    if support::query_ok(previous) && previous.attrs["inputs:seed"]!=() {
        ops.push(#{SetAttribute:#{edit_target:edit_target,path:shader,name:"inputs:seed",
            type_name:"float",value:previous.attrs["inputs:seed"].to_string()}});
    }
    #{ok:true,ops:ops,path:path,model:model}
}

fn griffin_rcs_wrench_check(doc, root) {
    let groups=#{pitch_pos:vec3(0.0,0.0,0.0),pitch_neg:vec3(0.0,0.0,0.0),
        roll_pos:vec3(0.0,0.0,0.0),roll_neg:vec3(0.0,0.0,0.0),
        yaw_pos:vec3(0.0,0.0,0.0),yaw_neg:vec3(0.0,0.0,0.0)};
    let forces=#{};
    for group in groups.keys() {forces[group]=vec3(0.0,0.0,0.0);}
    let generation=();
    for jet in griffin_spec::rcs_port_mapping() {
        let name=jet.model_name.sub_string(0,jet.model_name.len()-5);
        let record=assembly_builder::composed_query(doc,#{path:root+"/"+name,
            attrs:["xformOp:translate","xformOp:rotateXYZ","lunco:forceActuator:direction","lunco:forceActuator:maxForce"]});
        if !support::query_ok(record) {return support::plan_error("griffin_propulsion_assembly", "RCS wrench datum missing");}
        if generation==() {generation=record.document_generation;}
        if generation!=record.document_generation {return support::plan_error("griffin_propulsion_assembly", "RCS wrench generation changed");}
        let point=vec3_from(record.attrs["xformOp:translate"]);
        let rotation=quat_from_euler_xyz_deg(vec3_from(record.attrs["xformOp:rotateXYZ"]));
        let force=qrot(rotation,vec3_from(record.attrs["lunco:forceActuator:direction"]))
            *f64_from(record.attrs["lunco:forceActuator:maxForce"]);
        let group=jet.valve_port.sub_string(0,jet.valve_port.len()-8);
        groups[group]+=vcross(point,force);forces[group]+=force;
    }
    let checks=[];
    let tolerance=griffin_spec::_typed_model_number(
        "GriffinVisualConfigurationRequirements::GriffinVisualConfiguration::geometryVerificationToleranceM");
    for row in [#{name:"pitch_pos",axis:0,sign:1.0},#{name:"pitch_neg",axis:0,sign:-1.0},
        #{name:"yaw_pos",axis:1,sign:1.0},#{name:"yaw_neg",axis:1,sign:-1.0},
        #{name:"roll_pos",axis:2,sign:1.0},#{name:"roll_neg",axis:2,sign:-1.0}] {
        let values=vec3_array(groups[row.name]);
        let off_axis=0.0;for index in 0..3 {if index!=row.axis {off_axis+=values[index].abs();}}
        checks.push(#{group:row.name,moment:groups[row.name],net_force:forces[row.name],
            ok:values[row.axis]*row.sign>0.0 && off_axis<=tolerance
                && vlen(forces[row.name])<=tolerance});
    }
    let ok=true;for check in checks {ok=ok && check.ok;}
    #{ok:ok,doc_id:doc,document_generation:generation,checks:checks}
}

fn griffin_rcs_command_envelope_plan(doc,edit_target,root) {
    let pairs=griffin_rcs_wrench_check(doc,root);
    if !pairs.ok {return support::plan_error("griffin_propulsion_assembly", "RCS pure-axis geometry unavailable");}
    let fraction=griffin_spec::_typed_model_number(
        "GriffinPropulsionRequirements::GriffinAttitudeEngineAssembly::commandTorqueCapacityFraction");
    if fraction==() || fraction<=0.0 || fraction>=1.0 {
        return support::plan_error("griffin_propulsion_assembly", "RCS command reserve must be strictly between zero and one");
    }
    let capacity=();
    for pair in pairs.checks {
        let magnitude=vlen(pair.moment);
        if capacity==() || magnitude<capacity {capacity=magnitude;}
    }
    let limit=capacity*fraction;
    #{ok:true,document_generation:pairs.document_generation,torque_limit_nm:limit,
      ops:[#{RemoveAttribute:#{edit_target:edit_target,path:root,
        name:"inputs:hold_torque_limit_nm"}},
        #{SetAttribute:#{edit_target:edit_target,path:root,
        name:"inputs:hold_torque_limit_nm",type_name:"double",value:limit.to_string()}}]}
}
