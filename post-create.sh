#!/usr/bin/env bash
set -euo pipefail

# C compiler required to build the extended edition from source (cgo).
sudo apt-get update
sudo apt-get install -y gcc

# Pin for reproducibility; keep in sync with HUGO_VERSION in
# .github/workflows/hugo.yml so local == CI.
HUGO_VERSION="v0.158.0"

# Resolve the real install dir instead of assuming ~/go/bin.
GOBIN="$(go env GOBIN)"; [ -z "$GOBIN" ] && GOBIN="$(go env GOPATH)/bin"
export PATH="$GOBIN:$PATH"

CGO_ENABLED=1 go install -tags extended "github.com/gohugoio/hugo@${HUGO_VERSION}"

# Persist PATH for terminals opened later in the container.
grep -qs 'go env GOPATH' "$HOME/.bashrc" || \
  echo 'export PATH="$(go env GOPATH)/bin:$PATH"' >> "$HOME/.bashrc"

hugo version

# typos: spell checker for source and prose. Pinned for reproducibility.
TYPOS_VERSION="v1.48.0"

case "$(uname -m)" in
  x86_64)          TYPOS_ARCH="x86_64" ;;
  aarch64 | arm64) TYPOS_ARCH="aarch64" ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

TYPOS_TARBALL="typos-${TYPOS_VERSION}-${TYPOS_ARCH}-unknown-linux-musl.tar.gz"
curl -fsSL \
  "https://github.com/crate-ci/typos/releases/download/${TYPOS_VERSION}/${TYPOS_TARBALL}" \
  | sudo tar -xz -C /usr/local/bin ./typos

typos --version