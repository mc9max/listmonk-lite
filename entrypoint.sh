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

# Chain into the upstream entrypoint (LISTMONK_*_FILE secret loading, PUID
# handling) with the server binary as its command.
echo "[entrypoint] starting listmonk server..."
exec /usr/local/bin/docker-entrypoint.sh ./listmonk
