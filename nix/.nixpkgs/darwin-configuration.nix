{ config, pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ 
      pkgs.wget
      pkgs.htop
      pkgs.jq
      pkgs.fzf
      pkgs.ripgrep
      pkgs.git
      pkgs.awscli
      pkgs.sbt
      pkgs.vim
      pkgs.stow
      pkgs.terraform
      pkgs.tmux
      pkgs.tree
      pkgs.unzip
      pkgs.gradle
      pkgs.curl
      pkgs.neovim
      pkgs.bash_5
      pkgs.bashCompletion
      pkgs.vegeta

    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  # services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
