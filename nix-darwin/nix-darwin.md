# Nix-darwin with flakes! 

Yes, i've finally taken the time to migrate nix-darwin to 
* use flakes (so I can have a `flake.lock`)
* use home manager

The new setup is under `nix-darwin` folder. The legacy setup is still available for older installations. 

To update the flakes 
```
cd ~/dotfiles-public/nix-darwin
nix flake update
```
and to update darwin
```
sudo darwin-rebuild switch --option accept-flake-config true --flake ~/dotfiles-public/nix-darwin#this-mac

```

`darwin-rebuild` forwards `--option accept-flake-config true` to Nix, accepting
the flake's binary-cache settings. Do not pass `--accept-flake-config` directly:
that shorthand works with `nix build`, but this version of `darwin-rebuild`
rejects it as an unknown option.

A number of things are still not ideal, for instance the fact that I couldn't find a better way to setup darwin other than hardcoding my name in the file (absolutely not portable)
I will have to research more for better alternatives. 

## Temporary Codex packaging fix

The `llm-agents` input is temporarily pinned to commit
`c27a13893df72acf585d79d95d177bfe2e7a31cd` from
[PR #9889](https://github.com/numtide/llm-agents.nix/pull/9889). Its
`packages/codex/hashes.json` specifies Codex **0.157.0**, and the patch installs
the complete package layout required by the app-server daemon. The local
`codex.nix` overrides this to **0.157.1**, using the source hash from upstream
commit `bfda5b8161d9e05bb3255a6f975628f4373209fc`. Cargo and V8 hashes are identical
between those revisions, so the rest of the fixed build recipe is reused.
This addresses the startup failure that prompted the rollback in dotfiles PR #309.

The pin retains the PR's own dependencies. Dependencies can use the configured
`cache.numtide.com` binary cache, but the locally overridden Codex may require a
lengthy source build. Optionally build it separately to test before activation:

```sh
nix build --accept-flake-config ~/dotfiles-public/nix-darwin#codex
./result/bin/codex --version
```

`darwin-rebuild switch` also builds this package, so the separate build is not
required. If already built, Nix reuses the result.

This temporary trial applies to the flake setup;
the legacy configuration retains its existing pin pending upstream integration.

To apply the locked configuration with the binary cache enabled:

```sh
sudo darwin-rebuild switch --option accept-flake-config true --flake ~/dotfiles-public/nix-darwin#this-mac
```

After the fix lands upstream in a release at least as new as 0.157.1, restore `llm-agents.url` to
`github:numtide/llm-agents.nix`, remove its temporary comments, and update only
that input:

```sh
cd ~/dotfiles-public/nix-darwin
nix flake update llm-agents --accept-flake-config
```

Verify that the new revision includes the packaging fix and check its
`packages/codex/hashes.json` version before rebuilding. Switch `home.nix` back to
the upstream `codex` package, remove `packages.${system}.codex` from `flake.nix`,
and delete `codex.nix`. Remove this temporary section once the workaround is retired.
