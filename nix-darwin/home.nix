{
  pkgs,
  inputs,
  ...
}:

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
    jdk21
    (pkgs.sbt.override { jre = pkgs.jdk21; })
    coursier
  ];

  nvimNightly = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;

  cliStuff = with pkgs; [
    jq
    fzf
    ripgrep
    fd
    git
    gh
    delta
    awscli2
    tmux
    unzip
    pigz
    curl
    # nodejs_latest
    starship
    coreutils
    pkg-config
    ollama
    llama-cpp
    htop
    macmon
    universal-ctags
    # aerc
    opentofu
    tflint
    proximity-sort
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
  ];

  llmStuff = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    codex
  ];
in
{
  home.stateVersion = "25.05";

  home.packages = dockerStuff ++ scalaStuff ++ cliStuff ++ lspStuff ++ rustStuff ++ llmStuff;

  programs.bash.enable = false;
  programs.starship.enable = true;
  programs.git.enable = true;
  programs.neovim = {
    enable = true;
    package = nvimNightly;
    viAlias = true;
    vimAlias = true;
  };
  home.sessionVariables.JAVA_HOME = "${pkgs.jdk21}/";
}
