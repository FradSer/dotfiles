# ==============================================================================
# Other AI CLIs — wrappers that auto-apply a YOLO-style flag, with
# `--original` escape hatch to invoke the binary without it.
# ==============================================================================

_ai_wrap() {
  local cmd="$1" flag="$2"
  shift 2
  if [[ "$1" == "--original" ]]; then
    shift
    command "$cmd" "$@"
  else
    command "$cmd" "$flag" "$@"
  fi
}

codex()  { _ai_wrap codex  --dangerously-bypass-approvals-and-sandbox "$@" }
gemini() { _ai_wrap gemini --yolo "$@" }
qwen()   { _ai_wrap qwen   --yolo "$@" }
