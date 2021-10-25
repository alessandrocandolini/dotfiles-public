{ config, pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs;
    [ 
      wget
      htop
      jq
      fzf
      ripgrep
      git
      awscli
      (sbt.override { jre = pkgs.jdk11; })
      vim
      stow
      terraform
      tmux
      tree
      unzip
      gradle
      curl
      neovim
      bash_5
      bashCompletion
      nodejs_latest
      stack
      go
      glow
      terraform-lsp
#     texlab
      jdk11
      gradle
      apacheHttpd

    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  # services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = false;  # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
