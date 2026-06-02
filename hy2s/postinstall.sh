#!/bin/bash
set -e

# Install the default config only on first install; never overwrite an existing one.
if [ ! -f /etc/hy2s/config.yaml ]; then
  cp /etc/hy2s/config.yaml.example /etc/hy2s/config.yaml
  echo "Created /etc/hy2s/config.yaml from the example."
else
  echo "/etc/hy2s/config.yaml already exists, leaving it untouched."
fi

# Reload systemd so the new unit is picked up.
if command -v systemctl >/dev/null 2>&1; then
  systemctl daemon-reload || true
fi

echo "ys-hy2s installed."
echo "Edit /etc/hy2s/config.yaml (set TLS/ACME and change the auth password),"
echo "then start the service:"
echo "  sudo systemctl enable --now hy2s"
