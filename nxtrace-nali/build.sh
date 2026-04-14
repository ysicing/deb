#!/bin/bash
set -e

VERSION="${1:-1.7.5}"
ARCH_LIST="${2:-amd64 arm64}"

echo "▶ Building nxtrace-nali $VERSION for architectures: $ARCH_LIST"

rm -rf build
mkdir -p build

for ARCH in $ARCH_LIST; do
  WORKDIR="build/${ARCH}"
  mkdir -p "$WORKDIR"
  cd "$WORKDIR"

  FILENAME="nali-nt_linux_${ARCH}"
  URL="https://github.com/nxtrace/nali/releases/download/v${VERSION}/${FILENAME}"

  echo "▶ Downloading $FILENAME ..."
  curl -fsSLO "$URL"
  mv "$FILENAME" nxtrace-nali
  chmod +x nxtrace-nali

  echo "▶ Generating nfpm.yaml ..."
  sed -e "s/{{ .Version }}/$VERSION/g" \
      -e "s/{{ .Arch }}/$ARCH/g" \
      ../../nfpm.yaml.tmpl > nfpm.yaml

  echo "▶ Packaging .deb for $ARCH ..."
  nfpm pkg --packager deb --config nfpm.yaml

  echo "✔ Done: $(ls ./*.deb)"

  cd - >/dev/null
done

echo "🎉 All nxtrace-nali builds completed!"
