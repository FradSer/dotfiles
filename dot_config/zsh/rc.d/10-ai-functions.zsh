# ==============================================================================
# Gemini CLI - Claude Command Module (All-in-One)
#
# This file contains all logic, configuration, and completion for the `claude` wrapper.
# It is designed to be self-contained to avoid Zsh sourcing and scope issues.
# ==============================================================================

# Global AI Variables
export GOOGLE_VERTEX_LOCATION="us-central1"

# --- Step 1: Provider Name Discovery ---
# Providers are derived from the associative array definitions below.
function _claude_provider_names() {
  local -a names
  local name

  for name in ${(k)parameters}; do
    [[ "$name" == _claude_provider_* ]] || continue
    if [[ "${(tP)name}" == association* ]]; then
      names+=("${name#_claude_provider_}")
    fi
  done

  names=("${(@on)names}")
  names=("${(@)names//_/-}")
  echo "${names[@]}"
}

# --- Step 2: Load All Providers from TOML ---
CLAUDE_PROVIDERS_FILE="${HOME}/.config/zsh/.claude-providers.toml"

function _load_claude_providers() {
  [[ -f "$CLAUDE_PROVIDERS_FILE" ]] || return

  local p_name="" p_url="" p_token="" p_haiku="" p_sonnet="" p_opus="" p_extra=""
  local line name_part value safe expanded_url

  _register_provider() {
    [[ -z "$p_name" ]] && return
    safe="${p_name//-/_}"
    expanded_url="${(e)p_url}"
    eval "typeset -gA _claude_provider_${safe}; _claude_provider_${safe}=(url '${expanded_url}' token_var '${p_token}' haiku_model '${p_haiku}' sonnet_model '${p_sonnet}' opus_model '${p_opus}' extra_flags '${p_extra}')"
  }

  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      \[provider.*\])
        _register_provider
        name_part="${line#\[provider.}"
        p_name="${name_part%\]}"
        p_url="" p_token="" p_haiku="" p_sonnet="" p_opus="" p_extra=""
        ;;
      'url = "'*)
        value="${line#url = \"}"
        p_url="${value%\"}"
        ;;
      'token_var = "'*)
        value="${line#token_var = \"}"
        p_token="${value%\"}"
        ;;
      'haiku_model = "'*)
        value="${line#haiku_model = \"}"
        p_haiku="${value%\"}"
        ;;
      'sonnet_model = "'*)
        value="${line#sonnet_model = \"}"
        p_sonnet="${value%\"}"
        ;;
      'opus_model = "'*)
        value="${line#opus_model = \"}"
        p_opus="${value%\"}"
        ;;
      'extra_flags = "'*)
        value="${line#extra_flags = \"}"
        p_extra="${value%\"}"
        ;;
    esac
  done < "$CLAUDE_PROVIDERS_FILE"

  _register_provider
  unfunction _register_provider
}

_load_claude_providers

