#!/usr/bin/env bash
set -euo pipefail

# Spell check every file under content/.
# Pass --write-changes to apply the corrections in place.
cd "$(dirname "$0")"
exec typos content "$@"
