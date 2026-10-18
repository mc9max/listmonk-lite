[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/listmonk?utm_campaign=listmonk-lite)

# Deploy and Host

Self-hosted newsletter and mailing-list manager (listmonk v6.2.0, AGPL-3.0) with a PostgreSQL 16 companion. One-click deploy: the form has zero fields — the Postgres password is auto-generated and the app is auto-wired over the private network. First boot installs the schema; the setup wizard on the public URL creates your superuser.

## About Hosting

- Services: `listmonk` (Go binary) + `postgres` (PostgreSQL 16)
- Volumes: 2 — Postgres data at `/var/lib/postgresql/data`, app uploads at `/data` (`listmonk-data`)
- Memory at rest: ~30–60 MB app, ~100–200 MB Postgres
- Healthcheck: `GET /health` → 200 (public, unauthenticated)

## Why Deploy

Own your mailing list instead of renting it per subscriber. Listmonk gives you unlimited lists and subscribers, a visual campaign editor, scheduling, bounce handling, and open/click analytics — you only pay Railway usage plus your SMTP provider.

## Common Use Cases

- Newsletters for blogs, products, and communities
- Launch announcements and drip campaigns
- Bulk mail via the REST API (digests, notifications)
- Multi-list audiences with segments and custom attributes

## Dependencies for

### Deployment Dependencies

- Railway Hobby plan or higher (Postgres volume needs a few GB)
- After deploy: create the superuser in the setup wizard, then configure SMTP in **Settings → SMTP** before sending. SMTP lives in the database, not in env vars.

**Environment reference (condensed):** `LISTMONK_app__root_url` = `https://${{RAILWAY_PUBLIC_DOMAIN}}`, `LISTMONK_db__host` = `${{postgres.RAILWAY_PRIVATE_DOMAIN}}`, `LISTMONK_db__password` = `${{postgres.POSTGRES_PASSWORD}}`, `POSTGRES_PASSWORD` = `${{secret(32)}}` — all auto-wired. Baked into the image: `LISTMONK_db__port=5432`, `LISTMONK_db__user=listmonk`, `LISTMONK_db__database=listmonk`, `LISTMONK_db__ssl_mode=disable`, `LISTMONK_upload__filesystem__upload_path=/data/uploads` (volume-persisted). Optional, set later: `LISTMONK_ADMIN_USER` + `LISTMONK_ADMIN_PASSWORD` (skip the web wizard), `LISTMONK_ADMIN_API_USER`.
