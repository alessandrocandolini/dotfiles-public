{ pkgs ? import <nixpkgs> {
  config.allowUnfreePredicate = pkg: (pkg.pname or "") == "android-cli";
} }:

with pkgs;

let
  android-nixpkgs = callPackage (import (builtins.fetchGit {
    url = "https://github.com/tadfisher/android-nixpkgs.git";
  })) {
    # Default; can also choose "beta", "preview", or "canary".
    channel = "stable";
  };

  android-sdk = android-nixpkgs.sdk (sdkPkgs: with sdkPkgs; [
    cmdline-tools-latest
    build-tools-30-0-3
    build-tools-33-0-1
    build-tools-36-0-0
    platform-tools
    platforms-android-33
    platforms-android-37-0
    emulator
  ]);

in
mkShell {
  buildInputs = [
    jdk25
    (gradle_9.override { java = jdk25; })
    android-sdk
    (callPackage ./packages/kotlin-lsp.nix { })
  ];

  JAVA_HOME = "${jdk25.home}";
}
