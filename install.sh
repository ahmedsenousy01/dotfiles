#!/usr/bin/env bash

# Dotfiles Installation Script
# This script installs all dependencies and deploys configurations in one shot

set -e

echo "🚀 Starting dotfiles installation..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "✅ Homebrew found"
fi

# Install all dependencies
echo "📦 Installing all dependencies..."

# Define packages to install
PACKAGES=(
    "tmux"
    "ghostty"
    "fzf"
    "zoxide"
    "stow"
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
    "starship"
    "eza"
    "bat"
    "tree"
    "ranger"
    "fd"
    "ripgrep"
    "neovim"
    "mise"
    "atuin"
    "direnv"
    "kubectl"
    "kubectx"
)

# Install packages with error handling
FAILED_PACKAGES=()
for package in "${PACKAGES[@]}"; do
    echo "Installing $package..."
    if brew install "$package" 2>&1; then
        echo "✅ $package installed successfully"
    else
        echo "❌ FAILED to install $package - see error above"
        FAILED_PACKAGES+=("$package")
        echo "   Retrying $package installation..."
        if brew install "$package" 2>&1; then
            echo "✅ $package installed successfully on retry"
            # Remove from failed list
            FAILED_PACKAGES=("${FAILED_PACKAGES[@]/$package}")
        else
            echo "❌ $package FAILED AGAIN - manual installation required"
        fi
    fi
done

# Report failed installations
if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
    echo ""
    echo "❌ CRITICAL: Failed to install these packages:"
    for package in "${FAILED_PACKAGES[@]}"; do
        echo "   - $package"
    done
    echo ""
    echo "🔧 Manual installation commands:"
    for package in "${FAILED_PACKAGES[@]}"; do
        echo "   brew install $package"
    done
    echo ""
    echo "⚠️  Some tools may not work properly without these packages!"
fi

echo ""
echo "📦 Installing GUI applications (casks)..."
echo "   This will install Raycast, Rectangle, and Karabiner-Elements"

# Define cask packages to install
CASK_PACKAGES=("raycast" "rectangle" "karabiner-elements")

# Install cask packages with error handling
FAILED_CASKS=()
for cask in "${CASK_PACKAGES[@]}"; do
    echo "Installing $cask..."
    if brew install --cask "$cask" 2>&1; then
        echo "✅ $cask installed successfully"
    else
        echo "❌ FAILED to install $cask - see error above"
        FAILED_CASKS+=("$cask")
        echo "   Retrying $cask installation..."
        if brew install --cask "$cask" 2>&1; then
            echo "✅ $cask installed successfully on retry"
            # Remove from failed list
            FAILED_CASKS=("${FAILED_CASKS[@]/$cask}")
        else
            echo "❌ $cask FAILED AGAIN - manual installation required"
        fi
    fi
done

