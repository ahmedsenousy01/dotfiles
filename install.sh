#!/usr/bin/env bash

set -e

echo "🚀 Starting dotfiles installation..."

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

brew_install_with_fallback() {
    local kind="$1" # "formula" | "cask"
    shift
    local -a items=("$@")

    local brew_args=()
    case "$kind" in
        formula) brew_args=() ;;
        cask) brew_args=(--cask) ;;
        *)
            echo "❌ Internal error: unknown brew kind '$kind'"
            return 1
            ;;
    esac

    # Fast path: attempt a single batch install (much faster than per-item).
    if brew install "${brew_args[@]}" "${items[@]}" 2>&1; then
        return 0
    fi

    # Slow path: fall back to per-item installs so we can report what failed.
    local -a failed=()
    for item in "${items[@]}"; do
        echo "Installing $item..."
        if brew install "${brew_args[@]}" "$item" 2>&1; then
            echo "✅ $item installed successfully"
        else
            echo "❌ FAILED to install $item - see error above"
            failed+=("$item")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        echo ""
        if [[ "$kind" == "cask" ]]; then
            echo "❌ CRITICAL: Failed to install these GUI applications:"
            for item in "${failed[@]}"; do
                echo "   - $item"
            done
            echo ""
            echo "🔧 Manual installation commands:"
            for item in "${failed[@]}"; do
                echo "   brew install --cask $item"
            done
        else
            echo "❌ CRITICAL: Failed to install these packages:"
            for item in "${failed[@]}"; do
                echo "   - $item"
            done
            echo ""
            echo "🔧 Manual installation commands:"
            for item in "${failed[@]}"; do
                echo "   brew install $item"
            done
        fi
        echo ""
        echo "⚠️  Some tools may not work properly without these installs!"
        return 1
    fi

    return 0
}

if ! command_exists brew; then
    echo "❌ Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "✅ Homebrew found"
fi

BREW_PREFIX="$(brew --prefix)"

echo "📦 Installing all dependencies..."

PACKAGES=(
    "tmux"
    "fzf"
    "carapace"
    "zoxide"
    "stow"
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
    "starship"
    "eza"
    "bat"
    "tree"
    "fd"
    "ripgrep"
    "neovim"
    "mise"
    "atuin"
    "direnv"
    "kubectl"
    "kubectx"
)

brew_install_with_fallback formula "${PACKAGES[@]}" || true

echo ""
echo "📦 Installing GUI applications..."
CASK_PACKAGES=("ghostty" "raycast" "rectangle" "karabiner-elements")

brew_install_with_fallback cask "${CASK_PACKAGES[@]}" || true

echo "✅ Dependency installation step complete"

echo "🔗 Deploying configurations..."
cd "$(dirname "$0")"

STOW_PACKAGES=("atuin" "ghostty" "karabiner" "nvim" "ssh" "starship" "tmux" "vscode" "zsh")

FAILED_STOW=()
for package in "${STOW_PACKAGES[@]}"; do
    echo "Deploying $package..."
    if stow "$package" 2>&1; then
        echo "✅ $package deployed successfully"
    else
        FAILED_STOW+=("$package")
        echo "❌ FAILED to deploy $package - resolve conflicts and re-run:"
        echo "   stow $package"
    fi
done

if [[ ${#FAILED_STOW[@]} -gt 0 ]]; then
    echo ""
    echo "❌ CRITICAL: Failed to deploy these packages:"
    for package in "${FAILED_STOW[@]}"; do
        echo "   - $package"
    done
    echo ""
    echo "🔧 Manual deployment commands:"
    for package in "${FAILED_STOW[@]}"; do
        echo "   stow $package"
    done
    echo ""
    echo "⚠️  Some configurations may not work properly without these deployments!"
else
    echo "✅ All configurations deployed successfully"
fi

# SSH: build config for this machine (personal/work) – run after stow so ~/.ssh exists
if [[ -n "$SSH_ROLE" && ( "$SSH_ROLE" == "personal" || "$SSH_ROLE" == "work" ) ]]; then
    echo ""
    echo "🔐 Configuring SSH for: $SSH_ROLE"
    if [[ -x "./scripts/setup-ssh.sh" ]]; then
        ./scripts/setup-ssh.sh "$SSH_ROLE" && echo "✅ SSH configured"
    else
        chmod +x ./scripts/setup-ssh.sh && ./scripts/setup-ssh.sh "$SSH_ROLE" && echo "✅ SSH configured"
    fi
elif [[ -t 0 ]]; then
    echo ""
    read -r -p "Configure SSH for this machine? (personal/work/skip) [skip]: " ssh_choice
    ssh_choice="${ssh_choice:-skip}"
    if [[ "$ssh_choice" == "personal" || "$ssh_choice" == "work" ]]; then
        if [[ -x "./scripts/setup-ssh.sh" ]]; then
            ./scripts/setup-ssh.sh "$ssh_choice" && echo "✅ SSH configured"
        else
            chmod +x ./scripts/setup-ssh.sh && ./scripts/setup-ssh.sh "$ssh_choice" && echo "✅ SSH configured"
        fi
    fi
fi

echo "🔌 Installing tmux plugins automatically..."
if command_exists tmux; then
    if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
        echo "   Installing TPM (Tmux Plugin Manager)..."
        git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
    fi

    echo "   Installing tmux plugins using TPM..."
    if ~/.config/tmux/plugins/tpm/scripts/install_plugins.sh; then
        echo "✅ Tmux plugins installed"
    else
        echo "❌ FAILED to install tmux plugins"
    fi
else
    echo "⚠️  Tmux not found - skipping plugin installation"
fi

echo "🐚 Setting up shell integrations..."

if command_exists fzf; then
    echo "Installing FZF shell integration..."
    if "$BREW_PREFIX/opt/fzf/install" --all --no-bash --no-fish 2>&1; then
        echo "✅ FZF shell integration installed successfully"
    else
        echo "❌ FAILED to install FZF shell integration - see error above"
    fi
else
    echo "⚠️  FZF not found - skipping shell integration"
fi

if command_exists atuin; then
    echo "Initializing Atuin..."
    if atuin import auto 2>&1; then
        echo "✅ Atuin initialized successfully"
    else
        echo "❌ FAILED to initialize Atuin - see error above"
    fi
else
    echo "⚠️  Atuin not found - skipping initialization"
fi

echo "✅ Shell integrations configured"
echo "ℹ️  GUI configs need manual import (Rectangle/Raycast)"

echo ""
echo "🎉 Installation complete!"
echo ""

echo "🔍 Running validation script..."
if [[ -f "./validate.sh" ]]; then
    chmod +x ./validate.sh
    ./validate.sh || echo "⚠️  Validation found some issues. See output above."
else
    echo "⚠️  Validation script not found. Run './validate.sh' manually to check your setup."
fi

echo ""
echo "📋 Next steps:"
echo "   1. If you skipped SSH: ./scripts/setup-ssh.sh personal  (or  work)"
echo "   2. Restart your terminal or run: source ~/.zshrc"
echo "   3. Start tmux: tmux"
echo "   4. Restart VS Code/Cursor and Karabiner-Elements"
echo "   5. Import GUI application configurations:"
echo "      - Rectangle: Open Rectangle → Preferences → Import from rectangle/config.json"
echo "      - Raycast: Open Raycast → Preferences → Import from raycast/config.rayconfig"
