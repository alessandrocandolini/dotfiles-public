if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi
