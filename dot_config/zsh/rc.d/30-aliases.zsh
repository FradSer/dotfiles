# ==========================================
# Aliases
# ==========================================

# --- 1. System & Productivity ---
alias reload="source ~/.zshrc"
alias p="pnpm"
alias brewst="brew bundle --file=~/.local/share/chezmoi/Brewfile"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias grep="grep --color=auto"
alias ip="ipconfig getifaddr en0" # macOS Quick IP

# Quick Jump
alias down="cd ~/Downloads"
alias dev="cd ~/Developer"
alias doc="cd ~/Documents"

if type bat &>/dev/null; then
  alias cat="bat"
fi

# --- 2. File System (Enhanced ls) ---
# Use eza (modern ls replacement) if available, otherwise fallback to ls
if type eza &>/dev/null; then
  alias ls="eza --icons --git --group-directories-first"
  alias ll="eza -l --icons --git -a --group-directories-first"
  alias l="eza -l --icons --git --group-directories-first"
  alias la="eza -la --icons --git --group-directories-first"
  alias tree="eza --tree --icons"
else
  alias ll="ls -lah"
  alias la="ls -A"
  alias l="ls -CF"
fi

# Safety nets (prevent accidental deletions)
# alias rm="rm -i"
# alias cp="cp -i"
# alias mv="mv -i"

# --- 3. Git (The "Essential" OMZ set) ---
# Selected essential Git aliases from Oh-My-Zsh

alias g="git"

# Status & Diff
alias gst="git status"
alias gd="git diff"
alias gds="git diff --staged"

# Branching
alias gco="git checkout"
alias gcb="git checkout -b"
alias gb="git branch"
alias gbd="git branch -d"
alias gm="git merge"

# Add & Commit
alias ga="git add"
alias gaa="git add --all"
alias gc="git commit -v"
alias gcmsg="git commit -m"
alias gcam="git commit -a -m" # Add all tracked & commit
alias gamend="git commit --amend"

# Pull & Push
alias gl="git pull"
alias gp="git push"
alias gpsup='git push --set-upstream origin $(git branch --show-current)'
alias gpf="git push --force-with-lease" # Safer than --force

# Log
alias glog="git log --oneline --decorate --graph"
alias glol="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"

# Stash
alias gsta="git stash push"
alias gstp="git stash pop"
alias gstl="git stash list"
