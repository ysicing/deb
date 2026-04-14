#!/bin/bash
set -e

VERSION="${1:-0.8.1}"
ARCH_LIST="${2:-amd64 arm64}"

echo "▶ Building nali $VERSION for architectures: $ARCH_LIST"

rm -rf build
mkdir -p build

for ARCH in $ARCH_LIST; do
  WORKDIR="build/${ARCH}"
  mkdir -p "$WORKDIR"
  cd "$WORKDIR"

  # zu1k/nali arm64 用 armv8 命名
  if [ "$ARCH" = "arm64" ]; then
    RELEASE_ARCH="armv8"
  else
    RELEASE_ARCH="$ARCH"
  fi

  FILENAME="nali-linux-${RELEASE_ARCH}-v${VERSION}.gz"
  URL="https://github.com/zu1k/nali/releases/download/v${VERSION}/${FILENAME}"

  echo "▶ Downloading $FILENAME ..."
  curl -fsSLO "$URL"

  echo "▶ Extracting..."
  gzip -d "$FILENAME"
  mv "nali-linux-${RELEASE_ARCH}-v${VERSION}" nali
  chmod +x nali

  echo "▶ Generating nfpm.yaml ..."
  sed -e "s/{{ .Version }}/$VERSION/g" \
      -e "s/{{ .Arch }}/$ARCH/g" \
      ../../nfpm.yaml.tmpl > nfpm.yaml

  echo "▶ Packaging .deb for $ARCH ..."
  nfpm pkg --packager deb --config nfpm.yaml

  echo "✔ Done: $(ls ./*.deb)"

  cd - >/dev/null
done

echo "🎉 All nali builds completed!"
