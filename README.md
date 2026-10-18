# Listmonk

Self-hosted newsletter and mailing-list manager — a Mailchimp/Substack alternative you fully own. Create lists, design campaigns with the visual template editor, schedule and send to unlimited subscribers, and track opens, clicks, and bounces. One-click deploy on Railway with managed Postgres.

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/listmonk-3?utm_campaign=listmonk-lite)

## Deploy and Host

Click **Deploy on Railway** above. The deploy form is zero-field: the Postgres companion password is auto-generated and the app is auto-wired to it over the private network. On first boot the service installs the database schema, then visit the public URL to create your superuser in the setup wizard.

- **Runtime:** Go single binary (listmonk v6.2.0, pinned by digest) + PostgreSQL 16 companion
- **Memory at rest:** ~30–60 MB for the app, ~100–200 MB for Postgres
- **Port:** Railway-injected `PORT` (composed into `LISTMONK_app__address` at boot)
- **Persistence:** all data (subscribers, campaigns, templates, media, settings) lives in Postgres on a Railway volume at `/var/lib/postgresql/data`; uploaded media files persist on the `listmonk-data` volume at `/data`
- **Healthcheck:** `/health` (public, unauthenticated)

## Why Deploy

Newsletter platforms charge per subscriber and hold your list hostage. Listmonk is AGPL-3.0 open source with no subscriber limits — you bring your own SMTP (SendGrid, SES, Postmark, or your own mail server) and pay only Railway usage. Double opt-in lists, bounce handling, and template versioning are built in.

## Common Use Cases

- Weekly/monthly newsletters for a blog, product, or community
- Product launch announcements and drip campaigns
- Transactional-ish bulk mail (receipts, digests) via the REST API
- Multi-list audience management with segments and custom subscriber attributes

## Configuration

Every variable the deployment consumes. The first three are set automatically by the template; the rest are optional and set later in the Railway dashboard if needed.

| Variable | Default | What it does |
|---|---|---|
| `LISTMONK_db__host` | `${{postgres.RAILWAY_PRIVATE_DOMAIN}}` | Postgres host, auto-wired over the private network |
| `LISTMONK_db__password` | `${{postgres.POSTGRES_PASSWORD}}` | Postgres password, auto-wired from the companion |
| `POSTGRES_PASSWORD` | `${{secret(32)}}` | Auto-generated password for the Postgres companion |
| `LISTMONK_app__address` | `0.0.0.0:${PORT}` (composed at boot) | Interface/port the web UI binds to |
| `LISTMONK_db__port` | `5432` (baked) | Postgres port |
| `LISTMONK_db__user` | `listmonk` (baked) | Postgres user |
| `LISTMONK_db__database` | `listmonk` (baked) | Postgres database (created by `POSTGRES_DB`) |
| `LISTMONK_db__ssl_mode` | `disable` (baked) | Private network needs no TLS |
| `LISTMONK_upload__filesystem__upload_path` | `/data/uploads` (baked, on the `listmonk-data` volume) | Where uploaded campaign media files persist |
| `LISTMONK_ADMIN_USER` | unset | If set (min 3 chars) with `LISTMONK_ADMIN_PASSWORD`, the superuser is created at install instead of via the web wizard |
| `LISTMONK_ADMIN_PASSWORD` | unset | Min 8 chars; required together with `LISTMONK_ADMIN_USER` |
| `LISTMONK_ADMIN_API_USER` | unset | Optional API superuser (requires the two above, min 3 chars) |
| `PORT` | injected by Railway | Port the service must listen on |

SMTP is configured in the web UI under **Settings → SMTP** and stored in the database — it is not an env var. Two more DB settings are rewritten automatically at every boot by `entrypoint.sh` (listmonk loads DB settings over env vars, so these can't be env-driven): `upload.filesystem.upload_path` → `/data/uploads` (the `listmonk-data` volume, so campaign images survive restarts) and `app.root_url` → `https://${RAILWAY_PUBLIC_DOMAIN}` (correct media/email links).

### Deployment Dependencies

- **Plan:** works on Railway's Hobby plan; Postgres companion needs the volume add-on (a few GB is plenty).
- **After deploy:** open the public URL, create your superuser, then add your SMTP credentials in Settings → SMTP before sending campaigns. Import subscribers via CSV or the API.
