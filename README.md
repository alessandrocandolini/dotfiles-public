# dotfiles

Personal dotfiles managed using `git` and [stow](https://www.gnu.org/software/stow/). 

I use these dotfiles on MACOS, some of them can be used on linux, but not all of them. 

See [bashrc.md](bashrc.md), [vimrc.md](vimrc.md), and [nix.md](nix.md) for more details about those specific dotfiles.

## Requirements

* `git`
* close this repo 
* GNU `stow` 

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

Notice: for some dotfiles (eg, bash or git) `--no-folding` can be omitted, because the files are created in the `$HOME` folder. For other dotfiles created under nested folders (eg, those that will create links under `~/.config/`) be sure to always use `--no-folding` , otherwise `stow` will create symbolic links to the whole folder (if the folder does not exist) instead of creating the folder first and then generate the symbolic links. 


## stow-global-ignore

Stow will install symbolic links for every file but those matching the patterns in the `$HOME/.stow-global-ignore` file. This repo contains also a version of it, and it can be installed through stow itself.

Notice: *by default* `.gitignore` is in the list of files that stow will ignore.
So, running `stow git` on this repo will NOT work, unless a custom `.stow-global-ignore` without `gitignore` is available (like the one provided by this repo).



