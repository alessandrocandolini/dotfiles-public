{
  pkgs,
  lib,
  inputs,
  ...
}:

let

  dockerStuff = with pkgs; [
    docker
    docker-compose
    aws-iam-authenticator
    amazon-ecr-credential-helper
    docker-credential-helpers
  ];

  scalaStuff = with pkgs; [
    jdk25
    (pkgs.sbt.override { jre = pkgs.jdk25; })
    coursier
    async-profiler
  ];

  nvimNightly = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;

  cliStuff = with pkgs; [
    jq
    fzf
    ripgrep
    fd
    git
    delta
    awscli2
    tmux
    unzip
    pigz
    curl
    # nodejs_latest
    starship
    coreutils
    zlib
    pkg-config
    btop
    macmon
    universal-ctags
    # aerc
    opentofu
    tflint
    proximity-sort
    tree
  ];

  lspStuff = with pkgs; [
    bash-language-server
    shellcheck
    nil
    nixfmt
    terraform-ls
    basedpyright
    ruff
    lua-language-server
  ];

  rustPkgs = pkgs.extend inputs.rust-overlay.overlays.default;

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
    pkgs.cargo-generate
    pkgs.cargo-expand
  ];

  llmStuff = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    codex
    opencode
    claude-code
  ];

  fastPkgs = inputs.nixpkgs-fast.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  # Upstream mactop 2.0.5 currently fails tests in the Nix sandbox by writing under $HOME.
  mactopNoTests = fastPkgs.mactop.overrideAttrs (_: {
    doCheck = false;
  });
  fastMovingStuff = with fastPkgs; [
    ollama
    llama-cpp
    colima
    mactopNoTests
    gh
  ];
in
{
  home.stateVersion = "25.05";

  home.packages =
    dockerStuff ++ scalaStuff ++ cliStuff ++ fastMovingStuff ++ lspStuff ++ rustStuff ++ llmStuff;

  programs.bash.enable = false;
  programs.starship.enable = true;
  programs.git.enable = true;
  programs.neovim = {
    enable = true;
    package = nvimNightly;
    viAlias = true;
    vimAlias = true;
  };
  home.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk25}/";
    PKG_CONFIG_PATH = "${
      lib.makeSearchPathOutput "dev" "lib/pkgconfig" [ pkgs.zlib ]
    }:$PKG_CONFIG_PATH";
    CPATH = "${lib.makeSearchPathOutput "dev" "include" [ pkgs.zlib ]}:$CPATH";
    LIBRARY_PATH = "${lib.makeLibraryPath [ pkgs.zlib ]}:$LIBRARY_PATH";
  };
}
