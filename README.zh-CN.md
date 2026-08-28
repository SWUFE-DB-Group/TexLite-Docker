# TexLite Docker 部署

这是已发布 [TexLite](https://www.npmjs.com/package/texlite) 镜像的轻量 Docker Compose 启动仓库。配置、SQLite 数据、项目、PDF 与凭据均保存在仓库之外；宿主机只需安装 Docker 和 Docker Compose。

镜像以前台方式运行 TexLite（不使用 PM2），并内置 Git、Harper CLI、Harper Language Server 与固定的完整 TeX Live 环境。宿主机无需额外安装 LaTeX、Node.js、Git、Harper 或 PM2。

## 开始使用

```bash
git clone https://github.com/SWUFE-DB-Group/TexLite-Docker.git
cd texlite-docker
cp deployment.example.json deployment.json
# 首次启动前请编辑 deployment.json。
./scripts/compose.sh pull
./scripts/compose.sh up -d
```

第一次在交互式终端启动时，脚本会要求输入管理员密码。之后访问 <http://127.0.0.1:3040>。

`deployment.example.json` 是可直接复制、面向用户的启动配置。`deployment.json` 被 Git 忽略，并会在 Docker 启动前读取。Compose 直接使用 `zhongpu/texlite:latest`；启动或升级前执行 `./scripts/compose.sh pull`，即可拉取其当前版本。启动脚本会创建所配置的宿主机目录，并在内部处理 UID/GID 等容器细节。

| 配置项 | 用途 | 默认值 |
| --- | --- | --- |
| `host` | 宿主机绑定地址，例如 `127.0.0.1` 或 `0.0.0.0`。 | `127.0.0.1` |
| `port` | Docker 对外暴露的宿主机端口。 | `3040` |
| `configDir` | 存放 `texlite.config.json` 的宿主机目录。 | `~/.config/texlite-docker` |
| `dataDir` | 存放项目、SQLite 数据、PDF 和历史版本的宿主机目录。 | `~/.local/share/texlite-docker` |
| `siteName` | 首次初始化时创建的网站标题。 | `TexLite` |
| `adminEmail` | 首次初始化时创建的管理员联系邮箱。 | 留空 |
| `adminUsername` | 第一个管理员的用户名。 | `admin` |
| `adminDisplayName` | 第一个管理员的显示名称。 | `Administrator` |

初始管理员密码不会写入 `deployment.json`；首次执行 `up` 时，启动脚本会在终端中交互式请求密码。

## 持久化数据

默认的 `deployment.example.json` 挂载以下位置：

| 宿主机位置 | 容器位置 | 内容 |
| --- | --- | --- |
| `${XDG_CONFIG_HOME:-~/.config}/texlite-docker` | `/config` | `texlite.config.json` |
| `${XDG_DATA_HOME:-~/.local/share}/texlite-docker` | `/data` | SQLite 数据库、项目、保留 PDF、历史版本与临时文件 |

可在 `deployment.json` 中修改这两个宿主机路径。请备份它们：删除此 Git 检出或替换容器不会删除数据。不要让两个 TexLite 容器同时使用同一个数据目录。

## 常用命令

| 命令 | 含义 |
| --- | --- |
| `./scripts/compose.sh ps` | 查看 TexLite 容器的状态。 |
| `./scripts/compose.sh logs -f` | 持续显示容器日志；按 <kbd>Ctrl</kbd>+<kbd>C</kbd> 退出查看。 |
| `./scripts/compose.sh pull` | 下载当前的 `zhongpu/texlite:latest` 镜像；升级前应执行一次。 |
| `./scripts/compose.sh up -d` | 创建或更新容器，并在后台运行。 |
| `./scripts/compose.sh run --rm texlite requirements` | 在临时容器中执行 `requirements`，命令退出后自动删除该容器。仍会使用服务的常规环境变量以及挂载的配置和数据目录。 |
| `./scripts/compose.sh exec texlite texlite doctor` | 检查正在运行的安装，包括已挂载的配置和数据目录。 |
| `./scripts/compose.sh down` | 停止并移除容器和网络；持久化配置和数据不会被删除。 |

## 配置与安全

使用 `deployment.json` 配置 Docker 层面的宿主机端口、绑定地址及初始网站/管理员信息。这四项初始化信息仅在 TexLite 创建第一个配置和管理员时生效。之后，如需修改网站标题或管理员联系邮箱，请编辑挂载的 `texlite.config.json`；如需管理管理员账户，请使用 TexLite 的“用户管理”页面。示例仅将容器的 `3040` 端口暴露为 `127.0.0.1:3040`；除非明确在其前方配置 TLS 反向代理，否则请保持本机绑定。

TexLite 面向小型可信团队。请将项目源码、项目级 `latexmkrc`、Git token 和管理员凭据视为可信输入。

## 许可证

本部署仓库采用与 TexLite 一致的 [AGPL-3.0](LICENSE) 许可证。
