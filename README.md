# dotfiles

Personal dotfiles managed via `git` and `stow`.

See [bashrc.md](bashrc.md), [vimrc.md](vimrc.md), and [nix.md](nix.md) for more details about those specific dotfiles.

## Install GNU Stow

If `nix` is installed,
```bash
nix-shell -p stow
```
Uf homebrew is installed,
```bash
brew install stow
```

## Run

Clone the repo and run
```bash
stow --no-folding --verbose --target ~ <name of the folder>
```

If you want to run it in dry mode
```bash
stow --simulate --no-folding --verbose --target ~ <name of the folder>
```

Alternatively, a [makefile](Makefile) is provided with phony targets for each specific config
```bash
make bash
make alacritty 
make neovim 
...
```
and also a `all` target to run them all at once
```bash
make all
```

Notice: for some of the config files provided here, like bash or git, `--no-folding` is not strictly necessary and can be omitted when running stow manually. For some of the other configs, like for example those that will create links under `~/.config/`, it's important to always use `--no-folding` , otherwise `stow` will create symbolic links to the whole folder (if the folder does not exist) instead of creating the folder first and then generate the symbolic links. 


## stow-global-ignore

Stow will install symbolic links for every file but those matching the patterns in the `$HOME/.stow-global-ignore` file. This repo contains also a version of it, and it can be installed through stow itself.

Notice: *by default* `.gitignore` is in the list of files that stow will ignore.
So, running `stow git` on this repo will NOT work, unless a custom `.stow-global-ignore` without `gitignore` is available (like the one provided by this repo).



