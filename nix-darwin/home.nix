{ config, pkgs, inputs, ... }:

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

  vimStuff = with pkgs; [
    vim
    # neovim
    inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default
    proximity-sort
  ];

  cliStuff = with pkgs; [
    jq
    fzf
    skim
    ripgrep
    git
    gh
    delta
    awscli2
    tmux
    unzip
    curl
    # nodejs_latest
    starship
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

  lspStuff = with pkgs; [
    bash-language-server
    shellcheck
    nil
    terraform-ls
    basedpyright
    ruff
    lua-language-server
  ];
in
{
  home.stateVersion = "25.05";

  home.packages =
    dockerStuff ++ scalaStuff ++ vimStuff ++ cliStuff ++ lspStuff;

  programs.bash.enable = false;
  programs.starship.enable = true;
  programs.git.enable = true;

  home.sessionVariables.JAVA_HOME = "${pkgs.jdk21}/";
}
