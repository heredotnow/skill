---
name: here-now
description: >
  Publish files and folders to the web instantly. Use when asked to "publish this",
  "host this", "deploy this", "share this on the web", "make a website", or
  "put this online". Outputs a live URL at <slug>.here.now.
---

# here.now

**Skill version: 1.4**

Publish any file or folder to the web and get a live URL back. Static hosting only.

To check for skill updates: `npx skills add heredotnow/skill --skill here-now`

## Publish

```bash
./scripts/publish.sh <file-or-dir>
```

Outputs the live URL (e.g. `https://bright-canvas-a7k2.here.now/`).

Without an API key this creates an **anonymous publish** that expires in 24 hours.
With a saved API key, the publish is permanent.

## Update an existing publish

```bash
./scripts/publish.sh <file-or-dir> --slug <slug>
```

The script auto-loads the `claimToken` from `.herenow/state.json` when updating anonymous publishes. Pass `--claim-token <token>` to override.

Authenticated updates require a saved API key.

## API key storage

The publish script reads the API key from these sources (first match wins):

1. `--api-key <key>` flag (CI/scripting only — avoid in interactive use)
2. `$HERENOW_API_KEY` environment variable
3. `~/.herenow/credentials` file (recommended for agents)

To store a key, write it to the credentials file:

```bash
mkdir -p ~/.herenow && echo "<API_KEY>" > ~/.herenow/credentials && chmod 600 ~/.herenow/credentials
```

**IMPORTANT**: Never pass the API key directly in shell commands. Always write it to `~/.herenow/credentials` using the command above. This keeps the key out of terminal history and logs.

## State file

After every publish, the script writes to `.herenow/state.json` in the working directory:

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

Before publishing, check this file. If the user already has a publish for the same content, update it with `--slug` instead of creating a new one.

## What to tell the user

- Always share the `siteUrl`.
- For anonymous publishes, also share the `claimUrl` so they can keep it permanently.
- Warn: the claim token is only returned once and cannot be recovered.

## Limits

|                | Anonymous          | Authenticated                |
| -------------- | ------------------ | ---------------------------- |
| Max file size  | 250 MB             | 5 GB                         |
| Expiry         | 24 hours           | Permanent (or custom TTL)    |
| Rate limit     | 5 / hour / IP      | 60 / hour / account          |
| Account needed | No                 | Yes (get key at here.now)    |

## Getting an API key

To upgrade from anonymous (24h) to permanent publishing:

1. Ask the user for their email address.
2. Call the sign-up endpoint to send them a magic link:

```bash
curl -sS https://here.now/api/auth/login \
  -H "content-type: application/json" \
  -d '{"email": "user@example.com"}'
```

3. Tell the user: "Check your inbox for a sign-in link from here.now. Click it, then copy your API key from the dashboard."
4. Once the user provides the key, save it:

```bash
mkdir -p ~/.herenow && echo "<API_KEY>" > ~/.herenow/credentials && chmod 600 ~/.herenow/credentials
```

## Script options

| Flag                   | Description                                  |
| ---------------------- | -------------------------------------------- |
| `--slug <slug>`        | Update existing publish instead of creating   |
| `--claim-token <token>`| Override claim token for anonymous updates    |
| `--title <text>`       | Viewer title (non-site publishes)             |
| `--description <text>` | Viewer description                            |
| `--ttl <seconds>`      | Set expiry (authenticated only)               |
| `--base-url <url>`     | API base URL (default: `https://here.now`)    |
| `--api-key <key>`      | API key override (prefer credentials file)    |

## Beyond the script

For delete, metadata patch, claim, list, and other operations, see [references/REFERENCE.md](references/REFERENCE.md).

Full docs: https://here.now/docs
