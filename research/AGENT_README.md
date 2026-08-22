# Lunar Base Research Agent

The research agent answers a focused lunar-base question using the local mission
register and the curated primary-source links in `sources.md`. It keeps the
source URL, a short excerpt, matched terms, and a lightweight confidence label
in every result so the output can be audited before it becomes simulator data.

## Run it

From the project root:

```powershell
python .\research\lunar_base_research_agent.py "polar water ice and rover operations"
```

Outputs:

- `research\lunar_base_research_brief.md` — readable evidence brief
- `research\lunar_base_research_results.json` — structured findings for later tooling

For a network-free run against the existing register:

```powershell
python .\research\lunar_base_research_agent.py "Artemis IV lunar landing" --offline
```

The agent does not silently rewrite `missions.md`, `locations.md`, or
`vehicles.md`. That separation is deliberate: research findings should be
reviewed by a human before they become planning or simulation inputs.

## Evidence policy

Current agency, provider, and mission-owner pages are preferred. A local
register document is labeled `context`, while external findings are labeled
`high`, `medium`, or `low` based on source type and query relevance. Retrieval
failures are preserved as warnings, and successful sources still produce a
brief.
