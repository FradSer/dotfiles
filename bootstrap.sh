#!/bin/zsh

set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header()  { echo -e "\n${CYAN}${BOLD}==> $1${NC}\n"; }
print_step()    { echo -e "${YELLOW}${BOLD}  -> $1${NC}"; }
print_success() { echo -e "${GREEN}${BOLD}  ok $1${NC}"; }
print_error()   { echo -e "${RED}${BOLD} err $1${NC}"; }
print_info()    { echo -e "${BLUE}${BOLD}    $1${NC}"; }

echo -e "${CYAN}${BOLD}🚀 Starting environment bootstrap...${NC}"

# ==========================================
# 1. Homebrew
# ==========================================
print_header "🍺 Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  print_step "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  print_success "Homebrew already installed"
fi

# Load brew into current shell session
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v brew >/dev/null 2>&1; then
  print_error "Homebrew not found in PATH after install"
  exit 1
fi

# ==========================================
# 2. Homebrew Packages
# ==========================================
print_header "📦 Homebrew Packages"
BREWFILE_PATH="$(cd "$(dirname "$0")" && pwd)/Brewfile"
if [[ ! -f "$BREWFILE_PATH" ]]; then
  print_error "Brewfile not found at $BREWFILE_PATH"
  exit 1
fi
brew bundle --file="$BREWFILE_PATH"
print_success "Brew packages synced"

# ==========================================
# 3. Dotfiles (chezmoi)
# ==========================================
print_header "📁 Dotfiles (chezmoi)"
if command -v chezmoi >/dev/null 2>&1; then
  chezmoi init --apply FradSer
else
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply FradSer
fi
print_success "Dotfiles applied"

SECRETS_FILE="$HOME/.config/zsh/.secret"
if [[ ! -f "$SECRETS_FILE" ]]; then
  mkdir -p "$(dirname "$SECRETS_FILE")"
  touch "$SECRETS_FILE"
  print_info "⚠️  Created empty $SECRETS_FILE — sync your secrets manually"
fi

# ==========================================
# 4. Workspace
# ==========================================
print_header "🏗️ Workspace"
mkdir -p "$HOME/Developer/FradSer"
print_success "$HOME/Developer/FradSer created"

# ==========================================
# 5. Git
# ==========================================
print_header "🔧 Git"
git config --global user.name  "Frad LEE"
git config --global user.email "fradser@gmail.com"
git config --global core.excludesfile "$HOME/.gitignore_global"
print_success "Git configured"

# ==========================================
# 5. Node.js via nvm
# ==========================================
print_header "🟢 Node.js (nvm)"
if [[ ! -d "$HOME/.nvm" ]]; then
  print_step "Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

if ! command -v nvm >/dev/null 2>&1; then
  print_error "nvm failed to load"
  exit 1
fi

print_step "Installing Node.js 24..."
nvm install 24 --silent
nvm use 24 --silent
nvm alias default 24
print_success "Node.js $(node -v) ready"

print_step "Enabling pnpm via Corepack..."
corepack enable pnpm
print_success "pnpm $(pnpm -v) enabled"

# ==========================================
# 6. AI Coding Agents
# ==========================================
print_header "🤖 AI Coding Agents"
npm install -g @google/gemini-cli --silent
npm install -g @anthropic-ai/claude-code --silent
npm install -g @openai/codex --silent
print_success "AI agents installed"

# ==========================================
# 7. Bun
# ==========================================
print_header "🍞 Bun"
if ! command -v bun >/dev/null 2>&1; then
  print_step "Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
  print_success "Bun installed"
else
  print_success "Bun $(bun --version) found"
fi

# ==========================================
# 8. uv (Python)
# ==========================================
print_header "⚡ uv (Python)"
if ! command -v uv >/dev/null 2>&1; then
  print_step "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  print_success "uv installed"
else
  print_success "uv $(uv --version) found"
fi

# ==========================================
# 9. Ghostty Config
# ==========================================
print_header "👻 Ghostty"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GHOSTTY_CONFIG_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
if [[ -f "$SCRIPT_DIR/ghostty_config" ]]; then
  mkdir -p "$GHOSTTY_CONFIG_DIR"
  cp "$SCRIPT_DIR/ghostty_config" "$GHOSTTY_CONFIG_DIR/config"
  print_success "Ghostty config synced"
else
  print_info "ghostty_config not found, skipping"
fi

# ==========================================
# Done
# ==========================================
echo -e "\n${GREEN}${BOLD}🎉 Bootstrap complete.${NC}"
echo -e "${YELLOW}Run ${BOLD}source ~/.zshrc${NC}${YELLOW} or restart your terminal to apply changes.${NC}\n"
