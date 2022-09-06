{ config, pkgs, ... }:

let
  haskellStuff =
    let

      # things that cabal can't install on its own due to native dependencies
      troublesomePackages = p: [ p.digest p.postgresql-libpq p.zlib ];

      compilers =
        [
#          (pkgs.haskell.packages.ghc8107.ghcWithPackages troublesomePackages)
          (pkgs.haskell.packages.ghc902.ghcWithPackages troublesomePackages)
        ];

      hls = pkgs.haskell-language-server.override {
        supportedGhcVersions = [
          # "8107" 
          "902"
       ];
      };
    in
      compilers ++ [
        hls
        pkgs.cabal-install
        pkgs.cabal2nix
        pkgs.ghcid
        pkgs.hlint
        pkgs.hpack
        pkgs.stack
        pkgs.zlib
      ];
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; haskellStuff ++ 
    [
      jq
      fzf
      ripgrep
      git
      awscli2
      (sbt.override { jre = pkgs.jdk17; })
      vim
      tmux
      unzip
      curl
      neovim
      bash_5
      nodejs_latest
#     stack
#     terraform-lsp
#     texlab
      jdk11
#     apacheHttpd
      rnix-lsp
      postgresql
      coreutils
      fd
      gh
      # (haskell-language-server.override { supportedGhcVersions = [ "8107" ]; version = 1.5.1; })
      colima
      docker
      docker-compose
      aws-iam-authenticator
      amazon-ecr-credential-helper
      docker-credential-helpers

    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = false;  # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  environment.variables.JAVA_HOME = "${pkgs.jdk17}/";
}
