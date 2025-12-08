#!/bin/sh
set -e

GO_ROOT=/usr/local/go
BIN_DIR="$GO_ROOT/bin"
PRIORITY=60

# 如果 /usr/local/bin 不存在则创建
[ -d /usr/local/bin ] || mkdir -p /usr/local/bin

# 遍历 bin 目录中的可执行文件，注册到 update-alternatives
for exe in "$BIN_DIR"/*; do
  [ -f "$exe" ] || continue
  name=$(basename "$exe")
  # 避免为非命令文件建立 alternatives（但一般 bin 下都是可执行）
  update-alternatives --install /usr/bin/$name $name $exe $PRIORITY 2>/dev/null || true
done

# 兼容老系统：如果系统没有 update-alternatives，就用软链接（覆盖）
if ! command -v update-alternatives >/dev/null 2>&1; then
  for exe in "$BIN_DIR"/*; do
    [ -f "$exe" ] || continue
    name=$(basename "$exe")
    ln -sf "$exe" /usr/bin/$name
  done
fi

# optional: notify
echo "golang-binary installed to $GO_ROOT. Use 'update-alternatives --config go' to switch versions if multiple present."
exit 0
