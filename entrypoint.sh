#!/usr/bin/env bash
set -euo pipefail

export HOME=/home/coder
export USER=coder
export PATH="$HOME/.local/state/nix/profile/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

# If the mounted home came up empty, seed it once from the baked image copy.
if [ -z "$(ls -A "$HOME" 2>/dev/null)" ]; then
  rsync -a /opt/coder-home-seed/ "$HOME"/
fi

exec "$@"
