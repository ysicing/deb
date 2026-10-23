#!/bin/bash
set -euo pipefail

VERSION="${1:-1.36.5+k3s1}"
VERSION="${VERSION#v}"
ARCH_LIST="${2:-amd64 arm64}"

cd "$(dirname "$0")"
mkdir -p build

for ARCH in $ARCH_LIST; do
  case "$ARCH" in
    amd64) ASSET=k3s ;;
    arm64) ASSET=k3s-arm64 ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
  esac

  WORKDIR="build/$ARCH"
  mkdir -p "$WORKDIR"
  (
    cd "$WORKDIR"
    URL="https://github.com/k3s-io/k3s/releases/download/v${VERSION/+/%2B}"
    curl -fSL --retry 3 -o k3s "$URL/$ASSET"
    curl -fSL --retry 3 -o sha256sums.txt "$URL/sha256sum-$ARCH.txt"
    EXPECTED="$(awk -v asset="$ASSET" '$2 == asset || $2 == "*" asset { print $1 }' sha256sums.txt)"
    if [ -z "$EXPECTED" ]; then
      echo "Missing checksum for $ASSET" >&2
      exit 1
    fi
    if command -v sha256sum >/dev/null 2>&1; then
      ACTUAL="$(sha256sum k3s | awk '{print $1}')"
    else
      ACTUAL="$(shasum -a 256 k3s | awk '{print $1}')"
    fi
    if [ "$EXPECTED" != "$ACTUAL" ]; then
      echo "Checksum mismatch for $ASSET" >&2
      exit 1
    fi
    chmod 0755 k3s

    for ROLE in master worker; do
      if [ "$ROLE" = master ]; then
        SERVICE=k3s
        COMMAND=server
        CONFLICT=worker
      else
        SERVICE=k3s-agent
        COMMAND=agent
        CONFLICT=master
      fi
      mkdir -p "$ROLE/scripts"
      for SCRIPT in postinstall preremove postremove; do
        sed -e "s/{{ .Role }}/$ROLE/g" \
            -e "s/{{ .Service }}/$SERVICE/g" \
            "../../scripts/$SCRIPT.sh" > "$ROLE/scripts/$SCRIPT.sh"
      done
      sed -e "s/{{ .Command }}/$COMMAND/g" ../../k3s.service.tmpl > "$ROLE/k3s.service"
      sed -e "s/{{ .Version }}/$VERSION/g" \
          -e "s/{{ .Arch }}/$ARCH/g" \
          -e "s/{{ .Role }}/$ROLE/g" \
          -e "s/{{ .Conflict }}/$CONFLICT/g" \
          ../../nfpm.yaml.tmpl > "$ROLE/nfpm.yaml"
      (
        cd "$ROLE"
        nfpm pkg --packager deb --config nfpm.yaml --target ../
      )
    done
  )
done
