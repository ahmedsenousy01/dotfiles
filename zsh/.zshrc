export EDITOR='nvim'
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

(( $+commands[starship] )) && [[ -t 1 ]] && eval "$(starship init zsh)"

autoload -Uz compinit
compinit -C
if (( $+commands[carapace] )); then
	source <(carapace _carapace zsh)
	(( $+functions[_carapace_completer] )) && compdef _carapace_completer -default-
fi

(( $+commands[mise] )) && eval "$(mise activate zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[atuin] )) && [[ -t 1 ]] && eval "$(atuin init zsh)"
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

# Aliases
alias la=tree
alias cat=bat
alias cl='clear'

# Directory navigation
alias ..="cd .."
alias ...="cd ../.."

# Eza (modern ls replacement)
alias l="eza -l --icons --git -a"
alias lt="eza --tree --level=2 --long --icons --git"
alias ltree="eza --tree --level=2  --icons --git"

# Zsh plugins (keep last; syntax-highlighting must be last)
if (( $+commands[brew] )); then
	BREW_PREFIX="$(brew --prefix)"
	[[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
	[[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
