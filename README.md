# DEB Package Repository

用于构建常用软件多架构 DEB 安装包的自动化工具集。

## 支持的包

| 包名 | 当前版本 | 支持架构 | 详细说明 |
|------|---------|---------|---------|
| [ys-golang](./go/) | 1.26.3 | amd64, arm64 | Go 编程语言官方二进制包 |
| [ys-task](./task/) | 3.48.0 | amd64, arm64 | Task 任务运行器 (Make 替代) |
| [ys-gops](./gops/) | 0.3.29 | amd64, arm64 | Go 进程诊断工具 |
| [nali](./nali/) | 0.8.1 | amd64, arm64 | IP 地理信息查询工具 |
| [nxtrace-nali](./nxtrace-nali/) | 1.7.5 | amd64, arm64 | NextTrace 集成 Nali 路由追踪工具 |
| [ys-helm](./helm/) | 3.20.2 | amd64, arm64 | Helm - Kubernetes 包管理器 |

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
```

### 构建 DEB 包

每个软件包目录下都有独立的构建说明，例如：

```bash
cd go
./build.sh
```

详细构建说明请参考各软件包目录下的 README.md 文件。

## 项目结构

```
.
├── go/                    # ys-golang 包构建目录
│   ├── README.md         # 详细构建说明
│   └── build.sh          # 构建脚本
├── task/                  # ys-task 包构建目录
│   └── build.sh          # 构建脚本
├── gops/                  # ys-gops 包构建目录
│   └── build.sh          # 构建脚本
├── nali/                  # nali 包构建目录
│   └── build.sh          # 构建脚本
├── nxtrace-nali/          # nxtrace-nali 包构建目录
│   └── build.sh          # 构建脚本
├── helm/                  # ys-helm 包构建目录
│   └── build.sh          # 构建脚本
└── README.md             # 本文件
```

## License

AGPLv3
