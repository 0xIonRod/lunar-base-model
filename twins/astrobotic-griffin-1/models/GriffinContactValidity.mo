model GriffinContactValidity
  "Study validity boundary for native hull and four landing-leg contacts"
  input Real hull_speed_mps(unit="m/s");
  input Real leg_px_speed_mps(unit="m/s");
  input Real leg_nx_speed_mps(unit="m/s");
  input Real leg_pz_speed_mps(unit="m/s");
  input Real leg_nz_speed_mps(unit="m/s");
  input Real maximum_speed_mps(unit="m/s");
  output Real exceedance_ratio(unit="1");
  output Real speed_limit_mps(unit="m/s");
  LunCo.Sensors.ContactSpeedEnvelope envelope;
equation
  envelope.contact_speed_mps = max(hull_speed_mps,
    max(max(leg_px_speed_mps, leg_nx_speed_mps), max(leg_pz_speed_mps, leg_nz_speed_mps)));
  envelope.maximum_speed_mps = maximum_speed_mps;
  exceedance_ratio = envelope.exceedance_ratio;
  speed_limit_mps = envelope.speed_limit_mps;
end GriffinContactValidity;
