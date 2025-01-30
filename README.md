# dotfiles

Personal dotfiles managed using `git` and [stow](https://www.gnu.org/software/stow/). 

I use these dotfiles on MACOS, some of them can be used on linux too, but not all of them. 

See [bashrc.md](bashrc.md), [vimrc.md](vimrc.md), and [nix.md](nix.md) for more details about specific dotfiles.

## Requirements

* `git`
* GNU `stow` 

Git is usually pre-installed with the developer tools (although it can be convenient to update the version using a package manager). 

Install `stow` using `nix`
```bash
nix-shell -p stow
```
Alternatively, using `homebrew`
```bash
brew install stow
```

More options [here](https://www.gnu.org/software/stow/)

## Run

Once `stow` and `make` are available, clone this repo and use the [makefile](Makefile):
```bash
make all
```
Phony targets are provided for each specific config, if you want more granularity:
```bash
make bash
``` 
```
make alacritty 
```
```
make neovim 
```
etc. 

Alternatively, invoke `stow` directly 
```bash
stow --no-folding --verbose --target ~ <name of the folder>
```

If you want to run it in dry mode, use the `--simulate` option: 
```bash
stow --simulate --no-folding --verbose --target ~ <name of the folder>
```

## Why --no-folding?

* For dotfiles placed directly in $HOME (e.g., `.bashrc`, `.gitconfig`), the `--no-folding` flag is redundant and can be omitted.
* For configurations that reside in nested directories where there might be other files that we don't necessarily wanna track in git (e.g., `~/.config/`), always use `--no-folding` to prevent stow from creating a symlink to the entire folder instead of linking individual files, and the content of that folder to become part of this repo.

## stow-global-ignore

By default, stow creates symbolic links for all files except those matching patterns specified in `$HOME/.stow-global-ignore`.

This repository includes a predefined `.stow-global-ignore file`, which can be installed via stow.

Note: `.gitignore` is excluded by default. If you intend to apply stow git, ensure your `.stow-global-ignore` file does not exclude gitignore. You can use the one provided in this repository.


