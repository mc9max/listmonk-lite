#!/bin/sh
set -e

# Listmonk entrypoint for Railway — see Dockerfile header for the why.

# koanf does no shell expansion, so compose the listen address here from the
# Railway-injected PORT. 0.0.0.0 because localhost would only bind loopback.
export LISTMONK_app__address="0.0.0.0:${PORT:-9000}"
echo "[entrypoint] listen address: ${LISTMONK_app__address}"

# Wait for postgres AND run first-boot schema setup in one loop: --install is
# idempotent (skips when the settings table exists) and exits non-zero while
# the DB is unreachable, so retrying it is both the readiness probe and the
# migration step. Without admin envs it prints "no superadmin user created" —
# the web setup wizard on first visit creates the superuser instead.
echo "[entrypoint] waiting for postgres / installing schema..."
until ./listmonk --install --yes --idempotent; do
  echo "[entrypoint] postgres not ready, retrying in 5s..."
  sleep 5
done

# Fix two DB-seeded settings rows that listmonk's initSettings() loads OVER
# env vars (see Dockerfile header). Idempotent: safe to re-run every boot.
PSQL="psql -h ${LISTMONK_db__host} -p 5432 -U listmonk -d listmonk -v ON_ERROR_STOP=1 -q -t -A"
export PGPASSWORD="${LISTMONK_db__password}"

# 1. Media uploads: the seed default is the ephemeral "./uploads" dir — point
#    it at the Railway volume mount instead so campaign images survive restarts.
mkdir -p /data/uploads
$PSQL -c "UPDATE settings SET value = '\"/data/uploads\"' WHERE key = 'upload.filesystem.upload_path' AND value <> '\"/data/uploads\"';"
echo "[entrypoint] upload path pinned to /data/uploads."

# 2. Root URL: the seed default is http://localhost:9000, which would break
#    media links and email URLs. Rewrite it to the public Railway domain.
if [ -n "${RAILWAY_PUBLIC_DOMAIN}" ]; then
  $PSQL -c "UPDATE settings SET value = '\"https://${RAILWAY_PUBLIC_DOMAIN}\"' WHERE key = 'app.root_url';"
  echo "[entrypoint] root URL set to https://${RAILWAY_PUBLIC_DOMAIN}."
else
  echo "[entrypoint] RAILWAY_PUBLIC_DOMAIN unset; keeping seeded root URL."
fi

# Chain into the upstream entrypoint (LISTMONK_*_FILE secret loading, PUID
# handling) with the server binary as its command.
echo "[entrypoint] starting listmonk server..."
exec /usr/local/bin/docker-entrypoint.sh ./listmonk
