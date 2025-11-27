{ config, pkgs, ... }:

{
  services.nix-daemon.enable = true;

  nix.package = pkgs.nix;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.envVars = {
    OBJC_DISABLE_INITIALIZE_FORK_SAFETY = "YES";
    NIX_SSL_CERT_FILE =
      "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
  };

  programs.bash.enable = true;

  system.stateVersion = 6;
}
