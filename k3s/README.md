# K3s DEB 包

同一份官方 K3s 二进制生成两个互斥的包，支持 amd64 和 arm64：

| 包名 | 首次安装的服务 | 命令 |
|------|---------------|------|
| ys-k3s-master | k3s.service | k3s server |
| ys-k3s-worker | k3s-agent.service | k3s agent |

默认版本为 `1.36.5+k3s1`，来自 2026-10-23 核对的官方 stable 通道。官方 latest 通道为 `1.37.1+k3s1`，本包不自动跨通道或选择集群升级路径。

## 构建

依赖 `bash`、`curl`、`nfpm`、`sha256sum` 或 `shasum`。下载二进制后，用同一 release 的官方 SHA-256 清单校验，再为两个角色分别打包。

```bash
./build.sh
./build.sh '1.36.5+k3s1' 'amd64 arm64'
```

构建结果：

```text
build/amd64/ys-k3s-master_1.36.5+k3s1_amd64.deb
build/amd64/ys-k3s-worker_1.36.5+k3s1_amd64.deb
build/arm64/ys-k3s-master_1.36.5+k3s1_arm64.deb
build/arm64/ys-k3s-worker_1.36.5+k3s1_arm64.deb
```

## 首次安装

要求 systemd，安装时不下载其他文件，也不创建或覆盖集群配置。只生成对应 unit，以及不存在时的 `kubectl`、`crictl`、`ctr` 符号链接，不自动启动或启用服务。

```bash
# master / server
sudo apt install ys-k3s-master
sudo install -d -m 0755 /etc/rancher/k3s
# 按集群需要创建 /etc/rancher/k3s/config.yaml
sudo systemctl enable --now k3s
```

```bash
# worker / agent，在另一台节点上安装
sudo apt install ys-k3s-worker
sudo install -d -m 0755 /etc/rancher/k3s
sudo install -m 0600 /dev/null /etc/rancher/k3s/config.yaml
sudoedit /etc/rancher/k3s/config.yaml
```

worker 的最小配置：

```yaml
server: https://YOUR_SERVER:6443
token: YOUR_NODE_TOKEN
```

配置后执行 `sudo systemctl enable --now k3s-agent`。包不管理节点 token、数据目录或 Kubernetes 资源。

## 已有 K3s 服务

安装前存在 `k3s.service`、`k3s-agent.service` 或官方命名规则下的 `k3s-*.service` 时，进入二进制更新模式。检查 systemd unit 文件、已加载服务和磁盘上的 unit，包含停用、停止和 masked 服务。

- 更新包内 `/usr/local/bin/k3s`，并根据已有服务的 `ExecStart` 更新自定义目录下的 `k3s`。自定义路径使用同目录临时文件原子替换，保留符号链接。
- 保留原 unit、环境文件、配置、数据和运行状态，不执行 daemon-reload、enable、start、stop 或 restart，也不补建另一角色的 unit 或命令链接。
- 已有服务决定实际角色，包名不会把现有 agent 改成 server，或把 server 改成 agent。
- 无法安全识别 `ExecStart` 时明确报错，不尝试重新初始化。离线解析发现 drop-in 时要求在 systemd 可查询的环境中重新配置。

按现有角色选择对应包，并先确认所选版本适用于集群的升级路径。更新后手动安排重启，例如：

```bash
sudo apt install ys-k3s-master
# 维护窗口内执行，新版本在此时生效
sudo systemctl restart k3s
```

两个包通过 DEB `Conflicts` 互斥，不能同时安装。更换包名不会执行角色迁移。

## 卸载

卸载只停止、禁用并删除本包首次创建且未修改的 unit，清理本包创建且仍指向 `k3s` 的命令链接；保留用户修改过的 unit、所有集群配置和数据。

接管已有安装时，卸载不会停止或改写原服务。卸载会移除包拥有的 `/usr/local/bin/k3s`；自定义路径下更新过的二进制保留。移除包前应自行安排服务停止或恢复原安装的二进制。

## 验证

```bash
python3 -m unittest discover -s k3s/tests -v
shellcheck k3s/build.sh k3s/scripts/*.sh
```

GitHub Actions 另外验证真实 `dpkg` 安装、两个包互斥、重复安装及已有服务接管，再按仓库惯例发布到 Fury。

上游依据：[发行版本](https://github.com/k3s-io/k3s/releases)、[通道](https://update.k3s.io/v1-release/channels)、[官方安装脚本](https://github.com/k3s-io/k3s/blob/master/install.sh)、[手动升级说明](https://docs.k3s.io/upgrades/manual)。
