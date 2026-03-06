#!/bin/bash

# ==========================================
# Bootstrap Script for macOS Development
# ==========================================

set -e # Exit on error

echo "Starting environment bootstrap..."

# 1. Install Homebrew if not present
if ! command -v brew >/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Setup brew environment for the current script session
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2. Sync Brew Tools
echo "Syncing tools from Brewfile..."
brew bundle --file=~/.config/zsh/Brewfile

# 3. Node.js & Corepack (pnpm setup)
echo "Setting up pnpm via Corepack..."
if command -v node >/dev/null; then
  # Update Corepack to the latest version as requested
  npm install --global corepack@latest
  # Enable pnpm
  corepack enable pnpm
  echo "pnpm is now managed by Corepack"
else
  echo "Node.js not found, skipping Corepack setup."
fi

# 4. Chezmoi Dotfiles Sync
echo "Syncing dotfiles via Chezmoi..."
if command -v chezmoi >/dev/null; then
  # Check if chezmoi is already initialized
  if [ ! -d "$HOME/.local/share/chezmoi/.git" ]; then
    echo "Initializing chezmoi from fradser/dot_config..."
    chezmoi init https://github.com/fradser/dot_config.git
  fi
  # Apply changes (this will overwrite local files with chezmoi's version)
  chezmoi apply
  echo "Dotfiles synced successfully"
else
  echo "Chezmoi not found, skipping dotfiles sync."
fi

echo "Bootstrap complete! Please restart your terminal (Ghostty)."
