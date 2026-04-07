#!/bin/zsh

# ──────────────────────────────────────────────
# ~/.zshrc  —  managed by dotfiles
# symlink: ~/.zshrc -> ~/dotfiles/zsh/.zshrc
# ──────────────────────────────────────────────

# ── Performance: skip compinit on insecure dirs ──
ZSH_DISABLE_COMPFIX=true

# ── History ───────────────────────────────────

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt HIST_IGNORE_DUPS       # don't record duplicate adjacent entries
setopt HIST_IGNORE_ALL_DUPS   # remove older duplicate entries
setopt HIST_FIND_NO_DUPS      # don't show dupes when searching
setopt HIST_IGNORE_SPACE      # don't record commands prefixed with a space
setopt HIST_SAVE_NO_DUPS      # don't write dupes to history file
setopt SHARE_HISTORY          # share history across all sessions in real time
setopt APPEND_HISTORY         # append rather than overwrite
setopt EXTENDED_HISTORY       # record timestamp of command

# ── Directory navigation ──────────────────────

setopt AUTO_CD                # cd by typing directory name alone
setopt AUTO_PUSHD             # make cd push old dir onto the dir stack
setopt PUSHD_IGNORE_DUPS      # no duplicates in the dir stack
setopt PUSHD_SILENT           # no output when navigating dir stack

# ── Completion ────────────────────────────────

setopt COMPLETE_IN_WORD       # complete from both ends of a word
setopt ALWAYS_TO_END          # move cursor to end on completion
setopt PATH_DIRS              # perform path search even on command names with slashes
setopt AUTO_MENU              # show completion menu on tab
setopt AUTO_LIST              # list choices on ambiguous completion
setopt AUTO_PARAM_SLASH       # add trailing slash when completing directory

# ── Misc ──────────────────────────────────────

setopt INTERACTIVE_COMMENTS   # allow comments in interactive shell
setopt NO_BEEP                # no terminal bell
setopt COMBINING_CHARS        # handle combining unicode characters

# ── zinit bootstrap ───────────────────────────

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# ── Plugins ───────────────────────────────────

# Additional completions (load early so compinit sees them)
zinit ice wait lucid blockf atpull"zinit creinstall -q ."
zinit light zsh-users/zsh-completions

# History substring search — bind keys in atload so the widget exists first
zinit ice wait lucid atload"
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
"
zinit light zsh-users/zsh-history-substring-search

# Autosuggestions — bind accept keys in atload so the widget exists first
zinit ice wait lucid atload"
  _zsh_autosuggest_start
  bindkey '^ ' autosuggest-accept
  bindkey -M viins '^[[C' autosuggest-accept
"
zinit light zsh-users/zsh-autosuggestions

# fzf-tab: replace zsh's default completion with fzf
zinit ice wait lucid
zinit light Aloxaf/fzf-tab

# Syntax highlighting — must be last so it wraps all other widgets
zinit ice wait lucid atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay"
zinit light zdharma-continuum/fast-syntax-highlighting

# ── fzf ───────────────────────────────────────

# Set up fzf key bindings and fuzzy completion (if fzf is installed)
if [[ -f "${HOME}/.fzf.zsh" ]]; then
  source "${HOME}/.fzf.zsh"
elif command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# fzf defaults: use fd for file finding, show hidden files, ignore .git
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --info=inline
  --preview-window=right:60%:wrap
'
export FZF_CTRL_T_OPTS='
  --preview "bat --color=always --style=numbers --line-range=:200 {}"
'
export FZF_ALT_C_OPTS='
  --preview "eza --tree --color=always --icons {} | head -100"
'

# ── zoxide ────────────────────────────────────

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# ── Vi mode ───────────────────────────────────

bindkey -v

# Reduce key timeout (makes mode switching snappier, default is 400ms)
export KEYTIMEOUT=1

# Cursor shape: block in normal mode, beam in insert mode
_set_cursor_beam()  { printf '\e[6 q'; }
_set_cursor_block() { printf '\e[2 q'; }

zle-keymap-select() {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
    _set_cursor_block
  else
    _set_cursor_beam
  fi
}
zle-line-init() { _set_cursor_beam; }

zle -N zle-keymap-select
zle -N zle-line-init

# Make backspace work properly after returning from normal mode
bindkey -v '^?' backward-delete-char
bindkey -v '^H' backward-delete-char

# Ctrl+L to clear screen in insert mode
bindkey '^L' clear-screen

# Edit current command in $EDITOR (Ctrl+E or 'v' in normal mode)
autoload -z edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line
bindkey '^e' edit-command-line

# ── Completion system ─────────────────────────

autoload -Uz compinit
compinit -C

# Case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Coloured completion menu
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'

# fzf-tab: preview files with bat, directories with eza
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always --icons $realpath 2>/dev/null | head -100'
zstyle ':fzf-tab:complete:*' fzf-preview 'bat --color=always --style=plain $realpath 2>/dev/null | head -100'

# Group matches and describe
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' group-name ''

# ── Autosuggestions config ────────────────────

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=true

# (accept keybindings are set in the plugin's atload hook above)

# ── PATH extras ───────────────────────────────

# VS Code CLI
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# PostgreSQL 16 (Homebrew)
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# OpenCode
export PATH="$HOME/.opencode/bin:$PATH"

# ── NVM (Node Version Manager) ────────────────

export NVM_DIR="$HOME/.nvm"
# Lazy-load nvm: only initialise on first use of node/npm/nvm/npx
_nvm_lazy_load() {
  unset -f nvm node npm npx yarn pnpm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm()  { _nvm_lazy_load; nvm "$@"; }
node() { _nvm_lazy_load; node "$@"; }
npm()  { _nvm_lazy_load; npm "$@"; }
npx()  { _nvm_lazy_load; npx "$@"; }
yarn() { _nvm_lazy_load; yarn "$@"; }
pnpm() { _nvm_lazy_load; pnpm "$@"; }

# ── Aliases: navigation ───────────────────────

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# ── Aliases: ls -> eza ────────────────────────

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza --icons --group-directories-first -l --git'
  alias la='eza --icons --group-directories-first -la --git'
  alias lt='eza --icons --tree --level=2'
  alias lta='eza --icons --tree --level=2 -a'
else
  alias ls='ls --color=auto'
  alias ll='ls -lh'
  alias la='ls -lah'
fi

# ── Aliases: cat -> bat ───────────────────────

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias bcat='bat'
fi

# ── Aliases: git ──────────────────────────────

alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gdc='git diff --cached'
alias gl='git log --oneline --graph --decorate'
alias gla='git log --oneline --graph --decorate --all'
alias gb='git branch'
alias gba='git branch -a'
alias grb='git rebase'
alias gst='git stash'
alias gstp='git stash pop'

# ── Aliases: misc ─────────────────────────────

alias q='exit'
alias clr='clear'
alias reload='source ~/.zshrc'
alias dotfiles='cd ~/dotfiles'
alias zshrc='${EDITOR:-nvim} ~/dotfiles/zsh/.zshrc'
alias vimrc='${EDITOR:-nvim} ~/dotfiles/nvim/nvim/lua/'

# Human-readable sizes by default
alias df='df -h'
alias du='du -h'
alias free='free -h' 2>/dev/null || true  # Linux only

# Safer defaults
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'

# ── Functions ─────────────────────────────────

# mkcd: create a directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1" || return 1
}

# fcd: fuzzy-find a directory and cd into it (requires fzf + fd)
fcd() {
  local dir
  dir="$(fd --type d --hidden --follow --exclude .git "${1:-.}" | fzf --preview 'eza --tree --color=always --icons {} | head -50')" \
    && cd "$dir" || return 1
}

# fkill: fuzzy kill a process
fkill() {
  local pid
  pid="$(ps -eo pid,comm,args | fzf --header='Select process to kill' | awk '{print $1}')"
  if [[ -n "$pid" ]]; then
    echo "Killing PID $pid"
    kill -9 "$pid"
  fi
}

# up: go up N directories
up() {
  local n="${1:-1}"
  local path=""
  for (( i=0; i<n; i++ )); do
    path="../$path"
  done
  cd "$path" || return 1
}

# ── Editor ────────────────────────────────────

export EDITOR='nvim'
export VISUAL='nvim'

# ── Starship prompt ───────────────────────────

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# bun completions
[ -s "/Users/admin/.bun/_bun" ] && source "/Users/admin/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
