#!/bin/bash
set -euo pipefail

VERSION="${1:-0.23.0}"
ARCH_LIST="${2:-amd64 arm64}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Unsupported version: $VERSION (expected a stable version such as 0.23.0)" >&2
  exit 1
fi
if [[ -z "${ARCH_LIST//[[:space:]]/}" ]]; then
  echo "At least one architecture is required" >&2
  exit 1
fi
for ARCH in $ARCH_LIST; do
  case "$ARCH" in
    amd64|arm64) ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
  esac
done

cd "$(dirname "${BASH_SOURCE[0]}")"
BASE_URL="https://cnb.cool/gaeaflow/nezha/-/releases/download/v${VERSION}"

echo "▶ Building nezha-agent $VERSION for architectures: $ARCH_LIST"
if [[ -d build ]]; then rm -r build; fi
mkdir -p build
curl -fsSL --retry 3 "$BASE_URL/sha256sums.txt" -o build/sha256sums.txt

for ARCH in $ARCH_LIST; do
  (
    mkdir -p "build/$ARCH"
    cd "build/$ARCH"
    FILENAME="nezha-agent-linux-${ARCH}"
    echo "▶ Downloading $FILENAME ..."
    curl -fsSL --retry 3 "$BASE_URL/$FILENAME" -o "$FILENAME"
    # 上游校验文件还包含 Dashboard 和其他架构，仅校验本次下载的 Agent。
    awk -v name="$FILENAME" '$2 == name { print }' ../sha256sums.txt > sha256sums.txt
    test -s sha256sums.txt
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum -c sha256sums.txt
    else
      shasum -a 256 -c sha256sums.txt
    fi
    mv "$FILENAME" nezha-agent
    chmod +x nezha-agent

    sed -e "s/{{ .Version }}/$VERSION/g" \
        -e "s/{{ .Arch }}/$ARCH/g" \
        ../../nfpm.yaml.tmpl > nfpm.yaml
    cp ../../nezha-agent.service.example ../../agent.env.example ../../LICENSE .
    nfpm pkg --packager deb --config nfpm.yaml
  )
done

echo "🎉 All nezha-agent builds completed!"
