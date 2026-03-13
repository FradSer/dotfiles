# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A [chezmoi](https://chezmoi.io) dotfiles repository for macOS. Files here are managed by chezmoi and applied to `$HOME`. The `dot_` prefix maps to `.` (e.g., `dot_zshrc` → `~/.zshrc`), and `dot_config/` maps to `~/.config/`.

## Common Commands

```sh
# Apply changes from this repo to the system
chezmoi apply

# Pull latest changes and apply
chezmoi update

# Preview what would change before applying
chezmoi diff

# Edit a managed file (opens in $EDITOR, applies on save)
chezmoi edit ~/.zshrc

# Add a new file to be managed
chezmoi add ~/.some-new-config

# Bootstrap a fresh machine
./bootstrap.sh
```

## Architecture

### File Naming Conventions

- `dot_*` → `.` prefix in `$HOME` (e.g., `dot_gitignore_global` → `~/.gitignore_global`)
- `executable_*` → file is made executable on apply
- No `.tmpl` files — all configs are static (no chezmoi templating in use)
- `.chezmoiignore` excludes only `dot_config/zsh/.secret` (API keys, never committed)

### Zsh Configuration

Modular structure loaded by `dot_zshrc` → `dot_config/zsh/rc.d/` in numeric order:

| File | Purpose |
|------|---------|
| `00-init.zsh` | Tool init: evalcache, starship prompt, fnm (Node.js) |
| `10-ai-functions.zsh` | Shell functions for AI providers (Gemini, Claude, etc.) |
| `20-settings.zsh` | Zsh options and behavior |
| `25-fzf.zsh` | fzf keybindings and preview config |
| `30-aliases.zsh` | Git and system aliases |
| `90-plugins.zsh` | Zsh plugin loading |
| `99-zoxide.zsh` | zoxide (smart `cd`) init |

Secrets (API keys) go in `~/.config/zsh/.secret` — sourced by `dot_zshrc` but excluded from this repo.

### Claude Code Configuration

`dot_claude/` maps to `~/.claude/`:
- `settings.json` — enabled MCP plugins and tool permissions
- `executable_statusline.sh` — custom status line (model, dir, git branch)

`dot_config/zsh/dot_claude-providers.toml` maps to `~/.config/zsh/.claude-providers.toml` — 30+ alternative Claude API provider endpoints with model mappings.

### Key Managed Configs

- `dot_config/starship.toml` — Starship prompt (nerd font, multi-language)
- `ghostty_config` — Ghostty terminal (font: Maple Mono NF CN, theme: system light/dark)
- `dot_gitignore_global` — Global git ignores (macOS, editors, languages)
- `Brewfile` — All Homebrew packages, casks, and taps

### Bootstrap Script

`bootstrap.sh` is idempotent and handles full machine setup: Homebrew → Brewfile → chezmoi init → Git config → fnm + pnpm → AI tools (Claude Code, Gemini CLI, Codex) → Bun → uv.
