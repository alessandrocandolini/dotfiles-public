# dotfiles

my personal opinionated `.bashrc`, `.vimrc` and other dotfiles managed through git and stow

See [bashrc.md](bashrc.md), [vimrc.md](vimrc.md), and [nix.md](nix.md) for more specific details about the corresponding dotfiles. 

## Install GNU stow

Install [**GNU stow**](https://www.gnu.org/software/stow/). On MAC OS, one of the simplest way to install it is using homebrew: 
```brew install stow```
or you can check [nix.md](nix.md) if you are already used to nix. (Don't use nix just to install stow!)

## How to

1. Clone this repo in the `$HOME` folder (yes, the folder is important because of the way `stow` works by default)
3. `cd` inside the cloned repo 
4. run `stow <name of the folder>`, to create (for each file in the folder) symbolic links to the file in the `$HOME` directory

For example 
```
cd
git clone git@github.com:alessandrocandolini/dotfiles.git
cd dotfiles
stow bash
```
will automatically generate the symbolic links
```
$HOME/.bashrc@ -> $HOME/dotfiles/bash/.bashrc
$HOME/.bash_profile@ -> $HOME/dotfiles/bash/.bash_profile
```
Similarly, running 
```
stow vim
```
will automatically generate 
```
$HOME/.vimrc@ -> $HOME/dotfiles/vim/.vim
```

## stow-global-ignore

Stow will install symbolic links for every file but those matching the patterns in the `$HOME/.stow-global-ignore` file. This repo contains also a version of it, and it can be installed through stow itself. 

Notice: *by default* `.gitignore` is in the list of files that stow will ignore. 
So, running `stow git` on this repo will NOT work, unless a custom `.stow-global-ignore` without `gitignore` is available (like the one provided by this repo).



