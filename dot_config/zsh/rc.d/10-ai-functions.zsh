# ==========================================
# AI CLI Functions - Direct Source
# ==========================================

# Source the main file directly. The definitions of typeset -A and functions
# take less than 1ms. What was slow in the original version was doing complex
# logic or calling external binaries during load.
source "$HOME/.config/zsh/10-ai-functions.zsh"
