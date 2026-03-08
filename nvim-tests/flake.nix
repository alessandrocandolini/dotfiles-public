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
            REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
            REPO_XDG_CONFIG_HOME="$REPO_ROOT/nvim/.config"
            REPO_NVIM_CONFIG="$REPO_XDG_CONFIG_HOME/nvim"
            export HOME="$NVIM_TEST_ROOT/home"
            export XDG_CONFIG_HOME="$REPO_XDG_CONFIG_HOME"
            export XDG_DATA_HOME="$NVIM_TEST_ROOT/xdg/data"
            export XDG_STATE_HOME="$NVIM_TEST_ROOT/xdg/state"
            export XDG_CACHE_HOME="$NVIM_TEST_ROOT/xdg/cache"
            mkdir -p "$HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

            if [ ! -d "$REPO_NVIM_CONFIG" ]; then
              echo "Expected Neovim config at $REPO_NVIM_CONFIG" >&2
              return 1
            fi

            if [ ! -f "$REPO_NVIM_CONFIG/nvim-pack-lock.json" ]; then
              echo "Expected lockfile at $REPO_NVIM_CONFIG/nvim-pack-lock.json" >&2
              return 1
            fi

            cleanup_nvim_test_shell() {
              rm -rf "$NVIM_TEST_ROOT"
            }
            trap cleanup_nvim_test_shell EXIT
          '';
        };
      });
    };
}
