{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = [ (pkgs.callPackage ./packages/kotlin-lsp.nix { }) ];
}
