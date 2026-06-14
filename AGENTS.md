# AGENTS.md

## Repo shape

- This repository contains personal laptop and developer-environment configuration, including macOS/Nix setup, Neovim, and shell/tool dotfiles.
- Dotfiles are managed with GNU `stow`. Treat that as the default model unless a directory clearly uses a different mechanism.
- The main user-facing entrypoints are `make all`, individual `make <target>` stow targets, and `make nvim-test`.

## Stow conventions

- Top-level folders such as `nvim`, `gitconfig`, `alacritty`, `bash`, `tmux`, `starship`, `codex`, and `nix` are stow packages.
- Use `stow --no-folding --target ~ <package>` semantics consistently. The `Makefile` is configured this way, and this should not change. If invoking `stow` directly, always pass `--no-folding`.
- The repo intentionally avoids folding nested config directories into one symlink. Managed files should be linked as individual leaf symlinks inside real local directories, so runtime-owned directories can keep untracked state next to the managed files. For example, `codex/.codex/config.toml` should become `~/.codex/config.toml`, while `~/.codex/` itself remains a real local directory that can contain Codex-owned files such as `auth.json`, logs, caches, skills, and other runtime state outside this repo.
- When adding a new top-level stow package, update `TASKS` in `Makefile`.

## Nix layout

- There are two macOS Nix setups and both matter:
  - `nix-darwin/`: the newer flake-based setup with `flake.lock`
  - `nix/.nixpkgs/darwin-configuration.nix`: the legacy setup used on older multi-user Nix installations
- Do not remove or casually break the legacy setup just because the flake setup exists.
- The legacy setup is kept because migrating some older machines is not trivial: newer Nix installation flows introduced breaking changes around multi-user account creation and related ownership/layout assumptions.
- On those machines, the issue is not just "old config syntax" but installer- and account-model compatibility, so preserve the legacy path unless the migration work is explicitly in scope.
- The legacy setup should stay compatible with the flake setup where practical, especially for fast-moving inputs.

## Legacy pinning rules

- The legacy config previously drifted because it fetched floating `nixpkgs-unstable` and floating `neovim-nightly-overlay/master`.
- For Neovim-related failures, first check whether `nix/.nixpkgs/darwin-configuration.nix` still mirrors the relevant revisions from `nix-darwin/flake.lock`.
- Keep these legacy inputs aligned with the flake lock unless there is a deliberate reason not to:
  - Darwin `nixpkgs` used for the Neovim overlay build
  - `nixpkgs-fast` / unstable package set used for general fast-moving packages
  - `neovim-nightly-overlay`
  - `rust-overlay`
  - `llm-agents`
- Common task mapping: if the user says "port the flake update", "sync the legacy config", "update legacy pins", or similar, do only a `pinnedSources` revision sync. The expected diff for that task must only change `rev = "...";` lines.
- Any change outside `pinnedSources` for a legacy pin-sync task requires explicit user approval first.
- For `llm-agents` pin updates intended to update Codex, do not rely on commit dates, PR titles, or "latest main" alone. Before recommending or running a rebuild, verify the pinned source's packaged Codex version directly, for example by reading `packages/codex/hashes.json` from the candidate `llm-agents.nix` revision and confirming `version` is the expected Codex version.
- Do not refactor the legacy config, introduce new package groups such as `cliStuff` or `fastMovingStuff`, move packages between package sets, change Java versions or `JAVA_HOME`, alter environment variables, or otherwise mirror `home.nix` package/layout changes unless the user explicitly asks for that broader migration.
- The important subtlety is that the legacy Neovim build should track the Darwin-pinned `nixpkgs` lineage, not a random floating unstable revision, otherwise `neovim-unwrapped` can diverge and fail upstream tests.

## Neovim

- The real config lives in `nvim/.config/nvim`.
- Plugin versions are locked in `nvim/.config/nvim/nvim-pack-lock.json`. Treat lockfile changes as intentional.
- The Scala Metals LSP server version is pinned in `nvim/.config/nvim/lua/config/metals.lua` via `cfg.settings.serverVersion`. To update Metals, change that version string to the desired Metals release, then restart Neovim/open a Scala or sbt buffer and explicitly trigger a `:MetalsUpdate`
- Neovim tests live in `nvim-tests/` and are part of the normal maintenance path for this repo.
- `make nvim-test` is the canonical test command. It enters `./nvim-tests#default` and then runs the internal test suite.
- The test shell sets isolated `HOME` and `XDG_*` directories. Tests are expected to load the real repo config from `nvim/.config/nvim` while keeping plugin installs and runtime state outside the repo.
- If you change Neovim startup, plugin bootstrapping, or test harness paths, keep `nvim-tests/init_test.lua` and `nvim-tests/flake.nix` in sync.

## CI

- Neovim CI is defined in `.github/workflows/nvim-tests.yml`.
- Changes under `nvim/**`, `nvim-tests/**`, the Neovim workflow, or `Makefile` should be assumed to affect CI.

## Codex-specific notes

- Prefer focused changes. This repo often contains personal environment choices that are intentional even when they look unusual.
