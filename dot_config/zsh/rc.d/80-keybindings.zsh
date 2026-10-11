# ==========================================
# Key Bindings
# ==========================================

# --- sudo plugin: Esc-Esc toggles sudo prefix ---
_sudo_toggle() {
  if [[ $BUFFER = sudo\ * ]]; then
    BUFFER="${BUFFER#sudo }"
    CURSOR=$(( CURSOR > 5 ? CURSOR - 5 : 0 ))
  elif [[ -n $BUFFER ]]; then
    BUFFER="sudo $BUFFER"
    CURSOR=$(( CURSOR + 5 ))
  fi
}
zle -N _sudo_toggle
bindkey -M emacs '^[^[' _sudo_toggle
bindkey -M viins '^[^[' _sudo_toggle

# --- copybuffer: Ctrl-O smart copy ---
# Buffer has content → copy buffer to clipboard
# Buffer is empty   → copy current timestamp to clipboard
_copybuffer() {
  local content="${BUFFER:-$(date '+%Y-%m-%d %H:%M:%S')}"
  print -rn -- "$content" </dev/null | pbcopy || return $?
  zle -M "已复制到剪贴板"
}
zle -N _copybuffer
bindkey -M emacs '^O' _copybuffer
bindkey -M viins '^O' _copybuffer

# --- fancy-ctrl-z: Ctrl-Z toggles between foreground job and shell ---
_fancy_ctrl_z() {
  if [[ $#BUFFER -eq 0 ]]; then
    BUFFER="fg"
    zle accept-line -w
  else
    zle push-input -w
    zle clear-screen -w
  fi
}
zle -N _fancy_ctrl_z
bindkey -M emacs '^Z' _fancy_ctrl_z
bindkey -M viins '^Z' _fancy_ctrl_z

# --- Edit command line in $EDITOR: Ctrl-X Ctrl-E ---
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M emacs '^X^E' edit-command-line
bindkey -M viins '^X^E' edit-command-line

# --- Esc-l: run ls ---
_run_ls() {
  zle -M "$(ls -1)"
}
zle -N _run_ls
bindkey -M emacs '^[l' _run_ls
bindkey -M viins '^[l' _run_ls
