# History configuration
export HISTFILE=~/.zsh-history
export HISTSIZE=100000
export SAVEHIST=100000
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS

export AUTO_NOTIFY_THRESHOLD=40
export AUTO_NOTIFY_EXPIRE_TIME=5000

# SSH agent socket
if [[ -z "$SSH_AUTH_SOCK" && -n "$XDG_RUNTIME_DIR" ]]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
fi

# Leave Tab key unbound in deja so fzf / native completion handles Tab
export DEJA_CYCLE_KEY=""

# fzf-tab styling
zstyle ':fzf-tab:*' use-fzf-default-opts yes

function zvm_after_init() {
  eval "$(fzf --zsh)"
}
zvm_after_init_commands+=('eval "$(fzf --zsh)"')

# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

zmodload zsh/complist
zsh-defer compinit
_comp_options+=(globdots)		# Include hidden files.

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

function pochuj {
  nix why-depends /run/current-system nixpkgs#${1}
}

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'underline' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[3 q'
  fi
}

zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[3 q"
}
zle -N zle-line-init
echo -ne '\e[3 q' # Use underline shape cursor on startup.
preexec() { echo -ne '\e[3 q' ;} # Use underline shape cursor for each new prompt.
