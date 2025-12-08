#!/bin/bash
set -e

# 支持的架构映射
declare -A ARCH_MAP=(
  ["amd64"]="amd64"
  ["arm64"]="arm64"
  ["386"]="386"
  ["armv6"]="armv6l"
  ["armv7"]="armv6l"
  ["loong64"]="loong64"
  ["ppc64le"]="ppc64le"
  ["s390x"]="s390x"
)

GO_VERSION="${1:-1.25.5}"
ARCH_LIST="${2:-amd64 arm64}"

echo "▶ Building Go $GO_VERSION for architectures: $ARCH_LIST"

rm -rf build
mkdir -p build

for ARCH in $ARCH_LIST; do
  GO_ARCH=${ARCH_MAP[$ARCH]}

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
  cat ../../../nfpm.yaml.tmpl \
    | sed "s/{{ .Version }}/$GO_VERSION/g" \
    | sed "s/{{ .Arch }}/$ARCH/g" \
    > nfpm.yaml

  mkdir -p scripts
  cp ../../../scripts/* scripts/

  echo "▶ Packaging .deb for $ARCH ..."
  nfpm pkg --packager deb --config nfpm.yaml

  echo "✔ Done: $(ls *.deb)"

  cd - >/dev/null
done

echo "🎉 All builds completed!"
