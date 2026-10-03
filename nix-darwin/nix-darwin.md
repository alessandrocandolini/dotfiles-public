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
