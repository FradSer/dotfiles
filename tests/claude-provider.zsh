#!/bin/zsh
set -eu
root=${0:A:h:h}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME=$tmp
mkdir -p "$HOME/.config/zsh" "$tmp/bin"
printf '[provider.test]\nurl = "https://example.invalid/$(touch ${HOME}/should-not-run)"\ntoken_var = "PROVIDER_TEST_TOKEN"\nextra_flags = ["CLAUDE_CODE_EFFORT_LEVEL=max"]\n' > "$HOME/.config/zsh/.claude-providers.toml"
printf '#!/bin/sh\nexit 37\n' > "$tmp/bin/claude"
chmod +x "$tmp/bin/claude"
export PATH="$tmp/bin:$PATH"
export CLAUDE_PROVIDER_TOOL="$root/dot_config/zsh/executable_claude-provider.py"
source "$root/dot_config/zsh/rc.d/10-ai-claude.zsh"
export ANTHROPIC_AUTH_TOKEN=parent CLAUDE_CODE_EFFORT_LEVEL=parent PROVIDER_TEST_TOKEN=child
rc=0
claude --provider test > "$tmp/output" || rc=$?
[[ $rc == 37 ]]
[[ ! -s "$tmp/output" ]]
[[ $ANTHROPIC_AUTH_TOKEN == parent && $CLAUDE_CODE_EFFORT_LEVEL == parent ]]
[[ ! -e "$HOME/should-not-run" ]]
[[ $(claude-provider show test) != *child* ]]
printf '[provider.inherited]\nurl = "https://example.invalid"\ntoken_var = "ANTHROPIC_API_KEY"\n' >> "$CLAUDE_PROVIDERS_FILE"
export ANTHROPIC_API_KEY=inherited-token
export CLAUDE_CODE_USE_VERTEX=1 CLAUDE_CODE_USE_BEDROCK=1 CLAUDE_CODE_USE_FOUNDRY=1
printf '#!/bin/sh\n[ "$ANTHROPIC_AUTH_TOKEN" = inherited-token ] && [ -z "${ANTHROPIC_API_KEY+x}" ] && [ -z "${CLAUDE_CODE_USE_VERTEX+x}${CLAUDE_CODE_USE_BEDROCK+x}${CLAUDE_CODE_USE_FOUNDRY+x}" ]\n' > "$tmp/bin/claude"
claude --provider inherited
[[ $ANTHROPIC_API_KEY == inherited-token ]]
[[ $CLAUDE_CODE_USE_VERTEX == 1 && $CLAUDE_CODE_USE_BEDROCK == 1 && $CLAUDE_CODE_USE_FOUNDRY == 1 ]]
printf '#!/bin/sh\ntouch "$HOME/invoked"\nexit 0\n' > "$tmp/bin/claude"
for bad_url in '' 'http://:8080' 'ftp://example.invalid'; do
  printf '[provider.bad]\nurl = "%s"\ntoken_var = "PROVIDER_TEST_TOKEN"\n' "$bad_url" > "$tmp/bad.toml"
  rc=0
  CLAUDE_PROVIDERS_FILE="$tmp/bad.toml" claude --provider bad > "$tmp/output" 2> "$tmp/error" || rc=$?
  [[ $rc != 0 && ! -e "$HOME/invoked" ]]
done
printf '[provider.bad]\nurl = "https://example.invalid"\ntoken_var = "PROVIDER_TEST_TOKEN"\nextra_flags = "ANTHROPIC_AUTH_TOKEN=override"\n' > "$tmp/bad.toml"
rc=0
CLAUDE_PROVIDERS_FILE="$tmp/bad.toml" claude --provider bad > "$tmp/output" 2> "$tmp/error" || rc=$?
[[ $rc != 0 && ! -e "$HOME/invoked" ]]
printf '#!/bin/sh\n[ "$ANTHROPIC_AUTH_TOKEN" = parent ] || exit 12\n[ "$1" = -- ] && [ "$2" = --test ] || exit 13\n' > "$tmp/bin/claude"
claude -- --test
printf '\n[provider.legacy]\nkey = "legacy-private-value"\n' >> "$CLAUDE_PROVIDERS_FILE"
rc=0
claude --provider legacy > "$tmp/output" 2> "$tmp/error" || rc=$?
[[ $rc != 0 ]]
[[ $(<"$tmp/error") == *token_var* && $(<"$tmp/error") != *legacy-private-value* ]]
claude -- --test
rm "$CLAUDE_PROVIDERS_FILE"
claude -- --test
printf '[provider.test]\nurl = "https://example.invalid"\ntoken_var = "PROVIDER_TEST_TOKEN"\n' > "$CLAUDE_PROVIDERS_FILE"
fpath=("$root/dot_config/zsh/completions" $fpath)
autoload -Uz _claude _claude-provider _cpf
_arguments() { return 0; }
_CLAUDE_PROVIDER_NAMES=(sentinel)
for completion in _claude _claude-provider _cpf; do
  "$completion"
  "$completion"
  [[ "${_CLAUDE_PROVIDER_NAMES[*]}" == sentinel ]]
