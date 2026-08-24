# DEB Package Repository

用于构建常用软件多架构 DEB 安装包的自动化工具集。

## 支持的包

| 包名 | 当前版本 | 支持架构 | 详细说明 |
|------|---------|---------|---------|
| [ys-golang](./go/) | 1.27.0 | amd64, arm64 | Go 编程语言官方二进制包 |
| [ys-task](./task/) | 3.53.1 | amd64, arm64 | Task 任务运行器 (Make 替代) |
| [ys-gops](./gops/) | 0.3.29 | amd64, arm64 | Go 进程诊断工具 |
| [nali](./nali/) | 0.8.1 | amd64, arm64 | IP 地理信息查询工具 |
| [nxtrace-nali](./nxtrace-nali/) | 1.7.5 | amd64, arm64 | NextTrace 集成 Nali 路由追踪工具 |
| [ys-helm](./helm/) | 3.20.2 | amd64, arm64 | Helm - Kubernetes 包管理器 |
| [ys-mc](./mc/) | 2025.08.13 | amd64, arm64 | MinIO Client 对象存储命令行工具 |
| [ys-caddy](./caddy/) | 2.11.4 | amd64, arm64 | Caddy - 自动 HTTPS 的 Web 服务器 |
| [ys-hy2](./hy2/) | 2.12.2 | amd64, arm64 | hy2 代理客户端 |
| [ys-hy2s](./hy2s/) | 2.12.2 | amd64, arm64 | hy2s 代理服务端 (含 systemd) |

## 快速开始

### 使用 APT 镜像源安装

```bash
# 添加仓库配置
echo "deb [trusted=yes] https://mirrors.china.12306.work/repository/ysicing/apt/ /" | sudo tee /etc/apt/sources.list.d/ysicing.list

# 更新包列表
sudo apt update

# 安装软件包
sudo apt install ys-golang
sudo apt install ys-task
sudo apt install ys-gops
sudo apt install nali
sudo apt install nxtrace-nali
sudo apt install ys-helm
sudo apt install ys-mc
sudo apt install ys-caddy
sudo apt install ys-hy2
sudo apt install ys-hy2s
```

### 构建 DEB 包

每个软件包目录下都有独立的构建说明，例如：

```bash
cd go
./build.sh
```

详细构建说明请参考各软件包目录下的 README.md 文件。

## License

AGPLv3
