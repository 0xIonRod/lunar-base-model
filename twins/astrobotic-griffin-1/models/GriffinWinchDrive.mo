model GriffinWinchDrive
  "Reduced dual-drum converter and dissipative payout brake; no regeneration"
  extends LunCo.Electrical.RegulatedLoad;
  parameter Real efficiency=0.8 "Assumed motoring efficiency, 0..1";
  parameter Real idle_power_w(unit="W")=15.0 "Enabled electronics draw";
  input Real enabled=0.0;
  input Real spool_power0_w(unit="W")=0.0 "Positive payout, negative take-up";
  input Real spool_power1_w(unit="W")=0.0;
  input Real damper_power_w(unit="W")=0.0 "Passive line dissipation routed to this reduced thermal node";
  output Real available=powered;
  output Real mechanical_output_power_w(unit="W");
  output Real brake_power_w(unit="W");
  output Real heat_w(unit="W");
  output Real power_residual_w(unit="W");
  output Real motor_efficiency=efficiency;
protected
  Real demand_w(unit="W");
equation
  assert(efficiency>0.0 and efficiency<=1.0 and idle_power_w>=0.0,
    "Winch drive requires efficiency in (0,1] and nonnegative idle draw");
  demand_w=max(0.0,-spool_power0_w)+max(0.0,-spool_power1_w);
  requested_power_w=if enabled>0.5 then idle_power_w+demand_w/efficiency else 0.0;
  // Across the causal scene boundary, the last committed shaft powers are
  // sampled by the electrical network. UVLO availability reaches the drums
  // at the next admitted fixed endpoint; no hidden regeneration is assumed.
  mechanical_output_power_w=if enabled>0.5 then powered*demand_w else 0.0;
  brake_power_w=max(0.0,spool_power0_w)+max(0.0,spool_power1_w);
  heat_w=power_draw_w-mechanical_output_power_w+brake_power_w+max(0.0,damper_power_w);
  power_residual_w=power_draw_w+brake_power_w+max(0.0,damper_power_w)
    -mechanical_output_power_w-heat_w;
end GriffinWinchDrive;
