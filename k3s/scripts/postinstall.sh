#!/bin/sh
set -eu

[ "${1:-}" = configure ] || exit 0

BINARY=/usr/local/bin/k3s
SERVICE="{{ .Service }}"
TEMPLATE="/usr/share/ys-k3s-{{ .Role }}/k3s.service"
MARKER="/var/lib/ys-k3s/{{ .Role }}.service"

# 同时检查磁盘和 systemd，停用或未启动的已有服务也不能被重新初始化。
UNITS="$(
  for directory in /etc/systemd/system /run/systemd/system /usr/local/lib/systemd/system /usr/lib/systemd/system /lib/systemd/system; do
    for unit in "$directory"/k3s.service "$directory"/k3s-*.service; do
      if [ -f "$unit" ] || [ -L "$unit" ]; then
        basename "$unit"
      fi
    done
  done
  if command -v systemctl >/dev/null 2>&1; then
    systemctl list-unit-files 'k3s*.service' --no-legend --no-pager 2>/dev/null |
      awk '$1 ~ /^k3s([-.].*)?\.service$/ {print $1}' || true
    systemctl list-units --all 'k3s*.service' --plain --no-legend --no-pager 2>/dev/null |
      awk '$1 ~ /^k3s([-.].*)?\.service$/ {print $1}' || true
  fi
)"

if [ -n "$UNITS" ]; then
  for unit in $(printf '%s\n' "$UNITS" | sort -u); do
    executable=""
    if command -v systemctl >/dev/null 2>&1; then
      executable="$(systemctl show "$unit" --property=ExecStart --value 2>/dev/null |
        sed -n 's/.*path=\([^ ;]*\).*;.*/\1/p' | head -n 1)" || true
    fi
    if [ -z "$executable" ]; then
      for directory in /etc/systemd/system /run/systemd/system /usr/local/lib/systemd/system /usr/lib/systemd/system /lib/systemd/system; do
        # 无法读取合并后的 ExecStart 时，不猜测 drop-in 对二进制路径的覆盖。
        if [ -d "$directory/$unit.d" ]; then
          echo "Cannot resolve ExecStart for $unit with drop-ins; configure with systemd running." >&2
          exit 1
        fi
      done
      for directory in /etc/systemd/system /run/systemd/system /usr/local/lib/systemd/system /usr/lib/systemd/system /lib/systemd/system; do
        file="$directory/$unit"
        [ -e "$file" ] || [ -L "$file" ] || continue
        # mask 不是可初始化的空白状态；保留它，也不操作其 /dev/null 目标。
        if [ -L "$file" ] && [ "$(readlink "$file")" = /dev/null ]; then
          executable="$BINARY"
          break
        fi
        executable="$(awk '
          /^\[Service\]/ { service=1; next }
          /^\[/ { service=0 }
          service && /^[[:space:]]*ExecStart=/ {
            sub(/^[[:space:]]*ExecStart=[-+!:@]*/, "")
            sub(/[[:space:]]*\\$/, "")
            sub(/[[:space:]].*$/, "")
            gsub(/^"|"$/, "")
            path=$0
          }
          END {print path}
        ' "$file")"
        break
      done
    fi
    case "$executable" in
      /*/k3s) ;;
      *)
        echo "Cannot safely resolve the k3s binary for $unit: $executable" >&2
        exit 1
        ;;
    esac
    if [ "$executable" != "$BINARY" ]; then
      # 在同一目录原子替换，避免截断正在运行的二进制，并保留已有符号链接。
      if [ -L "$executable" ]; then
        executable="$(readlink -f "$executable")"
      fi
      temporary="$(mktemp "$(dirname "$executable")/.k3s.XXXXXX")"
      trap 'rm -f "$temporary"' EXIT HUP INT TERM
      install -m 0755 "$BINARY" "$temporary"
      mv -f "$temporary" "$executable"
      trap - EXIT HUP INT TERM
    fi
  done
  echo "Existing k3s service detected; binaries updated. Service files, configuration and running services were left untouched."
  echo "Restart the existing service manually when ready to use the new binary."
  exit 0
fi

install -d -m 0755 /etc/systemd/system /var/lib/ys-k3s
install -m 0644 "$TEMPLATE" "/etc/systemd/system/$SERVICE.service"
install -m 0644 "$TEMPLATE" "$MARKER"
for command in kubectl crictl ctr; do
  if [ ! -e "/usr/local/bin/$command" ] && [ ! -L "/usr/local/bin/$command" ]; then
    ln -s k3s "/usr/local/bin/$command"
    touch "/var/lib/ys-k3s/{{ .Role }}.$command"
  fi
done
if command -v systemctl >/dev/null 2>&1; then
  systemctl daemon-reload
fi
echo "Installed $SERVICE.service without starting or enabling it."
echo "Configure /etc/rancher/k3s/config.yaml, then run: systemctl enable --now $SERVICE"
