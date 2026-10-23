#!/bin/sh
set -eu

case "${1:-}" in remove|purge) ;; *) exit 0 ;; esac
MARKER="/var/lib/ys-k3s/{{ .Role }}.service"
UNIT="/etc/systemd/system/{{ .Service }}.service"
if [ -f "$MARKER" ]; then
  if cmp -s "$MARKER" "$UNIT"; then
    rm -f "$UNIT"
    if command -v systemctl >/dev/null 2>&1; then
      systemctl daemon-reload
    fi
  fi
  rm -f "$MARKER"
fi
for command in kubectl crictl ctr; do
  marker="/var/lib/ys-k3s/{{ .Role }}.$command"
  if [ -f "$marker" ]; then
    if [ -L "/usr/local/bin/$command" ] && [ "$(readlink "/usr/local/bin/$command")" = k3s ]; then
      rm -f "/usr/local/bin/$command"
    fi
    rm -f "$marker"
  fi
done
