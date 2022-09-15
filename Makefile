TASKS=bash stow alacritty gitconfig neovim nix starship tmux vim  vim-config
VERBOSITY=1
FLAGS=--no-folding --verbose $(VERBOSITY) --target ~

.PHONY: all $(TASKS) 

all: $(TASKS)

$(TASKS):
	stow $(FLAGS) $@
