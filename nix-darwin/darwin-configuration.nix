{
  pkgs,
  username,
  certificatePath,
  ...
}:

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

  system.stateVersion = 6;
}
