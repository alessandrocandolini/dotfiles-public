# dotfiles

This repository contains the configuration for my laptop and the tools I use regularly. It includes:

* nix-darwin configuration
  - a legacy setup
  - a newer setup based on *flakes* and *home-manager*
* Neovim configuration
* Dotfiles for tools such as Alacritty, Git, LLM tooling, etc

Dotfiles and nvim configuration are managed using [stow](https://www.gnu.org/software/stow/). 
This is a deliberate choice: I currently prefer not to manage them with Nix, though they live in this repository in case I decide to migrate them later.

My main development environment is macOS, and some configuration is macOS-specific (eg, nix-darwin). Other parts (e.g. Neovim) should also work on Linux.
Hereafter, the guide focuses only on installation on macOS.

See [bashrc.md](bashrc.md), [vimrc.md](vimrc.md), and [nix.md](nix.md) for more details about specific dotfiles.

## Requirements

* `git`
* GNU `stow` 
* `make` (recommended)

On macOS, `git` and `make` are usually pre-installed with developer tools on macOS, although updating it via a package manager can be convenient.

Install `stow` using `nix`
```bash
nix-shell -p stow
```
or using `homebrew`
```bash
brew install stow
```
More installation options are available [here](https://www.gnu.org/software/stow/).

## Run

Clone this repo and run:
```bash
make all
```
The [makefile](Makefile) provides phony targets for individual configurations if you want more granularity:
```bash
make bash
``` 
```
make alacritty 
```
```
make neovim 
```

Alternatively, invoke `stow` directly 
```bash
stow --no-folding --verbose --target ~ <name of the folder>
```

To run in dry mode, use the `--simulate` option: 
```bash
stow --simulate --no-folding --verbose --target ~ <name of the folder>
```

## Keep Makefile up to date

When adding a new target, remember update the list of targets in the Makefile.
## Why --no-folding?

* For dotfiles placed directly in $HOME (e.g., `.bashrc`, `.gitconfig`), the `--no-folding` flag is redundant and can be omitted.
* For configurations that reside in nested directories where there might be other files that we don't necessarily wanna track in git (e.g., `~/.config/`), always use `--no-folding` to prevent stow from creating a symlink to the entire folder instead of linking individual files, and the content of that folder to become part of this repo.

## stow-global-ignore

By default, stow creates symbolic links for all files except those matching patterns specified in `$HOME/.stow-global-ignore`.

This repository includes a predefined `.stow-global-ignore file`, which can be installed via stow.

Note: `.gitignore` is excluded by default. If you intend to apply stow git, ensure your `.stow-global-ignore` file does not exclude gitignore. You can use the one provided in this repository.


