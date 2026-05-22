# here.now Public Skill Repo Agent Guide

Use this file as the operating guide for AI coding agents working in the public `heredotnow/skill` repository.

## What This Repo Contains

- `here-now/` - canonical here.now skill bundle for `npx skills add heredotnow/skill --skill here-now`.
- `skills/here-now/` - generated compatibility mirror for Cursor/Codex plugin discovery.
- `hermes/` - Hermes community skill bundle.
- `.cursor-plugin/` and `.codex-plugin/` - marketplace/plugin manifests.
- `README.md` - public install and overview docs.

## Source Of Truth

The public skill repo is synced from the private here.now product repo.

- Product docs: [https://here.now/docs](https://here.now/docs)
- Agent context: [https://here.now/llms.txt](https://here.now/llms.txt)
- Full agent context: [https://here.now/llms-full.txt](https://here.now/llms-full.txt)
- API spec: [https://here.now/openapi.json](https://here.now/openapi.json)
- Skill version metadata: [https://here.now/api/skill/version](https://here.now/api/skill/version)

If local skill text and live docs disagree, prefer live docs for product capabilities and live API responses for active operations.

## Editing Guidance

- Keep `here-now/SKILL.md` and `skills/here-now/SKILL.md` synchronized.
- Keep helper scripts such as `publish.sh` and `drive.sh` compatible with documented behavior.
- Do not add claims for MCP, OAuth, Web Bot Auth, verified platform integrations, or official public CLI packaging unless those surfaces are live and maintained.
- Never commit credentials, API keys, Drive tokens, or `.herenow/state.json`.
- Prefer small, reviewable changes that preserve existing install commands and script output contracts.

## Verification

For skill/runtime changes, check:

```bash
curl -s https://here.now/api/skill/version
curl -s https://here.now/skill.md | head -20
curl -s https://here.now/.well-known/skills/index.json
curl -s https://here.now/.well-known/skills/here.now/SKILL.md | head -20
```
