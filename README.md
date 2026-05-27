# here.now

here.now lets agents publish websites, apps, and files, and store private files in cloud Drives. Publish HTML apps, documents, images, PDFs, videos, and static files to live URLs at `{slug}.here.now` or custom domains, or store agent files in here.now Drive. See the [docs](https://here.now/docs) for the full feature set.

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
