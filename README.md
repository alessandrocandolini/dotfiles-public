# dotfiles

Personal dotfiles managed via `git` and `stow`.

See [bashrc.md](bashrc.md), [vimrc.md](vimrc.md), and [nix.md](nix.md) for more details about those specific dotfiles.

## Install GNU stow

If `nix` is installed,
```bash
nix-shell -p stow
```
Uf homebrew is installed,
```bash
brew install stow
```

## How to run it

Clone this repo and from repo folder run
```bash
stow --no-folding --verbose --target ~ <name of the folder>
```

If you want to run it in dry mode
```bash
stow --simulate --no-folding --verbose --target ~ <name of the folder>
```

For some of the config files provided here, `--no-folding` is not strictly needed. 
For some of the others instead, like for example those that will be created under `~/.config/`, it's important to run `stow` always using the `--no-folding` option, otherwise `stow` will create symbolic links to the entire folder if the folder does not exist, instead of creating the folder first and then generate the symbolic links. 

To avoid the mistake of forgetting about `--no-folding`  and to avoid spending time copy pasting the command, a makefile has been created with specific phony tasks for each folder and also a `all` target to run them all: 

```bash
make bash
make alacritty 
make neovim 
...
```
or 
```bash
make all
```

## stow-global-ignore

Stow will install symbolic links for every file but those matching the patterns in the `$HOME/.stow-global-ignore` file. This repo contains also a version of it, and it can be installed through stow itself.

Notice: *by default* `.gitignore` is in the list of files that stow will ignore.
So, running `stow git` on this repo will NOT work, unless a custom `.stow-global-ignore` without `gitignore` is available (like the one provided by this repo).



