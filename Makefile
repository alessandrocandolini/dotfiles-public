TASKS=bash stow alacritty gitconfig nvim nix starship tmux vim stack agda rg
VERBOSITY=1
FLAGS=--no-folding --verbose $(VERBOSITY) --target ~

.PHONY: all $(TASKS) 

all: $(TASKS)

$(TASKS):
	stow $(FLAGS) $@
