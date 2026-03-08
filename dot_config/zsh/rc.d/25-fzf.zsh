# ==========================================
# FZF Configuration - Nerd Font Pro Edition
# ==========================================

# 1. 初始化 fzf 的 Zsh 补全和快捷键绑定
# Cache fzf init (regenerate with: fzf --zsh > ~/.config/zsh/.fzf.zsh)
if [[ -f "$HOME/.config/zsh/.fzf.zsh" ]]; then
  source "$HOME/.config/zsh/.fzf.zsh"
else
  source <(fzf --zsh)
fi

# 2. 统一色彩与 UI 规则 (Unified Nerd Font Palette)
export FZF_DEFAULT_OPTS="--height 50% --layout=reverse --border --ansi \
  --prompt='󰭎 ' --pointer='󰁔 ' --marker='󰄬 ' \
  --color=fg:-1,bg:-1,hl:cyan,fg+:white,bg+:black,hl+:cyan \
  --color=info:yellow,prompt:cyan,pointer:green,marker:yellow,spinner:green,header:cyan"

# 3. CTRL-T (搜索文件)：列表显示图标，结果返回纯路径
# 我们先用 fd 找出文件，再交给 eza 渲染图标
export FZF_CTRL_T_COMMAND='fd --type f --hidden --exclude .git --color=always'
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"

# 4. ALT-C (搜索目录)：列表显示图标，结果返回纯路径
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git --color=always'
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {}'"

# --- 5. 进阶功能函数 (全部适配 Nerd Font) ---

# 全局实时内容搜索 (Find In Files)
fif() {
  if [ ! "$#" -gt 0 ]; then return; fi
  rg --files-with-matches --no-messages "$1" | fzf --prompt='󰈞 ' --preview "rg --ignore-case --pretty --context 10 '$1' {}"
}

# 交互式 Git 分支切换
fgb() {
  local branches branch
  branches=$(git branch --all | grep -v 'HEAD') &&
  branch=$(echo "$branches" | fzf --prompt='󱔎 ' --height 50% --layout=reverse --border --preview "git log --oneline --graph --date=short --color=always --pretty='format:%C(auto)%h %C(magenta)%ad %C(cyan)%an %Creset%s' {1} | head -n 20") &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# 交互式 Git Log 查看
fgl() {
  git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --prompt='󰊚 ' --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF" \
      --preview "grep -o '[a-f0-9]\{7\}' <<< {} | xargs git show --color=always"
}

# 交互式杀进程
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf --prompt='󰆙 ' -m | awk '{print $2}')
  if [ "x$pid" != "x" ]; then
    echo $pid | xargs kill -${1:-9}
  fi
}
