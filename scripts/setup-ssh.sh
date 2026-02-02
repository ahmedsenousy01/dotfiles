#!/usr/bin/env bash
# Builds SSH config in the repo. Symlinks are done by stow (~/.ssh → repo/ssh/.ssh).
# Usage: ./scripts/setup-ssh.sh personal | ./scripts/setup-ssh.sh work
# Run from dotfiles root. Run after 'stow ssh' (or install.sh).

set -e

ROLE="${1:-}"
if [[ "$ROLE" != "personal" && "$ROLE" != "work" ]]; then
    echo "Usage: $0 personal | work"
    echo "  personal  – use personal GitHub key (github.com → personal_gh.pub)"
    echo "  work      – use work GitHub key (github.com → bub_gh.pub)"
    exit 1
fi

# Resolve dotfiles root (script lives in dotfiles/scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_SSH="$DOTFILES_ROOT/ssh/.ssh"
REPO_CONFIG="$REPO_SSH/config"
REPO_KEYS="$REPO_SSH/keys"

if [[ "$ROLE" == "personal" ]]; then
    KEY_NAME="personal_gh.pub"
else
    KEY_NAME="bub_gh.pub"
fi

if [[ ! -f "$REPO_KEYS/$KEY_NAME" ]]; then
    echo "Error: key not found: $REPO_KEYS/$KEY_NAME"
    exit 1
fi

mkdir -p "$REPO_SSH"

# Build config in repo (gitignored); ~/.ssh is symlinked here by stow
cat > "$REPO_CONFIG" << 'CONFIG_HEAD'
# Added by OrbStack: 'orb' SSH host for Linux machines
# This only works if it's at the top of ssh_config (before any Host blocks).
Include ~/.orbstack/ssh/config

# 1Password SSH Agent for all hosts
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

CONFIG_HEAD

cat >> "$REPO_CONFIG" << CONFIG_GITHUB

# GitHub – single key for this machine (1Password provides private key)
Host github.com
    HostName github.com
    User git
    IdentitiesOnly yes
    IdentityFile ~/.ssh/keys/$KEY_NAME
CONFIG_GITHUB

echo "SSH configured for: $ROLE"
echo "  github.com → $KEY_NAME"
echo "  config: $REPO_CONFIG (used via ~/.ssh when stowed)"
