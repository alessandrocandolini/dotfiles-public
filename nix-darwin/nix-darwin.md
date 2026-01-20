# Nix-darwin with flakes! 

Yes, i've finally taken the time to migrate nix-darwing to 
* use flakes (so i can have a `flake.lock`)
* use home manager

The new setup is under `nix-darwin` folder. The legacy setup is still available for older installations. 

To update the flakes 
```
cd ~/dotfiles-public/nix-darwin
nix flake update
```
and to update darwin
```
sudo darwin-rebuild switch --flake ~/dotfiles-public/nix-darwin/#this-mac

```

A number of things is still not ideal, for instance the fact that I couldn't find a better way to setup darwin other than hardcoding my name in the file (absolutely not portable)
I will have to research more for better alternatives. 
