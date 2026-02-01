#!/usr/bin/env bash

# Dotfiles Validation Script
# This script validates the entire dotfiles setup and reports missing dependencies

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Function to print status
print_status() {
    local status=$1
    local message=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    case $status in
        "PASS")
            echo -e "${GREEN}✅ PASS${NC}: $message"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            ;;
        "FAIL")
            echo -e "${RED}❌ FAIL${NC}: $message"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  WARN${NC}: $message"
            WARNINGS=$((WARNINGS + 1))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  INFO${NC}: $message"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            ;;
    esac
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if file exists and is readable
file_exists() {
    [[ -f "$1" && -r "$1" ]]
}

# Function to check if directory exists
dir_exists() {
    [[ -d "$1" ]]
}

echo -e "${BLUE}🔍 Starting dotfiles validation...${NC}\n"

# =============================================================================
# SYSTEM REQUIREMENTS
# =============================================================================
echo -e "${BLUE}📋 System Requirements${NC}"
echo "----------------------------------------"

# Check macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "PASS" "Running on macOS"
else
    print_status "FAIL" "Not running on macOS (this dotfiles setup is macOS-specific)"
fi

# Check Homebrew
BREW_PREFIX=""
if command_exists brew; then
    print_status "PASS" "Homebrew is installed"
    BREW_PREFIX=$(brew --prefix)
    print_status "INFO" "Homebrew prefix: $BREW_PREFIX"
else
    print_status "FAIL" "Homebrew is not installed"
fi

# Check GNU Stow
if command_exists stow; then
    print_status "PASS" "GNU Stow is installed"
else
    print_status "FAIL" "GNU Stow is not installed"
fi

echo ""

# =============================================================================
# CORE TOOLS VALIDATION
# =============================================================================
echo -e "${BLUE}🛠️  Core Tools${NC}"
echo "----------------------------------------"

# Define required tools
REQUIRED_TOOLS=(
    "tmux"
    "ghostty"
    "fzf"
    "carapace"
    "zoxide"
    "starship"
    "eza"
    "bat"
    "tree"
    "fd"
    "rg"
    "nvim"
    "mise"
    "atuin"
    "direnv"
    "kubectl"
    "kubectx"
)

# Check each required tool
for tool in "${REQUIRED_TOOLS[@]}"; do
    if [[ "$tool" == "ghostty" ]]; then
        # Check for Ghostty app
        if [[ -d "/Applications/Ghostty.app" ]]; then
            print_status "PASS" "$tool is installed"
        else
            print_status "FAIL" "$tool is not installed"
        fi
    else
        if command_exists "$tool"; then
            print_status "PASS" "$tool is installed"
        else
            print_status "FAIL" "$tool is not installed"
        fi
    fi
done

# Check GUI applications (casks)
GUI_APPS=("Karabiner-Elements" "Raycast" "Rectangle")

for app in "${GUI_APPS[@]}"; do
    if [[ -d "/Applications/$app.app" ]]; then
        print_status "PASS" "$app is installed"
    else
        print_status "WARN" "$app is not installed (requires manual installation)"
    fi
done

echo ""

# =============================================================================
# SHELL CONFIGURATION
# =============================================================================
echo -e "${BLUE}🐚 Shell Configuration${NC}"
echo "----------------------------------------"

# Check zsh plugins
ZSH_PLUGINS=(
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
)

for plugin in "${ZSH_PLUGINS[@]}"; do
    if [[ -n "$BREW_PREFIX" ]]; then
        if file_exists "$BREW_PREFIX/share/$plugin/$plugin.zsh"; then
            print_status "PASS" "Zsh plugin $plugin is available"
        else
            print_status "FAIL" "Zsh plugin $plugin is not available"
        fi
    else
        print_status "FAIL" "Homebrew missing; cannot verify zsh plugin $plugin"
    fi
done

# Check .zshrc
if file_exists "$HOME/.zshrc"; then
    print_status "PASS" ".zshrc exists"

    # Check for key configurations in .zshrc
    if grep -q "starship init zsh" "$HOME/.zshrc"; then
        print_status "PASS" "Starship integration in .zshrc"
    else
        print_status "WARN" "Starship integration not found in .zshrc"
    fi

    if grep -q "mise activate zsh" "$HOME/.zshrc"; then
        print_status "PASS" "Mise integration in .zshrc"
    else
        print_status "WARN" "Mise integration not found in .zshrc"
    fi

    if grep -q "carapace _carapace zsh" "$HOME/.zshrc"; then
        print_status "PASS" "Carapace integration in .zshrc"
    else
        print_status "WARN" "Carapace integration not found in .zshrc"
    fi
else
    print_status "FAIL" ".zshrc does not exist"
fi

echo ""

# =============================================================================
# CONFIGURATION FILES
# =============================================================================
echo -e "${BLUE}📁 Configuration Files${NC}"
echo "----------------------------------------"

