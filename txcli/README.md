# txcli DEB 打包

将 [txcli](https://cnb.cool/ysicing/txcli) 官方 Release 二进制打包为 `ys-txcli`，支持 Linux amd64、arm64，默认版本为 1.0.0。构建前会使用上游 `SHA256SUMS` 校验压缩包，无需 Go 工具链或 CNB 登录。

## 构建

需要 Bash、curl、tar、nFPM，以及 sha256sum 或 shasum。

```bash
cd txcli
./build.sh                      # 默认版本、双架构
./build.sh 1.0.0 amd64           # 指定版本、单架构
./build.sh 1.0.0 "amd64 arm64"   # 指定版本、双架构
```

版本参数不带 `v` 前缀，也支持 `1.0.0-rc.1` 等上游预发布版本。产物位于 `build/<arch>/ys-txcli_*.deb`，重新构建会清理本目录的 `build/`。

## 安装与验证

```bash
sudo apt install ./build/amd64/ys-txcli_*.deb
txcli --help
txcli policygen --read-only
sudo apt remove ys-txcli
```

安装路径为 `/usr/local/bin/txcli`，依赖 `ca-certificates`；与上游名为 `txcli` 的 DEB 包互斥，避免两个命令同时安装。帮助和权限策略生成不需要云凭证；云端操作的认证与用法见上游文档。

GitHub Actions 会构建双架构包，在 amd64 上验证安装、离线命令与卸载。推送到 main/master 时，配置了 `FURY_PUSH_TOKEN` 才会上传到 Fury。
