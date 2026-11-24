within;
model FlipPanelController "Study deployment command; native joint owns dynamics"
  input Real command_deg(unit="deg") "Operator deployment request (degrees)";
  parameter Real rate_deg_s(unit="deg/s") = 10 "Study command slew limit (deg/s)";
  parameter Real tau_s(unit="s") = 0.4 "Study command easing time (s)";
  parameter Real initial_deg(unit="deg") = 82 "Matches the authored presentation pose";
  parameter Real soft_limit_margin_deg(unit="deg") = 0.25
    "Control margin inside the native hinge stops";
  output Real deployment_deg(unit="deg",start=initial_deg, fixed=true);
  output Real angle(unit="rad") "Native Z-axis hinge setpoint, radians";
  Real bounded_deg(unit="deg");
  Real rate_command_deg_s(unit="deg/s");
equation
  bounded_deg = min(90.0 - soft_limit_margin_deg,
                    max(soft_limit_margin_deg, command_deg));
  rate_command_deg_s = max(-rate_deg_s,
                           min(rate_deg_s, (bounded_deg-deployment_deg)/tau_s));
  der(deployment_deg) = noEvent(
    if deployment_deg <= soft_limit_margin_deg and rate_command_deg_s < 0.0 then 0.0
    elseif deployment_deg >= 90.0 - soft_limit_margin_deg and rate_command_deg_s > 0.0 then 0.0
    else rate_command_deg_s);
  angle = -deployment_deg * 0.017453292519943295; // radians per degree
end FlipPanelController;
