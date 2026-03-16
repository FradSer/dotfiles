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
# 0. Prerequisites
# ==========================================
print_header "🔧 Prerequisites"

# Check Xcode Command Line Tools
if ! xcode-select -p >/dev/null 2>&1; then
  print_step "Installing Xcode Command Line Tools..."
  xcode-select --install
  print_info "Please click Install in the dialog, then press Enter"
  read -r
  while ! xcode-select -p >/dev/null 2>&1; do
    sleep 2
  done
fi
print_success "Xcode CLT ready"

# Check Rosetta 2 on Apple Silicon
if [[ $(uname -m) == "arm64" ]]; then
  if ! /usr/bin/pgrep -q oahd; then
    print_step "Installing Rosetta 2..."
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license 2>/dev/null || true
    print_success "Rosetta 2 ready"
  else
    print_success "Rosetta 2 already installed"
  fi
fi

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
CHEZMOI_REPO="https://github.com/FradSer/dotfiles.git"
if command -v chezmoi >/dev/null 2>&1; then
  chezmoi init "$CHEZMOI_REPO" --apply
else
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init "$CHEZMOI_REPO" --apply
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
# 6. Node.js via fnm
# ==========================================
print_header "🟢 Node.js (fnm)"
if ! command -v fnm >/dev/null 2>&1; then
  print_error "fnm not found — ensure Brewfile was applied"
  exit 1
fi

eval "$(fnm env --shell zsh)"

print_step "Installing Node.js LTS..."
fnm install --lts
fnm default lts-latest
print_success "Node.js $(node -v) ready"

print_step "Enabling pnpm via Corepack..."
corepack enable pnpm
print_success "pnpm $(pnpm -v) enabled"

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
# 9. AI Coding Agents
# ==========================================
print_header "🤖 AI Coding Agents"

# Claude Code (official installer)
if ! command -v claude >/dev/null 2>&1; then
  print_step "Installing Claude Code..."
  if curl -fsSL https://claude.ai/install.sh | bash 2>/dev/null; then
    print_success "Claude Code installed"
  else
    print_info "Claude Code failed (optional, skipping)"
  fi
else
  print_success "Claude Code found"
fi

# Gemini CLI (npm)
if command -v npm >/dev/null 2>&1; then
  if npm install -g @google/gemini-cli --silent 2>/dev/null; then
    print_success "gemini-cli installed"
  else
    print_info "gemini-cli failed (optional, skipping)"
  fi
fi

# Codex (npm)
if command -v npm >/dev/null 2>&1; then
  if npm install -g @openai/codex --silent 2>/dev/null; then
    print_success "codex installed"
  else
    print_info "codex failed (optional, skipping)"
  fi
fi

# ==========================================
# Done
# ==========================================
echo -e "\n${GREEN}${BOLD}🎉 Bootstrap complete.${NC}"
echo -e "${YELLOW}Run ${BOLD}source ~/.zshrc${NC}${YELLOW} or restart your terminal to apply changes.${NC}\n"
