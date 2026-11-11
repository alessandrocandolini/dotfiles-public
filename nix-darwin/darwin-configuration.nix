{
  lib,
  pkgs,
  username,
  certificatePath,
  ...
}:

let
  localCertificateBundle = "/etc/nix/ca-bundle.pem";
  javaTruststore = "/etc/nix/java-truststore.p12";
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

  environment.interactiveShellInit = ''
    if [ -f ${javaTruststore} ]; then
      export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=${javaTruststore}"
    fi
  '';

  system.activationScripts.postActivation.text = ''
    bundle=${localCertificateBundle}
    truststore=${javaTruststore}

    if [ -f "$bundle" ]; then
      if [ "$(grep -c 'BEGIN CERTIFICATE' "$bundle")" -gt 100 ] \
         && ${lib.getExe pkgs.openssl} pkcs12 -export -nokeys -jdktrust anyExtendedKeyUsage \
              -certpbe NONE -nomac -passout pass: \
              -in "$bundle" -out "$truststore.new"; then
        chmod 644 "$truststore.new"
        if [ -f "$truststore" ]; then
          cp -p "$truststore" "$truststore.previous"
        fi
        mv "$truststore.new" "$truststore"
      else
        rm -f "$truststore.new"
        echo "warning: Java truststore build failed, keeping the existing $truststore" >&2
      fi
    fi
  '';

  system.stateVersion = 6;
}
