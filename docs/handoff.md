# 打包维护注意事项

## Nezha Agent

- gaeaflow/nezha 的 CNB `latest` 当前指向 `dev` 预发布；正式版须从 Release 列表筛选，不能直接拿 latest 作为稳定版本。Agent 原始附件为 `nezha-agent-linux-<arch>`，校验文件名是 `sha256sums.txt`。
- 服务示例放在 `/usr/share/ys-nezha-agent`，由用户配置后手动启用，不在打包或安装时连接 Dashboard。已有手工部署须先核对服务与二进制路径，包不自动接管。

## txcli

- CNB 的 Release 查询 API 可能要求认证；401 不能判断为没有新版本。可通过 `cnb releases get-latest-release --repo ysicing/txcli` 查询，构建使用无需登录的 `https://cnb.cool/ysicing/txcli/-/releases/download/<tag>/<filename>` 下载附件，并校验 `SHA256SUMS`。
- v1.0.0 没有 `--version` 命令；安装冒烟检查使用 `--help` 和离线的 `policygen --read-only`，无需配置云凭证。

## K3s

- 官方 stable 和 GitHub latest 可能属于不同 Kubernetes 小版本。默认构建版本应核对官方通道，不自动选最新 release，也不代替现有集群的升级顺序判断。
- 两个角色共用二进制路径，必须保持 `Conflicts` 双向互斥；不能添加会隐式移除另一角色的 `Replaces`。
- 已有服务判断不能只检查 `is-active`。停用、停止、masked、重命名和自定义二进制路径的服务都应保留原状。
- unit 模板必须放在 `/usr/share`，由首次安装脚本按需创建真实 unit。直接将 unit 打进 `/etc/systemd/system` 会在接管已有安装时改变服务。
- 升级不停止或重启服务；prerm/postrm 必须排除 upgrade。已有服务路径只替换二进制，不运行官方安装/卸载脚本，避免改写参数或删除集群数据。
- 自定义二进制通过同目录临时文件和 rename 更新，不直接截断正在运行的可执行文件；无法确认 ExecStart 时应报错，不能重新初始化服务。
- 生命周期测试用临时目录和模拟 systemctl；真实 DEB 冲突与维护脚本执行另由 Linux CI 验证。macOS 本地脚本测试不等于实际节点升级验证。

## 2026-10-23 版本核对

- Go 默认版本从 1.27.2 更新为 1.27.3；Helm 在现有 3.x 内从 3.22.0 更新为 3.22.1，Helm 最新大版本为 4.3.1。
- gops 0.3.29、Task 3.54.0、nali 0.8.1、nxtrace-nali 1.7.5、Caddy 2.11.7、Hysteria 2.13.0、mc RELEASE.2025-08-13T08-35-41Z 与此次查询的最新 release 一致。
- GitHub 未认证 API 查询触发限流时，可读取官方 `/releases/latest` 重定向与 release 页面；不能把查询失败当成没有更新。
