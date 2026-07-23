# ==============================================================================
# Claude Code — provider wrapper, TOML-driven config, completions.
# ==============================================================================

export GOOGLE_VERTEX_LOCATION="us-central1"
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
export CLAUDE_CODE_NEW_INIT=1
export CLAUDE_CODE_NO_FLICKER=1
export CLAUDE_CODE_SIMPLE_SYSTEM_PROMPT=1
export CLAUDE_CODE_FORK_SUBAGENT=1
export CLAUDE_AUTO_BACKGROUND_TASKS=1

CLAUDE_PROVIDERS_FILE="${HOME}/.config/zsh/.claude-providers.toml"

# Flat store: _CLAUDE_PROVIDERS["<name>::<field>"] = "<value>"
typeset -gA _CLAUDE_PROVIDERS
typeset -ga _CLAUDE_PROVIDER_NAMES

_claude_providers_load() {
  _CLAUDE_PROVIDERS=()
  _CLAUDE_PROVIDER_NAMES=()
  [[ -f "$CLAUDE_PROVIDERS_FILE" ]] || return

  local line name="" field value
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ '^\[provider\.([^]]+)\]$' ]]; then
      name="${match[1]}"
      _CLAUDE_PROVIDER_NAMES+=("$name")
    elif [[ -n "$name" && "$line" =~ '^([a-z_]+) = "(.*)"$' ]]; then
      field="${match[1]}"
      value="${match[2]}"
      # Inline keys are stored verbatim; other fields allow $VAR expansion.
      if [[ "$field" == "key" ]]; then
        _CLAUDE_PROVIDERS[${name}::${field}]="$value"
      else
        _CLAUDE_PROVIDERS[${name}::${field}]="${(e)value}"
      fi
    fi
  done < "$CLAUDE_PROVIDERS_FILE"

  _CLAUDE_PROVIDER_NAMES=(${(o)_CLAUDE_PROVIDER_NAMES})
}

_claude_providers_load

_claude_provider_get() { print -r -- "${_CLAUDE_PROVIDERS[${1}::${2}]}" }


claude() {
  unset CLAUDE_CODE_OAUTH_TOKEN \
    ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC \
    ANTHROPIC_DEFAULT_HAIKU_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_DEFAULT_OPUS_MODEL \
    ANTHROPIC_DEFAULT_FABLE_MODEL

  local provider="" arg candidate
  local -i skip_perms=0
  local -a remaining=()

  for arg in "$@"; do
    candidate="${arg#--}"
    if [[ "$arg" == "--yolo" ]]; then
      skip_perms=1
    elif [[ "$arg" == --* && "${_CLAUDE_PROVIDER_NAMES[(Ie)$candidate]}" -gt 0 ]]; then
      provider="$candidate"
    else
      remaining+=("$arg")
    fi
  done

  if [[ -n "$provider" ]]; then
    export ANTHROPIC_BASE_URL="$(_claude_provider_get "$provider" url)"
    export ANTHROPIC_API_KEY=""

    local token_var v extra
    local inline_key
    inline_key="$(_claude_provider_get "$provider" key)"
    if [[ -n "$inline_key" ]]; then
      export ANTHROPIC_AUTH_TOKEN="$inline_key"
    else
      token_var="$(_claude_provider_get "$provider" token_var)"
      [[ -n "$token_var" ]] && export ANTHROPIC_AUTH_TOKEN="${(P)token_var}"
    fi

    v="$(_claude_provider_get "$provider" haiku_model)"
    [[ -n "$v" ]] && export ANTHROPIC_DEFAULT_HAIKU_MODEL="$v"
    v="$(_claude_provider_get "$provider" sonnet_model)"
    [[ -n "$v" ]] && export ANTHROPIC_DEFAULT_SONNET_MODEL="$v"
    v="$(_claude_provider_get "$provider" opus_model)"
    [[ -n "$v" ]] && export ANTHROPIC_DEFAULT_OPUS_MODEL="$v"
    v="$(_claude_provider_get "$provider" fable_model)"
    [[ -n "$v" ]] && export ANTHROPIC_DEFAULT_FABLE_MODEL="$v"

    extra="$(_claude_provider_get "$provider" extra_flags)"
    [[ -n "$extra" ]] && export ${(z)extra}
  fi

  if (( skip_perms )); then
    command claude --dangerously-skip-permissions "${remaining[@]}"
  else
    command claude "${remaining[@]}"
  fi

  printf '\e[>0u'
}

