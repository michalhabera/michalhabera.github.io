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