done
_CLAUDE_PROVIDER_NAMES=(stale)
printf 'invalid = "' > "$CLAUDE_PROVIDERS_FILE"
_claude_providers_load 2>/dev/null && exit 1
[[ ${#_CLAUDE_PROVIDER_NAMES} == 0 ]]
printf '#!/bin/sh\n[ "$ANTHROPIC_AUTH_TOKEN" = parent ] || exit 12\n[ "$CLAUDE_CODE_USE_VERTEX$CLAUDE_CODE_USE_BEDROCK$CLAUDE_CODE_USE_FOUNDRY" = 111 ] || exit 14\nprintf "%%s\\n" "$@"\n' > "$tmp/bin/claude"
[[ $(CLAUDE_PROVIDER_TOOL="$tmp/missing-tool" claude --version) == --version ]]
[[ $(CLAUDE_PROVIDER_TOOL="$tmp/missing-tool" claude --model native) == $'--model\nnative' ]]
[[ $(claude -- --provider test) == $'--\n--provider\ntest' ]]
printf '[provider.test]\nurl = "https://example.invalid"\ntoken_var = "PROVIDER_TEST_TOKEN"\n' > "$CLAUDE_PROVIDERS_FILE"
for selection in '' unknown; do
  rc=0
  claude --provider ${selection:+"$selection"} > "$tmp/output" 2> "$tmp/error" || rc=$?
  [[ $rc != 0 && ! -s "$tmp/output" ]]
done
rc=0
claude --provider test --provider test > "$tmp/output" 2> "$tmp/error" || rc=$?
[[ $rc != 0 && ! -s "$tmp/output" && $(<"$tmp/error") == *'select one provider'* ]]
[[ $(claude --yolo --model --yolo) == $'--dangerously-skip-permissions\n--model\n--yolo' ]]
rc=0
CLAUDE_PROVIDER_TOOL="$tmp/missing-tool" claude --yolo > "$tmp/output" 2> "$tmp/error" || rc=$?
[[ $rc != 0 && ! -s "$tmp/output" ]]
for native in --system-prompt --append-system-prompt --model --permission-mode -p prompt; do
  [[ $(claude "$native" --yolo --provider ignored --) == "${native}"$'\n--yolo\n--provider\nignored\n--' ]]
done
printf '#!/bin/sh\nprintf "%%s\\n" "$ANTHROPIC_AUTH_TOKEN" "$CLAUDE_CODE_EFFORT_LEVEL" "$@"\n' > "$tmp/bin/claude"
export FLAG_VALUE='high effort $(touch never)'
for credential in token provider url value result; do
  export "$credential=shadow-secret"
  printf '[provider.test]\nurl = "https://example.invalid"\ntoken_var = "%s"\nextra_flags = "CLAUDE_CODE_EFFORT_LEVEL=$FLAG_VALUE"\n' "$credential" > "$CLAUDE_PROVIDERS_FILE"
  [[ $(claude --provider test --yolo --model --yolo) == "shadow-secret"$'\n'"$FLAG_VALUE"$'\n--dangerously-skip-permissions\n--model\n--yolo' ]]
  [[ $(claude --yolo --provider test -- --provider ignored) == "shadow-secret"$'\n'"$FLAG_VALUE"$'\n--dangerously-skip-permissions\n--\n--provider\nignored' ]]
  [[ ${(P)credential} == shadow-secret ]]
done
typeset -a captured words
_arguments() { captured=("$@"); return 0; }
for prefix in yes no; do
  if [[ $prefix == yes ]]; then
    words=(claude --yolo --provider test '')
  else
    words=(claude --yolo --provider test --model '')
  fi
  CURRENT=${#words}
  _claude
  if [[ $prefix == yes ]]; then
    [[ "${captured[*]}" == *'--provider['* && "${captured[*]}" == *'--yolo['* ]]
  else
    [[ "${captured[*]}" != *'--provider['* && "${captured[*]}" != *'--yolo['* ]]
  fi
done
for native in -- --model --system-prompt prompt; do
  words=(claude "$native" '')
  CURRENT=${#words}
  _claude
  [[ "${captured[*]}" != *'--provider['* && "${captured[*]}" != *'--yolo['* ]]
done
words=(claude --yolo --provider '')
CURRENT=${#words}
_claude
[[ "${captured[*]}" == *'--provider[Use a configured provider]:provider:->provider'* ]]
typeset -a described
_arguments() { state=provider; return 1; }
_describe() { described=("${provider_names[@]}"); }
_CLAUDE_PROVIDER_NAMES=(sentinel)
_claude
[[ "${described[*]}" == test ]]
[[ "${_CLAUDE_PROVIDER_NAMES[*]}" == sentinel ]]
print 'provider wrapper tests passed' 
