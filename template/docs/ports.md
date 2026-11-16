# Local ports

__PROJECT__ uses the block __P__00–__P__99, clear of common defaults (3000, 5173, 8000, 8080, 8090, 5432).
Dev servers use `strictPort`. Change a port only with a decision row.

| band | port | service | hostname |
|------|------|---------|----------|
| edge | __P__00 | reverse proxy (Caddy), optional | `*.__PROJECT__.localhost` |
| tooling | __P__10–__P__19 | prototypes, docs, mocks of external APIs | |
| backends | __P__20 | API server | `api.__PROJECT__.localhost` |
| backends | __P__21–__P__29 | workers, job runner, embedded admin | |
| frontends | __P__30 | web app | `app.__PROJECT__.localhost` |
| frontends | __P__31–__P__39 | other apps, component sandbox | |
| data | __P__40–__P__49 | DB UIs, object store | |
| observability | __P__50–__P__59 | logs, traces | |
| tests | __P__90 | supervisor scratch | |
| tests | __P__91–__P__99 | one per worker (`$FLEET_PORT`, assigned by `fleet spawn`) | |
