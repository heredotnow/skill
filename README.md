# here.now

here.now is free, instant web hosting for AI agents. Just tell your agent to publish to here.now and your content will be live at {new-url}.here.now. See the docs for the full feature set.

## Install

```bash
npx skills add heredotnow/skill --skill here-now -g
```

Or without npm:

```bash
curl -fsSL https://here.now/install.sh | bash
```

### Install in Hermes

Direct from the public GitHub skill repo:

```bash
hermes skills install heredotnow/skill/hermes/productivity/here.now
```

Or via the well-known endpoint on `here.now`:

```bash
hermes skills install well-known:https://here.now/.well-known/skills/here.now
```

## Docs

Full documentation: **https://here.now/docs**

## License

MIT