# Report failed cask installations
if [[ ${#FAILED_CASKS[@]} -gt 0 ]]; then
    echo ""
    echo "❌ CRITICAL: Failed to install these GUI applications:"
    for cask in "${FAILED_CASKS[@]}"; do
        echo "   - $cask"
    done
    echo ""
    echo "🔧 Manual installation commands:"
    for cask in "${FAILED_CASKS[@]}"; do
        echo "   brew install --cask $cask"
    done
    echo ""
    echo "⚠️  Some GUI tools may not work properly without these applications!"
fi

echo "✅ All dependencies installed"

# Note about kubens
echo "ℹ️  Note: kubens is not available via Homebrew"
echo "   You can install it manually: https://github.com/ahmetb/kubectx"

# Install Oh My Zsh if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "📦 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "✅ Oh My Zsh installed"
else
    echo "✅ Oh My Zsh already installed"
fi


# Deploy configurations using stow
echo "🔗 Deploying configurations..."
cd "$(dirname "$0")"

# Deploy all packages (using ~ as default target from .stowrc)
echo "🔗 Symlinking configurations..."

# Define packages to deploy
STOW_PACKAGES=("atuin" "ghostty" "karabiner" "nvim" "ssh" "starship" "tmux" "vscode" "zsh")

# Deploy packages with error handling
FAILED_STOW=()
for package in "${STOW_PACKAGES[@]}"; do
    echo "Deploying $package..."
    if stow "$package" 2>&1; then
        echo "✅ $package deployed successfully"
    else
        echo "❌ FAILED to deploy $package - see error above"
        FAILED_STOW+=("$package")
        echo "   Retrying $package deployment..."
        if stow "$package" 2>&1; then
            echo "✅ $package deployed successfully on retry"
            # Remove from failed list
            FAILED_STOW=("${FAILED_STOW[@]/$package}")
        else
            echo "❌ $package FAILED AGAIN - manual deployment required"
        fi
    fi
done

# Report failed deployments
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

# Install tmux plugins automatically
echo "🔌 Installing tmux plugins automatically..."
if command -v tmux &> /dev/null; then
    # First, ensure TPM is installed
    if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
        echo "   Installing TPM (Tmux Plugin Manager)..."
        git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
    fi

    echo "   Installing tmux plugins using TPM..."
    # Run TPM install script directly (this is more reliable than keybindings)
    if ~/.config/tmux/plugins/tpm/scripts/install_plugins.sh; then
        # Count installed plugins
        if [[ -d "$HOME/.config/tmux/plugins" ]]; then
            PLUGIN_COUNT=$(ls -1 "$HOME/.config/tmux/plugins" 2>/dev/null | wc -l)
            echo "✅ Tmux plugins installed successfully ($((PLUGIN_COUNT-1)) plugins)"
        else
            echo "✅ Tmux plugins installation completed"
        fi

        # Clean up installation sessions and resurrect cache
        echo "   Cleaning up installation sessions..."
        tmux kill-session -t 0 2>/dev/null || true
        tmux kill-session -t plugin_install 2>/dev/null || true

        # Clear resurrect cache to remove installation sessions
        echo "   Clearing tmux-resurrect cache..."
        rm -rf ~/.tmux/resurrect/* 2>/dev/null || true
        echo "✅ Installation sessions and cache cleaned up"
    else
        echo "❌ FAILED to install tmux plugins"
    fi
else
    echo "⚠️  Tmux not found - skipping plugin installation"
fi

# Set up shell integration
echo "🐚 Setting up shell integrations..."

# Add fzf shell integration
if command -v fzf &> /dev/null; then
    echo "Installing FZF shell integration..."
    if $(brew --prefix)/opt/fzf/install --all --no-bash --no-fish 2>&1; then
        echo "✅ FZF shell integration installed successfully"
    else
        echo "❌ FAILED to install FZF shell integration - see error above"
    fi
else
    echo "⚠️  FZF not found - skipping shell integration"
fi

# Initialize atuin
if command -v atuin &> /dev/null; then
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

# Note about GUI application configurations
echo "ℹ️  Note: GUI application configurations need manual import"
echo "   - Rectangle: Import config from rectangle/config.json via Rectangle preferences"
echo "   - Raycast: Import config from raycast/config.rayconfig via Raycast preferences"

# Final instructions
echo ""
echo "🎉 Installation complete!"
echo ""

# Run validation script
echo "🔍 Running validation script..."
if [[ -f "./validate.sh" ]]; then
    chmod +x ./validate.sh
    ./validate.sh
    VALIDATION_EXIT_CODE=$?
    if [[ $VALIDATION_EXIT_CODE -eq 0 ]]; then
        echo "✅ Validation passed!"
    else
        echo "⚠️  Validation found some issues. Check the output above."
    fi
else
    echo "⚠️  Validation script not found. Run './validate.sh' manually to check your setup."
fi

echo ""
echo "📋 Next steps:"
echo "   1. Restart your terminal or run: source ~/.zshrc"
echo "   2. Start tmux: tmux"
echo "   3. Tmux plugins are automatically installed"
echo "   4. Restart VS Code/Cursor to see the new configuration"
echo "   5. Restart Karabiner-Elements to apply keyboard remappings"
echo "   6. Import GUI application configurations:"
echo "      - Rectangle: Open Rectangle → Preferences → Import from rectangle/config.json"
echo "      - Raycast: Open Raycast → Preferences → Import from raycast/config.rayconfig"
echo "   7. Install kubens manually: https://github.com/ahmetb/kubectx"
echo ""
echo "🔧 Available tools:"
echo "   - tmux: Terminal multiplexer with plugins"
echo "   - ghostty: Terminal emulator with Catppuccin theme"
echo "   - starship: Beautiful shell prompt"
echo "   - eza: Modern ls replacement"
echo "   - bat: Better cat"
echo "   - ranger: File manager"
echo "   - fzf: Fuzzy finder"
echo "   - zoxide: Smart cd"
echo "   - mise: Tool version manager"
echo "   - atuin: Shell history search"
echo "   - kubectl: Kubernetes CLI"
echo "   - karabiner-elements: Keyboard remapping"
echo "   - raycast: Productivity launcher (import config manually)"
echo "   - rectangle: Window management (import config manually)"
echo "   - vscode/cursor: IDE configuration (works for both)"
echo ""
echo "🚀 Your development environment is ready!"