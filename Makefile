TASKS=bash stow alacritty gitconfig nvim nix starship tmux stack agda rg cargo codex
VERBOSITY=1
FLAGS=--restow --no-folding --verbose $(VERBOSITY) --target ~

.PHONY: all $(TASKS) nvim-test nvim-test-internal

all: $(TASKS)

$(TASKS):
	stow $(FLAGS) $@

nvim-test:
	nix develop --ignore-environment ./nvim-tests#default -c make nvim-test-internal

nvim-test-internal:
	@if [ -z "$$IN_NIX_SHELL" ]; then \
		echo "nvim-test-internal must run inside nix develop ./nvim-tests#default"; \
		exit 1; \
	fi
	yes | nvim --headless -u nvim-tests/init_test.lua +qa!
	nvim --headless -u nvim-tests/init_test.lua -c "PlenaryBustedDirectory nvim-tests/spec { minimal_init = 'nvim-tests/init_test.lua' }" -c "qa!"
