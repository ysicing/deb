# Nezha Agent DEB 打包

将 [gaeaflow/nezha](https://cnb.cool/gaeaflow/nezha/-/releases) 的 Agent 二进制打包为 `ys-nezha-agent`，支持 Linux amd64、arm64，默认采用最新正式版 0.23.0。该项目为哪吒 v0 分支，连接参数应与对应 Dashboard 兼容。

CNB 的 `latest` 当前指向可变的 `dev` 预发布，本包固定下载正式版本标签 `v0.23.0`，并使用该 Release 的 `sha256sums.txt` 校验二进制。构建无需 Go 工具链或 CNB 登录。

## 构建与安装

需要 Bash、curl、nFPM，以及 sha256sum 或 shasum。

```bash
cd nezha-agent
./build.sh                       # 默认版本、双架构
./build.sh 0.23.0 amd64           # 指定正式版本、单架构
./build.sh 0.23.0 "amd64 arm64"   # 指定正式版本、双架构
sudo apt install ./build/amd64/ys-nezha-agent_*.deb
nezha-agent --version
nezha-agent --help
```

产物位于 `build/<arch>/`，重新构建会清理本目录的 `build/`。二进制安装到 `/usr/local/bin/nezha-agent`，依赖 `ca-certificates`，与上游名为 `nezha-agent` 的 DEB 包互斥。

## 启用 systemd 服务

包只安装服务和环境变量示例，不自动创建、启动或重启服务。已有手工安装的 Agent 时，先核对其服务、二进制路径和配置，避免同时运行两个实例；本包不会迁移已有安装。

首次启用时执行以下命令；已有同名配置或 unit 时先检查并保留原内容，不要直接覆盖：

```bash
sudo install -m 0600 /usr/share/ys-nezha-agent/agent.env.example /etc/default/ys-nezha-agent
sudoedit /etc/default/ys-nezha-agent
# 必填 NEZHA_AGENT_SERVER（Dashboard RPC 地址）和 NEZHA_AGENT_SECRET（节点 Secret）
# Dashboard RPC 启用 TLS 时，设置 NEZHA_AGENT_FLAGS="--tls"
sudo install -m 0644 /usr/share/ys-nezha-agent/nezha-agent.service.example /etc/systemd/system/ys-nezha-agent.service
sudo systemctl daemon-reload
sudo systemctl enable --now ys-nezha-agent
```

升级仅更新包内文件，正在运行的服务不会自动重启；需要生效时手动执行 `sudo systemctl restart ys-nezha-agent`。命令行参数、TLS 和监控选项见上游文档。

卸载前停止自行启用的服务，手工创建的配置与 unit 会保留：

```bash
sudo systemctl disable --now ys-nezha-agent
sudo apt remove ys-nezha-agent
```

GitHub Actions 构建双架构包，并在 amd64 上验证安装、版本输出和卸载。推送到 main/master 时，配置了 `FURY_PUSH_TOKEN` 才会上传到 Fury。
