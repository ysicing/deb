#!/bin/bash
set -e

VERSION="${1:-0.3.29}"
ARCH_LIST="${2:-amd64 arm64}"

echo "▶ Building gops $VERSION for architectures: $ARCH_LIST"

rm -rf build
mkdir -p build

# Download source once
SRCDIR="build/src"
mkdir -p "$SRCDIR"
echo "▶ Downloading gops source v${VERSION} ..."
curl -fsSL "https://github.com/google/gops/archive/refs/tags/v${VERSION}.tar.gz" | tar -xz -C "$SRCDIR" --strip-components=1

for ARCH in $ARCH_LIST; do
  WORKDIR="build/${ARCH}"
  mkdir -p "$WORKDIR"

  echo "▶ Cross-compiling gops for linux/$ARCH ..."
  cd "$SRCDIR"
  GOOS=linux GOARCH=$ARCH CGO_ENABLED=0 \
    go build -trimpath -ldflags="-s -w" \
    -o "../../${WORKDIR}/gops" .
  cd - >/dev/null

  cd "$WORKDIR"

  echo "▶ Generating nfpm.yaml ..."
  sed -e "s/{{ .Version }}/$VERSION/g" \
      -e "s/{{ .Arch }}/$ARCH/g" \
      ../../nfpm.yaml.tmpl > nfpm.yaml

  echo "▶ Packaging .deb for $ARCH ..."
  nfpm pkg --packager deb --config nfpm.yaml

  echo "✔ Done: $(ls ./*.deb)"

  cd - >/dev/null
done

echo "🎉 All gops builds completed!"
