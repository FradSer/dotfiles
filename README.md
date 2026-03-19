# Frad's Dotfiles ![](https://img.shields.io/badge/macOS-Dotfiles-blue)

[![CI Status](https://img.shields.io/badge/CI-chezmoi-purple)](https://github.com/FradSer/dotfiles) [![Shell](https://img.shields.io/badge/Shell-Zsh-orange)](https://www.zsh.org/) [![Terminal](https://img.shields.io/badge/Terminal-Ghostty-black)](https://ghostty.org/)

**English** | [简体中文](README.zh-CN.md)

----

# Frad's Dotfiles

My personal macOS development environment configuration managed with [chezmoi](https://www.chezmoi.io/).

## 🚨 Important Warning

**🚨 This script will reset your terminal and shell configuration!**

Before running, please:
1. Backup your existing configs: `~/.zshrc`, `~/.zshenv`, `~/.gitconfig`, `~/.config/ghostty/`
2. Understand what this script does (review `bootstrap.sh` and the directory structure above)
3. I am not responsible for any data loss or configuration issues

---

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
4. Sets up **Node.js** (via `fnm`), enables `pnpm`, and installs **AI agents** (Gemini, Claude Code, Codex)
5. Installs **Bun** and **uv** (Python manager)
6. Configures **Ghostty** terminal

## 🧰 Tech Stack & Tools

- **Shell**: Zsh (modular config, Homebrew plugins)
- **Terminal**: [Ghostty](https://ghostty.org/) (Maple Mono NF CN)
- **Prompt**: [Starship](https://starship.rs/) (nerd font, multi-language)
- **Runtimes**: Node.js (fnm), Go, Rust, Bun, Python (uv)
- **Editor**: Cursor / Zed
- **AI Tools**: Claude Code, Gemini CLI, OpenAI Codex
- **Core CLI Tools**:
  - `zoxide` (smart `cd`)
  - `eza` (modern `ls`)
  - `bat` (modern `cat`)
  - `fzf` + `fd` + `ripgrep` (fuzzy search)
  - `lazygit` (Git TUI)

## ⌨️ Quick Reference

```bash
chezmoi apply        # Apply dotfiles to $HOME
chezmoi update      # Pull latest & apply
chezmoi diff        # Preview changes
chezmoi edit ~/.zshrc  # Edit a managed file
```

## 📁 Directory Structure

```text
.
├── bin/
│   └── chezmoi               # chezmoi binary (self-managed)
├── bootstrap.sh              # Environment setup script
├── Brewfile                  # Homebrew dependencies
├── dot_zshrc                 # Zsh entry point
├── dot_zshenv                # Zsh environment variables
├── dot_zprofile              # Zsh login settings
├── dot_gitignore_global      # Global git ignores
├── dot_config/
│   ├── ghostty/config        # Ghostty terminal config
│   ├── starship.toml         # Starship prompt config
│   └── zsh/
│       ├── completions/      # Zsh completion scripts
│       ├── rc.d/             # Zsh initialization scripts (numeric order)
│       │   ├── 00-init.zsh          # Tool init: evalcache, starship, fnm
│       │   ├── 05-compinit.zsh      # Zsh completion
│       │   ├── 10-ai-functions.zsh  # AI shell functions
│       │   ├── 20-settings.zsh      # Zsh options
│       │   ├── 25-fzf.zsh           # fzf keybindings
│       │   ├── 30-aliases.zsh       # Git & system aliases
│       │   ├── 90-plugins.zsh       # Plugin loading
│       │   ├── 95-tips.zsh          # Shell tips
│       │   └── 99-zoxide.zsh        # zoxide init
│       └── .claude-providers.toml  # 30+ Claude API providers
└── dot_claude/
    ├── settings.json              # Claude Code settings & plugins
    └── executable_statusline.sh   # Custom status line
```

## 🔧 Configuration Highlights

### Zsh Modular Setup
Load order: `dot_zshrc` → `dot_config/zsh/rc.d/*.zsh` (00-99)

| Script | Purpose |
|--------|---------|
| `00-init.zsh` | evalcache, starship, fnm |
| `10-ai-functions.zsh` | Gemini, Claude, Codex CLI wrappers |
| `20-settings.zsh` | Zsh options (hist, completion) |
| `25-fzf.zsh` | fzf keybindings & preview |
| `30-aliases.zsh` | Git aliases, system shortcuts |
| `90-plugins.zsh` | zsh-autosuggestions, syntax-highlighting |
| `99-zoxide.zsh` | Smart `cd` integration |

### Claude Code
- Custom statusline showing model, directory, git branch
- 30+ alternative API providers configured in `.claude-providers.toml`
- Plugins: context7, exa-mcp-server, git, gitflow, github, review, refactor, impeccable, superpowers, code-context, and more
- Auto memory enabled; model defaults to `haiku`

### Terminal (Ghostty)
- Font: Maple Mono NF CN
- Theme: system (auto light/dark)
- Integrates with starship prompt

## 🔒 Secrets Management

Sensitive information (API keys, tokens) is excluded from this repository.
Create `~/.config/zsh/.secret` manually to store your private environment variables:

```zsh
# ~/.config/zsh/.secret
export GITHUB_TOKEN="your_token"
export ANTHROPIC_API_KEY="your_token"
```

## 🤖 AI Integration

Heavily optimized for AI-assisted development:

- [Claude Code](https://github.com/anthropics/claude-code) - custom statusline (model, dir, git branch)
- [Cursor](https://cursor.sh/) - primary editor
- Gemini CLI - Google AI
- OpenAI Codex - CLI coding assistant

### Claude Plugins Enabled
- context7 — library documentation lookup
- exa-mcp-server — web search & code examples
- git, gitflow, github — git workflow automation
- review, refactor — code quality
- impeccable — UI/UX polish
- superpowers — advanced agent workflows
- code-context — codebase research
- skill-creator, ralph-loop, acpx, claude-md-management — utilities

## 🔄 Updating

To pull the latest changes and apply them:

```bash
chezmoi update
```
