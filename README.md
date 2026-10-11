# Frad's Dotfiles ![](https://img.shields.io/badge/macOS-Dotfiles-blue)

[![chezmoi](https://img.shields.io/badge/managed%20with-chezmoi-purple)](https://www.chezmoi.io/) [![Zsh](https://img.shields.io/badge/shell-zsh-orange)](https://www.zsh.org/)

**English** | [简体中文](README.zh-CN.md)

Personal macOS dotfiles for Zsh, Ghostty, Starship, and AI CLI configuration, managed with chezmoi.

## Setup

Review [bootstrap.sh](bootstrap.sh) and [Brewfile](Brewfile) before running them. The script applies managed files, changes global Git identity and ignores, and configures GPG. Back up existing shell and application settings; adapt the author's Git identity before using this on another person's machine.

On a fresh Mac, initialize the source repository without applying it yet:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init https://github.com/FradSer/dotfiles.git
```

With the default chezmoi source location:

```bash
cd "$HOME/.local/share/chezmoi"
zsh bootstrap.sh
```

The bootstrap script:

1. Checks Xcode Command Line Tools and prompts for installation if needed.
2. Installs Homebrew when missing and runs the Brewfile.
3. Initializes and applies the dotfiles, creates an empty local secrets file if needed, and creates the development workspace.
4. Sets global Git identity and ignores, configures pinentry-mac, and restarts gpg-agent.
5. Sets up Node.js LTS with fnm and pnpm through Corepack; installs Bun and uv when missing.
6. Attempts to install amp, opencode, Claude Code, Gemini CLI, and Codex. These agent installation failures are treated as optional; check the output rather than assuming every CLI was installed.

The Brewfile includes Go, Rust, fnm, Python, shell plugins, Git tools, and GUI apps including Ghostty, Cursor, and Zed. Qwen has a shell wrapper but no bootstrap installation step. Authentication for AI tools is separate from installation. Open a new terminal when setup finishes.

## Managed files

chezmoi maps `dot_` to a leading dot and strips `executable_` while setting executable permissions. Configurations are static, without chezmoi templates.

| Source | Destination or purpose |
| --- | --- |
| `dot_zshenv`, `dot_zprofile`, `dot_zshrc` | `~/.zshenv`, `~/.zprofile`, `~/.zshrc` |
| `dot_config/zsh/rc.d/` | `~/.config/zsh/rc.d/`, ordered shell modules |
| `dot_config/zsh/completions/` | Claude and provider command completion |
| `dot_config/zsh/executable_claude-provider.py` | `~/.config/zsh/claude-provider.py`, provider parsing and execution |
| `dot_config/zsh/dot_claude-providers.toml` | `~/.config/zsh/.claude-providers.toml`, provider definitions |
| `dot_config/ghostty/config` | `~/.config/ghostty/config` |
| `dot_config/starship.toml` | `~/.config/starship.toml` |
| `dot_claude/settings.json` | `~/.claude/settings.json` |
| `dot_claude/executable_statusline.sh`, `dot_claude/statusline.d/` | Claude status line and its directory/usage helpers |
| `dot_claude/CLAUDE.md`, `dot_codex/AGENTS.md` | User-level Claude and Codex guidance |
| `dot_gitignore_global` | `~/.gitignore_global` |
| `Brewfile`, `bootstrap.sh`, `tests/` | Repository-side installation and validation files, not deployed to HOME |

[.chezmoiignore](.chezmoiignore) also excludes the root READMEs, local secrets, local Zsh overrides, project memory, and Git-agent metadata from deployment.

## Zsh

`.zshenv` holds universal variables. `.zprofile` sets login-shell tool paths. `.zshrc` loads secrets, optional tool environments, the numbered modules, and finally `~/.zshrc.local`.

| Module | Purpose |
| --- | --- |
| `00-init.zsh` | Homebrew prefix discovery, optional evalcache, Starship, per-shell fnm initialization |
| `05-compinit.zsh` | Completion paths and cache, matching rules, local Bun completion after compinit |
| `10-ai-claude.zsh` | Claude wrapper and provider-management entry points |
| `11-ai-others.zsh` | Codex, Gemini, and Qwen wrappers |
| `20-settings.zsh` | History, directory search paths, and color settings |
| `25-fzf.zsh` | File/content search, Git pickers, and process selection |
| `30-aliases.zsh` | Git aliases, directory shortcuts, secret editor, and shell restart |
| `40-functions.zsh` | Clipboard paths, archive extraction, Finder navigation, and file helpers |
| `80-keybindings.zsh` | Sudo toggle, clipboard widget, job control, and command-line editing |
| `90-plugins.zsh` | Autosuggestions, fzf-tab, autopair, you-should-use, history search, and highlighting |
| `95-tips.zsh` | Opt-in `terminal-tip` command |
| `99-zoxide.zsh` | Late zoxide initialization |

Missing optional plugins are skipped. Bun owns the generated `~/.bun/_bun` file; chezmoi manages only its loader, which skips unreadable or empty files. Tips do not print automatically, though evalcache may report first-use cache creation.

### Commands and keys

- `reload` replaces the shell while preserving login mode. It does not retain shell-local state or job bookkeeping; avoid repeatedly sourcing `.zshrc`.
- `esecret` opens the local secrets file. `EDITOR` defaults to `cot` unless inherited. CotEditor is not installed by the Brewfile; install it separately or choose another editor. GUI editors need a wait option for command-line editing.
- Ctrl-R searches history; Ctrl-T selects files; Alt-C selects directories through fzf.
- Esc-Esc toggles the sudo prefix; Ctrl-O copies the command buffer, or a timestamp when empty; Ctrl-X Ctrl-E uses Zsh's standard command-line editor.
- `fif` searches file contents. `fgb` switches local branches; a remote selection checks out the exact remote ref in detached HEAD mode.
- `fgl` previews and opens commits using full IDs, not hashes guessed from messages. Pass history filters and revisions, not output-format options such as `--graph`, `--oneline`, or `--format`.
- `fkill` defaults to TERM. Use `fkill 9` explicitly for forced termination.

## AI wrappers and providers

The wrappers do not add permission-bypass flags by default. Claude's separately managed settings use permission mode `auto` and include permission allowances; review [dot_claude/settings.json](dot_claude/settings.json) before applying them.

Codex, Gemini, and Qwen recognize `--yolo` only as the first argument. Claude recognizes a contiguous leading prefix of `--provider NAME` and `--yolo`; the first native argument ends wrapper parsing. Thus `claude --system-prompt --yolo` passes the literal prompt value without enabling bypass. `--` also ends wrapper parsing.

Claude's leading wrapper options and provider management require Python 3.11+ with `tomllib`, supplied by the Brewfile. Native-first calls, and calls with no arguments, do not require the Python helper or a valid provider file.

```bash
claude-provider list
claude-provider show cliproxyapi-qwen
claude-provider edit
claude --provider cliproxyapi-qwen
```

`cpf` aliases `claude-provider`. Provider selection is explicit, not automatic failover. The old `claude --NAME` syntax, provider TUI, and add/remove subcommands are removed; add or delete TOML sections through the editor.

- Use `token_var` to name an exported credential variable. Inline `key` fields are unsupported.
- URL, model, and extra-flag values support `$VAR` and `${VAR}` expansion without shell execution. Extra flags are restricted to the Claude tuning variables allowed by the Python helper; expanded spaces remain literal data.
- Selected providers get an isolated child environment, with competing cloud-backend selectors cleared. Credentials are read from the exported environment, not shell-local variables.
- Editing uses `VISUAL`, then `EDITOR`, then `vi`. Static validation runs before atomic replacement; templates do not require secrets during editing. Expanded URLs and credential availability are checked before execution.
- `claude-provider edit` changes the target file only. Run the printed `chezmoi add` command to persist that change in the source repository before another apply overwrites it.

For CLI Proxy API providers, configure `CLIPROXYAPI_HOST`, `CLIPROXYAPI_HOST_PORT`, and `CLIPROXYAPI_TOKEN` locally. Claude URLs use the host and port without `/v1`; OpenAI-compatible clients use a `/v1` base URL. Do not globally export proxy OpenAI credentials unless every client should use that proxy.

## Other configuration

- Ghostty uses Maple Mono NF CN, system-dependent light/dark themes, a translucent background, a top quick terminal, Zsh integration, and command-finish notifications.
- Starship configures Nerd Font symbols for Git and language modules.
- Claude settings select `sonnet`, enable automatic memory, and reference external plugin marketplaces. The plugin implementations are not bundled here; the settings file is the current reference for enabled plugins and permissions.
- The Claude status line shows model, repository/worktree path, Git state, and available usage data. It requires `jq`, which is not explicitly declared in the Brewfile. Official usage lookup can use macOS Keychain credentials; the OpenCode helper can use CodexBarCLI's browser session or a local database estimate. CodexBar is not installed by this repository.
- A Claude Stop hook references `~/.claude/consolidate-memory.sh`, which is not supplied here. Provide that script locally or remove the hook before use.

If needed for the status line:

```bash
brew install jq
```

## Local configuration and secrets

Keep credentials in the unmanaged `~/.config/zsh/.secret`, not provider TOML or version-controlled files. Create it without overwriting an existing file:

```bash
mkdir -p "$HOME/.config/zsh"
touch "$HOME/.config/zsh/.secret"
chmod 600 "$HOME/.config/zsh/.secret"
```

Enter exported credentials with your editor. Put final machine-specific overrides in `~/.zshrc.local`. Existing `~/.local/bin/env` and `~/.config/event-sync/env.sh` are sourced before modules; those files are optional and not provided here.

## Validation

Run from the repository root with Zsh and Python 3.11+:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_*.py'
zsh -f tests/claude-provider.zsh
zsh -f tests/utilities.zsh
uvx ty check dot_config/zsh/executable_claude-provider.py
```

The regression suites use temporary fixtures and mocked commands, not live AI services or credentials. BDD scenarios are in `tests/features/`; see [tests/README.md](tests/README.md) for syntax checks. The optional typecheck command uses uv's `uvx` and may download `ty`.

`tests/cliproxy-environment.zsh` is a separate workstation integration check that sources the real secrets file and checks managed provider definitions. Do not include it in unattended regression runs.

## Updating

Preview before applying; configuration diffs can contain private values, so do not share them without review:

```bash
chezmoi diff
chezmoi apply
```

Edit a managed file through chezmoi:

```bash
chezmoi edit ~/.zshrc
```

To pull the remote source and apply it:

```bash
chezmoi update
```

Apply the Zsh entry files, modules, completions, and Python helper together when updating the wrapper. Then open a new terminal. Changes in the source repository do not affect an already-running shell until applied and reloaded.
