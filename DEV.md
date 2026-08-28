# Development and Release Guide

This document is for maintainers of the Docker distribution. End users should follow `README.md` or `README.zh-CN.md`.

## Runtime design

The distribution deliberately produces one runtime image. TexLite must execute `latexmk`, TeX engines, `texcount`, Git, and `harper-ls` directly, so splitting TeX Live into a separate service would require a compiler RPC protocol and add operational failure modes.

The image is still released independently from the TexLite npm package. The publisher fixes these components in `Dockerfile`:

| Component | Current value |
| --- | --- |
| TexLite | `texlite@0.8.1` |
| TeX Live base | `registry.gitlab.com/islandoftex/images/texlive:TL2026-2026-08-23-full` |
| Harper CLI / Language Server | `2.7.0` |

`full` is the only published TeX Live variant. It is the most reliable option for arbitrary paper templates and includes the standard tools TexLite expects. The date-stamped upstream tag avoids a moving `latest` base. Do not add `tlmgr install` during the build: it would undermine that reproducibility by downloading from a rolling repository.

To release a newer TeX Live snapshot, update only its fixed `FROM` line, test, and publish a new Docker release tag. The installed TexLite npm version can remain unchanged. Conversely, updating TexLite does not require a TeX Live change.

## Local maintenance

Run the launcher for an end-to-end local build:

```bash
docker build -t zhongpu/texlite:latest .
./scripts/compose.sh up -d
./scripts/compose.sh logs -f
./scripts/compose.sh down
```

Before publishing, run the static checks used by CI:

```bash
bash -n docker-entrypoint.sh scripts/compose.sh
node --check scripts/create-config.mjs
docker build --check --file Dockerfile .
```

Then perform a local image build and basic smoke test when practical:

```bash
docker build -t zhongpu/texlite:latest .
./scripts/compose.sh up -d
./scripts/compose.sh run --rm texlite requirements
./scripts/compose.sh exec texlite texlite doctor
```

End users copy `deployment.example.json` to ignored `deployment.json`; the launcher translates its small set of host and first-initialization settings into the internal Compose configuration before Docker starts. The persistent configuration and data directories are intentionally outside the repository. Do not test two containers against the same data directory at once.

## GitHub Actions and Docker Hub

`.github/workflows/ci.yml` performs static validation on pushes and pull requests. `.github/workflows/publish.yml` builds and pushes a multi-architecture (`linux/amd64`, `linux/arm64`) Docker image only when a Git tag matching `vMAJOR.MINOR.PATCH` is pushed.

Before the first Docker Hub release, configure the GitHub repository settings:

| GitHub setting | Name | Required value |
| --- | --- | --- |
| Actions secret | `DOCKERHUB_TOKEN` | Docker Hub access token with permission to push images |

The token must be stored as an Actions **secret**, never in source code, a workflow file, a Compose file, or local deployment configuration. The workflow derives the destination image as:

```text
zhongpu/texlite
```

For example, tag `v0.1.0` produces `zhongpu/texlite:0.1.0`, its normal semver aliases, and `latest` for a stable release.

## Release procedure

1. Update the fixed component version(s) in `Dockerfile` deliberately.
2. Run the static checks and a local smoke test.
3. Commit the release changes.
4. Create and push an explicit Docker-distribution tag:

   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

5. Verify the GitHub Actions publish workflow and the resulting Docker Hub manifest.
6. Test the published image through Compose:

   ```bash
   ./scripts/compose.sh pull
   ./scripts/compose.sh up -d
   ```

The end-user Compose launcher intentionally follows `zhongpu/texlite:latest`; each stable release also retains its exact semver tag for traceability and rollback outside this launcher.
