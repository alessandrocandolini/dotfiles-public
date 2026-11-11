{
  description = "nix-darwin + home-manager config";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-fast.url = "github:NixOS/nixpkgs/nixos-unstable";

    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };

    agentop = {
      url = "github:leboiko/claude-codex-pid-inspector/master";
      flake = false;
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      darwin,
      home-manager,
      neovim-nightly-overlay,
      rust-overlay,
      ...
    }:
    let
      system = "aarch64-darwin";

      mkMac =
        {
          username,
          certificatePath,
          homeModule,
        }:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit username certificatePath; };
          modules = [
            ./darwin-configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = {
                imports = [
                  ./home.nix
                  homeModule
                ];
                home.username = username;
                home.homeDirectory = "/Users/${username}";
                _module.args = { inherit inputs; };
              };
            }
          ];
        };
    in
    {
      darwinConfigurations.this-mac = mkMac {
        username = "alessandrocandolini";
        certificatePath = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
        homeModule = ./home-this-mac.nix;
      };

      darwinConfigurations.alternative-mac = mkMac {
        username = "acandolini";
        certificatePath = "/etc/nix/ca-bundle.pem";
        homeModule = ./home-alternative-mac.nix;
      };
    };
}
