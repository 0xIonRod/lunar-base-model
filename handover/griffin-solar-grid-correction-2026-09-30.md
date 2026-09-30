# Griffin solar grid and support correction

Corrected the scale-before-translation bug affecting eight late-created
column dividers. The shared cube planner explicitly owns transform order.
The solar observer now catches the previously invisible raw-attribute error.

Rectangular arrays match the selected Astrobotic 2021 product rendering.
The cell face is dark, the 14 x 5 pitch is uniform, and smaller support
geometry no longer blocks the cell field. SysML and size evidence record
the selected revision and all appearance estimates. The solar component
fixture passed, including composed bus/bracket/link/frame overlap.

Review session: terrain checkout, API 49746, isolated presentation settings.
Close/reopen the parent vehicle after saved component changes to get a new
composed preview. No Rust mechanism was added. This is a visual/component
correction, not mission landing acceptance.
