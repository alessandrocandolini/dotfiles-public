{
  description = "nix-darwin + home-manager config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";

    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      darwin,
      home-manager,
      neovim-nightly-overlay,
      rust-overlay,
      llm-agents,
      ...
    }:
    let
      system = "aarch64-darwin";
      username = "alessandrocandolini";
      homeDirectory = "/Users/alessandrocandolini";
    in
    {
      darwinConfigurations.this-mac = darwin.lib.darwinSystem {
        inherit system;
        modules = [
          ./darwin-configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = {
              imports = [ ./home.nix ];
              home.username = username;
              home.homeDirectory = homeDirectory;
              _module.args = { inherit inputs; };
            };
          }
        ];
      };
    };
}
