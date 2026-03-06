{
  description = "Neovim test shell (nightly + external CLI dependencies)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, neovim-nightly-overlay }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forEachSystem = f:
        nixpkgs.lib.genAttrs systems (system:
          f {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;
            };
          });
    in
    {
      devShells = forEachSystem ({ system, pkgs }: {
        default = pkgs.mkShell {
          packages = [
            neovim-nightly-overlay.packages.${system}.default
            pkgs.git
            pkgs.gnumake
            pkgs.fzf
            pkgs.fd
            pkgs.proximity-sort
          ];

          shellHook = ''
            NVIM_TEST_ROOT="$(mktemp -d -t nvim-test-XXXXXX)"
            export HOME="$NVIM_TEST_ROOT/home"
            export XDG_DATA_HOME="$NVIM_TEST_ROOT/xdg/data"
            export XDG_STATE_HOME="$NVIM_TEST_ROOT/xdg/state"
            export XDG_CACHE_HOME="$NVIM_TEST_ROOT/xdg/cache"
            mkdir -p "$HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

            cleanup_nvim_test_shell() {
              rm -rf "$NVIM_TEST_ROOT"
            }
            trap cleanup_nvim_test_shell EXIT
          '';
        };
      });
    };
}
