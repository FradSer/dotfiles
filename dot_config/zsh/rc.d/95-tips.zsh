# ==========================================
# Terminal Tips - Scanned CLI Mastery
# ==========================================

function _show_terminal_tip() {
  # Display only in interactive shells
  [[ $- != *i* ]] && return

  local -a tips
  
  # --- Core (Always Available) ---
  tips+=(
    "[zsh] 按下 %F{yellow}CTRL-R%f 模糊搜索历史，比按向上键快得多。"
    "[zsh] 输入命令前缀（如 %F{green}ssh%f）后按 %F{yellow}上箭头%f，系统只会在匹配的历史中跳转。"
    "[zsh] 修改配置后，直接输入 %F{green}reload%f 即可让一切设置立即生效。"
  )

  # --- fzf & fzf-tab (Verified Config) ---
  if command -v fzf >/dev/null; then
    tips+=(
      "[fzf] 按下 %F{yellow}CTRL-T%f 搜索当前目录下文件，并将路径粘贴到命令行。"
      "[fzf] 按下 %F{yellow}ALT-C%f 模糊搜索子目录并直接 cd 进去。"
      "[fzf] 输入 %F{green}fkill%f 函数可以让你直接通过搜索进程名来“干掉”程序。"
      "[fzf-tab] 补全 %F{green}git checkout%f 时，使用 %F{yellow},%f 和 %F{yellow}.%f 在分支和标签组间切换。"
      "[fzf-tab] 补全时，fzf 窗口右侧会自动调用 %F{cyan}bat%f 或 %F{cyan}eza%f 进行实时预览。"
    )
  fi

  # --- Modern Rust Tools ---
  if command -v fd >/dev/null; then
    tips+=(
      "[fd] fd 比 find 快得多，且默认忽略 .git 和 .gitignore 中的文件。"
    )
  fi

  if command -v rg >/dev/null; then
    tips+=(
      "[rg] 输入 %F{green}fif <关键字>%f 可在当前所有文件中进行实时内容搜索。"
    )
  fi

  if command -v eza >/dev/null; then
    tips+=(
      "[eza] 您的 %F{green}ls/ll%f 已关联 eza，支持图标、Git 状态显示，并优先排列文件夹。"
      "[eza] 输入 %F{green}tree%f 即可查看带图标和色彩的现代目录树。"
    )
  fi

  if command -v bat >/dev/null; then
    tips+=(
      "[bat] 您的 %F{green}cat%f 已关联 bat，支持代码高亮、行号显示和 Git 修改标记。"
    )
  fi

  if command -v gdu >/dev/null; then
    tips+=(
      "[gdu] 输入 %F{green}gdu%f 快速分析磁盘空间占用，比 du 交互性更好。"
    )
  fi

  if command -v delta >/dev/null; then
    tips+=(
      "[delta] 您的 git diff 推荐配置 delta，它能提供带行号、语法高亮和边框的漂亮 Diff。"
    )
  fi

  # --- AI CLI ---
  if command -v claude >/dev/null; then
    tips+=(
      "[AI] 输入 %F{green}claude --glm%f 或 %F{green}claude --kimi%f 即可快速切换供应商。"
      "[AI] Claude 已开启 %F{cyan}agent-teams%f 实验性功能，适合处理复杂多步任务。"
    )
  fi

  if command -v gemini >/dev/null; then
    tips+=(
      "[AI] 您的 %F{green}gemini%f 命令已默认开启 %F{yellow}--yolo%f 模式。"
    )
  fi

  # --- Git & Other CLIs ---
  if command -v gh >/dev/null; then
    tips+=(
      "[gh] 使用 %F{green}gh pr list%f 查看当前仓库的 PR，或用 %F{green}gh issue status%f 查任务。"
      "[gh] 输入 %F{green}gh repo view --web%f 快速在浏览器中打开当前 GitHub 仓库页面。"
    )
  fi

  if command -v git >/dev/null; then
    tips+=(
      "[Git] 使用 %F{green}fgb%f 交互式切换分支，并实时预览该分支的提交记录。"
      "[Git] 输入 %F{green}fgl%f 开启交互式 Log。选中某个提交即可直接查看代码 Diff。"
      "[Git] 使用 %F{green}gpf%f (push --force-with-lease) 强推更安全。"
    )
  fi

  if command -v pnpm >/dev/null; then
    tips+=(
      "[pnpm] 您的 %F{green}p%f 别名已关联 pnpm，速度极快且节省磁盘空间。"
    )
  fi

  # Randomly pick a tip
  local index=$(( RANDOM % ${#tips[@]} + 1 ))
  
  # Print with some margin and cyan color
  print -P "\n%F{cyan}${tips[$index]}%f"
}

_show_terminal_tip
