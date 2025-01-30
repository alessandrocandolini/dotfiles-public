{ config, pkgs, ... }:

let

  dockerStuff = with pkgs; [
      colima
      docker
      docker-compose
      aws-iam-authenticator
      amazon-ecr-credential-helper
      docker-credential-helpers
  ];

  scalaStuff = with pkgs; [
      jdk17
      (sbt.override { jre = pkgs.jdk17; })
      coursier # for metals
  ];

  vimStuff = with pkgs; [
      vim
      neovim
  ];

in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; vimStuff ++ scalaStuff ++ dockerStuff ++
    [
      jq
      fzf
      ripgrep
      git
      gh
      delta
      awscli2
#     (gradle.override { java = pkgs.jdk17; })
      tmux
      unzip
      curl
      nodejs_latest
      starship
#     terraform-lsp
#     texlab
#     apacheHttpd
#     rnix-lsp
#     postgresql
      coreutils
      fd
      pkg-config 

    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = false;
  programs.bash.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  environment.variables.JAVA_HOME = "${pkgs.jdk17}/";
}
