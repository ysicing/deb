#!/bin/bash
set -e

VERSION="${1:-3.50.0}"
ARCH_LIST="${2:-amd64 arm64}"

echo "▶ Building task $VERSION for architectures: $ARCH_LIST"

rm -rf build
mkdir -p build

for ARCH in $ARCH_LIST; do
  WORKDIR="build/${ARCH}"
  mkdir -p "$WORKDIR"
  cd "$WORKDIR"

  TARBALL="task_linux_${ARCH}.tar.gz"
  URL="https://github.com/go-task/task/releases/download/v${VERSION}/${TARBALL}"

  echo "▶ Downloading $TARBALL ..."
  curl -fsSLO "$URL"

  echo "▶ Extracting..."
  tar -xf "$TARBALL" task

  echo "▶ Generating nfpm.yaml ..."
  sed -e "s/{{ .Version }}/$VERSION/g" \
      -e "s/{{ .Arch }}/$ARCH/g" \
      ../../nfpm.yaml.tmpl > nfpm.yaml

  echo "▶ Packaging .deb for $ARCH ..."
  nfpm pkg --packager deb --config nfpm.yaml

  echo "✔ Done: $(ls ./*.deb)"

  cd - >/dev/null
done

echo "🎉 All task builds completed!"
