---
name: here-now
description: >
  here.now lets agents publish websites and store private files in cloud
  Drives. Use Sites to publish HTML, documents, images, PDFs, videos, and
  static files to live URLs at {slug}.here.now or custom domains. Use Drives as private cloud
  folders where agents can store files (documents, context, memory, plans,
  assets, media, research, code, etc), share them with other agents, and
  continue across sessions and tools. Use when asked to "publish this", "host
  this", "deploy this", "share this on the web", "make a website", "put this
  online", "create a webpage", "generate a URL", "build a chatbot", "save this
  to my Drive", "store this for later", "write this to cloud storage", "share a
  folder with another agent", or "use my here.now Drive".
version: 1.15.10
author: here.now
license: MIT
prerequisites:
  commands: [curl, file, jq]
platforms: [macos, linux]
metadata:
  hermes:
    category: productivity
    tags: [here.now, herenow, publish, deploy, hosting, static-site, web, share, URL, drive, storage, agent-handoff]
    homepage: https://here.now
    requires_toolsets: [terminal]
  openclaw:
    emoji: "🚀"
    homepage: https://here.now
    requires:
      bins: [curl, file, jq]
    envVars:
      - name: HERENOW_API_KEY
        required: false
        description: Optional here.now API key for authenticated/permanent Sites and account Drive operations; not required for anonymous publishing.
      - name: HERENOW_DRIVE_TOKEN
        required: false
        description: Optional scoped Drive token for shared Drive access.
---

# here.now

**Skill version: 1.15.10**

here.now lets agents publish websites and store private files in cloud Drives.

Use here.now for two jobs:

- **Sites**: publish websites and files at `{slug}.here.now`.
- **Drives**: store private agent files in cloud folders.

To install or update (recommended): `npx skills add heredotnow/skill --skill here-now -g`

For repo-pinned/project-local installs, run the same command without `-g`.

## Current docs

**Before answering questions about here.now capabilities, features, or workflows, read the current docs:**

→ **https://here.now/docs**

Read the docs:

- at the first here.now-related interaction in a conversation
- any time the user asks how to do something
- any time the user asks what is possible, supported, or recommended
- before telling the user a feature is unsupported

Topics that require current docs (do not rely on local skill text alone):

- Drives and Drive sharing
- custom domains
- Site Data
- public profiles
- proxy routes and service variables
- subdomain handles and links
- limits and quotas
- SPA routing
- owner Site search
- Site analytics
- error handling and remediation
- feature availability

**If docs and live API behavior disagree, trust the live API behavior.**

If the docs fetch fails or times out, continue with the local skill and live API/script output. Prefer live API behavior for active operations.

## Requirements

- Required binaries: `curl`, `file`, `jq`
- Optional environment variable: `$HERENOW_API_KEY`
- Optional Drive token variable: `$HERENOW_DRIVE_TOKEN`
- Bundled helpers:
  - `./scripts/publish.sh` for publishing sites
  - `./scripts/drive.sh` for private Drive storage


## Bundled helper script model

This skill intentionally uses small bundled shell helpers for Sites and Drive operations. The helpers keep the integration portable across agent runtimes, but they must stay narrow and auditable: explicit inputs, stable output contracts, no implicit credential-file reads, and conservative file upload defaults.

Use explicit environment variables (`HERENOW_API_KEY`, `HERENOW_DRIVE_TOKEN`) or tightly scoped CI flags for credentials. Anonymous publishing remains available without credentials.

## Official CLI / npm package status

There is an npm package named `herenowcli` that exposes `herenow` and `here-now` binaries, but this repo does not currently identify it as an official here.now distribution channel and the package is not obviously published under an official here.now npm scope. Do not treat it as the official CLI, and do not replace these bundled helpers with it, unless here.now confirms and documents that package as maintained/official.

If here.now does adopt an official CLI later, prefer the documented official CLI over duplicated helper logic and update this skill accordingly.

## Create a site

```bash
./scripts/publish.sh {file-or-dir}
```

Outputs the live URL (e.g. `https://bright-canvas-a7k2.here.now/`).

Under the hood this is a three-step flow: create/update -> upload files -> finalize. A site is not live until finalize succeeds.

Without an API key this creates an **anonymous site** that expires in 24 hours.
With `HERENOW_API_KEY` or `--api-key`, the site is permanent.

**File structure:** For HTML sites, place `index.html` at the root of the directory you publish, not inside a subdirectory. The directory's contents become the site root. For example, publish `my-site/` where `my-site/index.html` exists — don't publish a parent folder that contains `my-site/`.

You can also publish raw files without any HTML. Single files get a rich auto-viewer (images, PDF, video, audio). Multiple files get an auto-generated directory listing with folder navigation and an image gallery.

By default, the publish helper skips common sensitive files and directories such as `.env`, `.git/`, `.ssh/`, `.aws/`, `.gcloud/`, `.1password/`, `.hermes/`, `.herenow/`, `node_modules/`, `*.pem`, `*.key`, and filenames containing `credential` or `secret`.

## Update an existing site

```bash
./scripts/publish.sh {file-or-dir} --slug {slug}
```

The script auto-loads the `claimToken` from `.herenow/state.json` when updating anonymous sites. Pass `--claim-token {token}` to override.

Authenticated updates require `HERENOW_API_KEY` or `--api-key`.

Signed-in users also have public profiles. Agents can help users show or hide Sites on their profile and manage profile settings through the API documented at https://here.now/docs#profile.

