# ==========================================
# nvm (Node Version Manager) Configuration
# ==========================================

export NVM_DIR="$HOME/.nvm"

# Lazy load nvm - only load when actually needed
_load_nvm() {
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

# Stub function for nvm
nvm() {
  unset -f nvm
  _load_nvm
  nvm "$@"
}

# Optional: Stub functions for node/npm/npx to auto-load nvm
# Uncomment if you want these commands to trigger nvm loading
# node() {
#   unset -f node npm npx
#   _load_nvm
#   node "$@"
# }
# npm() {
#   unset -f node npm npx
#   _load_nvm
#   npm "$@"
# }
# npx() {
#   unset -f node npm npx
#   _load_nvm
#   npx "$@"
# }
