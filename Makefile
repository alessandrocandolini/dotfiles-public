TASKS=bash stow alacritty gitconfig nvim nix starship tmux vim stack agda rg cargo
VERBOSITY=1
FLAGS=--restow --no-folding --verbose $(VERBOSITY) --target ~

.PHONY: all $(TASKS) 

all: $(TASKS)

$(TASKS):
	stow $(FLAGS) $@
