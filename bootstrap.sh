#!/bin/zsh

# ==========================================
# Bootstrap Script for macOS Development
# ==========================================

set -e # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_header() {
  echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}${BOLD}$1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_step() {
  echo -e "${YELLOW}${BOLD}$1${NC}"
}

print_success() {
  echo -e "${GREEN}${BOLD}$1${NC}"
}

print_error() {
  echo -e "${RED}${BOLD}$1${NC}"
}

print_info() {
  echo -e "${BLUE}${BOLD}$1${NC}"
}

echo -e "${CYAN}${BOLD}🚀 Starting environment bootstrap...${NC}"

# 1. Install Homebrew if not present
print_step "🍺 Checking Homebrew..."
if ! command -v brew >/dev/null; then
  print_info "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  print_success "🍺 Homebrew already installed"
fi

# Setup brew environment (works for both Intel and Apple Silicon)
if [ -f "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Verify brew is available
if ! command -v brew >/dev/null; then
  print_error "🚫 Homebrew installation failed or not found in PATH"
  exit 1
fi

# 2. Sync Brew Tools
print_header "📦 Installing Homebrew Packages"
BREWFILE_PATH="$(dirname "$0")/Brewfile"
if [ -f "$BREWFILE_PATH" ]; then
  # Use --quiet to keep output clean
  script -q /dev/null brew bundle --file="$BREWFILE_PATH"
  print_success "📦 Brew packages synced"
else
  print_error "🚫 Brewfile not found at $BREWFILE_PATH"
  exit 1
fi

# 3. Workspace Setup
print_header "🏗️ Setting up Workspace"
print_step "🏗️ Creating Developer directories..."
mkdir -p "$HOME/Developer/FradSer"
print_success "🏗️ $HOME/Developer/FradSer created"

# 4. Git configuration
print_header "🔧 Configuring Git"
git config --global user.name "Frad LEE"
git config --global user.email "fradser@gmail.com"
git config --global core.excludesfile ~/.gitignore_global
print_success "🔧 Git configured (Frad LEE <fradser@gmail.com>)"

# 5. Node.js & Corepack (nvm setup)
print_header "🟢 Setting up Node.js (via nvm) & AI Agents"
print_step "🟢 Checking nvm..."
if [ ! -d "$HOME/.nvm" ]; then
  print_info "🟢 Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
fi

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

print_step "🟢 Installing Node.js 24..."
nvm install 24 --silent
nvm use 24 --silent
nvm alias default 24
print_success "🟢 Node.js $(node -v) installed via nvm"

print_step "📦 Enabling pnpm via Corepack..."
corepack enable pnpm
print_success "📦 pnpm $(pnpm -v) enabled"

# Install AI Coding Agents
print_step "🤖 Installing AI coding agents..."

print_info "📦 Installing @google/gemini-cli..."
npm install -g @google/gemini-cli --silent

print_info "📦 Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code --silent

print_info "📦 Installing OpenAI Codex..."
npm install -g @openai/codex --silent

print_success "🤖 AI agents installed"

# 6. Bun Runtime Setup
print_header "🍞 Setting up Bun"
print_step "🍞 Checking Bun..."
if ! command -v bun >/dev/null; then
  print_info "🍞 Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  print_success "🍞 Bun installed"
else
  print_success "🍞 Bun $(bun --version) found"
fi

# 7. uv (Python manager) Setup
print_header "⚡ Setting up uv"
print_step "⚡ Checking uv..."
if ! command -v uv >/dev/null; then
  print_info "⚡ Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  print_success "⚡ uv installed"
else
  print_success "⚡ uv $(uv --version) found"
fi

# 8. Chezmoi Dotfiles Sync
print_header "📁 Syncing Dotfiles"
if command -v chezmoi >/dev/null; then
  if [ ! -d "$HOME/.local/share/chezmoi/.git" ]; then
    print_step "📁 Initializing chezmoi from FradSer/dotfiles..."
    chezmoi init git@github.com:FradSer/dotfiles.git --quiet
  fi
  chezmoi apply --force
  print_success "📁 Dotfiles synced"

  # Reminder for non-synced secrets file
  SECRETS_FILE="$HOME/.config/zsh/.secret"
  if [ ! -f "$SECRETS_FILE" ]; then
    mkdir -p "$(dirname "$SECRETS_FILE")"
    touch "$SECRETS_FILE"
    print_info "⚠️  Created empty $SECRETS_FILE. Please sync your secrets manually."
  fi
else
  print_info "📁 Chezmoi not found, skipping dotfiles sync."
fi

# 9. Sync Ghostty config
print_header "👻 Syncing Ghostty config"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GHOSTTY_CONFIG_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
if [ -f "$SCRIPT_DIR/ghostty_config" ]; then
  print_step "👻 Syncing Ghostty config..."
  mkdir -p "$GHOSTTY_CONFIG_DIR"
  cp "$SCRIPT_DIR/ghostty_config" "$GHOSTTY_CONFIG_DIR/config"
  print_success "👻 Ghostty config synced to $GHOSTTY_CONFIG_DIR/config"
else
  print_info "👻 ghostty_config not found at $SCRIPT_DIR/ghostty_config, skipping."
fi

# 10. Source zsh config
print_header "⚙️ Applying Configuration"
print_step "⚙️ Sourcing zsh configuration..."
if [ -f "$HOME/.zshrc" ]; then
  source "$HOME/.zshrc"
  print_success "⚙️ zshrc sourced"
else
  print_info "⚙️ .zshrc not found"
fi

echo -e "\n${GREEN}${BOLD}🎉 Bootstrap complete!${NC}"
echo -e "${YELLOW}To apply changes in current shell, run: ${BOLD}source ~/.zshrc${NC}"
echo -e "${YELLOW}Or restart your terminal (Ghostty).${NC}\n"