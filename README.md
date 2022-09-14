# dotfiles

Personal opinionated configuration dotfiles managed through `git` and `stow`.

See [bashrc.md](bashrc.md), [vimrc.md](vimrc.md), and [nix.md](nix.md) for more specific details about the corresponding dotfiles.

## Install GNU stow

Assuming `nix` is installed,
```bash
nix-shell -p stow
```
Alternatively, assuming homebrew installed
```bash
brew install stow
```

## How to use this repo

Clone this repo and from repo folder run
```bash
stow --no-folding --verbose --target ~ <name of the folder>
```

If you want to run it in dry mode
```bash
stow --simulate --no-folding --verbose --target ~ <name of the folder>
```


For most of the config files provided here,
```bash
stow --verbose --target ~ bash
```
is enough, or even simpler (assuming the repo has been cloned in the `$HOME` folder, so that targets are not needed):
```
stow bash
```

For config files under `~/.config/` instead, remenmber to run `stow` always using the `--no-folding` option, otherwise `stow` will create symbolic links to the entire folder if the folder does not exist, instead of creating the folder first and then generate the symbolic links. For example,
```bash
stow --simulate --no-folding --verbose --target ~ starship
stow --simulate --no-folding --verbose --target ~ neovim
stow --simulate --no-folding --verbose --target ~ alacritty
```

## stow-global-ignore

Stow will install symbolic links for every file but those matching the patterns in the `$HOME/.stow-global-ignore` file. This repo contains also a version of it, and it can be installed through stow itself.

Notice: *by default* `.gitignore` is in the list of files that stow will ignore.
So, running `stow git` on this repo will NOT work, unless a custom `.stow-global-ignore` without `gitignore` is available (like the one provided by this repo).