# Check main configuration files
CONFIG_FILES=(
    "$HOME/.config/tmux/tmux.conf"
    "$HOME/.config/starship/starship.toml"
    "$HOME/.config/ghostty/config"
    "$HOME/.config/karabiner/karabiner.json"
    "$HOME/.config/atuin/config.toml"
    "$HOME/.config/nvim/init.lua"
)

for config_file in "${CONFIG_FILES[@]}"; do
    if file_exists "$config_file"; then
        print_status "PASS" "Configuration file exists: $(basename "$config_file")"
    else
        print_status "FAIL" "Configuration file missing: $(basename "$config_file")"
    fi
done

# Check VS Code/Cursor configurations
VSCODE_CONFIGS=(
    "$HOME/Library/Application Support/Code/User/settings.json"
    "$HOME/Library/Application Support/Code/User/keybindings.json"
    "$HOME/Library/Application Support/Cursor/User/settings.json"
    "$HOME/Library/Application Support/Cursor/User/keybindings.json"
)

for config in "${VSCODE_CONFIGS[@]}"; do
    if file_exists "$config"; then
        print_status "PASS" "VS Code/Cursor config exists: $(basename "$config")"
    else
        print_status "FAIL" "VS Code/Cursor config missing: $(basename "$config")"
    fi
done

# Check if VS Code/Cursor configs are identical (redundancy check)
if file_exists "$HOME/Library/Application Support/Code/User/settings.json" && \
   file_exists "$HOME/Library/Application Support/Cursor/User/settings.json"; then
    if diff "$HOME/Library/Application Support/Code/User/settings.json" \
            "$HOME/Library/Application Support/Cursor/User/settings.json" >/dev/null 2>&1; then
        print_status "PASS" "VS Code/Cursor configurations are identical (redundancy maintained)"
    else
        print_status "WARN" "VS Code/Cursor configurations differ"
    fi
else
    print_status "WARN" "VS Code/Cursor configurations not found"
fi

echo ""

# =============================================================================
# SSH CONFIGURATION
# =============================================================================
echo -e "${BLUE}🔐 SSH Configuration${NC}"
echo "----------------------------------------"

if file_exists "$HOME/.ssh/config"; then
    print_status "PASS" "SSH config exists"

    # Check for 1Password SSH agent
    if grep -q "1password" "$HOME/.ssh/config"; then
        print_status "PASS" "1Password SSH agent configured"
    else
        print_status "WARN" "1Password SSH agent not configured"
    fi

    # Check for GitHub host configurations
    if grep -q "github.com" "$HOME/.ssh/config"; then
        print_status "PASS" "GitHub SSH configuration found"
    else
        print_status "WARN" "GitHub SSH configuration not found"
    fi
else
    print_status "FAIL" "SSH config does not exist"
fi

