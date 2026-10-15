# syntax=docker/dockerfile:1
# Web image of «Щитовик»: Flutter Web build and the price catalog served by static-web-server.
# Build from the repository root:
#   docker build -f deploy/docker/Dockerfile --build-arg APP_BASE_URL=https://shchitovik.ru .
# TLS, the domain and the ports 80/443 belong to the edge proxy on the host (deploy/caddy).

# Keep in sync with .fvmrc; CI passes the version from there.
ARG FLUTTER_VERSION=3.47.6
ARG SWS_VERSION=2.44.0
ARG BUSYBOX_VERSION=1.37.0

# --- Flutter Web build -------------------------------------------------------------------------
# Public Flutter images lag behind the version pinned in .fvmrc, so the SDK is installed here;
# the layer does not depend on the sources and stays cached.
FROM debian:trixie-slim AS web

ARG FLUTTER_VERSION
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter
ENV PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}
RUN flutter config --no-analytics --no-cli-animations \
    && flutter precache --web \
    && dart --disable-analytics

# Public URL of the site; the app downloads the price catalog from <APP_BASE_URL>/catalog/.
ARG APP_BASE_URL=https://shchitovik.ru
ENV PUB_CACHE=/var/cache/pub
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/var/cache/pub \
    bash scripts/bootstrap.bash \
    && cd app \
    && flutter build web --release \
      --dart-define=ENVIRONMENT=prod --dart-define=CATALOG_URL=${APP_BASE_URL} \
    # A release build loads CanvasKit from the gstatic CDN; the local copy (~36 MB) is never used.
    && rm -rf build/web/canvaskit

# --- Price catalog -----------------------------------------------------------------------------
FROM python:3.13-alpine AS catalog

WORKDIR /src
COPY tools/catalog tools/catalog
COPY engine/estimate_core/data engine/estimate_core/data
RUN python3 -I tools/catalog/validate_catalogs.py \
    && python3 -I tools/catalog/publish_catalog.py /out

# --- Runtime: static binaries only -------------------------------------------------------------
FROM joseluisq/static-web-server:${SWS_VERSION} AS sws
FROM busybox:${BUSYBOX_VERSION}-musl AS busybox

FROM scratch

COPY --from=sws /static-web-server /static-web-server
# Static busybox for the container healthcheck (wget); scratch has no shell.
COPY --from=busybox /bin/busybox /busybox
COPY deploy/docker/sws.toml /sws.toml
COPY --from=web /src/app/build/web /public
COPY --from=catalog /out/catalog /public/catalog

USER 65534:65534
EXPOSE 8080
STOPSIGNAL SIGQUIT
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/busybox", "wget", "-q", "--spider", "http://127.0.0.1:8080/health"]
ENTRYPOINT ["/static-web-server", "--config-file", "/sws.toml"]
