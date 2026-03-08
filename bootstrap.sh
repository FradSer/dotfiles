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

echo -e "${CYAN}${BOLD}🚀 Starting environment bootstrap...${NC}\n"

# 1. Install Homebrew if not present
print_step "🍺 Checking Homebrew..."
if ! command -v brew >/dev/null; then
  print_info "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  print_success "🍺 Homebrew already installed"
  echo
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
  echo
  print_success "📦 Brew packages synced"
else
  print_error "🚫 Brewfile not found at $BREWFILE_PATH"
  exit 1
fi

# 3. Git configuration
print_header "🔧 Configuring Git"
git config --global user.name "Frad LEE"
git config --global user.email "fradser@gmail.com"
print_success "🔧 Git configured (Frad LEE <fradser@gmail.com>)"
echo

# 4. Node.js & Corepack (pnpm setup)
print_header "🟢 Setting up Node.js & AI Agents"
print_step "🟢 Checking Node.js..."
if command -v node >/dev/null; then
  print_success "🟢 Node.js $(node --version) found"
  echo

  print_step "📦 Updating Corepack..."
  npm install --global corepack@latest --silent
  corepack enable pnpm
  print_success "📦 pnpm enabled via Corepack"
  echo

  # Install AI Coding Agents
  print_step "🤖 Installing AI coding agents..."
  
  print_info "📦 Installing @google/gemini-cli..."
  npm install -g @google/gemini-cli --silent
  
  print_info "📦 Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code --silent
  
  print_info "📦 Installing OpenAI Codex..."
  npm install -g @openai/codex --silent
  
  print_success "🤖 AI agents installed"
else
  print_info "🟢 Node.js not found, skipping AI agents setup."
fi

# 5. Chezmoi Dotfiles Sync
print_header "📁 Syncing Dotfiles"
if command -v chezmoi >/dev/null; then
  if [ ! -d "$HOME/.local/share/chezmoi/.git" ]; then
    print_step "📁 Initializing chezmoi from fradser/dotfiles..."
    chezmoi init https://github.com/fradser/dotfiles.git --quiet
  fi
  chezmoi apply --force
  echo
  print_success "📁 Dotfiles synced"
else
  print_info "📁 Chezmoi not found, skipping dotfiles sync."
fi

# 6. Sync Ghostty config
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GHOSTTY_CONFIG_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
if [ -f "$SCRIPT_DIR/ghostty_config" ]; then
  print_step "👻 Syncing Ghostty config..."
  mkdir -p "$GHOSTTY_CONFIG_DIR"
  cp "$SCRIPT_DIR/ghostty_config" "$GHOSTTY_CONFIG_DIR/config"
  echo
  print_success "👻 Ghostty config synced to $GHOSTTY_CONFIG_DIR/config"
else
  print_info "👻 ghostty_config not found at $SCRIPT_DIR/ghostty_config, skipping."
fi

# 7. Source zsh config
print_header "⚙️ Applying Configuration"
print_step "⚙️ Sourcing zsh configuration..."
if [ -f "$HOME/.zshrc" ]; then
  source "$HOME/.zshrc"
  echo
  print_success "⚙️ zshrc sourced"
else
  print_info "⚙️ .zshrc not found"
fi

echo -e "\n${GREEN}${BOLD}🎉 Bootstrap complete!${NC}"
echo -e "${YELLOW}To apply changes in current shell, run: ${BOLD}source ~/.zshrc${NC}"
echo -e "${YELLOW}Or restart your terminal (Ghostty).${NC}\n"