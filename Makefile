TASKS=bash stow alacritty gitconfig nvim nix starship tmux stack agda rg cargo codex
VERBOSITY=1
FLAGS=--restow --no-folding --verbose $(VERBOSITY) --target ~

.PHONY: all $(TASKS) nvim-test

all: $(TASKS)

$(TASKS):
	stow $(FLAGS) $@

nvim-test:
	@set -eu; \
	NVIM_TEST_ROOT="$(CURDIR)/.nvim-test"; \
	NVIM_TEST_XDG_ROOT="$$NVIM_TEST_ROOT/xdg"; \
	NVIM_TEST_XDG_DATA="$$NVIM_TEST_XDG_ROOT/data"; \
	NVIM_TEST_XDG_STATE="$$NVIM_TEST_XDG_ROOT/state"; \
	NVIM_TEST_XDG_CACHE="$$NVIM_TEST_XDG_ROOT/cache"; \
	trap 'rm -rf "$$NVIM_TEST_ROOT"' EXIT; \
	rm -rf "$$NVIM_TEST_ROOT"; \
	mkdir -p "$$NVIM_TEST_XDG_DATA" "$$NVIM_TEST_XDG_STATE" "$$NVIM_TEST_XDG_CACHE"; \
	XDG_DATA_HOME="$$NVIM_TEST_XDG_DATA" XDG_STATE_HOME="$$NVIM_TEST_XDG_STATE" XDG_CACHE_HOME="$$NVIM_TEST_XDG_CACHE" yes | nvim --headless -u nvim-tests/minimal_init.lua +qa!; \
	XDG_DATA_HOME="$$NVIM_TEST_XDG_DATA" XDG_STATE_HOME="$$NVIM_TEST_XDG_STATE" XDG_CACHE_HOME="$$NVIM_TEST_XDG_CACHE" nvim --headless -u nvim-tests/minimal_init.lua -l nvim-tests/run.lua
