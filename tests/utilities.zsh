#!/bin/zsh
setopt errexit nounset pipefail
ROOT=${0:A:h:h}
WORK=$(mktemp -d)
WORK=${WORK:A}
trap 'command rm -rf -- "$WORK"' EXIT
export WORK
failures=0
check() {
  if ( "$@" ); then
    print -r -- "PASS $1"
  else
    print -ru2 -- "FAIL $1"
    (( failures += 1 ))
  fi
}
source "$ROOT/dot_config/zsh/rc.d/40-functions.zsh"
copypath_case() {
  pbcopy() { /bin/cat > "$WORK/clipboard"; }
  local original=$PATH
  cd "$WORK"
  copypath 'a file' > /dev/null
  [[ $PATH == "$original" && $(< "$WORK/clipboard") == "$PWD/a file" ]]
}
copypath_failure_case() {
  pbcopy() { /bin/cat > /dev/null; return 19; }
  local result=0
  copypath 'a file' > "$WORK/copy-failure" || result=$?
  [[ $result == 19 && ! -s "$WORK/copy-failure" ]]
}
take_case() {
  mktemp() { print -r -- "$WORK"; }
  curl() { return 0; }
  tar() { return 23; }
  local result=0
  take 'https://example.invalid/test.tar.gz' > "$WORK/take" || result=$?
  [[ $result == 23 && $(< "$WORK/take") != *Ready* ]]
}
fzf() { [[ $1 == --zsh ]] && print 'FZF_INITIALIZED=yes'; }
source "$ROOT/dot_config/zsh/rc.d/25-fzf.zsh" 2>/dev/null || true
init_case() { [[ ${FZF_INITIALIZED:-no} == yes ]]; }
fif_case() {
  rg() { printf '%s\n' "$@" >> "$WORK/rg"; print file; }
  fzf() {
    /bin/cat > /dev/null
    local arg preview
    while (( $# )); do
      arg=$1; shift
      if [[ $arg == --preview ]]; then preview=$1; shift; fi
    done
    preview=${preview//\{\}/file}
    eval "$preview" > /dev/null
  }
  local query='-x '\''; touch "$WORK/injected"; #'
  fif "$query" > /dev/null
  local actual=$(< "$WORK/rg")
  [[ ! -e "$WORK/injected" && $actual == $'--files-with-matches\n--no-messages\n--\n'"$query"$'\n--ignore-case\n--pretty\n--context\n10\n--\n'"$query"$'\nfile' ]]
}
fgb_case() {
  local selected=$1 expected=$2
  git() {
    case $1 in
      for-each-ref)
        printf '\trefs/heads/feature/HEAD-fix\tfeature/HEAD-fix\n'
        printf 'refs/remotes/origin/main\trefs/remotes/origin/HEAD\torigin/HEAD\n'
        printf '\trefs/remotes/origin/release\torigin/release\n'
        printf '\trefs/remotes/upstream/release\tupstream/release\n'
        ;;
      branch) printf '  feature/HEAD-fix\n  remotes/upstream/release\n' ;;
      *) printf '%s\n' "$@" > "$WORK/checkout" ;;
    esac
  }
  fzf() {
    local rows=$(/bin/cat)
    [[ $rows != *refs/remotes/origin/HEAD* ]] || return 1
    print -r -- "$rows" | command grep -F "$selected"
  }
  fgb || return 1
  [[ $(< "$WORK/checkout") == "$expected" ]]
}
fgb_local_case() { fgb_case feature/HEAD-fix $'switch\n--\nfeature/HEAD-fix'; }
fgb_remote_case() { fgb_case upstream/release $'checkout\n--detach\nrefs/remotes/upstream/release'; }
fgl_case() {
  local hash=0123456789abcdef0123456789abcdef01234567
  git() {
    if [[ $1 == log ]]; then
      printf '%s\n' "$@" > "$WORK/log-args"
      printf '%s\tdeadbee $(touch "$WORK/log-injected")\n' "$hash"
    else
      printf '%s\n' "$@" >> "$WORK/show-args"
    fi
  }
  less() { /bin/cat; }
  fzf() {
    local row=$(/bin/cat) preview='' binding='' arg
    while (( $# )); do
      arg=$1; shift
      case $arg in
        --preview) preview=$1; shift ;;
        --bind) [[ $1 == *execute* ]] && binding=$1; shift ;;
      esac
    done
    [[ $preview == *'{1}'* && $binding == *'{1}'* ]] || return 1
    preview=${preview//\{1\}/$hash}
    binding=${binding#*execute:}
    binding=${binding//\{1\}/$hash}
    eval "$preview" || return 1
    eval "$binding"
  }
  fgl --all || return 1
  [[ $(< "$WORK/log-args") == *'%H'* && $(< "$WORK/log-args") == *--all* &&
     $(< "$WORK/show-args") == $'show\n--color=always\n'"$hash"$'\nshow\n--color=always\n'"$hash" &&
     ! -e "$WORK/log-injected" ]]
}
fkill_case() {
  ps() { print 'header'; print 'user 123 command'; }
  fzf() { /bin/cat; }
  xargs() { print -r -- "$*" > "$WORK/kill"; /bin/cat > /dev/null; }
  fkill
  [[ $(< "$WORK/kill") == 'kill -TERM' ]]
}
zle() { print -r -- "$*" >> "$WORK/zle"; }
bindkey() { print -r -- "$*" >> "$WORK/bindkey"; }
source "$ROOT/dot_config/zsh/rc.d/80-keybindings.zsh"
sudo_case() {
  BUFFER=hello CURSOR=2
  _sudo_toggle
  [[ $BUFFER == 'sudo hello' && $CURSOR == 7 ]] || return 1
  _sudo_toggle
  [[ $BUFFER == hello && $CURSOR == 2 ]] || return 1
  BUFFER='sudo hello' CURSOR=1
  _sudo_toggle
  [[ $CURSOR == 0 ]] || return 1
  BUFFER='' CURSOR=0
  _sudo_toggle
  [[ -z $BUFFER && $CURSOR == 0 ]]
}
widgets_case() {
  pbcopy() { /bin/cat > /dev/null; }
  sched() { print called > "$WORK/scheduled"; }
  BUFFER=hello
  _copybuffer
  [[ ! -e "$WORK/scheduled" && $(< "$WORK/zle") == *'-N edit-command-line'* && $(< "$WORK/bindkey") == *'^X^E edit-command-line'* ]]
}
check copypath_case
check copypath_failure_case
check take_case
check init_case
check fif_case
check fgb_local_case
check fgb_remote_case
check fgl_case
check fkill_case
check sudo_case
check widgets_case
(( failures == 0 ))
