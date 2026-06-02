#!/bin/bash
set -e

# Stop and disable the service before removal.
if command -v systemctl >/dev/null 2>&1; then
  systemctl stop hy2s >/dev/null 2>&1 || true
  systemctl disable hy2s >/dev/null 2>&1 || true
fi
