{ pkgs, inputs, ... }:

{
  home.packages = [
    pkgs.clang-tools
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex
  ];
}
