# Worldwide Lunar Base News Agent

This local agent supports the NASA Lunar Base project until the project is
finished. It searches the last seven days across official agency feeds,
SpaceNews, ESA, and broad Google News RSS topic searches. Coverage includes
lunar-base plans, engineering, habitats and life support, power,
communications, robotics, resources, science, international programs, and
commercial activity.

## Run it

From the project root:

```powershell
python .\news\artemis_news_agent.py
```

Outputs:

- `news\artemis_news.md` — seven-day TL;DR briefing
- `news\artemis_news.json` — structured article list
- `news\.artemis_news_state.json` — URLs seen during the latest run

The first run needs network access. Edit `news\artemis_news_agent.json` to add
sources or tune the focus keywords. The Sunday automation only prepares the
local briefing; it does not commit or push.

## Sunday review workflow

1. Open `news\artemis_news.md` and review the seven-day TL;DR.
2. Check source links and remove irrelevant search results if needed.
3. Add or correct useful context if needed.
4. Run project checks and review the staged diff.
5. Commit only after the review is complete.

## Useful options

```powershell
python .\news\artemis_news_agent.py --since-hours 24
python .\news\artemis_news_agent.py --timeout 30
python .\news\artemis_news_agent.py --config .\news\my-config.json --markdown .\news\out.md
```

Feed failures are reported as warnings; successfully fetched sources still
produce an output file.
