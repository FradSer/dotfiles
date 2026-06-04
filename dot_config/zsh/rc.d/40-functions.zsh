# ==========================================
# Utility Functions
# ==========================================

# mkcd: mkdir + cd in one step
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# copypath: copy absolute path to clipboard
copypath() {
  local path="${1:-$PWD}"
  print -rn "$path" | pbcopy
  print -P "%F{green}Copied to clipboard:%f $path"
}

# take: download, extract, and cd into an archive
take() {
  local url="$1"
  local tmpdir="$(mktemp -d)"
  local filename="$(basename "$url")"
  cd "$tmpdir" || return 1
  print -P "%F{cyan}Downloading %f$url%f..."
  curl -fsSL -o "$filename" "$url" || { print -P "%F{red}Download failed%f"; return 1 }
  # Try common extraction commands
  case "$filename" in
    *.tar.gz|*.tgz)   tar xzf "$filename" ;;
    *.tar.bz2|*.tbz2) tar xjf "$filename" ;;
    *.tar.xz|*.txz)   tar xJf "$filename" ;;
    *.tar)             tar xf "$filename"  ;;
    *.zip)             unzip "$filename"   ;;
    *.gz)              gunzip "$filename"  ;;
    *.bz2)             bunzip2 "$filename" ;;
    *.7z)              7z x "$filename"    ;;
    *)                 print -P "%F{red}Unknown archive format: %f$filename"; return 1 ;;
  esac
  # cd into the extracted directory if there's exactly one
  local extracted=(*/(N))
  if (( ${#extracted} == 1 )); then
    cd "${extracted[1]}" || return 1
  fi
  print -P "%F{green}Ready in %f$PWD"
}

# zsh_stats: show most frequently used commands
zsh_stats() {
  fc -l 1 | awk '{ print $2 }' | sort | uniq -c | sort -rn | head -20 | \
    awk -v total="$(fc -l 1 | wc -l)" '{ printf "%6d  %4.1f%%  %s\n", $1, 100*$1/total, $2 }'
}

# cdf: cd to the directory currently shown in Finder (macOS)
cdf() {
  local target
  target="$(osascript -e 'tell application "Finder" to return POSIX path of (target of front window as alias)' 2>/dev/null)"
  if [[ -n "$target" ]]; then
    cd "$target"
  else
    print -P "%F{red}No Finder window open%f"
  fi
}

# quick-look: trigger macOS Quick Look from terminal
quick-look() {
  qlmanage -p "$@" &>/dev/null
}

# rmdsstore: clean .DS_Store files recursively
rmdsstore() {
  find "${1:-.}" -name '.DS_Store' -print -delete
}

# Permission helpers
set644() { find "${1:-.}" -type f -exec chmod 644 {} + }
set755() { find "${1:-.}" -type d -exec chmod 755 {} + }
