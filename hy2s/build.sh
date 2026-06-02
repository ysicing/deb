#!/bin/bash
set -e

VERSION="${1:-2.9.2}"
ARCH_LIST="${2:-amd64 arm64}"

echo "▶ Building hy2s $VERSION for architectures: $ARCH_LIST"

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
  curl -fsSLo hy2s "$URL"
  chmod +x hy2s

  echo "▶ Generating nfpm.yaml ..."
  sed -e "s/{{ .Version }}/$VERSION/g" \
      -e "s/{{ .Arch }}/$ARCH/g" \
      ../../nfpm.yaml.tmpl > nfpm.yaml

  # nfpm reads contents relative to its config dir; copy the static assets in.
  cp ../../hy2s.service ./hy2s.service
  cp ../../config.yaml ./config.yaml
  cp ../../postinstall.sh ./postinstall.sh
  cp ../../preremove.sh ./preremove.sh

  echo "▶ Packaging .deb for $ARCH ..."
  nfpm pkg --packager deb --config nfpm.yaml

  echo "✔ Done: $(ls ./*.deb)"

  cd - >/dev/null
done

echo "🎉 All hy2s builds completed!"
