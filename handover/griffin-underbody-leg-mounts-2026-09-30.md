# Griffin under-body leg mount and engine skirt correction

The main leg sleeves previously sat halfway up the broad body panels: vehicle Y=1.32, versus body lower edge Y=.98. The user rejected adding panel cutouts and provided an Astrobotic rendering showing the legs beneath the belt. No cutouts remain in the saved USD, requirements, or builder.

## Reference and explicit estimates

- User-selected Astrobotic rendering: https://www.astrobotic.com/lunar-delivery/landers/griffin-lander/
- Supplied thumbnail: https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR2r1xQLuK9FVl67Bpt2FkrW5JXaLk0HFu78gfflGo-r32Rt636APG830o&s=10
- Three-member topology and open underside reference: https://www.pghtech.org/UserFiles/Image/OnRAMP/Astrobotic/griffin.png

Shared physics/visual leg roots now sit at Y=.90 rather than 1.20. The primary sleeve center is at that root and its radius is .08, so its upper edge meets the reconstructed body lower edge .98. This is a reference-informed packaging estimate, not supplier CAD. The primary tube length derives from its endpoints. Local pad and hub datums compensate the .30 m root move, preserving vehicle-frame foot bottom -.01 m, the existing footprint, and the derived suspension rest target. Joint body-side anchors and hidden foot contact proxies use the corrected shared roots. A bracket derived from the lower perimeter ring connects the sleeve to the frame. Twin braces terminate at the current skirt rail stations (X=1.56, Y=1.00 in the canonical +X leg frame).

The engine skirt uses estimated 80 mm rail stock and a 120 mm shallow fairing instead of 200 mm stock and a 500 mm fairing. Its 60 mm taper is also an estimate. The adapter plate's lower face meets the upper throat ends instead of intersecting bell walls. A composed geometry gate measures 130 mm minimum radial bell clearance and 34.6% exposed bell height. These are packaging checks, not propulsion or flight acceptance.

## Verification

Owned LunCoSim session API49746; optimization binary reports 0.6.0-dev (d079c766-dirty). Other agents' sessions were untouched. Saved assets were reopened in a fresh process before the final visual inspection.

- Landing leg fixture: TESTS_OK 161, including four new sleeve/body-lower-edge checks, endpoint closure, shared root/joint orientations, and cooked pad contact checks. Log: /tmp/griffin-underbody-leg-gate.log.
- Bus fixture: TESTS_OK 353. Log: /tmp/griffin-underbody-bus-gate.log.
- Propulsion fixture: TESTS_OK 117, including composed skirt/bell clearance, exposed bell height, and adapter/throat separation. Log: /tmp/griffin-final-skirt-gate.log.
- Requirement source catalog: 207 targets, 207 evidence records, 46 sources, 3 source roles.
- Final rendered review: griffin-underbody-leg-review-2026-09-30.png.

Remaining limitations: public references mix configuration eras; diagonal/corner planform attachment locations remain provisional. The prismatic spring is a dynamics proxy, not qualified flight shock kinematics. The visible upper attachments move with the leg body under spring motion. RCS integration remains deferred. The broad mission and landed suspension behavior have not been accepted by these component checks.
