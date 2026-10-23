#!/bin/sh
set -eu

# 升级和接管已有安装时，不停止服务；只处理本包首次创建且未被修改的 unit。
[ "${1:-}" = remove ] || exit 0
MARKER="/var/lib/ys-k3s/{{ .Role }}.service"
UNIT="/etc/systemd/system/{{ .Service }}.service"
if [ -f "$MARKER" ] && cmp -s "$MARKER" "$UNIT"; then
  if command -v systemctl >/dev/null 2>&1; then
    systemctl stop "{{ .Service }}"
    systemctl disable "{{ .Service }}"
  fi
fi
