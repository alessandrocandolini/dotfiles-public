# Nix

## Why nix?

[Nix](https://github.com/NixOS/nix) is a *purely functional* cross-platform package manager aiming at *reproducible builds*.

Generally speaking, there are many intriguing applications of nix, including: 
* **throwaway ephemeral shells**: do you want to access `sbt` (the scala build tool) but you don't want to install it global? Just run `nix-shell -p sbt` 
* **dev environment setup on a per-repo / per-project basis**, avoiding global installations and/or per-shell environment managers like pyenv, jenv etc; you `cd` into a project folder and all the right dependnecies becomes available

Ephemeral reproducible enviroments can be achieved alternatively through Dockerised environments, but there is a overhead of RAM, CPU, etc to setup docker containers for every usecase. 
In addition, nix can be used to generate smaller minimal Docker images. 

Here however I want to focus on another interesting aspect of nix, namely using nix as a package manager (essentially, on MACOSX as an alternative to homebrew). 

To achieve this we will need to install two / three things 
* nix itself
* nix-darwin (to have a declarative configuration)


## Installation 

### Install Nix

Latest guide should be available here: https://nixos.org/manual/nix/stable/installation/installing-binary.html
```
sh <(curl -L https://nixos.org/nix/install)
```

There were problems with MACOS in the past, due to the restrictions on creating `/nix` folder. Recent installers should take care of that automatically with 0 effort and no need to restart the machine. 

* Go for multi mode installation on MAC. 
* choose verbose mode
* allow sudo commands

### Install nix darwin

It can be installed using `nix`, once nix is installed. However the installer fails due to the need of creating a symb link on `/run`. 
The solution is to edit 
```
12:50 $ cat /etc/synthetic.conf
nix
run     /System/Volumes/Data/private/var/run/
```

and to **reboot** the machine in order the changes to become effective. You might also need to run 
```
 /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t
 ```


## Further readings 
* [What Is Nix and Why You Should Use It](https://serokell.io/blog/what-is-nix)
* [Using Nix to set up my new Mac](https://adrianhesketh.com/2020/07/03/mac-setup-with-nix-darwin/)
* [https://wickedchicken.github.io/post/macos-nix-setup/](https://wickedchicken.github.io/post/macos-nix-setup/)
* [Dev Environment Setup With Nix on MacOS](https://www.mathiaspolligkeit.de/dev/exploring-nix-on-macos/)
* [Set up nix & home-manager in macoS Big Sur 11](https://gist.github.com/mandrean/65108e0898629e20afe1002d8bf4f223)