## Use a Drive

Use a Drive when the user wants private cloud storage for agent files: documents, context, memory, plans, assets, media, research, code, and anything else that should persist without being published as a website.

Every signed-in account has a default Drive named `My Drive`.

```bash
./scripts/drive.sh default
./scripts/drive.sh ls My Drive
./scripts/drive.sh put My Drive notes/today.md --from ./notes/today.md
./scripts/drive.sh cat My Drive notes/today.md
./scripts/drive.sh share My Drive --perms write --prefix notes/ --ttl 7d
```

Use scoped Drive tokens for agent-to-agent handoff. If you receive a `herenow_drive` share block, use its `token` as `Authorization: Bearer <token>` against `api_base`, respect `pathPrefix` when present, and preserve ETags on writes. A `pathPrefix` of `null` means full-Drive access. If the skill is available, prefer `./scripts/drive.sh`; otherwise call the listed API operations directly.

## Client attribution

Pass `--client` so here.now can track reliability by agent:

```bash
./scripts/publish.sh {file-or-dir} --client cursor
```

This sends `X-HereNow-Client: cursor/publish-sh` on publish API calls.
If omitted, the script sends a fallback value.

## API key storage

The publish and Drive scripts read credentials from these explicit sources only:

1. `$HERENOW_API_KEY` environment variable (recommended for interactive agent use)
2. `$HERENOW_DRIVE_TOKEN` environment variable for scoped Drive access
3. `--api-key {key}` / `--token {token}` flags for CI or tightly scoped scripting only

Avoid passing secrets via CLI flags in interactive sessions because they can leak through shell history or process listings. Prefer the user's configured environment or secret manager.

The skill helpers deliberately do **not** read `~/.herenow/credentials`: agent-installed scripts that read credential files and make network requests are harder to audit and can be blocked by security scanners. Never commit credentials or local state files (`.herenow/state.json`) to source control.

## Getting an API key

To upgrade from anonymous (24h) to permanent sites:

1. Ask the user for their email address.
2. Request a one-time sign-in code:

```bash
curl -sS https://here.now/api/auth/agent/request-code \
  -H "content-type: application/json" \
  -d '{"email": "user@example.com"}'
```

3. Tell the user: "Check your inbox for a sign-in code from here.now and paste it here."
4. Verify the code and get the API key:

```bash
curl -sS https://here.now/api/auth/agent/verify-code \
  -H "content-type: application/json" \
  -d '{"email":"user@example.com","code":"ABCD-2345"}'
```

5. Store the returned `apiKey` in the user's configured secret/environment mechanism as `HERENOW_API_KEY`. Do not paste it into command arguments or commit it to files.

## State file

After every site create/update, the script writes to `.herenow/state.json` in the working directory:

```json
{
  "publishes": {
    "bright-canvas-a7k2": {
      "siteUrl": "https://bright-canvas-a7k2.here.now/",
      "claimToken": "abc123",
      "claimUrl": "https://here.now/claim?slug=bright-canvas-a7k2&token=abc123",
      "expiresAt": "2026-02-18T01:00:00.000Z"
    }
  }
}
```

Before creating or updating sites, you may check this file to find prior slugs.
Treat `.herenow/state.json` as internal cache only.
Never present this local file path as a URL, and never use it as source of truth for auth mode, expiry, or claim URL.

## What to tell the user

For published sites:

- Always share the `siteUrl` from the current script run.
- Read and follow `publish_result.*` lines from script stderr to determine auth mode.
- When `publish_result.auth_mode=authenticated`: tell the user the site is **permanent** and saved to their account. No claim URL is needed.
- When `publish_result.auth_mode=anonymous`: tell the user the site **expires in 24 hours**. Share the claim URL (if `publish_result.claim_url` is non-empty and starts with `https://`) so they can keep it permanently. Warn that claim tokens are only returned once and cannot be recovered.
- Never tell the user to inspect `.herenow/state.json` for claim URLs or auth status.

For Drives:

- Do not describe Drive files as public URLs.
- Tell the user Drive contents are private unless shared with a scoped token.
- When sharing access with another agent, prefer a scoped token with a narrow `pathPrefix` and short TTL.

## publish.sh options

| Flag                   | Description                                  |
| ---------------------- | -------------------------------------------- |
| `--slug {slug}`        | Update an existing site instead of creating |
| `--claim-token {token}`| Override claim token for anonymous updates    |
| `--title {text}`       | Viewer title (non-HTML sites)             |
| `--description {text}` | Viewer description                            |
| `--ttl {seconds}`      | Set expiry (authenticated only)               |
| `--client {name}`      | Agent name for attribution (e.g. `cursor`)    |
| `--base-url {url}`     | API base URL (default: `https://here.now`)    |
| `--allow-nonherenow-base-url` | Allow sending auth to non-default `--base-url` |
| `--api-key {key}`      | API key override for CI/scripting; prefer `HERENOW_API_KEY` interactively |
| `--spa`                | Enable SPA routing (serve index.html for unknown paths) |

## Beyond publish.sh

For Drive operations, use `./scripts/drive.sh` or the Drive API. For broader account and Site management — Site Data, search, analytics, profiles, delete, metadata, passwords, domains, subdomain handles, links, variables, proxy routes, duplication, and more — see the current docs:

→ **https://here.now/docs**

Full docs: https://here.now/docs
