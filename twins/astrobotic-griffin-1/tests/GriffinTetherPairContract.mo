model GriffinTetherPairContract
  GriffinTetherPairStudy pair(stiffness=4000,damping=800,initial_length=1.0,
    payout_speed=0.12,payout_extension=0.03,tension_limit=2500,
    enabled=1.0,span0_x=1.01,span1_y=1.01);
  GriffinTetherPairStudy slack(stiffness=4000,damping=800,initial_length=1.0,
    payout_speed=0.12,payout_extension=0.03,tension_limit=2500,
    enabled=1.0,span0_x=0.8,span1_y=0.8);
  Real dissipated(start=0.0,fixed=true);
equation
  der(dissipated)=pair.spool_power+pair.damper_power;
  assert(abs(pair.force_x+pair.reaction_x)<1e-8 and abs(pair.force_y+pair.reaction_y)<1e-8
    and abs(pair.force_z+pair.reaction_z)<1e-8,"Tether reactions must be equal and opposite");
  assert(pair.tension0>=0.0 and pair.tension1>=0.0 and pair.spool_power>=0.0
    and pair.damper_power>=0.0,"Lines may only pull and dissipate");
  assert(abs(slack.force_x)+abs(slack.force_y)+abs(slack.force_z)<1e-8
    and abs(slack.length0-1.0)<1e-8,"Slack lines must carry no load or uncommanded payout");
  assert(abs(pair.elastic_energy+dissipated-0.4)<1e-4,
    "Fixed-end payout must dissipate the initial 0.4 J elastic energy");
end GriffinTetherPairContract;
