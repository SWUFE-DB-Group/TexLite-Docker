# syntax=docker/dockerfile:1

ARG NODE_VERSION=24
ARG TEXLIVE_VERSION=TL2026-2026-08-23
ARG HARPER_VERSION=2.7.0
ARG TEXLITE_VERSION=0.8.4

# TexLite requires Node.js 24 or newer. Copy the official Node runtime into
# the TeX Live image. These component versions are maintained by the image
# publisher, not selected by each deployment.
#
# The date-stamped `full` tag is deliberately pinned so a rebuild does not
# silently change the LaTeX distribution. Updating TEXLIVE_VERSION and publishing a
# new Docker release upgrades TeX Live without requiring a TexLite npm release.
FROM node:${NODE_VERSION}-bookworm-slim AS node-runtime

FROM registry.gitlab.com/islandoftex/images/texlive:${TEXLIVE_VERSION}-full

ARG TARGETARCH
ARG HARPER_VERSION
ARG TEXLITE_VERSION

USER root

COPY --from=node-runtime /usr/local /usr/local

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl git tini python3 make g++ \
    && rm -rf /var/lib/apt/lists/* \
    && harper_target_arch="${TARGETARCH:-$(dpkg --print-architecture)}" \
    && case "$harper_target_arch" in \
         amd64) harper_arch=x86_64 ;; \
         arm64) harper_arch=aarch64 ;; \
         *) echo "Unsupported Harper architecture: ${harper_target_arch}" >&2; exit 1 ;; \
       esac \
    && curl --fail --location --retry 3 --output /tmp/harper-cli.tar.gz \
         "https://github.com/Automattic/harper/releases/download/v${HARPER_VERSION}/harper-cli-${harper_arch}-unknown-linux-gnu.tar.gz" \
    && curl --fail --location --retry 3 --output /tmp/harper-ls.tar.gz \
         "https://github.com/Automattic/harper/releases/download/v${HARPER_VERSION}/harper-ls-${harper_arch}-unknown-linux-gnu.tar.gz" \
    && tar -xzf /tmp/harper-cli.tar.gz -C /usr/local/bin harper-cli \
    && tar -xzf /tmp/harper-ls.tar.gz -C /usr/local/bin harper-ls \
    && chmod 0755 /usr/local/bin/harper-cli /usr/local/bin/harper-ls \
    && rm -f /tmp/harper-cli.tar.gz /tmp/harper-ls.tar.gz \
     && npm install --global --omit=dev "texlite@${TEXLITE_VERSION}" \
    && node --version \
    && texlite --version \
    && harper-cli --version \
    && harper-ls --version

COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/texlite-docker-entrypoint
COPY scripts/create-config.mjs /usr/local/lib/texlite-docker/create-config.mjs

LABEL org.opencontainers.image.title="TexLite Docker deployment" \
      org.opencontainers.image.description="TexLite with a pinned full TeX Live runtime"

EXPOSE 3040

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e 'fetch("http://127.0.0.1:3040/api/health").then((response) => process.exit(response.ok ? 0 : 1)).catch(() => process.exit(1))'

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/texlite-docker-entrypoint"]
CMD ["serve"]
