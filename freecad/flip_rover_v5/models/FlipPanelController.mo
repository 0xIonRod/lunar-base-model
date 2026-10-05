within;
model FlipPanelController "Study deployment command; native joint owns dynamics"
  input Real command_deg(unit="deg") "Operator deployment request (degrees)";
  parameter Real rate_deg_s(unit="deg/s") = 10 "Study command slew limit (deg/s)";
  parameter Real tau_s(unit="s") = 0.4 "Study command easing time (s)";
  parameter Real initial_deg(unit="deg") = 82 "Matches the authored presentation pose";
  output Real deployment_deg(unit="deg",start=initial_deg, fixed=true);
  output Real angle(unit="rad") "Native Z-axis hinge setpoint, radians";
  Real bounded_deg(unit="deg");
equation
  bounded_deg = min(90, max(0, command_deg));
  der(deployment_deg) = max(-rate_deg_s, min(rate_deg_s, (bounded_deg-deployment_deg)/tau_s));
  angle = -deployment_deg * 0.017453292519943295; // radians per degree
end FlipPanelController;
