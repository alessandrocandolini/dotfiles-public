{ pkgs, ... }:

let
  unstablePkgs =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz";
      })
      {
        system = pkgs.system;
        config = pkgs.config; # keep unfree / allowBroken etc consistent
      };
  neovimPkgs =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz";
      })
      {
        system = pkgs.system;
        overlays = [
          (import (
            builtins.fetchTarball {
              url = "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
            }
          ))
        ];
      };

  dockerStuff = with unstablePkgs; [
    colima
    docker
    docker-compose
    aws-iam-authenticator
    amazon-ecr-credential-helper
    docker-credential-helpers
  ];

  scalaStuff = with unstablePkgs; [
    jdk21
    (sbt.override { jre = pkgs.jdk21; })
    coursier # for metals
  ];

  vimStuff = with unstablePkgs; [
    neovimPkgs.neovim
    proximity-sort
  ];

  lspStuff = with unstablePkgs; [
    bash-language-server
    shellcheck
    nil
    nixfmt
    terraform-ls
    basedpyright
    ruff
    lua-language-server
  ];

  rustOverlay = import (
    builtins.fetchTarball {
      url = "https://github.com/oxalica/rust-overlay/archive/master.tar.gz";
    }
  );

  rustPkgs = unstablePkgs.extend rustOverlay;

  rustToolchain = rustPkgs.rust-bin.stable."1.93.0".default.override {
    extensions = [
      "rust-analyzer"
      "rust-src"
      "clippy"
      "rustfmt"
    ];
  };

  rustStuff = [
    rustToolchain
    unstablePkgs.cargo-generate
  ];
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    with unstablePkgs;
    vimStuff
    ++ scalaStuff
    ++ dockerStuff
    ++ lspStuff
    ++ rustStuff
    ++ [
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
      #     texlab
      #     apacheHttpd
      #     postgresql
      coreutils
      pigz
      fd
      pkg-config
      ollama
      llama-cpp
      htop
      macmon
      universal-ctags
    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  nix.package = pkgs.nix;

  # Point vim to neovim
  environment.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };
  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = false;
  programs.bash.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  environment.variables.JAVA_HOME = "${pkgs.jdk21}/";
}
