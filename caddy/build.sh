#!/bin/bash
set -e

VERSION="${1:-2.11.3}"
ARCH_LIST="${2:-amd64 arm64}"

# Caddy plugins compiled into the binary via xcaddy.
PLUGINS=(
  github.com/caddyserver/jsonc-adapter
  github.com/caddy-dns/cloudflare
  github.com/caddy-dns/tencentcloud
  github.com/caddy-dns/alidns
  github.com/mholt/caddy-dynamicdns
  github.com/mholt/caddy-events-exec
  github.com/mholt/caddy-l4
  github.com/mholt/caddy-webdav
  github.com/mholt/caddy-ratelimit
  github.com/WeidiDeng/caddy-cloudflare-ip
  github.com/xcaddyplugins/caddy-trusted-cloudfront
  github.com/ysicing/caddy2-geocn
)

WITH_ARGS=()
for p in "${PLUGINS[@]}"; do
  WITH_ARGS+=(--with "$p")
done

# Install xcaddy on demand and make sure it is on PATH.
if ! command -v xcaddy >/dev/null 2>&1; then
  echo "▶ Installing xcaddy ..."
  go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
fi
GOBIN_PATH="$(go env GOPATH)/bin"
export PATH="${GOBIN_PATH}:$PATH"

echo "▶ Building caddy $VERSION (with plugins) for architectures: $ARCH_LIST"

rm -rf build
mkdir -p build

for ARCH in $ARCH_LIST; do
  WORKDIR="build/${ARCH}"
  mkdir -p "$WORKDIR"

  echo "▶ Compiling caddy with xcaddy for $ARCH ..."
  GOOS=linux GOARCH="$ARCH" CGO_ENABLED=0 \
    xcaddy build "v${VERSION}" \
      "${WITH_ARGS[@]}" \
      --output "$WORKDIR/caddy"
  chmod +x "$WORKDIR/caddy"

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

echo "🎉 All caddy builds completed!"
