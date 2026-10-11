# ==============================================================================
# Other AI CLIs — native defaults, with an explicit leading --yolo opt-in.
# ==============================================================================

_ai_wrap() {
  local cmd="$1" flag="$2"
  shift 2
  if [[ "${1:-}" == "--yolo" ]]; then
    shift
    command "$cmd" "$flag" "$@"
  else
    command "$cmd" "$@"
  fi
}

codex()  { _ai_wrap codex  --dangerously-bypass-approvals-and-sandbox "$@" }
gemini() { _ai_wrap gemini --yolo "$@" }
qwen()   { _ai_wrap qwen   --yolo "$@" }
