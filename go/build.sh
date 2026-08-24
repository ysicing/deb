#!/bin/bash
set -e

# 架构映射函数 - 兼容 Bash 3.2+ (macOS/Linux)
map_arch() {
  case "$1" in
    amd64)   echo "amd64" ;;
    arm64)   echo "arm64" ;;
    386)     echo "386" ;;
    armv6)   echo "armv6l" ;;
    armv7)   echo "armv6l" ;;
    loong64) echo "loong64" ;;
    ppc64le) echo "ppc64le" ;;
    s390x)   echo "s390x" ;;
    *)       echo "" ;;
  esac
}

GO_VERSION="${1:-1.27.0}"
ARCH_LIST="${2:-amd64 arm64}"

echo "▶ Building Go $GO_VERSION for architectures: $ARCH_LIST"

rm -rf build
mkdir -p build

for ARCH in $ARCH_LIST; do
  GO_ARCH=$(map_arch "$ARCH")

  if [ -z "$GO_ARCH" ]; then
    echo "❌ Unknown architecture: $ARCH"
    exit 1
  fi

  WORKDIR="build/${ARCH}"
  mkdir -p "$WORKDIR"

  cd "$WORKDIR"

  TARBALL="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
  URL="https://go.dev/dl/${TARBALL}"

  echo "▶ Downloading $TARBALL for $ARCH ..."
  curl -fsSLO "$URL"

  echo "▶ Extracting..."
  tar -xf "$TARBALL"

  echo "▶ Generating nfpm.yaml ..."
  cat ../../nfpm.yaml.tmpl \
    | sed "s/{{ .Version }}/$GO_VERSION/g" \
    | sed "s/{{ .Arch }}/$ARCH/g" \
    > nfpm.yaml

  mkdir -p scripts
  cp ../../scripts/* scripts/

  echo "▶ Packaging .deb for $ARCH ..."
  nfpm pkg --packager deb --config nfpm.yaml

  echo "✔ Done: $(ls *.deb)"

  cd - >/dev/null
done

echo "🎉 All builds completed!"
