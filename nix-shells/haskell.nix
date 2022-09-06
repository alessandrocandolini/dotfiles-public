# shell.nix
{ pkgs ? import <nixpkgs> { } }:
let
  python-with-my-packages = pkgs.python3.withPackages (p: with p; [
    requests
    pyyaml
    black
    jinja2
    termcolor
    # other python packages you want
  ]);
in
pkgs.mkShell {
  buildInputs = [
    python-with-my-packages
    pkgs.neovim
  ];
  shellHook = ''
    PYTHONPATH=${python-with-my-packages}/${python-with-my-packages.sitePackages}
    # maybe set more env-vars
  '';
}
