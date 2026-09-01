# Instructions for LunCoSim

This directory is the home for reusable setup and operating instructions for
LunCoSim connections and plugins.

## Directory layout

- `connections/` — instructions for external services, local tools, or data
  sources that connect to LunCoSim.
- `plugins/` — instructions for installing, configuring, and using LunCoSim
  plugins or extensions.

Keep one topic per Markdown file. Include prerequisites, configuration steps,
validation checks, troubleshooting notes, and the date of the last verification.
Never commit credentials, tokens, private keys, or other secrets; reference
environment variables or a local secret store instead.

## Suggested naming

Use lowercase, descriptive filenames with hyphens, for example:

- `connections/telemetry-service.md`
- `plugins/terrain-importer.md`

