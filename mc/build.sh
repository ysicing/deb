#!/bin/bash
set -e

# MinIO mc uses RELEASE.<timestamp> versioning. Pass the full RELEASE tag.
RELEASE="${1:-RELEASE.2025-08-13T08-35-41Z}"
ARCH_LIST="${2:-amd64 arm64}"

# Derive a deb-compatible version: RELEASE.2025-08-13T08-35-41Z -> 2025.08.13.08.35.41
VERSION="$(echo "$RELEASE" | sed -E 's/^RELEASE\.//; s/Z$//; s/[-T:]/./g')"

echo "▶ Building mc $RELEASE (deb version $VERSION) for architectures: $ARCH_LIST"

rm -rf build
mkdir -p build

for ARCH in $ARCH_LIST; do
  WORKDIR="build/${ARCH}"
  mkdir -p "$WORKDIR"
  cd "$WORKDIR"

  FILENAME="mc.${RELEASE}"
  URL="https://dl.min.io/client/mc/release/linux-${ARCH}/archive/${FILENAME}"

  echo "▶ Downloading $FILENAME ..."
  curl -fsSLo mc "$URL"
  chmod +x mc

  echo "▶ Generating nfpm.yaml ..."
  sed -e "s/{{ .Version }}/$VERSION/g" \
      -e "s/{{ .Arch }}/$ARCH/g" \
      ../../nfpm.yaml.tmpl > nfpm.yaml

  echo "▶ Packaging .deb for $ARCH ..."
  nfpm pkg --packager deb --config nfpm.yaml

  echo "✔ Done: $(ls ./*.deb)"

  cd - >/dev/null
done

echo "🎉 All mc builds completed!"
