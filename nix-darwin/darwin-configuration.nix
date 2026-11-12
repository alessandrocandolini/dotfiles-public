{
  lib,
  pkgs,
  username,
  certificatePath ? null,
  ...
}:

let
  javaTruststore =
    pkgs.runCommandLocal "java-truststore.p12"
      {
        nativeBuildInputs = [ pkgs.openssl ];
        certificateBundle = pkgs.writeText "java-ca-bundle.pem" (builtins.readFile certificatePath);
      }
      ''
        begins=$(grep -Ec '^-----BEGIN (TRUSTED )?CERTIFICATE-----[[:space:]]*$' "$certificateBundle")
        ends=$(grep -Ec '^-----END (TRUSTED )?CERTIFICATE-----[[:space:]]*$' "$certificateBundle")
        test "$begins" -gt 0
        test "$begins" -eq "$ends"
        if grep -Eq '^-----BEGIN .*PRIVATE KEY-----' "$certificateBundle"; then
          echo "The certificate bundle contains a private key" >&2
          exit 1
        fi

        openssl pkcs12 -export -nokeys -jdktrust anyExtendedKeyUsage \
          -certpbe NONE -nomac -passout pass: \
          -in "$certificateBundle" -out "$out"

        openssl pkcs12 -in "$out" -nokeys -passin pass: -out exported.pem
        test "$(grep -c '^-----BEGIN CERTIFICATE-----' exported.pem)" -eq "$begins"
      '';
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
    }
    // lib.optionalAttrs (certificatePath != null) {
      ssl-cert-file = certificatePath;
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 120d";
    };

    optimise.automatic = true;

    envVars = {
      OBJC_DISABLE_INITIALIZE_FORK_SAFETY = "YES";
    }
    // lib.optionalAttrs (certificatePath != null) {
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

  environment.interactiveShellInit = lib.optionalString (certificatePath != null) ''
    case " ''${JAVA_TOOL_OPTIONS-} " in
      *" -Djavax.net.ssl.trustStore=${javaTruststore} "*) ;;
      *)
        export JAVA_TOOL_OPTIONS="''${JAVA_TOOL_OPTIONS:+$JAVA_TOOL_OPTIONS }-Djavax.net.ssl.trustStore=${javaTruststore}"
        ;;
    esac
  '';

  system.build = lib.optionalAttrs (certificatePath != null) {
    inherit javaTruststore;
  };

  system.stateVersion = 6;
}
