# ys-golang DEB 包构建

用于构建 Go 语言多架构 DEB 安装包。

## 功能特性

- 支持多架构构建：amd64、arm64、386、armv6、armv7、loong64、ppc64le、s390x
- 自动下载官方 Go 二进制文件
- 使用 nfpm 打包为 DEB 格式
- 自动配置 update-alternatives，支持多版本 Go 共存
- 包含完整的安装/卸载钩子脚本

## 依赖要求

- `nfpm`：用于创建 DEB 包
- `curl`：下载 Go 二进制文件
- `tar`：解压缩

安装 nfpm：
```bash
# macOS
brew install nfpm

# Linux
curl -sfL https://install.goreleaser.com/github.com/goreleaser/nfpm.sh | sh
```

## 使用方法

### 基础构建

```bash
./build.sh
```

默认构建 Go 1.26.4 版本，支持 amd64 和 arm64 架构。

### 指定版本

```bash
./build.sh 1.23.4
```

### 指定架构

```bash
./build.sh 1.26.4 "amd64 arm64 loong64"
```

### 构建产物

DEB 包输出在 `build/{架构}/` 目录下：
```
build/amd64/ys-golang_1.26.4_amd64.deb
build/arm64/ys-golang_1.26.4_arm64.deb
```

## 手动安装

```bash
# 安装 DEB 包
sudo dpkg -i ys-golang_1.26.4_amd64.deb

# 验证安装
go version
```

安装后 Go 会被放置在 `/usr/local/go`，并通过 update-alternatives 管理。

## 卸载

```bash
sudo dpkg -r ys-golang
```

## 项目结构

```
.
├── build.sh           # 构建脚本
├── nfpm.yaml.tmpl     # nfpm 配置模板
├── scripts/           # 安装钩子脚本
│   ├── postinstall.sh
│   ├── preremove.sh
│   └── postremove.sh
└── build/             # 构建输出目录（自动生成）
```
