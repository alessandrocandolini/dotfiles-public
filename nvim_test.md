# Neovim Test Work Summary

## Goals
1. Build a Neovim test setup to test the Neovim configuration in this repo using black-box behavioral tests.
2. Ensure tests run both locally and in CI.
3. Ensure determinism through Nix flakes (pinned, reproducible environment).
4. Use the exact same Neovim configuration for tests and real usage.

Black-box/behavioral means tests validate only what a user can observe while interacting with Neovim.
They exist to catch regressions automatically instead of manually opening Neovim and discovering breakage.

Concretely:
1. If part of the configuration is no longer loaded from `init.lua`, tests must fail (so tests must not call `require(...)` for config modules directly).
2. If implementation is reorganized across modules/files/helpers, tests should not need updates and should keep passing, as long as observable behavior remains unchanged.

## Non-Negotiable Constraints
1. Keep Makefile minimal.
2. No bash script files.
3. Avoid changing business logic only to satisfy tests.

## What Was Implemented (across iterations)
- Added `nvim-tests/` test area.
- Added `init_test.lua` bootstrap to load repo Neovim config.
- Added behavioral specs for diagnostics, projectionist, and fzf-lua.
- Added shared helpers under `nvim-tests/helpers/`.
- Added CI workflow for Neovim tests.
- Added Nix flake for test environment.
- Added Make targets for running Neovim tests.

## Reversions / Regression History
1. Custom runner and suite orchestration changed multiple times (Plenary directory mode vs custom Lua runner), causing inconsistent behavior and harder debugging.
2. FZF open-detection logic based on window-count deltas introduced hangs/flakiness; this was reverted when it blocked suite completion.
3. Shared-helper refactors temporarily broke stable test execution (notably projectionist/fzf paths) and were partially rolled back.
4. A busted-wrapper experiment was introduced, then removed due to portability/exit-code semantics concerns under LuaJIT/Lua 5.1.

## Current Risk
Configuration drift between test setup and real setup remains the biggest liability.
If test config is maintained separately or manually synced, regression confidence is weak.
