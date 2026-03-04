TASKS=bash stow alacritty gitconfig nvim nix starship tmux stack agda rg cargo
VERBOSITY=1
FLAGS=--restow --no-folding --verbose $(VERBOSITY) --target ~

.PHONY: all $(TASKS) nvim-test

all: $(TASKS)

$(TASKS):
	stow $(FLAGS) $@

nvim-test:
	@if [ -z "$$IN_NIX_SHELL" ]; then \
		nix develop ./nvim-tests#default -c $(MAKE) nvim-test; \
	else \
		yes | nvim --headless -u nvim-tests/minimal_init.lua +qa!; \
		nvim --headless -u nvim-tests/minimal_init.lua -l nvim-tests/run.lua; \
	fi