# --- Step 3: The Main `claude` Function ---
function claude() {

  export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

  # Ensure a clean environment for each run
  unset CLAUDE_CODE_OAUTH_TOKEN \
    ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC ANTHROPIC_DEFAULT_HAIKU_MODEL \
    ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_DEFAULT_OPUS_MODEL

  local provider_name=""
  local remaining_args=()

  # Parse arguments to find a valid provider flag
  local -a providers_list
  providers_list=($(_claude_provider_names))

  for arg in "$@"; do
    local potential_provider="${arg#--}"
    if [[ "$arg" == --* && "${providers_list[(Ie)$potential_provider]}" -gt 0 ]]; then
      provider_name="$potential_provider"
    else
      remaining_args+=("$arg")
    fi
  done

  # If a provider was found, set its configuration
  if [[ -n "$provider_name" ]]; then
    local sanitized_name="${provider_name//-/_}"
    local config_var_name="_claude_provider_${sanitized_name}"

    local url_ref="${config_var_name}[url]"
    export ANTHROPIC_BASE_URL="${(P)url_ref}"
    export ANTHROPIC_API_KEY=""

    local token_var_name_ref="${config_var_name}[token_var]"
    local token_var_name="${(P)token_var_name_ref}"
    if [[ -n "$token_var_name" ]]; then
      export ANTHROPIC_AUTH_TOKEN="${(P)token_var_name}"
    fi

    local haiku_ref="${config_var_name}[haiku_model]"
    local sonnet_ref="${config_var_name}[sonnet_model]"
    local opus_ref="${config_var_name}[opus_model]"
    local haiku_model_val="${(P)haiku_ref}"
    local sonnet_model_val="${(P)sonnet_ref}"
    local opus_model_val="${(P)opus_ref}"
    [ -n "${haiku_model_val}" ] && export ANTHROPIC_DEFAULT_HAIKU_MODEL="${haiku_model_val}"
    [ -n "${sonnet_model_val}" ] && export ANTHROPIC_DEFAULT_SONNET_MODEL="${sonnet_model_val}"
    [ -n "${opus_model_val}" ] && export ANTHROPIC_DEFAULT_OPUS_MODEL="${opus_model_val}"

    local flags_ref="${config_var_name}[extra_flags]"
    local extra_flags_val="${(P)flags_ref}"
    if [[ -n "${extra_flags_val}" ]]; then
      eval "export ${extra_flags_val}"
    fi
  fi

  # Run the wrapped claude command
  command claude --dangerously-skip-permissions --model opusplan "${remaining_args[@]}"
}

# --- Step 4: Interactive Provider Management ---
function claude-provider() {
  local action="${1:-list}"
  local toml_file="${CLAUDE_PROVIDERS_FILE}"

  case "$action" in
    list|ls)
      echo "Available providers:"
      echo ""
      local -a providers_list
      providers_list=($(_claude_provider_names))
      for provider in "${providers_list[@]}"; do
        local var_name="_claude_provider_${provider//-/_}"
        if [[ "${(tP)var_name}" == association* ]]; then
          local url="${${(P)var_name}[url]}"
          local token="${${(P)var_name}[token_var]}"
          local haiku="${${(P)var_name}[haiku_model]}"
          printf "  --%-35s  %s\n" "$provider" "$url"
          printf "    Token: %s  |  Haiku: %s\n" "$token" "$haiku"
        fi
      done
      ;;

    add)
      local name="$2"
      if [[ -z "$name" ]]; then
        echo "Usage: claude-provider add <name>"
        echo "Example: claude-provider add cliproxyapi-deepseek"
        return 1
      fi

      if grep -q "^\[provider\.${name}\]" "$toml_file" 2>/dev/null; then
        echo "Error: Provider '$name' already exists in TOML!"
        return 1
      fi

      echo "Adding new provider: $name"
      echo ""
      read "url?URL: "
      read "token?Token variable (default CLIPROXYAPI_TOKEN): "
      token="${token:-CLIPROXYAPI_TOKEN}"
      read "haiku?Haiku model: "
      read "sonnet?Sonnet model: "
      read "opus?Opus model: "

      if [[ -z "$url" || -z "$haiku" || -z "$sonnet" || -z "$opus" ]]; then
        echo "Error: URL and all model fields are required!"
        return 1
      fi

      printf '\n[provider.%s]\nurl = "%s"\ntoken_var = "%s"\nhaiku_model = "%s"\nsonnet_model = "%s"\nopus_model = "%s"\n' \
        "$name" "$url" "$token" "$haiku" "$sonnet" "$opus" >> "$toml_file"

      _load_claude_providers
      echo ""
      echo "Provider '$name' added!"
      echo "Use: claude --${name} <prompt>"
      ;;

    remove|rm)
      local name="$2"
      if [[ -z "$name" ]]; then
        echo "Usage: claude-provider remove <name>"
        return 1
      fi

      if ! grep -q "^\[provider\.${name}\]" "$toml_file" 2>/dev/null; then
        echo "Error: Provider '$name' not found in TOML!"
        return 1
      fi

      local tmp="${toml_file}.tmp"
      awk -v target="[provider.${name}]" '
        /^\[/ { in_sec = ($0 == target) }
        !in_sec { print }
      ' "$toml_file" > "$tmp" && mv "$tmp" "$toml_file"

      unset "_claude_provider_${name//-/_}"
      echo "Provider '$name' removed!"
      ;;

    show|info)
      local name="$2"
      if [[ -z "$name" ]]; then
        echo "Usage: claude-provider show <name>"
        return 1
      fi

      local safe_name="${name//-/_}"
      local var_name="_claude_provider_${safe_name}"

      if [[ "${(tP)var_name}" != association* ]]; then
        echo "Error: Provider '$name' does not exist!"
        return 1
      fi

      echo "Provider: $name"
      echo "===================="
      echo "URL:        ${${(P)var_name}[url]}"
      echo "Token var:  ${${(P)var_name}[token_var]}"
      echo "Haiku:      ${${(P)var_name}[haiku_model]}"
      echo "Sonnet:     ${${(P)var_name}[sonnet_model]}"
      echo "Opus:       ${${(P)var_name}[opus_model]}"
      ;;

    help|-h|--help)
      echo "claude-provider - Interactive Claude provider management"
      echo ""
      echo "Usage: claude-provider <command> [options]"
      echo ""
      echo "Commands:"
      echo "  list, ls              List all available providers"
      echo "  add <name>            Add a new provider to TOML"
      echo "  remove <name>         Remove a provider from TOML"
      echo "  show <name>           Show details of a provider"
      echo "  help                  Show this help message"
      echo ""
      echo "Examples:"
      echo "  claude-provider list"
      echo "  claude-provider add cliproxyapi-deepseek"
      echo "  claude-provider show cliproxyapi-qwen"
      echo "  claude-provider remove cliproxyapi-glm"
      ;;

    *)
      echo "Unknown command: $action"
      echo "Run 'claude-provider help' for usage information."
      return 1
      ;;
  esac
}