# Check SSH keys directory
if dir_exists "$HOME/.ssh/keys"; then
    print_status "PASS" "SSH keys directory exists"

    # Check for public keys
    if ls "$HOME/.ssh/keys"/*.pub >/dev/null 2>&1; then
        print_status "PASS" "SSH public keys found"
    else
        print_status "WARN" "No SSH public keys found in keys directory"
    fi
else
    print_status "WARN" "SSH keys directory does not exist"
fi

echo ""

# =============================================================================
# TMUX PLUGINS
# =============================================================================
echo -e "${BLUE}🔌 Tmux Plugins${NC}"
echo "----------------------------------------"

if dir_exists "$HOME/.config/tmux/plugins"; then
    print_status "PASS" "Tmux plugins directory exists"

    # Check for TPM
    if dir_exists "$HOME/.config/tmux/plugins/tpm"; then
        print_status "PASS" "TPM (Tmux Plugin Manager) is installed"

        # Check for some key plugins
        PLUGINS=("tmux-sensible" "tmux-yank" "tmux-resurrect" "catppuccin-tmux")
        PLUGIN_COUNT=0
        for plugin in "${PLUGINS[@]}"; do
            if dir_exists "$HOME/.config/tmux/plugins/$plugin"; then
                PLUGIN_COUNT=$((PLUGIN_COUNT + 1))
            fi
        done

        if [[ $PLUGIN_COUNT -gt 0 ]]; then
            print_status "PASS" "Tmux plugins installed ($PLUGIN_COUNT/${#PLUGINS[@]} key plugins)"
        else
            print_status "FAIL" "TPM installed but no plugins found"
        fi
    else
        print_status "WARN" "TPM (Tmux Plugin Manager) is not installed"
    fi
else
    print_status "WARN" "Tmux plugins directory does not exist"
fi

echo ""

# =============================================================================
# NEOVIM CONFIGURATION
# =============================================================================
echo -e "${BLUE}📝 Neovim Configuration${NC}"
echo "----------------------------------------"

if dir_exists "$HOME/.config/nvim"; then
    print_status "PASS" "Neovim config directory exists"

    # Check for LazyVim
    if file_exists "$HOME/.config/nvim/lazy-lock.json"; then
        print_status "PASS" "LazyVim lock file exists"
    else
        print_status "WARN" "LazyVim lock file not found"
    fi

    # Check for lazy.nvim
    if dir_exists "$HOME/.config/nvim/lua/config"; then
        print_status "PASS" "LazyVim config structure exists"
    else
        print_status "WARN" "LazyVim config structure not found"
    fi
else
    print_status "FAIL" "Neovim config directory does not exist"
fi

echo ""

# =============================================================================
# GUI APPLICATION CONFIGURATIONS
# =============================================================================
echo -e "${BLUE}🖥️  GUI Application Configurations${NC}"
echo "----------------------------------------"

# Check for Raycast configuration
if file_exists "$SCRIPT_DIR/raycast/config.rayconfig"; then
    print_status "PASS" "Raycast configuration file exists"
    print_status "INFO" "Import manually: Raycast → Preferences → Import from raycast/config.rayconfig"
else
    print_status "WARN" "Raycast configuration file not found"
fi

# Check for Rectangle configuration
if file_exists "$SCRIPT_DIR/rectangle/config.json"; then
    print_status "PASS" "Rectangle configuration file exists"
    print_status "INFO" "Import manually: Rectangle → Preferences → Import from rectangle/config.json"
else
    print_status "WARN" "Rectangle configuration file not found"
fi

echo ""

# =============================================================================
# STOW PACKAGES
# =============================================================================
echo -e "${BLUE}📦 Stow Packages${NC}"
echo "----------------------------------------"

# Check if we're in the dotfiles directory
if file_exists "$SCRIPT_DIR/.stowrc"; then
    print_status "PASS" "Stow configuration file exists"

    # Check for all expected packages
    EXPECTED_PACKAGES=("atuin" "ghostty" "karabiner" "nvim" "raycast" "rectangle" "ssh" "starship" "tmux" "vscode" "zsh")

    for package in "${EXPECTED_PACKAGES[@]}"; do
        if dir_exists "$SCRIPT_DIR/$package"; then
            print_status "PASS" "Stow package '$package' exists"
        else
            print_status "FAIL" "Stow package '$package' is missing"
        fi
    done
else
    print_status "FAIL" "Not in dotfiles directory or .stowrc missing"
fi

echo ""

# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================
echo -e "${BLUE}🌍 Environment Variables${NC}"
echo "----------------------------------------"

# Check important environment variables
if [[ -n "$EDITOR" ]]; then
    print_status "PASS" "EDITOR is set to: $EDITOR"
else
    if file_exists "$HOME/.zshrc" && grep -q "export EDITOR=" "$HOME/.zshrc"; then
        print_status "PASS" "EDITOR is configured in .zshrc"
    else
        print_status "WARN" "EDITOR environment variable is not set"
    fi
fi

if [[ -n "$TERM" ]]; then
    print_status "PASS" "TERM is set to: $TERM"
else
    print_status "WARN" "TERM environment variable is not set"
fi

if [[ -n "$STARSHIP_CONFIG" ]]; then
    print_status "PASS" "STARSHIP_CONFIG is set to: $STARSHIP_CONFIG"
else
    if file_exists "$HOME/.zshrc" && grep -q "export STARSHIP_CONFIG=" "$HOME/.zshrc"; then
        print_status "PASS" "STARSHIP_CONFIG is configured in .zshrc"
    else
        print_status "WARN" "STARSHIP_CONFIG environment variable is not set"
    fi
fi

echo ""

# =============================================================================
# SUMMARY
# =============================================================================
echo -e "${BLUE}📊 Validation Summary${NC}"
echo "========================================"
echo -e "Total checks: ${BLUE}$TOTAL_CHECKS${NC}"
echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

# Calculate success rate
if [[ $TOTAL_CHECKS -gt 0 ]]; then
    SUCCESS_RATE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    echo -e "Success rate: ${BLUE}${SUCCESS_RATE}%${NC}"
fi

echo ""

# Provide recommendations
if [[ $FAILED_CHECKS -gt 0 ]]; then
    echo -e "${RED}❌ Issues found that need attention:${NC}"
    echo "   Run './install.sh' to install missing dependencies"
    echo "   Or install missing tools manually with Homebrew"
    echo ""
fi

if [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Warnings that should be reviewed:${NC}"
    echo "   Check the warnings above for optional configurations"
    echo ""
fi

if [[ $FAILED_CHECKS -eq 0 && $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}🎉 All validations passed! Your dotfiles setup is complete.${NC}"
elif [[ $FAILED_CHECKS -eq 0 ]]; then
    echo -e "${GREEN}✅ Core setup is complete with some optional warnings.${NC}"
else
    echo -e "${RED}🔧 Please address the failed checks above.${NC}"
fi

# Exit with appropriate code
if [[ $FAILED_CHECKS -gt 0 ]]; then
    exit 1
else
    exit 0
fi
