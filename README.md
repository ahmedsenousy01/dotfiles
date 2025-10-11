# Dotfiles

Comprehensive dotfiles managed with GNU Stow for easy deployment across machines.

## Quick Install

```bash
./install.sh
```

This installs dependencies, deploys configurations, and runs validation.

## Validation

Check that everything is working:

```bash
./validate.sh
```

## Manual Deployment

Deploy all configurations:

```bash
# Deploy all packages at once
stow atuin ghostty karabiner nvim ssh starship tmux vscode zsh

# Or deploy individual packages
stow nvim      # goes to ~/.config/nvim
stow zsh       # goes to ~/.zshrc
stow vscode    # goes to ~/Library/Application Support/{Code,Cursor}/
```

Deploy individual packages:

## Included Tools

### Terminal

- **tmux** - Terminal multiplexer with plugins
- **zsh** - Shell with Oh My Zsh
- **starship** - Shell prompt
- **ghostty** - Terminal emulator

### Development

- **neovim** - LazyVim configuration
- **atuin** - Shell history
- **karabiner-elements** - Keyboard customization

### Utilities

- **fzf** - Fuzzy finder
- **zoxide** - Smart cd
- **eza** - ls replacement
- **bat** - cat with syntax highlighting
- **ripgrep** - Text search
- **fd** - Find replacement
- **mise** - Version manager
- **direnv** - Environment switcher

### Cloud

- **kubectl** - Kubernetes CLI
- **kubectx** - Switch between kubectl contexts

## Structure

Each directory represents a stow package:

```
dotfiles/
├── atuin/          → ~/.config/atuin/
├── ghostty/        → ~/.config/ghostty/
├── karabiner/      → ~/.config/karabiner/
├── nvim/           → ~/.config/nvim/
├── ssh/            → ~/.ssh/
├── starship/       → ~/.config/starship/
├── tmux/           → ~/.config/tmux/
├── vscode/         → ~/Library/Application Support/{Code,Cursor}/
└── zsh/            → ~/.zshrc
```

## After Installation

1. Restart terminal or run `source ~/.zshrc`
2. Start tmux (plugins install automatically)
3. Restart VS Code/Cursor and Karabiner-Elements

## Updates

```bash
cd ~/dotfiles
git pull
stow -R atuin ghostty karabiner nvim ssh starship tmux vscode zsh
```

## Adding New Configs

1. Create package directory matching target path:
   - `package/.config/app/` → `~/.config/app/`
   - `package/.dotfile` → `~/.dotfile`
2. Run `stow package-name`

## Requirements

- macOS
- Homebrew
- GNU Stow

## Configuration

Uses `.stowrc`:

```
--target=~
--ignore=.stowrc
--ignore=DS_Store
```

## Commands

- `stow -D package` - Unlink package
- `stow -R package` - Restow package
- `./validate.sh` - Check setup
