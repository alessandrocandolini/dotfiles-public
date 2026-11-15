{ lib, stdenvNoCC, fetchurl, unzip, makeWrapper }:

let
  version = "271.2085.0";
  releases = {
    aarch64-darwin = {
      archive = "kotlin-server-${version}-aarch64.sit";
      sha256 = "2d22388f58be6f4dfa7a8f18c1e231871164dcacc16e407559029d7232816b4a";
    };
    x86_64-darwin = {
      archive = "kotlin-server-${version}.sit";
      sha256 = "68457ab1825331e3eac85191b7c32737cbd8993867f5a9c50dfe012c5509e8f7";
    };
  };
  release = releases.${stdenvNoCC.hostPlatform.system}
    or (throw "Kotlin LSP: this package currently supports macOS only");
in
stdenvNoCC.mkDerivation {
  pname = "kotlin-lsp";
  inherit version;

  src = fetchurl {
    url = "https://download.jetbrains.com/language-server/kotlin-server/${version}/${release.archive}";
    inherit (release) sha256;
    name = "kotlin-lsp-${version}.zip";
  };

  nativeBuildInputs = [ unzip makeWrapper ];
  sourceRoot = "kotlin-server-${version}";
  dontConfigure = true;
  dontBuild = true;
  # Preserve the signatures of the bundled native launcher and JetBrains Runtime.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/kotlin-lsp" "$out/bin"
    cp -R . "$out/libexec/kotlin-lsp/"
    makeWrapper "$out/libexec/kotlin-lsp/bin/intellij-server" "$out/bin/kotlin-lsp"
    runHook postInstall
  '';

  meta = {
    description = "Official Kotlin language server";
    homepage = "https://github.com/Kotlin/kotlin-lsp";
    platforms = lib.platforms.darwin;
    mainProgram = "kotlin-lsp";
  };
}
