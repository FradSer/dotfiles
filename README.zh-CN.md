# Frad's Dotfiles ![](https://img.shields.io/badge/macOS-Dotfiles-blue)

[![CI Status](https://img.shields.io/badge/CI-chezmoi-purple)](https://github.com/FradSer/dotfiles) [![Shell](https://img.shields.io/badge/Shell-Zsh-orange)](https://www.zsh.org/) [![Terminal](https://img.shields.io/badge/Terminal-Ghostty-black)](https://ghostty.org/)

**English** | [简体中文](README.zh-CN.md)

----

# Frad 的 Dotfiles

我个人的 macOS 开发环境配置，使用 [chezmoi](https://www.chezmoi.io/) 管理。

## 🚨 重要警告

**此脚本会重置你的终端和 Shell 配置！**

运行前请务必：
1. 备份现有配置：`~/.zshrc`、`~/.zshenv`、`~/.gitconfig`、`~/.config/ghostty/`
2. 理解此脚本的作用（请查看上方的 `bootstrap.sh` 和目录结构）
3. **我不承担任何后果和责任**

---

## 🚀 快速上手（新 Mac 配置）

借助 [chezmoi](https://chezmoi.io/)，只需两条命令即可启动一台全新的空机器。

**1. 初始化并应用配置**
使用 chezmoi 官方的一行命令下载二进制文件、克隆本仓库并应用配置文件：
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply FradSer
```

**2. 运行引导脚本**
现在仓库已克隆到你的机器上，运行安装脚本来安装 Homebrew、工具、运行时和 AI 代理：
```bash
~/.local/share/chezmoi/bootstrap.sh
```

*(注意：`chezmoi init` 默认使用 HTTPS。可在生成 SSH 密钥后将 remote 改为 SSH 方式。)*

### `bootstrap.sh` 执行内容：
1. 安装 **Homebrew**
2. 通过 **Brewfile** 安装核心工具、运行时和应用程序
3. 配置全局 **Git** 设置
4. 设置 **Node.js**（通过 `fnm`），启用 `pnpm`，安装 **AI 代理**
5. 安装 **Bun** 和 **uv**（Python 包管理器）
6. 配置 **Ghostty** 终端

## 🧰 技术栈与工具

- **Shell**: Zsh（模块化配置，Homebrew 插件）
- **终端**: [Ghostty](https://ghostty.org/)（Maple Mono NF CN）
- **提示符**: [Starship](https://starship.rs/)（nerd font，多语言）
- **运行时**: Node.js (fnm)、Go、Rust、Bun、Python (uv)
- **编辑器**: Cursor / Zed
- **AI 工具**: Claude Code、 Gemini CLI、OpenAI Codex
- **核心 CLI 工具**:
  - `zoxide`（智能 `cd`）
  - `eza`（现代 `ls`）
  - `bat`（现代 `cat`）
  - `fzf` + `fd` + `ripgrep`（模糊搜索）
  - `lazygit`（Git TUI）

## ⌨️ 快捷命令

```bash
chezmoi apply        # 应用配置到 $HOME
chezmoi update      # 拉取最新并应用
chezmoi diff        # 预览变更
chezmoi edit ~/.zshrc  # 编辑托管文件
```

## 📁 目录结构

```text
.
├── bin/
│   └── chezmoi                    # chezmoi 二进制（自托管）
├── bootstrap.sh                   # 环境安装脚本
├── Brewfile                       # Homebrew 依赖
├── dot_zshrc                      # Zsh 入口
├── dot_zshenv                     # Zsh 环境变量
├── dot_zprofile                   # Zsh 登录设置
├── dot_gitignore_global           # 全局 git 忽略
├── dot_config/
│   ├── ghostty/config             # Ghostty 终端配置
│   ├── starship.toml              # Starship 提示符配置
│   └── zsh/
│       ├── completions/           # Zsh 补全脚本
│       ├── rc.d/                  # Zsh 初始化脚本（数字顺序）
│       │   ├── 00-init.zsh          # 工具初始化
│       │   ├── 05-compinit.zsh      # Zsh 补全
│       │   ├── 10-ai-claude.zsh     # Claude 封装与 provider 配置
│       │   ├── 11-ai-others.zsh     # Codex / Gemini / Qwen 封装
│       │   ├── 20-settings.zsh      # Zsh 选项
│       │   ├── 25-fzf.zsh           # fzf 键绑定
│       │   ├── 30-aliases.zsh       # Git 别名
│       │   ├── 90-plugins.zsh       # 插件加载
│       │   ├── 95-tips.zsh          # 终端提示
│       │   └── 99-zoxide.zsh        # zoxide 初始化
│       └── .claude-providers.toml  # 30+ Claude API 提供商
└── dot_claude/
    ├── settings.json              # Claude Code 设置和插件
    └── executable_statusline.sh   # 自定义状态栏
```

## 🔧 配置亮点

### Zsh 模块化设置
加载顺序：`dot_zshrc` → `dot_config/zsh/rc.d/*.zsh` (00-99)

| 脚本 | 用途 |
|---------|---------|
| `00-init.zsh` | evalcache, starship, fnm |
| `10-ai-claude.zsh` | Claude 封装 + provider TOML 加载 + 补全 |
| `11-ai-others.zsh` | Codex / Gemini / Qwen CLI 封装 |
| `20-settings.zsh` | Zsh 选项（历史、补全）|
| `25-fzf.zsh` | fzf 键绑定和预览 |
| `30-aliases.zsh` | Git 别名、系统快捷键 |
| `90-plugins.zsh` | zsh-autosuggestions, syntax-highlighting |
| `99-zoxide.zsh` | 智能 `cd` 集成 |

### Claude Code
- 自定义状态栏（显示模型、目录、git 分支）
- 30+ 备用 API 提供商（`.claude-providers.toml`）
- 插件：context7、exa-mcp-server、git、gitflow、github、review、refactor、impeccable、superpowers、code-context 等
- 自动记忆已启用；默认模型为 `opus`

### 终端（Ghostty）
- 字体：Maple Mono NF CN
- 主题：system（自动 light/dark）
- 与 starship 提示符集成

## 🔒 敏感信息管理

敏感信息已排除。请手动创建 `~/.config/zsh/.secret`：

```zsh
# ~/.config/zsh/.secret
export GITHUB_TOKEN="your_token"
export ANTHROPIC_API_KEY="your_token"
```

## 🤖 AI 集成

深度优化 AI 辅助开发：

- [Claude Code](https://github.com/anthropics/claude-code) - 自定义状态栏
- [Cursor](https://cursor.sh/) - 主要编辑器
- Gemini CLI - Google AI
- OpenAI Codex - CLI 编程助手

### 已启用的 Claude 插件
- context7 — 库文档查询
- exa-mcp-server — 网页搜索和代码示例
- git、gitflow、github — git 工作流自动化
- impeccable — UI/UX 优化
- superpowers — 高级 Agent 工作流
- code-context — 代码库研究
- skill-creator、acpx、claude-md-management — 实用工具

## 🔄 更新

拉取最新更改并应用：

```bash
chezmoi update
```
