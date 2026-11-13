{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
    kubectl
    k9s
    spacectl
  ];
}
