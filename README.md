# dotfiles

my personal opinionated `.bashrc`, `.vimrc` and other bash dotfiles managed through git.

See [bashrc.md](bashrc.md) and [vimrc.md](vimrc.md) for specific details about the corresponding dotfiles. 

## How to use them

1. install [GNU stow](https://www.gnu.org/software/stow/). On MAC OS it can be installed eg via homebrew: ```brew install stow```
2. clone this repo in the `$HOME` folder (yes, the folder is important because of the way `stow` works by default)
3. `cd` inside the cloned repo 
4. run `stow <name of the folder>`, to create (for each file in the folder) symbolic links to the file in the `$HOME` directory

For example, running 
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
and if you similarly run also `stow vim` it will generate 
```
$HOME/.vimrc@ -> $HOME/dotfiles/vim/.vim
```

Warning: never place any file (readmes etc) in the subfolders, because stow will create symbolic links for every file in the subfolders. 



