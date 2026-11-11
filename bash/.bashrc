
# This file is the User-wide .bashrc file for interactive bash(1) shells.
# Author: alessandro candolini
# Email: alessandro.candolini@gmail.com

# =============================================================================
# INIT
# =============================================================================
# Set home variable if not already defined
if [ -z "$HOME" ]; then
  export HOME=~
fi

# Set UTF-8 support
if [ -z "$LC_ALL" ]; then
  export LC_ALL="en_US.UTF-8"
fi

# Load system-wise bashrc (if existing)
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# macOS updates can replace /etc/bashrc and drop nix-darwin's setup; load nix-darwin's copy directly when that happens
if [ -z "$__NIX_DARWIN_SET_ENVIRONMENT_DONE" ] && [ -e /etc/static/bashrc ]; then
  . /etc/static/bashrc
fi

if [ -f /etc/nix/ca-bundle.pem ]; then
  export NIX_SSL_CERT_FILE=/etc/nix/ca-bundle.pem
fi

# Allow more open files, sockets, and watchers for Neovim and language servers.
ulimit -Sn 8192

# Trim the working directory path (this option is ignored in bash < 4)
PROMPT_DIRTRIM=3

# Bash prompt
# DO not export PS1 when defining it: https://unix.stackexchange.com/questions/247585/to-export-or-not-to-export-bash-ps1-variable
# PS1="\h:\W \u\$ "

# Remove sound
bind 'set bell-style none'

# Use bash as default on MACOS
# https://support.apple.com/en-us/HT208050
export BASH_SILENCE_DEPRECATION_WARNING=1

# Set default editor to nvim for both shell (EDITOR) and Git (GIT_EDITOR)
# https://git-scm.com/docs/git-var#Documentation/git-var.txt-GITEDITOR
export EDITOR="nvim -u NONE -i NONE"
export GIT_EDITOR="$EDITOR"

# =============================================================================
# SAFE ALIAS
# =============================================================================

alias rm='/bin/rm -i -v'
alias cp='/bin/cp -i -v'
alias mv='/bin/mv -i -v'
alias mkdir='/bin/mkdir -v'
alias ls='/bin/ls -GFh'

# https://github.com/openai/codex/issues/14601
alias codex='codex --profile local'

# Rg config
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

# =============================================================================
# LaTeX 2e (for legacy projects, now i use nix)
# =============================================================================
# Rules:
# * The // means that TeX programs will search recursively in that folder
# * The : at the end appends the standard value of TEXINPUTS
# For reference,
# http://tex.stackexchange.com/questions/93712/definition-of-the-texinputs-variable

if [ -d $HOME/canguro ]; then
  declare -x TEXINPUTS=.:$HOME/TeX/inputs:$HOME/canguro//:
  declare -x MFINPUTS=.:$HOME/TeX/inputs:$HOME/canguro//:
  declare -x MPINPUTS=.:$HOME/TeX/inputs:$HOME/canguro//:
  declare -x BSTINPUTS=.:$HOME/TeX/imputs:$HOME/canguro//:
  declare -x BIBINPUTS=.:$HOME/TeX/inputs:$HOME/canguro//:
fi
export TEXMFLOCAL=/usr/local/texlive/texmf-local:$TEXMFLOCAL

# Before 2015, MacTeX created symbolic link /usr/texbin.
# This changed in 2015 because El Capitan does not allow users to write
# into the /usr

file_old=/usr/texbin
file_new=/Library/TeX/texbin
if [[ -L "$file_old" && -d "$file_old" ]]; then
    export PATH=$file_old:$PATH
elif [[ -L "$file_new" && -d "$file_new" ]]; then
    export PATH=$file_new:$PATH
fi
unset file_old
unset file_new

# add local asymotote modules (if any)
if [ -d $HOME/.asy/node-4.0/modyles ]; then
  export ASYMPTOTE_DIR=$HOME/.asy/node-4.0/modules/:$ASYMPTOTE_DIR
  export ASYMPTOTE_HOME=$ASYMPTOTE_DIR
fi

# =============================================================================
# GIT and GH
# =============================================================================

# git autocompletion
# Source: wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -O .git-completion.bash
# curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o .git-completion.bash
if [ -f "$HOME/.git-completion.bash" ]; then
   source "$HOME/.git-completion.bash"
fi

if command -v gh &>/dev/null; then
  eval "$(gh completion -s bash)"
fi

if command -v delta >/dev/null; then
  eval "$(delta --generate-completion bash)"
fi

# =============================================================================
# ETERNAL BASH HISTORY
# =============================================================================

# Undocumented feature which sets the size to "unlimited".
# http://stackoverflow.com/questions/9457233/unlimited-bash-history
HISTFILESIZE=
HISTSIZE=
HISTTIMEFORMAT="[%F %T] "
HISTCONTROL=ignoreboth

# Change the file location because certain bash sessions truncate .bash_history
# file upon close.
# http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
HISTFILE=~/.bash_eternal_history

# Force prompt to write history after every command.
# http://superuser.com/questions/20900/bash-history-loss
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# append to the history file, don't overwrite it
shopt -s histappend

# =============================================================================
# PATH
# =============================================================================

# add $HOME/bin to path (for local-wise installation purposes)
export PATH="$PATH:$HOME/bin"

# haskell stack install installs under $HOME/.local
export PATH="$PATH:$HOME/.local/bin"

# =============================================================================
# NIX added by Nix installer
# =============================================================================
if [ -f "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" ]; then
  source "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
elif [ -f "$HOME/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh" ]; then
  source "$HOME/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh"
elif [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

# =============================================================================
# FZF (fuzzy search in history)
# =============================================================================
if command -v fzf >/dev/null; then
  if command -v fzf-share >/dev/null; then
    source "$(fzf-share)/key-bindings.bash"
    source "$(fzf-share)/completion.bash"
  fi
  if command -v rg > /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --follow --hidden'
  fi
fi

# =============================================================================
# Starship
# =============================================================================
if command -v starship >/dev/null; then
  eval "$(starship init bash)"
fi

# =============================================================================
# Haskell
# =============================================================================
macos_sdk_path=$(/usr/bin/xcrun --show-sdk-path)
export C_INCLUDE_PATH="$macos_sdk_path/usr/include"
export CPPFLAGS="-I$macos_sdk_path/usr/include"
unset macos_sdk_path

if [ -f "$HOME/.ghcup/env" ]; then
   source "$HOME/.ghcup/env"
fi

# More paths
export PATH="$PATH:$HOME/Library/Application Support/Coursier/bin"
export PATH="$PATH:/Applications/IntelliJ IDEA CE.app/Contents/MacOS"

# =============================================================================
# Colima
# =============================================================================
export DOCKER_HOST="unix://$HOME/.colima/docker.sock"

if [ -f "$HOME/.bashrc.local" ]; then
  source "$HOME/.bashrc.local"
fi
