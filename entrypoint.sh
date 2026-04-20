#!/usr/bin/env bash
set -euo pipefail

export HOME=/home/coder
export USER=coder
export PATH="$HOME/.local/state/nix/profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

# Restore the baked Nix user state if a mounted home hides it.
if [ ! -e "$HOME/.local/state/nix/profile/etc/profile.d/nix.sh" ]; then
  mkdir -p "$HOME/.config" "$HOME/.local/state"

  if [ -d /opt/coder-home-seed/.config/nix ]; then
    rsync -a --ignore-existing /opt/coder-home-seed/.config/nix/ "$HOME/.config/nix/"
  fi

  if [ -d /opt/coder-home-seed/.local/state/nix ]; then
    rsync -a --ignore-existing /opt/coder-home-seed/.local/state/nix/ "$HOME/.local/state/nix/"
  fi
fi

if [ ! -e "$HOME/.local/state/nix/profile" ] && [ -e "$HOME/.local/state/nix/profiles/profile" ]; then
  mkdir -p "$HOME/.local/state/nix"
  ln -sfn "$HOME/.local/state/nix/profiles/profile" "$HOME/.local/state/nix/profile"
fi

exec "$@"
