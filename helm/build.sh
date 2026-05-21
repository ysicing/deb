#!/bin/bash
set -e

VERSION="${1:-3.20.2}"
ARCH_LIST="${2:-amd64 arm64}"

echo "▶ Building helm $VERSION for architectures: $ARCH_LIST"

rm -rf build
mkdir -p build

for ARCH in $ARCH_LIST; do
  WORKDIR="build/${ARCH}"
  mkdir -p "$WORKDIR"
  cd "$WORKDIR"

  TARBALL="helm-v${VERSION}-linux-${ARCH}.tar.gz"
  URL="https://get.helm.sh/${TARBALL}"

  echo "▶ Downloading $TARBALL ..."
  curl -fsSLO "$URL"

  echo "▶ Extracting..."
  tar -xf "$TARBALL" "linux-${ARCH}/helm"
  mv "linux-${ARCH}/helm" helm
  rm -rf "linux-${ARCH}"

  echo "▶ Generating nfpm.yaml ..."
  sed -e "s/{{ .Version }}/$VERSION/g" \
      -e "s/{{ .Arch }}/$ARCH/g" \
      ../../nfpm.yaml.tmpl > nfpm.yaml

  echo "▶ Packaging .deb for $ARCH ..."
  nfpm pkg --packager deb --config nfpm.yaml

  echo "✔ Done: $(ls ./*.deb)"

  cd - >/dev/null
done

echo "🎉 All helm builds completed!"