# Alias for shorter command
alias cpf='claude-provider'

# --- Step 5: Define and Register Zsh Completions ---
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

# Register the completion function for the `claude` command
(( $+functions[compdef] )) && compdef _claude_completions claude

# Completion for claude-provider
function _claude_provider_completions() {
  local -a commands
  commands=(
    'list:List all available providers'
    'add:Add a new provider'
    'remove:Remove a provider'
    'show:Show details of a provider'
    'help:Show help message'
  )

  local -a providers
  local -a providers_list
  providers_list=($(_claude_provider_names))

  for provider in "${providers_list[@]}"; do
    providers+=("${provider}:Provider")
  done

  _arguments -C \
    '1: :->command' \
    '2: :->provider'

  case $state in
    command)
      _describe 'command' commands
      ;;
    provider)
      case "${words[2]}" in
        remove|show)
          _describe 'provider' providers
          ;;
        *)
          _message 'provider name'
          ;;
      esac
      ;;
  esac
}

(( $+functions[compdef] )) && compdef _claude_provider_completions claude-provider
(( $+functions[compdef] )) && compdef _claude_provider_completions cpf


# ==============================================================================
# Other AI CLI Wrappers
# ==============================================================================

# MARK: - OpenAI CLI
function codex() {
  if [[ "$1" == "--original" ]]; then
    shift
    command codex "$@"
  else
    command codex --dangerously-bypass-approvals-and-sandbox "$@"
  fi
}

# MARK: - Gemini CLI
function gemini() {
  if [[ "$1" == "--original" ]]; then
    shift
    command gemini "$@"
  else
    command gemini --yolo "$@"
  fi
}

# MARK: - Qwen CLI
function qwen() {
  if [[ "$1" == "--original" ]]; then
    shift
    command qwen "$@"
  else
    command qwen --yolo "$@"
  fi
}
