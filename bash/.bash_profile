if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi
if command -v brew >/dev/null; then
  eval "$(brew shellenv)"
fi
