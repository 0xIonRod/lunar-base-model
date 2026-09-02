// Griffin-1 surface-operations tools.
//
// This Twin-local library owns reusable mission presentation and route policy.
// Physical descent, contact, ramp hinges, the adapter joint, and drivetrain
// remain authored in USD/Modelica and are commanded through the normal Rhai
// verbs.  The functions are intentionally useful from other Griffin
// scenarios as well as the production surface-operations scenario.

/// Put the mission view on the lander while its authored GNC performs descent.
fn follow_lander() {
    follow(find("/Griffin1SurfaceOps/Lander"));
}

/// Hand the mission view to the rover immediately after the adapter release.
/// The follow camera makes the physical ramp exit and rover drop visible
/// without taking control away from the rover's autopilot.
fn follow_rover() {
    follow(find("/Griffin1SurfaceOps/FLIP"));
}

/// The short, explicit Griffin landing-demo route: clear the deployed ramp,
/// then reach the two survey gates and the base site. The top-deck approach
/// marker is deliberately not a post-release target: its y=6.2 m elevation
/// describes the attached payload deck, not the surface the rover drives on.
/// This is route data, not a claim about flight speed or the as-built FLIP ICD.
fn surface_route() {
    #{
        kind: "sequence",
        children: [
            #{ kind: "drive_to", target: [8.2, 1.0, 0.0], speed: 0.22, radius: 2.5 },
            #{ kind: "drive_to", target: [16.0, 0.0, 4.0], speed: 0.35, radius: 2.5 },
            #{ kind: "drive_to", target: [19.0, 0.0, 2.0], speed: 0.35, radius: 2.5 },
            #{ kind: "drive_to", target: [21.0, 0.0, 0.5], speed: 0.35, radius: 2.5 },
            #{ kind: "drive_to", target: [21.6, 0.0, -1.0], speed: 0.35, radius: 2.5 },
            #{ kind: "drive_to", target: [21.8, 0.0, -2.5], speed: 0.35, radius: 2.5 },
            #{ kind: "drive_to", target: [22.0, 0.0, -4.0], speed: 0.35, radius: 2.5 },
            #{ kind: "drive_to", target: [22.4, 0.0, -5.5], speed: 0.35, radius: 2.5 },
            #{ kind: "drive_to", target: [23.0, 0.0, -7.0], speed: 0.35, radius: 2.5 },
            #{ kind: "drive_to", target: [24.5, 0.0, -8.0], speed: 0.30, radius: 2.5 },
            #{ kind: "drive_to", target: [26.0, 0.0, -9.0], speed: 0.30, radius: 2.5 },
            #{ kind: "drive_to", target: [27.0, 0.0, -10.0], speed: 0.30, radius: 2.5 },
            #{ kind: "drive_to", target: [29.0, 0.0, -11.0], speed: 0.30, radius: 2.5 },
            #{ kind: "drive_to", target: [31.0, 0.0, -12.0], speed: 0.30, radius: 2.5 }
        ]
    }
}

/// Release the adapter and arm the complete route as one mission boundary.
/// Returns the typed command acknowledgment so callers can report a failure
/// instead of claiming that the rover moved when the command was rejected.
fn release_and_engage() {
    let release = cmd("DetachJoint", #{
        target: find("/Griffin1SurfaceOps/FLIPPayloadAdapterJoint"),
        intent: "Interactive"
    });
    if release.ok == false { return release; }
    let route = surface_route();
    cmd("EngageAutopilot", #{
        vessel: find("/Griffin1SurfaceOps/FLIP"),
        spec_json: to_json(route)
    })
}
