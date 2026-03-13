# ==========================================
# fnm (Fast Node Manager) Configuration
# Blazing fast alternative to nvm (Rust)
# ==========================================

# 1. Initialize fnm environment
# --use-on-cd: Automatically switches node version based on .nvmrc or .node-version
# --version-file-strategy=recursive: Look for version files in parent directories
eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"

# 2. Add aliases for compatibility with nvm habits
alias nvm="fnm"
