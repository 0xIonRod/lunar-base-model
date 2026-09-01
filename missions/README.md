# Mission twins

Mission twins are small, versioned simulator inputs. Each mission keeps its
scene, physical parameters, and assumptions together so humans can review the
design and tools can load it without interpreting a long narrative document.

The first package is [`mission-001`](mission-001/). The Griffin-1 / FLIP
package is [`mission-002`](mission-002/); it keeps the M01 package unchanged
and points to the executable Twin-local Modelica scene. Future missions should
follow the same layout and replace assumptions incrementally with sourced
values.

