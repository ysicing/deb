#!/bin/sh
set -e

GO_ROOT=/usr/local/go
BIN_DIR="$GO_ROOT/bin"

# 如果 update-alternatives 存在，尝试自动移除这个版本对应的安装
if command -v update-alternatives >/dev/null 2>&1; then
  for exe in "$BIN_DIR"/*; do
    [ -f "$exe" ] || continue
    name=$(basename "$exe")
    # 取消注册指定路径（如果还有其他候选，系统会回退到其他候选）
    update-alternatives --remove $name "$exe" 2>/dev/null || true
  done
else
  # 如果没有 update-alternatives，清理软链（仅当指向本版本时）
  for exe in "$BIN_DIR"/*; do
    [ -f "$exe" ] || continue
    name=$(basename "$exe")
    if [ -L /usr/bin/$name ] && [ "$(readlink -f /usr/bin/$name)" = "$exe" ]; then
      rm -f /usr/bin/$name
    fi
  done
fi

exit 0
