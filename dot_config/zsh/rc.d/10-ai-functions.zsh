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

# --- Step 2: Define Provider Configurations ---
# Using a naming convention (_claude_provider_<name_with_underscores>)
# The values are loaded from environment variables set in .zshrc.

typeset -A _claude_provider_cceverything_payg=(
  url           "https://hk.cceverything.com/api"
  token_var     'CCEVERYTHING_PAYG_TOKEN'
)
typeset -A _claude_provider_cceverything=(
  url           "https://hk.cceverything.com/api"
  token_var     'CCEVERYTHING_TOKEN'
)
typeset -A _claude_provider_codemirror=(
  url           "https://api.codemirror.codes"
  token_var     'CODEMIRROR_TOKEN'
)
typeset -A _claude_provider_codesome=(
  url           "https://v2.codesome.cn"
  token_var     'CODESOME_TOKEN'
)
typeset -A _claude_provider_codesome_ai=(
  url           "https://cc.codesome.ai"
  token_var     'CODESOME_TOKEN'
)
typeset -A _claude_provider_streamlake=(
  url           "https://vanchin.streamlake.ai/api/gateway/v1/endpoints/ep-5yrdj1-1760167206638876146/claude-code-proxy"
  token_var     'STREAMLAKE_TOKEN'
)
typeset -A _claude_provider_glm=(
  url           "https://open.bigmodel.cn/api/anthropic"
  token_var     'GLM_TOKEN'
  haiku_model   "glm-4.7"
  sonnet_model  "glm-5"
  opus_model    "glm-5"
  extra_flags   "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
)
typeset -A _claude_provider_z=(
  url           "https://api.z.ai/api/anthropic"
  token_var     'GLM_TOKEN'
  haiku_model   "glm-4.7"
  sonnet_model  "glm-5"
  opus_model    "glm-5"
  extra_flags   "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
)
typeset -A _claude_provider_anyrouter=(
  url           "https://anyrouter.top"
  token_var     'ANYROUTER_TOKEN'
)
typeset -A _claude_provider_anyrouter_cn=(
  url           "https://pmpjfbhq.cn-nb1.rainapp.top"
  token_var     'ANYROUTER_TOKEN'
)
typeset -A _claude_provider_moonshot=(
  url           "https://api.moonshot.cn/anthropic"
  token_var     'MOONSHOT_TOKEN'
)
typeset -A _claude_provider_modelscope=(
  url           "https://api-inference.modelscope.cn"
  token_var     'MODELSCOPE_TOKEN'
  haiku_model   "ZhipuAI/GLM-4.7-Flash"
  sonnet_model  "ZhipuAI/GLM-4.7"
  opus_model    "ZhipuAI/GLM-4.7"
)
typeset -A _claude_provider_aliyuncs=(
  url           "https://dashscope.aliyuncs.com/apps/anthropic"
  token_var     'ALIYUNCS_TOKEN'
  haiku_model   "qwen-flash"
  sonnet_model  "qwen3-coder-plus"
  opus_model    "qwen3-max-preview"
)
typeset -A _claude_provider_kimi=(
  url           "https://api.kimi.com/coding"
  token_var     'KIMI_TOKEN'
  haiku_model   "kimi-for-coding"
  sonnet_model  "kimi-for-coding"
  opus_model    "kimi-for-coding"
)
typeset -A _claude_provider_zenmux=(
  url           "https://zenmux.ai/api/anthropic"
  token_var     'ZENMUX_TOKEN'
  haiku_model   "z-ai/glm-4.6v-flash"
  sonnet_model  "kuaishou/kat-coder-pro-v1"
  opus_model    "google/gemini-3-pro-preview"
  extra_flags   "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
)
typeset -A _claude_provider_tu_zi=(
  url           "https://api.tu-zi.com"
  token_var     'TU_ZI_TOKEN'
  haiku_model   "gemini-2.5-flash"
  sonnet_model  "gemini-3-pro-preview"
  opus_model    "gemini-3-pro-preview"
  extra_flags   "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
)
typeset -A _claude_provider_openrouter=(
  url           "https://openrouter.ai/api"
  token_var     'OPENROUTER_TOKEN'
  haiku_model   "openrouter/pony-alpha"
  sonnet_model  "openrouter/pony-alpha"
  opus_model    "openrouter/pony-alpha"
)
typeset -A _claude_provider_antigravity=(
  url           "http://10.10.0.195:8045"
  token_var     'ANTIGRAVITY_TOKEN'
  haiku_model   "gemini-3-flash"
  sonnet_model  "gemini-3-pro-low"
  opus_model    "gemini-3-pro-high"
)
typeset -A _claude_provider_antigravity_claude=(
  url           "http://10.10.0.195:8045"
  token_var     'ANTIGRAVITY_CLAUDE_TOKEN'
  haiku_model   "gemini-3-flash"
  sonnet_model  "claude-sonnet-4-5-thinking"
  opus_model    "claude-opus-4-5-thinking"
)
typeset -A _claude_provider_cliproxyapi_qwen=(
  url           "http://10.10.0.195:8317"
  token_var     'CLIPROXYAPI_TOKEN'
  haiku_model   "qwen3-coder-next"
  sonnet_model  "qwen3.5-plus"
  opus_model    "qwen3-max-preview"
)
typeset -A _claude_provider_cliproxyapi_glm=(
  url           "http://10.10.0.195:8317"
  token_var     'CLIPROXYAPI_TOKEN'
  haiku_model   "glm-4.7"
  sonnet_model  "glm-5"
  opus_model    "glm-5"
)
typeset -A _claude_provider_cliproxyapi_glm_5=(
  url           "http://10.10.0.195:8317"
  token_var     'CLIPROXYAPI_TOKEN'
  haiku_model   "glm-5"
  sonnet_model  "glm-5"
  opus_model    "glm-5"
)
typeset -A _claude_provider_cliproxyapi_kimi=(
  url           "http://10.10.0.195:8317"
  token_var     'CLIPROXYAPI_TOKEN'
  haiku_model   "kimi-k2.5"
  sonnet_model  "kimi-k2.5"
  opus_model    "kimi-k2.5"
)
typeset -A _claude_provider_cliproxyapi_minimax=(
  url           "http://10.10.0.195:8317"
  token_var     'CLIPROXYAPI_TOKEN'
  haiku_model   "MiniMax/MiniMax-M2.5"
  sonnet_model  "MiniMax/MiniMax-M2.5"
  opus_model    "MiniMax/MiniMax-M2.5"
)
typeset -A _claude_provider_cliproxyapi_doubao=(
  url           "http://10.10.0.195:8317"
  token_var     'CLIPROXYAPI_TOKEN'
  haiku_model   "ark/doubao-seed-2.0-code"
  sonnet_model  "ark/doubao-seed-2.0-code"
  opus_model    "ark/doubao-seed-2.0-code"
)
typeset -A _claude_provider_cliproxyapi_gemini=(
  url           "http://10.10.0.195:8317"
  token_var     'CLIPROXYAPI_TOKEN'
  haiku_model   "gemini-3-flash-preview"
  sonnet_model  "gemini-3.1-pro-preview"
  opus_model    "gemini-3.1-pro-preview"
)

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

# --- Step 4: Define and Register Zsh Completions ---
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
