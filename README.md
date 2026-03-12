# Frad's Dotfiles

My personal macOS development environment configuration managed with [chezmoi](https://www.chezmoi.io/).

## 🚀 Quick Setup (For a fresh Mac)

Thanks to [chezmoi](https://chezmoi.io/), you can bootstrap a completely new, empty machine with just two commands.

**1. Initialize and apply dotfiles**
This uses chezmoi's official one-liner to download the binary, clone this repository, and apply the configuration files:
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply FradSer
```

**2. Run the bootstrap script**
Now that the repository is cloned to your machine, run the setup script to install Homebrew, tools, runtimes, and AI agents:
```bash
~/.local/share/chezmoi/bootstrap.sh
```

*(Note: The `chezmoi init` command uses HTTPS by default. If you plan to push changes back to GitHub later, you may want to update the git remote to SSH inside `~/.local/share/chezmoi` after generating your SSH keys.)*

### What `bootstrap.sh` does:
1. Installs **Homebrew** (if missing)
2. Installs core tools, runtimes, and applications via **Brewfile**
3. Configures global **Git** settings
4. Sets up **Node.js** (via `nvm`), enables `pnpm`, and installs **AI agents** (Gemini, Claude Code, Codex)
5. Installs **Bun** and **uv** (Python manager)
6. Configures **Ghostty** terminal

## 🧰 Tech Stack & Tools

- **Shell**: Zsh (custom configuration, Homebrew-managed plugins)
- **Terminal**: [Ghostty](https://ghostty.org/)
- **Prompt**: [Starship](https://starship.rs/)
- **Runtimes**: Node.js (nvm), Go, Rust, Bun, Python (uv)
- **Editor**: Cursor / Zed
- **Core CLI Tools**:
  - `zoxide` (smart `cd`)
  - `eza` (modern `ls`)
  - `bat` (modern `cat`)
  - `fzf` + `fd` + `ripgrep` (search)
  - `lazygit` (Git TUI)

## 📁 Directory Structure

```text
.
├── bootstrap.sh            # Environment setup script
├── Brewfile                # Homebrew dependencies
├── ghostty_config          # Ghostty terminal config
├── dot_zshrc               # Zsh entry point
├── dot_config/
│   ├── starship.toml       # Starship prompt config
│   └── zsh/                # Modular Zsh configuration
│       ├── rc.d/           # Zsh initialization scripts
│       └── claude-providers.toml # Claude Code models
└── dot_claude/             # Claude Code configuration
```

## 🔒 Secrets Management

Sensitive information (API keys, tokens) is excluded from this repository.
Create `~/.config/zsh/.secret` manually to store your private environment variables:

```zsh
# ~/.config/zsh/.secret
export GITHUB_TOKEN="your_token"
export ANTHROPIC_API_KEY="your_token"
```

## 🤖 AI Integration

This environment is heavily optimized for AI-assisted development, featuring pre-configured setups for:
- [Claude Code](https://github.com/anthropics/claude-code) (with custom statusline)
- [Cursor](https://cursor.sh/) (primary editor)
- Gemini CLI
- OpenAI Codex

## 🔄 Updating

To pull the latest changes and apply them:

```bash
chezmoi update
```
