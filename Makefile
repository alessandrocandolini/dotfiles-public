TASKS=bash stow alacritty gitconfig nvim nix starship tmux stack agda rg cargo codex
VERBOSITY=1
FLAGS=--restow --no-folding --verbose $(VERBOSITY) --target ~
NIX_UPDATE_INPUTS=nixpkgs nixpkgs-fast darwin home-manager neovim-nightly-overlay rust-overlay llm-agents

.PHONY: all $(TASKS) test help nvim-test nvim-test-internal nix-update nix-inputs codex-lock codex-unlock

all:
all: $(TASKS)

$(TASKS):
	stow $(FLAGS) $@

test:
test: nvim-test

nvim-test:
	nix develop --ignore-environment ./nvim-tests#default -c make nvim-test-internal

nvim-test-internal:
	@if [ -z "$$IN_NIX_SHELL" ]; then \
		echo "nvim-test-internal must run inside nix develop --ignore-environment ./nvim-tests#default"; \
		exit 1; \
	fi
	yes | nvim --headless -u nvim-tests/init_test.lua +qa!
	nvim --headless -u NONE -l nvim-tests/run_suite.lua

nix-update:
	nix flake update $(INPUTS) --flake ./nix-darwin

nix-inputs:
	@printf '%s\n' $(NIX_UPDATE_INPUTS)

codex-lock:
	chflags uchg codex/.codex/config.toml

codex-unlock:
	chflags nouchg codex/.codex/config.toml

help:
	@printf '%s\n' 'Stow targets:'
	@printf '  %-14s %s\n' all 'Stow all configured dotfile packages into ~'
	@for task in $(TASKS); do printf '  %-14s %s\n' "$$task" "Stow ./$$task into ~"; done
	@printf '\n%s\n' 'Utility targets:'
	@printf '  %-14s %s\n' test 'Run the test suite'
	@printf '  %-14s %s\n' nvim-test 'Run the Neovim test suite inside nix develop'
	@printf '  %-14s %s\n' nix-update 'Update all nix-darwin flake inputs, or pass INPUTS="nixpkgs darwin" to limit'
	@printf '  %-14s %s\n' nix-inputs 'List supported nix flake input names'
	@printf '  %-14s %s\n' codex-lock 'Protect codex/.codex/config.toml with chflags uchg'
	@printf '  %-14s %s\n' codex-unlock 'Remove uchg protection from codex/.codex/config.toml'
	@printf '  %-14s %s\n' help 'Show available targets'