claude-provider() {
  local action="${1:-list}"
  local toml="$CLAUDE_PROVIDERS_FILE"

  case "$action" in
    list|ls)
      echo "Available providers:"
      echo ""
      local name auth
      for name in "${_CLAUDE_PROVIDER_NAMES[@]}"; do
        auth="$(_claude_provider_get "$name" token_var)"
        [[ -n "$(_claude_provider_get "$name" key)" ]] && auth="(inline key)"
        printf "  --%-35s  %s\n" "$name" "$(_claude_provider_get "$name" url)"
        printf "    Token: %s  |  Haiku: %s  |  Fable: %s\n" \
          "$auth" \
          "$(_claude_provider_get "$name" haiku_model)" \
          "$(_claude_provider_get "$name" fable_model)"
      done
      ;;

    add)
      local name="$2"
      if [[ -z "$name" ]]; then
        echo "Usage: claude-provider add <name>"
        echo "Example: claude-provider add cliproxyapi-deepseek"
        return 1
      fi
      if grep -q "^\[provider\.${name}\]" "$toml" 2>/dev/null; then
        echo "Error: Provider '$name' already exists in TOML!"
        return 1
      fi

      echo "Adding new provider: $name"
      echo ""
      local url token key haiku sonnet opus fable
      read "url?URL: "
      read "token?Token variable (default CLIPROXYAPI_TOKEN, ignored if key set): "
      read "key?Inline API key (optional, takes precedence over token variable): "
      token="${token:-CLIPROXYAPI_TOKEN}"
      read "haiku?Haiku model: "
      read "sonnet?Sonnet model: "
      read "opus?Opus model: "
      read "fable?Fable model (optional): "

      if [[ -z "$url" || -z "$haiku" || -z "$sonnet" || -z "$opus" ]]; then
        echo "Error: URL and haiku/sonnet/opus model fields are required!"
        return 1
      fi

      {
        printf '\n[provider.%s]\nurl = "%s"\n' "$name" "$url"
        if [[ -n "$key" ]]; then
          printf 'key = "%s"\n' "$key"
        else
          printf 'token_var = "%s"\n' "$token"
        fi
        printf 'haiku_model = "%s"\nsonnet_model = "%s"\nopus_model = "%s"\n' "$haiku" "$sonnet" "$opus"
        [[ -n "$fable" ]] && printf 'fable_model = "%s"\n' "$fable"
      } >> "$toml"

      _claude_providers_load
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
      if ! grep -q "^\[provider\.${name}\]" "$toml" 2>/dev/null; then
        echo "Error: Provider '$name' not found in TOML!"
        return 1
      fi

      local tmp="${toml}.tmp"
      awk -v target="[provider.${name}]" '
        /^\[/ { in_sec = ($0 == target) }
        !in_sec { print }
      ' "$toml" > "$tmp" && mv "$tmp" "$toml"

      _claude_providers_load
      echo "Provider '$name' removed!"
      ;;

    show|info)
      local name="$2"
      if [[ -z "$name" ]]; then
        echo "Usage: claude-provider show <name>"
        return 1
      fi
      if [[ "${_CLAUDE_PROVIDER_NAMES[(Ie)$name]}" -eq 0 ]]; then
        echo "Error: Provider '$name' does not exist!"
        return 1
      fi

      echo "Provider: $name"
      echo "===================="
      echo "URL:        $(_claude_provider_get "$name" url)"
      local key_val
      key_val="$(_claude_provider_get "$name" key)"
      if [[ -n "$key_val" ]]; then
        echo "Key:        ${key_val:0:6}... (inline)"
      else
        echo "Token var:  $(_claude_provider_get "$name" token_var)"
      fi
      echo "Haiku:      $(_claude_provider_get "$name" haiku_model)"
      echo "Sonnet:     $(_claude_provider_get "$name" sonnet_model)"
      echo "Opus:       $(_claude_provider_get "$name" opus_model)"
      local fable_val
      fable_val="$(_claude_provider_get "$name" fable_model)"
      [[ -n "$fable_val" ]] && echo "Fable:      $fable_val"
      ;;

    help|-h|--help)
      cat <<'EOF'
claude-provider - Interactive Claude provider management

Usage: claude-provider <command> [options]

Commands:
  list, ls              List all available providers
  add <name>            Add a new provider to TOML
  remove <name>         Remove a provider from TOML
  show <name>           Show details of a provider
  help                  Show this help message

Examples:
  claude-provider list
  claude-provider add cliproxyapi-deepseek
  claude-provider show cliproxyapi-qwen
  claude-provider remove cliproxyapi-glm
EOF
      ;;

    *)
      echo "Unknown command: $action"
      echo "Run 'claude-provider help' for usage information."
      return 1
      ;;
  esac
}

alias cpf='claude-provider'

_claude_completions() {
  local -a providers options subcommands
  local name
  for name in "${_CLAUDE_PROVIDER_NAMES[@]}"; do
    providers+=("--${name}[Use the ${name} provider]")
  done
  options=(
    "--help[Show help]"
    "--version[Show version]"
    "--model[Override model]:model:"
    "--yolo[Enable --dangerously-skip-permissions]"
    "--dangerously-skip-permissions[Skip permission prompts]"
  )
  subcommands=(
    "agents[Manage background agents]"
    "auth[Manage authentication]"
    "doctor[Check installation health]"
    "mcp[Configure MCP servers]"
    "plugin[Manage plugins]"
    "install[Install native build]"
    "update[Check for updates]"
    "ultrareview[Run cloud code review]"
  )

  _arguments -C \
    $providers \
    $options \
    '1: :->subcmd' \
    '*: :->args'
  case $state in
    subcmd) _describe -t commands 'command' subcommands ;;
    args) _files ;;
  esac
}

_claude_provider_completions() {
  local -a commands providers
  commands=(
    'list:List all available providers'
    'add:Add a new provider'
    'remove:Remove a provider'
    'show:Show details of a provider'
    'help:Show help message'
  )
  local name
  for name in "${_CLAUDE_PROVIDER_NAMES[@]}"; do
    providers+=("${name}:Provider")
  done

  _arguments -C '1: :->command' '2: :->provider'
  case $state in
    command) _describe 'command' commands ;;
    provider)
      case "${words[2]}" in
        remove|show) _describe 'provider' providers ;;
        *) _message 'provider name' ;;
      esac
      ;;
  esac
}

(( $+functions[compdef] )) && compdef _claude_completions claude
(( $+functions[compdef] )) && compdef _claude_provider_completions claude-provider
(( $+functions[compdef] )) && compdef _claude_provider_completions cpf
