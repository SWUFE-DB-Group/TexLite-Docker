# TexLite Docker Deployment

This repository is a small Docker Compose launcher for a released [TexLite](https://www.npmjs.com/package/texlite) image. It keeps configuration, SQLite data, projects, PDFs, and credentials outside the checkout. `docker` and `docker-compose` are the only host requirements.


## Get Started

```bash
git clone https://github.com/SWUFE-DB-Group/TexLite-Docker.git
cd texlite-docker
cp deployment.example.json deployment.json
# Edit deployment.json before the first start.
./scripts/compose.sh pull
./scripts/compose.sh up -d
```

The first interactive launch asks for the administrator password. Then open <http://127.0.0.1:3040>.

`deployment.example.json` is a ready-to-copy, user-facing startup configuration. `deployment.json` is ignored by Git and is read before Docker starts. Compose directly uses `zhongpu/texlite:latest`; run `./scripts/compose.sh pull` before starting or upgrading to fetch its current version. The wrapper creates the configured host directories and handles container details such as UID/GID internally.

| Setting | Purpose | Default |
| --- | --- | --- |
| `host` | Host address to bind, such as `127.0.0.1` or `0.0.0.0`. | `127.0.0.1` |
| `port` | Host port exposed by Docker. | `3040` |
| `configDir` | Host directory that stores `texlite.config.json`. | `~/.config/texlite-docker` |
| `dataDir` | Host directory for projects, SQLite data, PDFs, and histories. | `~/.local/share/texlite-docker` |
| `siteName` | Website title created at the first initialization. | `TexLite` |
| `adminEmail` | Administrator contact email created at the first initialization. | Empty |
| `adminUsername` | First administrator username. | `admin` |
| `adminDisplayName` | First administrator display name. | `Administrator` |

The initial administrator password is intentionally not in `deployment.json`; the launcher requests it interactively on the first `up` command.

## Persistent data

The default `deployment.example.json` mounts these locations:

| Host location | Container location | Contents |
| --- | --- | --- |
| `${XDG_CONFIG_HOME:-~/.config}/texlite-docker` | `/config` | `texlite.config.json` |
| `${XDG_DATA_HOME:-~/.local/share}/texlite-docker` | `/data` | SQLite database, projects, retained PDFs, histories, and temporary work |

You can change both host paths in `deployment.json`. Back them up: deleting this Git checkout or replacing the container does not delete them. Do not run two TexLite containers against the same data directory.

## Useful commands

| Command | Meaning |
| --- | --- |
| `./scripts/compose.sh ps` | Show the TexLite container status. |
| `./scripts/compose.sh logs -f` | Stream the container log until you press <kbd>Ctrl</kbd>+<kbd>C</kbd>. |
| `./scripts/compose.sh pull` | Download the current `zhongpu/texlite:latest` image. Run this before an upgrade. |
| `./scripts/compose.sh up -d` | Create or update the container and run it in the background. |
| `./scripts/compose.sh run --rm texlite requirements` | Run `requirements` in a temporary container, then remove it when the command exits. It still uses the service's normal environment and mounted configuration and data directories. |
| `./scripts/compose.sh exec texlite texlite doctor` | Check the running installation, including its mounted configuration and data directory. |
| `./scripts/compose.sh down` | Stop and remove the container and network. Persistent configuration and data are retained. |

## Configuration and security

Use `deployment.json` for Docker-level settings and the initial site/administrator values. Those four initialization values apply only while TexLite creates its first configuration and administrator. Afterwards, edit the mounted `texlite.config.json` to change the website name or administrator contact email, and use TexLite's User Management page to manage administrators. The example publishes the container's port `3040` only on `127.0.0.1:3040`; keep that local binding unless you deliberately place a TLS-enabled reverse proxy in front of it.

TexLite is designed for small, trusted teams. Treat project sources, project-level `latexmkrc`, Git tokens, and administrator credentials as trusted inputs.

## License

This deployment repository is licensed under [AGPL-3.0](LICENSE), matching TexLite.
