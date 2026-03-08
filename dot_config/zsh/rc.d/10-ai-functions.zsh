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

# Load completions immediately so they are available before function execution
if [[ -f "$HOME/.config/zsh/10-ai-functions.zsh" ]]; then
  # We only need the completion parts, but sourcing the whole file is easiest
  # Let's extract and run just the completion definition part
  autoload -Uz compinit

  function _claude_provider_names() {
    # Lightweight version just for completions
    echo "cceverything-payg cceverything codemirror codesome codesome-ai streamlake glm z anyrouter anyrouter-cn moonshot modelscope aliyuncs kimi zenmux tu-zi openrouter antigravity antigravity-claude cliproxyapi-qwen cliproxyapi-glm cliproxyapi-glm-5 cliproxyapi-kimi cliproxyapi-minimax cliproxyapi-doubao cliproxyapi-gemini"
  }

  function _claude_completions() {
    local -a providers
    local -a options
    local -a providers_list

    providers_list=($(_claude_provider_names))

    for provider in "${providers_list[@]}"; do
        providers+=("--${provider}:Use the ${provider} provider")
    done

    options=(
      "--help:Show help"
      "--version:Show version"
      "--model:Override model"
      "--dangerously-skip-permissions:Skip permissions prompts"
    )

    _arguments -C \
      '*: :->args'

    case $state in
      args)
        _describe -t providers "provider" providers
        _describe -t options "option" options
        _files
        ;;
    esac
  }

  compdef _claude_completions claude
fi

