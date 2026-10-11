# Frad's Dotfiles ![](https://img.shields.io/badge/macOS-Dotfiles-blue)

[![chezmoi](https://img.shields.io/badge/managed%20with-chezmoi-purple)](https://www.chezmoi.io/) [![Zsh](https://img.shields.io/badge/shell-zsh-orange)](https://www.zsh.org/)

[English](README.md) | **简体中文**

个人 macOS dotfiles，使用 chezmoi 管理 Zsh、Ghostty、Starship 和 AI CLI 配置。

## 安装

运行前请检查 [bootstrap.sh](bootstrap.sh) 和 [Brewfile](Brewfile)。脚本会应用托管文件、修改全局 Git 身份与忽略规则，并配置 GPG。请备份现有 shell 和应用设置；在其他人的机器上使用前，先修改脚本中的作者 Git 身份。

在新 Mac 上初始化源仓库，暂不应用配置：

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init https://github.com/FradSer/dotfiles.git
```

使用 chezmoi 默认源目录时：

```bash
cd "$HOME/.local/share/chezmoi"
zsh bootstrap.sh
```

引导脚本会：

1. 检查 Xcode Command Line Tools，缺失时提示安装。
2. 在缺失时安装 Homebrew，并执行 Brewfile。
3. 初始化并应用 dotfiles，按需创建空的本机 secrets 文件，并创建开发工作目录。
4. 设置全局 Git 身份与忽略规则，配置 pinentry-mac，并重启 gpg-agent。
5. 通过 fnm 配置 Node.js LTS，通过 Corepack 启用 pnpm；在缺失时安装 Bun 和 uv。
6. 尝试安装 amp、opencode、Claude Code、Gemini CLI 和 Codex。这些代理工具的安装失败不会阻止后续步骤，请检查输出，不要假定所有 CLI 都已安装。

Brewfile 包含 Go、Rust、fnm、Python、shell 插件、Git 工具，以及 Ghostty、Cursor、Zed 等 GUI 应用。Qwen 有 shell 包装函数，但没有引导安装步骤。AI 工具的认证需另行完成。安装结束后请打开新终端。

## 托管文件

chezmoi 将 `dot_` 映射为文件名前的点，并移除 `executable_` 前缀、设置可执行权限。配置均为静态文件，不使用 chezmoi 模板。

| 源文件 | 目标位置或用途 |
| --- | --- |
| `dot_zshenv`, `dot_zprofile`, `dot_zshrc` | `~/.zshenv`, `~/.zprofile`, `~/.zshrc` |
| `dot_config/zsh/rc.d/` | `~/.config/zsh/rc.d/`，按顺序加载的 shell 模块 |
| `dot_config/zsh/completions/` | Claude 与 provider 管理命令的补全 |
| `dot_config/zsh/executable_claude-provider.py` | `~/.config/zsh/claude-provider.py`，provider 解析与执行 |
| `dot_config/zsh/dot_claude-providers.toml` | `~/.config/zsh/.claude-providers.toml`，provider 定义 |
| `dot_config/ghostty/config` | `~/.config/ghostty/config` |
| `dot_config/starship.toml` | `~/.config/starship.toml` |
| `dot_claude/settings.json` | `~/.claude/settings.json` |
| `dot_claude/executable_statusline.sh`, `dot_claude/statusline.d/` | Claude 状态栏及目录、用量辅助脚本 |
| `dot_claude/CLAUDE.md`, `dot_codex/AGENTS.md` | 用户级 Claude 和 Codex 指引 |
| `dot_gitignore_global` | `~/.gitignore_global` |
| `Brewfile`, `bootstrap.sh`, `tests/` | 仓库内的安装与验证文件，不部署到 HOME |

[.chezmoiignore](.chezmoiignore) 还将根目录 README、本机 secrets、本机 Zsh 覆盖配置、项目记忆和 Git-agent 元数据排除在部署范围之外。

## Zsh

`.zshenv` 保存通用变量，`.zprofile` 配置登录 shell 的工具路径。`.zshrc` 依次加载 secrets、可选工具环境、编号模块，最后加载 `~/.zshrc.local`。

| 模块 | 用途 |
| --- | --- |
| `00-init.zsh` | 检测 Homebrew 路径，初始化可选 evalcache、Starship 和每个 shell 独立的 fnm 环境 |
| `05-compinit.zsh` | 补全路径与缓存、匹配规则，在 compinit 后加载本机 Bun 补全 |
| `10-ai-claude.zsh` | Claude 包装函数与 provider 管理入口 |
| `11-ai-others.zsh` | Codex、Gemini 和 Qwen 包装函数 |
| `20-settings.zsh` | 历史记录、目录搜索路径和颜色设置 |
| `25-fzf.zsh` | 文件与内容搜索、Git 选择器和进程选择 |
| `30-aliases.zsh` | Git 别名、目录快捷方式、secrets 编辑与 shell 重启 |
| `40-functions.zsh` | 路径复制、归档解压、Finder 导航和文件辅助函数 |
| `80-keybindings.zsh` | sudo 切换、剪贴板组件、任务控制和命令行编辑 |
| `90-plugins.zsh` | 自动建议、fzf-tab、autopair、you-should-use、历史搜索和语法高亮 |
| `95-tips.zsh` | 按需执行的 `terminal-tip` 命令 |
| `99-zoxide.zsh` | 最后初始化 zoxide |

缺失的可选插件会被跳过。生成的 `~/.bun/_bun` 文件由 Bun 管理；chezmoi 只管理加载入口，文件不可读或为空时跳过。提示不会自动输出，但 evalcache 首次创建缓存时可能显示消息。

### 命令与快捷键

- `reload` 替换当前 shell，并保留登录模式；不会保留 shell 本地状态或任务记录。不要反复 source `.zshrc`。
- `esecret` 打开本机 secrets 文件。未继承其他设置时，`EDITOR` 默认为 `cot`。Brewfile 不安装 CotEditor，请单独安装或选择其他编辑器。GUI 编辑器用于命令行编辑时需要等待参数。
- Ctrl-R 搜索历史；Ctrl-T 选择文件；Alt-C 通过 fzf 选择目录。
- Esc-Esc 切换 sudo 前缀；Ctrl-O 复制命令缓冲区，为空时复制时间戳；Ctrl-X Ctrl-E 使用 Zsh 标准命令行编辑器。
- `fif` 搜索文件内容。`fgb` 切换本地分支；选择远程分支时，以 detached HEAD 模式检出准确的远程引用。
- `fgl` 用完整提交 ID 预览和打开提交，不从说明文字中猜测 hash。可传历史筛选条件和版本范围，不要传 `--graph`、`--oneline`、`--format` 等输出格式选项。
- `fkill` 默认发送 TERM。需要强制终止时显式使用 `fkill 9`。

## AI 包装函数与 provider

包装函数默认不会添加权限绕过参数。单独托管的 Claude 设置使用权限模式 `auto`，并配置了权限允许列表；应用前请检查 [dot_claude/settings.json](dot_claude/settings.json)。

Codex、Gemini 和 Qwen 只识别第一个参数位置的 `--yolo`。Claude 识别命令开头连续的 `--provider NAME` 和 `--yolo`，遇到第一个原生参数后停止解析包装选项。因此，`claude --system-prompt --yolo` 会原样传递提示词值，不启用权限绕过。`--` 也会结束包装选项解析。

Claude 前置包装选项和 provider 管理需要带有 `tomllib` 的 Python 3.11+，由 Brewfile 提供。以原生参数开头的调用，以及无参数调用，不需要 Python 工具或有效的 provider 文件。

```bash
claude-provider list
claude-provider show cliproxyapi-qwen
claude-provider edit
claude --provider cliproxyapi-qwen
```

`cpf` 是 `claude-provider` 的别名。Provider 需要显式选择，不会自动故障转移。旧的 `claude --NAME` 语法、provider TUI 和 add/remove 子命令已移除；请通过编辑器增删 TOML 配置段。

- 使用 `token_var` 指定已导出的凭证变量名，不支持内联 `key` 字段。
- URL、模型和额外参数值支持 `$VAR` 与 `${VAR}` 展开，不执行 shell 命令。额外参数仅限 Python 工具允许的 Claude 调优变量，展开后的空格保持为普通数据。
- 选中的 provider 使用隔离的子进程环境，并清除其他云后端选择开关。凭证从导出的环境中读取，不通过 shell 局部变量解析。
- 编辑器依次取自 `VISUAL`、`EDITOR`、`vi`。静态验证通过后才会原子替换文件；编辑模板时不要求提供 secrets。执行前再检查展开后的 URL 和凭证是否可用。
- `claude-provider edit` 只修改目标文件。请执行其输出的 `chezmoi add` 命令，将改动收回源仓库，避免被之后的 apply 覆盖。

使用 CLI Proxy API provider 时，请在本机配置 `CLIPROXYAPI_HOST`、`CLIPROXYAPI_HOST_PORT` 和 `CLIPROXYAPI_TOKEN`。Claude URL 使用不带 `/v1` 的主机与端口；兼容 OpenAI 的客户端使用带 `/v1` 的 base URL。除非所有客户端都应使用该代理，否则不要全局导出代理的 OpenAI 凭证。

## 其他配置

- Ghostty 使用 Maple Mono NF CN、随系统切换的明暗主题、半透明背景、顶部快速终端、Zsh 集成和命令完成通知。
- Starship 为 Git 和语言模块配置 Nerd Font 符号。
- Claude 设置选择 `sonnet`、启用自动记忆，并引用外部插件市场。仓库不包含这些插件的实现；当前启用的插件和权限以设置文件为准。
- Claude 状态栏显示模型、仓库或 worktree 路径、Git 状态及可用的用量数据。它需要 `jq`，但 Brewfile 未显式声明该依赖。官方用量查询可能使用 macOS Keychain 凭证；OpenCode 辅助脚本可以使用 CodexBarCLI 的浏览器会话或本机数据库估算。仓库不安装 CodexBar。
- Claude 的一个 Stop hook 引用了 `~/.claude/consolidate-memory.sh`，仓库不提供该脚本。使用前请在本机提供脚本，或移除该 hook。

状态栏需要时可安装：

```bash
brew install jq
```

## 本机配置与 secrets

凭证放在不受管理的 `~/.config/zsh/.secret` 中，不要写入 provider TOML 或版本控制文件。以下命令不会覆盖已有文件：

```bash
mkdir -p "$HOME/.config/zsh"
touch "$HOME/.config/zsh/.secret"
chmod 600 "$HOME/.config/zsh/.secret"
```

使用编辑器填写需要导出的凭证。最终的机器专属覆盖设置放在 `~/.zshrc.local`。已有的 `~/.local/bin/env` 和 `~/.config/event-sync/env.sh` 会在模块之前加载；它们是可选文件，不由本仓库提供。

## 验证

在仓库根目录运行，需要 Zsh 和 Python 3.11+：

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_*.py'
zsh -f tests/claude-provider.zsh
zsh -f tests/utilities.zsh
uvx ty check dot_config/zsh/executable_claude-provider.py
```

回归测试使用临时测试文件和模拟命令，不调用真实 AI 服务或使用真实凭证。BDD 场景位于 `tests/features/`；语法检查命令见 [tests/README.md](tests/README.md)。可选的类型检查通过 uv 的 `uvx` 执行，可能下载 `ty`。

`tests/cliproxy-environment.zsh` 是单独的工作站集成检查，会加载真实 secrets 文件并检查托管 provider 定义。不要将它加入无人值守的回归测试。

## 更新

先预览，再应用。配置差异可能包含私密值，未经检查不要分享：

```bash
chezmoi diff
chezmoi apply
```

通过 chezmoi 编辑托管文件：

```bash
chezmoi edit ~/.zshrc
```

拉取远程源仓库并应用：

```bash
chezmoi update
```

更新包装函数时，应一起应用 Zsh 入口文件、模块、补全和 Python 工具，然后打开新终端。源仓库的改动不会立即影响已运行的 shell，需先应用并重新加载。
