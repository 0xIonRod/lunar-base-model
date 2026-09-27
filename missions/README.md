# Mission twins

Mission twins are small, versioned simulator inputs. Each mission keeps its
scene, physical parameters, and assumptions together so humans can review the
design and tools can load it without interpreting a long narrative document.

The first package is [`mission-001`](mission-001/). The Griffin-1 / FLIP
package is [`mission-002`](mission-002/); it keeps the M01 package unchanged
and records mission facts separately from its executable Twin. Its `scene.usda`
composes the canonical Twin surface-operations scene, so vehicle geometry and
behavior have one authored source. Future mission scenes should compose their
own Twin assets instead of copying vehicle definitions.
