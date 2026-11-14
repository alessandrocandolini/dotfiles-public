# Nix & nix-darwin on macOS

[Nix](https://github.com/NixOS/nix) is a *purely functional* package manager designed for **reproducible builds** and **isolated dev environments**. Key benefits:

- **Ephemeral builds** via `nix-shell -p <pkg>`, eliminating global installations and allowing temporary usage.
- **Per-project environments** that reduce conflicts in language runtimes or system packages.
- **Declarative** configuration of packages and services, achievable on macOS through **nix-darwin**.

## Are you sure you want to adopt Nix? Maybe not

⚠️ While Nix is powerful and usually works perfectly well once it’s up and running, be aware of the following:
* Installing Nix on macOS can be challenging. The installation rarely worked straigth away for me (and I have run several installations), and tends to break with each major macOS update due to underlying system changes.
* Nix derivations are sometimes slow to get updated, so if you rely on having the latest version of a tool, it may not be immediately available.

That's precisely the reason why in this repo dotfiles are not managed by nix. 
