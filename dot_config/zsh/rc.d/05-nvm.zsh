# ==========================================
# nvm (Node Version Manager) Configuration
# Lazy-loaded for faster zsh startup (~95% improvement)
# ==========================================

export NVM_DIR="$HOME/.nvm"

_load_nvm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  if [ -s "$NVM_DIR/bash_completion" ]; then
    autoload -U +X bashcompinit && bashcompinit
    ZSH_VERSION= source "$NVM_DIR/bash_completion"
  fi
}

nvm()  { _load_nvm; nvm "$@"; }
node() { _load_nvm; node "$@"; }
npm()  { _load_nvm; npm "$@"; }
npx()  { _load_nvm; npx "$@"; }
