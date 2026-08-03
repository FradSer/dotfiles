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

  local line name="" field value elem
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ '^\[provider\.([^]]+)\]$' ]]; then
      name="${match[1]}"
      _CLAUDE_PROVIDER_NAMES+=("$name")
    elif [[ -n "$name" && "$line" =~ '^([a-z_]+)[[:space:]]*=[[:space:]]*\[[[:space:]]*$' ]]; then
      # Array value: collect quoted elements until the closing bracket.
      field="${match[1]}"
      value=""
      while IFS= read -r elem || [[ -n "$elem" ]]; do
        if [[ "$elem" =~ '^[[:space:]]*\]' ]]; then
          break
        elif [[ "$elem" =~ '^[[:space:]]*"(.*)"[[:space:]]*,?[[:space:]]*$' ]]; then
          [[ -n "$value" ]] && value+=" "
          value+="${match[1]}"
        fi
      done
      if [[ "$field" == "key" ]]; then
        _CLAUDE_PROVIDERS[${name}::${field}]="$value"
      else
        _CLAUDE_PROVIDERS[${name}::${field}]="${(e)value}"
      fi
    elif [[ -n "$name" && "$line" =~ '^([a-z_]+)[[:space:]]*=[[:space:]]*"(.*)"$' ]]; then
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
  local action="${1:-tui}"
  local toml="$CLAUDE_PROVIDERS_FILE"

  case "$action" in
    tui)
      _claude_provider_tui
      ;;

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
      _claude_provider_add "$2"
      ;;

    remove|rm)
      _claude_provider_remove "$2"
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

Usage: claude-provider [command] [options]

Commands:
  (no args)             TUI mode (fzf): browse, view, edit, delete providers
  list, ls              List all available providers
  add <name>            Add a new provider to TOML
  remove <name>         Remove a provider from TOML
  show <name>           Show details of a provider
  help                  Show this help message

TUI mode requires fzf and opens a picker with a live preview of each
provider's TOML section; select one to view, edit, or delete it.

Examples:
  claude-provider
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

# TUI helpers — require fzf
_claude_provider_tui() {
  (( $+commands[fzf] )) || {
    echo "Error: TUI mode requires fzf (brew install fzf)"
    return 1
  }
  [[ -t 1 ]] || {
    echo "Error: TUI mode requires an interactive terminal — use 'claude-provider list'"
    return 1
  }

  local toml="$CLAUDE_PROVIDERS_FILE"
  local preview="printf '[{1}]\n'; sed -n '/^\\[provider.{1}]/,/^\\[/p' '$toml' | grep -v '^\\['"
  local -a items
  local n sel

  while true; do
    items=()
    for n in "${_CLAUDE_PROVIDER_NAMES[@]}"; do
      items+=("$(printf -- '%-22s%s' "$n" "$(_claude_provider_get "$n" url)")")
    done
    items+=("+ add new provider")

    sel="$(print -l -- "${items[@]}" \
      | fzf --prompt 'provider> ' --preview "$preview" --preview-window=right:60%)" || return 0

    if [[ "$sel" == "+ add new provider" ]]; then
      _claude_provider_add
      continue
    fi

    _claude_provider_manage "${sel%% *}"
  done
}

# Manage a single provider: show full config, loop until back/delete/ESC.
_claude_provider_manage() {
  local name="$1" action
  while true; do
    action="$(_claude_provider_menu "$name")" || return 0
    case "$action" in
      edit)
        _claude_provider_edit "$name"
        ;;
      delete)
        _claude_provider_remove_confirm "$name" && return 0
        ;;
      *) return 0 ;;
    esac
  done
}

_claude_provider_menu() {
  local name="$1"

  # UI details go to stderr — stdout is reserved for the fzf selection,
  # which is captured by the caller via $(...).
  {
    clear
    print -r -- "Provider: $name"
    print -r -- "===================="
    print -r -- "URL:          $(_claude_provider_get "$name" url)"
    local key_val
    key_val="$(_claude_provider_get "$name" key)"
    if [[ -n "$key_val" ]]; then
      print -r -- "Key:          ${key_val:0:6}... (inline)"
    else
      print -r -- "Token var:    $(_claude_provider_get "$name" token_var)"
    fi
    print -r -- "Haiku:        $(_claude_provider_get "$name" haiku_model)"
    print -r -- "Sonnet:       $(_claude_provider_get "$name" sonnet_model)"
    print -r -- "Opus:         $(_claude_provider_get "$name" opus_model)"
    print -r -- "Fable:        $(_claude_provider_get "$name" fable_model)"
    print -r -- "Extra flags:  $(_claude_provider_get "$name" extra_flags)"
    print -r -- ""
  } >&2

  print -l "edit" "delete" "back" \
    | fzf --prompt 'action> ' --height=5 --reverse
}

_claude_provider_edit() {
  local name="$1"
  local toml="$CLAUDE_PROVIDERS_FILE"
  local field current newval

  field="$(print -l url token_var key haiku_model sonnet_model opus_model fable_model extra_flags \
    | fzf --prompt 'field> ' --height=9 --reverse)" || return 1

  current="$(_claude_provider_get "$name" "$field")"
  if [[ "$field" == "key" && -n "$current" ]]; then
    print -r -- "Current key: ${current:0:6}... (inline)"
  else
    print -r -- "Current ${field}: ${current:-<empty>}"
  fi
  newval=""
  vared -p "New ${field} (empty to cancel) > " newval || return 1
  [[ -z "$newval" ]] && return 1
  [[ "$newval" == "$current" ]] && { echo "Unchanged."; return 1 }

  local tmp="${toml}.tmp"
  cp "$toml" "${toml}.bak"
  awk -v sec="[provider.${name}]" -v key="$field" -v val="$newval" '
    /^\[/ { in_sec = ($0 == sec) }
    in_sec && $0 ~ ("^" key "[[:space:]]*=") { print key " = \"" val "\""; next }
    { print }
  ' "$toml" > "$tmp"

  if cmp -s "$tmp" "$toml"; then
    rm -f "$tmp" "${toml}.bak"
    echo "Error: field '$field' not found in provider '$name'"
    return 1
  fi
  mv "$tmp" "$toml"

  if ! python3 -c 'import tomllib,sys; tomllib.load(open(sys.argv[1],"rb"))' "$toml" 2>/dev/null; then
    mv "${toml}.bak" "$toml"
    echo "Error: edit produced invalid TOML — reverted"
    return 1
  fi
  rm -f "${toml}.bak"

  _claude_providers_load
  echo "Updated $name.$field"
}

_claude_provider_remove() {
  local name="$1"
  local toml="$CLAUDE_PROVIDERS_FILE"
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
}

_claude_provider_remove_confirm() {
  local name="$1" ans
  read "ans?Delete provider '$name'? [y/N]: "
  if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
    _claude_provider_remove "$name"
  else
    echo "Cancelled."
  fi
}

_claude_provider_add() {
  local toml="$CLAUDE_PROVIDERS_FILE"
  local name="$1"

  if [[ -z "$name" ]]; then
    read "name?Provider name: "
    if [[ -z "$name" ]]; then
      echo "Aborted."
      return 1
    fi
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
}

alias cpf='claude-provider'

# claude, claude-provider, and cpf completions are autoloaded via
# dot_config/zsh/completions/_claude and _claude-provider (fpath).
