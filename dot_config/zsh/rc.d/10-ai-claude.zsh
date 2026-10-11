# Claude Code provider wrapper. Management uses Python 3.11+ (tomllib).
export GOOGLE_VERTEX_LOCATION="us-central1"
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
export CLAUDE_CODE_NEW_INIT=1
export CLAUDE_CODE_NO_FLICKER=1
export CLAUDE_CODE_SIMPLE_SYSTEM_PROMPT=1
export CLAUDE_CODE_FORK_SUBAGENT=1
export CLAUDE_AUTO_BACKGROUND_TASKS=1

CLAUDE_PROVIDERS_FILE="${HOME}/.config/zsh/.claude-providers.toml"
CLAUDE_PROVIDER_TOOL="${CLAUDE_PROVIDER_TOOL:-${HOME}/.config/zsh/claude-provider.py}"
typeset -gA _CLAUDE_PROVIDERS
typeset -ga _CLAUDE_PROVIDER_NAMES

_claude_providers_load() {
  local records name field value
  _CLAUDE_PROVIDERS=()
  _CLAUDE_PROVIDER_NAMES=()
  records="$(python3 "$CLAUDE_PROVIDER_TOOL" load "$CLAUDE_PROVIDERS_FILE")" || return
  while IFS= read -r -d '' name && IFS= read -r -d '' field && IFS= read -r -d '' value; do
    _CLAUDE_PROVIDERS[${name}::${field}]="$value"
    (( ${_CLAUDE_PROVIDER_NAMES[(Ie)$name]} )) || _CLAUDE_PROVIDER_NAMES+=("$name")
  done < <(printf '%s' "$records")
  return 0
}

_claude_provider_get() { print -r -- "${_CLAUDE_PROVIDERS[${1}::${2}]-}" }

claude() (
  trap '[[ ! -t 1 ]] || printf "\e[>0u"' EXIT
  case "${1-}" in
    --provider|--yolo) command python3 "$CLAUDE_PROVIDER_TOOL" run "$CLAUDE_PROVIDERS_FILE" "$@" ;;
    *) command claude "$@" ;;
  esac
)

claude-provider() {
  local action="${1:-list}"
  (( $# )) && shift
  python3 "$CLAUDE_PROVIDER_TOOL" "$action" "$CLAUDE_PROVIDERS_FILE" "$@"
}

alias cpf='claude-provider'
