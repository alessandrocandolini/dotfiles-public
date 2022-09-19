# dotfiles

Personal dotfiles managed via `git` and `stow`. 

I use these config files on MACOS, some of them might be portable to linux, but not all. 

See [bashrc.md](bashrc.md), [vimrc.md](vimrc.md), and [nix.md](nix.md) for more details about those specific dotfiles.

## Install GNU Stow

Using `nix`
```bash
nix-shell -p stow
```
Alternatively, using `homebrew`
```bash
brew install stow
```

More options here: https://www.gnu.org/software/stow/

## Run

Assuming `stow` and `make` are available, clone this repo and use the [makefile](Makefile):
```bash
make all
```
Phony targets are provided for each specific config
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

If you want to run it in dry mode
```bash
stow --simulate --no-folding --verbose --target ~ <name of the folder>
```

Notice: for some of the config files provided (eg, bash or git) `--no-folding` can be omitted. For some of the other configs however (eg, those that will create links under `~/.config/`) always use `--no-folding` , otherwise `stow` will create symbolic links to the whole folder (if the folder does not exist) instead of creating the folder first and then generate the symbolic links. 


## stow-global-ignore

Stow will install symbolic links for every file but those matching the patterns in the `$HOME/.stow-global-ignore` file. This repo contains also a version of it, and it can be installed through stow itself.

Notice: *by default* `.gitignore` is in the list of files that stow will ignore.
So, running `stow git` on this repo will NOT work, unless a custom `.stow-global-ignore` without `gitignore` is available (like the one provided by this repo).



