# ys-gops DEB 包构建

用于构建 [gops](https://github.com/google/gops) Go 进程诊断工具的多架构 DEB 安装包。

## 依赖要求

- `go`：从源码交叉编译（gops 无预编译 release）
- `nfpm`：用于创建 DEB 包
- `curl`：下载源码

## 使用方法

```bash
# 默认构建 (v0.3.29, amd64+arm64)
./build.sh

# 指定版本
./build.sh 0.3.29

# 指定版本和架构
./build.sh 0.3.29 "amd64 arm64"
```

### 构建产物

```
build/amd64/ys-gops_0.3.29_amd64.deb
build/arm64/ys-gops_0.3.29_arm64.deb
```

## 安装 / 卸载

```bash
sudo dpkg -i ys-gops_0.3.29_amd64.deb
gops --version

sudo dpkg -r ys-gops
```
