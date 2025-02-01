
# This file is the User-wide .bashrc file for interactive bash(1) shells.
# Author: alessandro candolini
# Email: alessandro.candolini@gmail.com

# =============================================================================
# INIT
# =============================================================================
# Set home variable if not already defined
if [ -z $HOME ]; then
  export HOME=~
fi

# Set UTF-8 support
if [ -z $LC_ALL ]; then
  export LC_ALL="en_US.UTF-8"
fi

# Load system-wise bashrc (if existing)
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

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

# Git editor default to vim
# https://git-scm.com/docs/git-var#Documentation/git-var.txt-GITEDITOR
export GIT_EDITOR="nvim -u NONE"

# =============================================================================
# SAFE ALIAS
# =============================================================================

alias rm='/bin/rm -i -v'
alias cp='/bin/cp -i -v'
alias mv='/bin/mv -i -v'
alias mkdir='/bin/mkdir -v'
alias ls='/bin/ls -GFh'
alias rg='rg --hidden'

# =============================================================================
# NODE/NPM (local installation)
# =============================================================================
# TODO fix / move to nix?
export NPM_PACKAGES=$HOME/.npm-packages
export NODE_PATH=$NPM_PACKAGES/lib/node_modules:$NODE_PATH
export NODE_MODULES=$HOME/node-modules
export PATH=$NPM_PACKAGES/bin:$NODE_MODULES/.bin:$PATH

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
if [ -f $HOME/.git-completion.bash ]; then
   source $HOME/.git-completion.bash
fi

if command -v gh &>/dev/null; then
  eval "$(gh completion -s bash)"
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

# add /usr/local/bin to path (used by brew system-wise installation)
export PATH=/usr/local/bin:$PATH

# add $HOME/bin to path (for local-wise installation purposes)
export PATH=$HOME/bin:$PATH

# haskell stack local (TODO cleanup)
export PATH=$HOME/.local/bin:$PATH

# =============================================================================
# NIX added by Nix installer
# =============================================================================
function sourceAllIfExist {
  local -r arr=$1
  for i in "${arr[@]}"; do
    if [ -e $i ]; then
      echo $i
      source $i
    fi
  done
}

nixfiles=(
  "$HOME/.nix-profile/etc/profile.d/nix.sh"
  "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
)
sourceAllIfExist nixfiles

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
  # git diff using fzf with preview
  gd() {
    git diff $@ --name-only | fzf -m --ansi --preview 'git diff $@ --color=always -- {-1}'
  }
fi


# =============================================================================
# Starship
# =============================================================================

if command -v starship >/dev/null; then
  eval "$(starship init bash)"
fi

export C_INCLUDE_PATH="$(xcrun --show-sdk-path)/usr/include"
export LDFLAGS="-L/opt/homebrew/opt/zlib/lib"
export CPPFLAGS="-I$(xcrun --show-sdk-path)/usr/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/zlib/lib/pkgconfig"

[ -f "/Users/alessandrocandolini/.ghcup/env" ] && source "/Users/alessandrocandolini/.ghcup/env" # ghcup-env
[ -f ~/.fzf.bash ] && source ~/.fzf.bash


export PATH=/Applications/IntelliJ\ IDEA\ CE.app/Contents/MacOS:$PATH


# Nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
# End Nix
#
export PATH="$PATH:/Users/alessandrocandolini/Library/Application Support/Coursier/bin"
# =============================================================================
# Colima
# =============================================================================

export DOCKER_HOST="unix://$HOME/.colima/docker.sock"
