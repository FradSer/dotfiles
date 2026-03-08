# ==========================================
# AI CLI Functions - Lazy Loading
# ==========================================

# Stub functions that trigger lazy loading
claude() {
  unset -f claude gemini qwen codex
  source "$HOME/.config/zsh/10-ai-functions.zsh"
  claude "$@"
}

gemini() {
  unset -f claude gemini qwen codex
  source "$HOME/.config/zsh/10-ai-functions.zsh"
  gemini "$@"
}

qwen() {
  unset -f claude gemini qwen codex
  source "$HOME/.config/zsh/10-ai-functions.zsh"
  qwen "$@"
}

codex() {
  unset -f claude gemini qwen codex
  source "$HOME/.config/zsh/10-ai-functions.zsh"
  codex "$@"
}
