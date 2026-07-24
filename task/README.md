# ys-task DEB 包构建

用于构建 [Task](https://taskfile.dev) 任务运行器的多架构 DEB 安装包。

## 依赖要求

- `nfpm`：用于创建 DEB 包
- `curl`：下载二进制文件

## 使用方法

```bash
# 默认构建 (v3.52.0, amd64+arm64)
./build.sh

# 指定版本
./build.sh 3.52.0

# 指定版本和架构
./build.sh 3.52.0 "amd64 arm64"
```

### 构建产物

```
build/amd64/ys-task_3.52.0_amd64.deb
build/arm64/ys-task_3.52.0_arm64.deb
```

## 安装 / 卸载

```bash
sudo dpkg -i ys-task_3.52.0_amd64.deb
task --version

sudo dpkg -r ys-task
```
