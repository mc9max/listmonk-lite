# PostgreSQL 16 companion for the Listmonk Railway template.
#
# Bakes every constant as ENV because Railway's `templates create` only
# carries ${{...}} expressions into template defaults — literals would land
# on the deploy form as required fields. The only variable on this service
# is POSTGRES_PASSWORD (${{secret(32)}}), which listmonk references as
# ${{postgres.POSTGRES_PASSWORD}}.
#
# Volume handling: the official postgres image starts as root and its
# entrypoint chowns $PGDATA, which tolerates Railway's root-owned volumes.
# PGDATA is a SUBDIR of the mount because initdb refuses a volume mount
# point directly (it contains lost+found). The volume is created at deploy
# time on /var/lib/postgresql/data via `railway volume add`.
#
# Listmonk needs nothing but the stock extensions, so plain postgres:16 —
# not pgvector — is the right (lighter) companion.

FROM postgres:16@sha256:ca0bd484cb98bf4b24eb1010e73fb3fcbd6714d240fbc1a10eea5b7dbecb641d

ENV PGDATA=/var/lib/postgresql/data/pgdata \
    POSTGRES_USER=listmonk \
    POSTGRES_DB=listmonk

LABEL org.opencontainers.image.source="https://github.com/mc9max/listmonk-lite"
