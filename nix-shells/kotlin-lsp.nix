{ pkgs ? import <nixpkgs> {} }:

let
  version = "261.13587.0";

  system = pkgs.stdenv.hostPlatform.system;

  urlFor = system:
    if system == "aarch64-darwin" then
      "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-mac-aarch64.zip"
    else if system == "x86_64-darwin" then
      "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-mac-x64.zip"
    else if system == "aarch64-linux" then
      "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-linux-aarch64.zip"
    else if system == "x86_64-linux" then
      "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-linux-x64.zip"
    else
      throw "Unsupported system: ${system}";

  hashFor = system:
    if system == "aarch64-darwin" then
      "sha256-zwlzVt3KYN0OXKr6sI9XSijXSbTImomSTGRGa+3zCK8="
    else
      throw "Add the correct hash for ${system} from the release checksums.";
in
pkgs.mkShell {
  packages = [
    (pkgs.stdenvNoCC.mkDerivation {
      pname = "kotlin-lsp";
      inherit version;

      src = pkgs.fetchzip {
        url = urlFor system;
        hash = hashFor system;
        stripRoot = false;
      };

      installPhase = ''
        mkdir -p $out/bin $out/share/kotlin-lsp
        cp -R $src/* $out/share/kotlin-lsp/

        # Patch: kotlin-lsp.sh tries to chmod the bundled JRE at runtime.
        # Nix store is read-only, so remove those chmod lines.
        # (safe because we set the execute bits here during build)
        ${pkgs.gnused}/bin/sed -i.bak '/^[[:space:]]*chmod[[:space:]]\+/d' \
          $out/share/kotlin-lsp/kotlin-lsp.sh

        # Ensure the launcher is executable
        chmod +x $out/share/kotlin-lsp/kotlin-lsp.sh

        # Ensure bundled JRE bits are executable (macOS layout in this ZIP)
        chmod +x $out/share/kotlin-lsp/jre/Contents/Home/bin/java || true
        chmod +x $out/share/kotlin-lsp/jre/Contents/Home/lib/jspawnhelper 2>/dev/null || true

        ln -s $out/share/kotlin-lsp/kotlin-lsp.sh $out/bin/kotlin-lsp
      '';
    })
  ];
}
