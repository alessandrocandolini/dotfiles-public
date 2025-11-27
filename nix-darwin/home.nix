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
    jdk21
    (pkgs.sbt.override { jre = pkgs.jdk21; })
    coursier
  ];

  vimStuff = with pkgs; [
    vim
    neovim
  ];

  cliStuff = with pkgs; [
    jq
    fzf
    ripgrep
    git
    gh
    delta
    awscli2
    tmux
    tmuxinator
    unzip
    curl
    nodejs_latest
    starship
    coreutils
    fd
    pkg-config
    ollama
    llama-cpp
    htop
    macmon
  ];
in
{
  home.stateVersion = "25.05";

  home.packages =
    dockerStuff ++ scalaStuff ++ vimStuff ++ cliStuff;

  programs.bash.enable = false;
  programs.starship.enable = true;
  programs.git.enable = true;

  home.sessionVariables.JAVA_HOME = "${pkgs.jdk21}/";
}
