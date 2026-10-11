# ==========================================
# FZF Configuration - Nerd Font Pro Edition
# ==========================================

# 1. 初始化 fzf 的 Zsh 补全和快捷键绑定（.zshrc 必然交互，无需额外判断）
if type fzf &>/dev/null; then
  if (( $+functions[_evalcache] )); then
    _evalcache fzf --zsh
  else
    eval "$(fzf --zsh)"
  fi
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
  local -x FIF_QUERY="$1"
  rg --files-with-matches --no-messages -- "$FIF_QUERY" |
    fzf --preview 'rg --ignore-case --pretty --context 10 -- "$FIF_QUERY" {}'
}

# 交互式 Git 分支切换
fgb() {
  local branch ref
  branch=$(git for-each-ref --format='%(symref)%09%(refname)%09%(refname:short)' refs/heads refs/remotes |
    awk -F '\t' '$1 == "" { print $2 "\t" $3 }' |
    fzf --delimiter=$'\t' --with-nth=2 --height 50% --layout=reverse --border \
      --preview 'git log --oneline --graph --color=always -n 20 {1} --') || return
  [[ -n $branch ]] || return
  ref=${branch%%$'\t'*}
  if [[ $ref == refs/heads/* ]]; then
    git switch -- "${ref#refs/heads/}"
  else
    git checkout --detach "$ref"
  fi
}

# 交互式 Git Log 查看
fgl() {
  git log --color=always --format='%H%x09%C(auto)%h%d %s %C(black)%C(bold)%cr' "$@" |
    fzf --delimiter=$'\t' --with-nth=2.. --ansi --no-sort --reverse --tiebreak=index \
      --bind=ctrl-s:toggle-sort \
      --bind 'ctrl-m:execute:git show --color=always {1} | less -R' \
      --preview 'git show --color=always {1}'
}

# 交互式杀进程
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf --prompt='󰆙 ' -m | awk '{print $2}')
  if [ "x$pid" != "x" ]; then
    echo $pid | xargs kill -${1:-TERM}
  fi
}
