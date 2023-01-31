if [ -f ~/.bashrc ]; then
	source ~/.bashrc
fi

if [ -f ~/.proxyrc ]; then
	source ~/.proxyrc
fi

export SBT_CREDENTIALS="$HOME/.sbt/.credentials"
export COURSER_CREDENTIALS="$HOME/.sbt/.credentials"
eval "$(/opt/homebrew/bin/brew shellenv)"
