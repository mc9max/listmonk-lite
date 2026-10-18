# Listmonk on Railway — newsletter & mailing-list manager (listmonk-lite).
#
# WHY THIS WRAPPER EXISTS (house-style notes):
#
# - FROM pins the upstream multi-arch image by digest, never :latest, so every
#   deploy builds the exact binary we tested.
# - USER root: the image's own entrypoint defaults PUID=0 (root) and the
#   official Dockerfile has no USER directive; staying root keeps behavior
#   identical to upstream and avoids EACCES surprises on any future volume.
# - LISTMONK_db__* constants are baked as ENV because `railway templates
#   create` carries ONLY ${{...}} expressions into template defaults — plain
#   literals would land on the one-click deploy form as required fields. The
#   only two template variables are LISTMONK_db__host and
#   LISTMONK_db__password, both single ${{...}} refs to the postgres companion
#   (koanf maps LISTMONK_db__host -> db.host etc. via the LISTMONK_ prefix).
# - Upload path ENV (LISTMONK_upload__filesystem__upload_path=/data/uploads) is a
#   belt-and-braces fallback: listmonk's initSettings() loads the DB settings
#   table OVER env vars, so entrypoint.sh rewrites the
#   upload.filesystem.upload_path and app.root_url rows in the DB at boot —
#   that UPDATE is what actually takes effect.
# - No Docker HEALTHCHECK: the Alpine base has no curl/wget; Railway's
#   external healthcheckPath (/health, a public unauthenticated endpoint)
#   covers it.
# - postgresql16-client is added so the entrypoint can fix two DB-seeded
#   settings rows (initSettings() loads DB values OVER env vars): the upload
#   path and the app root URL. Without this, campaign media would land in the
#   ephemeral ./uploads dir and email/media links would point at
#   http://localhost:9000.
# - ENTRYPOINT is our script (not upstream docker-entrypoint.sh) because we
#   must (a) bind the Railway-injected PORT — koanf does no shell expansion,
#   so LISTMONK_app__address is composed here, and (b) run the idempotent
#   --install as a readiness gate: it fails fast while postgres is down, so
#   retrying it doubles as the DB wait. It then chains into the upstream
#   entrypoint to preserve _FILE secret loading and PUID handling.

FROM listmonk/listmonk:v6.2.0@sha256:f535d59e14991337a9f2d570273685378ae86b0d7698c3e00da444e3bc205286

USER root

ENV LISTMONK_db__port=5432 \
    LISTMONK_db__user=listmonk \
    LISTMONK_db__database=listmonk \
    LISTMONK_db__ssl_mode=disable \
    LISTMONK_upload__filesystem__upload_path=/data/uploads

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    apk --no-cache add postgresql16-client

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]

LABEL org.opencontainers.image.source="https://github.com/mc9max/listmonk-lite"
