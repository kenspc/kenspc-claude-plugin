#!/usr/bin/env bash
# Check that recommended dependencies are available.
# Runs as a SessionStart hook — stdout goes to the transcript.

set -euo pipefail

warnings=""

if [ -n "$warnings" ]; then
  printf "%b" "$warnings"
fi
