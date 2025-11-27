{ config, pkgs, ... }:

{
  nix = {
    enable = true;
    package = pkgs.nix;

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };

    optimise.automatic = true;

    envVars = {
      OBJC_DISABLE_INITIALIZE_FORK_SAFETY = "YES";
      NIX_SSL_CERT_FILE =
        "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
    };
  };

  programs.bash.enable = true;

  users.users.alessandrocandolini = {
    home = "/Users/alessandrocandolini";
  };

  system.stateVersion = 6;
}
