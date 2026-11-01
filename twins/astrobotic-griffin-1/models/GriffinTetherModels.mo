within;
package GriffinTetherModels
  "Study models for a fabric line unwinding from a wheel; not flight-qualified values"

  model EgressPair
    "Two wheel wraps with equal/opposite forces and anchor moments"
    parameter Real radius = 0.465;
    parameter Real stiffness = 8000;
    parameter Real damping = 600;
    parameter Real anchor_x = -1.16;
    parameter Real anchor_y = 2.16;
    parameter Real anchor_rl_z = -1.0;
    parameter Real anchor_rr_z = 1.0;
    input Real attached;
    input Real lander_px;
    input Real lander_py;
    input Real lander_pz;
    input Real lander_vx;
    input Real lander_vy;
    input Real lander_vz;
    input Real lander_qw;
    input Real lander_qx;
    input Real lander_qy;
    input Real lander_qz;
    input Real lander_wx;
    input Real lander_wy;
    input Real lander_wz;
    input Real lander_com_x;
    input Real lander_com_y;
    input Real lander_com_z;
    input Real rl_px;
    input Real rl_py;
    input Real rl_pz;
    input Real rl_vx;
    input Real rl_vy;
    input Real rl_vz;
    input Real rl_qw;
    input Real rl_qx;
    input Real rl_qy;
    input Real rl_qz;
    input Real rl_wx;
    input Real rl_wy;
    input Real rl_wz;
    input Real rl_com_x;
    input Real rl_com_y;
    input Real rl_com_z;
    input Real rr_px;
    input Real rr_py;
    input Real rr_pz;
    input Real rr_vx;
    input Real rr_vy;
    input Real rr_vz;
    input Real rr_qw;
    input Real rr_qx;
    input Real rr_qy;
    input Real rr_qz;
    input Real rr_wx;
    input Real rr_wy;
    input Real rr_wz;
    input Real rr_com_x;
    input Real rr_com_y;
    input Real rr_com_z;
    output Real lander_fx;
    output Real lander_fy;
    output Real lander_fz;
    output Real lander_tx;
    output Real lander_ty;
    output Real lander_tz;
    output Real rl_fx;
    output Real rl_fy;
    output Real rl_fz;
    output Real rl_tx;
    output Real rl_ty;
    output Real rl_tz;
    output Real rr_fx;
    output Real rr_fy;
    output Real rr_fz;
    output Real rr_tx;
    output Real rr_ty;
    output Real rr_tz;
    output Real rl_tension;
    output Real rl_energyResidual;
    output Real rl_anchor_x;
    output Real rl_anchor_y;
    output Real rl_anchor_z;
    output Real rl_tangent_x;
    output Real rl_tangent_y;
    output Real rl_tangent_z;
    WrappedLine rl(radius=radius, stiffness=stiffness, damping=damping);
    LunCo.Sensors.FrameVectorTransform rlAnchor(quaternion_w=lander_qw, quaternion_x=lander_qx, quaternion_y=lander_qy, quaternion_z=lander_qz, vector_x=anchor_x, vector_y=anchor_y, vector_z=anchor_rl_z);
    LunCo.Sensors.FrameVectorTransform rlAxis(quaternion_w=rl_qw, quaternion_x=rl_qx, quaternion_y=rl_qy, quaternion_z=rl_qz, vector_x=1, vector_y=0, vector_z=0);
    Real rlAnchorOffset[3];
    Real rlComTorque[3];
    output Real rr_tension;
    output Real rr_energyResidual;
    output Real rr_anchor_x;
    output Real rr_anchor_y;
    output Real rr_anchor_z;
    output Real rr_tangent_x;
    output Real rr_tangent_y;
    output Real rr_tangent_z;
    WrappedLine rr(radius=radius, stiffness=stiffness, damping=damping);
    LunCo.Sensors.FrameVectorTransform rrAnchor(quaternion_w=lander_qw, quaternion_x=lander_qx, quaternion_y=lander_qy, quaternion_z=lander_qz, vector_x=anchor_x, vector_y=anchor_y, vector_z=anchor_rr_z);
    LunCo.Sensors.FrameVectorTransform rrAxis(quaternion_w=rr_qw, quaternion_x=rr_qx, quaternion_y=rr_qy, quaternion_z=rr_qz, vector_x=1, vector_y=0, vector_z=0);
    Real rrAnchorOffset[3];
    Real rrComTorque[3];
    LunCo.Sensors.FrameVectorTransform landerCom(quaternion_w=lander_qw, quaternion_x=lander_qx, quaternion_y=lander_qy, quaternion_z=lander_qz, vector_x=lander_com_x, vector_y=lander_com_y, vector_z=lander_com_z);
    Real landerComOffset[3];
    LunCo.Sensors.FrameVectorTransform rlCom(quaternion_w=rl_qw, quaternion_x=rl_qx, quaternion_y=rl_qy, quaternion_z=rl_qz, vector_x=rl_com_x, vector_y=rl_com_y, vector_z=rl_com_z);
    Real rlComOffset[3];
    LunCo.Sensors.FrameVectorTransform rrCom(quaternion_w=rr_qw, quaternion_x=rr_qx, quaternion_y=rr_qy, quaternion_z=rr_qz, vector_x=rr_com_x, vector_y=rr_com_y, vector_z=rr_com_z);
    Real rrComOffset[3];
    Real landerForce[3];
    Real landerTorque[3];
  equation
    rlAnchorOffset = {rlAnchor.world_frame_x, rlAnchor.world_frame_y, rlAnchor.world_frame_z};
    rl.anchor = {lander_px, lander_py, lander_pz} + rlAnchorOffset;
    rl.anchorVelocity = {lander_vx, lander_vy, lander_vz} + cross({lander_wx, lander_wy, lander_wz}, rlAnchorOffset - landerComOffset);
    rl.center = {rl_px, rl_py, rl_pz};
    rl.centerVelocity = {rl_vx, rl_vy, rl_vz} - cross({rl_wx, rl_wy, rl_wz}, rlComOffset);
    rl.wheelAngularVelocity = {rl_wx, rl_wy, rl_wz};
    rl.wheelAxis = {rlAxis.world_frame_x, rlAxis.world_frame_y, rlAxis.world_frame_z};
    rl.attached = attached;
    rlComTorque = rl.torque - cross(rlComOffset, rl.force);
    rl_tension = rl.tension;
    rl_energyResidual = rl.energyResidual;
    rl_fx = rl.force[1];
    rl_tx = rlComTorque[1];
    rl_anchor_x = rl.anchor[1];
    rl_tangent_x = rl.tangent[1];
    rl_fy = rl.force[2];
    rl_ty = rlComTorque[2];
    rl_anchor_y = rl.anchor[2];
    rl_tangent_y = rl.tangent[2];
    rl_fz = rl.force[3];
    rl_tz = rlComTorque[3];
    rl_anchor_z = rl.anchor[3];
    rl_tangent_z = rl.tangent[3];
    rrAnchorOffset = {rrAnchor.world_frame_x, rrAnchor.world_frame_y, rrAnchor.world_frame_z};
    rr.anchor = {lander_px, lander_py, lander_pz} + rrAnchorOffset;
    rr.anchorVelocity = {lander_vx, lander_vy, lander_vz} + cross({lander_wx, lander_wy, lander_wz}, rrAnchorOffset - landerComOffset);
    rr.center = {rr_px, rr_py, rr_pz};
    rr.centerVelocity = {rr_vx, rr_vy, rr_vz} - cross({rr_wx, rr_wy, rr_wz}, rrComOffset);
    rr.wheelAngularVelocity = {rr_wx, rr_wy, rr_wz};
    rr.wheelAxis = {rrAxis.world_frame_x, rrAxis.world_frame_y, rrAxis.world_frame_z};
    rr.attached = attached;
    rrComTorque = rr.torque - cross(rrComOffset, rr.force);
    rr_tension = rr.tension;
    rr_energyResidual = rr.energyResidual;
    rr_fx = rr.force[1];
    rr_tx = rrComTorque[1];
    rr_anchor_x = rr.anchor[1];
    rr_tangent_x = rr.tangent[1];
    rr_fy = rr.force[2];
    rr_ty = rrComTorque[2];
    rr_anchor_y = rr.anchor[2];
    rr_tangent_y = rr.tangent[2];
    rr_fz = rr.force[3];
    rr_tz = rrComTorque[3];
    rr_anchor_z = rr.anchor[3];
    rr_tangent_z = rr.tangent[3];
    landerComOffset = {landerCom.world_frame_x, landerCom.world_frame_y, landerCom.world_frame_z};
    rlComOffset = {rlCom.world_frame_x, rlCom.world_frame_y, rlCom.world_frame_z};
    rrComOffset = {rrCom.world_frame_x, rrCom.world_frame_y, rrCom.world_frame_z};
    landerForce = -rl.force - rr.force;
    landerTorque = cross(rlAnchorOffset - landerComOffset, -rl.force) + cross(rrAnchorOffset - landerComOffset, -rr.force);
    lander_fx = landerForce[1];
    lander_tx = landerTorque[1];
    lander_fy = landerForce[2];
    lander_ty = landerTorque[2];
    lander_fz = landerForce[3];
    lander_tz = landerTorque[3];
  end EgressPair;

  model WrappedLine
    "Massless line, elastic stretch, passive damping and a cylindrical wrap"
    parameter Real radius(unit="m") = 0.465;
    parameter Real stiffness(unit="N/m") = 8000;
    parameter Real damping(unit="N.s/m") = 600;
    parameter Real tangentBranch = 1;
    parameter Real initialStretch(unit="m") = 0;
    input Real anchor[3](each unit="m");
    input Real anchorVelocity[3](each unit="m/s");
    input Real center[3](each unit="m");
    input Real centerVelocity[3](each unit="m/s");
    input Real wheelAxis[3];
    input Real wheelAngularVelocity[3](each unit="rad/s");
    input Real attached;
    output Real force[3](each unit="N") "Force on the wheel, in the navigation frame";
    output Real torque[3](each unit="N.m") "Moment about the wheel center";
    output Real tangent[3](each unit="m");
    output Real tension(unit="N");
    output Real stretch(unit="m", start=initialStretch, fixed=true);
    output Real stretchRate(unit="m/s");
    output Real storedEnergy(unit="J");
    output Real dissipatedPower(unit="W");
    output Real mechanicalPower(unit="W");
    output Real energyResidual(unit="W");
    output Real momentResidual[3](each unit="N.m");
    Real axisNorm;
    Real axis[3];
    Real offset[3];
    Real planar[3];
    Real planarSquared;
    Real radial[3];
    Real line[3];
    Real lineLength;
    Real direction[3];
    Real materialVelocity[3];
    Real elasticTension;
  equation
    assert(radius > 0 and stiffness > 0 and damping >= 0,
      "Wrapped line needs positive radius/stiffness and nonnegative damping");
    assert(abs(tangentBranch) == 1, "Tangent branch must be -1 or +1");
    axisNorm = sqrt(wheelAxis * wheelAxis);
    assert(axisNorm > 0.9, "Wrapped line has no valid wheel axis");
    axis = wheelAxis / axisNorm;
    offset = anchor - center;
    planar = offset - axis * (axis * offset);
    planarSquared = planar * planar;
    assert(planarSquared > radius * radius,
      "Fabric anchor intersects the wheel's cylindrical wrap surface");
    radial = radius * radius / planarSquared * planar
      + tangentBranch * radius * sqrt(planarSquared - radius * radius)
        / planarSquared * cross(axis, planar);
    tangent = center + radial;
    line = tangent - anchor;
    lineLength = sqrt(line * line);
    direction = line / lineLength;
    // Material velocity at tangency includes wheel rotation. The line does not
    // push, and it cannot add energy. The two equal/opposite end forces and
    // their actual lever arms also conserve total angular momentum.
    materialVelocity = centerVelocity + cross(wheelAngularVelocity, radial);
    stretchRate = direction * (materialVelocity - anchorVelocity);
    der(stretch) = if attached > 0.5 then stretchRate else 0;
    elasticTension = stiffness * max(0, stretch);
    tension = if attached > 0.5 and stretch > 0 then
      max(0, elasticTension + damping * stretchRate) else 0;
    force = -tension * direction;
    torque = cross(radial, force);
    storedEnergy = if attached > 0.5 then 0.5 * stiffness * max(0, stretch)^2 else 0;
    dissipatedPower = if attached > 0.5 and stretch > 0 then
      (tension - elasticTension) * stretchRate else 0;
    mechanicalPower = force * (centerVelocity - anchorVelocity)
      + torque * wheelAngularVelocity;
    energyResidual = mechanicalPower + dissipatedPower
      + (if attached > 0.5 then elasticTension * stretchRate else 0);
    momentResidual = cross(center - anchor, force) + torque;
  end WrappedLine;

  model ConservationTest
    "Prescribed motion checks independent force, moment and power balances"
    WrappedLine line(initialStretch=0.02);
    output Real powerResidual = line.energyResidual;
    output Real momentResidual = sqrt(line.momentResidual * line.momentResidual);
    output Real tension = line.tension;
    output Real dissipation = line.dissipatedPower;
    output Real storedEnergy = line.storedEnergy;
  equation
    line.anchor = {0, 1.0, 0};
    line.anchorVelocity = {0, 0, 0};
    line.center = {1.0 + 0.1 * time, 0, 0};
    line.centerVelocity = {0.1, 0, 0};
    line.wheelAxis = {0, 0, 1};
    line.wheelAngularVelocity = {0, 0, -0.1};
    line.attached = 1;
    assert(abs(powerResidual) < 1e-6, "Wrapped line creates or loses unaccounted energy");
    assert(momentResidual < 1e-6, "Wrapped line does not conserve angular momentum");
    assert(dissipation >= -1e-8, "Wrapped line damping creates energy");
  end ConservationTest;


end GriffinTetherModels;
