# Railway wacli template

Minimal Railway template for [wacli](https://github.com/openclaw/wacli) with a prebuilt image, persistent WhatsApp sessions, and continuous sync.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/wacli-self-hosted)

## Pair your phone

Open the wacli service's SSH terminal in Railway and run:

```sh
wacli-pair
```

In WhatsApp, open **Settings → Linked devices → Link a device** and scan the QR code. To link with a phone-number code instead, run `wacli-pair --phone +15551234567`. Pairing finishes after the initial sync idles; the service then starts continuous sync automatically.

Use `wacli-run --json auth status` to check the session and `wacli-run messages search "invoice"` to search synced messages. `wacli-run` runs commands as the same user that owns the session. For local CLI access, use `railway ssh --service wacli -- wacli-pair` from a linked project.

## Storage and operation

Mount one persistent volume at `/data`. The session, SQLite search index, and downloaded media live in `/data/store`. Keep one replica per volume. Before pairing, the worker waits without opening a WhatsApp connection; after pairing, it runs `wacli sync --follow`. Railway restarts the worker if it exits.

No public domain, HTTP API, or separate database is required. Terminal access is controlled by your Railway project permissions. The template does not send messages automatically.

The image contains wacli, verified against the release archive's SHA-256 checksum, and FFmpeg for media support. GitHub Actions builds and smoke-tests the image before publishing `latest` and `sha-<commit>` tags to GHCR. Renovate updates the release tag and checksum together in `Dockerfile`.

See the [wacli documentation](https://wacli.sh) for commands and pairing details. wacli uses the WhatsApp Web protocol and is not affiliated with WhatsApp or Meta.
