{
  lib,
  pkgs,
  username,
  certificatePath,
  enableJavaTruststore,
  ...
}:

let
  javaTruststore = import ./java-truststore.nix { inherit pkgs certificatePath; };
in
{
  nix = {
    enable = true;
    package = pkgs.nix;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-substituters = [ "https://cache.numtide.com" ];
      trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
      ssl-cert-file = certificatePath;
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 120d";
    };

    optimise.automatic = true;

    envVars = {
      OBJC_DISABLE_INITIALIZE_FORK_SAFETY = "YES";
      NIX_SSL_CERT_FILE = certificatePath;
    };
  };

  programs.bash.enable = true;

  environment.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };

  users.users.${username} = {
    home = "/Users/${username}";
  };

  nixpkgs.overlays = lib.optional enableJavaTruststore (
    import ./java-certificate-overlay.nix { inherit certificatePath; }
  );

  system.build = lib.optionalAttrs enableJavaTruststore {
    inherit javaTruststore;
    javaTruststoreTests = import ./tests/java-truststore.nix { inherit pkgs; };
    jdkWithCertificatesTests = import ./tests/jdk-with-certificates.nix { inherit pkgs; };
    javaToolTests = import ./tests/java-tools.nix { inherit pkgs; };
  };

  system.stateVersion = 6;
}
