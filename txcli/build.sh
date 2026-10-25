#!/bin/bash
set -euo pipefail

VERSION="${1:-1.0.0}"
ARCH_LIST="${2:-amd64 arm64}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$ ]]; then
  echo "Unsupported version: $VERSION (expected 1.0.0 or 1.0.0-rc.1)" >&2
  exit 1
fi
if [[ -z "${ARCH_LIST//[[:space:]]/}" ]]; then
  echo "At least one architecture is required" >&2
  exit 1
fi
for ARCH in $ARCH_LIST; do
  case "$ARCH" in
    amd64|arm64) ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
  esac
done

cd "$(dirname "${BASH_SOURCE[0]}")"
BASE_URL="https://cnb.cool/ysicing/txcli/-/releases/download/v${VERSION}"

echo "▶ Building txcli $VERSION for architectures: $ARCH_LIST"
rm -rf build
mkdir -p build
curl -fsSL --retry 3 "$BASE_URL/SHA256SUMS" -o build/SHA256SUMS

for ARCH in $ARCH_LIST; do
  (
    mkdir -p "build/$ARCH"
    cd "build/$ARCH"
    TARBALL="txcli_v${VERSION}_linux_${ARCH}.tar.gz"

    echo "▶ Downloading $TARBALL ..."
    curl -fsSL --retry 3 "$BASE_URL/$TARBALL" -o "$TARBALL"
    # 只校验当前架构，避免缺少其他平台的附件导致校验失败。
    awk -v name="./$TARBALL" '$2 == name { print }' ../SHA256SUMS > SHA256SUMS
    test -s SHA256SUMS
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum -c SHA256SUMS
    else
      shasum -a 256 -c SHA256SUMS
    fi
    tar -xzf "$TARBALL" txcli

    sed -e "s/{{ .Version }}/$VERSION/g" \
        -e "s/{{ .Arch }}/$ARCH/g" \
        ../../nfpm.yaml.tmpl > nfpm.yaml
    nfpm pkg --packager deb --config nfpm.yaml
  )
done

echo "🎉 All txcli builds completed!"
