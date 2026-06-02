#!/bin/bash
set -e

VERSION="${1:-2.9.2}"
ARCH_LIST="${2:-amd64 arm64}"

echo "▶ Building hy2 $VERSION for architectures: $ARCH_LIST"

rm -rf build
mkdir -p build

for ARCH in $ARCH_LIST; do
  WORKDIR="build/${ARCH}"
  mkdir -p "$WORKDIR"
  cd "$WORKDIR"

  FILENAME="hysteria-linux-${ARCH}"
  # release tag is app/v<version>, the slash must be URL-encoded
  URL="https://github.com/apernet/hysteria/releases/download/app%2Fv${VERSION}/${FILENAME}"

  echo "▶ Downloading $FILENAME ..."
  curl -fsSLo hy2 "$URL"
  chmod +x hy2

  echo "▶ Generating nfpm.yaml ..."
  sed -e "s/{{ .Version }}/$VERSION/g" \
      -e "s/{{ .Arch }}/$ARCH/g" \
      ../../nfpm.yaml.tmpl > nfpm.yaml

  echo "▶ Packaging .deb for $ARCH ..."
  nfpm pkg --packager deb --config nfpm.yaml

  echo "✔ Done: $(ls ./*.deb)"

  cd - >/dev/null
done

echo "🎉 All hy2 builds completed!"
