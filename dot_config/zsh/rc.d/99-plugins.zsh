# Plugins

if type brew &>/dev/null; then
    local BREW_PREFIX=$(brew --prefix)
    FPATH=~/.config/zsh/completions:$BREW_PREFIX/share/zsh-completions:$FPATH
fi

# export ZSH_AUTOSUGGEST_STRATEGY=(ai history)
export ZSH_AUTOSUGGEST_STRATEGY=(ai)
export ZSH_AUTOSUGGEST_AI_MIN_INPUT=0
export ZSH_AUTOSUGGEST_AI_HISTORY_LINES=5
export ZSH_AUTOSUGGEST_AI_PREFER_PWD_HISTORY=yes
export ZSH_AUTOSUGGEST_AI_DEBUG=0

# 1. Core Completion & Autosuggestions
source $HOME/Developer/FradSer/zsh-autosuggestions/zsh-autosuggestions.zsh
# source $HOME/Developer/FradSer/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# 2. FZF-Tab (Must be loaded after compinit and before syntax highlighting)
source $HOME/Developer/FradSer/fzf-tab/fzf-tab.plugin.zsh

# 3. Utilities
source ${BREW_PREFIX:-/opt/homebrew}/share/zsh-autopair/autopair.zsh
source ${BREW_PREFIX:-/opt/homebrew}/share/zsh-you-should-use/you-should-use.plugin.zsh

# 4. Visual & History (Must be loaded last)
source ${BREW_PREFIX:-/opt/homebrew}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ${BREW_PREFIX:-/opt/homebrew}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

# --- FZF-Tab Settings ---
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --icons --color=always $realpath'
# preview file's content with bat when completing other commands
zstyle ':fzf-tab:complete:*:*' fzf-preview '[[ -f $realpath ]] && bat --color=always --line-range :200 $realpath || eza -1 --icons --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'

# Key bindings for history substring search
for mode in emacs viins; do
  if [[ -n "${terminfo[kcuu1]}" ]]; then
    bindkey -M $mode "${terminfo[kcuu1]}" history-substring-search-up
  fi
  if [[ -n "${terminfo[kcud1]}" ]]; then
    bindkey -M $mode "${terminfo[kcud1]}" history-substring-search-down
  fi
  bindkey -M $mode '^[[A' history-substring-search-up
  bindkey -M $mode '^[[B' history-substring-search-down
  bindkey -M $mode '^[OA' history-substring-search-up
  bindkey -M $mode '^[OB' history-substring-search-down
done
