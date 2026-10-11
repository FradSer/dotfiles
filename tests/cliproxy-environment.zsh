#!/bin/zsh
set -eu

repo="${0:A:h:h}"

# Secrets remain local and are never printed or copied into fixtures.
(
  unset OPENAI_BASE_URL OPENAI_API_KEY CLIPROXYAPI_API_KEY CLIPROXYAPI_TOKEN
  unset CLIPROXYAPI_HOST CLIPROXYAPI_HOST_PORT CLIPROXYAPI_BASE_URL
  source "$HOME/.config/zsh/.secret"
  [[ -n "$CLIPROXYAPI_TOKEN" ]]
  [[ -z "${CLIPROXYAPI_API_KEY+x}" ]]
  [[ -z "${OPENAI_BASE_URL+x}" && -z "${OPENAI_API_KEY+x}" ]]
  [[ "$CLIPROXYAPI_BASE_URL" == "http://${CLIPROXYAPI_HOST}:${CLIPROXYAPI_HOST_PORT}/v1" ]]
)

(
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  export CLIPROXYAPI_HOST=proxy.example.invalid
  export CLIPROXYAPI_HOST_PORT=9876
  export CLIPROXYAPI_TOKEN=synthetic-proxy-token
  mkdir -p "$tmp/bin"
  printf '#!/bin/sh\n[ "$ANTHROPIC_BASE_URL" = "http://proxy.example.invalid:9876" ] && [ "$ANTHROPIC_AUTH_TOKEN" = synthetic-proxy-token ]\n' > "$tmp/bin/claude"
  chmod +x "$tmp/bin/claude"
  export PATH="$tmp/bin:$PATH"
  CLAUDE_PROVIDER_TOOL="$repo/dot_config/zsh/executable_claude-provider.py"
  source "$repo/dot_config/zsh/rc.d/10-ai-claude.zsh"
  CLAUDE_PROVIDERS_FILE="$repo/dot_config/zsh/dot_claude-providers.toml"
  _claude_providers_load
  count=0
  for provider in "${_CLAUDE_PROVIDER_NAMES[@]}"; do
    [[ "$provider" == cliproxyapi || "$provider" == cliproxyapi-* ]] || continue
    [[ "$(_claude_provider_get "$provider" token_var)" == CLIPROXYAPI_TOKEN ]]
    claude --provider "$provider"
    count=$((count + 1))
  done
  [[ "$count" -gt 0 ]]
)
print 'CLIPROXY_ENV_TESTS=PASS'
