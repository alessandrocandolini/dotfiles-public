
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
# DO not export: https://unix.stackexchange.com/questions/247585/to-export-or-not-to-export-bash-ps1-variable
PS1="\h:\W \u\$ "

# Remove sound
bind 'set bell-style none'

# Set CLICOLOR if you want Ansi Colors in iTerm2
export CLICOLOR=1

# Set colors to match iTerm2 Terminal Colors
export TERM=xterm-256color
# =============================================================================
# SAFE ALIAS
# =============================================================================

alias rm='/bin/rm -i -v'
alias cp='/bin/cp -i -v'
alias mv='/bin/mv -i -v'
alias mkdir='/bin/mkdir -v'
alias ls='/bin/ls -GFh'

# use coreutils on MAC OS as date (to have unix compatibility)
if [ -x "$(command -v gdate)" ]; then
  alias date='gdate'
fi

# Make nvim default
#if [ -x "$(command -v nvim)" ]; then
#  alias vim='nvim'
#fi

# =============================================================================
# JAVA
# =============================================================================

# set JDK installation dir
# on MAC, set it dynamically by relying on /usr/libexec/java_home
# otherwise (or for faster .bashrc load) provide a default location (if any)

# export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk1.8.0_181.jdk/Contents/Home"
if [ -f /usr/libexec/java_home ]; then
	export JAVA_HOME=$(/usr/libexec/java_home)
else
	export JAVA_HOME=""
fi

# if $JAVA_HOME is NOT empty, add $JAVA_HOME/bin to $PATH
if [[ ! -z $JAVA_HOME && -d $JAVA_HOME ]]; then
	export PATH=$JAVA_HOME/bin:$PATH
fi


# =============================================================================
# ANDROID
# =============================================================================

# set Android SDK path (default android studio one when installing AS)
# see https://developer.android.com/studio/command-line/variables
export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk

# if ANDROID_SDK_ROOT variable is NOT empty and the folder exist, add its relevant subfolders to $PATH
if [[ ! -z $ANDROID_SDK_ROOT && -d $ANDROID_SDK_ROOT ]]; then
  export PATH=$ANDROID_SDK_ROOT/tools:$PATH
  export PATH=$ANDROID_SDK_ROOT/platform-tools:$PATH
  export PATH=$ANDROID_SDK_ROOT/tools/bin:$PATH
  export PATH=$ANDROID_SDK_ROOT/platform-tools/systrace/catapult/systrace/bin:$PATH
  export PATH=$ANDROID_SDK_ROOT/tools/proguard/bin/:$PATH

  # additional variable pointing as well to android sdk home (deprecated)
  export ANDROID_HOME=$ANDROID_SDK_ROOT
fi
# =============================================================================
# NODE/NPM (local installation)
# =============================================================================
# TODO fix / move to nix?
export NPM_PACKAGES=$HOME/.npm-packages
export NODE_PATH=$NPM_PACKAGES/lib/node_modules:$NODE_PATH
export NODE_MODULES=$HOME/node-modules
export PATH=$NPM_PACKAGES/bin:$NODE_MODULES/.bin:$PATH

# =============================================================================
# GEM local folder (ruby)
# =============================================================================
if [ -d $HOME/Local/ruby ]; then
  export GEM_HOME=$HOME/Local/ruby
  export PATH=$GEM_HOME/bin:$PATH
fi

# =============================================================================
# LaTeX 2e
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
# CSV (in my old machine i'm still using csv instead of git for oldcprojects)
# =============================================================================

# set CSV repository folder
if [ -d $HOME/cvsroot ]; then
  export CVSROOT=$HOME/cvsroot
fi

# =============================================================================
# GIT
# =============================================================================
# !! This section is slow, particularly the bash-git-prompt

# git autocompletion
# Source: wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -O .git-completion.bash
if [ -f $HOME/.git-completion.bash ]; then
   source $HOME/.git-completion.bash
fi

# Git-prompt-bash
# Source: https://github.com/magicmonty/bash-git-prompt
# git clone https://github.com/magicmonty/bash-git-prompt.git .bash-git-prompt --depth=1

if [ -d $HOME/.bash-git-prompt ]; then
  GIT_PROMPT_ONLY_IN_REPO=1
  GIT_PROMPT_SHOW_UPSTREAM=0
  GIT_PROMPT_FETCH_REMOTE_STATUS=0
  GIT_PROMPT_THEME=Default
  source $HOME/.bash-git-prompt/gitprompt.sh
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
# NVM
# =============================================================================
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# =============================================================================
# PATH
# =============================================================================

# Local path (TODO: is this used at all?)
export LOCAL=$HOME/local
export PATH=$LOCAL:$LOCAL/bin:$LOCAL/install/bin:$LOCAL/lib/python/:$PATH

# conscript (eg, used for g8, don't use homebrew for g8 http://www.foundweekends.org/giter8/setup.html )
if [ -d $HOME/.conscript ]; then
  export PATH=$HOME/.conscript/bin:$PATH
fi

# curl brew on macos (if it exists)
if [ -d /usr/local/opt/curl/bin ]; then
  export PATH=/usr/local/opt/curl/bin:$PATH
fi

# add /usr/local/bin to path (used by brew system-wise installation)
export PATH=/usr/local/bin:$PATH

# add $HOME/bin to path (for local-wise installation purposes)
export PATH=$HOME/bin:$PATH

# haskell stack local (TODO cleanup)
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.ghcup/bin/:$PATH
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# =============================================================================
# ENVS (ruby, java)
# =============================================================================
# Slow to load, so i move these to functions

initRbenv() {
  if [ -x "$(command -v rbenv)" ]; then
    eval "$(rbenv init -)"
  fi
}

initJenv() {
  [[ -s "${HOME}/.jenv/bin/jenv-init.sh" ]] && source "${HOME}/.jenv/bin/jenv-init.sh" && source "${HOME}/.jenv/commands/completion.sh"
}

# =============================================================================
# NIX added by Nix installer
# =============================================================================
if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then
  source $HOME/.nix-profile/etc/profile.d/nix.sh
fi

# =============================================================================
# FZF (fuzzy search in history)
# =============================================================================

if [ -x "$(command -v fzf)"  ];  then
  if [ -f ~/.fzf.bash ]; then
    source ~/.fzf.bash
    if [ -x "$(command -v rg)" ]; then
      export FZF_DEFAULT_COMMAND='rg --files --follow --hidden'
    fi
  fi
fi

# git diff using fzf with preview
if [ -x "$(command -v fzf)"  ];  then
  gd() {
    git diff $@ --name-only | fzf -m --ansi --preview 'git diff $@ --color=always -- {-1}'
  }
fi
